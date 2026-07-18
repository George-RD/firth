#![no_std]
#![forbid(unsafe_code)]

//! Bounded decoder and bootstrap executor for the frozen Firth v0.1 image.
//! The wire format here is the canonical format in `target-spec.md` §7.

extern crate alloc;

use alloc::{string::String, vec, vec::Vec};

const MAX_INSTRUCTIONS: u64 = 4096;
const MAX_BYTES: usize = 1 << 20;
const MAX_NESTING: usize = 32;
const MAX_WORD_TYPE_NESTING: usize = 32;
const DIGEST_BYTES: usize = 32;
pub const DEFAULT_FUEL: u64 = MAX_INSTRUCTIONS;
pub const FORMAT_VERSION: u16 = 1;
pub const GAMMA_VERSION: u64 = 1;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Value {
    Int(i64),
    Bool(bool),
    Bytes(Vec<u8>),
    Quotation(Quotation),
    PrimitiveValue { tag: u64, bytes: Vec<u8> },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Quotation {
    pub code: Vec<Instruction>,
    pub captures: Vec<Value>,
    pub consumed: Vec<bool>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Op {
    PushLiteral,
    PushQuote,
    PushCapture,
    Dup,
    Drop,
    Swap,
    Call,
    Dip,
    Compose,
    Quote,
    If,
    CallWord,
    Prim,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Operand {
    Literal(Value),
    Quote(Quotation),
    Capture(u64),
    Word(String),
    Primitive(String),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Instruction {
    pub op: Op,
    pub operand: Option<Operand>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WordEntry {
    pub name: String,
    pub erased_word_type: String,
    pub code: Vec<Instruction>,
    pub body_digest: Vec<u8>,
    pub kernel_evidence_digest: Vec<u8>,
    pub refinement_evidence_digest: Vec<u8>,
    pub generation: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Image {
    pub format_version: u16,
    pub image_version: u64,
    pub gamma_version: u64,
    pub words: Vec<WordEntry>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum VmError {
    Truncated,
    InvalidLeb128,
    NonCanonicalLeb128,
    InputTooLarge,
    InstructionLimit,
    NestingLimit,
    LengthLimit,
    UnsupportedFormat(u16),
    UnsupportedGamma(u64),
    InvalidUtf8,
    InvalidIdentifier,
    InvalidWordType,
    InvalidValueTag(u8),
    InvalidLiteralEncoding,
    InvalidBoolean(u8),
    InvalidPrimitiveTag,
    InvalidOpcode(u8),
    InvalidDigestLength,
    InvalidCaptureBitmap,
    InvalidCaptureIndex(u64),
    FuelExhausted,
    DuplicateWord,
    UnsortedWords,
    TrailingBytes,
    UnsupportedOperation(Op),
    UnknownWord(String),
    StackFault,
}

pub fn decode(bytes: &[u8]) -> Result<Image, VmError> {
    if bytes.len() > MAX_BYTES {
        return Err(VmError::InputTooLarge);
    }
    let mut reader = Reader::new(bytes);
    let format_version = u16::try_from(reader.unsigned()?).map_err(|_| VmError::InvalidLeb128)?;
    if format_version != FORMAT_VERSION {
        return Err(VmError::UnsupportedFormat(format_version));
    }
    let image_version = reader.unsigned()?;
    let gamma_version = reader.unsigned()?;
    if gamma_version != GAMMA_VERSION {
        return Err(VmError::UnsupportedGamma(gamma_version));
    }
    let words = reader.vector(|reader| decode_word(reader))?;
    for pair in words.windows(2) {
        if pair[0].name.as_bytes() >= pair[1].name.as_bytes() {
            return Err(if pair[0].name == pair[1].name {
                VmError::DuplicateWord
            } else {
                VmError::UnsortedWords
            });
        }
    }
    if !reader.remaining().is_empty() {
        return Err(VmError::TrailingBytes);
    }
    Ok(Image {
        format_version,
        image_version,
        gamma_version,
        words,
    })
}

fn decode_word(reader: &mut Reader<'_>) -> Result<WordEntry, VmError> {
    let name = reader.string()?;
    if !is_canonical_identifier(name.as_bytes()) {
        return Err(VmError::InvalidIdentifier);
    }
    let erased_word_type = reader.string()?;
    if !is_canonical_word_type(&erased_word_type) {
        return Err(VmError::InvalidWordType);
    }
    let code = decode_code(reader, 0)?;
    let body_digest = reader.digest()?;
    let kernel_evidence_digest = reader.digest()?;
    let refinement_evidence_digest = reader.digest()?;
    let generation = reader.unsigned()?;
    Ok(WordEntry {
        name,
        erased_word_type,
        code,
        body_digest,
        kernel_evidence_digest,
        refinement_evidence_digest,
        generation,
    })
}

fn decode_code(reader: &mut Reader<'_>, depth: usize) -> Result<Vec<Instruction>, VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    let count = reader.count()?;
    let mut code = Vec::with_capacity(count);
    for _ in 0..count {
        code.push(decode_instruction(reader, depth)?);
    }
    Ok(code)
}

fn decode_instruction(reader: &mut Reader<'_>, depth: usize) -> Result<Instruction, VmError> {
    let opcode = reader.byte()?;
    let (op, operand) = match opcode {
        0 => (
            Op::PushLiteral,
            Some(Operand::Literal(decode_literal(reader)?)),
        ),
        1 => (
            Op::PushQuote,
            Some(Operand::Quote(decode_quotation(reader, depth + 1)?)),
        ),
        2 => (Op::PushCapture, Some(Operand::Capture(reader.unsigned()?))),
        3 => (Op::Dup, None),
        4 => (Op::Drop, None),
        5 => (Op::Swap, None),
        6 => (Op::Call, None),
        7 => (Op::Dip, None),
        8 => (Op::Compose, None),
        9 => (Op::Quote, None),
        10 => (Op::If, None),
        11 => {
            let name = reader.string()?;
            if !is_canonical_identifier(name.as_bytes()) {
                return Err(VmError::InvalidIdentifier);
            }
            (Op::CallWord, Some(Operand::Word(name)))
        }
        12 => (Op::Prim, Some(Operand::Primitive(reader.string()?))),
        other => return Err(VmError::InvalidOpcode(other)),
    };
    Ok(Instruction { op, operand })
}

fn decode_quotation(reader: &mut Reader<'_>, depth: usize) -> Result<Quotation, VmError> {
    let code = decode_code(reader, depth)?;
    let capture_count = reader.count()?;
    let bitmap_bytes = reader.count_for(capture_count.div_ceil(8))?;
    let mut consumed = Vec::with_capacity(capture_count);
    for index in 0..capture_count {
        consumed.push(bitmap_bytes[index / 8] & (1 << (index % 8)) != 0);
    }
    if capture_count % 8 != 0
        && bitmap_bytes
            .last()
            .is_some_and(|byte| byte & !((1 << (capture_count % 8)) - 1) != 0)
    {
        return Err(VmError::InvalidCaptureBitmap);
    }
    let mut captures = Vec::with_capacity(capture_count);
    for _ in 0..capture_count {
        captures.push(decode_value(reader, depth)?);
    }
    validate_capture_indices(&code, capture_count as u64)?;
    Ok(Quotation {
        code,
        captures,
        consumed,
    })
}

fn validate_capture_indices(code: &[Instruction], count: u64) -> Result<(), VmError> {
    for instruction in code {
        match instruction.operand.as_ref() {
            Some(Operand::Capture(index)) if *index >= count => {
                return Err(VmError::InvalidCaptureIndex(*index));
            }
            Some(Operand::Quote(quotation)) => {
                validate_capture_indices(&quotation.code, quotation.captures.len() as u64)?
            }
            _ => {}
        }
    }
    Ok(())
}

fn decode_value(reader: &mut Reader<'_>, depth: usize) -> Result<Value, VmError> {
    match reader.byte()? {
        0 => Ok(Value::Int(reader.signed()?)),
        1 => match reader.byte()? {
            0 => Ok(Value::Bool(false)),
            1 => Ok(Value::Bool(true)),
            value => Err(VmError::InvalidBoolean(value)),
        },
        2 => Ok(Value::Bytes(reader.bytes()?.to_vec())),
        3 => Ok(Value::Quotation(decode_quotation(reader, depth + 1)?)),
        4 => Ok(Value::PrimitiveValue {
            tag: reader.unsigned()?,
            bytes: reader.bytes()?.to_vec(),
        }),
        tag => Err(VmError::InvalidValueTag(tag)),
    }
}

fn decode_literal(reader: &mut Reader<'_>) -> Result<Value, VmError> {
    match reader.byte()? {
        0 => Ok(Value::Int(reader.signed()?)),
        1 => match reader.byte()? {
            0 => Ok(Value::Bool(false)),
            1 => Ok(Value::Bool(true)),
            value => Err(VmError::InvalidBoolean(value)),
        },
        2 => Ok(Value::Bytes(reader.bytes()?.to_vec())),
        3 | 4 => Err(VmError::InvalidLiteralEncoding),
        tag => Err(VmError::InvalidValueTag(tag)),
    }
}

pub fn execute(image: &Image) -> Result<Vec<Value>, VmError> {
    execute_with_fuel(image, DEFAULT_FUEL)
}

pub fn execute_with_fuel(image: &Image, fuel: u64) -> Result<Vec<Value>, VmError> {
    let word = image
        .words
        .iter()
        .find(|word| word.name == "main")
        .ok_or_else(|| VmError::UnknownWord(String::from("main")))?;
    let mut stack = Vec::new();
    let mut fuel = fuel;
    execute_frames(
        vec![Frame::new(word.code.clone(), None)],
        image,
        &mut stack,
        &mut fuel,
    )?;
    Ok(stack)
}

struct Frame {
    code: Vec<Instruction>,
    position: usize,
    captures: Option<Quotation>,
}

impl Frame {
    fn new(code: Vec<Instruction>, captures: Option<Quotation>) -> Self {
        Self {
            code,
            position: 0,
            captures,
        }
    }
}

fn execute_frames(
    mut frames: Vec<Frame>,
    image: &Image,
    stack: &mut Vec<Value>,
    fuel: &mut u64,
) -> Result<(), VmError> {
    while !frames.is_empty() {
        if frames
            .last()
            .is_some_and(|frame| frame.position == frame.code.len())
        {
            frames.pop();
            continue;
        }
        if *fuel == 0 {
            return Err(VmError::FuelExhausted);
        }
        *fuel -= 1;
        let instruction = {
            let frame = frames.last_mut().ok_or(VmError::StackFault)?;
            let instruction = frame.code[frame.position].clone();
            frame.position += 1;
            instruction
        };
        match instruction.op {
            Op::PushLiteral => match instruction.operand.as_ref() {
                Some(Operand::Literal(value)) if is_literal(value) => stack.push(value.clone()),
                _ => return Err(VmError::InvalidLiteralEncoding),
            },
            Op::PushQuote => match instruction.operand.as_ref() {
                Some(Operand::Quote(quotation)) => stack.push(Value::Quotation(quotation.clone())),
                _ => return Err(VmError::StackFault),
            },
            Op::PushCapture => match instruction.operand.as_ref() {
                Some(Operand::Capture(index)) => {
                    let index = usize::try_from(*index)
                        .map_err(|_| VmError::InvalidCaptureIndex(*index))?;
                    let quotation = frames
                        .last_mut()
                        .and_then(|frame| frame.captures.as_mut())
                        .ok_or(VmError::StackFault)?;
                    let value = quotation
                        .captures
                        .get(index)
                        .ok_or(VmError::InvalidCaptureIndex(index as u64))?;
                    if quotation.consumed.get(index).copied().unwrap_or(true) {
                        return Err(VmError::StackFault);
                    }
                    stack.push(value.clone());
                    *quotation
                        .consumed
                        .get_mut(index)
                        .ok_or(VmError::StackFault)? = true;
                }
                _ => return Err(VmError::StackFault),
            },
            Op::Dup => stack.push(stack.last().cloned().ok_or(VmError::StackFault)?),
            Op::Drop => {
                stack.pop().ok_or(VmError::StackFault)?;
            }
            Op::Swap => {
                let length = stack.len();
                if length < 2 {
                    return Err(VmError::StackFault);
                }
                stack.swap(length - 1, length - 2);
            }
            Op::CallWord => match instruction.operand.as_ref() {
                Some(Operand::Word(name)) => {
                    let word = image
                        .words
                        .iter()
                        .find(|word| word.name == *name)
                        .ok_or_else(|| VmError::UnknownWord(name.clone()))?;
                    frames.push(Frame::new(word.code.clone(), None));
                }
                _ => return Err(VmError::StackFault),
            },
            Op::Call => {
                let Value::Quotation(quotation) = stack.pop().ok_or(VmError::StackFault)? else {
                    return Err(VmError::StackFault);
                };
                frames.push(Frame::new(quotation.code.clone(), Some(quotation)));
            }
            operation => return Err(VmError::UnsupportedOperation(operation)),
        }
    }
    Ok(())
}

fn is_literal(value: &Value) -> bool {
    matches!(value, Value::Int(_) | Value::Bool(_) | Value::Bytes(_))
}

fn is_canonical_word_type(value: &str) -> bool {
    let bytes = value.as_bytes();
    if bytes.first() != Some(&b'(')
        || bytes.last() != Some(&b')')
        || value.chars().any(char::is_whitespace)
    {
        return false;
    }
    let mut parser = WordTypeParser {
        bytes,
        position: 1,
        rows: Vec::new(),
        quotation_depth: 0,
    };
    parser.parse()
}

struct WordTypeParser<'a> {
    bytes: &'a [u8],
    position: usize,
    rows: Vec<&'a [u8]>,
    quotation_depth: usize,
}

impl<'a> WordTypeParser<'a> {
    fn parse(&mut self) -> bool {
        if self.consume(b"forall") {
            let mut count = 0;
            loop {
                let row = match self.identifier() {
                    Some(row) => row,
                    None => return false,
                };
                if !is_row_name(row) {
                    return false;
                }
                self.rows.push(row);
                count += 1;
                if self.consume_byte(b';') {
                    break;
                }
                if !self.consume_byte(b',') {
                    return false;
                }
            }
            if count == 0 {
                return false;
            }
        }
        if !self.stack_items() || !self.consume(b"--") || !self.stack_items() {
            return false;
        }
        self.position + 1 == self.bytes.len()
    }

    fn stack_items(&mut self) -> bool {
        let mut count = 0;
        if self.bytes[self.position..].starts_with(b"--")
            || matches!(self.bytes.get(self.position), Some(b')' | b']'))
        {
            return true;
        }
        loop {
            if self.peek_byte() == Some(b'[') {
                return false;
            }
            let item = match self.identifier() {
                Some(item) => item,
                None => return false,
            };
            if self.consume_byte(b':') {
                if !is_canonical_identifier(item) || !self.value_type() {
                    return false;
                }
            } else if !is_row_name(item) || self.rows.is_empty() || !self.rows.contains(&item) {
                return false;
            }
            count += 1;
            if self.bytes[self.position..].starts_with(b"--")
                || matches!(self.bytes.get(self.position), Some(b')' | b']'))
            {
                break;
            }
            if !self.consume_byte(b',') {
                return false;
            }
            if self.bytes[self.position..].starts_with(b"--")
                || matches!(self.bytes.get(self.position), Some(b')' | b']'))
            {
                return false;
            }
        }
        count > 0
    }

    fn value_type(&mut self) -> bool {
        if self.consume_byte(b'[') {
            if self.quotation_depth >= MAX_WORD_TYPE_NESTING {
                return false;
            }
            self.quotation_depth += 1;
            if !self.stack_items() || !self.consume(b"--") || !self.stack_items() {
                return false;
            }
            if !self.consume_byte(b']') {
                return false;
            }
            self.quotation_depth -= 1;
        } else {
            let type_name = match self.identifier() {
                Some(type_name) => type_name,
                None => return false,
            };
            if !is_canonical_identifier(type_name) {
                return false;
            }
        }
        if self.consume_byte(b'^') && !self.consume(b"many") && !self.consume(b"linear") {
            return false;
        }
        true
    }

    fn identifier(&mut self) -> Option<&'a [u8]> {
        let start = self.position;
        if self
            .bytes
            .get(self.position)
            .is_some_and(|byte| *byte >= 0x80)
        {
            let first = self.bytes[self.position];
            let width = if first & 0xe0 == 0xc0 {
                2
            } else if first & 0xf0 == 0xe0 {
                3
            } else if first & 0xf8 == 0xf0 {
                4
            } else {
                return None;
            };
            let end = self.position.checked_add(width)?;
            if end > self.bytes.len()
                || !self.bytes[self.position + 1..end]
                    .iter()
                    .all(|byte| *byte & 0xc0 == 0x80)
                || core::str::from_utf8(&self.bytes[self.position..end])
                    .ok()?
                    .chars()
                    .count()
                    != 1
            {
                return None;
            }
            self.position = end;
            return Some(&self.bytes[start..end]);
        }
        while self.position < self.bytes.len()
            && (self.bytes[self.position].is_ascii_alphanumeric()
                || self.bytes[self.position] == b'_')
        {
            self.position += 1;
        }
        (self.position > start).then(|| &self.bytes[start..self.position])
    }

    fn peek_byte(&self) -> Option<u8> {
        self.bytes.get(self.position).copied()
    }

    fn consume(&mut self, text: &[u8]) -> bool {
        self.bytes.get(self.position..self.position + text.len()) == Some(text) && {
            self.position += text.len();
            true
        }
    }

    fn consume_byte(&mut self, byte: u8) -> bool {
        self.bytes.get(self.position) == Some(&byte) && {
            self.position += 1;
            true
        }
    }
}

fn is_row_name(value: &[u8]) -> bool {
    core::str::from_utf8(value)
        .map(|value| value.chars().count() == 1)
        .unwrap_or(false)
}

fn is_canonical_identifier(value: &[u8]) -> bool {
    let Some((&first, rest)) = value.split_first() else {
        return false;
    };
    (first.is_ascii_alphabetic() || first == b'_')
        && rest
            .iter()
            .all(|byte| byte.is_ascii_alphanumeric() || *byte == b'_')
}

/// Canonical minimal image used by the CLI smoke test: a `main` word pushing 42.
pub fn smoke_image() -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, u64::from(FORMAT_VERSION));
    put_unsigned(&mut bytes, 1);
    put_unsigned(&mut bytes, GAMMA_VERSION);
    put_unsigned(&mut bytes, 1);
    put_string(&mut bytes, "main");
    put_string(&mut bytes, "(--)");
    put_unsigned(&mut bytes, 1);
    bytes.push(0);
    bytes.push(0);
    put_unsigned(&mut bytes, 42 << 1);
    bytes.extend([0; DIGEST_BYTES * 3]);
    put_unsigned(&mut bytes, 1);
    bytes
}

fn put_unsigned(bytes: &mut Vec<u8>, mut value: u64) {
    loop {
        let mut byte = (value & 0x7f) as u8;
        value >>= 7;
        if value != 0 {
            byte |= 0x80;
        }
        bytes.push(byte);
        if value == 0 {
            return;
        }
    }
}

fn put_string(bytes: &mut Vec<u8>, value: &str) {
    put_unsigned(bytes, value.len() as u64);
    bytes.extend(value.as_bytes());
}

struct Reader<'a> {
    bytes: &'a [u8],
    position: usize,
}

impl<'a> Reader<'a> {
    fn new(bytes: &'a [u8]) -> Self {
        Self { bytes, position: 0 }
    }
    fn remaining(&self) -> &[u8] {
        &self.bytes[self.position..]
    }
    fn byte(&mut self) -> Result<u8, VmError> {
        let byte = *self.bytes.get(self.position).ok_or(VmError::Truncated)?;
        self.position += 1;
        Ok(byte)
    }
    fn take(&mut self, count: usize) -> Result<&'a [u8], VmError> {
        let end = self
            .position
            .checked_add(count)
            .ok_or(VmError::LengthLimit)?;
        let result = self
            .bytes
            .get(self.position..end)
            .ok_or(VmError::Truncated)?;
        self.position = end;
        Ok(result)
    }
    fn unsigned(&mut self) -> Result<u64, VmError> {
        let mut value = 0u64;
        for index in 0..10 {
            let byte = self.byte()?;
            let payload = u64::from(byte & 0x7f);
            if index == 9 && (byte & 0x80 != 0 || payload > 1) {
                return Err(VmError::InvalidLeb128);
            }
            value |= payload << (index * 7);
            if byte & 0x80 == 0 {
                if index > 0 && value < (1u64 << (index * 7)) {
                    return Err(VmError::NonCanonicalLeb128);
                }
                return Ok(value);
            }
        }
        Err(VmError::InvalidLeb128)
    }
    fn signed(&mut self) -> Result<i64, VmError> {
        let value = self.unsigned()?;
        Ok(((value >> 1) as i64) ^ -((value & 1) as i64))
    }
    fn bounded_len(&mut self) -> Result<usize, VmError> {
        let length = self.unsigned()?;
        let length = usize::try_from(length).map_err(|_| VmError::LengthLimit)?;
        if length > MAX_BYTES || length > self.remaining().len() {
            return Err(if length > MAX_BYTES {
                VmError::LengthLimit
            } else {
                VmError::Truncated
            });
        }
        Ok(length)
    }
    fn bytes(&mut self) -> Result<&'a [u8], VmError> {
        let length = self.bounded_len()?;
        self.take(length)
    }
    fn string(&mut self) -> Result<String, VmError> {
        String::from_utf8(self.bytes()?.to_vec()).map_err(|_| VmError::InvalidUtf8)
    }
    fn digest(&mut self) -> Result<Vec<u8>, VmError> {
        let bytes = self.take(DIGEST_BYTES)?;
        Ok(bytes.to_vec())
    }
    fn count(&mut self) -> Result<usize, VmError> {
        let count = self.unsigned()?;
        if count > MAX_INSTRUCTIONS {
            return Err(VmError::InstructionLimit);
        }
        usize::try_from(count).map_err(|_| VmError::LengthLimit)
    }
    fn count_for(&mut self, count: usize) -> Result<&'a [u8], VmError> {
        if count > MAX_BYTES {
            return Err(VmError::LengthLimit);
        }
        self.take(count)
    }
    fn vector<T>(
        &mut self,
        mut decode: impl FnMut(&mut Self) -> Result<T, VmError>,
    ) -> Result<Vec<T>, VmError> {
        let count = self.count()?;
        let mut values = Vec::with_capacity(count);
        for _ in 0..count {
            values.push(decode(self)?);
        }
        Ok(values)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::vec;

    #[test]
    fn smoke_program_decodes_and_executes_canonical_main() {
        let image = decode(&smoke_image()).expect("valid canonical image");
        assert_eq!(execute(&image), Ok(vec![Value::Int(42)]));
        assert_eq!(image.image_version, 1);
        assert_eq!(image.words[0].name, "main");
    }

    #[test]
    fn invalid_utf8_word_name_is_rejected() {
        let mut bytes = smoke_image();
        bytes[8] = 0xff;
        assert_eq!(decode(&bytes), Err(VmError::InvalidUtf8));
    }

    #[test]
    fn canonical_operands_and_metadata_are_preserved() {
        let mut code = Vec::new();
        put_unsigned(&mut code, 12);
        code.extend([0, 0]);
        put_unsigned(&mut code, (i64::MAX as u64) << 1);
        code.push(1);
        put_unsigned(&mut code, 1);
        code.extend([2, 0]);
        put_unsigned(&mut code, 1);
        code.push(1);
        code.push(0);
        put_unsigned(&mut code, 7 << 1);
        code.extend([11, 5]);
        code.extend(b"other");
        code.extend([12, 1, b'p']);
        code.extend([3, 4, 5, 6, 7, 8, 9, 10]);
        let mut bytes = Vec::new();
        put_unsigned(&mut bytes, 1);
        put_unsigned(&mut bytes, u64::MAX);
        put_unsigned(&mut bytes, GAMMA_VERSION);
        put_unsigned(&mut bytes, 2);
        put_string(&mut bytes, "main");
        put_string(&mut bytes, "(--)");
        bytes.extend(code);
        bytes.extend([1; DIGEST_BYTES]);
        bytes.extend([2; DIGEST_BYTES]);
        bytes.extend([3; DIGEST_BYTES]);
        put_unsigned(&mut bytes, u64::MAX);
        put_string(&mut bytes, "other");
        put_string(&mut bytes, "(--)");
        put_unsigned(&mut bytes, 0);
        bytes.extend([4; DIGEST_BYTES * 3]);
        put_unsigned(&mut bytes, 9);

        let image = decode(&bytes).expect("canonical operands decode");
        assert_eq!(image.image_version, u64::MAX);
        assert_eq!(image.words[0].generation, u64::MAX);
        assert_eq!(image.words[0].body_digest, vec![1; DIGEST_BYTES]);
        assert_eq!(image.words[1].name, "other");
        assert_eq!(
            image.words[0].code[0].operand,
            Some(Operand::Literal(Value::Int(i64::MAX)))
        );
        assert_eq!(
            image.words[0].code[2].operand,
            Some(Operand::Word(String::from("other")))
        );
        assert_eq!(
            image.words[0].code[3].operand,
            Some(Operand::Primitive(String::from("p")))
        );
        assert_eq!(
            image.words[0].code[4..]
                .iter()
                .map(|instruction| instruction.op)
                .collect::<Vec<_>>(),
            vec![
                Op::Dup,
                Op::Drop,
                Op::Swap,
                Op::Call,
                Op::Dip,
                Op::Compose,
                Op::Quote,
                Op::If
            ]
        );
        match &image.words[0].code[1].operand {
            Some(Operand::Quote(quote)) => {
                assert_eq!(quote.code[0].operand, Some(Operand::Capture(0)));
                assert_eq!(quote.captures, vec![Value::Int(7)]);
                assert_eq!(quote.consumed, vec![true]);
            }
            other => panic!("unexpected quote operand: {other:?}"),
        }
    }

    #[test]
    fn input_instruction_nesting_and_size_limits_are_bounded() {
        let mut too_large = vec![0; MAX_BYTES + 1];
        too_large[0] = 1;
        assert_eq!(decode(&too_large), Err(VmError::InputTooLarge));

        let mut overlong = Vec::new();
        put_unsigned(&mut overlong, 1);
        put_unsigned(&mut overlong, 1);
        put_unsigned(&mut overlong, GAMMA_VERSION);
        put_unsigned(&mut overlong, MAX_INSTRUCTIONS + 1);
        assert_eq!(decode(&overlong), Err(VmError::InstructionLimit));

        let mut nested = vec![1, 3];
        for _ in 0..=MAX_NESTING {
            let mut wrapped = vec![1, 1];
            wrapped.extend(nested);
            wrapped.push(0);
            nested = wrapped;
        }
        let mut image = Vec::new();
        put_unsigned(&mut image, 1);
        put_unsigned(&mut image, 1);
        put_unsigned(&mut image, GAMMA_VERSION);
        put_unsigned(&mut image, 1);
        put_string(&mut image, "main");
        put_string(&mut image, "(--)");
        image.extend(nested);
        image.extend([0; DIGEST_BYTES * 3]);
        image.push(0);
        assert_eq!(decode(&image), Err(VmError::NestingLimit));
    }

    #[test]
    fn malformed_header_and_trailing_bytes_are_rejected() {
        let mut bytes = smoke_image();
        bytes[0] = 2;
        assert_eq!(decode(&bytes), Err(VmError::UnsupportedFormat(2)));
        let mut bytes = smoke_image();
        bytes.push(0);
        assert_eq!(decode(&bytes), Err(VmError::TrailingBytes));
    }

    #[test]
    fn signed_integer_boundaries_round_trip() {
        for value in [i64::MIN, -1, 0, 1, i64::MAX] {
            let mut encoded = Vec::new();
            encoded.push(0);
            put_unsigned(&mut encoded, ((value as u64) << 1) ^ ((value >> 63) as u64));
            let mut reader = Reader::new(&encoded);
            assert_eq!(decode_value(&mut reader, 0), Ok(Value::Int(value)));
        }
    }

    fn instruction(op: Op, operand: Option<Operand>) -> Instruction {
        Instruction { op, operand }
    }

    fn word(name: &str, code: Vec<Instruction>) -> WordEntry {
        WordEntry {
            name: String::from(name),
            erased_word_type: String::from("(--)"),
            code,
            body_digest: vec![0; DIGEST_BYTES],
            kernel_evidence_digest: vec![0; DIGEST_BYTES],
            refinement_evidence_digest: vec![0; DIGEST_BYTES],
            generation: 0,
        }
    }

    fn test_image(words: Vec<WordEntry>) -> Image {
        Image {
            format_version: FORMAT_VERSION,
            image_version: 1,
            gamma_version: GAMMA_VERSION,
            words,
        }
    }

    #[test]
    fn call_word_uses_the_callers_operand_stack() {
        let main = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(1)))),
                instruction(Op::CallWord, Some(Operand::Word(String::from("drop_one")))),
            ],
        );
        let callee = word("drop_one", vec![instruction(Op::Drop, None)]);
        assert_eq!(execute(&test_image(vec![main, callee])), Ok(vec![]));
    }

    #[test]
    fn nested_word_and_quotation_calls_share_stack_and_fuel() {
        let main = word(
            "main",
            vec![
                instruction(Op::CallWord, Some(Operand::Word(String::from("outer")))),
                instruction(
                    Op::PushQuote,
                    Some(Operand::Quote(Quotation {
                        code: vec![instruction(
                            Op::PushLiteral,
                            Some(Operand::Literal(Value::Int(9))),
                        )],
                        captures: vec![],
                        consumed: vec![],
                    })),
                ),
                instruction(Op::Call, None),
            ],
        );
        let outer = word(
            "outer",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("inner"))),
            )],
        );
        let inner = word(
            "inner",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Int(7))),
            )],
        );
        let image = test_image(vec![main, outer, inner]);
        assert_eq!(
            execute_with_fuel(&image, 6),
            Ok(vec![Value::Int(7), Value::Int(9)])
        );
        assert_eq!(execute_with_fuel(&image, 5), Err(VmError::FuelExhausted));
    }

    #[test]
    fn recursive_calls_exhaust_one_shared_fuel_counter() {
        let main = word(
            "main",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("loop"))),
            )],
        );
        let loop_word = word(
            "loop",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("loop"))),
            )],
        );
        assert_eq!(
            execute_with_fuel(&test_image(vec![main, loop_word]), 4),
            Err(VmError::FuelExhausted)
        );
    }

    #[test]
    fn canonical_word_type_parser_accepts_and_rejects_structural_forms() {
        for valid in [
            "(--)",
            "(forallρ;ρ--ρ)",
            "(forallρ,σ;ρ--σ)",
            "(forallρ;ρ--ρ,x:Int^many)",
            "(forallρ;ρ--ρ,x:Bytes^linear)",
            "(forallρ;ρ--q:[ρ--ρ]^many)",
            "(forallρ,σ;ρ--q:[ρ--x:[ρ--σ]^linear]^many)",
        ] {
            assert!(is_canonical_word_type(valid), "{valid}");
        }
        for invalid in [
            "--",
            "(ρ--ρ)",
            "(forallρ;ρ--σ)",
            "(forallρ;ρ--ρ,x:Int^bogus)",
            "(forallρσ;ρ--σ)",
            "(forallrow;row--row)",
            "(forallx:Int--)",
            "(forallρ; ρ--ρ)",
            "(forall\u{00a0};--)",
            "(forallρ;ρ-ρ)",
            "(forallρ;ρ--q:[ρ-ρ]^many)",
            "(forallρ;ρ--q:[ρ--ρ]^bogus)",
            "(forallρ;ρ--q:[ρ--ρ]^many{positive q})",
            "(forallρ;ρ--q:[ρ--ρ]^manytail)",
            "(forallρ;ρ--q:[ρ--ρ]^many)trailing",
            "(forallρ;ρ--q:[ρ--ρ]^many,)",
        ] {
            assert!(!is_canonical_word_type(invalid), "{invalid}");
        }
    }

    #[test]
    fn canonical_identifiers_have_ascii_boundaries() {
        for valid in [b"a".as_slice(), b"A9".as_slice(), b"_name".as_slice()] {
            assert!(is_canonical_identifier(valid));
        }
        for invalid in [
            b"".as_slice(),
            b"9name".as_slice(),
            b"name-name".as_slice(),
            "é".as_bytes(),
        ] {
            assert!(!is_canonical_identifier(invalid));
        }
    }

    #[test]
    fn quotation_word_type_nesting_is_bounded() {
        let mut value = String::from("Int");
        for _ in 0..MAX_WORD_TYPE_NESTING {
            value = alloc::format!("[ρ--q:{value}]^many");
        }
        assert!(is_canonical_word_type(&alloc::format!(
            "(forallρ;ρ--q:{value})"
        )));
        value = alloc::format!("[ρ--q:{value}]^many");
        assert!(!is_canonical_word_type(&alloc::format!(
            "(forallρ;ρ--q:{value})"
        )));
    }

    #[test]
    fn image_and_call_word_identifiers_are_validated() {
        for (word_name, call_name) in [
            ("", "callee"),
            ("9main", "callee"),
            ("é", "callee"),
            ("main", ""),
            ("main", "9callee"),
            ("main", "é"),
        ] {
            assert_eq!(
                decode(&encoded_call_image(word_name, call_name)),
                Err(VmError::InvalidIdentifier)
            );
        }
        assert!(decode(&encoded_call_image("_main", "callee")).is_ok());
    }

    fn encoded_call_image(word_name: &str, call_name: &str) -> Vec<u8> {
        let mut bytes = Vec::new();
        put_unsigned(&mut bytes, u64::from(FORMAT_VERSION));
        put_unsigned(&mut bytes, 1);
        put_unsigned(&mut bytes, GAMMA_VERSION);
        put_unsigned(&mut bytes, 1);
        put_string(&mut bytes, word_name);
        put_string(&mut bytes, "(--)");
        put_unsigned(&mut bytes, 1);
        bytes.push(11);
        put_string(&mut bytes, call_name);
        bytes.extend([0; DIGEST_BYTES * 3]);
        put_unsigned(&mut bytes, 0);
        bytes
    }

    #[test]
    fn push_literal_rejects_quotation_and_primitive_values() {
        let image = test_image(vec![word(
            "main",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Quotation(Quotation {
                    code: vec![],
                    captures: vec![],
                    consumed: vec![],
                }))),
            )],
        )]);
        assert_eq!(execute(&image), Err(VmError::InvalidLiteralEncoding));

        let mut bytes = smoke_image();
        let literal_tag = bytes
            .iter()
            .position(|byte| *byte == 0)
            .expect("literal opcode");
        bytes[literal_tag + 1] = 4;
        assert_eq!(decode(&bytes), Err(VmError::InvalidLiteralEncoding));
    }

    #[test]
    fn malformed_and_noncanonical_encodings_are_rejected() {
        let mut bytes = smoke_image();
        let type_start = bytes
            .windows(4)
            .position(|window| window == b"(--)")
            .expect("type");
        bytes[type_start + 3] = b' ';
        assert_eq!(decode(&bytes), Err(VmError::InvalidWordType));

        let mut bytes = smoke_image();
        let literal = bytes
            .iter()
            .position(|byte| *byte == 0)
            .expect("literal opcode");
        bytes.splice(literal + 2..literal + 3, [0x80, 0x00]);
        assert_eq!(decode(&bytes), Err(VmError::NonCanonicalLeb128));
    }
}

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
    pub dictionary_digest: Vec<u8>,
    pub image_digest: Vec<u8>,
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
    InvalidDigest,
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
    let dictionary_digest = reader.digest()?;
    let image_digest = reader.digest()?;
    if dictionary_digest != sha256(&canonical_dictionary(&words))
        || image_digest
            != sha256(&canonical_image_identity(
                format_version,
                image_version,
                gamma_version,
                &dictionary_digest,
            ))
    {
        return Err(VmError::InvalidDigest);
    }
    if !reader.remaining().is_empty() {
        return Err(VmError::TrailingBytes);
    }
    Ok(Image {
        format_version,
        image_version,
        gamma_version,
        words,
        dictionary_digest,
        image_digest,
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
    if body_digest != sha256(&canonical_code(&code))
        || is_zero_digest(&kernel_evidence_digest)
        || is_zero_digest(&refinement_evidence_digest)
    {
        return Err(VmError::InvalidDigest);
    }
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
    validate_image(image)?;
    let word = image
        .words
        .iter()
        .find(|word| word.name == "main")
        .ok_or_else(|| VmError::UnknownWord(String::from("main")))?;
    let mut stack = Vec::new();
    let mut fuel = fuel;
    execute_frames(
        vec![Frame::new(word.code.clone())],
        image,
        &mut stack,
        &mut fuel,
    )?;
    Ok(stack)
}

struct Frame {
    code: Vec<Instruction>,
    position: usize,
}

impl Frame {
    fn new(code: Vec<Instruction>) -> Self {
        Self { code, position: 0 }
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
                Some(Operand::Quote(quotation)) if !contains_captures(quotation) => {
                    stack.push(Value::Quotation(quotation.clone()))
                }
                Some(Operand::Quote(_)) => {
                    return Err(VmError::UnsupportedOperation(Op::PushQuote));
                }
                _ => return Err(VmError::StackFault),
            },
            Op::PushCapture => match instruction.operand.as_ref() {
                Some(Operand::Capture(_)) => {
                    return Err(VmError::UnsupportedOperation(Op::PushCapture));
                }
                _ => return Err(VmError::StackFault),
            },
            /*
             * Capture-bearing quotations are outside the bootstrap executor:
             * cloning them would be an implicit copy of a possibly linear
             * value. Kernel execution will add usage-aware ownership.
             */
            Op::Dup | Op::Drop => return Err(VmError::UnsupportedOperation(instruction.op)),
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
                    frames.push(Frame::new(word.code.clone()));
                }
                _ => return Err(VmError::StackFault),
            },
            Op::Call => {
                let Value::Quotation(quotation) = stack.pop().ok_or(VmError::StackFault)? else {
                    return Err(VmError::StackFault);
                };
                if contains_captures(&quotation) {
                    return Err(VmError::UnsupportedOperation(Op::Call));
                }
                frames.push(Frame::new(quotation.code.clone()));
            }
            operation => return Err(VmError::UnsupportedOperation(operation)),
        }
    }
    Ok(())
}

fn validate_image(image: &Image) -> Result<(), VmError> {
    if image.format_version != FORMAT_VERSION || image.gamma_version != GAMMA_VERSION {
        return Err(VmError::InvalidDigest);
    }
    if image.dictionary_digest.len() != DIGEST_BYTES || image.image_digest.len() != DIGEST_BYTES {
        return Err(VmError::InvalidDigestLength);
    }
    for pair in image.words.windows(2) {
        if pair[0].name.as_bytes() >= pair[1].name.as_bytes() {
            return Err(if pair[0].name == pair[1].name {
                VmError::DuplicateWord
            } else {
                VmError::UnsortedWords
            });
        }
    }
    for word in &image.words {
        if !is_canonical_identifier(word.name.as_bytes())
            || !is_canonical_word_type(&word.erased_word_type)
        {
            return Err(if !is_canonical_identifier(word.name.as_bytes()) {
                VmError::InvalidIdentifier
            } else {
                VmError::InvalidWordType
            });
        }
        validate_code_structure(&word.code, 0)?;
        validate_bootstrap_code(&word.code, 0)?;
        if word.body_digest.len() != DIGEST_BYTES
            || word.kernel_evidence_digest.len() != DIGEST_BYTES
            || word.refinement_evidence_digest.len() != DIGEST_BYTES
        {
            return Err(VmError::InvalidDigestLength);
        }
        if word.body_digest != sha256(&canonical_code(&word.code))
            || is_zero_digest(&word.kernel_evidence_digest)
            || is_zero_digest(&word.refinement_evidence_digest)
        {
            return Err(VmError::InvalidDigest);
        }
    }
    if image.dictionary_digest != sha256(&canonical_dictionary(&image.words))
        || image.image_digest
            != sha256(&canonical_image_identity(
                image.format_version,
                image.image_version,
                image.gamma_version,
                &image.dictionary_digest,
            ))
    {
        return Err(VmError::InvalidDigest);
    }
    Ok(())
}

fn validate_code_structure(code: &[Instruction], depth: usize) -> Result<(), VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    for instruction in code {
        match instruction.op {
            Op::PushLiteral => match instruction.operand.as_ref() {
                Some(Operand::Literal(value)) if is_literal(value) => {
                    validate_value_structure(value, depth)?;
                }
                _ => return Err(VmError::InvalidLiteralEncoding),
            },
            Op::PushQuote => match instruction.operand.as_ref() {
                Some(Operand::Quote(quotation)) => {
                    validate_bootstrap_quotation(quotation, depth + 1)?;
                    validate_code_structure(&quotation.code, depth + 1)?;
                }
                _ => return Err(VmError::StackFault),
            },
            Op::PushCapture => match instruction.operand.as_ref() {
                Some(Operand::Capture(_)) => {}
                _ => return Err(VmError::StackFault),
            },
            Op::CallWord => match instruction.operand.as_ref() {
                Some(Operand::Word(name)) if is_canonical_identifier(name.as_bytes()) => {}
                _ => return Err(VmError::InvalidIdentifier),
            },
            Op::Prim => match instruction.operand.as_ref() {
                Some(Operand::Primitive(_)) => {}
                _ => return Err(VmError::InvalidPrimitiveTag),
            },
            Op::Dup
            | Op::Drop
            | Op::Swap
            | Op::Call
            | Op::Dip
            | Op::Compose
            | Op::Quote
            | Op::If
                if instruction.operand.is_some() =>
            {
                return Err(VmError::StackFault);
            }
            _ => {}
        }
    }
    Ok(())
}

fn validate_value_structure(value: &Value, depth: usize) -> Result<(), VmError> {
    if let Value::Quotation(quotation) = value {
        validate_bootstrap_quotation(quotation, depth + 1)?;
        validate_code_structure(&quotation.code, depth + 1)?;
    }
    Ok(())
}

fn validate_bootstrap_code(code: &[Instruction], depth: usize) -> Result<(), VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    for instruction in code {
        match instruction.op {
            Op::Dup | Op::Drop => {
                return Err(VmError::UnsupportedOperation(instruction.op));
            }
            Op::PushCapture => {
                return Err(VmError::UnsupportedOperation(Op::PushCapture));
            }
            _ => {}
        }
        match instruction.operand.as_ref() {
            Some(Operand::Quote(quotation)) => {
                validate_bootstrap_quotation(quotation, depth + 1)?;
                if contains_captures(quotation) {
                    return Err(VmError::UnsupportedOperation(Op::PushQuote));
                }
                validate_bootstrap_code(&quotation.code, depth + 1)?;
            }
            Some(Operand::Literal(value)) => validate_bootstrap_value(value, depth + 1)?,
            _ => {}
        }
    }
    Ok(())
}

fn validate_bootstrap_quotation(quotation: &Quotation, depth: usize) -> Result<(), VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    if quotation.consumed.len() != quotation.captures.len() {
        return Err(VmError::InvalidCaptureBitmap);
    }
    for capture in &quotation.captures {
        validate_bootstrap_value(capture, depth + 1)?;
    }
    Ok(())
}

fn validate_bootstrap_value(value: &Value, depth: usize) -> Result<(), VmError> {
    if let Value::Quotation(quotation) = value {
        validate_bootstrap_quotation(quotation, depth + 1)?;
        if contains_captures(quotation) {
            return Err(VmError::UnsupportedOperation(Op::PushLiteral));
        }
        validate_bootstrap_code(&quotation.code, depth + 1)?;
    }
    Ok(())
}

fn contains_captures(quotation: &Quotation) -> bool {
    !quotation.captures.is_empty()
        || quotation.captures.iter().any(value_contains_captures)
        || quotation.code.iter().any(instruction_contains_captures)
}

fn instruction_contains_captures(instruction: &Instruction) -> bool {
    match instruction.operand.as_ref() {
        Some(Operand::Quote(quotation)) => contains_captures(quotation),
        Some(Operand::Literal(value)) => value_contains_captures(value),
        _ => false,
    }
}

fn value_contains_captures(value: &Value) -> bool {
    matches!(value, Value::Quotation(quotation) if contains_captures(quotation))
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
                let row = match self.row_name() {
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
            let item = match self.identifier().or_else(|| self.row_name()) {
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

    fn row_name(&mut self) -> Option<&'a [u8]> {
        let start = self.position;
        let first = *self.bytes.get(self.position)?;
        let width = if first < 0x80 {
            1
        } else if first & 0xe0 == 0xc0 {
            2
        } else if first & 0xf0 == 0xe0 {
            3
        } else if first & 0xf8 == 0xf0 {
            4
        } else {
            return None;
        };
        let end = self.position.checked_add(width)?;
        let value = self.bytes.get(start..end)?;
        let scalar = core::str::from_utf8(value).ok()?.chars().next()?;
        if scalar.is_whitespace()
            || matches!(scalar, ',' | ';' | ':' | '^' | '(' | ')' | '[' | ']' | '-')
        {
            return None;
        }
        self.position = end;
        Some(value)
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
    let mut parser = WordTypeParser {
        bytes: value,
        position: 0,
        rows: Vec::new(),
        quotation_depth: 0,
    };
    parser.row_name().is_some() && parser.position == value.len()
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
    let body_digest = sha256(&canonical_code(&[Instruction {
        op: Op::PushLiteral,
        operand: Some(Operand::Literal(Value::Int(42))),
    }]));
    bytes.extend(body_digest);
    bytes.extend(sha256(&[]));
    bytes.extend(sha256(&[]));
    put_unsigned(&mut bytes, 1);
    let word = WordEntry {
        name: String::from("main"),
        erased_word_type: String::from("(--)"),
        code: vec![Instruction {
            op: Op::PushLiteral,
            operand: Some(Operand::Literal(Value::Int(42))),
        }],
        body_digest: sha256(&canonical_code(&[Instruction {
            op: Op::PushLiteral,
            operand: Some(Operand::Literal(Value::Int(42))),
        }]))
        .to_vec(),
        kernel_evidence_digest: sha256(&[]).to_vec(),
        refinement_evidence_digest: sha256(&[]).to_vec(),
        generation: 1,
    };
    let dictionary_digest = sha256(&canonical_dictionary(&[word]));
    bytes.extend(dictionary_digest);
    bytes.extend(sha256(&canonical_image_identity(
        FORMAT_VERSION,
        1,
        GAMMA_VERSION,
        &dictionary_digest,
    )));
    bytes
}

fn is_zero_digest(digest: &[u8]) -> bool {
    digest.iter().all(|byte| *byte == 0)
}

fn canonical_code(code: &[Instruction]) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, code.len() as u64);
    for instruction in code {
        bytes.push(match instruction.op {
            Op::PushLiteral => 0,
            Op::PushQuote => 1,
            Op::PushCapture => 2,
            Op::Dup => 3,
            Op::Drop => 4,
            Op::Swap => 5,
            Op::Call => 6,
            Op::Dip => 7,
            Op::Compose => 8,
            Op::Quote => 9,
            Op::If => 10,
            Op::CallWord => 11,
            Op::Prim => 12,
        });
        match instruction.operand.as_ref() {
            Some(Operand::Literal(value)) => canonical_value(&mut bytes, value),
            Some(Operand::Quote(quotation)) => {
                bytes.extend(canonical_code(&quotation.code));
                put_unsigned(&mut bytes, quotation.captures.len() as u64);
                let mut bitmap = vec![0; quotation.captures.len().div_ceil(8)];
                for (index, consumed) in quotation.consumed.iter().copied().enumerate() {
                    if consumed {
                        bitmap[index / 8] |= 1 << (index % 8);
                    }
                }
                bytes.extend(bitmap);
                for capture in &quotation.captures {
                    canonical_value(&mut bytes, capture);
                }
            }
            Some(Operand::Capture(index)) => put_unsigned(&mut bytes, *index),
            Some(Operand::Word(name)) | Some(Operand::Primitive(name)) => {
                put_string(&mut bytes, name)
            }
            None => {}
        }
    }
    bytes
}

fn canonical_value(bytes: &mut Vec<u8>, value: &Value) {
    match value {
        Value::Int(value) => {
            bytes.push(0);
            put_unsigned(bytes, ((*value as u64) << 1) ^ ((*value >> 63) as u64));
        }
        Value::Bool(value) => {
            bytes.extend([1, u8::from(*value)]);
        }
        Value::Bytes(value) => {
            bytes.push(2);
            put_string_bytes(bytes, value);
        }
        Value::Quotation(quotation) => {
            bytes.push(3);
            bytes.extend(canonical_code(&quotation.code));
            put_unsigned(bytes, quotation.captures.len() as u64);
            let mut bitmap = vec![0; quotation.captures.len().div_ceil(8)];
            for (index, consumed) in quotation.consumed.iter().copied().enumerate() {
                if consumed {
                    bitmap[index / 8] |= 1 << (index % 8);
                }
            }
            bytes.extend(bitmap);
            for capture in &quotation.captures {
                canonical_value(bytes, capture);
            }
        }
        Value::PrimitiveValue { tag, bytes: value } => {
            bytes.push(4);
            put_unsigned(bytes, *tag);
            put_string_bytes(bytes, value);
        }
    }
}

fn canonical_dictionary(words: &[WordEntry]) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, words.len() as u64);
    for word in words {
        put_string(&mut bytes, &word.name);
        put_string(&mut bytes, &word.erased_word_type);
        bytes.extend(canonical_code(&word.code));
        bytes.extend(&word.body_digest);
        bytes.extend(&word.kernel_evidence_digest);
        bytes.extend(&word.refinement_evidence_digest);
        put_unsigned(&mut bytes, word.generation);
    }
    bytes
}

fn canonical_image_identity(
    format_version: u16,
    image_version: u64,
    gamma_version: u64,
    dictionary_digest: &[u8],
) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, u64::from(format_version));
    put_unsigned(&mut bytes, image_version);
    put_unsigned(&mut bytes, gamma_version);
    bytes.extend(dictionary_digest);
    bytes
}

fn put_string_bytes(bytes: &mut Vec<u8>, value: &[u8]) {
    put_unsigned(bytes, value.len() as u64);
    bytes.extend(value);
}

// SHA-256, specified by target-spec.md §7 and kept dependency-free for no_std.
fn sha256(input: &[u8]) -> [u8; DIGEST_BYTES] {
    const K: [u32; 64] = [
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4,
        0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe,
        0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f,
        0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
        0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
        0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
        0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116,
        0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7,
        0xc67178f2,
    ];
    let mut h: [u32; 8] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab,
        0x5be0cd19,
    ];
    let bit_len = (input.len() as u64).wrapping_mul(8);
    let padded_len = (input.len() + 9).div_ceil(64) * 64;
    let mut padded = vec![0; padded_len];
    padded[..input.len()].copy_from_slice(input);
    padded[input.len()] = 0x80;
    padded[padded_len - 8..].copy_from_slice(&bit_len.to_be_bytes());
    for chunk in padded.chunks_exact(64) {
        let mut w = [0u32; 64];
        for i in 0..16 {
            w[i] = u32::from_be_bytes([
                chunk[i * 4],
                chunk[i * 4 + 1],
                chunk[i * 4 + 2],
                chunk[i * 4 + 3],
            ]);
        }
        for i in 16..64 {
            let s0 = w[i - 15].rotate_right(7) ^ w[i - 15].rotate_right(18) ^ (w[i - 15] >> 3);
            let s1 = w[i - 2].rotate_right(17) ^ w[i - 2].rotate_right(19) ^ (w[i - 2] >> 10);
            w[i] = w[i - 16]
                .wrapping_add(s0)
                .wrapping_add(w[i - 7])
                .wrapping_add(s1);
        }
        let (mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut hh) =
            (h[0], h[1], h[2], h[3], h[4], h[5], h[6], h[7]);
        for i in 0..64 {
            let s1 = e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25);
            let ch = (e & f) ^ ((!e) & g);
            let t1 = hh
                .wrapping_add(s1)
                .wrapping_add(ch)
                .wrapping_add(K[i])
                .wrapping_add(w[i]);
            let s0 = a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22);
            let maj = (a & b) ^ (a & c) ^ (b & c);
            let t2 = s0.wrapping_add(maj);
            (hh, g, f, e, d, c, b, a) = (g, f, e, d.wrapping_add(t1), c, b, a, t1.wrapping_add(t2));
        }
        for (value, add) in h.iter_mut().zip([a, b, c, d, e, f, g, hh]) {
            *value = (*value).wrapping_add(add);
        }
    }
    let mut result = [0; DIGEST_BYTES];
    for (i, value) in h.into_iter().enumerate() {
        result[i * 4..i * 4 + 4].copy_from_slice(&value.to_be_bytes());
    }
    result
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
        bytes.extend(sha256(&canonical_code(&[
            Instruction {
                op: Op::PushLiteral,
                operand: Some(Operand::Literal(Value::Int(i64::MAX))),
            },
            Instruction {
                op: Op::PushQuote,
                operand: Some(Operand::Quote(Quotation {
                    code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                    captures: vec![Value::Int(7)],
                    consumed: vec![true],
                })),
            },
            Instruction {
                op: Op::CallWord,
                operand: Some(Operand::Word(String::from("other"))),
            },
            Instruction {
                op: Op::Prim,
                operand: Some(Operand::Primitive(String::from("p"))),
            },
            instruction(Op::Dup, None),
            instruction(Op::Drop, None),
            instruction(Op::Swap, None),
            instruction(Op::Call, None),
            instruction(Op::Dip, None),
            instruction(Op::Compose, None),
            instruction(Op::Quote, None),
            instruction(Op::If, None),
        ])));
        bytes.extend(sha256(&[]));
        bytes.extend(sha256(&[1]));
        put_unsigned(&mut bytes, u64::MAX);
        put_string(&mut bytes, "other");
        put_string(&mut bytes, "(--)");
        put_unsigned(&mut bytes, 0);
        bytes.extend(sha256(&canonical_code(&[])));
        bytes.extend(sha256(&[]));
        bytes.extend(sha256(&[1]));
        put_unsigned(&mut bytes, 9);
        let first_code = vec![
            instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Int(i64::MAX))),
            ),
            instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                    captures: vec![Value::Int(7)],
                    consumed: vec![true],
                })),
            ),
            instruction(Op::CallWord, Some(Operand::Word(String::from("other")))),
            instruction(Op::Prim, Some(Operand::Primitive(String::from("p")))),
            instruction(Op::Dup, None),
            instruction(Op::Drop, None),
            instruction(Op::Swap, None),
            instruction(Op::Call, None),
            instruction(Op::Dip, None),
            instruction(Op::Compose, None),
            instruction(Op::Quote, None),
            instruction(Op::If, None),
        ];
        let first = WordEntry {
            name: String::from("main"),
            erased_word_type: String::from("(--)"),
            code: first_code.clone(),
            body_digest: sha256(&canonical_code(&first_code)).to_vec(),
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[1]).to_vec(),
            generation: u64::MAX,
        };
        let second = WordEntry {
            name: String::from("other"),
            erased_word_type: String::from("(--)"),
            code: vec![],
            body_digest: sha256(&canonical_code(&[])).to_vec(),
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[1]).to_vec(),
            generation: 9,
        };
        let dictionary_digest = sha256(&canonical_dictionary(&[first, second]));
        bytes.extend(dictionary_digest);
        bytes.extend(sha256(&canonical_image_identity(
            1,
            u64::MAX,
            GAMMA_VERSION,
            &dictionary_digest,
        )));

        let image = decode(&bytes).expect("canonical operands decode");
        assert_eq!(image.image_version, u64::MAX);
        assert_eq!(image.words[0].generation, u64::MAX);
        assert_eq!(
            image.words[0].body_digest,
            sha256(&canonical_code(&image.words[0].code))
        );
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
            body_digest: sha256(&canonical_code(&code)).to_vec(),
            code,
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[]).to_vec(),
            generation: 0,
        }
    }

    fn test_image(words: Vec<WordEntry>) -> Image {
        let mut words = words;
        words.sort_by(|left, right| left.name.as_bytes().cmp(right.name.as_bytes()));
        let dictionary_digest = sha256(&canonical_dictionary(&words)).to_vec();
        Image {
            format_version: FORMAT_VERSION,
            image_version: 1,
            gamma_version: GAMMA_VERSION,
            image_digest: sha256(&canonical_image_identity(
                FORMAT_VERSION,
                1,
                GAMMA_VERSION,
                &dictionary_digest,
            ))
            .to_vec(),
            dictionary_digest,
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
        assert_eq!(
            execute(&test_image(vec![main, callee])),
            Err(VmError::UnsupportedOperation(Op::Drop))
        );
    }

    #[test]
    fn bootstrap_rejects_dup_and_capture_copying_deterministically() {
        let dup = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(1)))),
                instruction(Op::Dup, None),
            ],
        );
        assert_eq!(
            execute(&test_image(vec![dup])),
            Err(VmError::UnsupportedOperation(Op::Dup))
        );

        let capture = word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::Int(1)],
                    consumed: vec![false],
                })),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![capture])),
            Err(VmError::UnsupportedOperation(Op::PushQuote))
        );

        let nested = word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![instruction(
                        Op::PushQuote,
                        Some(Operand::Quote(Quotation {
                            code: vec![],
                            captures: vec![Value::Int(2)],
                            consumed: vec![false],
                        })),
                    )],
                    captures: vec![],
                    consumed: vec![],
                })),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![nested])),
            Err(VmError::UnsupportedOperation(Op::PushQuote))
        );

        let mut invalid_length = test_image(vec![word("main", vec![])]);
        invalid_length.words[0].kernel_evidence_digest.pop();
        assert_eq!(execute(&invalid_length), Err(VmError::InvalidDigestLength));

        let literal_capture = word(
            "main",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Quotation(Quotation {
                    code: vec![],
                    captures: vec![Value::Int(3)],
                    consumed: vec![false],
                }))),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![literal_capture])),
            Err(VmError::InvalidLiteralEncoding)
        );

        let malformed_capture = word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::Int(4)],
                    consumed: vec![],
                })),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![malformed_capture])),
            Err(VmError::InvalidCaptureBitmap)
        );
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

    #[test]
    fn row_names_follow_target_scalar_grammar() {
        for valid in [
            "(forallρ;ρ--ρ)",
            "(forall1;1--1)",
            "(forall!;!--!)",
            "(forall@;@--@)",
            "(forall😀;😀--😀)",
        ] {
            assert!(is_canonical_word_type(valid), "{valid}");
        }
        for invalid in [
            "(forall;--)",
            "(forall;ρ--ρ)",
            "(forall12;12--12)",
            "(forall ;--)",
            "(forall\u{2003};--)",
        ] {
            assert!(!is_canonical_word_type(invalid), "{invalid}");
        }
    }

    #[test]
    fn bootstrap_rejects_zero_or_mismatched_digests() {
        let mut bytes = smoke_image();
        let digest_start = bytes.len() - (DIGEST_BYTES * 3 + 1);
        bytes[digest_start] ^= 1;
        assert_eq!(decode(&bytes), Err(VmError::InvalidDigest));

        let mut bytes = smoke_image();
        let evidence_start = bytes.len() - (DIGEST_BYTES * 2 + 1);
        bytes[evidence_start..evidence_start + DIGEST_BYTES].fill(0);
        assert_eq!(decode(&bytes), Err(VmError::InvalidDigest));
    }

    #[test]
    fn sha256_matches_known_empty_vector() {
        assert_eq!(
            sha256(&[]),
            [
                0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14, 0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f,
                0xb9, 0x24, 0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c, 0xa4, 0x95, 0x99, 0x1b,
                0x78, 0x52, 0xb8, 0x55,
            ]
        );
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
        bytes.extend(sha256(&canonical_code(&[instruction(
            Op::CallWord,
            Some(Operand::Word(String::from(call_name))),
        )])));
        bytes.extend(sha256(&[]));
        bytes.extend(sha256(&[1]));
        put_unsigned(&mut bytes, 0);
        let word = WordEntry {
            name: String::from(word_name),
            erased_word_type: String::from("(--)"),
            code: vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from(call_name))),
            )],
            body_digest: sha256(&canonical_code(&[instruction(
                Op::CallWord,
                Some(Operand::Word(String::from(call_name))),
            )]))
            .to_vec(),
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[1]).to_vec(),
            generation: 0,
        };
        let dictionary_digest = sha256(&canonical_dictionary(&[word]));
        bytes.extend(dictionary_digest);
        bytes.extend(sha256(&canonical_image_identity(
            FORMAT_VERSION,
            1,
            GAMMA_VERSION,
            &dictionary_digest,
        )));
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

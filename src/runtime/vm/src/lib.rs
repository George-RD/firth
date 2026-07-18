#![no_std]

//! Safe, deterministic bootstrap boundary for the Firth v0.1 target.
//!
//! The bootstrap envelope is `FVM0`, followed by canonical LEB128 format and
//! Gamma versions, an instruction count, and encoded instructions.
//! This bootstrap executes the literal and structural stack operations needed
//! by the smoke image. The remaining target operations are decoded and rejected
//! as unsupported until their execution boundary is implemented.

extern crate alloc;

use alloc::vec::Vec;

const MAGIC: &[u8; 4] = b"FVM0";
const MAX_INSTRUCTIONS: u64 = 4096;
const MAX_BYTES: u64 = 1 << 20;
const MAX_NESTING: usize = 32;
pub const FORMAT_VERSION: u16 = 1;
pub const GAMMA_VERSION: u64 = 1;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Value {
    Int(i64),
    Bool(bool),
    Bytes(Vec<u8>),
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
pub struct Instruction {
    pub op: Op,
    pub value: Option<Value>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Image {
    pub format_version: u16,
    pub gamma_version: u64,
    pub instructions: Vec<Instruction>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum VmError {
    Truncated,
    ResourceFault,
    InvalidLeb128,
    InvalidMagic,
    UnsupportedFormat(u16),
    UnsupportedGamma(u64),
    InvalidValueTag(u8),
    InvalidBoolean(u8),
    UnknownOpcode(u8),
    TrailingBytes,
    UnsupportedOperation(Op),
    StackFault,
}

pub fn decode(bytes: &[u8]) -> Result<Image, VmError> {
    if u64::try_from(bytes.len()).map_err(|_| VmError::ResourceFault)? > MAX_BYTES {
        return Err(VmError::ResourceFault);
    }
    let mut reader = Reader::new(bytes);
    if reader.take(4)? != MAGIC {
        return Err(VmError::InvalidMagic);
    }
    let format_version = u16::try_from(reader.leb128()?).map_err(|_| VmError::InvalidLeb128)?;
    if format_version != FORMAT_VERSION {
        return Err(VmError::UnsupportedFormat(format_version));
    }
    let gamma_version = reader.leb128()?;
    if gamma_version != GAMMA_VERSION {
        return Err(VmError::UnsupportedGamma(gamma_version));
    }
    let count = reader.leb128()?;
    if count > MAX_INSTRUCTIONS {
        return Err(VmError::ResourceFault);
    }
    let count = usize::try_from(count).map_err(|_| VmError::ResourceFault)?;
    let mut instructions = Vec::with_capacity(count);
    for _ in 0..count {
        let opcode = reader.byte()?;
        let instruction = match opcode {
            0 => Instruction {
                op: Op::PushLiteral,
                value: Some(decode_value(&mut reader)?),
            },
            1 => {
                decode_code(&mut reader, 1)?;
                let captures = reader.leb128()?;
                for _ in 0..captures {
                    decode_value(&mut reader)?;
                }
                Instruction {
                    op: Op::PushQuote,
                    value: None,
                }
            }
            2 => {
                reader.leb128()?;
                Instruction {
                    op: Op::PushCapture,
                    value: None,
                }
            }
            3 => Instruction {
                op: Op::Dup,
                value: None,
            },
            4 => Instruction {
                op: Op::Drop,
                value: None,
            },
            5 => Instruction {
                op: Op::Swap,
                value: None,
            },
            6 => Instruction {
                op: Op::Call,
                value: None,
            },
            7 => Instruction {
                op: Op::Dip,
                value: None,
            },
            8 => Instruction {
                op: Op::Compose,
                value: None,
            },
            9 => Instruction {
                op: Op::Quote,
                value: None,
            },
            10 => Instruction {
                op: Op::If,
                value: None,
            },
            11 => {
                let length = usize::try_from(reader.leb128()?).map_err(|_| VmError::Truncated)?;
                reader.take(length)?;
                Instruction {
                    op: Op::CallWord,
                    value: None,
                }
            }
            12 => {
                let length = usize::try_from(reader.leb128()?).map_err(|_| VmError::Truncated)?;
                reader.take(length)?;
                Instruction {
                    op: Op::Prim,
                    value: None,
                }
            }
            other => return Err(VmError::UnknownOpcode(other)),
        };
        instructions.push(instruction);
    }
    if !reader.remaining().is_empty() {
        return Err(VmError::TrailingBytes);
    }
    Ok(Image {
        format_version,
        gamma_version,
        instructions,
    })
}

pub fn execute(image: &Image) -> Result<Vec<Value>, VmError> {
    let mut stack = Vec::new();
    for instruction in &image.instructions {
        match instruction.op {
            Op::PushLiteral => stack.push(instruction.value.clone().ok_or(VmError::StackFault)?),
            Op::Dup => {
                let value = stack.last().cloned().ok_or(VmError::StackFault)?;
                stack.push(value);
            }
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
            operation => return Err(VmError::UnsupportedOperation(operation)),
        }
    }
    Ok(stack)
}

pub fn smoke_image() -> Vec<u8> {
    let mut bytes = Vec::from(*MAGIC);
    bytes.extend([FORMAT_VERSION as u8, GAMMA_VERSION as u8, 3]);
    bytes.extend([0, 0, 84, 3, 4]);
    bytes
}

fn decode_value(reader: &mut Reader<'_>) -> Result<Value, VmError> {
    match reader.byte()? {
        0 => Ok(Value::Int(unzigzag(reader.leb128()?))),
        1 => match reader.byte()? {
            0 => Ok(Value::Bool(false)),
            1 => Ok(Value::Bool(true)),
            value => Err(VmError::InvalidBoolean(value)),
        },
        2 => {
            let length = reader.leb128()?;
            if length > MAX_BYTES {
                return Err(VmError::ResourceFault);
            }
            let length = usize::try_from(length).map_err(|_| VmError::ResourceFault)?;
            Ok(Value::Bytes(reader.take(length)?.to_vec()))
        }
        tag => Err(VmError::InvalidValueTag(tag)),
    }
}

fn decode_code(reader: &mut Reader<'_>, depth: usize) -> Result<(), VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::ResourceFault);
    }
    let count = reader.leb128()?;
    if count > MAX_INSTRUCTIONS {
        return Err(VmError::ResourceFault);
    }
    let count = usize::try_from(count).map_err(|_| VmError::ResourceFault)?;
    for _ in 0..count {
        let opcode = reader.byte()?;
        match opcode {
            0 => {
                decode_value(reader)?;
            }
            1 => {
                decode_code(reader, depth + 1)?;
                let captures = reader.leb128()?;
                for _ in 0..captures {
                    decode_value(reader)?;
                }
            }
            2 => {
                reader.leb128()?;
            }
            3..=10 => {}
            11 | 12 => {
                let length = reader.leb128()?;
                if length > MAX_BYTES {
                    return Err(VmError::ResourceFault);
                }
                let length = usize::try_from(length).map_err(|_| VmError::ResourceFault)?;
                reader.take(length)?;
            }
            other => return Err(VmError::UnknownOpcode(other)),
        }
    }
    Ok(())
}

fn unzigzag(value: u64) -> i64 {
    ((value >> 1) as i64) ^ -((value & 1) as i64)
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
        let end = self.position.checked_add(count).ok_or(VmError::Truncated)?;
        let bytes = self
            .bytes
            .get(self.position..end)
            .ok_or(VmError::Truncated)?;
        self.position = end;
        Ok(bytes)
    }
    fn leb128(&mut self) -> Result<u64, VmError> {
        let mut value = 0u64;
        for index in 0..10 {
            let byte = self.byte()?;
            let payload = u64::from(byte & 0x7f);
            if index == 9 && (byte & 0x80 != 0 || payload > 1) {
                return Err(VmError::InvalidLeb128);
            }
            value |= payload << (index * 7);
            if byte & 0x80 == 0 {
                if index > 0 && payload == 0 && value < (1 << (index * 7)) {
                    return Err(VmError::InvalidLeb128);
                }
                return Ok(value);
            }
        }
        Err(VmError::InvalidLeb128)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloc::vec;

    #[test]
    fn smoke_program_decodes_and_executes() {
        let image = decode(&smoke_image()).expect("valid smoke image");
        assert_eq!(execute(&image), Ok(vec![Value::Int(42)]));
    }

    #[test]
    fn invalid_headers_are_rejected() {
        let mut bytes = smoke_image();
        bytes[0] = b'X';
        assert_eq!(decode(&bytes), Err(VmError::InvalidMagic));
        let mut bytes = smoke_image();
        bytes[4] = 2;
        assert_eq!(decode(&bytes), Err(VmError::UnsupportedFormat(2)));
        let mut bytes = Vec::from(*MAGIC);
        bytes.extend([0x81, 0x00]);
        assert_eq!(decode(&bytes), Err(VmError::InvalidLeb128));
    }

    #[test]
    fn invalid_operations_are_rejected() {
        let mut bytes = smoke_image();
        bytes[7] = 0x7f;
        assert_eq!(decode(&bytes), Err(VmError::UnknownOpcode(0x7f)));
        let mut bytes = smoke_image();
        bytes.pop();
        assert_eq!(decode(&bytes), Err(VmError::Truncated));
    }

    #[test]
    fn stack_fault_is_reported() {
        let mut bytes = Vec::from(*MAGIC);
        bytes.extend([FORMAT_VERSION as u8, GAMMA_VERSION as u8]);
        bytes.extend([1, 3]);
        let image = decode(&bytes).expect("valid encoding");
        assert_eq!(execute(&image), Err(VmError::StackFault));
    }
}

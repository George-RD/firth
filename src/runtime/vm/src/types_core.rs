pub const FORMAT_VERSION: u16 = 1;
pub const GAMMA_VERSION: u64 = 1;

/// The ownership class assigned by the kernel type system.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Usage {
    Many,
    Linear,
}

impl Usage {
    fn meet(self, other: Self) -> Self {
        if matches!(self, Self::Linear) || matches!(other, Self::Linear) {
            Self::Linear
        } else {
            Self::Many
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Value {
    Int(i64),
    Bool(bool),
    Bytes(Vec<u8>),
    Quotation(Quotation),
    PrimitiveValue {
        tag: u64,
        bytes: Vec<u8>,
    },
    /// Administrative World capture. It is never reported as a language value.
    World,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Quotation {
    pub code: Vec<Instruction>,
    pub captures: Vec<Value>,
    pub consumed: Vec<bool>,
}

impl Quotation {
    /// A quotation owns a capture exactly when one of its captures is linear.
    pub fn usage(&self, registry: &PrimitiveRegistry) -> Usage {
        self.captures.iter().fold(Usage::Many, |usage, value| {
            usage.meet(value.usage(registry))
        })
    }
}

impl Value {
    /// Returns the encoded value's declared ownership class.
    pub fn usage(&self, registry: &PrimitiveRegistry) -> Usage {
        match self {
            Self::Quotation(quotation) => quotation.usage(registry),
            Self::PrimitiveValue { tag, .. } => registry.value_usage(*tag).unwrap_or(Usage::Linear),
            Self::World => Usage::Linear,
            Self::Int(_) | Self::Bool(_) | Self::Bytes(_) => Usage::Many,
        }
    }
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

/// One row from the Lean reference interpreter's differential corpus.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FixtureCase {
    pub name: String,
    pub initial_stack: Vec<Value>,
    pub image: Image,
    pub outcome: String,
    pub final_stack: String,
    pub lean_cost: u64,
    pub residual_frames: String,
    pub target_cost: u64,
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
    UnknownPrimitive(String),
    TypeFault,
    ResourceFault,
    AllocationFailure,
    PrimitiveFault,
    StackFault,
    WorldFault,
}

impl VmError {
    pub fn stable_code(&self) -> &'static str {
        match self {
            Self::Truncated
            | Self::InvalidLeb128
            | Self::NonCanonicalLeb128
            | Self::InputTooLarge
            | Self::InstructionLimit
            | Self::NestingLimit
            | Self::LengthLimit
            | Self::UnsupportedFormat(_)
            | Self::UnsupportedGamma(_)
            | Self::InvalidUtf8
            | Self::InvalidIdentifier
            | Self::InvalidWordType
            | Self::InvalidValueTag(_)
            | Self::InvalidLiteralEncoding
            | Self::InvalidBoolean(_)
            | Self::InvalidPrimitiveTag
            | Self::InvalidOpcode(_)
            | Self::InvalidDigestLength
            | Self::InvalidDigest
            | Self::InvalidCaptureBitmap
            | Self::InvalidCaptureIndex(_)
            | Self::TrailingBytes => "malformed-instruction",
            Self::FuelExhausted => "fuel-exhausted",
            Self::UnknownWord(_) => "unknown-word",
            Self::UnknownPrimitive(_) => "unknown-primitive",
            Self::TypeFault => "type-fault",
            Self::ResourceFault => "resource-fault",
            Self::AllocationFailure => "resource-fault",
            Self::PrimitiveFault | Self::WorldFault => "primitive-fault",
            Self::StackFault => "stack-fault",
            Self::DuplicateWord | Self::UnsortedWords | Self::UnsupportedOperation(_) => {
                "malformed-instruction"
            }
        }
    }

    pub fn stable_subcode(&self) -> &'static str {
        if matches!(self, Self::AllocationFailure) {
            "allocation-failure"
        } else {
            ""
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TrapLocation {
    pub word: String,
    pub pc: usize,
    pub image_version: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Trap {
    pub code: &'static str,
    pub error: VmError,
    pub location: Option<TrapLocation>,
    pub stack: Vec<Value>,
    pub world: WorldState,
    pub cost: CostReport,
    pub trace: Vec<TraceEvent>,
    pub frames: Vec<FrameTrace>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionOutcome {
    Complete(ExecutionReport),
    Trap(Trap),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CostReport {
    pub total: u64,
    pub instructions: u64,
    pub word_entries: u64,
    pub primitives: u64,
    pub steps: Vec<CostStep>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CostStep {
    pub cost: u64,
    pub word: String,
    pub pc: usize,
    pub image_version: u64,
    pub primitive: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExecutionReport {
    pub stack: Vec<Value>,
    pub cost: CostReport,
    pub trace: Vec<TraceEvent>,
    pub world: WorldState,
    pub frames: Vec<FrameTrace>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WorldState {
    observation: Vec<u8>,
    active: bool,
}

impl WorldState {
    pub fn new() -> Self {
        Self {
            observation: vec![0],
            active: false,
        }
    }

    pub fn observation(&self) -> &[u8] {
        &self.observation
    }
}

impl Default for WorldState {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TraceEvent {
    pub word: String,
    pub pc: usize,
    pub image_version: u64,
    pub stack: Vec<Value>,
    pub cost: u64,
    pub format_version: u16,
    pub gamma_version: u64,
    pub world_observation: Vec<u8>,
    pub frames: Vec<FrameTrace>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrameTrace {
    pub word: String,
    pub pc: usize,
    pub code_digest: Vec<u8>,
    pub captures: Vec<bool>,
    pub capture_values: Vec<Value>,
    pub saved: Vec<Value>,
    pub continuation: Continuation,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Continuation {
    Halt,
    Return,
    RestoreDip,
}

pub struct PrimitiveContext<'a> {
    stack: &'a mut Vec<Slot>,
    world: &'a mut WorldState,
}

impl PrimitiveContext<'_> {
    pub fn pop_int(&mut self) -> Result<i64, VmError> {
        pop_int_from(self.stack)
    }

    pub fn push_int(&mut self, value: i64) -> Result<(), VmError> {
        reserve(self.stack, 1)?;
        self.stack.push(Slot::Value(Value::Int(value)));
        Ok(())
    }

    pub fn make_world(&mut self) -> Result<(), VmError> {
        if self.world.active {
            return Err(VmError::WorldFault);
        }
        reserve(self.stack, 1)?;
        self.world.active = true;
        self.stack.push(Slot::WorldMarker);
        Ok(())
    }

    pub fn consume_world(&mut self) -> Result<(), VmError> {
        match self.stack.pop().ok_or(VmError::StackFault)? {
            Slot::WorldMarker => {
                if !self.world.active {
                    return Err(VmError::WorldFault);
                }
                reserve(&mut self.world.observation, 1)?;
                self.world.active = false;
                self.world.observation.push(1);
                Ok(())
            }
            Slot::Value(_) => Err(VmError::TypeFault),
        }
    }
}

pub type PrimitiveHandler = for<'a> fn(&mut PrimitiveContext<'a>) -> Result<(), VmError>;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PrimitiveType {
    Int,
    Bool,
    Bytes,
    Quotation,
    World,
    Any,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PrimitiveSignature {
    pub input: &'static [PrimitiveType],
    pub output: &'static [PrimitiveType],
}

#[derive(Clone, Copy)]
pub struct PrimitiveDefinition {
    pub name: &'static str,
    pub cost: u64,
    pub handler: PrimitiveHandler,
    pub input: &'static [Usage],
    pub output: &'static [Usage],
    pub world: bool,
    pub value_tags: &'static [(u64, Usage)],
}

impl PrimitiveDefinition {
    pub fn signature(&self) -> PrimitiveSignature {
        match self.name {
            "addNat" => PrimitiveSignature {
                input: &[PrimitiveType::Int, PrimitiveType::Int],
                output: &[PrimitiveType::Int],
            },
            "makeWorld" => PrimitiveSignature {
                input: &[],
                output: &[PrimitiveType::World],
            },
            "consumeWorld" => PrimitiveSignature {
                input: &[PrimitiveType::World],
                output: &[],
            },
            _ => PrimitiveSignature {
                input: &[],
                output: &[],
            },
        }
    }
}

#[derive(Clone)]
pub struct PrimitiveRegistry {
    pub version: u64,
    pub definitions: Vec<PrimitiveDefinition>,
}

impl PrimitiveRegistry {
    fn value_usage(&self, tag: u64) -> Option<Usage> {
        self.definitions
            .iter()
            .flat_map(|definition| definition.value_tags)
            .find(|(value_tag, _)| *value_tag == tag)
            .map(|(_, usage)| *usage)
    }
}


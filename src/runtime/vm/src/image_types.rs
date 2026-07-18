use alloc::sync::Arc;
use std::sync::RwLock;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WordPatch {
    pub name: String,
    pub expected_image_version: u64,
    pub expected_body_digest: Vec<u8>,
    pub erased_word_type: String,
    pub code: Vec<Instruction>,
    pub body_digest: Vec<u8>,
    pub kernel_evidence_digest: Vec<u8>,
    pub refinement_evidence_digest: Vec<u8>,
}

#[derive(Debug, Clone, Copy)]
pub struct PatchEvidence<'a> {
    pub expected_image_version: u64,
    pub old_word: &'a WordEntry,
    pub replacement: &'a WordPatch,
}

/// Authenticates external proof artefacts before the VM may publish a patch.
pub trait PatchVerifier {
    fn verify(&self, evidence: &PatchEvidence<'_>) -> bool;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ImageError {
    InvalidImage(VmError),
    MissingWord(String),
    StaleImage { expected: u64, actual: u64 },
    StaleWord,
    WordTypeMismatch,
    InvalidBodyDigest,
    InvalidEvidenceDigest,
    EffectfulWord,
    UnknownReference(String),
    UnknownPrimitive(String),
    UnprovenPatch,
    VersionExhausted,
    GenerationExhausted,
    AllocationFailure,
    RollbackUnavailable(u64),
    LockPoisoned,
}

impl ImageError {
    pub fn stable_code(&self) -> &'static str {
        match self {
            Self::AllocationFailure => "resource-fault",
            Self::InvalidImage(_)
            | Self::MissingWord(_)
            | Self::StaleImage { .. }
            | Self::StaleWord
            | Self::WordTypeMismatch
            | Self::InvalidBodyDigest
            | Self::InvalidEvidenceDigest
            | Self::EffectfulWord
            | Self::UnknownReference(_)
            | Self::UnknownPrimitive(_)
            | Self::UnprovenPatch
            | Self::VersionExhausted
            | Self::GenerationExhausted
            | Self::RollbackUnavailable(_)
            | Self::LockPoisoned => "patch-fault",
        }
    }

    pub fn stable_subcode(&self) -> &'static str {
        match self {
            Self::InvalidImage(_) => "invalid-image",
            Self::MissingWord(_) => "missing-word",
            Self::StaleImage { .. } => "stale-image",
            Self::StaleWord => "stale-word",
            Self::WordTypeMismatch => "word-type-mismatch",
            Self::InvalidBodyDigest => "invalid-body-digest",
            Self::InvalidEvidenceDigest => "invalid-evidence-digest",
            Self::EffectfulWord => "effectful-word",
            Self::UnknownReference(_) => "unknown-reference",
            Self::UnknownPrimitive(_) => "unknown-primitive",
            Self::UnprovenPatch => "unproven-patch",
            Self::VersionExhausted => "version-exhausted",
            Self::GenerationExhausted => "generation-exhausted",
            Self::AllocationFailure => "allocation-failure",
            Self::RollbackUnavailable(_) => "rollback-unavailable",
            Self::LockPoisoned => "lock-poisoned",
        }
    }
}

impl From<VmError> for ImageError {
    fn from(error: VmError) -> Self {
        Self::InvalidImage(error)
    }
}

#[derive(Debug, Clone)]
pub struct ImageHandle {
    image: Arc<Image>,
}

impl ImageHandle {
    pub fn image(&self) -> &Image {
        &self.image
    }

    pub fn image_version(&self) -> u64 {
        self.image.image_version
    }

    pub fn image_digest(&self) -> &[u8] {
        &self.image.image_digest
    }

    pub fn lookup(&self, name: &str) -> Result<WordHandle, ImageError> {
        let index = self
            .image
            .words
            .binary_search_by(|word| word.name.as_str().cmp(name))
            .map_err(|_| ImageError::MissingWord(String::from(name)))?;
        Ok(WordHandle {
            image: Arc::clone(&self.image),
            index,
        })
    }
}

#[derive(Debug, Clone)]
pub struct WordHandle {
    image: Arc<Image>,
    index: usize,
}

impl WordHandle {
    pub fn image(&self) -> &Image {
        &self.image
    }

    pub fn entry(&self) -> &WordEntry {
        &self.image.words[self.index]
    }

    pub fn image_version(&self) -> u64 {
        self.image.image_version
    }
}

#[derive(Clone)]
pub struct ImageStore {
    state: Arc<RwLock<ImageState>>,
}

struct ImageState {
    active: Arc<Image>,
    retired: Vec<RetiredImage>,
}

struct RetiredImage {
    image: Arc<Image>,
    retired_at: u64,
}

trait ImageAllocation {
    fn copy_words(&self, words: &[WordEntry]) -> Result<Vec<WordEntry>, ImageError>;
}

struct GlobalImageAllocation;

impl ImageAllocation for GlobalImageAllocation {
    fn copy_words(&self, words: &[WordEntry]) -> Result<Vec<WordEntry>, ImageError> {
        let mut copy = Vec::new();
        copy.try_reserve_exact(words.len())
            .map_err(|_| ImageError::AllocationFailure)?;
        copy.extend_from_slice(words);
        Ok(copy)
    }
}

#[cfg(test)]
struct FailingImageAllocation;

#[cfg(test)]
impl ImageAllocation for FailingImageAllocation {
    fn copy_words(&self, _words: &[WordEntry]) -> Result<Vec<WordEntry>, ImageError> {
        Err(ImageError::AllocationFailure)
    }
}

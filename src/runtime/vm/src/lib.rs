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

include!("types.rs");
include!("fixtures.rs");
include!("decode.rs");
include!("execute.rs");
include!("validation.rs");
include!("syntax.rs");
include!("encoding.rs");

#[cfg(test)]
mod tests {
    include!("tests.rs");
}

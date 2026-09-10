#![cfg_attr(not(feature = "std"), no_std)]
#![forbid(unsafe_code)]

//! Bounded decoder and bootstrap executor for the frozen Firth v0.1 image.
//! The wire format here is the canonical format in `target-spec.md` §7.

extern crate alloc;

#[cfg(feature = "std")]
extern crate std;

use alloc::{string::String, string::ToString, vec, vec::Vec};

const MAX_INSTRUCTIONS: u64 = 4096;
const MAX_BYTES: usize = 1 << 20;
const MAX_NESTING: usize = 32;
const MAX_WORD_TYPE_NESTING: usize = 32;
const DIGEST_BYTES: usize = 32;
pub const DEFAULT_FUEL: u64 = MAX_INSTRUCTIONS;
/// The largest fuel budget the adapter and the CLI accept. Every pinned gate
/// runs at or below it, and with `MAX_CALL_DEPTH` it bounds the trace to
/// `MAX_FUEL` events of at most `MAX_CALL_DEPTH` frames each.
pub const MAX_FUEL: u64 = DEFAULT_FUEL;
/// The deepest administrative call-frame stack the hosted executor admits.
/// Entering one more frame traps with `resource-fault/call-depth-exceeded`
/// instead of exhausting the native stack. This is a hosted-VM bound that the
/// reference interpreter does not have: a deeper program is a one-sided trap.
pub const MAX_CALL_DEPTH: usize = 256;
/// The most bytes the CLI reads from an image file or from `vm-run` stdin.
/// Equal to the wire decoder's own bound, so an oversize input is classified
/// as `InputTooLarge` rather than buffered first.
pub const MAX_INPUT_BYTES: usize = MAX_BYTES;
/// The JSON nesting bound of the adapter transport. A level-`k` quotation
/// object sits at JSON depth `3k + 3` and its literal operands at `3k + 6`, so
/// this admits every structure the sealed-image decoder admits (`MAX_NESTING`)
/// and leaves the decoder as the sole authority on quotation depth.
const MAX_TRANSPORT_NESTING: usize = 3 * MAX_NESTING + 8;

include!("types.rs");
include!("fixtures.rs");
include!("decode.rs");
include!("word_resolver.rs");
include!("execute.rs");
include!("execute_steps.rs");
include!("resource_bounds.rs");
include!("validation.rs");
include!("syntax.rs");
include!("encoding.rs");
include!("image_encoding.rs");
include!("conformance.rs");
include!("conformance_render.rs");
include!("conformance_observe.rs");
include!("json.rs");
include!("adapter.rs");
include!("adapter_request.rs");
include!("adapter_response.rs");

#[cfg(feature = "std")]
include!("image_types.rs");
#[cfg(feature = "std")]
include!("image_bounds.rs");
#[cfg(feature = "std")]
include!("image_patch.rs");
#[cfg(feature = "std")]
include!("image_store.rs");

#[cfg(test)]
mod tests {
    include!("tests.rs");
}

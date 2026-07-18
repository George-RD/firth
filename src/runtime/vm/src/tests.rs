    use super::*;
    use alloc::format;
    use alloc::string::ToString;
    use alloc::vec;

include!("tests_basic.rs");
include!("tests_execution.rs");
include!("tests_conformance.rs");
include!("tests_fixtures.rs");

#[cfg(feature = "std")]
include!("tests_image.rs");
#[cfg(feature = "std")]
include!("tests_patch_validation.rs");
#[cfg(feature = "std")]
include!("tests_image_concurrency.rs");

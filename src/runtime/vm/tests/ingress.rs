//! Direct Rust values must meet the same bounds as decoded image bytes.
//! All probes use public crate APIs, including when the VM is built no_std.

use firth_vm::{
    ExecutionOutcome, Image, Instruction, Op, Operand, Quotation, Value, VmError,
    WordEntry, body_digest, decode, default_registry, encode_image, evidence_digest,
    execute, execute_diagnostic, execute_diagnostic_entry, execute_diagnostic_with_stack,
    execute_report_entry, execute_report_with_stack, execute_with_fuel, seal_image,
};
#[cfg(feature = "std")]
use firth_vm::{ImageError, ImageStore};

const LIMIT: usize = 4096;
const BYTES: usize = 1 << 20;
const DEPTH: usize = 32;

fn literal(value: Value) -> Instruction {
    Instruction { op: Op::PushLiteral, operand: Some(Operand::Literal(value)) }
}

fn quote(value: Quotation) -> Instruction {
    Instruction { op: Op::PushQuote, operand: Some(Operand::Quote(value)) }
}

fn word(name: &str, code: Vec<Instruction>) -> WordEntry {
    WordEntry {
        name: name.to_owned(),
        erased_word_type: "(--)".to_owned(),
        body_digest: body_digest(&code),
        code,
        kernel_evidence_digest: evidence_digest(b"test content, not proof"),
        refinement_evidence_digest: evidence_digest(b"test content, not proof"),
        generation: 0,
    }
}

fn image(code: Vec<Instruction>) -> Image {
    seal_image(1, vec![word("main", code)])
}

fn empty_quote() -> Quotation {
    Quotation { code: vec![], captures: vec![], consumed: vec![] }
}

fn assert_empty_trap(outcome: ExecutionOutcome, expected: VmError) {
    let ExecutionOutcome::Trap(trap) = outcome else {
        panic!("invalid input was executed")
    };
    assert_eq!(trap.error, expected);
    assert_eq!(trap.cost.total, 0);
    assert!(trap.cost.steps.is_empty());
    assert!(trap.trace.is_empty());
    assert!(trap.frames.is_empty());
    assert!(trap.stack.is_empty());
    assert!(trap.location.is_none());
    assert_eq!(trap.world.observation(), &[0]);
}

fn assert_image_rejected(image: Image, expected: VmError) {
    assert_eq!(execute(&image).err(), Some(expected.clone()));
    assert_eq!(execute_with_fuel(&image, 0).err(), Some(expected.clone()));
    assert_eq!(
        execute_report_entry(&image, "main", vec![], 0, &default_registry()).err(),
        Some(expected.clone())
    );
    assert_empty_trap(execute_diagnostic(&image, 0, &default_registry()), expected.clone());
    assert_empty_trap(
        execute_diagnostic_entry(&image, "main", vec![], 0, &default_registry(), None),
        expected.clone(),
    );
    #[cfg(feature = "std")]
    assert!(matches!(ImageStore::new(image), Err(ImageError::InvalidImage(error)) if error == expected));
}

fn assert_stack_rejected(stack: Vec<Value>, expected: VmError) {
    let image = image(vec![]);
    assert_eq!(
        execute_report_with_stack(&image, stack.clone(), 0, &default_registry()).err(),
        Some(expected.clone())
    );
    assert_empty_trap(
        execute_diagnostic_with_stack(&image, stack, 0, &default_registry()),
        expected,
    );
}

#[test]
fn oversized_word_code_is_refused_before_fuel() {
    let image = image(vec![Instruction { op: Op::Drop, operand: None }; LIMIT + 1]);
    assert_eq!(decode(&encode_image(&image)), Err(VmError::InstructionLimit));
    assert_image_rejected(image, VmError::InstructionLimit);
}

#[test]
fn oversized_dictionary_is_refused_before_lookup() {
    let mut words = vec![word("main", vec![])];
    words.extend((0..LIMIT).map(|index| word(&format!("w{index:04}"), vec![])));
    let image = seal_image(1, words);
    assert_eq!(decode(&encode_image(&image)), Err(VmError::InstructionLimit));
    assert_eq!(
        execute_report_entry(&image, "missing", vec![], 0, &default_registry()),
        Err(VmError::InstructionLimit)
    );
    assert_image_rejected(image, VmError::InstructionLimit);
}

#[test]
fn oversized_literal_is_refused_before_hashing() {
    let image = image(vec![literal(Value::Bytes(vec![0; BYTES + 1]))]);
    assert_eq!(decode(&encode_image(&image)), Err(VmError::InputTooLarge));
    assert_image_rejected(image, VmError::LengthLimit);
}

#[test]
fn individually_valid_literals_share_one_image_budget() {
    let image = image(vec![
        literal(Value::Bytes(vec![0; BYTES / 2])),
        literal(Value::Bytes(vec![0; BYTES / 2])),
    ]);
    assert_image_rejected(image, VmError::LengthLimit);
}

#[test]
fn unused_helpers_share_the_image_budget() {
    let image = seal_image(1, vec![
        word("main", vec![]),
        word("unused_a", vec![literal(Value::Bytes(vec![0; BYTES / 2]))]),
        word("unused_b", vec![literal(Value::Bytes(vec![0; BYTES / 2]))]),
    ]);
    assert_image_rejected(image, VmError::LengthLimit);
}

#[test]
fn nested_code_vectors_cannot_bypass_the_limit() {
    let mut quotation = empty_quote();
    quotation.code = vec![Instruction { op: Op::Drop, operand: None }; LIMIT + 1];
    assert_image_rejected(image(vec![quote(quotation.clone())]), VmError::InstructionLimit);
    assert_stack_rejected(vec![Value::Quotation(quotation)], VmError::InstructionLimit);
}

#[test]
fn quotation_capture_vectors_cannot_bypass_the_limit() {
    let mut quotation = empty_quote();
    quotation.captures = vec![Value::Bool(false); LIMIT + 1];
    quotation.consumed = vec![false; LIMIT + 1];
    assert_image_rejected(image(vec![quote(quotation.clone())]), VmError::InstructionLimit);
    assert_stack_rejected(vec![Value::Quotation(quotation)], VmError::InstructionLimit);
}

#[test]
fn initial_stack_count_is_bounded_even_without_instructions() {
    assert_stack_rejected(vec![Value::Int(0); LIMIT + 1], VmError::InstructionLimit);
}

#[test]
fn initial_stack_bytes_are_bounded_even_without_instructions() {
    assert_stack_rejected(vec![Value::Bytes(vec![0; BYTES])], VmError::LengthLimit);
}

#[test]
fn individually_valid_inputs_share_one_stack_budget() {
    assert_stack_rejected(
        vec![Value::Bytes(vec![0; BYTES / 2]), Value::Bytes(vec![0; BYTES / 2])],
        VmError::LengthLimit,
    );
}

#[test]
fn nested_input_captures_share_the_stack_budget() {
    let quotation = Quotation {
        captures: vec![Value::Bytes(vec![0; BYTES / 2]), Value::Bytes(vec![0; BYTES / 2])],
        consumed: vec![false; 2],
        ..empty_quote()
    };
    assert_stack_rejected(vec![Value::Quotation(quotation)], VmError::LengthLimit);
}

#[test]
fn unused_initial_capture_indices_are_checked() {
    let invalid = Quotation {
        code: vec![Instruction { op: Op::PushCapture, operand: Some(Operand::Capture(0)) }],
        ..empty_quote()
    };
    assert_stack_rejected(vec![Value::Quotation(invalid.clone())], VmError::InvalidCaptureIndex(0));
    let nested = Quotation {
        captures: vec![Value::Quotation(invalid)],
        consumed: vec![false],
        ..empty_quote()
    };
    assert_stack_rejected(vec![Value::Quotation(nested)], VmError::InvalidCaptureIndex(0));
}

#[test]
fn malformed_capture_bitmap_is_rejected_before_hashing() {
    for quotation in [
        Quotation { captures: vec![Value::Int(1)], ..empty_quote() },
        Quotation { consumed: vec![true], ..empty_quote() },
    ] {
        // Do not invoke an unchecked construction helper on malformed state.
        let mut image = image(vec![]);
        image.words[0].code = vec![quote(quotation.clone())];
        assert_image_rejected(image, VmError::InvalidCaptureBitmap);
        assert_stack_rejected(vec![Value::Quotation(quotation)], VmError::InvalidCaptureBitmap);
    }
}

#[test]
fn large_metadata_is_rejected_before_identity_hashing() {
    let mut image = image(vec![]);
    image.words[0].kernel_evidence_digest = vec![1; BYTES + 1];
    assert_image_rejected(image, VmError::LengthLimit);
}

#[test]
fn exact_image_byte_limit_is_accepted_and_the_next_byte_is_not() {
    // Compute the fixed overhead using a payload in the same LEB128 width.
    let probe = image(vec![literal(Value::Bytes(vec![0; BYTES / 2]))]);
    let overhead = encode_image(&probe).len() - BYTES / 2;
    let image = image(vec![literal(Value::Bytes(vec![0; BYTES - overhead]))]);
    assert_eq!(encode_image(&image).len(), BYTES);
    assert_eq!(decode(&encode_image(&image)), Ok(image.clone()));
    assert_eq!(execute_with_fuel(&image, 0), Err(VmError::FuelExhausted));
    #[cfg(feature = "std")]
    assert!(ImageStore::new(image).is_ok());

    let too_large = self::image(vec![literal(Value::Bytes(vec![0; BYTES - overhead + 1]))]);
    assert_eq!(encode_image(&too_large).len(), BYTES + 1);
    assert_image_rejected(too_large, VmError::LengthLimit);
}

#[test]
fn exact_input_byte_and_vector_limits_are_accepted() {
    let image = image(vec![]);
    // Vector count (1), value tag (1), payload length (3), then payload bytes.
    let stack = vec![Value::Bytes(vec![0; BYTES - 5])];
    assert_eq!(
        execute_report_with_stack(&image, stack.clone(), 0, &default_registry()).unwrap().stack,
        stack
    );
    let stack = vec![Value::Int(0); LIMIT];
    assert_eq!(
        execute_report_with_stack(&image, stack.clone(), 0, &default_registry()).unwrap().stack,
        stack
    );
    assert_stack_rejected(vec![Value::Bytes(vec![0; BYTES - 4])], VmError::LengthLimit);
}

fn nested_code(depth: usize) -> Vec<Instruction> {
    let mut code = vec![];
    for _ in 0..depth {
        code = vec![quote(Quotation { code, ..empty_quote() })];
    }
    code
}

fn nested_capture(depth: usize) -> Value {
    let mut value = Value::Int(7);
    for _ in 0..depth {
        value = Value::Quotation(Quotation {
            captures: vec![value], consumed: vec![false], ..empty_quote()
        });
    }
    value
}

#[test]
fn deepest_valid_code_validates_without_exponential_walk() {
    // The deadline wrapper runs this exact public-API test in another process.
    let image = image(nested_code(DEPTH));
    assert_eq!(decode(&encode_image(&image)), Ok(image.clone()));
    assert_eq!(execute_with_fuel(&image, 0), Err(VmError::FuelExhausted));
    #[cfg(feature = "std")]
    assert!(ImageStore::new(image).is_ok());
}

#[test]
fn deepest_valid_capture_matches_the_binary_decoder() {
    let value = nested_capture(DEPTH);
    let Value::Quotation(quotation) = &value else { panic!("quotation required") };
    let quoted_image = image(vec![quote(quotation.clone())]);
    assert_eq!(decode(&encode_image(&quoted_image)), Ok(quoted_image.clone()));
    assert_eq!(execute_with_fuel(&quoted_image, 0), Err(VmError::FuelExhausted));
    let stack = vec![value];
    assert_eq!(
        execute_report_with_stack(&image(vec![]), stack.clone(), 0, &default_registry()).unwrap().stack,
        stack
    );
}

#[test]
fn excessive_code_and_capture_depth_is_rejected() {
    assert_image_rejected(image(nested_code(DEPTH + 1)), VmError::NestingLimit);
    assert_stack_rejected(vec![nested_capture(DEPTH + 1)], VmError::NestingLimit);
}

#[test]
fn valid_capture_indices_and_bitmap_at_the_vector_limit_are_accepted() {
    let quotation = Quotation {
        code: vec![Instruction { op: Op::PushCapture, operand: Some(Operand::Capture((LIMIT - 1) as u64)) }],
        captures: vec![Value::Bool(false); LIMIT],
        consumed: vec![false; LIMIT],
    };
    let stack = vec![Value::Quotation(quotation)];
    assert_eq!(
        execute_report_with_stack(&image(vec![]), stack.clone(), 0, &default_registry()).unwrap().stack,
        stack
    );
}

//! `PICK n` and `ROLL n`, through the public API.
//!
//! Each reaches a value `n` places below the top in one step, so a named
//! local costs the same to read however deep it sits.

use firth_vm::{
    DEFAULT_FUEL, ExecutionOutcome, Image, Instruction, Op, Operand, Value, WordEntry, body_digest,
    decode, default_registry, encode_image, evidence_digest, execute_diagnostic_with_stack,
    seal_image,
};

fn shuffle(op: Op, depth: u64) -> Instruction {
    Instruction {
        op,
        operand: Some(Operand::Depth(depth)),
    }
}

fn image(code: Vec<Instruction>) -> Image {
    seal_image(
        1,
        vec![WordEntry {
            name: "main".to_owned(),
            erased_word_type: "(--)".to_owned(),
            body_digest: body_digest(&code),
            code,
            kernel_evidence_digest: evidence_digest(b"test content, not proof"),
            refinement_evidence_digest: evidence_digest(b"test content, not proof"),
            generation: 0,
        }],
    )
}

fn ints(values: &[i64]) -> Vec<Value> {
    values.iter().copied().map(Value::Int).collect()
}

fn run(code: Vec<Instruction>, stack: Vec<Value>) -> ExecutionOutcome {
    execute_diagnostic_with_stack(&image(code), stack, DEFAULT_FUEL, &default_registry())
}

#[test]
fn pick_copies_the_value_below_and_costs_one_step() {
    // Bottom to top 1 2 3 4: `pick 3` copies the 1 to the top.
    let ExecutionOutcome::Complete(report) = run(vec![shuffle(Op::Pick, 3)], ints(&[1, 2, 3, 4]))
    else {
        panic!("pick completes")
    };
    assert_eq!(report.stack, ints(&[1, 2, 3, 4, 1]));
    assert_eq!(report.trace.len(), 1);
}

#[test]
fn roll_moves_the_value_below_and_keeps_the_others_in_order() {
    let ExecutionOutcome::Complete(report) = run(vec![shuffle(Op::Roll, 3)], ints(&[1, 2, 3, 4]))
    else {
        panic!("roll completes")
    };
    assert_eq!(report.stack, ints(&[2, 3, 4, 1]));
    assert_eq!(report.trace.len(), 1);
}

#[test]
fn depth_zero_is_dup_and_the_identity() {
    let ExecutionOutcome::Complete(picked) = run(vec![shuffle(Op::Pick, 0)], ints(&[5])) else {
        panic!("pick 0 completes")
    };
    assert_eq!(picked.stack, ints(&[5, 5]));
    let ExecutionOutcome::Complete(rolled) = run(vec![shuffle(Op::Roll, 0)], ints(&[5, 6])) else {
        panic!("roll 0 completes")
    };
    assert_eq!(rolled.stack, ints(&[5, 6]));
}

#[test]
fn reaching_past_the_bottom_is_a_stack_fault() {
    for op in [Op::Pick, Op::Roll] {
        for depth in [2, u64::MAX] {
            let ExecutionOutcome::Trap(trap) = run(vec![shuffle(op, depth)], ints(&[1, 2])) else {
                panic!("{op:?} {depth} past the bottom traps")
            };
            assert_eq!(trap.code, "stack-fault");
        }
    }
}

#[test]
fn pick_refuses_to_copy_a_linear_value_but_roll_moves_it() {
    // Default tag 1 is linear.
    let linear = Value::PrimitiveValue {
        tag: 1,
        bytes: vec![0],
    };
    let ExecutionOutcome::Trap(trap) = run(
        vec![shuffle(Op::Pick, 1)],
        vec![linear.clone(), Value::Int(2)],
    ) else {
        panic!("copying a linear value traps")
    };
    assert_eq!(trap.code, "resource-fault");
    // Rolling moves it, not a copy: exit then faults on the one linear value
    // left, now on top.
    let ExecutionOutcome::Trap(exit) = run(
        vec![shuffle(Op::Roll, 1)],
        vec![linear.clone(), Value::Int(2)],
    ) else {
        panic!("a linear value left on the stack traps at exit")
    };
    assert_eq!(exit.code, "resource-fault");
    assert_eq!(exit.stack, vec![Value::Int(2), linear]);
}

#[test]
fn the_depth_survives_encoding() {
    let original = image(vec![shuffle(Op::Pick, 300), shuffle(Op::Roll, 7)]);
    let decoded = decode(&encode_image(&original)).expect("the image decodes");
    assert_eq!(decoded.words[0].code, original.words[0].code);
}

//! Tail calls and the natural-number primitives, through the public API.
//!
//! A `CALL`, `IF` or `CALL_WORD` that is the last instruction of a frame
//! replaces that frame, so loops written as tail recursion run in constant
//! frame depth and end on data or on fuel, as in the reference interpreter.

use firth_vm::{
    DEFAULT_FUEL, ExecutionOutcome, Image, Instruction, Op, Operand, Quotation, Value, WordEntry,
    body_digest, default_registry, evidence_digest, execute_diagnostic,
    execute_diagnostic_with_stack, seal_image,
};

fn op(op: Op) -> Instruction {
    Instruction { op, operand: None }
}

fn int(value: i64) -> Instruction {
    Instruction {
        op: Op::PushLiteral,
        operand: Some(Operand::Literal(Value::Int(value))),
    }
}

fn prim(name: &str) -> Instruction {
    Instruction {
        op: Op::Prim,
        operand: Some(Operand::Primitive(name.to_owned())),
    }
}

fn call_main() -> Instruction {
    Instruction {
        op: Op::CallWord,
        operand: Some(Operand::Word("main".to_owned())),
    }
}

fn quote(code: Vec<Instruction>) -> Instruction {
    Instruction {
        op: Op::PushQuote,
        operand: Some(Operand::Quote(Quotation {
            code,
            captures: vec![],
            consumed: vec![],
        })),
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

/// `: main dup 0 = [ ] [ 1 - main ] if ;` counts down to zero.
fn countdown() -> Image {
    image(vec![
        op(Op::Dup),
        int(0),
        prim("eqNat"),
        quote(vec![]),
        quote(vec![int(1), prim("subNat"), call_main()]),
        op(Op::If),
    ])
}

fn run(image: &Image, stack: Vec<Value>) -> ExecutionOutcome {
    execute_diagnostic_with_stack(image, stack, DEFAULT_FUEL, &default_registry())
}

#[test]
fn a_tail_recursive_loop_runs_past_the_call_depth_bound() {
    // 300 iterations of nine instructions and one entry fit the default fuel,
    // and would need 600 frames (word plus branch) if every iteration nested,
    // far past MAX_CALL_DEPTH (256).
    let ExecutionOutcome::Complete(report) = run(&countdown(), vec![Value::Int(300)]) else {
        panic!("a tail-recursive countdown completes")
    };
    assert_eq!(report.stack, vec![Value::Int(0)]);
    assert!(report.trace.iter().all(|event| event.frames.len() <= 2));
}

#[test]
fn unbounded_tail_recursion_stops_on_fuel_in_one_frame() {
    let registry = default_registry();
    for code in [
        vec![call_main()],
        vec![quote(vec![call_main()]), op(Op::Call)],
    ] {
        let ExecutionOutcome::Trap(trap) =
            execute_diagnostic(&image(code), DEFAULT_FUEL, &registry)
        else {
            panic!("unbounded tail recursion must stop on fuel")
        };
        assert_eq!(trap.code, "fuel-exhausted");
        assert!(trap.trace.iter().all(|event| event.frames.len() == 1));
    }
}

#[test]
fn a_quotation_with_unrestricted_captures_is_a_tail_target() {
    // `: main 7 quote call ;` calls a quotation that captured 7.
    let ExecutionOutcome::Complete(report) =
        run(&image(vec![int(7), op(Op::Quote), op(Op::Call)]), vec![])
    else {
        panic!("a captured value is pushed back")
    };
    assert_eq!(report.stack, vec![Value::Int(7)]);
    assert!(report.trace.iter().all(|event| event.frames.len() == 1));
}

#[test]
fn a_call_followed_by_more_code_still_nests() {
    // `: main main 1 ;` is not a tail call and still meets the depth bound.
    let ExecutionOutcome::Trap(trap) = run(&image(vec![call_main(), int(1)]), vec![]) else {
        panic!("non-tail recursion traps")
    };
    assert_eq!(trap.error.stable_subcode(), "call-depth-exceeded");
}

fn binary(name: &str, left: i64, right: i64) -> ExecutionOutcome {
    run(&image(vec![int(left), int(right), prim(name)]), vec![])
}

fn result(outcome: ExecutionOutcome) -> Value {
    match outcome {
        ExecutionOutcome::Complete(report) => {
            assert_eq!(report.stack.len(), 1);
            report.stack[0].clone()
        }
        ExecutionOutcome::Trap(trap) => panic!("unexpected trap {}", trap.code),
    }
}

#[test]
fn natural_primitives_match_the_reference_definitions() {
    assert_eq!(result(binary("subNat", 7, 3)), Value::Int(4));
    // Natural subtraction truncates at zero, as Lean's `Nat.sub` does.
    assert_eq!(result(binary("subNat", 3, 7)), Value::Int(0));
    assert_eq!(result(binary("mulNat", 6, 7)), Value::Int(42));
    assert_eq!(result(binary("ltNat", 2, 3)), Value::Bool(true));
    assert_eq!(result(binary("ltNat", 3, 3)), Value::Bool(false));
    assert_eq!(result(binary("eqNat", 3, 3)), Value::Bool(true));
    assert_eq!(result(binary("eqNat", 3, 4)), Value::Bool(false));
}

#[test]
fn multiplication_past_the_target_integer_faults() {
    let ExecutionOutcome::Trap(trap) = binary("mulNat", i64::MAX, 2) else {
        panic!("overflow must trap")
    };
    assert_eq!(trap.code, "primitive-fault");
}

#[test]
fn a_negative_operand_faults_for_every_natural_primitive() {
    for name in ["addNat", "subNat", "mulNat", "ltNat", "eqNat"] {
        let ExecutionOutcome::Trap(trap) = binary(name, -2, 1) else {
            panic!("{name} accepted a negative operand")
        };
        assert_eq!(trap.code, "primitive-fault", "{name}");
    }
}

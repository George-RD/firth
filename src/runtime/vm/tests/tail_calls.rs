//! Tail calls and the integer and Boolean primitives, through the public API.
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
        prim("eqInt"),
        quote(vec![]),
        quote(vec![int(1), prim("subInt"), call_main()]),
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
fn integer_primitives_match_the_reference_definitions() {
    assert_eq!(result(binary("subInt", 7, 3)), Value::Int(4));
    // Subtraction is signed, as Lean's `Int.sub` is; it no longer truncates.
    assert_eq!(result(binary("subInt", 3, 7)), Value::Int(-4));
    assert_eq!(result(binary("addInt", -2, 1)), Value::Int(-1));
    assert_eq!(result(binary("mulInt", -6, 7)), Value::Int(-42));
    assert_eq!(result(binary("ltInt", -3, 2)), Value::Bool(true));
    assert_eq!(result(binary("mulInt", 6, 7)), Value::Int(42));
    assert_eq!(result(binary("ltInt", 2, 3)), Value::Bool(true));
    assert_eq!(result(binary("ltInt", 3, 3)), Value::Bool(false));
    assert_eq!(result(binary("eqInt", 3, 3)), Value::Bool(true));
    assert_eq!(result(binary("eqInt", 3, 4)), Value::Bool(false));
}

#[test]
fn comparisons_order_every_pair_of_edge_integers() {
    // Written in strictly ascending order, so for positions i and j the
    // expected answers come from the positions, not from the VM's `<`.
    let ascending = [
        i64::MIN,
        i64::MIN + 1,
        -2,
        -1,
        0,
        1,
        2,
        i64::MAX - 1,
        i64::MAX,
    ];
    for (i, &left) in ascending.iter().enumerate() {
        for (j, &right) in ascending.iter().enumerate() {
            for (name, expected) in [
                ("ltInt", i < j),
                ("eqInt", i == j),
                ("leInt", i <= j),
                ("gtInt", i > j),
                ("geInt", i >= j),
            ] {
                assert_eq!(
                    result(binary(name, left, right)),
                    Value::Bool(expected),
                    "{name} {left} {right}"
                );
            }
        }
    }
}

#[test]
fn multiplication_past_the_target_integer_faults() {
    let ExecutionOutcome::Trap(trap) = binary("mulInt", i64::MAX, 2) else {
        panic!("overflow must trap")
    };
    assert_eq!(trap.code, "primitive-fault");
}

#[test]
fn arithmetic_past_either_end_of_the_target_integer_faults() {
    for (name, left, right) in [
        ("addInt", i64::MAX, 1),
        ("addInt", i64::MIN, -1),
        ("subInt", i64::MIN, 1),
        ("subInt", i64::MAX, -1),
        ("mulInt", i64::MIN, -1),
        ("mulInt", i64::MIN, 2),
    ] {
        let ExecutionOutcome::Trap(trap) = binary(name, left, right) else {
            panic!("{name} {left} {right} must trap")
        };
        assert_eq!(trap.code, "primitive-fault", "{name}");
    }
}

#[test]
fn division_and_remainder_are_euclidean() {
    // Hand-computed: a = b*q + r with 0 <= r < |b| (Lean's `Int./` and `Int.%`).
    for (left, right, quotient, remainder) in [
        (7, 2, 3, 1),
        (-7, 2, -4, 1),
        (7, -2, -3, 1),
        (-7, -2, 4, 1),
        (6, 3, 2, 0),
        (0, 5, 0, 0),
        (i64::MIN, 1, i64::MIN, 0),
        (i64::MAX, -1, -i64::MAX, 0),
        (i64::MIN, 2, -4_611_686_018_427_387_904, 0),
        (i64::MIN, i64::MAX, -2, 9_223_372_036_854_775_806),
    ] {
        assert_eq!(
            result(binary("divInt", left, right)),
            Value::Int(quotient),
            "{left} div {right}"
        );
        assert_eq!(
            result(binary("modInt", left, right)),
            Value::Int(remainder),
            "{left} mod {right}"
        );
    }
}

#[test]
fn a_zero_divisor_faults() {
    for name in ["divInt", "modInt"] {
        for left in [7, 0, -7, i64::MIN] {
            let ExecutionOutcome::Trap(trap) = binary(name, left, 0) else {
                panic!("{name} {left} 0 must trap")
            };
            assert_eq!(trap.code, "primitive-fault", "{name} {left}");
        }
    }
}

#[test]
fn the_quotient_past_the_target_integer_faults_but_its_remainder_does_not() {
    // i64::MIN / -1 is 2^63, one past i64::MAX, and faults like `*` does.
    let ExecutionOutcome::Trap(trap) = binary("divInt", i64::MIN, -1) else {
        panic!("i64::MIN div -1 must trap")
    };
    assert_eq!(trap.code, "primitive-fault");
    // The remainder is 0, which is in range, so it is returned.
    assert_eq!(result(binary("modInt", i64::MIN, -1)), Value::Int(0));
}

fn boolean(value: bool) -> Instruction {
    Instruction {
        op: Op::PushLiteral,
        operand: Some(Operand::Literal(Value::Bool(value))),
    }
}

#[test]
fn boolean_primitives_match_the_reference_definitions() {
    for left in [false, true] {
        assert_eq!(
            result(run(&image(vec![boolean(left), prim("notBool")]), vec![])),
            Value::Bool(!left)
        );
        for right in [false, true] {
            let apply = |name| {
                run(
                    &image(vec![boolean(left), boolean(right), prim(name)]),
                    vec![],
                )
            };
            assert_eq!(result(apply("andBool")), Value::Bool(left && right));
            assert_eq!(result(apply("orBool")), Value::Bool(left || right));
        }
    }
}

#[test]
fn boolean_primitives_refuse_an_integer() {
    let ExecutionOutcome::Trap(trap) = run(&image(vec![int(1), prim("notBool")]), vec![]) else {
        panic!("not on an Int must trap")
    };
    assert_eq!(trap.code, "type-fault");
}

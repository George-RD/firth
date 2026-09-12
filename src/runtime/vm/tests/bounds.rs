//! Execution and transport bounds, run case by case under a process deadline
//! by `tools/loop/check_runtime_bounds.py`.
//!
//! On the unchanged runtime the recursion case overflowed the native stack and
//! aborted the whole test process, and the other two cases exceeded their
//! deadlines, so the gate executes each case in its own subprocess rather than
//! letting an abort take a shared test worker down with it. Every probe uses
//! public crate APIs only, in the std and the no_std configuration alike, and
//! only APIs the unchanged runtime also exported, so the gate's baseline mode
//! can compile these exact cases against it: the bounds are named by value
//! and traps by their stable codes. `tests/observations.rs` ties the values
//! to the crate constants.

use firth_vm::{
    ConformanceCostReference, ConformanceReference, ConformanceStatus, ConformanceVerdict,
    DEFAULT_FUEL, ExecutionOutcome, Image, Instruction, Op, Operand, Quotation, TrapLocation,
    Value, WordEntry, body_digest, compare_conformance, default_registry, evidence_digest,
    execute_diagnostic, observe_image, parse_json, seal_image,
};

/// `firth_vm::MAX_CALL_DEPTH`, by value.
const MAX_CALL_DEPTH: usize = 256;
/// `firth_vm::MAX_FUEL`, by value: the default budget is the largest one.
const MAX_FUEL: u64 = DEFAULT_FUEL;

fn literal(value: Value) -> Instruction {
    Instruction {
        op: Op::PushLiteral,
        operand: Some(Operand::Literal(value)),
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

/// Runs `body` on a thread with the 2 MiB native stack the test harness gives
/// its workers, so the pinned depth is shown to fit that stack rather than the
/// larger main-thread stack.
fn on_a_two_mebibyte_stack(body: impl FnOnce() + Send + 'static) {
    std::thread::Builder::new()
        .stack_size(2 << 20)
        .spawn(body)
        .expect("thread starts")
        .join()
        .expect("the bounded execution neither panicked nor overflowed");
}

#[test]
fn self_recursion_at_gate_fuel_traps_with_call_depth_exceeded() {
    on_a_two_mebibyte_stack(|| {
        let registry = default_registry();
        // `CALL_WORD` recursion: the entry frame plus MAX_CALL_DEPTH - 1
        // entered frames, then the next entry is refused.
        let ExecutionOutcome::Trap(trap) =
            execute_diagnostic(&image(vec![call_main()]), MAX_FUEL, &registry)
        else {
            panic!("unbounded recursion must trap, not complete")
        };
        assert_eq!(trap.code, "resource-fault");
        assert_eq!(trap.error.stable_subcode(), "call-depth-exceeded");
        assert_eq!(trap.frames.len(), MAX_CALL_DEPTH);
        assert_eq!(
            trap.location,
            Some(TrapLocation {
                word: "main".to_owned(),
                pc: 0,
                image_version: 1,
            })
        );
        // The refusing CALL_WORD is charged as an instruction; the entry it
        // never made is not charged as a word entry.
        assert_eq!(trap.cost.instructions as usize, MAX_CALL_DEPTH);
        assert_eq!(trap.cost.word_entries as usize, MAX_CALL_DEPTH - 1);
        assert_eq!(trap.cost.total as usize, 2 * MAX_CALL_DEPTH - 1);
        assert_eq!(trap.trace.len(), MAX_CALL_DEPTH);
        assert_eq!(
            trap.trace.last().map(|event| event.frames.len()),
            Some(MAX_CALL_DEPTH)
        );
        assert!(trap.trace.iter().all(|event| event.cost == 1));

        // The `DIP` path holds the most native state per frame; it must fit
        // the same stack at the same depth.
        let dip = image(vec![
            literal(Value::Int(1)),
            quote(vec![call_main()]),
            Instruction {
                op: Op::Dip,
                operand: None,
            },
        ]);
        let ExecutionOutcome::Trap(trap) = execute_diagnostic(&dip, MAX_FUEL, &registry) else {
            panic!("unbounded dip recursion must trap, not complete")
        };
        assert_eq!(trap.error.stable_subcode(), "call-depth-exceeded");
        assert_eq!(trap.frames.len(), MAX_CALL_DEPTH);

        // Cross-host, the reference has no such bound: a deeper program is a
        // one-sided trap and disagrees, never agreement.
        let observed = observe_image(&image(vec![call_main()]), vec![], MAX_FUEL, &registry);
        assert_eq!(observed.status, ConformanceStatus::Trap);
        let terminal = ConformanceReference {
            status: ConformanceStatus::Terminal,
            stack: String::new(),
            frames: "-".to_owned(),
            cost: ConformanceCostReference {
                total: observed.cost.total,
                kernel: observed.cost.kernel,
                breakdown: None,
            },
            world_observation: None,
            trap: None,
        };
        assert!(matches!(
            compare_conformance(&terminal, &observed),
            ConformanceVerdict::Disagree(_)
        ));
    });
}

#[test]
fn a_flat_word_at_gate_fuel_executes_within_the_deadline() {
    // 4096 instructions at fuel 4096: one checkpoint per step must cost the
    // stack, not the whole trace, or this is quadratic in the trace length.
    let code: Vec<Instruction> = (0..MAX_FUEL).map(|_| literal(Value::Int(1))).collect();
    let ExecutionOutcome::Complete(report) =
        execute_diagnostic(&image(code), MAX_FUEL, &default_registry())
    else {
        panic!("a flat word within fuel completes")
    };
    assert_eq!(report.stack.len(), MAX_FUEL as usize);
    assert_eq!(report.cost.total, MAX_FUEL);
    assert_eq!(report.trace.len(), MAX_FUEL as usize);
}

#[test]
fn a_maximal_member_object_parses_within_the_deadline() {
    // 80,000 distinct members just under the byte bound: duplicate detection
    // must be logarithmic per member, not a scan of every earlier member.
    let mut object = String::from("{");
    for index in 0..80_000 {
        if index != 0 {
            object.push(',');
        }
        object.push_str(&format!("\"k{index:05}\":0"));
    }
    object.push('}');
    assert!(object.len() < 1 << 20);
    let parsed = parse_json(&object).expect("a maximal object parses");
    assert_eq!(parsed.member_names().len(), 80_000);
    // The same object with one repeated name at the end is still refused.
    let duplicate = object.replace("\"k79999\":0}", "\"k79999\":0,\"k00000\":1}");
    assert_eq!(
        parse_json(&duplicate).expect_err("a repeated member is refused"),
        firth_vm::JsonError::DuplicateMember
    );
}

//! Public observation regressions. Image hashes in these fixtures are content
//! identifiers, not proof artefacts. None of these tests asserts contract discharge.

use firth_vm::{
    ConformanceCostReference, ConformanceObservation, ConformanceReference, ConformanceStatus,
    ConformanceVerdict, ExecutionOutcome, Image, Instruction, Op, Operand, Quotation, Value,
    VmError, WordEntry, body_digest, compare_conformance, default_registry, evidence_digest,
    execute_diagnostic_entry, execute_report, execute_report_entry, observe_image,
    render_conformance_stack, seal_image,
};
use std::collections::BTreeSet;

fn literal(value: Value) -> Instruction {
    Instruction {
        op: Op::PushLiteral,
        operand: Some(Operand::Literal(value)),
    }
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

fn reference(observed: &ConformanceObservation) -> ConformanceReference {
    ConformanceReference {
        status: observed.status,
        stack: observed.stack.clone(),
        frames: observed.frames.clone(),
        cost: ConformanceCostReference {
            total: observed.cost.total,
            kernel: observed.cost.kernel,
            breakdown: Some(observed.cost.breakdown),
        },
        world_observation: Some(observed.world_observation.clone()),
        trap: observed.trap.clone(),
    }
}

fn assert_stack_disagreement(left: &ConformanceObservation, right: &ConformanceObservation) {
    let ConformanceVerdict::Disagree(mismatches) = compare_conformance(&reference(left), right)
    else {
        panic!("different residual values were reported as agreement")
    };
    assert_eq!(mismatches.len(), 1);
    assert_eq!(mismatches[0].field, "stack");
}

#[test]
fn byte_values_have_exact_lowercase_hex_payloads() {
    for (bytes, expected) in [
        (vec![], "bytes:"),
        (vec![0], "bytes:00"),
        (vec![0, 1, 15, 16, 127, 128, 255], "bytes:00010f107f80ff"),
    ] {
        assert_eq!(
            render_conformance_stack(&[Value::Bytes(bytes)], &default_registry()),
            expected
        );
    }
}

#[test]
fn primitive_values_preserve_full_unsigned_tags_and_payloads() {
    for (tag, bytes, expected) in [
        (0, vec![], "primitive:0:"),
        (1, vec![0], "primitive:1:00"),
        (256, vec![10, 255], "primitive:256:0aff"),
        (
            u64::MAX,
            vec![0, 128],
            "primitive:18446744073709551615:0080",
        ),
    ] {
        assert_eq!(
            render_conformance_stack(&[Value::PrimitiveValue { tag, bytes }], &default_registry()),
            expected
        );
    }
}

#[test]
fn all_single_byte_payloads_have_distinct_renderings() {
    let registry = default_registry();
    let mut seen = BTreeSet::new();
    for byte in 0..=u8::MAX {
        assert!(seen.insert(render_conformance_stack(
            &[Value::Bytes(vec![byte])],
            &registry
        )));
    }
    assert!(seen.insert(render_conformance_stack(&[Value::Bytes(vec![])], &registry)));
    assert_eq!(seen.len(), 257);
}

#[test]
fn primitive_tags_are_not_conflated() {
    let registry = default_registry();
    let mut seen = BTreeSet::new();
    for tag in [0, 1, 255, 256, i64::MAX as u64, u64::MAX] {
        assert!(seen.insert(render_conformance_stack(
            &[Value::PrimitiveValue {
                tag,
                bytes: vec![0]
            }],
            &registry,
        )));
    }
    assert_eq!(seen.len(), 6);
}

#[test]
fn rendering_preserves_types_stack_order_and_empty_payloads() {
    let stack = [
        Value::Int(-1),
        Value::Bool(false),
        Value::Bytes(vec![]),
        Value::PrimitiveValue {
            tag: 1,
            bytes: vec![],
        },
        Value::Bytes(vec![44, 58]),
        Value::Bool(true),
        Value::World,
    ];
    assert_eq!(
        render_conformance_stack(&stack, &default_registry()),
        "-1,false,bytes:,primitive:1:,bytes:2c3a,true,world"
    );
    assert_eq!(render_conformance_stack(&[], &default_registry()), "");
}

#[test]
fn payload_lengths_and_adjacent_value_boundaries_are_preserved() {
    let registry = default_registry();
    let stacks = [
        vec![Value::Bytes(vec![0]), Value::Bytes(vec![1, 2])],
        vec![Value::Bytes(vec![0, 1]), Value::Bytes(vec![2])],
        vec![Value::Bytes(vec![0, 1, 2])],
        vec![Value::Bytes(vec![]), Value::Bytes(vec![0, 1, 2])],
        vec![Value::PrimitiveValue {
            tag: 1,
            bytes: vec![0, 1, 2],
        }],
    ];
    let mut seen = BTreeSet::new();
    for stack in stacks {
        assert!(seen.insert(render_conformance_stack(&stack, &registry)));
    }
}

#[test]
fn different_byte_outputs_disagree_through_public_execution() {
    let registry = default_registry();
    let left = observe_image(
        &image(vec![literal(Value::Bytes(vec![0, 1]))]),
        vec![],
        8,
        &registry,
    );
    let right = observe_image(
        &image(vec![literal(Value::Bytes(vec![0, 2]))]),
        vec![],
        8,
        &registry,
    );
    assert_eq!(left.status, ConformanceStatus::Terminal);
    assert_eq!(right.status, ConformanceStatus::Terminal);
    assert_stack_disagreement(&left, &right);
}

#[test]
fn an_independent_byte_reference_agrees_with_the_execution() {
    let observed = observe_image(
        &image(vec![literal(Value::Bytes(vec![0, 255]))]),
        vec![],
        8,
        &default_registry(),
    );
    let expected = ConformanceReference {
        status: ConformanceStatus::Terminal,
        stack: "bytes:00ff".to_owned(),
        frames: "-".to_owned(),
        cost: ConformanceCostReference {
            total: 1,
            kernel: 1,
            breakdown: None,
        },
        world_observation: Some(vec![0]),
        trap: None,
    };
    assert_eq!(
        compare_conformance(&expected, &observed),
        ConformanceVerdict::Agree
    );
}

#[test]
fn primitive_payloads_remain_distinct_in_real_retained_trap_stacks() {
    let registry = default_registry();
    let image = image(vec![]);
    let run = |bytes| {
        observe_image(
            &image,
            vec![Value::PrimitiveValue { tag: 1, bytes }],
            8,
            &registry,
        )
    };
    let left = run(vec![0, 1]);
    let right = run(vec![0, 2]);
    // Default tag 1 is linear: leaving it on the stack is a resource fault,
    // not successful program execution. Conformance still retains its payload.
    assert_eq!(left.status, ConformanceStatus::Trap);
    assert_eq!(
        left.trap.as_ref().expect("resource trap").code,
        "resource-fault"
    );
    assert_eq!(right.status, ConformanceStatus::Trap);
    assert_stack_disagreement(&left, &right);
}

fn named_image(code: Vec<Instruction>, helpers: Vec<WordEntry>) -> Image {
    let mut words = vec![
        word("main", vec![literal(Value::Int(99))]),
        word("policy_run", code),
    ];
    words.extend(helpers);
    seal_image(1, words)
}

#[test]
fn named_root_reports_label_cost_events_traces_and_frames_correctly() {
    let image = named_image(vec![literal(Value::Int(7))], vec![]);
    let report =
        execute_report_entry(&image, "policy_run", vec![], 8, &default_registry()).unwrap();
    assert_eq!(report.stack, vec![Value::Int(7)]);
    assert_eq!(report.cost.total, 1);
    assert_eq!(report.cost.steps[0].word, "policy_run");
    assert_eq!(report.trace[0].word, "policy_run");
    assert_eq!(report.trace[0].frames[0].word, "policy_run");
}

#[test]
fn named_nested_calls_keep_root_and_helper_attribution_separate() {
    let image = named_image(
        vec![
            Instruction {
                op: Op::CallWord,
                operand: Some(Operand::Word("policy_helper".to_owned())),
            },
            literal(Value::Int(2)),
        ],
        vec![word("policy_helper", vec![literal(Value::Int(1))])],
    );
    let report =
        execute_report_entry(&image, "policy_run", vec![], 8, &default_registry()).unwrap();
    assert_eq!(report.stack, vec![Value::Int(1), Value::Int(2)]);
    assert_eq!(report.cost.total, 4);
    assert_eq!(report.cost.kernel_total(), 3);
    assert_eq!(
        report
            .cost
            .steps
            .iter()
            .map(|step| step.word.as_str())
            .collect::<Vec<_>>(),
        ["policy_run", "policy_helper", "policy_helper", "policy_run"]
    );
    assert_eq!(
        report
            .trace
            .iter()
            .map(|event| event.word.as_str())
            .collect::<Vec<_>>(),
        ["policy_run", "policy_helper", "policy_run"]
    );
    assert_eq!(report.trace[1].frames[0].word, "policy_run");
    assert_eq!(report.trace[1].frames[1].word, "policy_helper");
}

#[test]
fn quotation_steps_keep_the_named_enclosing_word() {
    let image = named_image(
        vec![
            Instruction {
                op: Op::PushQuote,
                operand: Some(Operand::Quote(Quotation {
                    code: vec![literal(Value::Int(8))],
                    captures: vec![],
                    consumed: vec![],
                })),
            },
            Instruction {
                op: Op::Call,
                operand: None,
            },
        ],
        vec![],
    );
    let report =
        execute_report_entry(&image, "policy_run", vec![], 8, &default_registry()).unwrap();
    assert_eq!(report.stack, vec![Value::Int(8)]);
    assert_eq!(report.cost.steps.len(), 3);
    assert!(
        report
            .cost
            .steps
            .iter()
            .all(|step| step.word == "policy_run")
    );
    assert!(report.trace.iter().all(|event| event.word == "policy_run"));
    assert!(report.trace.iter().any(|event| event.frames.len() == 2));
    assert!(
        report
            .trace
            .iter()
            .flat_map(|event| &event.frames)
            .all(|frame| frame.word == "policy_run")
    );
}

#[test]
fn named_report_and_diagnostic_execution_produce_identical_reports() {
    let image = named_image(vec![literal(Value::Int(7))], vec![]);
    let registry = default_registry();
    let report = execute_report_entry(&image, "policy_run", vec![], 8, &registry).unwrap();
    let ExecutionOutcome::Complete(diagnostic) =
        execute_diagnostic_entry(&image, "policy_run", vec![], 8, &registry, None)
    else {
        panic!("expected a complete diagnostic report")
    };
    assert_eq!(report, diagnostic);
}

#[test]
fn default_main_execution_and_missing_entry_behaviour_are_unchanged() {
    let image = named_image(vec![literal(Value::Int(7))], vec![]);
    let registry = default_registry();
    let report = execute_report(&image, 8).unwrap();
    assert_eq!(report.stack, vec![Value::Int(99)]);
    assert_eq!(report.cost.steps[0].word, "main");
    assert_eq!(report.trace[0].word, "main");
    assert_eq!(report.trace[0].frames[0].word, "main");
    assert_eq!(
        execute_report_entry(&image, "absent", vec![], 8, &registry),
        Err(VmError::UnknownWord("absent".to_owned()))
    );
}

#[cfg(feature = "std")]
#[test]
fn retained_image_execution_keeps_main_attribution() {
    let store = firth_vm::ImageStore::new(named_image(vec![], vec![])).unwrap();
    let report = firth_vm::execute_active_report(&store, 8, &default_registry()).unwrap();
    assert_eq!(report.stack, vec![Value::Int(99)]);
    assert_eq!(report.cost.steps[0].word, "main");
    assert_eq!(report.trace[0].frames[0].word, "main");
}

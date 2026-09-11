//! Quotation and frame regressions on the public conformance boundary: full
//! renderings, the unsupported verdict for legacy projections, the corpus
//! lift, the admission label and the pinned execution bounds.

use firth_vm::{
    ConformanceCostReference, ConformanceObservation, ConformanceReference, ConformanceStatus,
    ConformanceVerdict, Image, Instruction, Op, Operand, Quotation, Value, WordEntry, body_digest,
    compare_conformance, default_registry, evidence_digest, observe_image,
    render_conformance_stack, seal_image,
};

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
fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

fn bare(op: Op) -> Instruction {
    Instruction { op, operand: None }
}

fn quote_of(code: Vec<Instruction>) -> Instruction {
    Instruction {
        op: Op::PushQuote,
        operand: Some(Operand::Quote(Quotation {
            code,
            captures: vec![],
            consumed: vec![],
        })),
    }
}

/// The full rendering of a root `main` frame stopped at `pc` with `code` as
/// its body and no `DIP` in flight.
fn root_frame(code: &[Instruction], pc: usize) -> String {
    format!("main@{pc}:{}:halt{{}}", hex(&body_digest(code)))
}

#[test]
fn quotation_bodies_and_captures_are_rendered_in_full() {
    // Before this rendering every quotation collapsed to `quotation-many`, so
    // `1 quote` and `2 quote` were indistinguishable through the conformance
    // API and `firth-vm run`.
    let registry = default_registry();
    let capture_body = [Instruction {
        op: Op::PushCapture,
        operand: Some(Operand::Capture(0)),
    }];
    let quoted = |value: i64| {
        observe_image(
            &image(vec![literal(Value::Int(value)), bare(Op::Quote)]),
            vec![],
            8,
            &registry,
        )
    };
    let left = quoted(42);
    assert_eq!(left.status, ConformanceStatus::Terminal);
    assert_eq!(
        left.stack,
        format!("quotation:many:{}{{42}}", hex(&body_digest(&capture_body)))
    );
    assert_ne!(left.stack, quoted(43).stack);
    assert!(!left.stack.contains("quotation-many"));

    // Nested quotations render their own digest inside the outer slots, and
    // a linear capture makes the quotation linear.
    let nested = Value::Quotation(Quotation {
        code: vec![],
        captures: vec![
            Value::Quotation(Quotation {
                code: vec![literal(Value::Int(1))],
                captures: vec![],
                consumed: vec![],
            }),
            Value::PrimitiveValue {
                tag: 1,
                bytes: vec![0xab],
            },
        ],
        consumed: vec![false, false],
    });
    assert_eq!(
        render_conformance_stack(&[nested], &registry),
        format!(
            "quotation:linear:{}{{quotation:many:{}{{}},primitive:1:ab}}",
            hex(&body_digest(&[])),
            hex(&body_digest(&[literal(Value::Int(1))]))
        )
    );
}

#[test]
fn different_quotation_captures_disagree_through_public_execution() {
    let registry = default_registry();
    let quoted = |value: i64| {
        observe_image(
            &image(vec![literal(Value::Int(value)), bare(Op::Quote)]),
            vec![],
            8,
            &registry,
        )
    };
    let left = quoted(1);
    let right = quoted(2);
    assert_eq!(left.status, ConformanceStatus::Terminal);
    assert_eq!(right.status, ConformanceStatus::Terminal);
    assert_stack_disagreement(&left, &right);

    // Different bodies with the same captures disagree too.
    let bodies = |value: i64| {
        observe_image(
            &image(vec![quote_of(vec![literal(Value::Int(value))])]),
            vec![],
            8,
            &registry,
        )
    };
    assert_stack_disagreement(&bodies(1), &bodies(2));
}

#[test]
fn a_usage_only_reference_is_unsupported_never_agreement() {
    let registry = default_registry();
    let observed = observe_image(
        &image(vec![literal(Value::Int(42)), bare(Op::Quote)]),
        vec![],
        8,
        &registry,
    );
    let mut usage_only = reference(&observed);
    usage_only.stack = "quotation-many".to_owned();
    let verdict = compare_conformance(&usage_only, &observed);
    let ConformanceVerdict::UnsupportedComparison(unsupported) = &verdict else {
        panic!("a usage projection must be unsupported, not {verdict:?}")
    };
    assert_eq!(unsupported.len(), 1);
    assert_eq!(unsupported[0].field, "stack");
    assert_eq!(unsupported[0].reference, "quotation-many");
    assert_eq!(unsupported[0].target, observed.stack);
    assert!(!verdict.is_agreement());
    assert_eq!(verdict.canonical(), "unsupported-comparison");

    // A projection that differs still disagrees, and a disagreement wins
    // over an unsupported field elsewhere.
    usage_only.stack = "quotation-linear".to_owned();
    assert!(matches!(
        compare_conformance(&usage_only, &observed),
        ConformanceVerdict::Disagree(_)
    ));
    usage_only.stack = "quotation-many".to_owned();
    usage_only.frames = "main@0".to_owned();
    let ConformanceVerdict::Disagree(mismatches) = compare_conformance(&usage_only, &observed)
    else {
        panic!("a frame disagreement must win over the unsupported stack")
    };
    assert_eq!(mismatches.len(), 1);
    assert_eq!(mismatches[0].field, "frames");
}

#[test]
fn frames_render_digest_continuation_saved_and_capture_state() {
    let registry = default_registry();
    // Fuel runs out on the first instruction inside the dip body, so the root
    // frame is parked at the DIP with 4 saved and the body frame at pc 0.
    let body = vec![literal(Value::Int(5))];
    let code = vec![
        literal(Value::Int(4)),
        quote_of(body.clone()),
        bare(Op::Dip),
    ];
    let observed = observe_image(&image(code.clone()), vec![], 3, &registry);
    assert_eq!(observed.status, ConformanceStatus::FuelExhausted);
    assert_eq!(
        observed.frames,
        format!(
            "main@2:{}:restore-dip(4){{}};main@0:{}:return{{}}",
            hex(&body_digest(&code)),
            hex(&body_digest(&body))
        )
    );

    // A consumed linear capture is rendered as such in the body frame, and
    // the moved value is on the stack in full.
    let linear = Value::PrimitiveValue {
        tag: 1,
        bytes: vec![0xab],
    };
    let capture_body = vec![
        Instruction {
            op: Op::PushCapture,
            operand: Some(Operand::Capture(0)),
        },
        bare(Op::Drop),
    ];
    let code = vec![
        Instruction {
            op: Op::PushQuote,
            operand: Some(Operand::Quote(Quotation {
                code: capture_body.clone(),
                captures: vec![linear],
                consumed: vec![false],
            })),
        },
        bare(Op::Call),
    ];
    let observed = observe_image(&image(code.clone()), vec![], 8, &registry);
    assert_eq!(observed.status, ConformanceStatus::Trap);
    assert_eq!(
        observed.trap.as_ref().map(|trap| trap.code.as_str()),
        Some("resource-fault")
    );
    assert_eq!(observed.stack, "primitive:1:ab");
    assert_eq!(
        observed.frames,
        format!(
            "main@1:{}:halt{{}};main@1:{}:return{{consumed}}",
            hex(&body_digest(&code)),
            hex(&body_digest(&capture_body))
        )
    );
}

#[test]
fn different_saved_dip_values_disagree() {
    // Before the full rendering both traps rendered `main@2;main@0` and the
    // comparison agreed although one host saved 4 and the other 5.
    let registry = default_registry();
    let dip = |saved: i64| {
        observe_image(
            &image(vec![
                literal(Value::Int(saved)),
                quote_of(vec![bare(Op::Drop)]),
                bare(Op::Dip),
            ]),
            vec![],
            8,
            &registry,
        )
    };
    let left = dip(4);
    let right = dip(5);
    assert_eq!(left.status, ConformanceStatus::Trap);
    assert_eq!(left.stack, right.stack);
    let ConformanceVerdict::Disagree(mismatches) = compare_conformance(&reference(&left), &right)
    else {
        panic!("different saved DIP values were reported as agreement")
    };
    assert_eq!(mismatches.len(), 1);
    assert_eq!(mismatches[0].field, "frames");
    assert!(mismatches[0].reference.contains("restore-dip(4)"));
    assert!(mismatches[0].target.contains("restore-dip(5)"));
}

#[test]
fn a_completed_dip_restores_the_frames_own_continuation() {
    // The root frame halts. Resetting it to `return` after the dipped
    // quotation finished published a residual configuration that cannot be
    // resumed, and would have made the frozen corpus lift disagree with a
    // real observation of the same program.
    let registry = default_registry();
    let observed = observe_image(
        &image(vec![
            literal(Value::Int(1)),
            quote_of(vec![]),
            bare(Op::Dip),
            bare(Op::Drop),
            bare(Op::Drop),
        ]),
        vec![],
        16,
        &registry,
    );
    assert_eq!(observed.status, ConformanceStatus::Trap);
    assert!(
        observed.frames.ends_with(":halt{}"),
        "the root frame must still halt after a completed dip, got {}",
        observed.frames
    );
    assert!(!observed.frames.contains("return"));
}

#[test]
fn the_entry_frame_lift_matches_the_frozen_corpus_row() {
    let corpus = include_str!("../fixtures/kernel.tsv");
    let row = corpus
        .lines()
        .find(|line| line.starts_with("drop-fault|"))
        .expect("the frozen corpus has row drop-fault");
    let case = firth_vm::decode_fixture_line(row).expect("valid corpus row");
    assert_eq!(case.residual_frames, "main@0");
    let lifted = firth_vm::fixture_reference(&case).expect("frozen outcome vocabulary");
    assert_eq!(lifted.frames, root_frame(&[bare(Op::Drop)], 0));
    let observed = observe_image(&case.image, vec![], 64, &default_registry());
    assert_eq!(observed.frames, lifted.frames);
    assert_eq!(
        compare_conformance(&lifted, &observed),
        ConformanceVerdict::Agree
    );

    // A row with no residual frame is left as `-`.
    let terminal = corpus
        .lines()
        .find(|line| line.starts_with("dup|"))
        .expect("row dup");
    let case = firth_vm::decode_fixture_line(terminal).expect("valid corpus row");
    assert_eq!(
        firth_vm::fixture_reference(&case)
            .expect("vocabulary")
            .frames,
        "-"
    );
}

#[test]
fn observations_never_contain_an_invalid_frame() {
    let registry = default_registry();
    let programs = vec![
        vec![
            literal(Value::Int(4)),
            quote_of(vec![literal(Value::Int(5))]),
            bare(Op::Dip),
        ],
        vec![
            literal(Value::Int(4)),
            quote_of(vec![bare(Op::Drop)]),
            bare(Op::Dip),
        ],
        vec![quote_of(vec![bare(Op::Drop)]), bare(Op::Call)],
        vec![
            literal(Value::Bool(true)),
            quote_of(vec![bare(Op::Drop)]),
            quote_of(vec![]),
            bare(Op::If),
        ],
        vec![bare(Op::Drop)],
    ];
    for code in programs {
        for fuel in 0..8 {
            let observed = observe_image(&image(code.clone()), vec![], fuel, &registry);
            assert!(
                !observed.frames.contains("invalid-frame"),
                "{}",
                observed.frames
            );
        }
    }
    // The renderer itself labels a frame whose saved values do not match its
    // continuation, which only a hand-built frame can exhibit.
    let broken = firth_vm::FrameTrace {
        word: "main".to_owned(),
        pc: 0,
        code_digest: body_digest(&[]),
        captures: vec![],
        capture_values: vec![],
        saved: vec![Value::Int(1)],
        continuation: firth_vm::Continuation::Halt,
    };
    assert_eq!(
        firth_vm::render_conformance_frames(&[broken], &registry),
        "invalid-frame"
    );
}

#[test]
fn the_execution_bounds_are_pinned_by_value() {
    // `tests/bounds.rs` names these by value so it also compiles against the
    // unchanged runtime for the gate's baseline mode; this ties the values to
    // the crate constants.
    assert_eq!(firth_vm::MAX_CALL_DEPTH, 256);
    assert_eq!(firth_vm::MAX_FUEL, firth_vm::DEFAULT_FUEL);
    assert_eq!(firth_vm::MAX_FUEL, 4096);
    assert_eq!(firth_vm::MAX_INPUT_BYTES, 1 << 20);
    assert_eq!(
        firth_vm::VmError::CallDepthExceeded.stable_code(),
        "resource-fault"
    );
    assert_eq!(
        firth_vm::VmError::CallDepthExceeded.stable_subcode(),
        "call-depth-exceeded"
    );
}

#[test]
fn every_observation_carries_the_admission_label() {
    let observed = observe_image(
        &image(vec![literal(Value::Int(1))]),
        vec![],
        8,
        &default_registry(),
    );
    assert_eq!(observed.admission, firth_vm::VM_ADMISSION);
    assert_eq!(observed.admission.admission, "structural-digest-recheck");
    assert_eq!(
        observed.admission.image_evidence,
        "legacy-content-identifiers-not-authenticated-proofs"
    );
    assert_eq!(observed.admission.refinements, "not-checked");
    assert_eq!(
        observed.admission.patch_admission,
        "external-verifier-unauthenticated"
    );
}

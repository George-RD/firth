// Witnesses for the differential conformance boundary in `conformance.rs`.
//
// The frozen Lean corpus already witnesses kernel execution itself; these
// cases exercise the comparison boundary instead, and cover the classes the
// corpus row format cannot state: the hidden `World` observation, classified
// traps, malformed input, fuel exhaustion, primitive faults, and the
// dual-fuel inconclusive verdict.

fn conformance_witness(code: Vec<Instruction>) -> Image {
    test_image(vec![word("main", code)])
}

fn push_int(value: i64) -> Instruction {
    instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(value))))
}

fn prim(name: &str) -> Instruction {
    instruction(Op::Prim, Some(Operand::Primitive(String::from(name))))
}

fn breakdown(instructions: u64, word_entries: u64, primitives: u64) -> ConformanceCostBreakdown {
    ConformanceCostBreakdown {
        instructions,
        word_entries,
        primitives,
    }
}

fn trap_reference(
    code: &str,
    subcode: &str,
    stack: &str,
    frames: &str,
    world_observation: Vec<u8>,
    cost: ConformanceCostReference,
) -> ConformanceReference {
    ConformanceReference {
        status: ConformanceStatus::Trap,
        stack: String::from(stack),
        frames: String::from(frames),
        cost,
        world_observation: Some(world_observation),
        trap: Some(ConformanceTrap {
            code: String::from(code),
            subcode: String::from(subcode),
        }),
    }
}

fn zero_cost() -> ConformanceCostReference {
    ConformanceCostReference {
        total: 0,
        kernel: 0,
        breakdown: Some(breakdown(0, 0, 0)),
    }
}

#[test]
fn world_threading_agrees_on_the_hidden_observation_and_the_cost_breakdown() {
    let image = conformance_witness(vec![prim("makeWorld"), prim("consumeWorld")]);
    let reference = ConformanceReference {
        status: ConformanceStatus::Terminal,
        stack: String::new(),
        frames: String::from("-"),
        cost: ConformanceCostReference {
            total: 2,
            kernel: 2,
            breakdown: Some(breakdown(2, 0, 2)),
        },
        world_observation: Some(vec![0, 0, 1]),
        trap: None,
    };
    let observed = observe_image(&image, Vec::new(), 64, &default_registry());
    assert_eq!(observed.world_observation, vec![0, 0, 1]);
    assert_eq!(
        compare_conformance(&reference, &observed),
        ConformanceVerdict::Agree
    );
}

#[test]
fn a_wrong_world_observation_disagrees_on_exactly_that_field() {
    let image = conformance_witness(vec![prim("makeWorld"), prim("consumeWorld")]);
    let reference = ConformanceReference {
        status: ConformanceStatus::Terminal,
        stack: String::new(),
        frames: String::from("-"),
        cost: ConformanceCostReference {
            total: 2,
            kernel: 2,
            breakdown: None,
        },
        world_observation: Some(vec![0]),
        trap: None,
    };
    let observed = observe_image(&image, Vec::new(), 64, &default_registry());
    let ConformanceVerdict::Disagree(mismatches) = compare_conformance(&reference, &observed)
    else {
        panic!("expected a world-observation disagreement")
    };
    assert_eq!(mismatches.len(), 1);
    assert_eq!(mismatches[0].field, "world-observation");
    assert_eq!(mismatches[0].reference, "0");
    assert_eq!(mismatches[0].target, "0,0,1");
}

#[test]
fn malformed_image_bytes_trap_before_any_cost_is_charged() {
    let mut bytes = smoke_image();
    bytes.truncate(bytes.len() - 1);
    let observed = observe_image_bytes(&bytes, Vec::new(), 64, &default_registry());
    let reference = trap_reference(
        "malformed-instruction",
        "",
        "",
        "-",
        WorldState::new().observation().to_vec(),
        zero_cost(),
    );
    assert_eq!(
        compare_conformance(&reference, &observed),
        ConformanceVerdict::Agree
    );

    let mut bytes = smoke_image();
    let literal = bytes.iter().position(|byte| *byte == 0).expect("literal");
    bytes.splice(literal + 2..literal + 3, [0x80, 0x00]);
    let observed = observe_image_bytes(&bytes, Vec::new(), 64, &default_registry());
    assert_eq!(
        compare_conformance(&reference, &observed),
        ConformanceVerdict::Agree
    );
}

#[test]
fn a_well_formed_image_still_decodes_through_the_byte_boundary() {
    let observed = observe_image_bytes(&smoke_image(), Vec::new(), 64, &default_registry());
    assert_eq!(observed.status, ConformanceStatus::Terminal);
    assert_eq!(observed.stack, "42");
    assert_eq!(observed.trap, None);
}

#[test]
fn primitive_faults_and_unknown_primitives_carry_their_stable_classes() {
    let overflow = conformance_witness(vec![
        push_int(i64::MAX),
        push_int(1),
        prim("addNat"),
    ]);
    let observed = observe_image(&overflow, Vec::new(), 64, &default_registry());
    assert_eq!(observed.status, ConformanceStatus::Trap);
    assert_eq!(
        observed.trap,
        Some(ConformanceTrap {
            code: String::from("primitive-fault"),
            subcode: String::new(),
        })
    );

    let unknown = conformance_witness(vec![prim("missing")]);
    let observed = observe_image(&unknown, Vec::new(), 64, &default_registry());
    let reference = trap_reference(
        "unknown-primitive",
        "",
        "",
        "main@0",
        WorldState::new().observation().to_vec(),
        zero_cost(),
    );
    assert_eq!(
        compare_conformance(&reference, &observed),
        ConformanceVerdict::Agree
    );
}

#[test]
fn a_stack_fault_is_classified_where_the_frozen_corpus_only_says_stuck() {
    let image = conformance_witness(vec![instruction(Op::Drop, None)]);
    let observed = observe_image(&image, Vec::new(), 64, &default_registry());
    let reference = trap_reference(
        "stack-fault",
        "",
        "",
        "main@0",
        WorldState::new().observation().to_vec(),
        ConformanceCostReference {
            total: 0,
            kernel: 0,
            breakdown: Some(breakdown(0, 0, 0)),
        },
    );
    assert_eq!(
        compare_conformance(&reference, &observed),
        ConformanceVerdict::Agree
    );
    assert_eq!(observed.frames, "main@0");
}

#[test]
fn fuel_exhaustion_is_its_own_status_and_a_dual_exhaustion_is_inconclusive() {
    let image = conformance_witness(vec![push_int(1), push_int(2)]);
    let observed = observe_image(&image, Vec::new(), 0, &default_registry());
    assert_eq!(observed.status, ConformanceStatus::FuelExhausted);
    assert_eq!(
        observed.trap,
        Some(ConformanceTrap {
            code: String::from("fuel-exhausted"),
            subcode: String::new(),
        })
    );
    assert_eq!(observed.cost.total, 0);

    let exhausted = ConformanceReference {
        status: ConformanceStatus::FuelExhausted,
        stack: String::from("this stack is never compared"),
        frames: String::from("this frame rendering is never compared"),
        cost: ConformanceCostReference {
            total: 99,
            kernel: 99,
            breakdown: None,
        },
        world_observation: Some(vec![9, 9, 9]),
        trap: None,
    };
    assert_eq!(
        compare_conformance(&exhausted, &observed),
        ConformanceVerdict::BoundedFuelInconclusive
    );
    assert_eq!(
        compare_conformance(&exhausted, &observed).canonical(),
        "bounded-fuel-inconclusive"
    );
}

#[test]
fn a_one_sided_exhaustion_disagrees_rather_than_being_inconclusive() {
    let image = conformance_witness(vec![push_int(1)]);
    let terminal = observe_image(&image, Vec::new(), 64, &default_registry());
    assert_eq!(terminal.status, ConformanceStatus::Terminal);

    let exhausted = ConformanceReference {
        status: ConformanceStatus::FuelExhausted,
        stack: String::from("1"),
        frames: String::from("-"),
        cost: ConformanceCostReference {
            total: 1,
            kernel: 1,
            breakdown: None,
        },
        world_observation: None,
        trap: None,
    };
    let ConformanceVerdict::Disagree(mismatches) = compare_conformance(&exhausted, &terminal)
    else {
        panic!("expected a one-sided exhaustion to disagree")
    };
    assert_eq!(mismatches.len(), 1);
    assert_eq!(mismatches[0].field, "status");
    assert_eq!(mismatches[0].reference, "fuel-exhausted");
    assert_eq!(mismatches[0].target, "terminal");

    let target_exhausted = observe_image(&image, Vec::new(), 0, &default_registry());
    let terminal_reference = ConformanceReference {
        status: ConformanceStatus::Terminal,
        stack: String::from("1"),
        frames: String::from("-"),
        cost: ConformanceCostReference {
            total: 1,
            kernel: 1,
            breakdown: None,
        },
        world_observation: None,
        trap: None,
    };
    assert!(matches!(
        compare_conformance(&terminal_reference, &target_exhausted),
        ConformanceVerdict::Disagree(_)
    ));
}

#[test]
fn a_mismatched_cost_breakdown_is_reported_even_when_the_totals_agree() {
    let image = conformance_witness(vec![push_int(2), push_int(40), prim("addNat")]);
    let observed = observe_image(&image, Vec::new(), 64, &default_registry());
    assert_eq!(observed.stack, "42");
    let reference = ConformanceReference {
        status: ConformanceStatus::Terminal,
        stack: String::from("42"),
        frames: String::from("-"),
        cost: ConformanceCostReference {
            total: 3,
            kernel: 3,
            breakdown: Some(breakdown(3, 0, 0)),
        },
        world_observation: None,
        trap: None,
    };
    let ConformanceVerdict::Disagree(mismatches) = compare_conformance(&reference, &observed)
    else {
        panic!("expected a cost-breakdown disagreement")
    };
    assert_eq!(mismatches.len(), 1);
    assert_eq!(mismatches[0].field, "cost-breakdown");
    assert_eq!(mismatches[0].reference, "3,0,0");
    assert_eq!(mismatches[0].target, "3,0,1");
}

#[test]
fn observations_are_deterministic_and_independent_of_the_allocation_budget() {
    let image = conformance_witness(vec![push_int(2), push_int(40), prim("addNat")]);
    let first = observe_image(&image, Vec::new(), 64, &default_registry());
    let second = observe_image(&image, Vec::new(), 64, &default_registry());
    assert_eq!(first, second);

    let generous = execute_diagnostic_with_stack_budget(
        &image,
        Vec::new(),
        64,
        &default_registry(),
        Some(1 << 20),
    );
    let ExecutionOutcome::Complete(report) = generous else {
        panic!("expected a generous budget to complete")
    };
    assert_eq!(
        render_conformance_stack(&report.stack, &default_registry()),
        first.stack
    );
    assert_eq!(report.cost.total, first.cost.total);
}

#[test]
fn an_unstated_reference_field_is_not_invented_by_the_comparison() {
    let image = conformance_witness(vec![prim("makeWorld"), prim("consumeWorld")]);
    let observed = observe_image(&image, Vec::new(), 64, &default_registry());
    let unstated = ConformanceReference {
        status: ConformanceStatus::Terminal,
        stack: String::new(),
        frames: String::from("-"),
        cost: ConformanceCostReference {
            total: 2,
            kernel: 2,
            breakdown: None,
        },
        world_observation: None,
        trap: None,
    };
    assert_eq!(
        compare_conformance(&unstated, &observed),
        ConformanceVerdict::Agree
    );
    assert_eq!(observed.world_observation, vec![0, 0, 1]);
}

#[test]
fn the_frozen_outcome_vocabulary_is_the_only_one_accepted() {
    assert_eq!(
        parse_conformance_status("terminal"),
        Some(ConformanceStatus::Terminal)
    );
    assert_eq!(
        parse_conformance_status("stuck"),
        Some(ConformanceStatus::Trap)
    );
    assert_eq!(
        parse_conformance_status("fuel"),
        Some(ConformanceStatus::FuelExhausted)
    );
    assert_eq!(parse_conformance_status("trap"), None);
    assert_eq!(parse_conformance_status(""), None);
}

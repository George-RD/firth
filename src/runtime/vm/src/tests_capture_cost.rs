// PUSH_CAPTURE is a real VM instruction but implements a zero-cost reference
// S-PUSH. Never remove its target charge or its fuel requirement.

#[test]
fn captured_value_restoration_has_separate_kernel_and_target_charges() {
    let code = vec![
        push_int(42),
        instruction(Op::Quote, None),
        instruction(Op::Call, None),
    ];
    let image = seal_image(1, vec![word("main", code)]);
    let ExecutionOutcome::Complete(report) =
        execute_diagnostic(&image, 4, &default_registry())
    else {
        panic!("captured quotation should execute")
    };
    assert_eq!(report.stack, vec![Value::Int(42)]);
    assert_eq!(report.cost.total, 4);
    assert_eq!(report.cost.instructions, 4);
    assert_eq!(report.trace.len(), 4);
    assert_eq!(report.cost.kernel_total(), 3);
    assert_eq!(
        report.cost.steps.iter().map(|step| step.kernel_cost).collect::<Vec<_>>(),
        vec![1, 1, 1, 0]
    );
    let observed = observe_image(&image, Vec::new(), 4, &default_registry());
    assert_eq!(observed.cost.total, 4);
    assert_eq!(observed.cost.kernel, 3);
}

#[test]
fn captured_restoration_cannot_execute_without_its_vm_fuel() {
    let image = seal_image(1, vec![word("main", vec![
        push_int(42),
        instruction(Op::Quote, None),
        instruction(Op::Call, None),
    ])]);
    let ExecutionOutcome::Trap(trap) =
        execute_diagnostic(&image, 3, &default_registry())
    else {
        panic!("zero kernel charge must not make restoration free to execute")
    };
    assert_eq!(trap.error, VmError::FuelExhausted);
    assert_eq!(trap.cost.total, 3);
    assert_eq!(trap.cost.kernel_total(), 3);
    assert_eq!(trap.trace.len(), 3);
}

#[test]
fn adapter_reports_capture_costs_without_reducing_target_steps() {
    let request = adapter_request("main", r#"[
        {"op":"push-literal","literal":{"kind":"int","value":42}},
        {"op":"quote"},{"op":"call"}
    ]"#, 4);
    let response = response_of(&request);
    assert_eq!(member_str(&response, "status"), "success");
    assert_eq!(
        response.member("cost"),
        Some(&parse_json("{\"steps\":4,\"total\":4,\"kernel\":3}").unwrap())
    );
}

#[test]
fn composed_capture_restorations_each_keep_their_vm_charge() {
    let image = seal_image(1, vec![word("main", vec![
        push_int(20),
        instruction(Op::Quote, None),
        push_int(22),
        instruction(Op::Quote, None),
        instruction(Op::Compose, None),
        instruction(Op::Call, None),
        prim("addNat"),
    ])]);
    let observed = observe_image(&image, Vec::new(), 9, &default_registry());
    assert_eq!(observed.status, ConformanceStatus::Terminal);
    assert_eq!(observed.stack, "42");
    assert_eq!(observed.cost.total, 9);
    assert_eq!(observed.cost.kernel, 7);
    assert_eq!(observed.cost.breakdown.instructions, 9);
}

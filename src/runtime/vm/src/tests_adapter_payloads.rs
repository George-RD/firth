// Witnesses for the adapter's full quotation payloads, per-event trace
// fields, frames, envelope and bound refusals, and the admission label.

fn nested_push_quote_request(depth: usize, innermost: &str) -> String {
    let mut code = String::from(innermost);
    let mut instructions = if innermost == "[]" {
        vec![]
    } else {
        adapter_code_of(innermost)
    };
    for _ in 0..depth {
        code = alloc::format!(
            "[{{\"op\":\"push-quote\",\"quotation\":{{\"kind\":\"quotation\",\"code\":{code},\"captures\":[],\"consumed\":[]}}}}]"
        );
        instructions = vec![instruction(
            Op::PushQuote,
            Some(Operand::Quote(Quotation {
                code: instructions,
                captures: vec![],
                consumed: vec![],
            })),
        )];
    }
    let digest = render_hex(&body_digest(&instructions));
    let evidence = render_hex(&evidence_digest(&[]));
    alloc::format!(
        "{{\"request_id\":\"nested\",\"target_program\":{{\"format_version\":1,\"entry\":\"main\",\
         \"words\":[{{\"name\":\"main\",\"erased_word_type\":\"(--)\",\"code\":{code},\
         \"body_digest\":\"{digest}\",\"kernel_evidence_digest\":\"{evidence}\",\
         \"refinement_evidence_digest\":\"{evidence}\",\"generation\":0}}]}},\
         \"initial_stack\":[],\"image\":{{\"image_version\":1,\"gamma_version\":1}},\
         \"gamma_version\":\"0.1\",\"fuel\":0}}"
    )
}

fn without_projection_members(value: &Json) -> Json {
    let Json::Object(members) = value else {
        panic!("a quotation is an object")
    };
    Json::Object(
        members
            .iter()
            .filter(|(name, _)| name != "usage" && name != "body_digest")
            .cloned()
            .collect(),
    )
}

#[test]
fn quotation_values_round_trip_through_the_request_grammar() {
    let response = response_of(&adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":42}},{\"op\":\"quote\"}]",
        8,
    ));
    let Some(Json::Array(stack)) = response.member("stack") else {
        panic!("stack is an array")
    };
    assert_eq!(member_str(&stack[0], "kind"), "quotation");
    assert_eq!(member_str(&stack[0], "usage"), "many");
    let capture_body = vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))];
    assert_eq!(
        member_str(&stack[0], "body_digest"),
        render_hex(&body_digest(&capture_body))
    );
    assert_eq!(
        adapter_operand_value(&without_projection_members(&stack[0]), "round-trip")
            .expect("the reported body is a request value"),
        Value::Quotation(Quotation {
            code: capture_body,
            captures: vec![Value::Int(42)],
            consumed: vec![false],
        })
    );

    // A nested static quotation round-trips as the exact operand that was
    // sent, including the inner quotation in request grammar.
    let nested = "[{\"op\":\"push-quote\",\"quotation\":{\"kind\":\"quotation\",\
                  \"code\":[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}},\
                  {\"op\":\"dup\"}],\"captures\":[],\"consumed\":[]}}]";
    let response = response_of(&adapter_request("main", nested, 8));
    let Some(Json::Array(stack)) = response.member("stack") else {
        panic!("stack is an array")
    };
    let Some(Operand::Quote(sent)) = adapter_code_of(nested)[0].operand.clone() else {
        panic!("the request pushes a quotation")
    };
    assert_eq!(
        adapter_operand_value(&without_projection_members(&stack[0]), "round-trip")
            .expect("request value"),
        Value::Quotation(sent)
    );
}

#[test]
fn trace_costs_are_per_event_charges() {
    // Before this change each event reported the running total: [1, 2, 3].
    let image = seal_image(
        1,
        vec![word("main", vec![push_int(1), push_int(2), push_int(3)])],
    );
    let ExecutionOutcome::Complete(report) = execute_diagnostic(&image, 8, &default_registry())
    else {
        panic!("three literals complete")
    };
    assert_eq!(
        report.trace.iter().map(|event| event.cost).collect::<Vec<_>>(),
        vec![1, 1, 1]
    );
    assert_eq!(
        report
            .trace
            .iter()
            .map(|event| event.kernel_cost)
            .collect::<Vec<_>>(),
        vec![1, 1, 1]
    );

    // Capture restoration and word entry keep the identities that relate the
    // per-event charges to the totals.
    let callee = word(
        "callee",
        vec![
            push_int(42),
            instruction(Op::Quote, None),
            instruction(Op::Call, None),
        ],
    );
    let caller = word(
        "main",
        vec![instruction(
            Op::CallWord,
            Some(Operand::Word(String::from("callee"))),
        )],
    );
    let image = seal_image(1, vec![caller, callee]);
    let ExecutionOutcome::Complete(report) = execute_diagnostic(&image, 8, &default_registry())
    else {
        panic!("the call completes")
    };
    assert_eq!(
        report.trace.iter().map(|event| event.cost).collect::<Vec<_>>(),
        vec![1, 1, 1, 1, 1]
    );
    assert_eq!(
        report
            .trace
            .iter()
            .map(|event| event.kernel_cost)
            .collect::<Vec<_>>(),
        vec![1, 1, 1, 1, 0]
    );
    let event_total: u64 = report.trace.iter().map(|event| event.cost).sum();
    assert_eq!(event_total + report.cost.word_entries, report.cost.total);
    let event_kernel: u64 = report.trace.iter().map(|event| event.kernel_cost).sum();
    assert_eq!(event_kernel, report.cost.kernel_total());

    let response = response_of(&adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":42}},{\"op\":\"quote\"},{\"op\":\"call\"}]",
        8,
    ));
    let Some(Json::Array(trace)) = response.member("trace") else {
        panic!("trace is an array")
    };
    let costs: Vec<_> = trace
        .iter()
        .map(|event| event.member("cost").cloned())
        .collect();
    assert_eq!(costs, vec![Some(Json::Int(1)); 4]);
    let kernel: Vec<_> = trace
        .iter()
        .map(|event| event.member("kernel_cost").cloned())
        .collect();
    assert_eq!(
        kernel,
        vec![
            Some(Json::Int(1)),
            Some(Json::Int(1)),
            Some(Json::Int(1)),
            Some(Json::Int(0))
        ]
    );
    assert!(
        trace
            .iter()
            .all(|event| event.member("image_version") == Some(&Json::Int(1)))
    );
}

#[test]
fn trace_events_carry_frames_and_residual_frames_are_reported() {
    let program = "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":4}},\
                   {\"op\":\"push-quote\",\"quotation\":{\"kind\":\"quotation\",\
                   \"code\":[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":5}}],\
                   \"captures\":[],\"consumed\":[]}},{\"op\":\"dip\"}]";
    let response = response_of(&adapter_request("main", program, 3));
    assert_eq!(member_str(&response, "status"), "trap");
    assert_eq!(member_str(&response, "trap"), "fuel-exhausted");
    assert_eq!(member_str(&response, "trap_subcode"), "");
    let Some(Json::Array(frames)) = response.member("frames") else {
        panic!("residual frames are an array")
    };
    assert_eq!(frames.len(), 2);
    assert_eq!(member_str(&frames[0], "word"), "main");
    assert_eq!(frames[0].member("pc"), Some(&Json::Int(2)));
    assert_eq!(member_str(&frames[0], "continuation"), "restore-dip");
    assert_eq!(
        frames[0].member("saved"),
        Some(
            &parse_json("[{\"kind\":\"literal\",\"literal\":{\"type\":\"nat\",\"value\":4}}]")
                .unwrap()
        )
    );
    assert_eq!(
        member_str(&frames[0], "code_digest"),
        render_hex(&body_digest(&adapter_code_of(program)))
    );
    assert_eq!(frames[1].member("pc"), Some(&Json::Int(0)));
    assert_eq!(member_str(&frames[1], "continuation"), "return");
    assert_eq!(frames[1].member("saved"), Some(&Json::Array(vec![])));
    assert_eq!(frames[1].member("captures"), Some(&Json::Array(vec![])));
    assert_eq!(frames[1].member("consumed"), Some(&Json::Array(vec![])));
    assert_eq!(
        member_str(&frames[1], "code_digest"),
        render_hex(&body_digest(&[push_int(5)]))
    );

    // Each event records the frames in flight before its instruction ran.
    let Some(Json::Array(trace)) = response.member("trace") else {
        panic!("trace is an array")
    };
    assert_eq!(trace.len(), 3);
    let Some(Json::Array(before_dip)) = trace[2].member("frames") else {
        panic!("event frames")
    };
    assert_eq!(before_dip.len(), 1);
    assert_eq!(member_str(&before_dip[0], "continuation"), "halt");

    // A successful run has no residual frame and no subcode.
    let response = response_of(&adapter_request("main", program, 8));
    assert_eq!(member_str(&response, "status"), "success");
    assert_eq!(response.member("frames"), Some(&Json::Array(vec![])));
    assert_eq!(response.member("trap_subcode"), Some(&Json::Null));
}

#[test]
fn push_quote_envelopes_are_validated() {
    // Before this check the operand path never examined the envelope: a
    // missing `kind` and an unknown member were both accepted.
    let base = adapter_request(
        "main",
        "[{\"op\":\"push-quote\",\"quotation\":{\"kind\":\"quotation\",\"code\":[],\"captures\":[],\"consumed\":[]}}]",
        8,
    );
    assert_eq!(member_str(&response_of(&base), "status"), "success");
    for (mutated, detail) in [
        (
            base.replace("\"kind\":\"quotation\",\"code\":[]", "\"code\":[]"),
            "missing member",
        ),
        (
            base.replace(
                "\"kind\":\"quotation\",\"code\":[]",
                "\"kind\":\"int\",\"code\":[]",
            ),
            "expected a quotation",
        ),
        (
            base.replace("\"consumed\":[]}}", "\"consumed\":[],\"extra\":1}}"),
            "unknown member",
        ),
    ] {
        let error = vm_run(&mutated).expect_err(detail);
        assert_eq!(error.code, "invalid-request", "{detail}");
        assert!(error.message.contains(detail), "{}", error.message);
    }
}

#[test]
fn a_preconsumed_capture_is_refused() {
    let base = adapter_request(
        "main",
        "[{\"op\":\"push-quote\",\"quotation\":{\"kind\":\"quotation\",\"code\":[],\
          \"captures\":[{\"kind\":\"int\",\"value\":1}],\"consumed\":[false]}}]",
        8,
    );
    assert_eq!(member_str(&response_of(&base), "status"), "success");
    let error = vm_run(&base.replace("\"consumed\":[false]", "\"consumed\":[true]"))
        .expect_err("a consumed capture has no valid origin");
    assert_eq!(error.code, "invalid-request");
    assert!(
        error.message.contains("consumed capture"),
        "{}",
        error.message
    );
    // The length check still comes first, with its original message.
    let error = vm_run(&base.replace("\"consumed\":[false]", "\"consumed\":[]"))
        .expect_err("a missing state is refused");
    assert!(
        error.message.contains("capture state length"),
        "{}",
        error.message
    );
    // The same refusal on the value path, nested inside a capture.
    let nested = base.replace(
        "\"captures\":[{\"kind\":\"int\",\"value\":1}],\"consumed\":[false]",
        "\"captures\":[{\"kind\":\"quotation\",\"code\":[],\"captures\":[{\"kind\":\"int\",\"value\":1}],\"consumed\":[true]}],\"consumed\":[false]",
    );
    let error = vm_run(&nested).expect_err("a nested consumed capture is refused");
    assert!(
        error.message.contains("consumed capture"),
        "{}",
        error.message
    );
}

#[test]
fn a_json_document_over_max_bytes_is_refused() {
    let mut document = String::from("\"");
    document.push_str(&"a".repeat(MAX_BYTES - 1));
    document.push('"');
    assert_eq!(document.len(), MAX_BYTES + 1);
    assert_eq!(parse_json(&document), Err(JsonError::TooLarge));
    let error = vm_run_bytes(document.as_bytes()).expect_err("oversize");
    assert_eq!(error.code, "input-too-large");
    let mut exact = String::from("\"");
    exact.push_str(&"a".repeat(MAX_BYTES - 2));
    exact.push('"');
    assert_eq!(exact.len(), MAX_BYTES);
    assert!(parse_json(&exact).is_ok());
    // Bytes that are not UTF-8 are not a JSON document, and a multibyte
    // character cut at the bound is classified as oversize, never as a read
    // failure.
    assert_eq!(
        vm_run_bytes(&[0xff, b'{']).expect_err("not utf-8").code,
        "malformed-json"
    );
    let mut cut = vec![b'"'; MAX_BYTES - 1];
    cut.extend_from_slice("\u{1F600}".as_bytes());
    assert!(cut.len() > MAX_BYTES);
    assert_eq!(
        vm_run_bytes(&cut[..MAX_BYTES + 1]).expect_err("cut").code,
        "input-too-large"
    );
}

#[test]
fn surrogate_pairs_decode_and_lone_surrogates_are_refused() {
    // Before this change the escaped spelling Python emits by default was
    // refused while the raw UTF-8 spelling of the same character parsed.
    assert_eq!(
        parse_json("\"\\ud83d\\ude00\""),
        Ok(Json::Str(String::from("\u{1F600}")))
    );
    assert_eq!(
        parse_json("\"\\ud83d\\ude00\""),
        parse_json("\"\u{1F600}\"")
    );
    assert_eq!(
        parse_json("\"\\uD83D\\uDE00x\""),
        Ok(Json::Str(String::from("\u{1F600}x")))
    );
    for lone in [
        "\"\\ud83d\"",
        "\"\\ude00\"",
        "\"\\ude00\\ud83d\"",
        "\"\\ud83dx\"",
        "\"\\ud83d\\u0041\"",
    ] {
        assert_eq!(parse_json(lone), Err(JsonError::Malformed), "{lone}");
    }
    let request = adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}}]",
        8,
    )
    .replace(
        "\"request_id\":\"r1\"",
        "\"request_id\":\"\\ud83d\\ude00\"",
    );
    let response = response_of(&request);
    assert_eq!(member_str(&response, "request_id"), "\u{1F600}");
}

#[test]
fn a_max_nesting_quotation_passes_transport_and_depth_33_is_refused_by_the_decoder() {
    // Before this change the transport counted two levels per quotation and
    // refused depth 9 with `depth-limit` while the decoder admits 32.
    let literal = "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}}]";
    for depth in [9, MAX_NESTING] {
        let error = vm_run(&nested_push_quote_request(depth, literal)).err();
        assert_eq!(
            error, None,
            "depth {depth} with a literal operand is admitted"
        );
    }
    // At depth 33 with an empty innermost body the sealed-image decoder, not
    // the transport, refuses.
    let error = vm_run(&nested_push_quote_request(MAX_NESTING + 1, "[]"))
        .expect_err("depth 33 is refused");
    assert_eq!(error.code, "invalid-image");
    assert!(
        error
            .message
            .contains(VmError::NestingLimit.stable_code()),
        "{}",
        error.message
    );
    assert!(!error.message.contains("depth-limit"));
    // Carrying a literal operand adds JSON depth the decoder does not count,
    // so past 32 the transport reaches its own bound first and refuses with
    // `depth-limit`. Either refusal is correct; admitting the program is not.
    let error = vm_run(&nested_push_quote_request(MAX_NESTING + 1, literal))
        .expect_err("depth 33 with a literal operand is refused");
    assert_eq!(error.code, "depth-limit");
}

#[test]
fn fuel_above_max_fuel_is_refused() {
    let program = "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}}]";
    assert_eq!(
        member_str(
            &response_of(&adapter_request("main", program, MAX_FUEL)),
            "status"
        ),
        "success"
    );
    let error =
        vm_run(&adapter_request("main", program, MAX_FUEL + 1)).expect_err("above the budget");
    assert_eq!(error.code, "invalid-request");
    assert_eq!(
        error.message,
        "request.fuel: fuel exceeds the adapter budget"
    );
    assert_eq!(MAX_FUEL, 4096);
}

#[test]
fn the_response_carries_the_admission_label() {
    let expected = parse_json(
        "{\"schema\":\"firth.vm-verification.v1\",\"admission\":\"structural-digest-recheck\",\
         \"image_evidence\":\"legacy-content-identifiers-not-authenticated-proofs\",\
         \"refinements\":\"not-checked\",\"patch_admission\":\"external-verifier-unauthenticated\"}",
    )
    .unwrap();
    let success = response_of(&adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}}]",
        8,
    ));
    assert_eq!(success.member("verification"), Some(&expected));
    let trap = response_of(&adapter_request("main", "[{\"op\":\"drop\"}]", 8));
    assert_eq!(trap.member("verification"), Some(&expected));
    assert_eq!(member_str(&trap, "trap"), "stack-fault");
    assert_eq!(member_str(&trap, "trap_subcode"), "");
    let Some(Json::Array(frames)) = trap.member("frames") else {
        panic!("frames")
    };
    assert_eq!(frames.len(), 1);
}

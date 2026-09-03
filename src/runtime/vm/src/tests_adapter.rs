// Witnesses for the bounded JSON transport and the `firth.vm-run.v1` adapter.
//
// The adapter's contract is that nothing outside the accepted grammar reaches
// execution, and that nothing the target contract classifies as a trap is
// reported as success. Both halves are exercised here.

fn adapter_request(entry: &str, code: &str, fuel: u64) -> String {
    let digest = render_hex(&body_digest(&adapter_code_of(code)));
    let evidence = render_hex(&evidence_digest(&[]));
    let mut request = String::from("{\"request_id\":\"r1\",\"target_program\":{");
    request.push_str("\"format_version\":1,\"entry\":\"");
    request.push_str(entry);
    request.push_str("\",\"words\":[{\"name\":\"");
    request.push_str(entry);
    request.push_str("\",\"erased_word_type\":\"(--)\",\"code\":");
    request.push_str(code);
    request.push_str(",\"body_digest\":\"");
    request.push_str(&digest);
    request.push_str("\",\"kernel_evidence_digest\":\"");
    request.push_str(&evidence);
    request.push_str("\",\"refinement_evidence_digest\":\"");
    request.push_str(&evidence);
    request.push_str("\",\"generation\":0}]},\"initial_stack\":[],\"image\":{\"image_version\":1,");
    request.push_str("\"gamma_version\":1},\"gamma_version\":\"0.1\",\"fuel\":");
    request.push_str(&fuel.to_string());
    request.push('}');
    request
}

/// Decodes the same instruction array the request carries, so a test never
/// has to restate a word body in two notations.
fn adapter_code_of(code: &str) -> Vec<Instruction> {
    let json = parse_json(code).expect("test code parses");
    let Json::Array(items) = &json else {
        panic!("test code is an array")
    };
    let mut instructions = Vec::new();
    for item in items {
        instructions.push(adapter_instruction(item, "test", 0).expect("test instruction"));
    }
    instructions
}

fn response_of(request: &str) -> Json {
    let rendered = vm_run(request).expect("the adapter accepts the request");
    parse_json(&rendered).expect("the response is a JSON document")
}

fn member_str(value: &Json, name: &str) -> String {
    match value.member(name) {
        Some(Json::Str(text)) => text.clone(),
        other => panic!("{name} is not a string: {other:?}"),
    }
}

#[test]
fn the_json_grammar_rejects_what_it_does_not_accept() {
    assert_eq!(parse_json("{\"a\":1,\"a\":2}"), Err(JsonError::DuplicateMember));
    assert_eq!(parse_json("1.5"), Err(JsonError::UnsupportedNumber));
    assert_eq!(parse_json("1e3"), Err(JsonError::UnsupportedNumber));
    assert_eq!(parse_json("01"), Err(JsonError::Malformed));
    assert_eq!(parse_json("{\"a\":1} trailing"), Err(JsonError::Malformed));
    assert_eq!(parse_json("[1,]"), Err(JsonError::Malformed));
    assert_eq!(parse_json(""), Err(JsonError::Malformed));
    assert_eq!(parse_json("\"\\ud800\""), Err(JsonError::Malformed));
    assert_eq!(
        parse_json("99999999999999999999"),
        Err(JsonError::UnsupportedNumber)
    );
}

#[test]
fn the_json_grammar_accepts_and_round_trips_what_it_does_accept() {
    let document = "{\"a\":[1,-2,true,false,null],\"b\":{\"c\":\"x\\ny\"}}";
    let parsed = parse_json(document).expect("accepted");
    assert_eq!(render_json(&parsed), document);
    assert_eq!(
        parse_json("\"\\u00e9\""),
        Ok(Json::Str(String::from("\u{e9}")))
    );
    assert_eq!(
        parse_json("  {\n  \"a\" : 1\n}  "),
        Ok(Json::Object(vec![(String::from("a"), Json::Int(1))]))
    );
}

#[test]
fn a_json_document_nested_past_the_bound_is_refused() {
    let mut deep = String::new();
    for _ in 0..(MAX_NESTING + 2) {
        deep.push('[');
    }
    for _ in 0..(MAX_NESTING + 2) {
        deep.push(']');
    }
    assert_eq!(parse_json(&deep), Err(JsonError::DepthLimit));
}

#[test]
fn a_literal_program_runs_and_reports_a_success_observation() {
    let response = response_of(&adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":42}}]",
        64,
    ));
    assert_eq!(member_str(&response, "request_id"), "r1");
    assert_eq!(member_str(&response, "status"), "success");
    assert_eq!(response.member("trap"), Some(&Json::Null));
    assert_eq!(
        response.member("stack"),
        Some(&parse_json("[{\"kind\":\"literal\",\"literal\":{\"type\":\"nat\",\"value\":42}}]").unwrap())
    );
    assert_eq!(
        response.member("cost"),
        Some(&parse_json("{\"steps\":1,\"total\":1}").unwrap())
    );
    assert_eq!(
        response.member("world_observation"),
        Some(&parse_json("{\"bytes\":[0]}").unwrap())
    );
    assert_eq!(
        response.member_names(),
        vec![
            "request_id",
            "status",
            "stack",
            "trace",
            "cost",
            "trap",
            "world_observation"
        ]
    );
}

#[test]
fn an_entry_word_other_than_main_runs_without_an_administrative_call() {
    let response = response_of(&adapter_request(
        "literal_int",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":42}}]",
        64,
    ));
    assert_eq!(member_str(&response, "status"), "success");
    assert_eq!(
        response.member("cost"),
        Some(&parse_json("{\"steps\":1,\"total\":1}").unwrap())
    );
}

#[test]
fn a_stack_fault_is_reported_as_a_classified_trap_not_a_success() {
    let response = response_of(&adapter_request("main", "[{\"op\":\"drop\"}]", 64));
    assert_eq!(member_str(&response, "status"), "trap");
    assert_eq!(member_str(&response, "trap"), "stack-fault");
}

#[test]
fn an_unknown_word_and_an_unknown_primitive_each_keep_their_class() {
    let response = response_of(&adapter_request(
        "main",
        "[{\"op\":\"call-word\",\"name\":\"missing\"}]",
        64,
    ));
    assert_eq!(member_str(&response, "status"), "trap");
    assert_eq!(member_str(&response, "trap"), "unknown-word");

    let response = response_of(&adapter_request(
        "main",
        "[{\"op\":\"prim\",\"primitive\":\"missing\"}]",
        64,
    ));
    assert_eq!(member_str(&response, "status"), "trap");
    assert_eq!(member_str(&response, "trap"), "unknown-primitive");
}

#[test]
fn fuel_exhaustion_is_reported_as_a_trap_with_its_own_class() {
    let response = response_of(&adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}}]",
        0,
    ));
    assert_eq!(member_str(&response, "status"), "trap");
    assert_eq!(member_str(&response, "trap"), "fuel-exhausted");
    assert_eq!(
        response.member("cost"),
        Some(&parse_json("{\"steps\":0,\"total\":0}").unwrap())
    );
}

#[test]
fn a_body_digest_the_compiler_computed_wrongly_is_refused_before_execution() {
    let honest = adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":42}}]",
        64,
    );
    let wrong = honest.replace(
        &render_hex(&body_digest(&adapter_code_of(
            "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":42}}]",
        ))),
        &render_hex(&evidence_digest(b"not the canonical body")),
    );
    let error = vm_run(&wrong).expect_err("a mis-signed word is refused");
    assert_eq!(error.code, "invalid-image");
    assert!(error.message.contains("malformed-instruction"), "{error:?}");
}

#[test]
fn a_request_outside_the_schema_is_refused_rather_than_repaired() {
    let base = adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":1}}]",
        64,
    );
    assert_eq!(
        vm_run(&base.replace("\"gamma_version\":\"0.1\"", "\"gamma_version\":\"0.2\""))
            .expect_err("gamma version")
            .code,
        "unsupported-gamma"
    );
    assert_eq!(
        vm_run(&base.replace("\"format_version\":1", "\"format_version\":2"))
            .expect_err("format version")
            .code,
        "unsupported-format"
    );
    assert_eq!(
        vm_run(&base.replace("\"entry\":\"main\"", "\"entry\":\"absent\""))
            .expect_err("entry word")
            .code,
        "unknown-entry"
    );
    assert_eq!(
        vm_run(&base.replace("\"fuel\":64", "\"fuel\":-1"))
            .expect_err("negative fuel")
            .code,
        "invalid-request"
    );
    assert_eq!(
        vm_run(&base.replace("\"request_id\":\"r1\"", "\"request_id\":\"\""))
            .expect_err("empty request id")
            .code,
        "invalid-request"
    );
    assert_eq!(
        vm_run(&base.replace("\"fuel\":64", "\"fuel\":64,\"extra\":1"))
            .expect_err("unknown member")
            .code,
        "invalid-request"
    );
    assert_eq!(
        vm_run("not json").expect_err("malformed").code,
        "malformed-json"
    );
    assert_eq!(
        vm_run(&base.replace("{\"op\":\"push-literal\"", "{\"op\":\"push-litteral\""))
            .expect_err("unknown instruction")
            .code,
        "invalid-request"
    );
}

#[test]
fn an_initial_stack_value_with_no_target_representation_is_refused() {
    let base = adapter_request("main", "[]", 64);
    for (encoded, code) in [
        (
            "[{\"kind\":\"literal\",\"literal\":{\"type\":\"unit\"}}]",
            "unsupported-value",
        ),
        (
            "[{\"kind\":\"world\",\"id\":0}]",
            "unsupported-value",
        ),
        (
            "[{\"kind\":\"quotation\",\"body\":[],\"usage\":\"many\"}]",
            "unsupported-value",
        ),
    ] {
        let request = base.replace("\"initial_stack\":[]", &{
            let mut member = String::from("\"initial_stack\":");
            member.push_str(encoded);
            member
        });
        assert_eq!(vm_run(&request).expect_err(encoded).code, code, "{encoded}");
    }

    let accepted = base.replace(
        "\"initial_stack\":[]",
        "\"initial_stack\":[{\"kind\":\"literal\",\"literal\":{\"type\":\"nat\",\"value\":7}}]",
    );
    let response = response_of(&accepted);
    assert_eq!(member_str(&response, "status"), "success");
    assert_eq!(
        response.member("stack"),
        Some(&parse_json("[{\"kind\":\"literal\",\"literal\":{\"type\":\"nat\",\"value\":7}}]").unwrap())
    );
}

#[test]
fn the_adapter_is_deterministic() {
    let request = adapter_request(
        "main",
        "[{\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":2}},\
          {\"op\":\"push-literal\",\"literal\":{\"kind\":\"int\",\"value\":40}},\
          {\"op\":\"prim\",\"primitive\":\"addNat\"}]",
        64,
    );
    let first = vm_run(&request).expect("accepted");
    let second = vm_run(&request).expect("accepted");
    assert_eq!(first, second);
    let response = parse_json(&first).expect("document");
    assert_eq!(
        response.member("stack"),
        Some(&parse_json("[{\"kind\":\"literal\",\"literal\":{\"type\":\"nat\",\"value\":42}}]").unwrap())
    );
    assert_eq!(
        response.member("cost"),
        Some(&parse_json("{\"steps\":3,\"total\":3}").unwrap())
    );
}

#[test]
fn a_refusal_renders_its_stable_code_alongside_its_message() {
    let error = vm_run("not json").expect_err("malformed");
    let rendered = render_adapter_error(&error);
    let parsed = parse_json(&rendered).expect("document");
    assert_eq!(member_str(&parsed, "status"), "error");
    assert_eq!(member_str(&parsed, "code"), "malformed-json");
    assert!(!member_str(&parsed, "error").is_empty());
}

// The `firth.observation.v1` response of the `firth.vm-run.v1` adapter:
// values, traces, frames and the verification label, rendered from the
// execution report. Request decoding lives in `adapter.rs`.

fn value_json(value: &Value, registry: &PrimitiveRegistry) -> Json {
    match value {
        Value::Int(number) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("literal"))),
            (
                String::from("literal"),
                Json::Object(vec![
                    (
                        String::from("type"),
                        Json::Str(String::from(if *number >= 0 { "nat" } else { "int" })),
                    ),
                    (String::from("value"), Json::Int(*number)),
                ]),
            ),
        ]),
        Value::Bool(flag) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("literal"))),
            (
                String::from("literal"),
                Json::Object(vec![
                    (String::from("type"), Json::Str(String::from("bool"))),
                    (String::from("value"), Json::Bool(*flag)),
                ]),
            ),
        ]),
        Value::Bytes(bytes) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("bytes"))),
            (String::from("value"), Json::Str(render_hex(bytes))),
        ]),
        // A quotation reports its usage, its canonical body digest, and its
        // complete body and capture state in the request grammar, so the
        // object minus `usage` and `body_digest` round-trips through
        // `adapter_operand_value`. A consumed slot and an administrative
        // `World` capture have no request spelling and are labelled as such.
        Value::Quotation(quotation) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("quotation"))),
            (
                String::from("usage"),
                Json::Str(String::from(if quotation.usage(registry) == Usage::Many {
                    "many"
                } else {
                    "linear"
                })),
            ),
            (
                String::from("body_digest"),
                Json::Str(render_hex(&sha256(&canonical_code(&quotation.code)))),
            ),
            (String::from("code"), code_json(&quotation.code)),
            (
                String::from("captures"),
                capture_slots_json(&quotation.captures, &quotation.consumed),
            ),
            (String::from("consumed"), consumed_json(&quotation.consumed)),
        ]),
        Value::PrimitiveValue { tag, bytes } => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("primitive"))),
            (String::from("tag"), Json::Int(*tag as i64)),
            (String::from("value"), Json::Str(render_hex(bytes))),
        ]),
        Value::World => Json::Object(vec![(
            String::from("kind"),
            Json::Str(String::from("world")),
        )]),
    }
}

/// One value in the request operand grammar (`adapter_operand_value`), so a
/// reported quotation body can be fed back to the adapter unchanged.
fn operand_value_json(value: &Value) -> Json {
    match value {
        Value::Int(number) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("int"))),
            (String::from("value"), Json::Int(*number)),
        ]),
        Value::Bool(flag) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("bool"))),
            (String::from("value"), Json::Bool(*flag)),
        ]),
        Value::Bytes(bytes) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("bytes"))),
            (String::from("value"), Json::Str(render_hex(bytes))),
        ]),
        Value::Quotation(quotation) => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("quotation"))),
            (String::from("code"), code_json(&quotation.code)),
            (
                String::from("captures"),
                capture_slots_json(&quotation.captures, &quotation.consumed),
            ),
            (String::from("consumed"), consumed_json(&quotation.consumed)),
        ]),
        Value::PrimitiveValue { tag, bytes } => Json::Object(vec![
            (String::from("kind"), Json::Str(String::from("primitive"))),
            (String::from("tag"), Json::Int(*tag as i64)),
            (String::from("bytes"), Json::Str(render_hex(bytes))),
        ]),
        // Only a trap can retain a captured `World`; it has no request form.
        Value::World => Json::Object(vec![(
            String::from("kind"),
            Json::Str(String::from("world")),
        )]),
    }
}

/// Capture slots in the request grammar, with a consumed slot labelled
/// `{"kind":"consumed"}` since its value has been moved out.
fn capture_slots_json(captures: &[Value], consumed: &[bool]) -> Json {
    Json::Array(
        captures
            .iter()
            .enumerate()
            .map(|(index, value)| {
                if consumed.get(index).copied().unwrap_or(false) {
                    Json::Object(vec![(
                        String::from("kind"),
                        Json::Str(String::from("consumed")),
                    )])
                } else {
                    operand_value_json(value)
                }
            })
            .collect(),
    )
}

fn consumed_json(consumed: &[bool]) -> Json {
    Json::Array(consumed.iter().map(|flag| Json::Bool(*flag)).collect())
}

/// One instruction in the request grammar (`adapter_instruction`).
fn instruction_json(instruction: &Instruction) -> Json {
    let op = |name: &str| (String::from("op"), Json::Str(String::from(name)));
    match (instruction.op, instruction.operand.as_ref()) {
        (Op::PushLiteral, Some(Operand::Literal(value))) => Json::Object(vec![
            op("push-literal"),
            (String::from("literal"), operand_value_json(value)),
        ]),
        (Op::PushQuote, Some(Operand::Quote(quotation))) => Json::Object(vec![
            op("push-quote"),
            (
                String::from("quotation"),
                operand_value_json(&Value::Quotation(quotation.clone())),
            ),
        ]),
        (Op::PushCapture, Some(Operand::Capture(index))) => Json::Object(vec![
            op("push-capture"),
            (String::from("index"), Json::Int(*index as i64)),
        ]),
        (Op::CallWord, Some(Operand::Word(name))) => Json::Object(vec![
            op("call-word"),
            (String::from("name"), Json::Str(name.clone())),
        ]),
        (Op::Prim, Some(Operand::Primitive(name))) => Json::Object(vec![
            op("prim"),
            (String::from("primitive"), Json::Str(name.clone())),
        ]),
        (Op::Dup, _) => Json::Object(vec![op("dup")]),
        (Op::Drop, _) => Json::Object(vec![op("drop")]),
        (Op::Swap, _) => Json::Object(vec![op("swap")]),
        (Op::Call, _) => Json::Object(vec![op("call")]),
        (Op::Dip, _) => Json::Object(vec![op("dip")]),
        (Op::Compose, _) => Json::Object(vec![op("compose")]),
        (Op::Quote, _) => Json::Object(vec![op("quote")]),
        (Op::If, _) => Json::Object(vec![op("if")]),
        // A decoded image never pairs these opcodes with another operand; the
        // opcode is still reported rather than silently dropped.
        (Op::PushLiteral, _) => Json::Object(vec![op("push-literal")]),
        (Op::PushQuote, _) => Json::Object(vec![op("push-quote")]),
        (Op::PushCapture, _) => Json::Object(vec![op("push-capture")]),
        (Op::CallWord, _) => Json::Object(vec![op("call-word")]),
        (Op::Prim, _) => Json::Object(vec![op("prim")]),
    }
}

fn code_json(code: &[Instruction]) -> Json {
    Json::Array(code.iter().map(instruction_json).collect())
}

fn stack_json(stack: &[Value], registry: &PrimitiveRegistry) -> Json {
    Json::Array(
        stack
            .iter()
            .map(|value| value_json(value, registry))
            .collect(),
    )
}

/// Frame capture slots in the observation grammar, with a consumed slot
/// labelled `{"kind":"consumed"}`.
fn frame_slots_json(values: &[Value], consumed: &[bool], registry: &PrimitiveRegistry) -> Json {
    Json::Array(
        values
            .iter()
            .enumerate()
            .map(|(index, value)| {
                if consumed.get(index).copied().unwrap_or(false) {
                    Json::Object(vec![(
                        String::from("kind"),
                        Json::Str(String::from("consumed")),
                    )])
                } else {
                    value_json(value, registry)
                }
            })
            .collect(),
    )
}

/// One administrative frame with every field `target-spec.md` §4 requires of
/// a residual configuration.
fn frame_json(frame: &FrameTrace, registry: &PrimitiveRegistry) -> Json {
    Json::Object(vec![
        (String::from("word"), Json::Str(frame.word.clone())),
        (String::from("pc"), Json::Int(frame.pc as i64)),
        (
            String::from("code_digest"),
            Json::Str(render_hex(&frame.code_digest)),
        ),
        (
            String::from("continuation"),
            Json::Str(String::from(frame.continuation.canonical())),
        ),
        (String::from("saved"), stack_json(&frame.saved, registry)),
        (
            String::from("captures"),
            frame_slots_json(&frame.capture_values, &frame.captures, registry),
        ),
        (String::from("consumed"), consumed_json(&frame.captures)),
    ])
}

fn frames_json(frames: &[FrameTrace], registry: &PrimitiveRegistry) -> Json {
    Json::Array(
        frames
            .iter()
            .map(|frame| frame_json(frame, registry))
            .collect(),
    )
}

/// Every trace event with its own charges, never a running total, plus the
/// frames in flight before the instruction ran.
fn trace_json(trace: &[TraceEvent], registry: &PrimitiveRegistry) -> Json {
    Json::Array(
        trace
            .iter()
            .enumerate()
            .map(|(index, event)| {
                Json::Object(vec![
                    (String::from("index"), Json::Int(index as i64)),
                    (String::from("word"), Json::Str(event.word.clone())),
                    (String::from("pc"), Json::Int(event.pc as i64)),
                    (String::from("stack"), stack_json(&event.stack, registry)),
                    (String::from("cost"), Json::Int(event.cost as i64)),
                    (
                        String::from("kernel_cost"),
                        Json::Int(event.kernel_cost as i64),
                    ),
                    (
                        String::from("image_version"),
                        Json::Int(event.image_version as i64),
                    ),
                    (String::from("frames"), frames_json(&event.frames, registry)),
                ])
            })
            .collect(),
    )
}

/// The `firth.vm-verification.v1` member: what this VM checked, stated in the
/// compiler's admission vocabulary so a consumer cannot mistake a structural
/// digest recheck for authenticated evidence.
fn verification_json() -> Json {
    Json::Object(vec![
        (
            String::from("schema"),
            Json::Str(String::from("firth.vm-verification.v1")),
        ),
        (
            String::from("admission"),
            Json::Str(String::from(VM_ADMISSION.admission)),
        ),
        (
            String::from("image_evidence"),
            Json::Str(String::from(VM_ADMISSION.image_evidence)),
        ),
        (
            String::from("refinements"),
            Json::Str(String::from(VM_ADMISSION.refinements)),
        ),
        (
            String::from("patch_admission"),
            Json::Str(String::from(VM_ADMISSION.patch_admission)),
        ),
    ])
}

/// The cost report.
///
/// `total` is this target's `kappa_vm` charge. `kernel` is the same total
/// projected from recorded per-step kernel charges. Administrative word entry
/// and capture restoration do not contribute to the implemented reference
/// model. Target charges and the existing VM fuel accounting are unchanged.
fn cost_json(steps: usize, cost: &CostReport) -> Json {
    Json::Object(vec![
        (String::from("steps"), Json::Int(steps as i64)),
        (String::from("total"), Json::Int(cost.total as i64)),
        (
            String::from("kernel"),
            Json::Int(cost.kernel_total() as i64),
        ),
    ])
}

fn world_json(observation: &[u8]) -> Json {
    Json::Object(vec![(
        String::from("bytes"),
        Json::Array(observation.iter().map(|byte| Json::Int(i64::from(*byte))).collect()),
    )])
}

/// The `firth.observation.v1` members in their pinned order, followed by the
/// VM-only extensions `frames`, `trap_subcode` and `verification` that the
/// manifest declares for this adapter.
#[allow(clippy::too_many_arguments)]
fn observation_json(
    request_id: &str,
    status: &str,
    stack: Json,
    trace: Json,
    cost: Json,
    trap: Json,
    world: Json,
    frames: Json,
    trap_subcode: Json,
) -> Json {
    Json::Object(vec![
        (String::from("request_id"), Json::Str(String::from(request_id))),
        (String::from("status"), Json::Str(String::from(status))),
        (String::from("stack"), stack),
        (String::from("trace"), trace),
        (String::from("cost"), cost),
        (String::from("trap"), trap),
        (String::from("world_observation"), world),
        (String::from("frames"), frames),
        (String::from("trap_subcode"), trap_subcode),
        (String::from("verification"), verification_json()),
    ])
}

/// Runs one decoded request and renders its `firth.observation.v1` response.
pub fn run_vm_request(request: &VmRunRequest, registry: &PrimitiveRegistry) -> Json {
    match execute_diagnostic_entry(
        &request.image,
        &request.entry,
        request.initial_stack.clone(),
        request.fuel,
        registry,
        None,
    ) {
        ExecutionOutcome::Complete(report) => observation_json(
            &request.request_id,
            "success",
            stack_json(&report.stack, registry),
            trace_json(&report.trace, registry),
            cost_json(report.trace.len(), &report.cost),
            Json::Null,
            world_json(report.world.observation()),
            frames_json(&report.frames, registry),
            Json::Null,
        ),
        ExecutionOutcome::Trap(trap) => observation_json(
            &request.request_id,
            "trap",
            stack_json(&trap.stack, registry),
            trace_json(&trap.trace, registry),
            cost_json(trap.trace.len(), &trap.cost),
            Json::Str(String::from(trap.code)),
            world_json(trap.world.observation()),
            frames_json(&trap.frames, registry),
            Json::Str(String::from(trap.error.stable_subcode())),
        ),
    }
}

/// The whole `firth.vm-run.v1` adapter: request bytes in, response bytes out.
pub fn vm_run(input: &str) -> Result<String, AdapterError> {
    let request = decode_vm_run_request(input)?;
    Ok(render_json(&run_vm_request(&request, &default_registry())))
}

/// The adapter on raw bytes: an input over `MAX_INPUT_BYTES` is refused as
/// `input-too-large` before UTF-8 decoding, so a multibyte character cut by the
/// caller's read bound is classified as oversize rather than as unreadable, and
/// bytes that are not UTF-8 are not a JSON document.
pub fn vm_run_bytes(input: &[u8]) -> Result<String, AdapterError> {
    if input.len() > MAX_INPUT_BYTES {
        return Err(AdapterError::new(
            JsonError::TooLarge.stable_code(),
            "the request exceeds the input bound",
        ));
    }
    let input = core::str::from_utf8(input).map_err(|_| {
        AdapterError::new(
            JsonError::Malformed.stable_code(),
            "the request is not an accepted JSON document",
        )
    })?;
    vm_run(input)
}

/// Renders a refusal as the same `{"status":"error","error":...}` shape the
/// reference-run adapter uses, with the stable code alongside it.
pub fn render_adapter_error(error: &AdapterError) -> String {
    render_json(&Json::Object(vec![
        (String::from("status"), Json::Str(String::from("error"))),
        (String::from("code"), Json::Str(error.code.clone())),
        (String::from("error"), Json::Str(error.message.clone())),
    ]))
}

// The `firth.vm-run.v1` adapter: one `firth.vm-execution.v1` request in, one
// `firth.observation.v1` response out, as pinned by
// `tools/loop/mvp_agent_manifest.toml`.
//
// The adapter has no semantic authority. It decodes the request into a word
// vector, seals and encodes that vector into canonical image bytes, and hands
// those bytes to the same `decode` every other caller uses. Every structural
// rule the target contract states, including each word's `body_digest`,
// is therefore enforced by the trusted decoder rather than by this file, and
// a compiler that computed a digest differently is caught here rather than
// silently executed.
//
// Nothing is reported as success that the target contract classifies
// otherwise: a malformed image, an unknown word or instruction, an invalid
// primitive, a stack fault, and fuel exhaustion each produce a classified
// observation with `status` `trap`.

/// The language-level `Gamma` version this adapter speaks, matching the
/// reference-run adapter's `gamma_version` check.
pub const ADAPTER_GAMMA_VERSION: &str = "0.1";

/// Why a request was refused before any execution happened.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AdapterError {
    /// A stable refusal code.
    pub code: String,
    /// A deterministic message naming the offending member or value.
    pub message: String,
}

impl AdapterError {
    fn new(code: &str, message: &str) -> Self {
        Self {
            code: String::from(code),
            message: String::from(message),
        }
    }

    fn field(code: &str, context: &str, detail: &str) -> Self {
        let mut message = String::from(context);
        message.push_str(": ");
        message.push_str(detail);
        Self {
            code: String::from(code),
            message,
        }
    }
}

fn object<'a>(
    value: &'a Json,
    context: &str,
    required: &[&str],
) -> Result<&'a Json, AdapterError> {
    let Json::Object(_) = value else {
        return Err(AdapterError::field("invalid-request", context, "expected object"));
    };
    for name in value.member_names() {
        if !required.contains(&name) {
            return Err(AdapterError::field("invalid-request", context, "unknown member"));
        }
    }
    for name in required {
        if value.member(name).is_none() {
            return Err(AdapterError::field("invalid-request", context, "missing member"));
        }
    }
    Ok(value)
}

fn member<'a>(value: &'a Json, context: &str, name: &str) -> Result<&'a Json, AdapterError> {
    value
        .member(name)
        .ok_or_else(|| AdapterError::field("invalid-request", context, "missing member"))
}

fn string(value: &Json, context: &str) -> Result<String, AdapterError> {
    match value {
        Json::Str(text) => Ok(text.clone()),
        _ => Err(AdapterError::field("invalid-request", context, "expected string")),
    }
}

fn nonempty_string(value: &Json, context: &str) -> Result<String, AdapterError> {
    let text = string(value, context)?;
    if text.is_empty() {
        return Err(AdapterError::field("invalid-request", context, "empty string"));
    }
    Ok(text)
}

fn unsigned(value: &Json, context: &str) -> Result<u64, AdapterError> {
    match value {
        Json::Int(number) if *number >= 0 => Ok(*number as u64),
        _ => Err(AdapterError::field(
            "invalid-request",
            context,
            "expected a non-negative integer",
        )),
    }
}

fn array<'a>(value: &'a Json, context: &str) -> Result<&'a [Json], AdapterError> {
    match value {
        Json::Array(items) => Ok(items),
        _ => Err(AdapterError::field("invalid-request", context, "expected array")),
    }
}

fn adapter_hex(text: &str, context: &str) -> Result<Vec<u8>, AdapterError> {
    if !text.len().is_multiple_of(2) {
        return Err(AdapterError::field("invalid-request", context, "odd-length hex"));
    }
    let bytes = text.as_bytes();
    let mut decoded = Vec::with_capacity(text.len() / 2);
    for pair in bytes.chunks(2) {
        let mut byte = 0u8;
        for digit in pair {
            let nibble = match digit {
                b'0'..=b'9' => digit - b'0',
                b'a'..=b'f' => digit - b'a' + 10,
                _ => {
                    return Err(AdapterError::field(
                        "invalid-request",
                        context,
                        "expected lowercase hex",
                    ));
                }
            };
            byte = byte * 16 + nibble;
        }
        decoded.push(byte);
    }
    Ok(decoded)
}

fn render_hex(bytes: &[u8]) -> String {
    let mut rendered = String::with_capacity(bytes.len() * 2);
    for byte in bytes {
        for shift in [4, 0] {
            let nibble = u32::from((byte >> shift) & 0xF);
            rendered.push(char::from_digit(nibble, 16).unwrap_or('0'));
        }
    }
    rendered
}

fn adapter_operand_value(value: &Json, context: &str, depth: usize) -> Result<Value, AdapterError> {
    if depth > MAX_NESTING {
        return Err(AdapterError::field("invalid-request", context, "nesting limit"));
    }
    let kind = string(member(value, context, "kind")?, context)?;
    match kind.as_str() {
        "int" => {
            object(value, context, &["kind", "value"])?;
            match member(value, context, "value")? {
                Json::Int(number) => Ok(Value::Int(*number)),
                _ => Err(AdapterError::field("invalid-request", context, "expected integer")),
            }
        }
        "bool" => {
            object(value, context, &["kind", "value"])?;
            match member(value, context, "value")? {
                Json::Bool(flag) => Ok(Value::Bool(*flag)),
                _ => Err(AdapterError::field("invalid-request", context, "expected boolean")),
            }
        }
        "bytes" => {
            object(value, context, &["kind", "value"])?;
            let text = string(member(value, context, "value")?, context)?;
            Ok(Value::Bytes(adapter_hex(&text, context)?))
        }
        "quotation" => {
            object(value, context, &["kind", "code", "captures", "consumed"])?;
            Ok(Value::Quotation(adapter_quotation(value, context, depth)?))
        }
        "primitive" => {
            object(value, context, &["kind", "tag", "bytes"])?;
            let tag = unsigned(member(value, context, "tag")?, context)?;
            let text = string(member(value, context, "bytes")?, context)?;
            Ok(Value::PrimitiveValue {
                tag,
                bytes: adapter_hex(&text, context)?,
            })
        }
        _ => Err(AdapterError::field("invalid-request", context, "unknown value kind")),
    }
}

fn adapter_quotation(value: &Json, context: &str, depth: usize) -> Result<Quotation, AdapterError> {
    let code = adapter_code(member(value, context, "code")?, context, depth + 1)?;
    let mut captures = Vec::new();
    for capture in array(member(value, context, "captures")?, context)? {
        captures.push(adapter_operand_value(capture, context, depth + 1)?);
    }
    let mut consumed = Vec::new();
    for flag in array(member(value, context, "consumed")?, context)? {
        match flag {
            Json::Bool(flag) => consumed.push(*flag),
            _ => {
                return Err(AdapterError::field(
                    "invalid-request",
                    context,
                    "expected boolean capture state",
                ));
            }
        }
    }
    Ok(Quotation {
        code,
        captures,
        consumed,
    })
}

fn adapter_code(value: &Json, context: &str, depth: usize) -> Result<Vec<Instruction>, AdapterError> {
    if depth > MAX_NESTING {
        return Err(AdapterError::field("invalid-request", context, "nesting limit"));
    }
    let mut code = Vec::new();
    for item in array(value, context)? {
        code.push(adapter_instruction(item, context, depth)?);
    }
    Ok(code)
}

fn adapter_instruction(
    value: &Json,
    context: &str,
    depth: usize,
) -> Result<Instruction, AdapterError> {
    let op = string(member(value, context, "op")?, context)?;
    let (op, operand) = match op.as_str() {
        "push-literal" => {
            object(value, context, &["op", "literal"])?;
            (
                Op::PushLiteral,
                Some(Operand::Literal(adapter_operand_value(
                    member(value, context, "literal")?,
                    context,
                    depth + 1,
                )?)),
            )
        }
        "push-quote" => {
            object(value, context, &["op", "quotation"])?;
            (
                Op::PushQuote,
                Some(Operand::Quote(adapter_quotation(
                    member(value, context, "quotation")?,
                    context,
                    depth + 1,
                )?)),
            )
        }
        "push-capture" => {
            object(value, context, &["op", "index"])?;
            (
                Op::PushCapture,
                Some(Operand::Capture(unsigned(
                    member(value, context, "index")?,
                    context,
                )?)),
            )
        }
        "call-word" => {
            object(value, context, &["op", "name"])?;
            (
                Op::CallWord,
                Some(Operand::Word(nonempty_string(
                    member(value, context, "name")?,
                    context,
                )?)),
            )
        }
        "prim" => {
            object(value, context, &["op", "primitive"])?;
            (
                Op::Prim,
                Some(Operand::Primitive(nonempty_string(
                    member(value, context, "primitive")?,
                    context,
                )?)),
            )
        }
        bare => {
            object(value, context, &["op"])?;
            let op = match bare {
                "dup" => Op::Dup,
                "drop" => Op::Drop,
                "swap" => Op::Swap,
                "call" => Op::Call,
                "dip" => Op::Dip,
                "compose" => Op::Compose,
                "quote" => Op::Quote,
                "if" => Op::If,
                _ => {
                    return Err(AdapterError::field(
                        "invalid-request",
                        context,
                        "unknown instruction",
                    ));
                }
            };
            (op, None)
        }
    };
    Ok(Instruction { op, operand })
}

fn adapter_word_entry(value: &Json, context: &str) -> Result<WordEntry, AdapterError> {
    object(
        value,
        context,
        &[
            "name",
            "erased_word_type",
            "code",
            "body_digest",
            "kernel_evidence_digest",
            "refinement_evidence_digest",
            "generation",
        ],
    )?;
    Ok(WordEntry {
        name: nonempty_string(member(value, context, "name")?, context)?,
        erased_word_type: nonempty_string(member(value, context, "erased_word_type")?, context)?,
        code: adapter_code(member(value, context, "code")?, context, 0)?,
        body_digest: adapter_hex(
            &string(member(value, context, "body_digest")?, context)?,
            context,
        )?,
        kernel_evidence_digest: adapter_hex(
            &string(member(value, context, "kernel_evidence_digest")?, context)?,
            context,
        )?,
        refinement_evidence_digest: adapter_hex(
            &string(member(value, context, "refinement_evidence_digest")?, context)?,
            context,
        )?,
        generation: unsigned(member(value, context, "generation")?, context)?,
    })
}

/// A value the reference adapter can also carry, so the same `initial_stack`
/// may be sent to both hosts.
///
/// The frozen kernel's `unit` literal has no v0.1 target representation, and a
/// kernel-shaped quotation would have to be lowered first, which is the
/// compiler's job and not this adapter's. Both are refused rather than
/// approximated.
fn adapter_reference_value(value: &Json, context: &str) -> Result<Value, AdapterError> {
    let kind = string(member(value, context, "kind")?, context)?;
    match kind.as_str() {
        "literal" => {
            object(value, context, &["kind", "literal"])?;
            let literal = member(value, context, "literal")?;
            let literal_type = string(member(literal, context, "type")?, context)?;
            match literal_type.as_str() {
                "nat" => {
                    object(literal, context, &["type", "value"])?;
                    let number = unsigned(member(literal, context, "value")?, context)?;
                    i64::try_from(number).map(Value::Int).map_err(|_| {
                        AdapterError::field("invalid-request", context, "literal exceeds the target integer")
                    })
                }
                "bool" => {
                    object(literal, context, &["type", "value"])?;
                    match member(literal, context, "value")? {
                        Json::Bool(flag) => Ok(Value::Bool(*flag)),
                        _ => Err(AdapterError::field("invalid-request", context, "expected boolean")),
                    }
                }
                "unit" => Err(AdapterError::field(
                    "unsupported-value",
                    context,
                    "the unit literal has no v0.1 target representation",
                )),
                _ => Err(AdapterError::field("invalid-request", context, "unknown literal type")),
            }
        }
        "quotation" => Err(AdapterError::field(
            "unsupported-value",
            context,
            "a kernel quotation must be lowered by the compiler before execution",
        )),
        "world" => Err(AdapterError::field(
            "unsupported-value",
            context,
            "World is administrative and is never supplied as an initial value",
        )),
        _ => Err(AdapterError::field("invalid-request", context, "unknown value kind")),
    }
}

/// One decoded `firth.vm-execution.v1` request.
pub struct VmRunRequest {
    /// Correlator echoed in the response.
    pub request_id: String,
    /// The image the target program was sealed into.
    pub image: Image,
    /// The word the run enters at.
    pub entry: String,
    /// Bottom-to-top initial value stack.
    pub initial_stack: Vec<Value>,
    /// The execution budget.
    pub fuel: u64,
}

/// Decodes and seals a `firth.vm-execution.v1` request.
///
/// The word vector is sealed and encoded, then decoded again through the
/// trusted decoder, so every digest, ordering, identifier and word-type rule
/// in the target contract is checked by the same code path a real image takes.
pub fn decode_vm_run_request(input: &str) -> Result<VmRunRequest, AdapterError> {
    let json = parse_json(input).map_err(|error| {
        AdapterError::new(error.stable_code(), "the request is not an accepted JSON document")
    })?;
    object(
        &json,
        "request",
        &[
            "request_id",
            "target_program",
            "initial_stack",
            "image",
            "gamma_version",
            "fuel",
        ],
    )?;
    let request_id = nonempty_string(member(&json, "request", "request_id")?, "request.request_id")?;
    let gamma_version = string(
        member(&json, "request", "gamma_version")?,
        "request.gamma_version",
    )?;
    if gamma_version != ADAPTER_GAMMA_VERSION {
        return Err(AdapterError::field(
            "unsupported-gamma",
            "request.gamma_version",
            "unsupported gamma version",
        ));
    }
    let fuel = unsigned(member(&json, "request", "fuel")?, "request.fuel")?;

    let program = member(&json, "request", "target_program")?;
    object(program, "target_program", &["format_version", "entry", "words"])?;
    let format_version = unsigned(
        member(program, "target_program", "format_version")?,
        "target_program.format_version",
    )?;
    if format_version != u64::from(FORMAT_VERSION) {
        return Err(AdapterError::field(
            "unsupported-format",
            "target_program.format_version",
            "unsupported target format version",
        ));
    }
    let entry = nonempty_string(
        member(program, "target_program", "entry")?,
        "target_program.entry",
    )?;
    let mut words = Vec::new();
    for word in array(
        member(program, "target_program", "words")?,
        "target_program.words",
    )? {
        words.push(adapter_word_entry(word, "target_program.words")?);
    }
    if !words.iter().any(|word| word.name == entry) {
        return Err(AdapterError::field(
            "unknown-entry",
            "target_program.entry",
            "the entry word is not in the target program",
        ));
    }

    let image_object = member(&json, "request", "image")?;
    object(image_object, "image", &["image_version", "gamma_version"])?;
    let image_version = unsigned(
        member(image_object, "image", "image_version")?,
        "image.image_version",
    )?;
    let image_gamma = unsigned(
        member(image_object, "image", "gamma_version")?,
        "image.gamma_version",
    )?;
    if image_gamma != GAMMA_VERSION {
        return Err(AdapterError::field(
            "unsupported-gamma",
            "image.gamma_version",
            "unsupported target registry version",
        ));
    }

    let mut initial_stack = Vec::new();
    for value in array(
        member(&json, "request", "initial_stack")?,
        "request.initial_stack",
    )? {
        initial_stack.push(adapter_reference_value(value, "request.initial_stack")?);
    }

    let sealed = seal_image(image_version, words);
    let image = decode(&encode_image(&sealed)).map_err(|error| {
        AdapterError::field(
            "invalid-image",
            "target_program",
            error.stable_code(),
        )
    })?;

    Ok(VmRunRequest {
        request_id,
        image,
        entry,
        initial_stack,
        fuel,
    })
}

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

fn stack_json(stack: &[Value], registry: &PrimitiveRegistry) -> Json {
    Json::Array(
        stack
            .iter()
            .map(|value| value_json(value, registry))
            .collect(),
    )
}

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
                ])
            })
            .collect(),
    )
}

fn cost_json(steps: usize, total: u64) -> Json {
    Json::Object(vec![
        (String::from("steps"), Json::Int(steps as i64)),
        (String::from("total"), Json::Int(total as i64)),
    ])
}

fn world_json(observation: &[u8]) -> Json {
    Json::Object(vec![(
        String::from("bytes"),
        Json::Array(observation.iter().map(|byte| Json::Int(i64::from(*byte))).collect()),
    )])
}

fn observation_json(
    request_id: &str,
    status: &str,
    stack: Json,
    trace: Json,
    cost: Json,
    trap: Json,
    world: Json,
) -> Json {
    Json::Object(vec![
        (String::from("request_id"), Json::Str(String::from(request_id))),
        (String::from("status"), Json::Str(String::from(status))),
        (String::from("stack"), stack),
        (String::from("trace"), trace),
        (String::from("cost"), cost),
        (String::from("trap"), trap),
        (String::from("world_observation"), world),
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
            cost_json(report.trace.len(), report.cost.total),
            Json::Null,
            world_json(report.world.observation()),
        ),
        ExecutionOutcome::Trap(trap) => observation_json(
            &request.request_id,
            "trap",
            stack_json(&trap.stack, registry),
            trace_json(&trap.trace, registry),
            cost_json(trap.trace.len(), trap.cost.total),
            Json::Str(String::from(trap.code)),
            world_json(trap.world.observation()),
        ),
    }
}

/// The whole `firth.vm-run.v1` adapter: request bytes in, response bytes out.
pub fn vm_run(input: &str) -> Result<String, AdapterError> {
    let request = decode_vm_run_request(input)?;
    Ok(render_json(&run_vm_request(&request, &default_registry())))
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

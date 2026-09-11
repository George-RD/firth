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

// The adapter functions below recurse over the parsed document. That recursion
// is bounded by the transport's `MAX_TRANSPORT_NESTING`, which admits every
// structure the sealed-image decoder admits (`MAX_NESTING`), so the adapter
// does not count levels a second time in a different unit. Past that depth
// either bound refuses; which one reports it depends on the operands carried.

fn adapter_operand_value(value: &Json, context: &str) -> Result<Value, AdapterError> {
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
        "quotation" => Ok(Value::Quotation(adapter_quotation(value, context)?)),
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

/// Decodes one quotation object, on the value path and the `push-quote`
/// operand path alike: the same envelope, the same `kind`, and the same
/// refusal of a capture already marked consumed, which no static quotation can
/// carry because only an executing frame consumes a slot.
fn adapter_quotation(value: &Json, context: &str) -> Result<Quotation, AdapterError> {
    object(value, context, &["kind", "code", "captures", "consumed"])?;
    if string(member(value, context, "kind")?, context)? != "quotation" {
        return Err(AdapterError::field(
            "invalid-request",
            context,
            "expected a quotation",
        ));
    }
    let code = adapter_code(member(value, context, "code")?, context)?;
    let mut captures = Vec::new();
    for capture in array(member(value, context, "captures")?, context)? {
        captures.push(adapter_operand_value(capture, context)?);
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
    // Canonical encoding indexes a bitmap sized from captures. Validate the
    // shape before sealing/hashing; round-trip decoding is too late here.
    if captures.len() != consumed.len() {
        return Err(AdapterError::field(
            "invalid-request",
            context,
            "capture state length must match captures",
        ));
    }
    if consumed.iter().any(|flag| *flag) {
        return Err(AdapterError::field(
            "invalid-request",
            context,
            "a static quotation cannot carry a consumed capture",
        ));
    }
    Ok(Quotation {
        code,
        captures,
        consumed,
    })
}

fn adapter_code(value: &Json, context: &str) -> Result<Vec<Instruction>, AdapterError> {
    let mut code = Vec::new();
    for item in array(value, context)? {
        code.push(adapter_instruction(item, context)?);
    }
    Ok(code)
}

fn adapter_instruction(value: &Json, context: &str) -> Result<Instruction, AdapterError> {
    let op = string(member(value, context, "op")?, context)?;
    let (op, operand) = match op.as_str() {
        "push-literal" => {
            object(value, context, &["op", "literal"])?;
            (
                Op::PushLiteral,
                Some(Operand::Literal(adapter_operand_value(
                    member(value, context, "literal")?,
                    context,
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
        code: adapter_code(member(value, context, "code")?, context)?,
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

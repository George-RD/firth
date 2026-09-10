// Decoding one `firth.vm-execution.v1` request: the portable initial-stack
// values, the request envelope and its bounds, and the seal-encode-decode
// round trip that hands every structural rule to the trusted decoder.

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
    if fuel > MAX_FUEL {
        return Err(AdapterError::field(
            "invalid-request",
            "request.fuel",
            "fuel exceeds the adapter budget",
        ));
    }

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

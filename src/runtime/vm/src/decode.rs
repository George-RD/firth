fn decode_word(reader: &mut Reader<'_>) -> Result<WordEntry, VmError> {
    let name = reader.string()?;
    if !is_canonical_identifier(name.as_bytes()) {
        return Err(VmError::InvalidIdentifier);
    }
    let erased_word_type = reader.string()?;
    if !is_canonical_word_type(&erased_word_type) {
        return Err(VmError::InvalidWordType);
    }
    let code = decode_code(reader, 0)?;
    let body_digest = reader.digest()?;
    let kernel_evidence_digest = reader.digest()?;
    let refinement_evidence_digest = reader.digest()?;
    if body_digest != sha256(&canonical_code(&code))
        || is_zero_digest(&kernel_evidence_digest)
        || is_zero_digest(&refinement_evidence_digest)
    {
        return Err(VmError::InvalidDigest);
    }
    let generation = reader.unsigned()?;
    Ok(WordEntry {
        name,
        erased_word_type,
        code,
        body_digest,
        kernel_evidence_digest,
        refinement_evidence_digest,
        generation,
    })
}

fn decode_code(reader: &mut Reader<'_>, depth: usize) -> Result<Vec<Instruction>, VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    let count = reader.count()?;
    let mut code = Vec::with_capacity(count);
    for _ in 0..count {
        code.push(decode_instruction(reader, depth)?);
    }
    Ok(code)
}

fn decode_instruction(reader: &mut Reader<'_>, depth: usize) -> Result<Instruction, VmError> {
    let opcode = reader.byte()?;
    let (op, operand) = match opcode {
        0 => (
            Op::PushLiteral,
            Some(Operand::Literal(decode_literal(reader)?)),
        ),
        1 => (
            Op::PushQuote,
            Some(Operand::Quote(decode_quotation(reader, depth + 1)?)),
        ),
        2 => (Op::PushCapture, Some(Operand::Capture(reader.unsigned()?))),
        3 => (Op::Dup, None),
        4 => (Op::Drop, None),
        5 => (Op::Swap, None),
        6 => (Op::Call, None),
        7 => (Op::Dip, None),
        8 => (Op::Compose, None),
        9 => (Op::Quote, None),
        10 => (Op::If, None),
        11 => {
            let name = reader.string()?;
            if !is_canonical_identifier(name.as_bytes()) {
                return Err(VmError::InvalidIdentifier);
            }
            (Op::CallWord, Some(Operand::Word(name)))
        }
        12 => {
            let name = reader.string()?;
            if !is_canonical_identifier(name.as_bytes()) {
                return Err(VmError::InvalidIdentifier);
            }
            (Op::Prim, Some(Operand::Primitive(name)))
        }
        other => return Err(VmError::InvalidOpcode(other)),
    };
    Ok(Instruction { op, operand })
}

fn decode_quotation(reader: &mut Reader<'_>, depth: usize) -> Result<Quotation, VmError> {
    let code = decode_code(reader, depth)?;
    let capture_count = reader.count()?;
    let bitmap_bytes = reader.count_for(capture_count.div_ceil(8))?;
    let mut consumed = Vec::with_capacity(capture_count);
    for index in 0..capture_count {
        consumed.push(bitmap_bytes[index / 8] & (1 << (index % 8)) != 0);
    }
    if capture_count % 8 != 0
        && bitmap_bytes
            .last()
            .is_some_and(|byte| byte & !((1 << (capture_count % 8)) - 1) != 0)
    {
        return Err(VmError::InvalidCaptureBitmap);
    }
    let mut captures = Vec::with_capacity(capture_count);
    for _ in 0..capture_count {
        captures.push(decode_value(reader, depth)?);
    }
    validate_capture_indices(&code, capture_count as u64)?;
    Ok(Quotation {
        code,
        captures,
        consumed,
    })
}

fn validate_capture_indices(code: &[Instruction], count: u64) -> Result<(), VmError> {
    for instruction in code {
        match instruction.operand.as_ref() {
            Some(Operand::Capture(index)) if *index >= count => {
                return Err(VmError::InvalidCaptureIndex(*index));
            }
            Some(Operand::Quote(quotation)) => {
                validate_capture_indices(&quotation.code, quotation.captures.len() as u64)?
            }
            _ => {}
        }
    }
    Ok(())
}

fn decode_value(reader: &mut Reader<'_>, depth: usize) -> Result<Value, VmError> {
    match reader.byte()? {
        0 => Ok(Value::Int(reader.signed()?)),
        1 => match reader.byte()? {
            0 => Ok(Value::Bool(false)),
            1 => Ok(Value::Bool(true)),
            value => Err(VmError::InvalidBoolean(value)),
        },
        2 => Ok(Value::Bytes(reader.bytes()?.to_vec())),
        3 => Ok(Value::Quotation(decode_quotation(reader, depth + 1)?)),
        4 => Ok(Value::PrimitiveValue {
            tag: reader.unsigned()?,
            bytes: reader.bytes()?.to_vec(),
        }),
        5 => Ok(Value::World),
        tag => Err(VmError::InvalidValueTag(tag)),
    }
}

fn decode_literal(reader: &mut Reader<'_>) -> Result<Value, VmError> {
    match reader.byte()? {
        0 => Ok(Value::Int(reader.signed()?)),
        1 => match reader.byte()? {
            0 => Ok(Value::Bool(false)),
            1 => Ok(Value::Bool(true)),
            value => Err(VmError::InvalidBoolean(value)),
        },
        2 => Ok(Value::Bytes(reader.bytes()?.to_vec())),
        3 | 4 => Err(VmError::InvalidLiteralEncoding),
        tag => Err(VmError::InvalidValueTag(tag)),
    }
}

pub fn execute(image: &Image) -> Result<Vec<Value>, VmError> {
    Ok(execute_report(image, DEFAULT_FUEL)?.stack)
}

pub fn execute_with_fuel(image: &Image, fuel: u64) -> Result<Vec<Value>, VmError> {
    Ok(execute_report(image, fuel)?.stack)
}

pub fn execute_report(image: &Image, fuel: u64) -> Result<ExecutionReport, VmError> {
    execute_report_with_registry(image, fuel, &default_registry())
}

pub fn execute_report_with_registry(
    image: &Image,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> Result<ExecutionReport, VmError> {
    execute_report_with_stack(image, Vec::new(), fuel, registry)
}

/// Executes a checked image with an explicit bottom-to-top initial value stack.
/// This is the boundary used by the Lean differential fixture corpus.
pub fn execute_report_with_stack(
    image: &Image,
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> Result<ExecutionReport, VmError> {
    let resolver = StaticWordResolver { image };
    let word = resolver.resolve("main")?;
    execute_report_resolved(word, &resolver, initial_stack, fuel, registry)
}

fn execute_report_resolved(
    resolved: ResolvedWord<'_>,
    resolver: &dyn WordResolver,
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> Result<ExecutionReport, VmError> {
    let (image, word) = resolved.parts();
    validate_image(image)?;
    if registry.version != image.gamma_version {
        return Err(VmError::UnsupportedGamma(registry.version));
    }
    for value in &initial_stack {
        validate_value_structure(value, 0)?;
    }
    if initial_stack
        .iter()
        .any(|value| !matches!(value, Value::World) && value_contains_world(value))
    {
        return Err(VmError::WorldFault);
    }
    if world_count(&initial_stack)? > 1 {
        return Err(VmError::WorldFault);
    }
    let world_active = world_count(&initial_stack)? != 0;
    let mut state = Machine {
        stack: initial_stack
            .into_iter()
            .map(|value| {
                if matches!(value, Value::World) {
                    Slot::WorldMarker
                } else {
                    Slot::Value(value)
                }
            })
            .collect(),
        world: WorldState {
            observation: vec![0],
            active: world_active,
        },
        fuel,
        cost: CostReport {
            total: 0,
            instructions: 0,
            word_entries: 0,
            primitives: 0,
            steps: Vec::new(),
        },
        trace: Vec::new(),
        location: None,
        linear_quotes: Vec::new(),
        frames: Vec::new(),
        allocation_budget: None,
    };
    let environment = ExecutionEnvironment { resolver, registry };
    run_code(
        &word.code,
        &mut [],
        &mut [],
        image,
        &environment,
        &mut state,
        "main",
    )?;
    Ok(ExecutionReport {
        stack: terminal_stack(state.stack, registry)?,
        cost: state.cost,
        trace: state.trace,
        world: state.world,
        frames: Vec::new(),
    })
}

/// Executes while retaining deterministic state and location information on a trap.
pub fn execute_diagnostic(
    image: &Image,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> ExecutionOutcome {
    execute_diagnostic_with_stack(image, Vec::new(), fuel, registry)
}

pub fn execute_diagnostic_with_stack(
    image: &Image,
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> ExecutionOutcome {
    execute_diagnostic_with_stack_budget(image, initial_stack, fuel, registry, None)
}

pub fn execute_diagnostic_with_stack_budget(
    image: &Image,
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
    allocation_budget: Option<usize>,
) -> ExecutionOutcome {
    if let Err(error) = validate_image(image) {
        return diagnostic_trap(error, empty_machine());
    }
    if registry.version != image.gamma_version {
        return diagnostic_trap(VmError::UnsupportedGamma(registry.version), empty_machine());
    }
    let resolver = StaticWordResolver { image };
    let Ok(resolved) = resolver.resolve("main") else {
        return diagnostic_trap(VmError::UnknownWord(String::from("main")), empty_machine());
    };
    let (_, word) = resolved.parts();
    for value in &initial_stack {
        if let Err(error) = validate_value_structure(value, 0) {
            return diagnostic_trap(error, empty_machine());
        }
    }
    if initial_stack
        .iter()
        .any(|value| !matches!(value, Value::World) && value_contains_world(value))
    {
        return diagnostic_trap(VmError::WorldFault, empty_machine());
    }
    match world_count(&initial_stack) {
        Ok(_) => {}
        Err(error) => return diagnostic_trap(error, empty_machine()),
    }
    let world_active = match world_count(&initial_stack) {
        Ok(count) => count != 0,
        Err(error) => return diagnostic_trap(error, empty_machine()),
    };
    let mut state = Machine {
        stack: initial_stack
            .into_iter()
            .map(|value| {
                if matches!(value, Value::World) {
                    Slot::WorldMarker
                } else {
                    Slot::Value(value)
                }
            })
            .collect(),
        world: WorldState {
            observation: vec![0],
            active: world_active,
        },
        fuel,
        cost: empty_cost(),
        trace: Vec::new(),
        location: None,
        linear_quotes: Vec::new(),
        frames: Vec::new(),
        allocation_budget,
    };
    let environment = ExecutionEnvironment {
        resolver: &resolver,
        registry,
    };
    match run_code(
        &word.code,
        &mut [],
        &mut [],
        image,
        &environment,
        &mut state,
        "main",
    ) {
        Ok(()) => match terminal_stack(state.stack.clone(), registry) {
            Ok(stack) => ExecutionOutcome::Complete(ExecutionReport {
                stack,
                cost: state.cost,
                trace: state.trace,
                world: state.world,
                frames: state.frames,
            }),
            Err(error) => diagnostic_trap(error, state),
        },
        Err(error) => diagnostic_trap(error, state),
    }
}

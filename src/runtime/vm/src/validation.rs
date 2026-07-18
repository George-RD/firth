#[allow(clippy::too_many_arguments)]
fn validate_before_charge(
    instruction: &Instruction,
    machine: &Machine,
    captures: &[Value],
    consumed: &[bool],
    image: &Image,
    registry: &PrimitiveRegistry,
    current_word: &str,
    pc: usize,
) -> Result<(), VmError> {
    let top = || machine.stack.last().ok_or(VmError::StackFault);
    match instruction.op {
        Op::PushLiteral => match instruction.operand.as_ref() {
            Some(Operand::Literal(value)) if is_literal(value) => Ok(()),
            _ => Err(VmError::InvalidLiteralEncoding),
        },
        Op::PushQuote => match instruction.operand.as_ref() {
            Some(Operand::Quote(quotation)) => {
                if quotation.usage(registry) == Usage::Linear {
                    let code = canonical_code(&quotation.code);
                    if machine
                        .linear_quotes
                        .iter()
                        .any(|(word, origin_pc, origin_code)| {
                            word == current_word && *origin_pc == pc && *origin_code == code
                        })
                    {
                        return Err(VmError::ResourceFault);
                    }
                }
                Ok(())
            }
            _ => Err(VmError::StackFault),
        },
        Op::PushCapture => {
            let Some(Operand::Capture(index)) = instruction.operand.as_ref() else {
                return Err(VmError::StackFault);
            };
            let index =
                usize::try_from(*index).map_err(|_| VmError::InvalidCaptureIndex(*index))?;
            if index >= captures.len() || index >= consumed.len() {
                return Err(VmError::InvalidCaptureIndex(index as u64));
            }
            if consumed[index] {
                Err(VmError::ResourceFault)
            } else {
                Ok(())
            }
        }
        Op::Dup | Op::Drop => match top()? {
            Slot::Value(value) if value.usage(registry) == Usage::Many => Ok(()),
            Slot::Value(_) | Slot::WorldMarker => Err(VmError::ResourceFault),
        },
        Op::Swap => {
            if machine.stack.len() < 2 {
                Err(VmError::StackFault)
            } else {
                Ok(())
            }
        }
        Op::Call => match top()? {
            Slot::Value(Value::Quotation(_)) => Ok(()),
            Slot::Value(_) => Err(VmError::TypeFault),
            Slot::WorldMarker => Err(VmError::ResourceFault),
        },
        Op::Dip => {
            if machine.stack.len() < 2 {
                return Err(VmError::StackFault);
            }
            match &machine.stack[machine.stack.len() - 1] {
                Slot::Value(Value::Quotation(_)) => Ok(()),
                Slot::Value(_) => Err(VmError::TypeFault),
                Slot::WorldMarker => Err(VmError::ResourceFault),
            }
        }
        Op::Compose => {
            if machine.stack.len() < 2 {
                return Err(VmError::StackFault);
            }
            for slot in &machine.stack[machine.stack.len() - 2..] {
                if !matches!(slot, Slot::Value(Value::Quotation(_))) {
                    return Err(VmError::TypeFault);
                }
            }
            Ok(())
        }
        Op::Quote => match top()? {
            Slot::Value(_) => Ok(()),
            Slot::WorldMarker => Ok(()),
        },
        Op::If => {
            if machine.stack.len() < 3 {
                return Err(VmError::StackFault);
            }
            let len = machine.stack.len();
            if !matches!(&machine.stack[len - 3], Slot::Value(Value::Bool(_))) {
                return Err(VmError::TypeFault);
            }
            if !matches!(&machine.stack[len - 2], Slot::Value(Value::Quotation(_)))
                || !matches!(&machine.stack[len - 1], Slot::Value(Value::Quotation(_)))
            {
                return Err(VmError::TypeFault);
            }
            Ok(())
        }
        Op::CallWord => {
            let Some(Operand::Word(name)) = instruction.operand.as_ref() else {
                return Err(VmError::StackFault);
            };
            if image.words.iter().any(|word| word.name == *name) {
                Ok(())
            } else {
                Err(VmError::UnknownWord(name.clone()))
            }
        }
        Op::Prim => {
            let Some(Operand::Primitive(name)) = instruction.operand.as_ref() else {
                return Err(VmError::InvalidPrimitiveTag);
            };
            let definition = registry
                .definitions
                .iter()
                .find(|definition| definition.name == name)
                .ok_or_else(|| VmError::UnknownPrimitive(name.clone()))?;
            validate_primitive_inputs(machine, definition, registry)
        }
    }
}

fn terminal_stack(stack: Vec<Slot>, registry: &PrimitiveRegistry) -> Result<Vec<Value>, VmError> {
    let mut result = Vec::with_capacity(stack.len());
    for slot in stack {
        match slot {
            Slot::WorldMarker => {}
            Slot::Value(value) if value.usage(registry) == Usage::Many => result.push(value),
            Slot::Value(_) => return Err(VmError::ResourceFault),
        }
    }
    Ok(result)
}

fn ensure_captures_consumed(
    quotation: &Quotation,
    registry: &PrimitiveRegistry,
) -> Result<(), VmError> {
    if quotation
        .captures
        .iter()
        .zip(&quotation.consumed)
        .any(|(value, consumed)| value.usage(registry) == Usage::Linear && !consumed)
    {
        Err(VmError::ResourceFault)
    } else {
        Ok(())
    }
}

fn pop_quotation(machine: &mut Machine) -> Result<Quotation, VmError> {
    match machine.stack.pop().ok_or(VmError::StackFault)? {
        Slot::Value(Value::Quotation(value)) => Ok(value),
        Slot::Value(_) => Err(VmError::TypeFault),
        Slot::WorldMarker => Err(VmError::ResourceFault),
    }
}

fn rebase_captures(code: &[Instruction], offset: usize) -> Result<Vec<Instruction>, VmError> {
    code.iter()
        .map(|instruction| {
            let mut instruction = instruction.clone();
            if let Some(Operand::Capture(index)) = instruction.operand.as_mut() {
                *index = index
                    .checked_add(offset as u64)
                    .ok_or(VmError::LengthLimit)?;
            }
            Ok(instruction)
        })
        .collect()
}

fn run_primitive(
    name: &str,
    registry: &PrimitiveRegistry,
    machine: &mut Machine,
) -> Result<(), VmError> {
    let definition = registry
        .definitions
        .iter()
        .find(|definition| definition.name == name)
        .ok_or_else(|| VmError::UnknownPrimitive(String::from(name)))?;
    validate_primitive_inputs(machine, definition, registry)?;
    let old_len = machine.stack.len();
    let old_stack = machine.stack.clone();
    let old_world = machine.world.clone();
    let mut context = PrimitiveContext {
        stack: &mut machine.stack,
        world: &mut machine.world,
    };
    let result = (definition.handler)(&mut context).map_err(|error| match error {
        VmError::StackFault
        | VmError::TypeFault
        | VmError::ResourceFault
        | VmError::AllocationFailure => error,
        _ => VmError::PrimitiveFault,
    });
    if let Err(error) = result {
        machine.stack = old_stack;
        machine.world = old_world;
        return Err(error);
    }
    if let Err(error) = validate_primitive_outputs(machine, definition, registry, old_len) {
        machine.stack = old_stack;
        machine.world = old_world;
        return Err(error);
    }
    Ok(())
}

fn validate_primitive_inputs(
    machine: &Machine,
    definition: &PrimitiveDefinition,
    registry: &PrimitiveRegistry,
) -> Result<(), VmError> {
    if machine.stack.len() < definition.input.len() {
        return Err(VmError::StackFault);
    }
    let start = machine.stack.len() - definition.input.len();
    for (slot, usage) in machine.stack[start..].iter().zip(definition.input) {
        match slot {
            Slot::WorldMarker if *usage != Usage::Linear => return Err(VmError::TypeFault),
            Slot::WorldMarker => {}
            Slot::Value(value) if value.usage(registry) != *usage => {
                return Err(VmError::TypeFault);
            }
            Slot::Value(_) => {}
        }
    }
    for (slot, kind) in machine.stack[start..]
        .iter()
        .zip(definition.signature().input)
    {
        if !slot_matches_type(slot, *kind) {
            return Err(VmError::TypeFault);
        }
    }
    Ok(())
}

fn validate_primitive_outputs(
    machine: &Machine,
    definition: &PrimitiveDefinition,
    registry: &PrimitiveRegistry,
    old_len: usize,
) -> Result<(), VmError> {
    let expected_len = old_len
        .checked_sub(definition.input.len())
        .and_then(|len| len.checked_add(definition.output.len()))
        .ok_or(VmError::PrimitiveFault)?;
    if machine.stack.len() != expected_len {
        return Err(VmError::PrimitiveFault);
    }
    let start = machine.stack.len() - definition.output.len();
    for (slot, usage) in machine.stack[start..].iter().zip(definition.output) {
        match (slot, usage) {
            (Slot::WorldMarker, Usage::Linear) => {}
            (Slot::Value(value), expected) if value.usage(registry) == *expected => {}
            _ => return Err(VmError::PrimitiveFault),
        }
    }
    for (slot, kind) in machine.stack[start..]
        .iter()
        .zip(definition.signature().output)
    {
        if !slot_matches_type(slot, *kind) {
            return Err(VmError::PrimitiveFault);
        }
    }
    Ok(())
}

fn slot_matches_type(slot: &Slot, kind: PrimitiveType) -> bool {
    match kind {
        PrimitiveType::Int => matches!(slot, Slot::Value(Value::Int(_))),
        PrimitiveType::Bool => matches!(slot, Slot::Value(Value::Bool(_))),
        PrimitiveType::Bytes => matches!(slot, Slot::Value(Value::Bytes(_))),
        PrimitiveType::Quotation => matches!(slot, Slot::Value(Value::Quotation(_))),
        PrimitiveType::World => matches!(slot, Slot::WorldMarker),
        PrimitiveType::Any => true,
    }
}

fn pop_int_from(stack: &mut Vec<Slot>) -> Result<i64, VmError> {
    match stack.pop().ok_or(VmError::StackFault)? {
        Slot::Value(Value::Int(value)) => Ok(value),
        Slot::Value(_) => Err(VmError::TypeFault),
        Slot::WorldMarker => Err(VmError::ResourceFault),
    }
}

fn validate_image(image: &Image) -> Result<(), VmError> {
    if image.format_version != FORMAT_VERSION || image.gamma_version != GAMMA_VERSION {
        return Err(VmError::InvalidDigest);
    }
    if image.dictionary_digest.len() != DIGEST_BYTES || image.image_digest.len() != DIGEST_BYTES {
        return Err(VmError::InvalidDigestLength);
    }
    for pair in image.words.windows(2) {
        if pair[0].name.as_bytes() >= pair[1].name.as_bytes() {
            return Err(if pair[0].name == pair[1].name {
                VmError::DuplicateWord
            } else {
                VmError::UnsortedWords
            });
        }
    }
    for word in &image.words {
        if !is_canonical_identifier(word.name.as_bytes())
            || !is_canonical_word_type(&word.erased_word_type)
        {
            return Err(if !is_canonical_identifier(word.name.as_bytes()) {
                VmError::InvalidIdentifier
            } else {
                VmError::InvalidWordType
            });
        }
        validate_code_structure(&word.code, 0)?;
        if code_contains_world(&word.code) {
            return Err(VmError::WorldFault);
        }
        if word.body_digest.len() != DIGEST_BYTES
            || word.kernel_evidence_digest.len() != DIGEST_BYTES
            || word.refinement_evidence_digest.len() != DIGEST_BYTES
        {
            return Err(VmError::InvalidDigestLength);
        }
        if word.body_digest != sha256(&canonical_code(&word.code))
            || is_zero_digest(&word.kernel_evidence_digest)
            || is_zero_digest(&word.refinement_evidence_digest)
        {
            return Err(VmError::InvalidDigest);
        }
    }
    if image.dictionary_digest != sha256(&canonical_dictionary(&image.words))
        || image.image_digest
            != sha256(&canonical_image_identity(
                image.format_version,
                image.image_version,
                image.gamma_version,
                &image.dictionary_digest,
            ))
    {
        return Err(VmError::InvalidDigest);
    }
    Ok(())
}

fn validate_code_structure(code: &[Instruction], depth: usize) -> Result<(), VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    for instruction in code {
        match instruction.op {
            Op::PushLiteral => match instruction.operand.as_ref() {
                Some(Operand::Literal(value)) if is_literal(value) => {
                    validate_value_structure(value, depth)?;
                }
                _ => return Err(VmError::InvalidLiteralEncoding),
            },
            Op::PushQuote => match instruction.operand.as_ref() {
                Some(Operand::Quote(quotation)) => {
                    validate_quotation_structure(quotation, depth + 1)?;
                    validate_code_structure(&quotation.code, depth + 1)?;
                }
                _ => return Err(VmError::StackFault),
            },
            Op::PushCapture => match instruction.operand.as_ref() {
                Some(Operand::Capture(_)) => {}
                _ => return Err(VmError::StackFault),
            },
            Op::CallWord => match instruction.operand.as_ref() {
                Some(Operand::Word(name)) if is_canonical_identifier(name.as_bytes()) => {}
                _ => return Err(VmError::InvalidIdentifier),
            },
            Op::Prim => match instruction.operand.as_ref() {
                Some(Operand::Primitive(name)) if is_canonical_identifier(name.as_bytes()) => {}
                _ => return Err(VmError::InvalidPrimitiveTag),
            },
            Op::Dup
            | Op::Drop
            | Op::Swap
            | Op::Call
            | Op::Dip
            | Op::Compose
            | Op::Quote
            | Op::If
                if instruction.operand.is_some() =>
            {
                return Err(VmError::StackFault);
            }
            _ => {}
        }
    }
    Ok(())
}

fn validate_value_structure(value: &Value, depth: usize) -> Result<(), VmError> {
    match value {
        Value::Quotation(quotation) => {
            validate_quotation_structure(quotation, depth + 1)?;
            validate_code_structure(&quotation.code, depth + 1)?;
        }
        Value::PrimitiveValue { tag, .. } if default_registry().value_usage(*tag).is_none() => {
            return Err(VmError::InvalidPrimitiveTag);
        }
        Value::PrimitiveValue { .. } => {}
        Value::Int(_) | Value::Bool(_) | Value::Bytes(_) | Value::World => {}
    }
    Ok(())
}

fn world_count(values: &[Value]) -> Result<usize, VmError> {
    fn count(value: &Value) -> usize {
        match value {
            Value::World => 1,
            Value::Quotation(quotation) => quotation.captures.iter().map(count).sum(),
            Value::Int(_) | Value::Bool(_) | Value::Bytes(_) | Value::PrimitiveValue { .. } => 0,
        }
    }
    let total: usize = values.iter().map(count).sum();
    if total > 1 {
        Err(VmError::WorldFault)
    } else {
        Ok(total)
    }
}

fn code_contains_world(code: &[Instruction]) -> bool {
    code.iter()
        .any(|instruction| match instruction.operand.as_ref() {
            Some(Operand::Literal(value)) => value_contains_world(value),
            Some(Operand::Quote(quotation)) => {
                quotation.captures.iter().any(value_contains_world)
                    || code_contains_world(&quotation.code)
            }
            _ => false,
        })
}

fn value_contains_world(value: &Value) -> bool {
    match value {
        Value::World => true,
        Value::Quotation(quotation) => {
            quotation.captures.iter().any(value_contains_world)
                || code_contains_world(&quotation.code)
        }
        Value::Int(_) | Value::Bool(_) | Value::Bytes(_) | Value::PrimitiveValue { .. } => false,
    }
}

fn validate_quotation_structure(quotation: &Quotation, depth: usize) -> Result<(), VmError> {
    if depth > MAX_NESTING || quotation.consumed.len() != quotation.captures.len() {
        return Err(if depth > MAX_NESTING {
            VmError::NestingLimit
        } else {
            VmError::InvalidCaptureBitmap
        });
    }
    validate_code_structure(&quotation.code, depth)?;
    for capture in &quotation.captures {
        validate_value_structure(capture, depth + 1)?;
    }
    Ok(())
}

fn is_literal(value: &Value) -> bool {
    matches!(value, Value::Int(_) | Value::Bool(_) | Value::Bytes(_))
}

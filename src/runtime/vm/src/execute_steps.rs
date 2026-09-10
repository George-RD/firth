// One function per opcode, so that only the active path's temporaries
// occupy native stack at each level of quotation or word nesting (see the
// note above `run_code` in `execute.rs`).

fn step_push_literal(instruction: &Instruction, machine: &mut Machine) -> Result<(), VmError> {
    match instruction.operand.as_ref() {
        Some(Operand::Literal(value)) if is_literal(value) => {
            reserve_stack(machine, 1)?;
            machine.stack.push(Slot::Value(value.clone()));
            Ok(())
        }
        _ => Err(VmError::InvalidLiteralEncoding),
    }
}

fn step_push_quote(
    instruction: &Instruction,
    pc: usize,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    let Some(Operand::Quote(quotation)) = instruction.operand.as_ref() else {
        return Err(VmError::StackFault);
    };
    reserve_stack(machine, 1)?;
    if quotation.usage(environment.registry) == Usage::Linear {
        let origin = (
            String::from(current_word),
            pc,
            canonical_code(&quotation.code),
        );
        if machine.linear_quotes.contains(&origin) {
            return Err(VmError::ResourceFault);
        }
        consume_allocation_budget(machine)?;
        reserve(&mut machine.linear_quotes, 1)?;
        machine.linear_quotes.push(origin);
    }
    machine
        .stack
        .push(Slot::Value(Value::Quotation(quotation.clone())));
    Ok(())
}

fn step_push_capture(
    instruction: &Instruction,
    captures: &mut [Value],
    consumed: &mut [bool],
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
) -> Result<(), VmError> {
    let Some(Operand::Capture(index)) = instruction.operand.as_ref() else {
        return Err(VmError::StackFault);
    };
    let index = usize::try_from(*index).map_err(|_| VmError::InvalidCaptureIndex(*index))?;
    let Some(value) = captures.get_mut(index) else {
        return Err(VmError::InvalidCaptureIndex(index as u64));
    };
    let Some(used) = consumed.get_mut(index) else {
        return Err(VmError::InvalidCaptureIndex(index as u64));
    };
    if *used {
        return Err(VmError::ResourceFault);
    }
    if value.usage(environment.registry) == Usage::Linear {
        reserve_stack(machine, 1)?;
        *used = true;
        let moved = core::mem::replace(value, Value::Bytes(Vec::new()));
        machine.stack.push(if matches!(moved, Value::World) {
            Slot::WorldMarker
        } else {
            Slot::Value(moved)
        });
    } else {
        reserve_stack(machine, 1)?;
        machine.stack.push(Slot::Value(value.clone()));
    }
    Ok(())
}

fn step_dup(environment: &ExecutionEnvironment<'_>, machine: &mut Machine) -> Result<(), VmError> {
    let value = machine.stack.last().ok_or(VmError::StackFault)?;
    let Slot::Value(value) = value else {
        return Err(VmError::ResourceFault);
    };
    if value.usage(environment.registry) == Usage::Linear {
        return Err(VmError::ResourceFault);
    }
    let copy = value.clone();
    reserve_stack(machine, 1)?;
    machine.stack.push(Slot::Value(copy));
    Ok(())
}

fn step_drop(environment: &ExecutionEnvironment<'_>, machine: &mut Machine) -> Result<(), VmError> {
    match machine.stack.pop().ok_or(VmError::StackFault)? {
        Slot::Value(value) if value.usage(environment.registry) == Usage::Many => Ok(()),
        Slot::Value(_) | Slot::WorldMarker => Err(VmError::ResourceFault),
    }
}

fn step_swap(machine: &mut Machine) -> Result<(), VmError> {
    let n = machine.stack.len();
    if n < 2 {
        return Err(VmError::StackFault);
    }
    machine.stack.swap(n - 1, n - 2);
    Ok(())
}

fn step_call(
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    let mut quotation = pop_quotation(machine)?;
    run_code(
        &quotation.code,
        &mut quotation.captures,
        &mut quotation.consumed,
        image,
        environment,
        machine,
        current_word,
    )?;
    ensure_captures_consumed(&quotation, environment.registry)
}

fn step_dip(
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    reserve_stack(machine, 1)?;
    let mut quotation = pop_quotation(machine)?;
    let protected = machine.stack.pop().ok_or(VmError::StackFault)?;
    if let Some(frame) = machine.frames.last_mut() {
        frame.continuation = Continuation::RestoreDip;
        frame.saved.clear();
        reserve(&mut frame.saved, 1)?;
        frame.saved.push(match &protected {
            Slot::Value(value) => value.clone(),
            Slot::WorldMarker => Value::World,
        });
    }
    run_code(
        &quotation.code,
        &mut quotation.captures,
        &mut quotation.consumed,
        image,
        environment,
        machine,
        current_word,
    )?;
    ensure_captures_consumed(&quotation, environment.registry)?;
    if let Some(frame) = machine.frames.last_mut() {
        frame.saved.clear();
        frame.continuation = Continuation::Return;
    }
    reserve_stack(machine, 1)?;
    machine.stack.push(protected);
    Ok(())
}

fn step_compose(machine: &mut Machine) -> Result<(), VmError> {
    reserve_stack(machine, 1)?;
    let right = pop_quotation(machine)?;
    let left = pop_quotation(machine)?;
    let right_capture_count = right.captures.len();
    let mut consumed = left.consumed;
    reserve_target(machine, &mut consumed, right.consumed.len())?;
    consumed.extend(right.consumed.iter().copied());
    let mut captures = left.captures;
    reserve_target(machine, &mut captures, right.captures.len())?;
    captures.extend(right.captures);
    let offset = captures.len() - right_capture_count;
    let mut code = left.code;
    reserve_target(machine, &mut code, right.code.len())?;
    code.extend(rebase_captures(&right.code, offset)?);
    machine.stack.push(Slot::Value(Value::Quotation(Quotation {
        code,
        captures,
        consumed,
    })));
    Ok(())
}

fn step_quote(machine: &mut Machine) -> Result<(), VmError> {
    reserve_stack(machine, 1)?;
    let value = machine.stack.pop().ok_or(VmError::StackFault)?;
    let value = match value {
        Slot::Value(value) => value,
        Slot::WorldMarker => Value::World,
    };
    machine.stack.push(Slot::Value(Value::Quotation(Quotation {
        code: vec![Instruction {
            op: Op::PushCapture,
            operand: Some(Operand::Capture(0)),
        }],
        captures: vec![value],
        consumed: vec![false],
    })));
    Ok(())
}

fn step_if(
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    let false_branch = pop_quotation(machine)?;
    let true_branch = pop_quotation(machine)?;
    let condition = match machine.stack.pop().ok_or(VmError::StackFault)? {
        Slot::Value(Value::Bool(value)) => value,
        _ => return Err(VmError::TypeFault),
    };
    if true_branch.usage(environment.registry) == Usage::Linear
        || false_branch.usage(environment.registry) == Usage::Linear
    {
        return Err(VmError::ResourceFault);
    }
    let mut branch = if condition { true_branch } else { false_branch };
    run_code(
        &branch.code,
        &mut branch.captures,
        &mut branch.consumed,
        image,
        environment,
        machine,
        current_word,
    )
}

fn step_call_word(
    instruction: &Instruction,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
) -> Result<(), VmError> {
    let Some(Operand::Word(name)) = instruction.operand.as_ref() else {
        return Err(VmError::StackFault);
    };
    let resolved = environment.resolver.resolve(name)?;
    let (word_image, word) = resolved.parts();
    // A frame that will be refused is not an entry, so it is not charged
    // as one.
    ensure_call_depth(machine)?;
    reserve(&mut machine.cost.steps, 1)?;
    machine.cost.total = machine.cost.total.saturating_add(1);
    machine.cost.word_entries += 1;
    machine.cost.steps.push(CostStep {
        cost: 1,
        kernel_cost: 0,
        word: word.name.clone(),
        pc: 0,
        image_version: word_image.image_version,
        primitive: None,
    });
    run_code(
        &word.code,
        &mut [],
        &mut [],
        word_image,
        environment,
        machine,
        &word.name,
    )
}

fn step_prim(
    instruction: &Instruction,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
) -> Result<(), VmError> {
    let Some(Operand::Primitive(name)) = instruction.operand.as_ref() else {
        return Err(VmError::InvalidPrimitiveTag);
    };
    run_primitive(name, environment.registry, machine)
}

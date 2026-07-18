fn empty_cost() -> CostReport {
    CostReport {
        total: 0,
        instructions: 0,
        word_entries: 0,
        primitives: 0,
        steps: Vec::new(),
    }
}

fn reserve<T>(values: &mut Vec<T>, additional: usize) -> Result<(), VmError> {
    values
        .try_reserve(additional)
        .map_err(|_| VmError::AllocationFailure)
}

fn reserve_stack(machine: &mut Machine, additional: usize) -> Result<(), VmError> {
    if let Some(budget) = machine.allocation_budget.as_mut() {
        if *budget == 0 {
            return Err(VmError::AllocationFailure);
        }
        *budget -= 1;
    }
    reserve(&mut machine.stack, additional)
}

fn reserve_target<T>(
    machine: &mut Machine,
    values: &mut Vec<T>,
    additional: usize,
) -> Result<(), VmError> {
    consume_allocation_budget(machine)?;
    reserve(values, additional)
}

fn consume_allocation_budget(machine: &mut Machine) -> Result<(), VmError> {
    if let Some(budget) = machine.allocation_budget.as_mut() {
        if *budget == 0 {
            return Err(VmError::AllocationFailure);
        }
        *budget -= 1;
    }
    Ok(())
}

fn empty_machine() -> Machine {
    Machine {
        stack: Vec::new(),
        world: WorldState::new(),
        fuel: 0,
        cost: empty_cost(),
        trace: Vec::new(),
        location: None,
        linear_quotes: Vec::new(),
        frames: Vec::new(),
        allocation_budget: None,
    }
}

fn diagnostic_trap(error: VmError, state: Machine) -> ExecutionOutcome {
    let stack = state
        .stack
        .into_iter()
        .filter_map(|slot| match slot {
            Slot::Value(value) => Some(value),
            Slot::WorldMarker => None,
        })
        .collect();
    ExecutionOutcome::Trap(Trap {
        code: error.stable_code(),
        error,
        location: state.location,
        stack,
        world: state.world,
        cost: state.cost,
        trace: state.trace,
        frames: state.frames,
    })
}

#[derive(Debug, Clone, PartialEq, Eq)]
enum Slot {
    Value(Value),
    WorldMarker,
}

#[derive(Clone)]
struct Machine {
    stack: Vec<Slot>,
    world: WorldState,
    fuel: u64,
    cost: CostReport,
    trace: Vec<TraceEvent>,
    location: Option<TrapLocation>,
    linear_quotes: Vec<(String, usize, Vec<u8>)>,
    frames: Vec<FrameTrace>,
    allocation_budget: Option<usize>,
}

#[allow(clippy::too_many_arguments)]
fn charge(
    machine: &mut Machine,
    primitive: bool,
    word: bool,
    instruction: &Instruction,
    current_word: &str,
    pc: usize,
    image: &Image,
    primitive_name: Option<&str>,
    primitive_cost: u64,
) -> Result<(), VmError> {
    machine.location = Some(TrapLocation {
        word: String::from(current_word),
        pc,
        image_version: image.image_version,
    });
    if machine.fuel == 0 {
        return Err(VmError::FuelExhausted);
    }
    reserve(&mut machine.cost.steps, 1)?;
    reserve(&mut machine.trace, 1)?;
    machine.fuel -= 1;
    let cost = if primitive { primitive_cost } else { 1 };
    machine.cost.total = machine.cost.total.saturating_add(cost);
    machine.cost.instructions += 1;
    if primitive {
        machine.cost.primitives += 1;
    }
    if word {
        machine.cost.word_entries += 1;
    }
    machine.cost.steps.push(CostStep {
        cost,
        word: String::from(current_word),
        pc,
        image_version: image.image_version,
        primitive: primitive_name.map(String::from),
    });
    machine.trace.push(TraceEvent {
        word: String::from(current_word),
        pc,
        image_version: image.image_version,
        stack: machine
            .stack
            .iter()
            .filter_map(|slot| match slot {
                Slot::Value(value) => Some(value.clone()),
                Slot::WorldMarker => None,
            })
            .collect(),
        cost: machine.cost.total,
        format_version: image.format_version,
        gamma_version: image.gamma_version,
        world_observation: machine.world.observation.clone(),
        frames: machine.frames.clone(),
    });
    let _ = instruction;
    Ok(())
}

fn run_code(
    code: &[Instruction],
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    let frame_depth = machine.frames.len();
    reserve(&mut machine.frames, 1)?;
    machine.frames.push(FrameTrace {
        word: String::from(current_word),
        pc: 0,
        code_digest: sha256(&canonical_code(code)).to_vec(),
        captures: consumed.to_vec(),
        capture_values: captures.to_vec(),
        saved: Vec::new(),
        continuation: if frame_depth == 0 {
            Continuation::Halt
        } else {
            Continuation::Return
        },
    });
    let result = (|| {
        for (pc, instruction) in code.iter().enumerate() {
            if let Some(frame) = machine.frames.last_mut() {
                frame.pc = pc;
                frame.captures = consumed.to_vec();
                frame.capture_values = captures.to_vec();
            }
            let captures_checkpoint = captures.to_vec();
            let consumed_checkpoint = consumed.to_vec();
            let checkpoint = machine.clone();
            let instruction_result = (|| {
                let primitive_cost = match instruction.operand.as_ref() {
                    Some(Operand::Primitive(name)) => environment
                        .registry
                        .definitions
                        .iter()
                        .find(|definition| definition.name == name)
                        .map_or(1, |definition| definition.cost),
                    _ => 1,
                };
                charge(
                    machine,
                    matches!(instruction.op, Op::Prim),
                    false,
                    instruction,
                    current_word,
                    pc,
                    image,
                    match instruction.operand.as_ref() {
                        Some(Operand::Primitive(name)) => Some(name.as_str()),
                        _ => None,
                    },
                    primitive_cost,
                )?;
                if let Err(error) = validate_before_charge(
                    instruction,
                    machine,
                    captures,
                    consumed,
                    environment.registry,
                    current_word,
                    pc,
                ) {
                    let location = machine.location.clone();
                    *machine = checkpoint.clone();
                    machine.location = location;
                    return Err(error);
                }
                match instruction.op {
                    Op::PushLiteral => match instruction.operand.as_ref() {
                        Some(Operand::Literal(value)) if is_literal(value) => {
                            reserve_stack(machine, 1)?;
                            machine.stack.push(Slot::Value(value.clone()))
                        }
                        _ => return Err(VmError::InvalidLiteralEncoding),
                    },
                    Op::PushQuote => match instruction.operand.as_ref() {
                        Some(Operand::Quote(quotation)) => {
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
                                .push(Slot::Value(Value::Quotation(quotation.clone())))
                        }
                        _ => return Err(VmError::StackFault),
                    },
                    Op::PushCapture => {
                        let Some(Operand::Capture(index)) = instruction.operand.as_ref() else {
                            return Err(VmError::StackFault);
                        };
                        let index = usize::try_from(*index)
                            .map_err(|_| VmError::InvalidCaptureIndex(*index))?;
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
                    }
                    Op::Dup => {
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
                    }
                    Op::Drop => match machine.stack.pop().ok_or(VmError::StackFault)? {
                        Slot::Value(value) if value.usage(environment.registry) == Usage::Many => {}
                        Slot::Value(_) | Slot::WorldMarker => return Err(VmError::ResourceFault),
                    },
                    Op::Swap => {
                        let n = machine.stack.len();
                        if n < 2 {
                            return Err(VmError::StackFault);
                        }
                        machine.stack.swap(n - 1, n - 2);
                    }
                    Op::Call => {
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
                        ensure_captures_consumed(&quotation, environment.registry)?;
                    }
                    Op::Dip => {
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
                    }
                    Op::Compose => {
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
                    }
                    Op::Quote => {
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
                    }
                    Op::If => {
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
                        let branch = if condition { true_branch } else { false_branch };
                        let mut branch = branch;
                        run_code(
                            &branch.code,
                            &mut branch.captures,
                            &mut branch.consumed,
                            image,
                            environment,
                            machine,
                            current_word,
                        )?;
                    }
                    Op::CallWord => {
                        let Some(Operand::Word(name)) = instruction.operand.as_ref() else {
                            return Err(VmError::StackFault);
                        };
                        let resolved = environment.resolver.resolve(name)?;
                        let (word_image, word) = resolved.parts();
                        reserve(&mut machine.cost.steps, 1)?;
                        machine.cost.total = machine.cost.total.saturating_add(1);
                        machine.cost.word_entries += 1;
                        machine.cost.steps.push(CostStep {
                            cost: 1,
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
                        )?;
                    }
                    Op::Prim => {
                        let Some(Operand::Primitive(name)) = instruction.operand.as_ref() else {
                            return Err(VmError::InvalidPrimitiveTag);
                        };
                        run_primitive(name, environment.registry, machine)?;
                    }
                }
                Ok::<(), VmError>(())
            })();
            if matches!(instruction_result, Err(VmError::AllocationFailure)) {
                let location = TrapLocation {
                    word: String::from(current_word),
                    pc,
                    image_version: image.image_version,
                };
                *machine = checkpoint;
                machine.location = Some(location);
                captures.clone_from_slice(&captures_checkpoint);
                consumed.copy_from_slice(&consumed_checkpoint);
            }
            instruction_result?;
        }
        Ok(())
    })();
    if result.is_ok() {
        machine.frames.truncate(frame_depth);
    }
    result
}

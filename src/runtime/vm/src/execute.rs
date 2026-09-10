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

/// Enough of the machine to undo one instruction. The append-only vectors
/// (cost steps, trace, linear-quote origins, frames) are restored by
/// truncation, so taking and restoring a checkpoint costs O(stack) rather than
/// a copy of the whole trace at every step.
struct Checkpoint {
    stack: Vec<Slot>,
    world: WorldState,
    fuel: u64,
    cost_total: u64,
    cost_instructions: u64,
    cost_word_entries: u64,
    cost_primitives: u64,
    steps_len: usize,
    trace_len: usize,
    linear_quotes_len: usize,
    frames_len: usize,
    frame_continuation: Option<Continuation>,
    frame_saved: Vec<Value>,
    allocation_budget: Option<usize>,
}

fn checkpoint(machine: &Machine) -> Checkpoint {
    Checkpoint {
        stack: machine.stack.clone(),
        world: machine.world.clone(),
        fuel: machine.fuel,
        cost_total: machine.cost.total,
        cost_instructions: machine.cost.instructions,
        cost_word_entries: machine.cost.word_entries,
        cost_primitives: machine.cost.primitives,
        steps_len: machine.cost.steps.len(),
        trace_len: machine.trace.len(),
        linear_quotes_len: machine.linear_quotes.len(),
        frames_len: machine.frames.len(),
        frame_continuation: machine.frames.last().map(|frame| frame.continuation),
        frame_saved: machine
            .frames
            .last()
            .map(|frame| frame.saved.clone())
            .unwrap_or_default(),
        allocation_budget: machine.allocation_budget,
    }
}

fn rollback(machine: &mut Machine, checkpoint: Checkpoint) {
    machine.stack = checkpoint.stack;
    machine.world = checkpoint.world;
    machine.fuel = checkpoint.fuel;
    machine.cost.total = checkpoint.cost_total;
    machine.cost.instructions = checkpoint.cost_instructions;
    machine.cost.word_entries = checkpoint.cost_word_entries;
    machine.cost.primitives = checkpoint.cost_primitives;
    machine.cost.steps.truncate(checkpoint.steps_len);
    machine.trace.truncate(checkpoint.trace_len);
    machine.linear_quotes.truncate(checkpoint.linear_quotes_len);
    machine.frames.truncate(checkpoint.frames_len);
    if let (Some(frame), Some(continuation)) =
        (machine.frames.last_mut(), checkpoint.frame_continuation)
    {
        frame.continuation = continuation;
        frame.saved = checkpoint.frame_saved;
    }
    machine.allocation_budget = checkpoint.allocation_budget;
}

/// Refuses to enter one more administrative frame past `MAX_CALL_DEPTH`.
fn ensure_call_depth(machine: &Machine) -> Result<(), VmError> {
    if machine.frames.len() >= MAX_CALL_DEPTH {
        Err(VmError::CallDepthExceeded)
    } else {
        Ok(())
    }
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
    // PUSH_CAPTURE implements the reference interpreter's administrative
    // S-PUSH, which currently costs zero. It still consumes VM fuel/cost.
    let kernel_cost = if word || matches!(instruction.op, Op::PushCapture) {
        0
    } else {
        cost
    };
    machine.cost.steps.push(CostStep {
        cost,
        kernel_cost,
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
        cost,
        kernel_cost,
        format_version: image.format_version,
        gamma_version: image.gamma_version,
        world_observation: machine.world.observation.clone(),
        frames: machine.frames.clone(),
    });
    Ok(())
}
// The executor is split so that each opcode's temporaries live in their own
// function. Only the frames on the active path (`run_code`, `run_frame`,
// `step`, and the one opcode that recurses) occupy native stack at each level
// of nesting, which keeps `MAX_CALL_DEPTH` administrative frames inside a
// small native stack in an unoptimised build.

fn run_code(
    code: &[Instruction],
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    ensure_call_depth(machine)?;
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
    let result = run_frame(
        code,
        captures,
        consumed,
        image,
        environment,
        machine,
        current_word,
    );
    if result.is_ok() {
        machine.frames.truncate(frame_depth);
    }
    result
}

fn run_frame(
    code: &[Instruction],
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    for (pc, instruction) in code.iter().enumerate() {
        if let Some(frame) = machine.frames.last_mut() {
            frame.pc = pc;
            frame.captures = consumed.to_vec();
            frame.capture_values = captures.to_vec();
        }
        let captures_checkpoint = captures.to_vec();
        let consumed_checkpoint = consumed.to_vec();
        let mut undo = Some(checkpoint(machine));
        let instruction_result = step(
            instruction,
            pc,
            captures,
            consumed,
            image,
            environment,
            machine,
            current_word,
            &mut undo,
        );
        if matches!(instruction_result, Err(VmError::AllocationFailure))
            && let Some(undo) = undo.take()
        {
            rollback(machine, undo);
            machine.location = Some(TrapLocation {
                word: String::from(current_word),
                pc,
                image_version: image.image_version,
            });
            captures.clone_from_slice(&captures_checkpoint);
            consumed.copy_from_slice(&consumed_checkpoint);
        }
        instruction_result?;
    }
    Ok(())
}

/// Charges, validates and dispatches one instruction. A validation failure
/// undoes the charge (`target-spec.md` §5: a failed instruction reports its
/// cost only if it passed validation) but keeps the recorded location.
#[allow(clippy::too_many_arguments)]
fn step(
    instruction: &Instruction,
    pc: usize,
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'_>,
    machine: &mut Machine,
    current_word: &str,
    undo: &mut Option<Checkpoint>,
) -> Result<(), VmError> {
    let primitive_name = match instruction.operand.as_ref() {
        Some(Operand::Primitive(name)) => Some(name.as_str()),
        _ => None,
    };
    let primitive_cost = primitive_name.map_or(1, |name| {
        environment
            .registry
            .definitions
            .iter()
            .find(|definition| definition.name == name)
            .map_or(1, |definition| definition.cost)
    });
    charge(
        machine,
        matches!(instruction.op, Op::Prim),
        false,
        instruction,
        current_word,
        pc,
        image,
        primitive_name,
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
        if let Some(undo) = undo.take() {
            rollback(machine, undo);
        }
        return Err(error);
    }
    match instruction.op {
        Op::PushLiteral => step_push_literal(instruction, machine),
        Op::PushQuote => step_push_quote(instruction, pc, environment, machine, current_word),
        Op::PushCapture => step_push_capture(instruction, captures, consumed, environment, machine),
        Op::Dup => step_dup(environment, machine),
        Op::Drop => step_drop(environment, machine),
        Op::Swap => step_swap(machine),
        Op::Call => step_call(image, environment, machine, current_word),
        Op::Dip => step_dip(image, environment, machine, current_word),
        Op::Compose => step_compose(machine),
        Op::Quote => step_quote(machine),
        Op::If => step_if(image, environment, machine, current_word),
        Op::CallWord => step_call_word(instruction, environment, machine),
        Op::Prim => step_prim(instruction, environment, machine),
    }
}

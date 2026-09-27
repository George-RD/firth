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
    let traced = machine.trace.len() < MAX_TRACE_EVENTS;
    if traced {
        reserve(&mut machine.trace, 1)?;
    }
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
    if !traced {
        return Ok(());
    }
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

/// A control transfer in tail position. Once it is taken the current frame
/// has nothing left to run, so `run_code` replaces that frame with the target
/// instead of nesting a new one; tail-recursive words run in constant frames.
enum Tail<'x> {
    Quote(Quotation),
    Word(ResolvedWord<'x>),
}

fn run_code<'x>(
    code: &[Instruction],
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'x>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    ensure_call_depth(machine)?;
    let frame_depth = machine.frames.len();
    push_frame(machine, current_word, code, captures, consumed)?;
    let tail = run_frame(
        code,
        captures,
        consumed,
        image,
        environment,
        machine,
        current_word,
        !owns_linear_captures(captures, environment.registry),
    )?;
    machine.frames.truncate(frame_depth);
    match tail {
        None => Ok(()),
        Some(exit) => run_tail_chain(exit, image, environment, machine, current_word),
    }
}

fn push_frame(
    machine: &mut Machine,
    word: &str,
    code: &[Instruction],
    captures: &[Value],
    consumed: &[bool],
) -> Result<(), VmError> {
    let continuation = if machine.frames.is_empty() {
        Continuation::Halt
    } else {
        Continuation::Return
    };
    reserve(&mut machine.frames, 1)?;
    machine.frames.push(FrameTrace {
        word: String::from(word),
        pc: 0,
        code_digest: sha256(&canonical_code(code)).to_vec(),
        captures: consumed.to_vec(),
        capture_values: captures.to_vec(),
        saved: Vec::new(),
        continuation,
    });
    Ok(())
}

/// Runs tail targets in the frame slot the finished frame gave up. It is a
/// separate function so that its state is on the native stack only while a
/// tail chain runs, not on every nested call (see the note above).
// The exit stays boxed so that `run_code` holds a pointer, not the exit.
#[allow(clippy::boxed_local)]
#[inline(never)]
fn run_tail_chain<'x>(
    exit: Box<TailExit<'x>>,
    image: &Image,
    environment: &ExecutionEnvironment<'x>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<(), VmError> {
    let TailExit { tail: first, undo } = *exit;
    let frame_depth = machine.frames.len();
    // A tail word replaces the word (and its image); a tail quotation
    // replaces only the code and keeps the enclosing word, exactly as a
    // nested `call` would attribute it. Tail quotations own no linear
    // captures, so nothing is left to check when they end.
    let mut word: Option<ResolvedWord<'x>> = None;
    let mut next = Some(first);
    while let Some(target) = next.take() {
        let quote = match target {
            Tail::Quote(quote) => Some(quote),
            Tail::Word(resolved) => {
                word = Some(resolved);
                None
            }
        };
        let mut quote = quote;
        let mut no_captures: [Value; 0] = [];
        let mut no_consumed: [bool; 0] = [];
        let (frame_image, frame_word) = match &word {
            Some(resolved) => {
                let (word_image, entry) = resolved.parts();
                (word_image, entry.name.as_str())
            }
            None => (image, current_word),
        };
        let (frame_code, frame_captures, frame_consumed): (&[Instruction], &mut [Value], &mut [bool]) =
            match (&word, &mut quote) {
                (_, Some(Quotation {
                    code,
                    captures,
                    consumed,
                })) => (code, captures, consumed),
                (Some(resolved), None) => (
                    &resolved.parts().1.code,
                    &mut no_captures,
                    &mut no_consumed,
                ),
                (None, None) => return Err(VmError::StackFault),
            };
        let result = match push_frame(machine, frame_word, frame_code, frame_captures, frame_consumed) {
            Ok(()) => run_frame(
            frame_code,
            frame_captures,
            frame_consumed,
            frame_image,
            environment,
            machine,
                frame_word,
                true,
            ),
            Err(error) => Err(error),
        };
        match result {
            Ok(exit) => next = exit.map(|exit| exit.tail),
            Err(VmError::AllocationFailure) => {
                return Err(undo_tail_transfer(undo, frame_depth, image, machine, current_word));
            }
            Err(error) => return Err(error),
        }
        machine.frames.truncate(frame_depth);
    }
    Ok(())
}

/// A tail target with the state before the instruction that transferred to
/// it. The target runs after that instruction returned, so a failure in the
/// tail chain is rolled back here to that instruction, exactly as `run_frame`
/// rolls back a nested call (`target-spec.md` §5).
struct TailExit<'x> {
    tail: Tail<'x>,
    undo: Box<TailUndo>,
}

struct TailUndo {
    checkpoint: Checkpoint,
    pc: usize,
    caller: Option<FrameTrace>,
}

/// Kept out of `run_frame` so that building the exit is not on the native
/// stack of every nested call.
#[allow(clippy::boxed_local)]
#[inline(never)]
fn tail_exit<'x>(
    tail: Box<Tail<'x>>,
    undo: Option<Checkpoint>,
    pc: usize,
    machine: &Machine,
) -> Result<Box<TailExit<'x>>, VmError> {
    Ok(Box::new(TailExit {
        tail: *tail,
        undo: Box::new(TailUndo {
            checkpoint: undo.ok_or(VmError::StackFault)?,
            pc,
            caller: machine.frames.last().cloned(),
        }),
    }))
}

/// Restores the caller's frame and the state before its transferring
/// instruction. The transfer reads no captures, so the caller's are unchanged.
#[inline(never)]
fn undo_tail_transfer(
    undo: Box<TailUndo>,
    frame_depth: usize,
    image: &Image,
    machine: &mut Machine,
    current_word: &str,
) -> VmError {
    let TailUndo {
        checkpoint,
        pc,
        caller,
    } = *undo;
    machine.frames.truncate(frame_depth);
    machine.frames.extend(caller);
    rollback(machine, checkpoint);
    machine.location = Some(TrapLocation {
        word: String::from(current_word),
        pc,
        image_version: image.image_version,
    });
    VmError::AllocationFailure
}

#[allow(clippy::too_many_arguments)]
fn run_frame<'x>(
    code: &[Instruction],
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'x>,
    machine: &mut Machine,
    current_word: &str,
    allow_tail: bool,
) -> Result<Option<Box<TailExit<'x>>>, VmError> {
    let last = code.len().saturating_sub(1);
    let mut exit = None;
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
            allow_tail && pc == last,
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
        if let Some(tail) = instruction_result? {
            exit = Some(tail_exit(tail, undo, pc, machine)?);
        }
    }
    Ok(exit)
}


/// Dispatches a `CALL`, `IF` or `CALL_WORD` in tail position. A quotation
/// that owns linear captures keeps its own frame so they are checked when it
/// ends; any other quotation becomes a tail target with its captures.
#[inline(never)]
fn step_tail<'x>(
    instruction: &Instruction,
    image: &Image,
    environment: &ExecutionEnvironment<'x>,
    machine: &mut Machine,
    current_word: &str,
) -> Result<Option<Box<Tail<'x>>>, VmError> {
    match instruction.op {
        Op::Call if top_is_tail_quotation(machine, environment.registry) => {
            Ok(Some(Box::new(Tail::Quote(pop_quotation(machine)?))))
        }
        Op::Call => step_call(image, environment, machine, current_word).map(|()| None),
        Op::If => {
            let branch = take_if_branch(environment, machine)?;
            if !owns_linear_captures(&branch.captures, environment.registry) {
                Ok(Some(Box::new(Tail::Quote(branch))))
            } else {
                run_branch(branch, image, environment, machine, current_word).map(|()| None)
            }
        }
        _ => Ok(Some(Box::new(Tail::Word(enter_word(
            instruction,
            environment,
            machine,
            false,
        )?)))),
    }
}

/// Charges, validates and dispatches one instruction. A validation failure
/// undoes the charge (`target-spec.md` §5: a failed instruction reports its
/// cost only if it passed validation) but keeps the recorded location.
#[allow(clippy::too_many_arguments)]
fn step<'x>(
    instruction: &Instruction,
    pc: usize,
    captures: &mut [Value],
    consumed: &mut [bool],
    image: &Image,
    environment: &ExecutionEnvironment<'x>,
    machine: &mut Machine,
    current_word: &str,
    undo: &mut Option<Checkpoint>,
    tail: bool,
) -> Result<Option<Box<Tail<'x>>>, VmError> {
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
        Op::Call | Op::If | Op::CallWord if tail => step_tail(
            instruction,
            image,
            environment,
            machine,
            current_word,
        ),
        _ => match instruction.op {
            Op::PushLiteral => step_push_literal(instruction, machine),
            Op::PushQuote => step_push_quote(instruction, pc, environment, machine, current_word),
            Op::PushCapture => step_push_capture(instruction, captures, consumed, environment, machine),
            Op::Dup => step_dup(environment, machine),
            Op::Drop => step_drop(environment, machine),
            Op::Swap => step_swap(machine),
            Op::Pick => step_pick(instruction, machine),
            Op::Roll => step_roll(instruction, machine),
            Op::Call => step_call(image, environment, machine, current_word),
            Op::Dip => step_dip(image, environment, machine, current_word),
            Op::Compose => step_compose(machine),
            Op::Quote => step_quote(machine),
            Op::If => step_if(image, environment, machine, current_word),
            Op::CallWord => step_call_word(instruction, environment, machine),
            Op::Prim => step_prim(instruction, environment, machine),
        }
        .map(|()| None),
    }
}

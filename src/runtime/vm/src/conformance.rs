// Differential conformance boundary between this VM and the Lean reference
// contract.
//
// `target-spec.md` §7 fixes what the two hosts compare: terminal status, the
// canonical bottom-to-top residual stack, the residual frame stack, the
// deterministic hidden `WorldState` observation, the classified trap, and the
// cost report. Every field reachable through this module is one of those.
// Nothing derived from a host address, wall clock, or allocator is
// observable here, so a record produced on one host is comparable on any
// other.
//
// The reference side is deliberately partial: the frozen Lean fixture row
// format carries no world column and does not classify its stuck rows, so a
// corpus-derived reference leaves those unstated and the comparison skips
// them. A hand-written witness states them and they are compared.

/// Terminal classification of one execution.
///
/// Fuel exhaustion is a third outcome, not a trap and not termination
/// (`target-spec.md` §4): a dual exhaustion is inconclusive rather than
/// agreement.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConformanceStatus {
    /// The program ran to completion with no residual code or frames.
    Terminal,
    /// The program stopped at a classified trap.
    Trap,
    /// The bounded fuel budget was spent before the program terminated.
    FuelExhausted,
}

impl ConformanceStatus {
    /// The canonical wire spelling of this status.
    pub fn canonical(self) -> &'static str {
        match self {
            Self::Terminal => "terminal",
            Self::Trap => "trap",
            Self::FuelExhausted => "fuel-exhausted",
        }
    }
}

/// A classified trap: the cross-host stable code from `target-spec.md` §4 plus
/// the optional subcode. Host addresses and payload pointers are not carried.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConformanceTrap {
    /// Stable cross-host trap class, for example `resource-fault`.
    pub code: String,
    /// Stable subcode, empty when the class has none.
    pub subcode: String,
}

impl ConformanceTrap {
    /// Builds a trap record from a VM error's stable classification.
    pub fn of_error(error: &VmError) -> Self {
        Self {
            code: String::from(error.stable_code()),
            subcode: String::from(error.stable_subcode()),
        }
    }
}

/// The instruction, word-entry and primitive split of a cost report.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ConformanceCostBreakdown {
    /// Units charged for target instructions.
    pub instructions: u64,
    /// Units charged for administrative word entries.
    pub word_entries: u64,
    /// Units charged by the `Gamma` registry for primitives.
    pub primitives: u64,
}

/// A comparable cost report.
///
/// `total` is this target's `kappa_vm` charge. `kernel` is the same total
/// without the administrative word-entry charges, which is the quantity the
/// Lean reference `kappa` accounts for; the two differ exactly by
/// `word_entries`.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ConformanceCost {
    /// Total target cost.
    pub total: u64,
    /// Total cost excluding administrative word-entry charges.
    pub kernel: u64,
    /// The per-category split of `total`.
    pub breakdown: ConformanceCostBreakdown,
}

/// One host's canonical observation of an execution.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConformanceObservation {
    /// Terminal classification.
    pub status: ConformanceStatus,
    /// Canonical bottom-to-top residual stack rendering.
    pub stack: String,
    /// Canonical residual frame rendering, `-` when no frame remains.
    pub frames: String,
    /// The deterministic hidden `WorldState` observation bytes.
    pub world_observation: Vec<u8>,
    /// The classified trap, present exactly when execution did not terminate
    /// normally.
    pub trap: Option<ConformanceTrap>,
    /// The cost report.
    pub cost: ConformanceCost,
}

/// The cost half of a reference contract.
///
/// `breakdown` is `None` when the reference does not fix the per-category
/// split, which is the case for every row of the frozen fixture corpus.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ConformanceCostReference {
    /// Expected total target cost.
    pub total: u64,
    /// Expected total cost excluding administrative word-entry charges.
    pub kernel: u64,
    /// Expected per-category split, when the reference fixes it.
    pub breakdown: Option<ConformanceCostBreakdown>,
}

/// What the reference contract requires of a target observation.
///
/// `world_observation` and `trap` are `None` when the reference does not fix
/// them; the comparison then leaves those fields unchecked rather than
/// inventing an expectation.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConformanceReference {
    /// Required terminal classification.
    pub status: ConformanceStatus,
    /// Required canonical bottom-to-top residual stack rendering.
    pub stack: String,
    /// Required canonical residual frame rendering.
    pub frames: String,
    /// Required cost report.
    pub cost: ConformanceCostReference,
    /// Required hidden `WorldState` observation, when the reference fixes it.
    pub world_observation: Option<Vec<u8>>,
    /// Required trap classification, when the reference fixes it.
    pub trap: Option<ConformanceTrap>,
}

/// One field on which a target observation departed from its reference.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConformanceMismatch {
    /// The compared field's stable name.
    pub field: &'static str,
    /// The reference contract's canonical rendering of that field.
    pub reference: String,
    /// The target's canonical rendering of that field.
    pub target: String,
}

/// The outcome of comparing one target observation with its reference.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ConformanceVerdict {
    /// Every field the reference fixes matched.
    Agree,
    /// Both hosts spent an equivalent bounded budget. `target-spec.md` §7
    /// classifies this as `bounded-fuel-inconclusive`, never as agreement.
    BoundedFuelInconclusive,
    /// At least one fixed field differed.
    Disagree(Vec<ConformanceMismatch>),
}

impl ConformanceVerdict {
    /// The canonical wire spelling of this verdict.
    pub fn canonical(&self) -> &'static str {
        match self {
            Self::Agree => "agree",
            Self::BoundedFuelInconclusive => "bounded-fuel-inconclusive",
            Self::Disagree(_) => "disagree",
        }
    }
}

/// Renders a residual stack in the canonical bottom-to-top form shared with
/// the Lean fixture corpus. Quotations render by usage rather than by body, so
/// no pointer or allocation detail reaches the record.
pub fn render_conformance_stack(stack: &[Value], registry: &PrimitiveRegistry) -> String {
    let mut rendered = String::new();
    for (index, value) in stack.iter().enumerate() {
        if index != 0 {
            rendered.push(',');
        }
        match value {
            Value::Int(value) => rendered.push_str(&value.to_string()),
            Value::Bool(value) => rendered.push_str(if *value { "true" } else { "false" }),
            Value::Bytes(_) => rendered.push_str("bytes"),
            Value::PrimitiveValue { .. } => rendered.push_str("primitive"),
            Value::World => rendered.push_str("world"),
            Value::Quotation(quotation) => {
                rendered.push_str(if quotation.usage(registry) == Usage::Many {
                    "quotation-many"
                } else {
                    "quotation-linear"
                });
            }
        }
    }
    rendered
}

/// Renders a residual frame stack as `word@pc` entries, `-` when empty. The
/// code digest and capture values stay out of the rendering: they are already
/// determined by the image and the instruction pointer.
pub fn render_conformance_frames(frames: &[FrameTrace]) -> String {
    if frames.is_empty() {
        return String::from("-");
    }
    let mut rendered = String::new();
    for (index, frame) in frames.iter().enumerate() {
        if index != 0 {
            rendered.push(';');
        }
        rendered.push_str(&frame.word);
        rendered.push('@');
        rendered.push_str(&frame.pc.to_string());
    }
    rendered
}

fn conformance_cost(cost: &CostReport) -> ConformanceCost {
    ConformanceCost {
        total: cost.total,
        kernel: cost.total.saturating_sub(cost.word_entries),
        breakdown: ConformanceCostBreakdown {
            instructions: cost.instructions,
            word_entries: cost.word_entries,
            primitives: cost.primitives,
        },
    }
}

/// Observes one execution of a decoded image through the conformance
/// boundary.
pub fn observe_image(
    image: &Image,
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> ConformanceObservation {
    match execute_diagnostic_with_stack(image, initial_stack, fuel, registry) {
        ExecutionOutcome::Complete(report) => ConformanceObservation {
            status: ConformanceStatus::Terminal,
            stack: render_conformance_stack(&report.stack, registry),
            frames: render_conformance_frames(&report.frames),
            world_observation: report.world.observation().to_vec(),
            trap: None,
            cost: conformance_cost(&report.cost),
        },
        ExecutionOutcome::Trap(trap) => ConformanceObservation {
            status: if trap.error == VmError::FuelExhausted {
                ConformanceStatus::FuelExhausted
            } else {
                ConformanceStatus::Trap
            },
            stack: render_conformance_stack(&trap.stack, registry),
            frames: render_conformance_frames(&trap.frames),
            world_observation: trap.world.observation().to_vec(),
            trap: Some(ConformanceTrap::of_error(&trap.error)),
            cost: conformance_cost(&trap.cost),
        },
    }
}

/// Observes one execution of an encoded image, classifying a decode failure as
/// a malformed-input trap.
///
/// `target-spec.md` §5 charges nothing for bytes that never decoded, so the
/// cost report of a rejected image is zero in every category.
pub fn observe_image_bytes(
    bytes: &[u8],
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> ConformanceObservation {
    match decode(bytes) {
        Ok(image) => observe_image(&image, initial_stack, fuel, registry),
        Err(error) => ConformanceObservation {
            status: ConformanceStatus::Trap,
            stack: String::new(),
            frames: String::from("-"),
            world_observation: WorldState::new().observation().to_vec(),
            trap: Some(ConformanceTrap::of_error(&error)),
            cost: ConformanceCost {
                total: 0,
                kernel: 0,
                breakdown: ConformanceCostBreakdown {
                    instructions: 0,
                    word_entries: 0,
                    primitives: 0,
                },
            },
        },
    }
}

/// Parses a canonical fixture outcome column into a status.
pub fn parse_conformance_status(outcome: &str) -> Option<ConformanceStatus> {
    match outcome {
        "terminal" => Some(ConformanceStatus::Terminal),
        "stuck" => Some(ConformanceStatus::Trap),
        "fuel" => Some(ConformanceStatus::FuelExhausted),
        _ => None,
    }
}

/// Lifts one frozen Lean fixture row into the reference contract it states.
///
/// The row fixes status, canonical stack, residual frames and both cost
/// totals. It carries no world column and does not name a trap class, so those
/// stay unstated; a hand-written witness supplies them where they matter.
/// Returns `None` for an outcome column outside the frozen vocabulary.
pub fn fixture_reference(case: &FixtureCase) -> Option<ConformanceReference> {
    Some(ConformanceReference {
        status: parse_conformance_status(&case.outcome)?,
        stack: case.final_stack.clone(),
        frames: case.residual_frames.clone(),
        cost: ConformanceCostReference {
            total: case.target_cost,
            kernel: case.lean_cost,
            breakdown: None,
        },
        world_observation: None,
        trap: None,
    })
}

/// Renders observation bytes as a canonical comma-separated decimal list.
pub fn render_conformance_bytes(bytes: &[u8]) -> String {
    let mut rendered = String::new();
    for (index, byte) in bytes.iter().enumerate() {
        if index != 0 {
            rendered.push(',');
        }
        rendered.push_str(&byte.to_string());
    }
    rendered
}

/// Renders a classified trap as `code` or `code/subcode`, `-` when absent.
pub fn render_conformance_trap(trap: Option<&ConformanceTrap>) -> String {
    match trap {
        None => String::from("-"),
        Some(trap) => {
            let mut rendered = trap.code.clone();
            if !trap.subcode.is_empty() {
                rendered.push('/');
                rendered.push_str(&trap.subcode);
            }
            rendered
        }
    }
}

/// Renders a cost report as `total=.. kernel=.. instructions=.. word-entries=.. primitives=..`.
pub fn render_conformance_cost(cost: &ConformanceCost) -> String {
    let mut rendered = String::from("total=");
    rendered.push_str(&cost.total.to_string());
    rendered.push_str(" kernel=");
    rendered.push_str(&cost.kernel.to_string());
    rendered.push_str(" instructions=");
    rendered.push_str(&cost.breakdown.instructions.to_string());
    rendered.push_str(" word-entries=");
    rendered.push_str(&cost.breakdown.word_entries.to_string());
    rendered.push_str(" primitives=");
    rendered.push_str(&cost.breakdown.primitives.to_string());
    rendered
}

fn render_breakdown(breakdown: ConformanceCostBreakdown) -> String {
    let mut rendered = breakdown.instructions.to_string();
    rendered.push(',');
    rendered.push_str(&breakdown.word_entries.to_string());
    rendered.push(',');
    rendered.push_str(&breakdown.primitives.to_string());
    rendered
}

fn mismatch(field: &'static str, reference: String, target: String) -> ConformanceMismatch {
    ConformanceMismatch {
        field,
        reference,
        target,
    }
}

/// Compares one target observation with the reference contract for the same
/// case.
///
/// Dual exhaustion of an equivalent budget is `BoundedFuelInconclusive` and is
/// never reported as agreement. A one-sided exhaustion falls through to the
/// status comparison and disagrees, as `target-spec.md` §7 requires.
pub fn compare_conformance(
    reference: &ConformanceReference,
    target: &ConformanceObservation,
) -> ConformanceVerdict {
    if reference.status == ConformanceStatus::FuelExhausted
        && target.status == ConformanceStatus::FuelExhausted
    {
        return ConformanceVerdict::BoundedFuelInconclusive;
    }
    let mut mismatches = Vec::new();
    if reference.status != target.status {
        mismatches.push(mismatch(
            "status",
            String::from(reference.status.canonical()),
            String::from(target.status.canonical()),
        ));
    }
    if reference.stack != target.stack {
        mismatches.push(mismatch(
            "stack",
            reference.stack.clone(),
            target.stack.clone(),
        ));
    }
    if reference.frames != target.frames {
        mismatches.push(mismatch(
            "frames",
            reference.frames.clone(),
            target.frames.clone(),
        ));
    }
    if let Some(expected) = &reference.world_observation
        && expected.as_slice() != target.world_observation.as_slice()
    {
        mismatches.push(mismatch(
            "world-observation",
            render_conformance_bytes(expected),
            render_conformance_bytes(&target.world_observation),
        ));
    }
    if let Some(expected) = &reference.trap
        && Some(expected) != target.trap.as_ref()
    {
        mismatches.push(mismatch(
            "trap",
            render_conformance_trap(Some(expected)),
            render_conformance_trap(target.trap.as_ref()),
        ));
    }
    if reference.cost.total != target.cost.total {
        mismatches.push(mismatch(
            "cost-total",
            reference.cost.total.to_string(),
            target.cost.total.to_string(),
        ));
    }
    if reference.cost.kernel != target.cost.kernel {
        mismatches.push(mismatch(
            "cost-kernel",
            reference.cost.kernel.to_string(),
            target.cost.kernel.to_string(),
        ));
    }
    if let Some(expected) = reference.cost.breakdown
        && expected != target.cost.breakdown
    {
        mismatches.push(mismatch(
            "cost-breakdown",
            render_breakdown(expected),
            render_breakdown(target.cost.breakdown),
        ));
    }
    if mismatches.is_empty() {
        ConformanceVerdict::Agree
    } else {
        ConformanceVerdict::Disagree(mismatches)
    }
}

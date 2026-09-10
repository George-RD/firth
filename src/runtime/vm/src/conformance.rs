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
/// projected from recorded per-step kernel charges. Administrative word-entry
/// and capture-restoration charges are excluded only from `kernel`, never from
/// target cost or fuel consumption.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ConformanceCost {
    /// Total target cost.
    pub total: u64,
    /// Total cost excluding administrative word-entry and capture-restoration charges.
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
    /// What this VM checked before executing; never a proof of anything the
    /// elaborator owns.
    pub admission: AdmissionLabel,
}

/// The cost half of a reference contract.
///
/// `breakdown` is `None` when the reference does not fix the per-category
/// split, which is the case for every row of the frozen fixture corpus.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ConformanceCostReference {
    /// Expected total target cost.
    pub total: u64,
    /// Expected kernel cost excluding word-entry and capture-restoration charges.
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

/// One field the reference states only as a projection this target cannot be
/// compared against in full.
///
/// The legacy fixture profile writes a quotation as `quotation-many` or
/// `quotation-linear` and a frame as `word@pc`. Those spellings fix neither a
/// body nor a capture nor a continuation, so a target whose projection matches
/// has not been shown equal: the comparison is unsupported, never agreement.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConformanceUnsupported {
    /// The compared field's stable name.
    pub field: &'static str,
    /// Why the comparison could not be completed.
    pub reason: &'static str,
    /// The reference contract's rendering of that field.
    pub reference: String,
    /// The target's full rendering of that field.
    pub target: String,
}

/// The outcome of comparing one target observation with its reference.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ConformanceVerdict {
    /// Every field the reference fixes matched in full.
    Agree,
    /// Both hosts spent an equivalent bounded budget. `target-spec.md` §7
    /// classifies this as `bounded-fuel-inconclusive`, never as agreement.
    BoundedFuelInconclusive,
    /// At least one fixed field differed.
    Disagree(Vec<ConformanceMismatch>),
    /// No fixed field differed, but at least one was stated only as a
    /// projection that cannot establish equality. Never agreement.
    UnsupportedComparison(Vec<ConformanceUnsupported>),
}

impl ConformanceVerdict {
    /// The canonical wire spelling of this verdict.
    pub fn canonical(&self) -> &'static str {
        match self {
            Self::Agree => "agree",
            Self::BoundedFuelInconclusive => "bounded-fuel-inconclusive",
            Self::Disagree(_) => "disagree",
            Self::UnsupportedComparison(_) => "unsupported-comparison",
        }
    }

    /// True only for `Agree`. An inconclusive or unsupported verdict is not
    /// evidence that the two hosts agreed.
    pub fn is_agreement(&self) -> bool {
        matches!(self, Self::Agree)
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

/// Lifts a legacy `main@pc` residual-frame column to the full grammar when the
/// row fixes it completely.
///
/// A single root frame of the entry word is fully determined: its code is the
/// word body, it has no captures, it runs under `Halt` at depth zero and no
/// `DIP` is in flight, so `main@pc` with `pc` inside the body means exactly
/// `main@pc:<body digest>:halt{}`. Any other legacy form stays a projection.
fn lift_legacy_root_frame(case: &FixtureCase) -> String {
    let column = case.residual_frames.as_str();
    let Some(pc) = column.strip_prefix("main@") else {
        return String::from(column);
    };
    let Ok(pc) = pc.parse::<usize>() else {
        return String::from(column);
    };
    let Some(entry) = case.image.words.iter().find(|word| word.name == "main") else {
        return String::from(column);
    };
    if pc >= entry.code.len() {
        return String::from(column);
    }
    let mut lifted = String::from(column);
    lifted.push(':');
    lifted.push_str(&render_hex(&entry.body_digest));
    lifted.push_str(":halt{}");
    lifted
}

/// Lifts one frozen Lean fixture row into the reference contract it states.
///
/// The row fixes status, canonical stack, residual frames and both cost
/// totals. It carries no world column and does not name a trap class, so those
/// stay unstated; a hand-written witness supplies them where they matter.
/// A `quotation-many`/`quotation-linear` stack item is kept as the usage
/// projection it is, which `compare_conformance` reports as unsupported.
/// Returns `None` for an outcome column outside the frozen vocabulary.
pub fn fixture_reference(case: &FixtureCase) -> Option<ConformanceReference> {
    Some(ConformanceReference {
        status: parse_conformance_status(&case.outcome)?,
        stack: case.final_stack.clone(),
        frames: lift_legacy_root_frame(case),
        cost: ConformanceCostReference {
            total: case.target_cost,
            kernel: case.lean_cost,
            breakdown: None,
        },
        world_observation: None,
        trap: None,
    })
}


fn mismatch(field: &'static str, reference: String, target: String) -> ConformanceMismatch {
    ConformanceMismatch {
        field,
        reference,
        target,
    }
}

/// Compares a full target rendering with a reference that may be a legacy
/// projection.
///
/// A reference in the full grammar is compared exactly. A reference in the
/// legacy profile is compared against the target's projection: a different
/// projection is a disagreement, an equal one is an unsupported comparison,
/// because the projection fixes less than the target reports.
#[allow(clippy::too_many_arguments)]
fn compare_projected(
    field: &'static str,
    reason: &'static str,
    reference: &str,
    target: &str,
    is_projection: fn(&str) -> bool,
    project: fn(&str) -> String,
    mismatches: &mut Vec<ConformanceMismatch>,
    unsupported: &mut Vec<ConformanceUnsupported>,
) {
    if is_projection(reference) {
        let projected = project(target);
        if reference != projected {
            mismatches.push(mismatch(field, String::from(reference), projected));
        } else {
            unsupported.push(ConformanceUnsupported {
                field,
                reason,
                reference: String::from(reference),
                target: String::from(target),
            });
        }
    } else if reference != target {
        mismatches.push(mismatch(field, String::from(reference), String::from(target)));
    }
}

/// Compares one target observation with the reference contract for the same
/// case.
///
/// Dual exhaustion of an equivalent budget is `BoundedFuelInconclusive` and is
/// never reported as agreement. A one-sided exhaustion falls through to the
/// status comparison and disagrees, as `target-spec.md` §7 requires.
///
/// A reference stack that names a quotation only by its usage, or a reference
/// frame stated only as `word@pc`, is a projection: the target is projected
/// the same way and a difference still disagrees, but an equal projection is
/// `UnsupportedComparison`, never `Agree`. Disagreement wins over unsupported,
/// and unsupported wins over agreement.
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
    let mut unsupported = Vec::new();
    if reference.status != target.status {
        mismatches.push(mismatch(
            "status",
            String::from(reference.status.canonical()),
            String::from(target.status.canonical()),
        ));
    }
    compare_projected(
        "stack",
        "the reference states a quotation only by its usage; body and captures are not compared",
        &reference.stack,
        &target.stack,
        is_usage_projection,
        project_stack_to_usage,
        &mut mismatches,
        &mut unsupported,
    );
    compare_projected(
        "frames",
        "the reference states a frame only as word@pc; code, captures and continuation are not compared",
        &reference.frames,
        &target.frames,
        is_frame_projection,
        project_frames_to_legacy,
        &mut mismatches,
        &mut unsupported,
    );
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
    if !mismatches.is_empty() {
        ConformanceVerdict::Disagree(mismatches)
    } else if !unsupported.is_empty() {
        ConformanceVerdict::UnsupportedComparison(unsupported)
    } else {
        ConformanceVerdict::Agree
    }
}

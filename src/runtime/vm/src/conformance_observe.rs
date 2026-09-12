// Observing one execution through the conformance boundary: the decoded
// and the encoded image entry points, each carrying the admission label.

fn conformance_cost(cost: &CostReport) -> ConformanceCost {
    ConformanceCost {
        total: cost.total,
        kernel: cost.kernel_total(),
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
    observe_image_entry(image, "main", initial_stack, fuel, registry)
}

/// Observes one execution of a named entry word through the conformance
/// boundary.
pub fn observe_image_entry(
    image: &Image,
    entry: &str,
    initial_stack: Vec<Value>,
    fuel: u64,
    registry: &PrimitiveRegistry,
) -> ConformanceObservation {
    match execute_diagnostic_entry(image, entry, initial_stack, fuel, registry, None) {
        ExecutionOutcome::Complete(report) => ConformanceObservation {
            status: ConformanceStatus::Terminal,
            stack: render_conformance_stack(&report.stack, registry),
            frames: render_conformance_frames(&report.frames, registry),
            world_observation: report.world.observation().to_vec(),
            trap: None,
            cost: conformance_cost(&report.cost),
            admission: VM_ADMISSION,
        },
        ExecutionOutcome::Trap(trap) => ConformanceObservation {
            status: if trap.error == VmError::FuelExhausted {
                ConformanceStatus::FuelExhausted
            } else {
                ConformanceStatus::Trap
            },
            stack: render_conformance_stack(&trap.stack, registry),
            frames: render_conformance_frames(&trap.frames, registry),
            world_observation: trap.world.observation().to_vec(),
            trap: Some(ConformanceTrap::of_error(&trap.error)),
            cost: conformance_cost(&trap.cost),
            admission: VM_ADMISSION,
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
            admission: VM_ADMISSION,
        },
    }
}

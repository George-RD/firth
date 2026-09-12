// Renderings of the conformance boundary: the value and frame grammar of
// `target-spec.md` §4, the legacy projections `compare_conformance` treats
// as unsupported, and the scalar renderers the CLI prints.

const LEGACY_QUOTATION_MANY: &str = "quotation-many";
const LEGACY_QUOTATION_LINEAR: &str = "quotation-linear";
const INVALID_FRAME: &str = "invalid-frame";

/// Renders one value in the conformance grammar:
///
/// ```text
/// value     ::= int | "true" | "false" | "world" | "bytes:" hex
///             | "primitive:" udec ":" hex | quotation
/// quotation ::= "quotation:" ("many" | "linear") ":" hex64 "{" [slot {"," slot}] "}"
/// slot      ::= value | "consumed"
/// ```
///
/// `hex64` is the lowercase SHA-256 of the quotation's canonical code, so two
/// quotations render alike exactly when their code and every capture slot are
/// equal. Braces occur in no other alphabet of this grammar.
fn render_conformance_value(value: &Value, registry: &PrimitiveRegistry, out: &mut String) {
    match value {
        Value::Int(value) => out.push_str(&value.to_string()),
        Value::Bool(value) => out.push_str(if *value { "true" } else { "false" }),
        Value::Bytes(bytes) => {
            out.push_str("bytes:");
            out.push_str(&render_hex(bytes));
        }
        Value::PrimitiveValue { tag, bytes } => {
            out.push_str("primitive:");
            out.push_str(&tag.to_string());
            out.push(':');
            out.push_str(&render_hex(bytes));
        }
        Value::World => out.push_str("world"),
        Value::Quotation(quotation) => {
            out.push_str("quotation:");
            out.push_str(if quotation.usage(registry) == Usage::Many {
                "many"
            } else {
                "linear"
            });
            out.push(':');
            out.push_str(&render_hex(&sha256(&canonical_code(&quotation.code))));
            render_conformance_slots(
                &quotation.captures,
                &quotation.consumed,
                registry,
                out,
            );
        }
    }
}

fn render_conformance_slots(
    values: &[Value],
    consumed: &[bool],
    registry: &PrimitiveRegistry,
    out: &mut String,
) {
    out.push('{');
    for (index, value) in values.iter().enumerate() {
        if index != 0 {
            out.push(',');
        }
        if consumed.get(index).copied().unwrap_or(false) {
            out.push_str("consumed");
        } else {
            render_conformance_value(value, registry, out);
        }
    }
    out.push('}');
}

/// Renders a residual stack bottom-to-top, comma separated. Scalar spellings
/// retain the frozen Lean fixture form; bytes, primitive values and quotations
/// render their full payloads in the grammar of `render_conformance_value`.
///
/// The legacy usage-only spellings `quotation-many` and `quotation-linear` are
/// never produced here; they remain legal only in a reference string, where
/// `compare_conformance` treats them as a projection.
pub fn render_conformance_stack(stack: &[Value], registry: &PrimitiveRegistry) -> String {
    let mut rendered = String::new();
    for (index, value) in stack.iter().enumerate() {
        if index != 0 {
            rendered.push(',');
        }
        render_conformance_value(value, registry, &mut rendered);
    }
    rendered
}

/// Renders the complete residual frame stack, `-` when empty:
///
/// ```text
/// frames ::= "-" | frame {";" frame}
/// frame  ::= word "@" pc ":" hex64 ":" cont "{" [slot {"," slot}] "}"
/// cont   ::= "halt" | "return" | "restore-dip(" value ")"
/// ```
///
/// `hex64` is the frame's code digest and the braces hold its capture slots,
/// so every field `target-spec.md` §4 requires of a residual configuration
/// (word, code identity, instruction pointer, capture state, continuation and
/// the saved `DIP` value) is comparable. A frame whose saved values do not
/// match its continuation renders `invalid-frame`; the executor never
/// produces one.
pub fn render_conformance_frames(frames: &[FrameTrace], registry: &PrimitiveRegistry) -> String {
    if frames.is_empty() {
        return String::from("-");
    }
    let mut rendered = String::new();
    for (index, frame) in frames.iter().enumerate() {
        if index != 0 {
            rendered.push(';');
        }
        let saved_count = match frame.continuation {
            Continuation::RestoreDip => 1,
            Continuation::Halt | Continuation::Return => 0,
        };
        if frame.saved.len() != saved_count || frame.captures.len() != frame.capture_values.len() {
            rendered.push_str(INVALID_FRAME);
            continue;
        }
        rendered.push_str(&frame.word);
        rendered.push('@');
        rendered.push_str(&frame.pc.to_string());
        rendered.push(':');
        rendered.push_str(&render_hex(&frame.code_digest));
        rendered.push(':');
        rendered.push_str(frame.continuation.canonical());
        if let Some(saved) = frame.saved.first() {
            rendered.push('(');
            render_conformance_value(saved, registry, &mut rendered);
            rendered.push(')');
        }
        render_conformance_slots(&frame.capture_values, &frame.captures, registry, &mut rendered);
    }
    rendered
}

/// Splits a rendering on `separator` outside braces and parentheses, so the
/// commas and semicolons inside quotation slots and saved values do not count.
fn split_outside_groups(text: &str, separator: char) -> Vec<&str> {
    let mut items = Vec::new();
    let mut depth = 0usize;
    let mut start = 0;
    for (index, character) in text.char_indices() {
        match character {
            '{' | '(' => depth += 1,
            '}' | ')' => depth = depth.saturating_sub(1),
            _ if character == separator && depth == 0 => {
                items.push(&text[start..index]);
                start = index + character.len_utf8();
            }
            _ => {}
        }
    }
    items.push(&text[start..]);
    items
}

/// True when a reference stack states some quotation only by its usage.
fn is_usage_projection(stack: &str) -> bool {
    split_outside_groups(stack, ',')
        .into_iter()
        .any(|item| item == LEGACY_QUOTATION_MANY || item == LEGACY_QUOTATION_LINEAR)
}

/// Projects a full stack rendering onto the legacy usage-only profile.
fn project_stack_to_usage(stack: &str) -> String {
    split_outside_groups(stack, ',')
        .into_iter()
        .map(|item| match item.strip_prefix("quotation:") {
            Some(rest) => {
                let usage = rest.split(':').next().unwrap_or_default();
                let mut projected = String::from("quotation-");
                projected.push_str(usage);
                projected
            }
            None => String::from(item),
        })
        .collect::<Vec<_>>()
        .join(",")
}

/// True when a reference frame rendering states some frame only as `word@pc`.
fn is_frame_projection(frames: &str) -> bool {
    frames != "-"
        && split_outside_groups(frames, ';')
            .into_iter()
            .any(|frame| !frame.contains(':'))
}

/// Projects a full frame rendering onto the legacy `word@pc` profile.
fn project_frames_to_legacy(frames: &str) -> String {
    if frames == "-" {
        return String::from(frames);
    }
    split_outside_groups(frames, ';')
        .into_iter()
        .map(|frame| frame.split(':').next().unwrap_or_default())
        .collect::<Vec<_>>()
        .join(";")
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

/// Renders an admission label as `admission=.. image-evidence=.. refinements=.. patch-admission=..`.
pub fn render_conformance_admission(label: &AdmissionLabel) -> String {
    let mut rendered = String::from("admission=");
    rendered.push_str(label.admission);
    rendered.push_str(" image-evidence=");
    rendered.push_str(label.image_evidence);
    rendered.push_str(" refinements=");
    rendered.push_str(label.refinements);
    rendered.push_str(" patch-admission=");
    rendered.push_str(label.patch_admission);
    rendered
}

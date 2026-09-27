fn add_int(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let (left, right) = pop_int_pair(context)?;
    context.push_int(left.checked_add(right).ok_or(VmError::PrimitiveFault)?)
}

/// Pops the two integer operands of a binary primitive, `left` below `right`.
fn pop_int_pair(context: &mut PrimitiveContext<'_>) -> Result<(i64, i64), VmError> {
    let right = context.pop_int()?;
    let left = context.pop_int()?;
    Ok((left, right))
}

fn sub_int(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let (left, right) = pop_int_pair(context)?;
    context.push_int(left.checked_sub(right).ok_or(VmError::PrimitiveFault)?)
}

fn mul_int(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let (left, right) = pop_int_pair(context)?;
    context.push_int(left.checked_mul(right).ok_or(VmError::PrimitiveFault)?)
}

fn lt_int(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let (left, right) = pop_int_pair(context)?;
    context.push_bool(left < right)
}

fn eq_int(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let (left, right) = pop_int_pair(context)?;
    context.push_bool(left == right)
}

fn and_bool(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let right = context.pop_bool()?;
    let left = context.pop_bool()?;
    context.push_bool(left && right)
}

fn or_bool(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let right = context.pop_bool()?;
    let left = context.pop_bool()?;
    context.push_bool(left || right)
}

fn not_bool(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let value = context.pop_bool()?;
    context.push_bool(!value)
}

/// The element at `index` of a sequence whose elements are `width` bytes
/// wide. An index past the end is a primitive fault, never a default.
fn element(bytes: &[u8], index: i64, width: usize) -> Result<&[u8], VmError> {
    let index = usize::try_from(index).map_err(|_| VmError::PrimitiveFault)?;
    let start = index.checked_mul(width).ok_or(VmError::PrimitiveFault)?;
    let end = start.checked_add(width).ok_or(VmError::PrimitiveFault)?;
    bytes
        .get(start..end)
        .ok_or(VmError::PrimitiveFault)
}

fn int_seq_empty(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    context.push_primitive(SEQ_INT_TAG, Vec::new())
}

fn int_seq_len(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let bytes = context.pop_primitive(SEQ_INT_TAG)?;
    context.push_int(i64::try_from(bytes.len() / 8).map_err(|_| VmError::PrimitiveFault)?)
}

fn int_seq_at(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let index = context.pop_int()?;
    let bytes = context.pop_primitive(SEQ_INT_TAG)?;
    let mut word = [0u8; 8];
    word.copy_from_slice(element(&bytes, index, 8)?);
    context.push_int(i64::from_le_bytes(word))
}

fn int_seq_push(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let value = context.pop_int()?;
    let mut bytes = context.pop_primitive(SEQ_INT_TAG)?;
    reserve(&mut bytes, 8)?;
    bytes.extend_from_slice(&value.to_le_bytes());
    context.push_primitive(SEQ_INT_TAG, bytes)
}

fn bool_seq_empty(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    context.push_primitive(SEQ_BOOL_TAG, Vec::new())
}

fn bool_seq_len(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let bytes = context.pop_primitive(SEQ_BOOL_TAG)?;
    context.push_int(i64::try_from(bytes.len()).map_err(|_| VmError::PrimitiveFault)?)
}

fn bool_seq_at(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let index = context.pop_int()?;
    let bytes = context.pop_primitive(SEQ_BOOL_TAG)?;
    let byte = element(&bytes, index, 1)?[0];
    context.push_bool(byte == 1)
}

fn bool_seq_push(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let value = context.pop_bool()?;
    let mut bytes = context.pop_primitive(SEQ_BOOL_TAG)?;
    reserve(&mut bytes, 1)?;
    bytes.push(u8::from(value));
    context.push_primitive(SEQ_BOOL_TAG, bytes)
}

fn make_world(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    context.make_world()?;
    reserve(&mut context.world.observation, 1)?;
    context.world.observation.push(0);
    Ok(())
}

fn consume_world(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    context.consume_world()
}

pub fn default_registry() -> PrimitiveRegistry {
    PrimitiveRegistry {
        version: GAMMA_VERSION,
        definitions: vec![
            PrimitiveDefinition {
                name: "addInt",
                cost: 1,
                handler: add_int,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "subInt",
                cost: 1,
                handler: sub_int,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "mulInt",
                cost: 1,
                handler: mul_int,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "ltInt",
                cost: 1,
                handler: lt_int,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "eqInt",
                cost: 1,
                handler: eq_int,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "andBool",
                cost: 1,
                handler: and_bool,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "orBool",
                cost: 1,
                handler: or_bool,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "notBool",
                cost: 1,
                handler: not_bool,
                input: &[Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "intSeqEmpty",
                cost: 1,
                handler: int_seq_empty,
                input: &[],
                output: &[Usage::Many],
                world: false,
                value_tags: &[(SEQ_INT_TAG, Usage::Many)],
            },
            PrimitiveDefinition {
                name: "intSeqLen",
                cost: 1,
                handler: int_seq_len,
                input: &[Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "intSeqAt",
                cost: 1,
                handler: int_seq_at,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "intSeqPush",
                cost: 1,
                handler: int_seq_push,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "boolSeqEmpty",
                cost: 1,
                handler: bool_seq_empty,
                input: &[],
                output: &[Usage::Many],
                world: false,
                value_tags: &[(SEQ_BOOL_TAG, Usage::Many)],
            },
            PrimitiveDefinition {
                name: "boolSeqLen",
                cost: 1,
                handler: bool_seq_len,
                input: &[Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "boolSeqAt",
                cost: 1,
                handler: bool_seq_at,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "boolSeqPush",
                cost: 1,
                handler: bool_seq_push,
                input: &[Usage::Many, Usage::Many],
                output: &[Usage::Many],
                world: false,
                value_tags: &[],
            },
            PrimitiveDefinition {
                name: "makeWorld",
                cost: 1,
                handler: make_world,
                input: &[],
                output: &[Usage::Linear],
                world: true,
                value_tags: &[(1, Usage::Linear)],
            },
            PrimitiveDefinition {
                name: "consumeWorld",
                cost: 1,
                handler: consume_world,
                input: &[Usage::Linear],
                output: &[],
                world: true,
                value_tags: &[],
            },
        ],
    }
}

pub fn decode(bytes: &[u8]) -> Result<Image, VmError> {
    if bytes.len() > MAX_BYTES {
        return Err(VmError::InputTooLarge);
    }
    let mut reader = Reader::new(bytes);
    let format_version = u16::try_from(reader.unsigned()?).map_err(|_| VmError::InvalidLeb128)?;
    if format_version != FORMAT_VERSION {
        return Err(VmError::UnsupportedFormat(format_version));
    }
    let image_version = reader.unsigned()?;
    let gamma_version = reader.unsigned()?;
    if gamma_version != GAMMA_VERSION {
        return Err(VmError::UnsupportedGamma(gamma_version));
    }
    let words = reader.vector(|reader| decode_word(reader))?;
    for pair in words.windows(2) {
        if pair[0].name.as_bytes() >= pair[1].name.as_bytes() {
            return Err(if pair[0].name == pair[1].name {
                VmError::DuplicateWord
            } else {
                VmError::UnsortedWords
            });
        }
    }
    let dictionary_digest = reader.digest()?;
    let image_digest = reader.digest()?;
    if dictionary_digest != sha256(&canonical_dictionary(&words))
        || image_digest
            != sha256(&canonical_image_identity(
                format_version,
                image_version,
                gamma_version,
                &dictionary_digest,
            ))
    {
        return Err(VmError::InvalidDigest);
    }
    if !reader.remaining().is_empty() {
        return Err(VmError::TrailingBytes);
    }
    let image = Image {
        format_version,
        image_version,
        gamma_version,
        words,
        dictionary_digest,
        image_digest,
    };
    validate_image(&image)?;
    Ok(image)
}

/// Decode a generated Lean fixture row through the same binary image decoder
/// used for real VM images. This is production support for the differential
/// harness, not a test-only alternate image representation.
pub fn decode_fixture_line(line: &str) -> Result<FixtureCase, VmError> {
    let fields: Vec<&str> = line.split('|').collect();
    if fields.len() != 9 {
        return Err(VmError::Truncated);
    }
    let initial_stack = fixture_stack(fields[1])?;
    let mut words = fixture_dictionary(fields[2])?;
    words.push(fixture_word("main", fixture_code(fields[3])?));
    let image = fixture_image(words);
    let image = decode(&encode_image(&image))?;
    Ok(FixtureCase {
        name: String::from(fields[0]),
        initial_stack,
        image,
        outcome: String::from(fields[4]),
        final_stack: String::from(fields[5]),
        lean_cost: fields[6].parse().map_err(|_| VmError::InvalidLeb128)?,
        residual_frames: String::from(fields[7]),
        target_cost: fields[8].parse().map_err(|_| VmError::InvalidLeb128)?,
    })
}

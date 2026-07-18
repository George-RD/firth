fn add_nat(context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
    let right = context.pop_int()?;
    let left = context.pop_int()?;
    context.push_int(left.checked_add(right).ok_or(VmError::PrimitiveFault)?)
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
                name: "addNat",
                cost: 1,
                handler: add_nat,
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


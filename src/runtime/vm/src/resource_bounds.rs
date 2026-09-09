// Shared resource admission for images, patches and initial value stacks.
// Measure before canonical encoding/hashing: caller-created values need not
// have passed the bounded wire decoder. No allocations are made by this pass.

fn validate_image_resource_bounds(image: &Image) -> Result<(), VmError> {
    if image.words.len() as u64 > MAX_INSTRUCTIONS {
        return Err(VmError::InstructionLimit);
    }
    let mut size = 0;
    for value in [
        u64::from(image.format_version),
        image.image_version,
        image.gamma_version,
        image.words.len() as u64,
    ] {
        measure_add(&mut size, unsigned_size(value))?;
    }
    for word in &image.words {
        measure_word(word, &mut size)?;
    }
    measure_add(&mut size, image.dictionary_digest.len())?;
    measure_add(&mut size, image.image_digest.len())
}

fn validate_initial_stack(values: &[Value]) -> Result<(), VmError> {
    if values.len() as u64 > MAX_INSTRUCTIONS {
        return Err(VmError::InstructionLimit);
    }
    let mut size = unsigned_size(values.len() as u64);
    for value in values {
        measure_value(value, 0, &mut size)?;
    }
    for value in values {
        validate_value_structure(value, 0)?;
        validate_capture_value_indices(value)?;
    }
    Ok(())
}

fn measure_code(code: &[Instruction], depth: usize, size: &mut usize) -> Result<(), VmError> {
    if depth > MAX_NESTING {
        return Err(VmError::NestingLimit);
    }
    if code.len() as u64 > MAX_INSTRUCTIONS {
        return Err(VmError::InstructionLimit);
    }
    measure_add(size, unsigned_size(code.len() as u64))?;
    for instruction in code {
        measure_add(size, 1)?;
        match instruction.operand.as_ref() {
            Some(Operand::Literal(value)) => measure_value(value, depth, size)?,
            Some(Operand::Quote(quotation)) => measure_quotation(quotation, depth + 1, size)?,
            Some(Operand::Capture(index)) => measure_add(size, unsigned_size(*index))?,
            Some(Operand::Word(name)) | Some(Operand::Primitive(name)) => {
                measure_bytes(name.len(), size)?;
            }
            None => {}
        }
    }
    Ok(())
}

fn measure_quotation(
    quotation: &Quotation,
    depth: usize,
    size: &mut usize,
) -> Result<(), VmError> {
    if quotation.captures.len() as u64 > MAX_INSTRUCTIONS
        || quotation.consumed.len() as u64 > MAX_INSTRUCTIONS
    {
        return Err(VmError::InstructionLimit);
    }
    if quotation.consumed.len() != quotation.captures.len() {
        return Err(VmError::InvalidCaptureBitmap);
    }
    measure_code(&quotation.code, depth, size)?;
    measure_add(size, unsigned_size(quotation.captures.len() as u64))?;
    measure_add(size, quotation.captures.len().div_ceil(8))?;
    for capture in &quotation.captures {
        measure_value(capture, depth, size)?;
    }
    Ok(())
}

fn measure_word(word: &WordEntry, size: &mut usize) -> Result<(), VmError> {
    measure_bytes(word.name.len(), size)?;
    measure_bytes(word.erased_word_type.len(), size)?;
    measure_code(&word.code, 0, size)?;
    measure_add(size, word.body_digest.len())?;
    measure_add(size, word.kernel_evidence_digest.len())?;
    measure_add(size, word.refinement_evidence_digest.len())?;
    measure_add(size, unsigned_size(word.generation))
}

fn measure_value(value: &Value, depth: usize, size: &mut usize) -> Result<(), VmError> {
    measure_add(size, 1)?;
    match value {
        Value::Int(value) => {
            let zigzag = ((*value as u64) << 1) ^ ((*value >> 63) as u64);
            measure_add(size, unsigned_size(zigzag))
        }
        Value::Bool(_) | Value::World => {
            measure_add(size, usize::from(matches!(value, Value::Bool(_))))
        }
        Value::Bytes(bytes) => measure_bytes(bytes.len(), size),
        Value::Quotation(quotation) => measure_quotation(quotation, depth + 1, size),
        Value::PrimitiveValue { tag, bytes } => {
            measure_add(size, unsigned_size(*tag))?;
            measure_bytes(bytes.len(), size)
        }
    }
}

fn measure_bytes(length: usize, size: &mut usize) -> Result<(), VmError> {
    if length > MAX_BYTES {
        return Err(VmError::LengthLimit);
    }
    measure_add(size, unsigned_size(length as u64))?;
    measure_add(size, length)
}

fn measure_add(size: &mut usize, additional: usize) -> Result<(), VmError> {
    *size = size.checked_add(additional).ok_or(VmError::LengthLimit)?;
    if *size > MAX_BYTES {
        return Err(VmError::LengthLimit);
    }
    Ok(())
}

fn unsigned_size(mut value: u64) -> usize {
    let mut size = 1;
    while value >= 0x80 {
        value >>= 7;
        size += 1;
    }
    size
}

struct PatchServices<'a> {
    verifier: &'a dyn PatchVerifier,
    allocation: &'a dyn ImageAllocation,
}

fn prepare_patch(
    base: &Image,
    patch: &WordPatch,
    services: PatchServices<'_>,
) -> Result<Image, ImageError> {
    validate_patch_resource_bounds(patch)?;
    let index = base
        .words
        .binary_search_by(|word| word.name.as_str().cmp(&patch.name))
        .map_err(|_| ImageError::MissingWord(patch.name.clone()))?;
    let old_word = &base.words[index];
    let evidence = PatchEvidence {
        expected_image_version: patch.expected_image_version,
        old_word,
        replacement: patch,
    };
    if !services.verifier.verify(&evidence) {
        return Err(ImageError::UnprovenPatch);
    }
    if base.image_version != patch.expected_image_version {
        return Err(ImageError::StaleImage {
            expected: patch.expected_image_version,
            actual: base.image_version,
        });
    }
    if old_word.body_digest != patch.expected_body_digest {
        return Err(ImageError::StaleWord);
    }
    validate_code_structure(&patch.code, 0).map_err(ImageError::InvalidImage)?;
    if patch.body_digest.len() != DIGEST_BYTES
        || patch.body_digest != sha256(&canonical_code(&patch.code))
    {
        return Err(ImageError::InvalidBodyDigest);
    }
    if !valid_evidence_digest(&patch.kernel_evidence_digest)
        || !valid_evidence_digest(&patch.refinement_evidence_digest)
    {
        return Err(ImageError::InvalidEvidenceDigest);
    }
    validate_patch_references(&patch.code, base, &default_registry())?;
    if erased_type_mentions_world(&patch.erased_word_type) {
        return Err(ImageError::EffectfulWord);
    }
    if old_word.erased_word_type != patch.erased_word_type {
        return Err(ImageError::WordTypeMismatch);
    }
    let generation = old_word
        .generation
        .checked_add(1)
        .ok_or(ImageError::GenerationExhausted)?;
    let new_word = WordEntry {
        name: patch.name.clone(),
        erased_word_type: patch.erased_word_type.clone(),
        code: patch.code.clone(),
        body_digest: patch.body_digest.clone(),
        kernel_evidence_digest: patch.kernel_evidence_digest.clone(),
        refinement_evidence_digest: patch.refinement_evidence_digest.clone(),
        generation,
    };
    let image_version = base
        .image_version
        .checked_add(1)
        .ok_or(ImageError::VersionExhausted)?;
    validate_candidate_image_bounds(base, index, &new_word, image_version)?;
    let mut words = services.allocation.copy_words(&base.words)?;
    words[index] = new_word;
    let dictionary_digest = sha256(&canonical_dictionary(&words)).to_vec();
    let image = Image {
        format_version: base.format_version,
        image_version,
        gamma_version: base.gamma_version,
        image_digest: sha256(&canonical_image_identity(
            base.format_version,
            image_version,
            base.gamma_version,
            &dictionary_digest,
        ))
        .to_vec(),
        dictionary_digest,
        words,
    };
    validate_image(&image).map_err(ImageError::InvalidImage)?;
    Ok(image)
}

fn valid_evidence_digest(digest: &[u8]) -> bool {
    digest.len() == DIGEST_BYTES && !is_zero_digest(digest)
}

fn erased_type_mentions_world(word_type: &str) -> bool {
    word_type.match_indices(":World").any(|(index, _)| {
        matches!(
            word_type.as_bytes().get(index + 6),
            Some(b'^' | b',' | b'-' | b']' | b')')
        )
    })
}

fn validate_patch_references(
    code: &[Instruction],
    image: &Image,
    registry: &PrimitiveRegistry,
) -> Result<(), ImageError> {
    for instruction in code {
        match instruction.operand.as_ref() {
            Some(Operand::Quote(quotation)) => {
                validate_patch_references(&quotation.code, image, registry)?;
                for capture in &quotation.captures {
                    validate_patch_value(capture, image, registry)?;
                }
            }
            Some(Operand::Word(name)) => {
                if image
                    .words
                    .binary_search_by(|word| word.name.as_str().cmp(name))
                    .is_err()
                {
                    return Err(ImageError::UnknownReference(name.clone()));
                }
            }
            Some(Operand::Primitive(name)) => {
                let definition = registry
                    .definitions
                    .iter()
                    .find(|definition| definition.name == name)
                    .ok_or_else(|| ImageError::UnknownPrimitive(name.clone()))?;
                if definition.world {
                    return Err(ImageError::EffectfulWord);
                }
            }
            Some(Operand::Literal(_) | Operand::Capture(_)) | None => {}
        }
    }
    Ok(())
}

fn validate_patch_value(
    value: &Value,
    image: &Image,
    registry: &PrimitiveRegistry,
) -> Result<(), ImageError> {
    match value {
        Value::Quotation(quotation) => {
            validate_patch_references(&quotation.code, image, registry)?;
            for capture in &quotation.captures {
                validate_patch_value(capture, image, registry)?;
            }
            Ok(())
        }
        Value::World => Err(ImageError::EffectfulWord),
        Value::Int(_) | Value::Bool(_) | Value::Bytes(_) | Value::PrimitiveValue { .. } => Ok(()),
    }
}

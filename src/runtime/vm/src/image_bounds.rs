fn validate_patch_resource_bounds(patch: &WordPatch) -> Result<(), ImageError> {
    let mut size = 0;
    measure_add(&mut size, unsigned_size(patch.expected_image_version))
        .map_err(ImageError::InvalidImage)?;
    for length in [
        patch.name.len(),
        patch.expected_body_digest.len(),
        patch.erased_word_type.len(),
        patch.body_digest.len(),
        patch.kernel_evidence_digest.len(),
        patch.refinement_evidence_digest.len(),
    ] {
        measure_bytes(length, &mut size).map_err(ImageError::InvalidImage)?;
    }
    measure_code(&patch.code, 0, &mut size).map_err(ImageError::InvalidImage)
}

fn validate_candidate_image_bounds(
    base: &Image,
    replacement_index: usize,
    replacement: &WordEntry,
    image_version: u64,
) -> Result<(), ImageError> {
    let mut size = 0;
    measure_add(&mut size, unsigned_size(u64::from(base.format_version)))
        .map_err(ImageError::InvalidImage)?;
    measure_add(&mut size, unsigned_size(image_version)).map_err(ImageError::InvalidImage)?;
    measure_add(&mut size, unsigned_size(base.gamma_version)).map_err(ImageError::InvalidImage)?;
    measure_add(&mut size, unsigned_size(base.words.len() as u64))
        .map_err(ImageError::InvalidImage)?;
    for (index, word) in base.words.iter().enumerate() {
        measure_word(
            if index == replacement_index { replacement } else { word },
            &mut size,
        )
        .map_err(ImageError::InvalidImage)?;
    }
    measure_add(&mut size, DIGEST_BYTES * 2).map_err(ImageError::InvalidImage)
}

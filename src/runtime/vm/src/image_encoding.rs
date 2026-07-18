pub fn encode_image(image: &Image) -> Vec<u8> {
    let mut bytes = Vec::new();
    put_unsigned(&mut bytes, u64::from(image.format_version));
    put_unsigned(&mut bytes, image.image_version);
    put_unsigned(&mut bytes, image.gamma_version);
    put_unsigned(&mut bytes, image.words.len() as u64);
    for word in &image.words {
        put_string(&mut bytes, &word.name);
        put_string(&mut bytes, &word.erased_word_type);
        bytes.extend(canonical_code(&word.code));
        bytes.extend(&word.body_digest);
        bytes.extend(&word.kernel_evidence_digest);
        bytes.extend(&word.refinement_evidence_digest);
        put_unsigned(&mut bytes, word.generation);
    }
    bytes.extend(&image.dictionary_digest);
    bytes.extend(&image.image_digest);
    bytes
}

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

/// SHA-256 of a word body's canonical encoding, which is how `target-spec.md`
/// §7 defines `body_digest`. An embedder preparing a `WordEntry` or a
/// `WordPatch` computes its digest through this boundary instead of
/// re-deriving the canonical encoding.
pub fn body_digest(code: &[Instruction]) -> Vec<u8> {
    sha256(&canonical_code(code)).to_vec()
}

/// SHA-256 of externally owned evidence bytes, which is how `target-spec.md`
/// §7 defines the kernel and refinement evidence digests. The VM binds the
/// digest and never interprets the payload.
pub fn evidence_digest(payload: &[u8]) -> Vec<u8> {
    sha256(payload).to_vec()
}

/// Seals a word vector into an image at `image_version`: the dictionary is
/// sorted by canonical name bytes and both identity digests are computed, so
/// the result survives `decode(&encode_image(..))` unchanged.
pub fn seal_image(image_version: u64, mut words: Vec<WordEntry>) -> Image {
    words.sort_by(|left, right| left.name.as_bytes().cmp(right.name.as_bytes()));
    let dictionary_digest = sha256(&canonical_dictionary(&words)).to_vec();
    let image_digest = sha256(&canonical_image_identity(
        FORMAT_VERSION,
        image_version,
        GAMMA_VERSION,
        &dictionary_digest,
    ))
    .to_vec();
    Image {
        format_version: FORMAT_VERSION,
        image_version,
        gamma_version: GAMMA_VERSION,
        words,
        dictionary_digest,
        image_digest,
    }
}

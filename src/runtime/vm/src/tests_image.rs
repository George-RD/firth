    #[derive(Clone)]
    struct ExactEvidence {
        expected_version: u64,
        old_body: Vec<u8>,
        new_body: Vec<u8>,
        kernel: Vec<u8>,
        refinement: Vec<u8>,
    }

    impl PatchVerifier for ExactEvidence {
        fn verify(&self, evidence: &PatchEvidence<'_>) -> bool {
            evidence.expected_image_version == self.expected_version
                && evidence.replacement.expected_body_digest == self.old_body
                && evidence.replacement.body_digest == self.new_body
                && evidence.replacement.kernel_evidence_digest == self.kernel
                && evidence.replacement.refinement_evidence_digest == self.refinement
        }
    }

    struct ExternalPass;

    impl PatchVerifier for ExternalPass {
        fn verify(&self, _evidence: &PatchEvidence<'_>) -> bool {
            true
        }
    }

    fn literal_code(value: i64) -> Vec<Instruction> {
        vec![instruction(
            Op::PushLiteral,
            Some(Operand::Literal(Value::Int(value))),
        )]
    }

    fn patch_for(image: &Image, name: &str, value: i64) -> (WordPatch, ExactEvidence) {
        let old = image
            .words
            .iter()
            .find(|word| word.name == name)
            .expect("fixture word");
        let code = literal_code(value);
        let body_digest = sha256(&canonical_code(&code)).to_vec();
        let kernel_evidence_digest = sha256(b"kernel replacement proof").to_vec();
        let refinement_evidence_digest = sha256(b"refinement subsumption proof").to_vec();
        (
            WordPatch {
                name: String::from(name),
                expected_image_version: image.image_version,
                expected_body_digest: old.body_digest.clone(),
                erased_word_type: old.erased_word_type.clone(),
                code,
                body_digest: body_digest.clone(),
                kernel_evidence_digest: kernel_evidence_digest.clone(),
                refinement_evidence_digest: refinement_evidence_digest.clone(),
            },
            ExactEvidence {
                expected_version: image.image_version,
                old_body: old.body_digest.clone(),
                new_body: body_digest,
                kernel: kernel_evidence_digest,
                refinement: refinement_evidence_digest,
            },
        )
    }

    fn dictionary_image() -> Image {
        let main = word(
            "main",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("value"))),
            )],
        );
        test_image(vec![main, word("value", literal_code(1))])
    }

    #[test]
    fn canonical_image_round_trip_preserves_word_identity_and_digests() {
        let image = dictionary_image();

        let decoded = decode(&encode_image(&image)).expect("canonical image round trip");

        assert_eq!(decoded, image);
        assert_eq!(decoded.dictionary_digest, sha256(&canonical_dictionary(&decoded.words)));
        assert_eq!(
            decoded.image_digest,
            sha256(&canonical_image_identity(
                decoded.format_version,
                decoded.image_version,
                decoded.gamma_version,
                &decoded.dictionary_digest,
            ))
        );
    }

    #[test]
    fn verified_patch_replaces_exactly_one_binding_atomically() {
        let image = dictionary_image();
        let unchanged = image.words[0].clone();
        let old_dictionary_digest = image.dictionary_digest.clone();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");

        let published = store
            .apply_patch(&patch, &verifier)
            .expect("verified patch publishes");

        assert_eq!(published.image_version(), 2);
        assert_eq!(published.image().words[0], unchanged);
        let replacement = published.lookup("value").expect("replacement word");
        assert_eq!(replacement.entry().generation, 1);
        assert_eq!(replacement.entry().code, literal_code(2));
        assert_eq!(replacement.entry().body_digest, patch.body_digest);
        assert_ne!(published.image().dictionary_digest, old_dictionary_digest);
        assert_eq!(
            published.image().dictionary_digest,
            sha256(&canonical_dictionary(&published.image().words))
        );
    }

    #[test]
    fn unproven_patch_is_rejected_without_changing_the_active_image() {
        struct RejectEvidence;
        impl PatchVerifier for RejectEvidence {
            fn verify(&self, _evidence: &PatchEvidence<'_>) -> bool {
                false
            }
        }

        let image = dictionary_image();
        let original_digest = image.image_digest.clone();
        let (patch, _) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");

        let error = store
            .apply_patch(&patch, &RejectEvidence)
            .expect_err("unproven patch must fail");

        assert_eq!(error, ImageError::UnprovenPatch);
        assert_eq!(error.stable_code(), "patch-fault");
        assert_eq!(error.stable_subcode(), "unproven-patch");
        assert_eq!(store.snapshot().expect("active image").image_digest(), original_digest);
    }

    #[test]
    fn patch_errors_are_deterministic_and_leave_the_image_unchanged() {
        let image = dictionary_image();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image.clone()).expect("valid store");

        let mut missing = patch.clone();
        missing.name = String::from("missing");
        assert!(matches!(
            store.apply_patch(&missing, &verifier),
            Err(ref error @ ImageError::MissingWord(ref name))
                if name == "missing" && error.stable_code() == "patch-fault"
        ));

        let mut wrong_type = patch.clone();
        wrong_type.erased_word_type = String::from("(forallρ;ρ--ρ,x:Int^many)");
        assert!(matches!(
            store.apply_patch(&wrong_type, &verifier),
            Err(ImageError::WordTypeMismatch)
        ));

        let mut wrong_body = patch.clone();
        wrong_body.body_digest[0] ^= 1;
        assert!(matches!(
            store.apply_patch(&wrong_body, &ExternalPass),
            Err(ImageError::InvalidBodyDigest)
        ));

        let mut missing_evidence = patch.clone();
        missing_evidence.kernel_evidence_digest.fill(0);
        assert!(matches!(
            store.apply_patch(&missing_evidence, &ExternalPass),
            Err(ImageError::InvalidEvidenceDigest)
        ));

        let mut stale = patch.clone();
        stale.expected_image_version = 0;
        assert!(matches!(
            store.apply_patch(&stale, &ExternalPass),
            Err(ImageError::StaleImage {
                expected: 0,
                actual: 1
            })
        ));

        assert_eq!(store.snapshot().expect("active image").image(), &image);
    }

    #[test]
    fn rollback_republishes_prior_contents_with_a_fresh_version() {
        let image = dictionary_image();
        let old_dictionary_digest = image.dictionary_digest.clone();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");
        store.apply_patch(&patch, &verifier).expect("patch");

        let rolled_back = store.rollback(2, 1).expect("rollback");

        assert_eq!(rolled_back.image_version(), 3);
        assert_eq!(rolled_back.image().dictionary_digest, old_dictionary_digest);
        assert_eq!(rolled_back.lookup("value").expect("value").entry().code, literal_code(1));
        assert_ne!(rolled_back.image().image_digest, patch.body_digest);
    }

    #[test]
    fn external_evidence_precedes_vm_patch_validation() {
        use core::sync::atomic::{AtomicUsize, Ordering};

        struct RejectAndCount<'a>(&'a AtomicUsize);
        impl PatchVerifier for RejectAndCount<'_> {
            fn verify(&self, _evidence: &PatchEvidence<'_>) -> bool {
                self.0.fetch_add(1, Ordering::SeqCst);
                false
            }
        }

        let image = dictionary_image();
        let (mut patch, mut verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");
        patch.code = vec![instruction(
            Op::CallWord,
            Some(Operand::Word(String::from("absent"))),
        )];
        patch.body_digest = sha256(&canonical_code(&patch.code)).to_vec();
        verifier.new_body = patch.body_digest.clone();
        let calls = AtomicUsize::new(0);
        assert!(matches!(
            store.apply_patch(&patch, &RejectAndCount(&calls)),
            Err(ImageError::UnprovenPatch)
        ));
        assert_eq!(calls.load(Ordering::SeqCst), 1);

        patch.expected_image_version = 0;
        assert!(matches!(
            store.apply_patch(&patch, &RejectAndCount(&calls)),
            Err(ImageError::UnprovenPatch)
        ));
        assert_eq!(calls.load(Ordering::SeqCst), 2);
        patch.expected_image_version = 1;
        patch.expected_body_digest[0] ^= 1;
        assert!(matches!(
            store.apply_patch(&patch, &RejectAndCount(&calls)),
            Err(ImageError::UnprovenPatch)
        ));
        assert_eq!(calls.load(Ordering::SeqCst), 3);
        patch.expected_body_digest[0] ^= 1;
        patch.expected_image_version = 1;
        assert!(matches!(
            store.apply_patch(&patch, &verifier),
            Err(ImageError::UnknownReference(name)) if name == "absent"
        ));

        patch.code = vec![instruction(
            Op::Prim,
            Some(Operand::Primitive(String::from("makeWorld"))),
        )];
        patch.body_digest = sha256(&canonical_code(&patch.code)).to_vec();
        verifier.new_body = patch.body_digest.clone();
        assert!(matches!(
            store.apply_patch(&patch, &verifier),
            Err(ImageError::EffectfulWord)
        ));

        patch.code = literal_code(2);
        patch.body_digest = sha256(&canonical_code(&patch.code)).to_vec();
        for word_type in [
            "(forallρ;ρ--ρ,x:World)",
            "(forallρ;ρ--ρ,x:World^many)",
            "(forallρ;ρ--ρ,x:World^linear)",
        ] {
            patch.erased_word_type = String::from(word_type);
            assert!(matches!(
                store.apply_patch(&patch, &ExternalPass),
                Err(ImageError::EffectfulWord)
            ));
        }
    }

    #[test]
    fn oversized_and_deep_patches_fail_before_hashing_or_verification() {
        struct MustNotVerify;
        impl PatchVerifier for MustNotVerify {
            fn verify(&self, _evidence: &PatchEvidence<'_>) -> bool {
                panic!("resource-invalid patch reached external verifier")
            }
        }

        let image = dictionary_image();
        let (mut patch, _) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");
        patch.name = "x".repeat(MAX_BYTES + 1);
        assert!(matches!(
            store.apply_patch(&patch, &MustNotVerify),
            Err(ImageError::InvalidImage(VmError::LengthLimit))
        ));
        patch.name = String::from("value");

        patch.code = vec![instruction(Op::Dup, None); MAX_INSTRUCTIONS as usize + 1];
        assert!(matches!(
            store.apply_patch(&patch, &MustNotVerify),
            Err(ImageError::InvalidImage(VmError::InstructionLimit))
        ));

        patch.code = literal_code(2);
        patch.kernel_evidence_digest = vec![1; MAX_BYTES + 1];
        assert!(matches!(
            store.apply_patch(&patch, &MustNotVerify),
            Err(ImageError::InvalidImage(VmError::LengthLimit))
        ));
        patch.kernel_evidence_digest = sha256(b"kernel replacement proof").to_vec();

        let mut quotation = Quotation {
            code: Vec::new(),
            captures: Vec::new(),
            consumed: Vec::new(),
        };
        for _ in 0..=MAX_NESTING {
            quotation = Quotation {
                code: vec![instruction(Op::PushQuote, Some(Operand::Quote(quotation)))],
                captures: Vec::new(),
                consumed: Vec::new(),
            };
        }
        patch.code = quotation.code;
        assert!(matches!(
            store.apply_patch(&patch, &MustNotVerify),
            Err(ImageError::InvalidImage(VmError::NestingLimit))
        ));

        patch.code = vec![instruction(
            Op::PushQuote,
            Some(Operand::Quote(Quotation {
                code: Vec::new(),
                captures: Vec::new(),
                consumed: vec![false; MAX_INSTRUCTIONS as usize + 1],
            })),
        )];
        assert!(matches!(
            store.apply_patch(&patch, &MustNotVerify),
            Err(ImageError::InvalidImage(VmError::InstructionLimit))
        ));
    }

    #[test]
    fn captured_quotation_references_are_validated() {
        let image = dictionary_image();
        let (mut patch, mut verifier) = patch_for(&image, "value", 2);
        let deepest = Value::Quotation(Quotation {
            code: vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("absent"))),
            )],
            captures: Vec::new(),
            consumed: Vec::new(),
        });
        let hidden = Value::Quotation(Quotation {
            code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
            captures: vec![deepest],
            consumed: vec![false],
        });
        patch.code = vec![instruction(
            Op::PushQuote,
            Some(Operand::Quote(Quotation {
                code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                captures: vec![hidden],
                consumed: vec![false],
            })),
        )];
        patch.body_digest = sha256(&canonical_code(&patch.code)).to_vec();
        verifier.new_body = patch.body_digest.clone();
        let store = ImageStore::new(image).expect("valid store");

        assert!(matches!(
            store.apply_patch(&patch, &verifier),
            Err(ImageError::UnknownReference(name)) if name == "absent"
        ));
    }

    #[test]
    fn candidate_image_size_is_bounded_before_copy_and_hash() {
        struct MustNotCopy;
        impl ImageAllocation for MustNotCopy {
            fn copy_words(&self, _words: &[WordEntry]) -> Result<Vec<WordEntry>, ImageError> {
                panic!("oversized candidate reached image copy")
            }
        }

        let half_limit = MAX_BYTES / 2;
        let padding = word(
            "padding",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Bytes(vec![0; half_limit]))),
            )],
        );
        let main = word(
            "main",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("value"))),
            )],
        );
        let image = test_image(vec![main, padding, word("value", literal_code(1))]);
        let (mut patch, _) = patch_for(&image, "value", 2);
        patch.code = vec![instruction(
            Op::PushLiteral,
            Some(Operand::Literal(Value::Bytes(vec![0; half_limit]))),
        )];
        patch.body_digest = sha256(&canonical_code(&patch.code)).to_vec();
        let store = ImageStore::new(image).expect("bounded base image");

        assert!(matches!(
            store.apply_patch_using(
                &patch,
                PatchServices {
                    verifier: &ExternalPass,
                    allocation: &MustNotCopy,
                },
            ),
            Err(ImageError::InvalidImage(VmError::LengthLimit))
        ));
        assert_eq!(store.snapshot().expect("active image").image_version(), 1);
    }

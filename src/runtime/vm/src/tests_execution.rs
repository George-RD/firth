    #[test]
    fn call_word_uses_the_callers_operand_stack() {
        let main = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(1)))),
                instruction(Op::CallWord, Some(Operand::Word(String::from("drop_one")))),
            ],
        );
        let callee = word("drop_one", vec![instruction(Op::Drop, None)]);
        assert_eq!(execute(&test_image(vec![main, callee])), Ok(vec![]));
    }

    #[test]
    fn kernel_execution_accepts_many_dup_and_quotations() {
        let dup = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(1)))),
                instruction(Op::Dup, None),
            ],
        );
        assert_eq!(
            execute(&test_image(vec![dup])),
            Ok(vec![Value::Int(1), Value::Int(1)])
        );

        let capture = word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::Int(1)],
                    consumed: vec![false],
                })),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![capture])),
            Ok(vec![Value::Quotation(Quotation {
                code: vec![],
                captures: vec![Value::Int(1)],
                consumed: vec![false]
            })])
        );

        let nested = word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![instruction(
                        Op::PushQuote,
                        Some(Operand::Quote(Quotation {
                            code: vec![],
                            captures: vec![Value::Int(2)],
                            consumed: vec![false],
                        })),
                    )],
                    captures: vec![],
                    consumed: vec![],
                })),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![nested])),
            Ok(vec![Value::Quotation(Quotation {
                code: vec![instruction(
                    Op::PushQuote,
                    Some(Operand::Quote(Quotation {
                        code: vec![],
                        captures: vec![Value::Int(2)],
                        consumed: vec![false]
                    }))
                )],
                captures: vec![],
                consumed: vec![]
            })])
        );

        let mut invalid_length = test_image(vec![word("main", vec![])]);
        invalid_length.words[0].kernel_evidence_digest.pop();
        assert_eq!(execute(&invalid_length), Err(VmError::InvalidDigestLength));

        let literal_capture = word(
            "main",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Quotation(Quotation {
                    code: vec![],
                    captures: vec![Value::Int(3)],
                    consumed: vec![false],
                }))),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![literal_capture])),
            Err(VmError::InvalidLiteralEncoding)
        );

        let malformed_capture = word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::Int(4)],
                    consumed: vec![],
                })),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![malformed_capture])),
            Err(VmError::InvalidCaptureBitmap)
        );
    }

    #[test]
    fn nested_word_and_quotation_calls_share_stack_and_fuel() {
        let main = word(
            "main",
            vec![
                instruction(Op::CallWord, Some(Operand::Word(String::from("outer")))),
                instruction(
                    Op::PushQuote,
                    Some(Operand::Quote(Quotation {
                        code: vec![instruction(
                            Op::PushLiteral,
                            Some(Operand::Literal(Value::Int(9))),
                        )],
                        captures: vec![],
                        consumed: vec![],
                    })),
                ),
                instruction(Op::Call, None),
            ],
        );
        let outer = word(
            "outer",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("inner"))),
            )],
        );
        let inner = word(
            "inner",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Int(7))),
            )],
        );
        let image = test_image(vec![main, outer, inner]);
        assert_eq!(
            execute_with_fuel(&image, 6),
            Ok(vec![Value::Int(7), Value::Int(9)])
        );
        assert_eq!(execute_with_fuel(&image, 5), Err(VmError::FuelExhausted));
    }

    #[test]
    fn recursive_calls_exhaust_one_shared_fuel_counter() {
        let main = word(
            "main",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("loop"))),
            )],
        );
        let loop_word = word(
            "loop",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("loop"))),
            )],
        );
        assert_eq!(
            execute_with_fuel(&test_image(vec![main, loop_word]), 4),
            Err(VmError::FuelExhausted)
        );
    }

    #[test]
    fn canonical_word_type_parser_accepts_and_rejects_structural_forms() {
        for valid in [
            "(--)",
            "(forallρ;ρ--ρ)",
            "(forallρ,σ;ρ--σ)",
            "(forallρ;ρ--ρ,x:Int^many)",
            "(forallρ;ρ--ρ,x:Bytes^linear)",
            "(forallρ;ρ--q:[ρ--ρ]^many)",
            "(forallρ,σ;ρ--q:[ρ--x:[ρ--σ]^linear]^many)",
        ] {
            assert!(is_canonical_word_type(valid), "{valid}");
        }
        for invalid in [
            "--",
            "(ρ--ρ)",
            "(forallρ;ρ--σ)",
            "(forallρ;ρ--ρ,x:Int^bogus)",
            "(forallρσ;ρ--σ)",
            "(forallrow;row--row)",
            "(forallx:Int--)",
            "(forallρ; ρ--ρ)",
            "(forall\u{00a0};--)",
            "(forallρ;ρ-ρ)",
            "(forallρ;ρ--q:[ρ-ρ]^many)",
            "(forallρ;ρ--q:[ρ--ρ]^bogus)",
            "(forallρ;ρ--q:[ρ--ρ]^many{positive q})",
            "(forallρ;ρ--q:[ρ--ρ]^manytail)",
            "(forallρ;ρ--q:[ρ--ρ]^many)trailing",
            "(forallρ;ρ--q:[ρ--ρ]^many,)",
        ] {
            assert!(!is_canonical_word_type(invalid), "{invalid}");
        }
    }

    #[test]
    fn canonical_identifiers_have_ascii_boundaries() {
        for valid in [b"a".as_slice(), b"A9".as_slice(), b"_name".as_slice()] {
            assert!(is_canonical_identifier(valid));
        }
        for invalid in [
            b"".as_slice(),
            b"9name".as_slice(),
            b"name-name".as_slice(),
            "é".as_bytes(),
        ] {
            assert!(!is_canonical_identifier(invalid));
        }
    }

    #[test]
    fn quotation_word_type_nesting_is_bounded() {
        let mut value = String::from("Int");
        for _ in 0..MAX_WORD_TYPE_NESTING {
            value = alloc::format!("[ρ--q:{value}]^many");
        }
        assert!(is_canonical_word_type(&alloc::format!(
            "(forallρ;ρ--q:{value})"
        )));
        value = alloc::format!("[ρ--q:{value}]^many");
        assert!(!is_canonical_word_type(&alloc::format!(
            "(forallρ;ρ--q:{value})"
        )));
    }

    #[test]
    fn image_and_call_word_identifiers_are_validated() {
        for (word_name, call_name) in [
            ("", "callee"),
            ("9main", "callee"),
            ("é", "callee"),
            ("main", ""),
            ("main", "9callee"),
            ("main", "é"),
        ] {
            assert_eq!(
                decode(&encoded_call_image(word_name, call_name)),
                Err(VmError::InvalidIdentifier)
            );
        }
        assert!(decode(&encoded_call_image("_main", "callee")).is_ok());
    }

    #[test]
    fn row_names_follow_target_scalar_grammar() {
        for valid in [
            "(forallρ;ρ--ρ)",
            "(forall1;1--1)",
            "(forall!;!--!)",
            "(forall@;@--@)",
            "(forall😀;😀--😀)",
        ] {
            assert!(is_canonical_word_type(valid), "{valid}");
        }
        for invalid in [
            "(forall;--)",
            "(forall;ρ--ρ)",
            "(forall12;12--12)",
            "(forall ;--)",
            "(forall\u{2003};--)",
        ] {
            assert!(!is_canonical_word_type(invalid), "{invalid}");
        }
    }

    #[test]
    fn bootstrap_rejects_zero_or_mismatched_digests() {
        let mut bytes = smoke_image();
        let digest_start = bytes.len() - (DIGEST_BYTES * 3 + 1);
        bytes[digest_start] ^= 1;
        assert_eq!(decode(&bytes), Err(VmError::InvalidDigest));

        let mut bytes = smoke_image();
        let evidence_start = bytes.len() - (DIGEST_BYTES * 2 + 1);
        bytes[evidence_start..evidence_start + DIGEST_BYTES].fill(0);
        assert_eq!(decode(&bytes), Err(VmError::InvalidDigest));
    }

    #[test]
    fn sha256_matches_known_empty_vector() {
        assert_eq!(
            sha256(&[]),
            [
                0xe3, 0xb0, 0xc4, 0x42, 0x98, 0xfc, 0x1c, 0x14, 0x9a, 0xfb, 0xf4, 0xc8, 0x99, 0x6f,
                0xb9, 0x24, 0x27, 0xae, 0x41, 0xe4, 0x64, 0x9b, 0x93, 0x4c, 0xa4, 0x95, 0x99, 0x1b,
                0x78, 0x52, 0xb8, 0x55,
            ]
        );
    }

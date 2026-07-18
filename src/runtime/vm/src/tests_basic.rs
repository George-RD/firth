    #[test]
    fn smoke_program_decodes_and_executes_canonical_main() {
        let image = decode(&smoke_image()).expect("valid canonical image");
        assert_eq!(execute(&image), Ok(vec![Value::Int(42)]));
        assert_eq!(image.image_version, 1);
        assert_eq!(image.words[0].name, "main");
    }

    #[test]
    fn invalid_utf8_word_name_is_rejected() {
        let mut bytes = smoke_image();
        bytes[8] = 0xff;
        assert_eq!(decode(&bytes), Err(VmError::InvalidUtf8));
    }

    #[test]
    fn canonical_operands_and_metadata_are_preserved() {
        let mut code = Vec::new();
        put_unsigned(&mut code, 12);
        code.extend([0, 0]);
        put_unsigned(&mut code, (i64::MAX as u64) << 1);
        code.push(1);
        put_unsigned(&mut code, 1);
        code.extend([2, 0]);
        put_unsigned(&mut code, 1);
        code.push(1);
        code.push(0);
        put_unsigned(&mut code, 7 << 1);
        code.extend([11, 5]);
        code.extend(b"other");
        code.extend([12, 1, b'p']);
        code.extend([3, 4, 5, 6, 7, 8, 9, 10]);
        let mut bytes = Vec::new();
        put_unsigned(&mut bytes, 1);
        put_unsigned(&mut bytes, u64::MAX);
        put_unsigned(&mut bytes, GAMMA_VERSION);
        put_unsigned(&mut bytes, 2);
        put_string(&mut bytes, "main");
        put_string(&mut bytes, "(--)");
        bytes.extend(code);
        bytes.extend(sha256(&canonical_code(&[
            Instruction {
                op: Op::PushLiteral,
                operand: Some(Operand::Literal(Value::Int(i64::MAX))),
            },
            Instruction {
                op: Op::PushQuote,
                operand: Some(Operand::Quote(Quotation {
                    code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                    captures: vec![Value::Int(7)],
                    consumed: vec![true],
                })),
            },
            Instruction {
                op: Op::CallWord,
                operand: Some(Operand::Word(String::from("other"))),
            },
            Instruction {
                op: Op::Prim,
                operand: Some(Operand::Primitive(String::from("p"))),
            },
            instruction(Op::Dup, None),
            instruction(Op::Drop, None),
            instruction(Op::Swap, None),
            instruction(Op::Call, None),
            instruction(Op::Dip, None),
            instruction(Op::Compose, None),
            instruction(Op::Quote, None),
            instruction(Op::If, None),
        ])));
        bytes.extend(sha256(&[]));
        bytes.extend(sha256(&[1]));
        put_unsigned(&mut bytes, u64::MAX);
        put_string(&mut bytes, "other");
        put_string(&mut bytes, "(--)");
        put_unsigned(&mut bytes, 0);
        bytes.extend(sha256(&canonical_code(&[])));
        bytes.extend(sha256(&[]));
        bytes.extend(sha256(&[1]));
        put_unsigned(&mut bytes, 9);
        let first_code = vec![
            instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Int(i64::MAX))),
            ),
            instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                    captures: vec![Value::Int(7)],
                    consumed: vec![true],
                })),
            ),
            instruction(Op::CallWord, Some(Operand::Word(String::from("other")))),
            instruction(Op::Prim, Some(Operand::Primitive(String::from("p")))),
            instruction(Op::Dup, None),
            instruction(Op::Drop, None),
            instruction(Op::Swap, None),
            instruction(Op::Call, None),
            instruction(Op::Dip, None),
            instruction(Op::Compose, None),
            instruction(Op::Quote, None),
            instruction(Op::If, None),
        ];
        let first = WordEntry {
            name: String::from("main"),
            erased_word_type: String::from("(--)"),
            code: first_code.clone(),
            body_digest: sha256(&canonical_code(&first_code)).to_vec(),
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[1]).to_vec(),
            generation: u64::MAX,
        };
        let second = WordEntry {
            name: String::from("other"),
            erased_word_type: String::from("(--)"),
            code: vec![],
            body_digest: sha256(&canonical_code(&[])).to_vec(),
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[1]).to_vec(),
            generation: 9,
        };
        let dictionary_digest = sha256(&canonical_dictionary(&[first, second]));
        bytes.extend(dictionary_digest);
        bytes.extend(sha256(&canonical_image_identity(
            1,
            u64::MAX,
            GAMMA_VERSION,
            &dictionary_digest,
        )));

        let image = decode(&bytes).expect("canonical operands decode");
        assert_eq!(image.image_version, u64::MAX);
        assert_eq!(image.words[0].generation, u64::MAX);
        assert_eq!(
            image.words[0].body_digest,
            sha256(&canonical_code(&image.words[0].code))
        );
        assert_eq!(image.words[1].name, "other");
        assert_eq!(
            image.words[0].code[0].operand,
            Some(Operand::Literal(Value::Int(i64::MAX)))
        );
        assert_eq!(
            image.words[0].code[2].operand,
            Some(Operand::Word(String::from("other")))
        );
        assert_eq!(
            image.words[0].code[3].operand,
            Some(Operand::Primitive(String::from("p")))
        );
        assert_eq!(
            image.words[0].code[4..]
                .iter()
                .map(|instruction| instruction.op)
                .collect::<Vec<_>>(),
            vec![
                Op::Dup,
                Op::Drop,
                Op::Swap,
                Op::Call,
                Op::Dip,
                Op::Compose,
                Op::Quote,
                Op::If
            ]
        );
        match &image.words[0].code[1].operand {
            Some(Operand::Quote(quote)) => {
                assert_eq!(quote.code[0].operand, Some(Operand::Capture(0)));
                assert_eq!(quote.captures, vec![Value::Int(7)]);
                assert_eq!(quote.consumed, vec![true]);
            }
            other => panic!("unexpected quote operand: {other:?}"),
        }
    }

    #[test]
    fn input_instruction_nesting_and_size_limits_are_bounded() {
        let mut too_large = vec![0; MAX_BYTES + 1];
        too_large[0] = 1;
        assert_eq!(decode(&too_large), Err(VmError::InputTooLarge));

        let mut overlong = Vec::new();
        put_unsigned(&mut overlong, 1);
        put_unsigned(&mut overlong, 1);
        put_unsigned(&mut overlong, GAMMA_VERSION);
        put_unsigned(&mut overlong, MAX_INSTRUCTIONS + 1);
        assert_eq!(decode(&overlong), Err(VmError::InstructionLimit));

        let mut nested = vec![1, 3];
        for _ in 0..=MAX_NESTING {
            let mut wrapped = vec![1, 1];
            wrapped.extend(nested);
            wrapped.push(0);
            nested = wrapped;
        }
        let mut image = Vec::new();
        put_unsigned(&mut image, 1);
        put_unsigned(&mut image, 1);
        put_unsigned(&mut image, GAMMA_VERSION);
        put_unsigned(&mut image, 1);
        put_string(&mut image, "main");
        put_string(&mut image, "(--)");
        image.extend(nested);
        image.extend([0; DIGEST_BYTES * 3]);
        image.push(0);
        assert_eq!(decode(&image), Err(VmError::NestingLimit));
    }

    #[test]
    fn malformed_header_and_trailing_bytes_are_rejected() {
        let mut bytes = smoke_image();
        bytes[0] = 2;
        assert_eq!(decode(&bytes), Err(VmError::UnsupportedFormat(2)));
        let mut bytes = smoke_image();
        bytes.push(0);
        assert_eq!(decode(&bytes), Err(VmError::TrailingBytes));
    }

    #[test]
    fn signed_integer_boundaries_round_trip() {
        for value in [i64::MIN, -1, 0, 1, i64::MAX] {
            let mut encoded = Vec::new();
            encoded.push(0);
            put_unsigned(&mut encoded, ((value as u64) << 1) ^ ((value >> 63) as u64));
            let mut reader = Reader::new(&encoded);
            assert_eq!(decode_value(&mut reader, 0), Ok(Value::Int(value)));
        }
    }

    fn instruction(op: Op, operand: Option<Operand>) -> Instruction {
        Instruction { op, operand }
    }

    fn word(name: &str, code: Vec<Instruction>) -> WordEntry {
        WordEntry {
            name: String::from(name),
            erased_word_type: String::from("(--)"),
            body_digest: sha256(&canonical_code(&code)).to_vec(),
            code,
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[]).to_vec(),
            generation: 0,
        }
    }

    fn test_image(words: Vec<WordEntry>) -> Image {
        let mut words = words;
        words.sort_by(|left, right| left.name.as_bytes().cmp(right.name.as_bytes()));
        let dictionary_digest = sha256(&canonical_dictionary(&words)).to_vec();
        Image {
            format_version: FORMAT_VERSION,
            image_version: 1,
            gamma_version: GAMMA_VERSION,
            image_digest: sha256(&canonical_image_identity(
                FORMAT_VERSION,
                1,
                GAMMA_VERSION,
                &dictionary_digest,
            ))
            .to_vec(),
            dictionary_digest,
            words,
        }
    }

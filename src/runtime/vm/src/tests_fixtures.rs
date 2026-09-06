    #[test]
    fn fuel_precedes_instruction_validation() {
        let image = test_image(vec![word("main", vec![instruction(Op::Drop, None)])]);
        let ExecutionOutcome::Trap(trap) = execute_diagnostic(&image, 0, &default_registry())
        else {
            panic!("expected fuel trap")
        };
        assert_eq!(trap.error, VmError::FuelExhausted);
        assert_eq!(trap.location.as_ref().map(|location| location.pc), Some(0));
        assert_eq!(trap.cost.total, 0);
        assert_eq!(trap.trace.len(), 0);

        let ExecutionOutcome::Trap(trap) = execute_diagnostic(&image, 1, &default_registry())
        else {
            panic!("expected validation trap")
        };
        assert_eq!(trap.error, VmError::StackFault);
        assert_eq!(trap.location.as_ref().map(|location| location.pc), Some(0));
        assert_eq!(trap.cost.total, 0);
        assert!(trap.trace.is_empty());
    }

    #[test]
    fn lean_reference_fixture_vectors_agree_through_the_conformance_boundary() {
        let fixture = include_str!("../fixtures/kernel.tsv");
        let registry = default_registry();
        let mut rows = 0;
        for line in fixture
            .lines()
            .filter(|line| !line.is_empty() && !line.starts_with('#'))
        {
            let case = decode_fixture_line(line).expect("valid fixture row");
            let reference = fixture_reference(&case).expect("frozen outcome vocabulary");
            let observed = observe_image(
                &case.image,
                case.initial_stack.clone(),
                64,
                &registry,
            );
            assert_eq!(
                compare_conformance(&reference, &observed),
                ConformanceVerdict::Agree,
                "{}",
                case.name
            );
            rows += 1;
        }
        assert_eq!(rows, 15, "the frozen corpus lost or gained a row");
    }

    fn encoded_call_image(word_name: &str, call_name: &str) -> Vec<u8> {
        let mut bytes = Vec::new();
        put_unsigned(&mut bytes, u64::from(FORMAT_VERSION));
        put_unsigned(&mut bytes, 1);
        put_unsigned(&mut bytes, GAMMA_VERSION);
        put_unsigned(&mut bytes, 1);
        put_string(&mut bytes, word_name);
        put_string(&mut bytes, "(--)");
        put_unsigned(&mut bytes, 1);
        bytes.push(11);
        put_string(&mut bytes, call_name);
        bytes.extend(sha256(&canonical_code(&[instruction(
            Op::CallWord,
            Some(Operand::Word(String::from(call_name))),
        )])));
        bytes.extend(sha256(&[]));
        bytes.extend(sha256(&[1]));
        put_unsigned(&mut bytes, 0);
        let word = WordEntry {
            name: String::from(word_name),
            erased_word_type: String::from("(--)"),
            code: vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from(call_name))),
            )],
            body_digest: sha256(&canonical_code(&[instruction(
                Op::CallWord,
                Some(Operand::Word(String::from(call_name))),
            )]))
            .to_vec(),
            kernel_evidence_digest: sha256(&[]).to_vec(),
            refinement_evidence_digest: sha256(&[1]).to_vec(),
            generation: 0,
        };
        let dictionary_digest = sha256(&canonical_dictionary(&[word]));
        bytes.extend(dictionary_digest);
        bytes.extend(sha256(&canonical_image_identity(
            FORMAT_VERSION,
            1,
            GAMMA_VERSION,
            &dictionary_digest,
        )));
        bytes
    }

    #[test]
    fn push_literal_rejects_quotation_and_primitive_values() {
        let image = test_image(vec![word(
            "main",
            vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Quotation(Quotation {
                    code: vec![],
                    captures: vec![],
                    consumed: vec![],
                }))),
            )],
        )]);
        assert_eq!(execute(&image), Err(VmError::InvalidLiteralEncoding));

        let mut bytes = smoke_image();
        let literal_tag = bytes
            .iter()
            .position(|byte| *byte == 0)
            .expect("literal opcode");
        bytes[literal_tag + 1] = 4;
        assert_eq!(decode(&bytes), Err(VmError::InvalidLiteralEncoding));
    }

    #[test]
    fn malformed_and_noncanonical_encodings_are_rejected() {
        let mut bytes = smoke_image();
        let type_start = bytes
            .windows(4)
            .position(|window| window == b"(--)")
            .expect("type");
        bytes[type_start + 3] = b' ';
        assert_eq!(decode(&bytes), Err(VmError::InvalidWordType));

        let mut bytes = smoke_image();
        let literal = bytes
            .iter()
            .position(|byte| *byte == 0)
            .expect("literal opcode");
        bytes.splice(literal + 2..literal + 3, [0x80, 0x00]);
        assert_eq!(decode(&bytes), Err(VmError::NonCanonicalLeb128));
    }

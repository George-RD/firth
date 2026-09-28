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
        // The frozen corpus is unchanged. Fourteen rows fix their stacks and
        // frames completely and must agree exactly. Row `quote` states its
        // result only as `quotation-many`, a usage projection that fixes no
        // body or capture, so the comparison is unsupported: asserting
        // agreement on it would be exactly the false agreement being closed.
        let fixture = include_str!("../fixtures/kernel.tsv");
        let registry = default_registry();
        let mut rows = 0;
        let mut unsupported_rows = Vec::new();
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
            let verdict = compare_conformance(&reference, &observed);
            if case.name == "quote" {
                let ConformanceVerdict::UnsupportedComparison(unsupported) = &verdict else {
                    panic!("row quote must be unsupported, not {verdict:?}");
                };
                assert_eq!(unsupported.len(), 1);
                assert_eq!(unsupported[0].field, "stack");
                assert_eq!(unsupported[0].reference, "quotation-many");
                assert!(unsupported[0].target.starts_with("quotation:many:"));
                assert!(!verdict.is_agreement());
                unsupported_rows.push(case.name.clone());
            } else {
                assert_eq!(verdict, ConformanceVerdict::Agree, "{}", case.name);
            }
            rows += 1;
        }
        assert_eq!(rows, 19, "the frozen corpus lost or gained a row");
        assert_eq!(unsupported_rows, vec![String::from("quote")]);
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
    fn push_literal_accepts_only_scalars_and_canonical_sequences() {
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
        bytes[literal_tag + 1] = 3;
        assert_eq!(decode(&bytes), Err(VmError::InvalidLiteralEncoding));

        // Of the primitive values only sequences, in their canonical
        // encoding, are literals.
        for (tag, bytes, accepted) in [
            (SEQ_INT_TAG, 7_i64.to_le_bytes().to_vec(), true),
            (SEQ_BOOL_TAG, vec![0, 1], true),
            (SEQ_INT_TAG, (-1_i64).to_le_bytes().to_vec(), true),
            (SEQ_INT_TAG, vec![7], false),
            (SEQ_BOOL_TAG, vec![2], false),
            (99, vec![], false),
        ] {
            let image = test_image(vec![word(
                "main",
                vec![instruction(
                    Op::PushLiteral,
                    Some(Operand::Literal(Value::PrimitiveValue { tag, bytes })),
                )],
            )]);
            let result = execute(&image);
            if accepted {
                assert!(result.is_ok(), "{tag}: {result:?}");
            } else {
                assert_eq!(result, Err(VmError::InvalidLiteralEncoding), "{tag}");
            }
        }
    }

    fn run_sequence_primitive(tag: u64, bytes: Vec<u8>, operand: Value, name: &str) -> Result<Vec<Value>, VmError> {
        execute(&test_image(vec![word(
            "main",
            vec![
                instruction(
                    Op::PushLiteral,
                    Some(Operand::Literal(Value::PrimitiveValue { tag, bytes })),
                ),
                instruction(Op::PushLiteral, Some(Operand::Literal(operand))),
                instruction(Op::Prim, Some(Operand::Primitive(String::from(name)))),
            ],
        )]))
    }

    #[test]
    fn sequence_indexes_past_the_end_fault_at_every_magnitude() {
        let ints: Vec<u8> = [7_i64, 8, 9].iter().flat_map(|v| v.to_le_bytes()).collect();
        assert_eq!(
            run_sequence_primitive(SEQ_INT_TAG, ints.clone(), Value::Int(2), "intSeqAt"),
            Ok(vec![Value::Int(9)])
        );
        // 2^61 - 1 is the largest index whose byte offset fits a usize but
        // whose end does not; it once overflowed and panicked.
        for index in [3, (1_i64 << 61) - 1, 1_i64 << 61, i64::MAX, -1] {
            assert_eq!(
                run_sequence_primitive(SEQ_INT_TAG, ints.clone(), Value::Int(index), "intSeqAt"),
                Err(VmError::PrimitiveFault),
                "Seq Int at {index}"
            );
            assert_eq!(
                run_sequence_primitive(SEQ_BOOL_TAG, vec![1, 0], Value::Int(index), "boolSeqAt"),
                Err(VmError::PrimitiveFault),
                "Seq Bool at {index}"
            );
        }
    }

    #[test]
    fn negative_integers_push_onto_and_read_back_from_a_sequence() {
        let pushed = run_sequence_primitive(SEQ_INT_TAG, vec![], Value::Int(i64::MIN), "intSeqPush")
            .expect("push a negative element");
        let [Value::PrimitiveValue { tag, bytes }] = pushed.as_slice() else {
            panic!("push leaves one sequence: {pushed:?}")
        };
        assert_eq!(
            run_sequence_primitive(*tag, bytes.clone(), Value::Int(0), "intSeqAt"),
            Ok(vec![Value::Int(i64::MIN)])
        );
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

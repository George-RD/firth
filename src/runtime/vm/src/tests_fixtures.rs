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
    fn lean_reference_fixture_vectors_execute_in_rust() {
        let fixture = include_str!("../fixtures/kernel.tsv");
        for line in fixture
            .lines()
            .filter(|line| !line.is_empty() && !line.starts_with('#'))
        {
            let fixture = decode_fixture_line(line).expect("valid fixture row");
            let expected_outcome = fixture.outcome.as_str();
            let (stack, cost, frames) = match expected_outcome {
                "terminal" => {
                    let report = execute_report_with_stack(
                        &fixture.image,
                        fixture.initial_stack.clone(),
                        64,
                        &default_registry(),
                    )
                    .expect(&fixture.name);
                    (report.stack, report.cost, report.frames)
                }
                "stuck" => {
                    let ExecutionOutcome::Trap(trap) = execute_diagnostic_with_stack(
                        &fixture.image,
                        fixture.initial_stack,
                        64,
                        &default_registry(),
                    ) else {
                        panic!("expected trap: {}", fixture.name)
                    };
                    assert_eq!(trap.code, "stack-fault", "{}", fixture.name);
                    (trap.stack, trap.cost, trap.frames)
                }
                other => panic!("unsupported fixture outcome {other}: {}", fixture.name),
            };
            assert_eq!(
                render_fixture_stack(&stack),
                fixture.final_stack,
                "{}",
                fixture.name
            );
            assert_eq!(
                cost.total.saturating_sub(cost.word_entries),
                fixture.lean_cost,
                "Lean cost: {}",
                fixture.name
            );
            assert_eq!(
                render_fixture_frames(&frames),
                fixture.residual_frames,
                "{}",
                fixture.name
            );
            assert_eq!(
                cost.total, fixture.target_cost,
                "target cost: {}",
                fixture.name
            );
        }
    }

    fn render_fixture_stack(stack: &[Value]) -> String {
        stack
            .iter()
            .map(|value| match value {
                Value::Int(value) => value.to_string(),
                Value::Bool(value) => value.to_string(),
                Value::Quotation(quotation) => {
                    if quotation.usage(&default_registry()) == Usage::Many {
                        String::from("quotation-many")
                    } else {
                        String::from("quotation-linear")
                    }
                }
                Value::Bytes(_) => String::from("bytes"),
                Value::PrimitiveValue { .. } => String::from("primitive"),
                Value::World => String::from("world"),
            })
            .collect::<Vec<_>>()
            .join(",")
    }

    fn render_fixture_frames(frames: &[FrameTrace]) -> String {
        if frames.is_empty() {
            return String::from("-");
        }
        frames
            .iter()
            .map(|frame| format!("{}@{}", frame.word, frame.pc))
            .collect::<Vec<_>>()
            .join(";")
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

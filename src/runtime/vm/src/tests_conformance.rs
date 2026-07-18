    #[test]
    fn every_kernel_control_rule_and_default_primitive_has_a_witness() {
        let quote = |value| {
            instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![instruction(
                        Op::PushLiteral,
                        Some(Operand::Literal(Value::Int(value))),
                    )],
                    captures: vec![],
                    consumed: vec![],
                })),
            )
        };
        let compose = word(
            "main",
            vec![
                quote(1),
                quote(2),
                instruction(Op::Compose, None),
                instruction(Op::Call, None),
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(9)))),
                instruction(Op::Swap, None),
                instruction(Op::Drop, None),
            ],
        );
        assert_eq!(
            execute(&test_image(vec![compose])),
            Ok(vec![Value::Int(1), Value::Int(9)])
        );

        let dip = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(1)))),
                quote(2),
                instruction(Op::Dip, None),
            ],
        );
        assert_eq!(
            execute(&test_image(vec![dip])),
            Ok(vec![Value::Int(2), Value::Int(1)])
        );

        let conditional = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Bool(true)))),
                quote(3),
                quote(4),
                instruction(Op::If, None),
            ],
        );
        assert_eq!(
            execute(&test_image(vec![conditional])),
            Ok(vec![Value::Int(3)])
        );

        let primitives = word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(2)))),
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(40)))),
                instruction(Op::Prim, Some(Operand::Primitive(String::from("addNat")))),
                instruction(
                    Op::Prim,
                    Some(Operand::Primitive(String::from("makeWorld"))),
                ),
                instruction(
                    Op::Prim,
                    Some(Operand::Primitive(String::from("consumeWorld"))),
                ),
            ],
        );
        let report = execute_report(&test_image(vec![primitives]), 10).expect("primitive witness");
        assert_eq!(report.stack, vec![Value::Int(42)]);
        assert_eq!(report.cost.primitives, 3);
        assert_eq!(report.cost.total, 5);

        let linear = word(
            "main",
            vec![
                instruction(
                    Op::PushQuote,
                    Some(Operand::Quote(Quotation {
                        code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                        captures: vec![Value::PrimitiveValue {
                            tag: 1,
                            bytes: vec![],
                        }],
                        consumed: vec![false],
                    })),
                ),
                instruction(Op::Call, None),
                instruction(Op::Dup, None),
            ],
        );
        assert_eq!(
            execute(&test_image(vec![linear])),
            Err(VmError::ResourceFault)
        );
    }

    #[test]
    fn primitive_registry_and_fuel_errors_are_stable() {
        let unknown = word(
            "main",
            vec![instruction(
                Op::Prim,
                Some(Operand::Primitive(String::from("missing"))),
            )],
        );
        assert_eq!(
            execute(&test_image(vec![unknown])),
            Err(VmError::UnknownPrimitive(String::from("missing")))
        );
        let infinite = word(
            "main",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("main"))),
            )],
        );
        assert_eq!(
            execute_with_fuel(&test_image(vec![infinite]), 2),
            Err(VmError::FuelExhausted)
        );

        let mut registry = default_registry();
        registry.version = GAMMA_VERSION + 1;
        assert_eq!(
            execute_report_with_registry(&test_image(vec![word("main", vec![])]), 1, &registry),
            Err(VmError::UnsupportedGamma(GAMMA_VERSION + 1))
        );
    }

    #[test]
    fn usage_is_encoded_by_registry_and_linear_residue_is_not_terminal() {
        let linear = Value::PrimitiveValue {
            tag: 1,
            bytes: vec![],
        };
        for op in [Op::Dup, Op::Drop] {
            let image = test_image(vec![word(
                "main",
                vec![
                    instruction(
                        Op::PushQuote,
                        Some(Operand::Quote(Quotation {
                            code: vec![instruction(Op::PushCapture, Some(Operand::Capture(0)))],
                            captures: vec![linear.clone()],
                            consumed: vec![false],
                        })),
                    ),
                    instruction(Op::Call, None),
                    instruction(op, None),
                ],
            )]);
            assert_eq!(execute(&image), Err(VmError::ResourceFault));
        }
        let residue = test_image(vec![word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![linear],
                    consumed: vec![false],
                })),
            )],
        )]);
        assert_eq!(execute(&residue), Err(VmError::ResourceFault));
    }

    #[test]
    fn if_requires_many_branches_even_when_the_linear_one_is_not_selected() {
        let linear_quote = || {
            instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::PrimitiveValue {
                        tag: 1,
                        bytes: vec![],
                    }],
                    consumed: vec![false],
                })),
            )
        };
        let image = test_image(vec![word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Bool(true)))),
                linear_quote(),
                linear_quote(),
                instruction(Op::If, None),
            ],
        )]);
        assert_eq!(execute(&image), Err(VmError::ResourceFault));
    }

    #[test]
    fn diagnostic_outcome_contains_stable_location_trace_cost_and_world() {
        let image = test_image(vec![word(
            "main",
            vec![
                instruction(
                    Op::Prim,
                    Some(Operand::Primitive(String::from("makeWorld"))),
                ),
                instruction(
                    Op::Prim,
                    Some(Operand::Primitive(String::from("consumeWorld"))),
                ),
            ],
        )]);
        let complete = execute_diagnostic(&image, 2, &default_registry());
        let ExecutionOutcome::Complete(report) = complete else {
            panic!("expected completion")
        };
        assert_eq!(report.world.observation(), &[0, 0, 1]);
        assert_eq!(report.cost.steps.len(), 2);
        assert_eq!(report.trace.len(), 2);

        let trapped = execute_diagnostic(&image, 0, &default_registry());
        let ExecutionOutcome::Trap(trap) = trapped else {
            panic!("expected fuel trap")
        };
        assert_eq!(trap.code, "fuel-exhausted");
        assert_eq!(
            trap.location,
            Some(TrapLocation {
                word: String::from("main"),
                pc: 0,
                image_version: 1,
            })
        );

        let dip_image = test_image(vec![word(
            "main",
            vec![
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(4)))),
                instruction(
                    Op::PushQuote,
                    Some(Operand::Quote(Quotation {
                        code: vec![instruction(
                            Op::PushLiteral,
                            Some(Operand::Literal(Value::Int(5))),
                        )],
                        captures: vec![],
                        consumed: vec![],
                    })),
                ),
                instruction(Op::Dip, None),
            ],
        )]);
        let ExecutionOutcome::Trap(dip_trap) =
            execute_diagnostic(&dip_image, 3, &default_registry())
        else {
            panic!("expected nested fuel trap")
        };
        assert_eq!(dip_trap.code, "fuel-exhausted");
        assert_eq!(dip_trap.frames.len(), 2);
        assert_eq!(dip_trap.frames[0].continuation, Continuation::RestoreDip);
        assert_eq!(dip_trap.frames[0].saved, vec![Value::Int(4)]);
        assert_eq!(dip_trap.frames[1].continuation, Continuation::Return);
    }

    #[test]
    fn target_quotation_allocations_are_recoverable() {
        let quotation = Quotation {
            code: vec![instruction(
                Op::PushLiteral,
                Some(Operand::Literal(Value::Int(1))),
            )],
            captures: vec![],
            consumed: vec![],
        };
        let initial = vec![
            Value::Quotation(quotation.clone()),
            Value::Quotation(quotation),
        ];
        let image = test_image(vec![word("main", vec![instruction(Op::Compose, None)])]);
        let ExecutionOutcome::Trap(trap) = execute_diagnostic_with_stack_budget(
            &image,
            initial.clone(),
            64,
            &default_registry(),
            Some(1),
        ) else {
            panic!("expected mid-operation allocation trap")
        };
        assert_eq!(trap.error, VmError::AllocationFailure);
        assert_eq!(trap.stack, initial);
        assert_eq!(trap.world, WorldState::new());
        assert!(trap.trace.is_empty());
        assert_eq!(trap.cost.total, 0);
        assert_eq!(
            trap.location,
            Some(TrapLocation {
                word: String::from("main"),
                pc: 0,
                image_version: 1,
            })
        );
    }

    #[test]
    fn invalid_multiple_world_states_are_rejected_at_diagnostic_boundary() {
        let image = test_image(vec![word("main", vec![])]);
        let worlds = vec![Value::World, Value::World];
        let ExecutionOutcome::Trap(trap) =
            execute_diagnostic_with_stack(&image, worlds, 64, &default_registry())
        else {
            panic!("expected invalid world state trap")
        };
        assert_eq!(trap.error, VmError::WorldFault);

        let nested = Value::Quotation(Quotation {
            code: vec![],
            captures: vec![Value::World, Value::World],
            consumed: vec![false, false],
        });
        let ExecutionOutcome::Trap(trap) =
            execute_diagnostic_with_stack(&image, vec![nested], 64, &default_registry())
        else {
            panic!("expected nested invalid world state trap")
        };
        assert_eq!(trap.error, VmError::WorldFault);

        let encoded_image_world = fixture_image(vec![word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::World],
                    consumed: vec![false],
                })),
            )],
        )]);
        assert_eq!(
            decode(&encode_image(&encoded_image_world)),
            Err(VmError::WorldFault)
        );

        let nested_single = Value::Quotation(Quotation {
            code: vec![],
            captures: vec![Value::World],
            consumed: vec![false],
        });
        let ExecutionOutcome::Trap(trap) =
            execute_diagnostic_with_stack(&image, vec![nested_single], 64, &default_registry())
        else {
            panic!("expected nested single world trap")
        };
        assert_eq!(trap.error, VmError::WorldFault);

        let image_world = test_image(vec![word(
            "main",
            vec![instruction(
                Op::PushQuote,
                Some(Operand::Quote(Quotation {
                    code: vec![],
                    captures: vec![Value::World],
                    consumed: vec![false],
                })),
            )],
        )]);
        let ExecutionOutcome::Trap(trap) =
            execute_diagnostic(&image_world, 64, &default_registry())
        else {
            panic!("expected image world trap")
        };
        assert_eq!(trap.error, VmError::WorldFault);
    }

    #[test]
    fn in_flight_handles_keep_old_code_until_their_lookup_finishes() {
        let image = dictionary_image();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");
        let in_flight = store.lookup("value").expect("old lookup");

        store.apply_patch(&patch, &verifier).expect("patch");
        let later = store.lookup("value").expect("new lookup");

        assert_eq!(in_flight.image_version(), 1);
        assert_eq!(in_flight.entry().code, literal_code(1));
        assert_eq!(later.image_version(), 2);
        assert_eq!(later.entry().code, literal_code(2));
    }

    #[test]
    fn reclamation_waits_for_reader_quiescence() {
        let image = dictionary_image();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image).expect("valid store");
        let reader = store.snapshot().expect("reader snapshot");
        store.apply_patch(&patch, &verifier).expect("patch");

        assert_eq!(store.reclaim_through(2).expect("retained reader"), Vec::<u64>::new());
        assert_eq!(store.retired_versions().expect("retired"), vec![1]);

        drop(reader);
        assert_eq!(store.reclaim_through(1).expect("early epoch"), Vec::<u64>::new());
        assert_eq!(store.retired_versions().expect("retired"), vec![1]);
        assert_eq!(store.reclaim_through(2).expect("reclaim pass"), vec![1]);
        assert!(matches!(
            store.rollback(2, 1),
            Err(ImageError::RollbackUnavailable(1))
        ));
    }

    type PauseBarriers = (
        std::sync::Arc<std::sync::Barrier>,
        std::sync::Arc<std::sync::Barrier>,
    );

    static EXECUTION_PAUSE: std::sync::OnceLock<std::sync::Mutex<Option<PauseBarriers>>> =
        std::sync::OnceLock::new();
    static PAUSE_ONCE: core::sync::atomic::AtomicBool =
        core::sync::atomic::AtomicBool::new(true);

    fn pause_execution(_context: &mut PrimitiveContext<'_>) -> Result<(), VmError> {
        if !PAUSE_ONCE.swap(false, core::sync::atomic::Ordering::SeqCst) {
            return Ok(());
        }
        let barriers = EXECUTION_PAUSE
            .get_or_init(|| std::sync::Mutex::new(None))
            .lock()
            .expect("pause lock")
            .clone()
            .expect("configured pause");
        barriers.0.wait();
        barriers.1.wait();
        Ok(())
    }

    #[test]
    fn executing_calls_take_an_atomic_version_cut_per_word_entry() {
        use std::sync::{Arc, Barrier};
        use std::thread;

        let main = word(
            "main",
            vec![
                instruction(Op::CallWord, Some(Operand::Word(String::from("value")))),
                instruction(Op::CallWord, Some(Operand::Word(String::from("value")))),
            ],
        );
        let value = word(
            "value",
            vec![
                instruction(Op::Prim, Some(Operand::Primitive(String::from("pause")))),
                instruction(Op::PushLiteral, Some(Operand::Literal(Value::Int(1)))),
            ],
        );
        let image = test_image(vec![main, value]);
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = Arc::new(ImageStore::new(image).expect("valid store"));
        let entered = Arc::new(Barrier::new(2));
        let resume = Arc::new(Barrier::new(2));
        PAUSE_ONCE.store(true, core::sync::atomic::Ordering::SeqCst);
        *EXECUTION_PAUSE
            .get_or_init(|| std::sync::Mutex::new(None))
            .lock()
            .expect("pause lock") = Some((Arc::clone(&entered), Arc::clone(&resume)));
        let mut registry = default_registry();
        registry.definitions.push(PrimitiveDefinition {
            name: "pause",
            cost: 1,
            handler: pause_execution,
            input: &[],
            output: &[],
            world: false,
            value_tags: &[],
        });
        let executing_store = Arc::clone(&store);
        let execution = thread::spawn(move || {
            execute_active_report(&executing_store, DEFAULT_FUEL, &registry)
        });

        entered.wait();
        store.apply_patch(&patch, &verifier).expect("patch");
        resume.wait();
        let report = execution
            .join()
            .expect("execution thread")
            .expect("active execution");

        assert_eq!(report.stack, vec![Value::Int(1), Value::Int(2)]);
        assert!(report.trace.iter().any(|event| event.word == "value" && event.image_version == 1));
        assert!(report.trace.iter().any(|event| event.word == "value" && event.image_version == 2));
        *EXECUTION_PAUSE
            .get()
            .expect("pause state")
            .lock()
            .expect("pause lock") = None;
    }

    #[test]
    fn allocation_failure_rolls_back_before_publication() {
        let image = dictionary_image();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = ImageStore::new(image.clone()).expect("valid store");

        let error = store
            .apply_patch_using(
                &patch,
                PatchServices {
                    verifier: &verifier,
                    allocation: &FailingImageAllocation,
                },
            )
            .expect_err("injected allocation failure");

        assert_eq!(error, ImageError::AllocationFailure);
        assert_eq!(error.stable_code(), "resource-fault");
        assert_eq!(error.stable_subcode(), "allocation-failure");
        assert_eq!(store.snapshot().expect("active image").image(), &image);
        assert!(store.retired_versions().expect("retired").is_empty());
    }

    #[test]
    fn concurrent_readers_observe_only_complete_old_or_new_bindings() {
        use std::sync::{Arc, Barrier};
        use std::thread;

        let image = dictionary_image();
        let (patch, verifier) = patch_for(&image, "value", 2);
        let store = Arc::new(ImageStore::new(image).expect("valid store"));
        let barrier = Arc::new(Barrier::new(5));
        let mut readers = Vec::new();
        for _ in 0..4 {
            let store = Arc::clone(&store);
            let barrier = Arc::clone(&barrier);
            readers.push(thread::spawn(move || {
                barrier.wait();
                for _ in 0..512 {
                    let word = store.lookup("value").expect("atomic lookup");
                    assert!(word.entry().code == literal_code(1) || word.entry().code == literal_code(2));
                    assert_eq!(
                        word.entry().body_digest,
                        sha256(&canonical_code(&word.entry().code))
                    );
                }
            }));
        }

        barrier.wait();
        store.apply_patch(&patch, &verifier).expect("patch");
        for reader in readers {
            reader.join().expect("reader completes");
        }
        assert_eq!(store.lookup("value").expect("new word").entry().code, literal_code(2));
    }

    #[test]
    fn competing_patches_from_one_version_have_one_atomic_winner() {
        use std::sync::{Arc, Barrier};
        use std::thread;

        let image = dictionary_image();
        let (first, first_verifier) = patch_for(&image, "value", 2);
        let (second, second_verifier) = patch_for(&image, "value", 3);
        let store = Arc::new(ImageStore::new(image).expect("valid store"));
        let barrier = Arc::new(Barrier::new(3));
        let spawn_writer = |patch: WordPatch, verifier: ExactEvidence| {
            let store = Arc::clone(&store);
            let barrier = Arc::clone(&barrier);
            thread::spawn(move || {
                barrier.wait();
                store.apply_patch(&patch, &verifier)
            })
        };
        let left = spawn_writer(first, first_verifier);
        let right = spawn_writer(second, second_verifier);

        barrier.wait();
        let results = [left.join().expect("writer"), right.join().expect("writer")];

        assert_eq!(results.iter().filter(|result| result.is_ok()).count(), 1);
        assert_eq!(
            results
                .iter()
                .filter(|result| matches!(result, Err(ImageError::StaleImage { expected: 1, actual: 2 })))
                .count(),
            1
        );
        let winner = store.lookup("value").expect("winner");
        let code = &winner.entry().code;
        assert!(code == &literal_code(2) || code == &literal_code(3));
    }

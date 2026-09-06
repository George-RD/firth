//! End-to-end integration of the bootstrap decoder, the execution core, the
//! dictionary image, and the verified-patch protocol.
//!
//! Every step here goes through the crate's public contracts only: the frozen
//! wire format (`encode_image`/`decode`), the image store, the patch protocol,
//! and the conformance boundary. Nothing reaches into a private helper, so a
//! passing run is evidence that an embedder can drive the whole lifecycle.

use firth_vm::{
    ConformanceVerdict, ImageError, ImageStore, Instruction, Op, Operand, PatchEvidence,
    PatchVerifier, Value, WordEntry, WordPatch, body_digest, compare_conformance, decode,
    decode_fixture_line, default_registry, encode_image, evidence_digest, execute_active,
    execute_active_report, fixture_reference, observe_image, seal_image,
};

const CORPUS: &str = include_str!("../fixtures/kernel.tsv");

/// Accepts any patch. The real verifier lives outside the VM: `target-spec.md`
/// §6 hook 2 is discharged by Lean, and the VM only binds its verdict.
struct AcceptingVerifier;

impl PatchVerifier for AcceptingVerifier {
    fn verify(&self, _evidence: &PatchEvidence<'_>) -> bool {
        true
    }
}

/// Refuses every patch, standing in for an external check that failed.
struct RefusingVerifier;

impl PatchVerifier for RefusingVerifier {
    fn verify(&self, _evidence: &PatchEvidence<'_>) -> bool {
        false
    }
}

fn instruction(op: Op, operand: Option<Operand>) -> Instruction {
    Instruction { op, operand }
}

fn word(name: &str, code: Vec<Instruction>) -> WordEntry {
    WordEntry {
        name: String::from(name),
        erased_word_type: String::from("(--)"),
        body_digest: body_digest(&code),
        code,
        kernel_evidence_digest: evidence_digest(&[]),
        refinement_evidence_digest: evidence_digest(&[1]),
        generation: 0,
    }
}

fn value_word(literal: i64) -> WordEntry {
    word(
        "value",
        vec![instruction(
            Op::PushLiteral,
            Some(Operand::Literal(Value::Int(literal))),
        )],
    )
}

fn caller_image(literal: i64) -> Vec<WordEntry> {
    vec![
        word(
            "main",
            vec![instruction(
                Op::CallWord,
                Some(Operand::Word(String::from("value"))),
            )],
        ),
        value_word(literal),
    ]
}

fn redefinition(expected_image_version: u64, from: i64, to: i64) -> WordPatch {
    let old = value_word(from);
    let new = value_word(to);
    WordPatch {
        name: String::from("value"),
        expected_image_version,
        expected_body_digest: old.body_digest,
        erased_word_type: new.erased_word_type.clone(),
        body_digest: new.body_digest.clone(),
        code: new.code,
        kernel_evidence_digest: new.kernel_evidence_digest,
        refinement_evidence_digest: new.refinement_evidence_digest,
    }
}

fn corpus_row(name: &str) -> String {
    CORPUS
        .lines()
        .find(|line| line.starts_with(&format!("{name}|")))
        .unwrap_or_else(|| panic!("corpus row {name}"))
        .to_string()
}

/// Compares the store's active image with the frozen Lean reference row of the
/// same name through the differential conformance boundary.
fn assert_agrees_with_reference(store: &ImageStore, row: &str) {
    let case = decode_fixture_line(&corpus_row(row)).expect("valid corpus row");
    let reference = fixture_reference(&case).expect("frozen outcome vocabulary");
    let active = store.snapshot().expect("active snapshot");
    let observed = observe_image(active.image(), Vec::new(), 64, &default_registry());
    assert_eq!(
        compare_conformance(&reference, &observed),
        ConformanceVerdict::Agree,
        "{row}"
    );
}

#[test]
fn load_execute_redefine_verify_and_swap_runs_end_to_end() {
    // Load: seal a two-word image, put it on the wire, and decode it back.
    let sealed = seal_image(1, caller_image(1));
    let loaded = decode(&encode_image(&sealed)).expect("sealed image decodes");
    assert_eq!(loaded.image_version, 1);

    let store = ImageStore::new(loaded).expect("store accepts a valid image");

    // Execute: the call resolves through the active image.
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(1)]));
    assert_agrees_with_reference(&store, "dictionary-before-redefinition");

    // Redefine and verify: the external verifier accepts, so the VM validates
    // and publishes.
    let published = store
        .apply_patch(&redefinition(1, 1, 2), &AcceptingVerifier)
        .expect("an accepted patch publishes");
    assert_eq!(published.image_version(), 2);

    // Swap: exactly one binding changed, atomically, and the new definition is
    // what later calls resolve.
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(2)]));
    assert_agrees_with_reference(&store, "dictionary-after-redefinition");
    let active = store.snapshot().expect("active snapshot");
    assert_eq!(active.image().words.len(), 2);
    assert_eq!(
        active
            .lookup("main")
            .expect("main survives")
            .entry()
            .body_digest,
        sealed
            .words
            .iter()
            .find(|word| word.name == "main")
            .expect("main")
            .body_digest,
    );

    // The superseded snapshot is retained for rollback until it is reclaimed.
    assert_eq!(store.retired_versions(), Ok(vec![1]));
}

#[test]
fn a_refused_patch_leaves_the_prior_image_observable() {
    let store =
        ImageStore::new(decode(&encode_image(&seal_image(1, caller_image(1)))).expect("decodes"))
            .expect("store");

    assert_eq!(
        store
            .apply_patch(&redefinition(1, 1, 2), &RefusingVerifier)
            .err(),
        Some(ImageError::UnprovenPatch)
    );

    let active = store.snapshot().expect("active snapshot");
    assert_eq!(active.image_version(), 1);
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(1)]));
    assert_agrees_with_reference(&store, "dictionary-before-redefinition");
    assert_eq!(store.retired_versions(), Ok(Vec::new()));
}

#[test]
fn a_stale_patch_leaves_the_prior_image_observable() {
    let store =
        ImageStore::new(decode(&encode_image(&seal_image(1, caller_image(1)))).expect("decodes"))
            .expect("store");
    store
        .apply_patch(&redefinition(1, 1, 2), &AcceptingVerifier)
        .expect("first patch publishes");

    // The same patch replayed against the superseded version is stale.
    assert_eq!(
        store
            .apply_patch(&redefinition(1, 1, 2), &AcceptingVerifier)
            .err(),
        Some(ImageError::StaleImage {
            expected: 1,
            actual: 2
        })
    );
    assert_eq!(store.snapshot().expect("snapshot").image_version(), 2);
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(2)]));
}

#[test]
fn a_patch_whose_body_digest_does_not_bind_is_refused_before_publication() {
    let store =
        ImageStore::new(decode(&encode_image(&seal_image(1, caller_image(1)))).expect("decodes"))
            .expect("store");

    let mut patch = redefinition(1, 1, 2);
    patch.body_digest = evidence_digest(b"not the canonical body");
    assert_eq!(
        store.apply_patch(&patch, &AcceptingVerifier).err(),
        Some(ImageError::InvalidBodyDigest)
    );
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(1)]));
    assert_eq!(store.snapshot().expect("snapshot").image_version(), 1);
}

#[test]
fn rollback_republishes_the_prior_definition_under_a_fresh_version() {
    let store =
        ImageStore::new(decode(&encode_image(&seal_image(1, caller_image(1)))).expect("decodes"))
            .expect("store");
    store
        .apply_patch(&redefinition(1, 1, 2), &AcceptingVerifier)
        .expect("patch publishes");
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(2)]));

    let restored = store
        .rollback(2, 1)
        .expect("rollback republishes version 1");
    assert_eq!(restored.image_version(), 3);
    assert_eq!(execute_active(&store), Ok(vec![Value::Int(1)]));
    assert_agrees_with_reference(&store, "dictionary-before-redefinition");
}

#[test]
fn the_cost_report_of_a_word_call_charges_the_administrative_entry() {
    let store =
        ImageStore::new(decode(&encode_image(&seal_image(1, caller_image(1)))).expect("decodes"))
            .expect("store");
    let report = execute_active_report(&store, 64, &default_registry()).expect("terminal run");
    assert_eq!(report.stack, vec![Value::Int(1)]);
    // One `CALL_WORD`, one administrative entry, one `PUSH_LITERAL`: the Lean
    // reference charges two of those three, which is exactly the corpus row's
    // `lean_cost` of 2 against a `target_cost` of 3.
    assert_eq!(report.cost.total, 3);
    assert_eq!(report.cost.word_entries, 1);
    assert_eq!(report.cost.total - report.cost.word_entries, 2);
}

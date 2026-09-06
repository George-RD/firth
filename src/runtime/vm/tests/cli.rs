use std::process::Command;

const USAGE: &[u8] =
    b"usage: firth-vm --smoke | firth-vm run <image-path> [--fuel <n>] | firth-vm vm-run\n";

fn firth_vm(args: &[&str]) -> std::process::Output {
    Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .args(args)
        .output()
        .expect("CLI starts")
}

#[test]
fn smoke_cli_contract() {
    let output = firth_vm(&["--smoke"]);
    assert!(output.status.success());
    assert_eq!(output.stdout, b"42\n");
    assert!(output.stderr.is_empty());
}

#[test]
fn usage_cli_contract() {
    let output = firth_vm(&[]);
    assert_eq!(output.status.code(), Some(2));
    assert_eq!(output.stderr, USAGE);
}

#[test]
fn extra_cli_argument_is_usage_error() {
    let output = firth_vm(&["--smoke", "extra"]);
    assert_eq!(output.status.code(), Some(2));
    assert_eq!(output.stderr, USAGE);
}

#[test]
fn unknown_subcommand_is_usage_error() {
    let output = firth_vm(&["execute"]);
    assert_eq!(output.status.code(), Some(2));
    assert_eq!(output.stderr, USAGE);
}

#[test]
fn run_reports_the_canonical_observation_of_a_loaded_image() {
    let directory = std::env::temp_dir().join("firth-vm-cli-run");
    std::fs::create_dir_all(&directory).expect("scratch directory");
    let path = directory.join("smoke.image");
    std::fs::write(&path, firth_vm_smoke_image()).expect("write image");

    let output = firth_vm(&["run", path.to_str().expect("utf-8 path")]);
    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).expect("utf-8 report"),
        "status: terminal\n\
         stack: 42\n\
         frames: -\n\
         world: 0\n\
         trap: -\n\
         cost: total=1 kernel=1 instructions=1 word-entries=0 primitives=0\n"
    );
    assert!(output.stderr.is_empty());
}

#[test]
fn run_reports_a_zero_cost_trap_for_a_malformed_image() {
    let directory = std::env::temp_dir().join("firth-vm-cli-run");
    std::fs::create_dir_all(&directory).expect("scratch directory");
    let path = directory.join("malformed.image");
    let mut bytes = firth_vm_smoke_image();
    bytes.truncate(bytes.len() - 1);
    std::fs::write(&path, bytes).expect("write image");

    let output = firth_vm(&["run", path.to_str().expect("utf-8 path")]);
    assert_eq!(output.status.code(), Some(1));
    assert_eq!(
        String::from_utf8(output.stdout).expect("utf-8 report"),
        "status: trap\n\
         stack: \n\
         frames: -\n\
         world: 0\n\
         trap: malformed-instruction\n\
         cost: total=0 kernel=0 instructions=0 word-entries=0 primitives=0\n"
    );
}

#[test]
fn run_honours_an_explicit_fuel_budget() {
    let directory = std::env::temp_dir().join("firth-vm-cli-run");
    std::fs::create_dir_all(&directory).expect("scratch directory");
    let path = directory.join("fuel.image");
    std::fs::write(&path, firth_vm_smoke_image()).expect("write image");

    let output = firth_vm(&["run", path.to_str().expect("utf-8 path"), "--fuel", "0"]);
    assert_eq!(output.status.code(), Some(1));
    let report = String::from_utf8(output.stdout).expect("utf-8 report");
    assert!(report.starts_with("status: fuel-exhausted\n"), "{report}");
    assert!(report.contains("trap: fuel-exhausted\n"), "{report}");
}

#[test]
fn run_without_a_readable_image_fails_without_a_report() {
    let output = firth_vm(&["run", "/nonexistent/firth-vm/image.bin"]);
    assert_eq!(output.status.code(), Some(1));
    assert!(output.stdout.is_empty());
    assert_eq!(
        String::from_utf8(output.stderr).expect("utf-8 error"),
        "cannot read image: /nonexistent/firth-vm/image.bin\n"
    );
}

fn firth_vm_smoke_image() -> Vec<u8> {
    firth_vm::smoke_image()
}

#[test]
fn vm_run_reads_one_request_from_stdin_and_writes_one_observation() {
    use std::io::Write;
    let digest = hex(&firth_vm::body_digest(&[firth_vm::Instruction {
        op: firth_vm::Op::PushLiteral,
        operand: Some(firth_vm::Operand::Literal(firth_vm::Value::Int(42))),
    }]));
    let evidence = hex(&firth_vm::evidence_digest(&[]));
    let request = format!(
        "{{\"request_id\":\"cli\",\"target_program\":{{\"format_version\":1,\"entry\":\"main\",\
         \"words\":[{{\"name\":\"main\",\"erased_word_type\":\"(--)\",\
         \"code\":[{{\"op\":\"push-literal\",\"literal\":{{\"kind\":\"int\",\"value\":42}}}}],\
         \"body_digest\":\"{digest}\",\"kernel_evidence_digest\":\"{evidence}\",\
         \"refinement_evidence_digest\":\"{evidence}\",\"generation\":0}}]}},\
         \"initial_stack\":[],\"image\":{{\"image_version\":1,\"gamma_version\":1}},\
         \"gamma_version\":\"0.1\",\"fuel\":64}}"
    );

    let mut child = Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .arg("vm-run")
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("CLI starts");
    child
        .stdin
        .as_mut()
        .expect("stdin")
        .write_all(request.as_bytes())
        .expect("write request");
    let output = child.wait_with_output().expect("CLI finishes");

    assert!(output.status.success());
    let response = String::from_utf8(output.stdout).expect("utf-8 response");
    assert!(
        response.starts_with("{\"request_id\":\"cli\",\"status\":\"success\""),
        "{response}"
    );
    assert!(response.ends_with("\n"));
    assert!(output.stderr.is_empty());
}

#[test]
fn vm_run_reports_a_refusal_on_stderr_and_never_on_stdout() {
    use std::io::Write;
    let mut child = Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .arg("vm-run")
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .spawn()
        .expect("CLI starts");
    child
        .stdin
        .as_mut()
        .expect("stdin")
        .write_all(b"not json")
        .expect("write request");
    let output = child.wait_with_output().expect("CLI finishes");

    assert_eq!(output.status.code(), Some(1));
    assert!(output.stdout.is_empty());
    let error = String::from_utf8(output.stderr).expect("utf-8 error");
    assert!(error.contains("\"code\":\"malformed-json\""), "{error}");
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

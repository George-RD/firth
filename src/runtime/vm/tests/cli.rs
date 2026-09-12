use std::io::{Read, Write};
use std::path::PathBuf;
use std::process::{Child, Command, Output, Stdio};
use std::time::{Duration, Instant};

const USAGE: &[u8] =
    b"usage: firth-vm --smoke | firth-vm run <image-path> [--fuel <n>] | firth-vm vm-run\n";

const ADMISSION: &str = "admission: admission=structural-digest-recheck \
     image-evidence=legacy-content-identifiers-not-authenticated-proofs \
     refinements=not-checked patch-admission=external-verifier-unauthenticated\n";

fn firth_vm(args: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .args(args)
        .output()
        .expect("CLI starts")
}

/// A scratch directory unique to this process and test, removed on drop, so
/// concurrent test processes never share or leave behind image files.
struct Scratch {
    directory: PathBuf,
}

impl Scratch {
    fn new(name: &str) -> Self {
        let directory =
            std::env::temp_dir().join(format!("firth-vm-cli-{}-{name}", std::process::id()));
        std::fs::create_dir_all(&directory).expect("scratch directory");
        Self { directory }
    }

    fn write(&self, name: &str, bytes: &[u8]) -> String {
        let path = self.directory.join(name);
        std::fs::write(&path, bytes).expect("write image");
        path.to_str().expect("utf-8 path").to_owned()
    }
}

impl Drop for Scratch {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.directory);
    }
}

/// What a bounded child produced.
struct Finished {
    status: std::process::ExitStatus,
    stdout: Vec<u8>,
    stderr: Vec<u8>,
}

/// Drains one pipe on its own thread, so a child writing more than the pipe
/// buffer holds never blocks on a parent that is only polling for exit.
fn drain(pipe: Option<impl Read + Send + 'static>) -> std::thread::JoinHandle<Vec<u8>> {
    std::thread::spawn(move || {
        let mut bytes = Vec::new();
        if let Some(mut pipe) = pipe {
            pipe.read_to_end(&mut bytes).expect("read the pipe");
        }
        bytes
    })
}

/// Waits for `child` up to `deadline`, killing it when the deadline passes so
/// a runtime that no longer terminates fails the test instead of hanging it.
fn wait_with_deadline(mut child: Child, deadline: Duration) -> Finished {
    let stdout = drain(child.stdout.take());
    let stderr = drain(child.stderr.take());
    let start = Instant::now();
    let status = loop {
        if let Some(status) = child.try_wait().expect("poll child") {
            break status;
        }
        if start.elapsed() > deadline {
            child.kill().expect("kill the child");
            child.wait().expect("reap the child");
            let stderr = stderr.join().expect("stderr reader");
            panic!(
                "the CLI did not finish within {deadline:?}; stderr: {}",
                String::from_utf8_lossy(&stderr)
            );
        }
        std::thread::sleep(Duration::from_millis(20));
    };
    Finished {
        status,
        stdout: stdout.join().expect("stdout reader"),
        stderr: stderr.join().expect("stderr reader"),
    }
}

fn spawn_vm_run() -> Child {
    Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .arg("vm-run")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
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
    let scratch = Scratch::new("run");
    let path = scratch.write("smoke.image", &firth_vm_smoke_image());

    let output = firth_vm(&["run", &path]);
    assert!(output.status.success());
    assert_eq!(
        String::from_utf8(output.stdout).expect("utf-8 report"),
        format!(
            "status: terminal\n\
             stack: 42\n\
             frames: -\n\
             world: 0\n\
             trap: -\n\
             cost: total=1 kernel=1 instructions=1 word-entries=0 primitives=0\n\
             {ADMISSION}"
        )
    );
    assert!(output.stderr.is_empty());
}

#[test]
fn run_reports_a_zero_cost_trap_for_a_malformed_image() {
    let scratch = Scratch::new("malformed");
    let mut bytes = firth_vm_smoke_image();
    bytes.truncate(bytes.len() - 1);
    let path = scratch.write("malformed.image", &bytes);

    let output = firth_vm(&["run", &path]);
    assert_eq!(output.status.code(), Some(1));
    assert_eq!(
        String::from_utf8(output.stdout).expect("utf-8 report"),
        format!(
            "status: trap\n\
             stack: \n\
             frames: -\n\
             world: 0\n\
             trap: malformed-instruction\n\
             cost: total=0 kernel=0 instructions=0 word-entries=0 primitives=0\n\
             {ADMISSION}"
        )
    );
}

#[test]
fn run_honours_an_explicit_fuel_budget() {
    let scratch = Scratch::new("fuel");
    let path = scratch.write("fuel.image", &firth_vm_smoke_image());

    let output = firth_vm(&["run", &path, "--fuel", "0"]);
    assert_eq!(output.status.code(), Some(1));
    let report = String::from_utf8(output.stdout).expect("utf-8 report");
    assert!(report.starts_with("status: fuel-exhausted\n"), "{report}");
    assert!(report.contains("trap: fuel-exhausted\n"), "{report}");

    // The CLI shares the adapter's fuel bound: above it is a usage error.
    let output = firth_vm(&["run", &path, "--fuel", "4097"]);
    assert_eq!(output.status.code(), Some(2));
    assert_eq!(output.stderr, USAGE);
    let output = firth_vm(&["run", &path, "--fuel", "4096"]);
    assert!(output.status.success());
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

#[cfg(unix)]
#[test]
fn run_bounds_an_unbounded_image_source() {
    // `/dev/zero` never ends. The reader stops one byte past the input bound
    // and the decoder classifies the buffer as too large at zero cost; before
    // the bound the CLI read until the host ran out of memory.
    let child = Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .args(["run", "/dev/zero"])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("CLI starts");
    let output = wait_with_deadline(child, Duration::from_secs(20));
    assert_eq!(output.status.code(), Some(1));
    let report = String::from_utf8(output.stdout).expect("utf-8 report");
    assert!(report.starts_with("status: trap\n"), "{report}");
    assert!(report.contains("trap: malformed-instruction\n"), "{report}");
    assert!(
        report.contains("cost: total=0 kernel=0 instructions=0 word-entries=0 primitives=0\n"),
        "{report}"
    );
    assert!(output.stderr.is_empty());
}

fn firth_vm_smoke_image() -> Vec<u8> {
    firth_vm::smoke_image()
}

fn literal_request(fuel: u64) -> String {
    let digest = hex(&firth_vm::body_digest(&[firth_vm::Instruction {
        op: firth_vm::Op::PushLiteral,
        operand: Some(firth_vm::Operand::Literal(firth_vm::Value::Int(42))),
    }]));
    let evidence = hex(&firth_vm::evidence_digest(&[]));
    format!(
        "{{\"request_id\":\"cli\",\"target_program\":{{\"format_version\":1,\"entry\":\"main\",\
         \"words\":[{{\"name\":\"main\",\"erased_word_type\":\"(--)\",\
         \"code\":[{{\"op\":\"push-literal\",\"literal\":{{\"kind\":\"int\",\"value\":42}}}}],\
         \"body_digest\":\"{digest}\",\"kernel_evidence_digest\":\"{evidence}\",\
         \"refinement_evidence_digest\":\"{evidence}\",\"generation\":0}}]}},\
         \"initial_stack\":[],\"image\":{{\"image_version\":1,\"gamma_version\":1}},\
         \"gamma_version\":\"0.1\",\"fuel\":{fuel}}}"
    )
}

#[test]
fn vm_run_reads_one_request_from_stdin_and_writes_one_observation() {
    let mut child = spawn_vm_run();
    child
        .stdin
        .as_mut()
        .expect("stdin")
        .write_all(literal_request(64).as_bytes())
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
    let mut child = spawn_vm_run();
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

#[test]
fn vm_run_stops_reading_stdin_at_the_input_bound() {
    // The parent writes until the child closes the pipe. A reader bounded at
    // one byte past 1 MiB stops well inside 2 MiB; before the bound the
    // child accepted a gibibyte and more.
    let mut child = spawn_vm_run();
    let mut stdin = child.stdin.take().expect("stdin");
    let chunk = vec![b'0'; 64 << 10];
    let mut written = 0usize;
    loop {
        match stdin.write_all(&chunk) {
            Ok(()) => written += chunk.len(),
            Err(error) if error.kind() == std::io::ErrorKind::BrokenPipe => break,
            Err(error) => panic!("unexpected pipe error: {error}"),
        }
        assert!(written <= 4 << 20, "the child is still reading past 4 MiB");
    }
    drop(stdin);
    let output = wait_with_deadline(child, Duration::from_secs(20));
    assert!(written <= 2 << 20, "written {written} bytes");
    assert_eq!(output.status.code(), Some(1));
    assert!(output.stdout.is_empty());
    let error = String::from_utf8(output.stderr).expect("utf-8 error");
    assert!(error.contains("\"code\":\"input-too-large\""), "{error}");
}

#[test]
fn vm_run_reports_call_depth_exceeded_for_a_self_recursive_program() {
    // Before the depth cap this request overflowed the native stack and the
    // process died with SIGABRT instead of answering.
    let digest = hex(&firth_vm::body_digest(&[firth_vm::Instruction {
        op: firth_vm::Op::CallWord,
        operand: Some(firth_vm::Operand::Word("main".to_owned())),
    }]));
    let evidence = hex(&firth_vm::evidence_digest(&[]));
    let request = format!(
        "{{\"request_id\":\"recursion\",\"target_program\":{{\"format_version\":1,\
         \"entry\":\"main\",\"words\":[{{\"name\":\"main\",\"erased_word_type\":\"(--)\",\
         \"code\":[{{\"op\":\"call-word\",\"name\":\"main\"}}],\
         \"body_digest\":\"{digest}\",\"kernel_evidence_digest\":\"{evidence}\",\
         \"refinement_evidence_digest\":\"{evidence}\",\"generation\":0}}]}},\
         \"initial_stack\":[],\"image\":{{\"image_version\":1,\"gamma_version\":1}},\
         \"gamma_version\":\"0.1\",\"fuel\":4096}}"
    );
    let mut child = spawn_vm_run();
    child
        .stdin
        .take()
        .expect("stdin")
        .write_all(request.as_bytes())
        .expect("write request");
    let output = wait_with_deadline(child, Duration::from_secs(60));
    assert!(
        output.status.success(),
        "{}",
        String::from_utf8_lossy(&output.stderr)
    );
    // The observation carries every event's frames, so at this depth it is
    // several megabytes: larger than the bounded request parser admits, which
    // is why the members are located textually here.
    let response = String::from_utf8(output.stdout).expect("utf-8");
    assert!(
        response.starts_with("{\"request_id\":\"recursion\",\"status\":\"trap\","),
        "{}",
        &response[..response.len().min(200)]
    );
    assert!(
        response.contains(",\"trap\":\"resource-fault\","),
        "no trap class"
    );
    assert!(
        response.contains(",\"trap_subcode\":\"call-depth-exceeded\","),
        "no subcode"
    );
    let residual = response
        .find("\"world_observation\"")
        .and_then(|start| {
            let tail = &response[start..];
            let end = tail.find("\"trap_subcode\"")?;
            Some(&tail[..end])
        })
        .expect("the residual frames follow the world observation");
    assert_eq!(
        residual.matches("\"continuation\":").count(),
        firth_vm::MAX_CALL_DEPTH
    );
}

#[test]
fn vm_run_accepts_a_request_exactly_at_the_fuel_bound_and_refuses_the_next() {
    for (fuel, accepted) in [(4096, true), (4097, false)] {
        let mut child = spawn_vm_run();
        child
            .stdin
            .take()
            .expect("stdin")
            .write_all(literal_request(fuel).as_bytes())
            .expect("write request");
        let output = child.wait_with_output().expect("CLI finishes");
        assert_eq!(output.status.success(), accepted, "fuel {fuel}");
        if !accepted {
            let mut error = String::new();
            output
                .stderr
                .as_slice()
                .read_to_string(&mut error)
                .expect("utf-8");
            assert!(error.contains("fuel exceeds the adapter budget"), "{error}");
        }
    }
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().map(|byte| format!("{byte:02x}")).collect()
}

use std::process::Command;

const USAGE: &[u8] = b"usage: firth-vm --smoke | firth-vm run <image-path> [--fuel <n>]\n";

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

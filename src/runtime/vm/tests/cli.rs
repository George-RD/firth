use std::process::Command;

#[test]
fn smoke_cli_contract() {
    let output = Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .arg("--smoke")
        .output()
        .expect("CLI starts");
    assert!(output.status.success());
    assert_eq!(output.stdout, b"42\n");
    assert!(output.stderr.is_empty());
}

#[test]
fn usage_cli_contract() {
    let output = Command::new(env!("CARGO_BIN_EXE_firth-vm"))
        .output()
        .expect("CLI starts");
    assert_eq!(output.status.code(), Some(2));
    assert_eq!(output.stderr, b"usage: firth-vm --smoke\n");
}

use std::env;
use std::process::ExitCode;

use firth_vm::{Value, decode, execute, smoke_image};

fn main() -> ExitCode {
    run(env::args().skip(1))
}

fn run(mut args: impl Iterator<Item = String>) -> ExitCode {
    if args.next().as_deref() != Some("--smoke") || args.next().is_some() {
        eprintln!("usage: firth-vm --smoke");
        return ExitCode::from(2);
    }
    match decode(&smoke_image()).and_then(|image| execute(&image)) {
        Ok(stack) if stack == [Value::Int(42)] => {
            println!("42");
            ExitCode::SUCCESS
        }
        Ok(_) => {
            eprintln!("smoke result has an unexpected stack");
            ExitCode::from(1)
        }
        Err(error) => {
            eprintln!("smoke failed: {error:?}");
            ExitCode::from(1)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::run;

    #[test]
    fn smoke_is_successful() {
        assert_eq!(
            run([String::from("--smoke")].into_iter()),
            std::process::ExitCode::SUCCESS
        );
    }

    #[test]
    fn missing_command_is_usage_error() {
        assert_eq!(run([].into_iter()), std::process::ExitCode::from(2));
    }

    #[test]
    fn extra_command_is_usage_error() {
        assert_eq!(
            run([String::from("--smoke"), String::from("extra")].into_iter()),
            std::process::ExitCode::from(2)
        );
    }
}

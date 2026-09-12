use std::env;
use std::fs::File;
use std::io::Read;
use std::process::ExitCode;

use firth_vm::{
    ConformanceStatus, DEFAULT_FUEL, MAX_FUEL, MAX_INPUT_BYTES, Value, decode, default_registry,
    execute, observe_image_bytes, render_adapter_error, render_conformance_admission,
    render_conformance_bytes, render_conformance_cost, render_conformance_trap, smoke_image,
    vm_run_bytes,
};

const USAGE: &str =
    "usage: firth-vm --smoke | firth-vm run <image-path> [--fuel <n>] | firth-vm vm-run";

/// Reads at most one byte past the input bound, so an oversize or unbounded
/// source is classified by the decoder as `InputTooLarge` instead of being
/// buffered in full first.
fn read_bounded(source: impl Read) -> std::io::Result<Vec<u8>> {
    let mut bytes = Vec::new();
    source
        .take(MAX_INPUT_BYTES as u64 + 1)
        .read_to_end(&mut bytes)?;
    Ok(bytes)
}

fn main() -> ExitCode {
    run(env::args().skip(1))
}

fn run(args: impl Iterator<Item = String>) -> ExitCode {
    let args: Vec<String> = args.collect();
    match args.split_first() {
        Some((command, rest)) if command == "--smoke" && rest.is_empty() => smoke(),
        Some((command, rest)) if command == "run" => run_image(rest),
        Some((command, rest)) if command == "vm-run" && rest.is_empty() => vm_run_adapter(),
        _ => usage(),
    }
}

fn usage() -> ExitCode {
    eprintln!("{USAGE}");
    ExitCode::from(2)
}

fn smoke() -> ExitCode {
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

/// Loads a canonical image file and reports the execution through the same
/// conformance boundary the differential comparison uses, so the CLI cannot
/// report anything the contract does not fix.
fn run_image(args: &[String]) -> ExitCode {
    let Some((path, fuel)) = parse_run_arguments(args) else {
        return usage();
    };
    let bytes = match File::open(path).and_then(read_bounded) {
        Ok(bytes) => bytes,
        Err(_) => {
            eprintln!("cannot read image: {path}");
            return ExitCode::from(1);
        }
    };
    let observation = observe_image_bytes(&bytes, Vec::new(), fuel, &default_registry());
    println!("status: {}", observation.status.canonical());
    println!("stack: {}", observation.stack);
    println!("frames: {}", observation.frames);
    println!(
        "world: {}",
        render_conformance_bytes(&observation.world_observation)
    );
    println!(
        "trap: {}",
        render_conformance_trap(observation.trap.as_ref())
    );
    println!("cost: {}", render_conformance_cost(&observation.cost));
    println!(
        "admission: {}",
        render_conformance_admission(&observation.admission)
    );
    if observation.status == ConformanceStatus::Terminal {
        ExitCode::SUCCESS
    } else {
        ExitCode::from(1)
    }
}

/// The `firth.vm-run.v1` adapter entry point: one request object on stdin,
/// one `firth.observation.v1` object on stdout. A refused request prints its
/// classified error on stderr and exits 1, so a caller can never mistake a
/// refusal for an observation.
fn vm_run_adapter() -> ExitCode {
    let Ok(input) = read_bounded(std::io::stdin().lock()) else {
        eprintln!("cannot read the request from stdin");
        return ExitCode::from(1);
    };
    match vm_run_bytes(&input) {
        Ok(response) => {
            println!("{response}");
            ExitCode::SUCCESS
        }
        Err(error) => {
            eprintln!("{}", render_adapter_error(&error));
            ExitCode::from(1)
        }
    }
}

/// A fuel budget above `MAX_FUEL` is a usage error, the same bound the
/// `vm-run` adapter refuses with `invalid-request`.
fn parse_run_arguments(args: &[String]) -> Option<(&str, u64)> {
    match args {
        [path] => Some((path.as_str(), DEFAULT_FUEL)),
        [path, flag, fuel] if flag == "--fuel" => {
            let fuel: u64 = fuel.parse().ok()?;
            (fuel <= MAX_FUEL).then_some((path.as_str(), fuel))
        }
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::{USAGE, run};

    fn arguments(values: &[&str]) -> impl Iterator<Item = String> {
        values
            .iter()
            .map(|value| String::from(*value))
            .collect::<Vec<_>>()
            .into_iter()
    }

    #[test]
    fn smoke_is_successful() {
        assert_eq!(
            run(arguments(&["--smoke"])),
            std::process::ExitCode::SUCCESS
        );
    }

    #[test]
    fn missing_command_is_usage_error() {
        assert_eq!(run(arguments(&[])), std::process::ExitCode::from(2));
    }

    #[test]
    fn extra_command_is_usage_error() {
        assert_eq!(
            run(arguments(&["--smoke", "extra"])),
            std::process::ExitCode::from(2)
        );
    }

    #[test]
    fn run_without_an_image_path_is_a_usage_error() {
        assert_eq!(run(arguments(&["run"])), std::process::ExitCode::from(2));
    }

    #[test]
    fn run_with_an_unparseable_fuel_budget_is_a_usage_error() {
        assert_eq!(
            run(arguments(&["run", "image.bin", "--fuel", "lots"])),
            std::process::ExitCode::from(2)
        );
    }

    #[test]
    fn run_with_a_fuel_budget_above_the_bound_is_a_usage_error() {
        assert_eq!(
            run(arguments(&["run", "image.bin", "--fuel", "4097"])),
            std::process::ExitCode::from(2)
        );
    }

    #[test]
    fn usage_names_every_supported_command() {
        assert!(USAGE.contains("--smoke"));
        assert!(USAGE.contains("run <image-path>"));
        assert!(USAGE.contains("vm-run"));
    }

    #[test]
    fn vm_run_takes_no_argument() {
        assert_eq!(
            run(arguments(&["vm-run", "request.json"])),
            std::process::ExitCode::from(2)
        );
    }
}

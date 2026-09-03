use std::env;
use std::fs;
use std::process::ExitCode;

use firth_vm::{
    ConformanceStatus, DEFAULT_FUEL, Value, decode, default_registry, execute, observe_image_bytes,
    render_conformance_bytes, render_conformance_cost, render_conformance_trap, smoke_image,
};

const USAGE: &str = "usage: firth-vm --smoke | firth-vm run <image-path> [--fuel <n>]";

fn main() -> ExitCode {
    run(env::args().skip(1))
}

fn run(args: impl Iterator<Item = String>) -> ExitCode {
    let args: Vec<String> = args.collect();
    match args.split_first() {
        Some((command, rest)) if command == "--smoke" && rest.is_empty() => smoke(),
        Some((command, rest)) if command == "run" => run_image(rest),
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
    let bytes = match fs::read(path) {
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
    if observation.status == ConformanceStatus::Terminal {
        ExitCode::SUCCESS
    } else {
        ExitCode::from(1)
    }
}

fn parse_run_arguments(args: &[String]) -> Option<(&str, u64)> {
    match args {
        [path] => Some((path.as_str(), DEFAULT_FUEL)),
        [path, flag, fuel] if flag == "--fuel" => Some((path.as_str(), fuel.parse().ok()?)),
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
    fn usage_names_every_supported_command() {
        assert!(USAGE.contains("--smoke"));
        assert!(USAGE.contains("run <image-path>"));
    }
}

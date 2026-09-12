# Proposal: mvp-agent-vm-adapter

## Motivation

`tools/loop/mvp_agent_manifest.toml` pins four adapters for the MVP gate. The
reference-run adapter exists and speaks structured JSON over stdin and stdout;
the VM side did not. `firth-vm` accepted `--smoke` and, since the previous
unit, `run <image-path>`, neither of which is the `firth.vm-run.v1` contract
the gate must call.

Without it the gate cannot execute a compiled application at all, so
`entry_point.vm_run` stays `availability = "gate-required"` and the
`mvp-agent-authoring` obligation cannot close.

## Scope

- A bounded JSON reader and writer inside the VM crate, so the trusted
  runtime gains a transport without gaining a dependency.
- The `firth.vm-run.v1` adapter: decode a `firth.vm-execution.v1` request,
  seal and re-decode the target program through the trusted decoder, execute
  the named entry word, and emit a `firth.observation.v1` response.
- A `vm-run` CLI subcommand reading one request from stdin.
- Named-entry execution, so a compiled word that is not called `main` runs
  without an administrative call the reference interpreter never makes.

## Out of scope

- The compiler that produces the target program. This unit defines and
  enforces the shape it must produce; `todo.mvp-agent-compiler-adapter`
  produces it.
- Any change to execution semantics, the target contract, or trap
  classification. The adapter reports the classification the VM already
  computes.

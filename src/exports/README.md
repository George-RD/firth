# Kernel exports

Each `.lean` file here except `All.lean` is generated from one Firth source
listed in `manifest.json`. For every word in that source it defines:

- `body`: the erased kernel program the elaborator checked and the compiler
  accepted, as a `Firth.Interpreter.Program`;
- `bodyDigest`: the `body_digest` of that program in the VM image;
- `erasedType`: the erased word type the image records.

It also defines `words` and a `dictionary` that runs under
`Firth.ReferenceRun.adapterGamma` and `defaultCosts`, exactly as the reference
runner does. These are the definitions a Lean proof about a Firth program
should mention, so that the proof is about the code the VM runs and not about
a model of it.

Do not edit these files. After changing a listed source, the elaborator or
erasure, regenerate them:

```sh
lake build
python3 tools/loop/update_kernel_exports.py
lake build
```

Two checks bind them:

- CI runs `python3 tools/loop/update_kernel_exports.py --check`, which
  re-exports every source and fails on any difference or on a stray file. It
  also exports a copy of `signed.firth` with a planted edit and fails unless
  the export of `abs` changes. `lake build` builds the exporter it runs.
- `lake exe firthExportsTest` (part of `lake test`) lowers each `body` again
  and fails unless it hashes to `bodyDigest`, and fails unless the source
  still elaborates to the same program.

To export another source, add a `{"source": ..., "module": ...}` entry to
`manifest.json` and regenerate. The module name is dot-separated, each part
starting with a capital letter, and becomes `Firth.Exports.<module>`.

The exports state nothing about the programs. They are inputs to proofs.
The two gaps any such proof inherits: it is about the reference interpreter,
with VM agreement resting on differential testing, and Lean's `Int` is
unbounded where the VM traps on i64 overflow.

Each `dictionary` entry carries the reference runner's placeholder type
`adapterWordType` (`ρ -- ρ`), because the runner reads only bodies. So the
kernel's typing theorems (preservation, progress) cannot be applied to these
dictionaries as they stand. The real erased type of each word is recorded as
the string `erasedType`, which nothing in Lean parses yet.

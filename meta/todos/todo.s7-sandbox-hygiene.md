---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Tighten two corners of the S7 author sandbox

The reviewer approved #134 at `2d034c0` and at `3a3319c` and noted four
things the README's threat model does not require, since all are implausible
as accidents.

- **Loose object directories.** `hidden_copies` recognises git storage by a
  `.git` entry, or by HEAD, `objects` and `refs` together. An `objects/`
  directory on its own (no HEAD, no refs) is not treated as storage. Git
  will not read it, but its loose objects can be decompressed by hand.
- **Only the `/etc` the author needs.** The sandbox shows all of `/etc`.
  Showing only the entries an author CLI needs (passwd, group, nsswitch,
  resolver files, TLS certificates) would narrow what the scan has to
  cover.
- **A subtree rooted at `eval/s7`.** The storage tree scan recognises the
  references by the path chain `eval`, `s7`, `reference` from a root tree.
  A tree written with `eval/s7` as its root holds `reference/` directly
  and is not matched. Matching any tree that holds a `reference` directory
  whose entries match the reference file names would close it.
- **Treeless partial clones.** A clone made with `--filter=tree:0` fetches
  trees on demand from its promisor remote. The scan reads only the trees
  present, and fails closed only when git errors, so a later lazy fetch
  inside the sandbox is blocked by the missing network, not by the scan.
  The scan should refuse a repository with a promisor remote outright.
- **The direct `harness.py try` reads any path it is given.** Run as root,
  it reads the program file on the host before sandboxing the run, so a
  diagnostic can echo any host file (Codex, on #134 at `6661ad8`). Only a
  caller already on the host can pass that path, and such a caller can read
  the file anyway, so this is outside the sandbox's threat model. The
  in-workspace `./try` already refuses paths outside the workspace. Reading
  the program with `read_regular` under a named workspace would make the
  direct command match it.

## Acceptance criteria

- A shown directory holding loose objects of a hidden file (zlib-compressed,
  under `xx/yyyy...` names) makes the sandbox refuse. A planted case shows
  the refusal, and shows the content readable with the check bypassed.
- `/etc` inside the sandbox is an allowlist of named entries. A planted
  file elsewhere in `/etc` is unreachable inside, and reachable with the
  allowlist bypassed. The author CLI and Python still start (`test_isolation.py`).
- A shown repository whose only tree holding the references is rooted at
  `eval/s7` is refused, with the bypass mutant reading it.
- A shown partial clone (a `remote.*.promisor` setting) is refused.
- `harness.py try` reads its program only as a plain file under a named
  workspace, with a planted `/etc/shadow` path that is refused.

---
node: firth.toolchain.agent
status: open
created: 2026-09-28
---

# Tighten two corners of the S7 author sandbox

The reviewer approved #134 at `2d034c0` and noted two things the README's
threat model does not require, since both are implausible as accidents.

- **Loose object directories.** `hidden_copies` recognises git storage by a
  `.git` entry, or by HEAD, `objects` and `refs` together. An `objects/`
  directory on its own (no HEAD, no refs) is not treated as storage. Git
  will not read it, but its loose objects can be decompressed by hand.
- **Only the `/etc` the author needs.** The sandbox shows all of `/etc`.
  Showing only the entries an author CLI needs (passwd, group, nsswitch,
  resolver files, TLS certificates) would narrow what the scan has to
  cover.

## Acceptance criteria

- A shown directory holding loose objects of a hidden file (zlib-compressed,
  under `xx/yyyy...` names) makes the sandbox refuse. A planted case shows
  the refusal, and shows the content readable with the check bypassed.
- `/etc` inside the sandbox is an allowlist of named entries. A planted
  file elsewhere in `/etc` is unreachable inside, and reachable with the
  allowlist bypassed. The author CLI and Python still start (`test_isolation.py`).

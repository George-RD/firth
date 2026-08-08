# Tasks: driver-token-tail

- [x] Author dec.driver-token-tail amending the token reading only.
- [x] Replace the driver block's last-line read with the fail-closed
      tail scan; keep `LOOP EXHAUSTED` strict final-line.
- [x] Update the Terminal tokens section of `docs/loop-runbook.md`.
- [x] Add `tools/loop/test_driver_tokens.py` (nine adversarial paths
      against the extracted block) and run it green.
- [x] Run control-plane suites, validators, `cairn scan`,
      `cairn hook all`; land on `origin/main` outside the loop.

# Branch reports that name an operation inside an inner quotation

The checker's reports before and after the change that names the operation
inside a nested quotation of a refused `if`'s branch, such as `addto` in
fillb (`eval/s7/harder/runs/2026-10-11-scored/sonnet-firth-3`, warehouse).

`compare.py` sends every unique source (each `solutions-*.json` answer under
`eval/s7`, every `.firth` file under `examples/` and `stdlib/`) to two
`firthElaborate` binaries and records every report that differs:

```sh
python3 eval/s7/report-changes/inner-reach/compare.py . <main>/firthElaborate \
  .lake/build/bin/firthElaborate changes.jsonl
```

Run on 12 October 2026, main at 2acf715 against this change. Of 6,959
sources, 54 get a different report (`changes.jsonl`, one line each). None
changes between accepted and refused, or in its code or location. In 32 the
message changes only where it said "inside a quotation in that branch": it
now names the quotation, and nothing else in the message or hint changes. In the other 22 the report named no operation on
main and now names the one that takes a value that is not there.

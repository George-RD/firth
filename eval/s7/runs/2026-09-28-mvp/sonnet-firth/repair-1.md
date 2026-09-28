Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## ledger
Start with balance start. Apply each transaction in txs in order by adding it to the balance, except that a transaction that would make the balance negative is rejected and skipped. Return the final balance and the number of rejected transactions.
Inputs on the stack, bottom to top: start: Int, txs: Seq Int.
Outputs left on the stack, bottom to top: balance: Int, rejected: Int.
Example: stack [10, { 5 -20 -15 4 }] becomes [4, 1].

Your answer:
```
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { txs start 0 0 ledger-loop }
  ;

: ledger-loop
  (forall ρ; ρ txs:Seq Int^many i:Int^many balance:Int^many rejected:Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs i balance rejected } {
    i txs prim seq-int.len prim <
    [ balance txs i prim seq-int.at prim + 0 prim <
      [ txs i 1 prim + balance rejected 1 prim + ]
      [ txs i 1 prim + balance txs i prim seq-int.at prim + rejected ]
      if
      ledger-loop
    ]
    [ balance rejected ]
    if
  }
  ;

```
On the example, it returned [0, 0] instead of [4, 1]

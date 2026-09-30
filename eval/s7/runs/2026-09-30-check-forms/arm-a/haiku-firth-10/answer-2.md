### task: seq-sum
```firth
: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ total:Int^many)
  locals { xs i acc } {
    xs prim seq-int.len i prim >=
    [ acc ]
    [
      xs i prim seq-int.at acc prim +
      i 1 prim +
      locals { new-acc new-i } {
        xs new-i new-acc sum-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    xs 0 0 sum-loop
  };
```

### task: seq-max
```firth
: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many max:Int^many -- ρ largest:Int^many)
  locals { xs i max } {
    xs prim seq-int.len i prim >=
    [ max ]
    [
      xs i prim seq-int.at
      max prim <
      [ max ] [ xs i prim seq-int.at ] if
      i 1 prim +
      locals { new-max new-i } {
        xs new-i new-max max-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 1 xs 0 prim seq-int.at max-loop
  };
```

### task: count-below
```firth
: count-loop
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many cnt:Int^many -- ρ count:Int^many)
  locals { xs k i cnt } {
    xs prim seq-int.len i prim >=
    [ cnt ]
    [
      xs i prim seq-int.at k prim <
      [ cnt 1 prim + ] [ cnt ] if
      i 1 prim +
      locals { new-cnt new-i } {
        xs k new-i new-cnt count-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } {
    xs k 0 0 count-loop
  };
```

### task: index-of
```firth
: find-loop
  (forall ρ; ρ xs:Seq Int^many x:Int^many i:Int^many -- ρ index:Int^many)
  locals { xs x i } {
    xs prim seq-int.len i prim >=
    [ -1 ]
    [
      xs i prim seq-int.at x prim =
      [ i ] [ xs x i 1 prim + find-loop ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { xs x } {
    xs x 0 find-loop
  };
```

### task: reverse
```firth
: reverse-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs i result } {
    i 0 prim <
    [ result ]
    [
      result xs i prim seq-int.at prim seq-int.push
      i 1 prim -
      locals { new-i new-result } {
        xs new-i new-result reverse-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - prim seq-int.empty reverse-loop
  };
```

### task: prefix-sums
```firth
: prefix-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many sum:Int^many result:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs i sum result } {
    xs prim seq-int.len i prim >=
    [ result ]
    [
      xs i prim seq-int.at sum prim +
      locals { new-sum } {
        result new-sum prim seq-int.push
        i 1 prim +
        locals { new-i new-result } {
          xs new-i new-sum new-result prefix-loop
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    xs 0 0 prim seq-int.empty prefix-loop
  };
```

### task: keep-positive
```firth
: filter-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many result:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs i result } {
    xs prim seq-int.len i prim >=
    [ result ]
    [
      xs i prim seq-int.at
      locals { v } {
        v 0 prim >
        [ result v prim seq-int.push ] [ result ] if
        i 1 prim +
        locals { new-i new-result } {
          xs new-result new-i filter-loop
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    xs 0 prim seq-int.empty filter-loop
  };
```

### task: is-sorted
```firth
: sorted-check
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ sorted:Bool^many)
  locals { xs i } {
    xs prim seq-int.len i prim >=
    [ true ]
    [
      xs i prim seq-int.at
      xs i 1 prim + prim seq-int.at
      prim <=
      [ xs i 1 prim + sorted-check ] [ false ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <=
    [ true ] [ xs 0 sorted-check ] if
  };
```

### task: dot
```firth
: dot-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many i:Int^many sum:Int^many -- ρ product:Int^many)
  locals { xs ys i sum } {
    xs prim seq-int.len i prim >=
    [ sum ]
    [
      xs i prim seq-int.at
      ys i prim seq-int.at
      prim *
      sum prim +
      i 1 prim +
      locals { new-sum new-i } {
        xs ys new-i new-sum dot-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } {
    xs ys 0 0 dot-loop
  };
```

### task: all-true
```firth
: all-true-check
  (forall ρ; ρ flags:Seq Bool^many i:Int^many -- ρ all:Bool^many)
  locals { flags i } {
    flags prim seq-bool.len i prim >=
    [ true ]
    [
      flags i prim seq-bool.at
      [ flags i 1 prim + all-true-check ] [ false ] if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim =
    [ true ] [ flags 0 all-true-check ] if
  };
```

### task: longest-run
```firth
: run-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many run-len:Int^many max-len:Int^many -- ρ length:Int^many)
  locals { xs i run-len max-len } {
    xs prim seq-int.len i prim >=
    [ max-len ]
    [
      i 0 prim =
      [ 1 ]
      [
        xs i prim seq-int.at
        xs i 1 prim - prim seq-int.at
        prim =
        [ run-len 1 prim + ] [ 1 ] if
      ]
      if
      locals { new-run-len } {
        new-run-len max-len prim >
        [ new-run-len ] [ max-len ] if
        locals { new-max-len } {
          i 1 prim +
          locals { new-i } {
            xs new-i new-run-len new-max-len run-loop
          }
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ] [ xs 0 0 0 run-loop ] if
  };
```

### task: digits
```firth
: reverse-digits
  (forall ρ; ρ digits:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { digits } {
    0 prim seq-int.empty
    0 prim seq-int.len [ ] [ ] if
    prim seq-int.empty
  };

: digits-loop
  (forall ρ; ρ n:Int^many result:Seq Int^many -- ρ digits:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div
      locals { new-n new-result } {
        new-result new-n digits-loop
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ 0 prim seq-int.empty 0 prim seq-int.push ]
    [ n prim seq-int.empty digits-loop ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } {
    start 0
  };
```

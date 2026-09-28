### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } {
    0 0 xs helper-sum
  };

: helper-sum
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs idx acc } {
    idx xs prim seq-int.len prim <
    [ xs idx prim seq-int.at acc prim + idx 1 prim + xs helper-sum ]
    [ acc ]
    if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 0 xs helper-max
  };

: helper-max
  (forall ρ; ρ idx:Int^many i:Int^many current:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs current i idx } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v current prim <
        [ idx 1 prim + i current xs helper-max ]
        [ idx 1 prim + i v xs helper-max ]
        if
      }
    ]
    [ current ]
    if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { k xs } {
    0 0 xs k helper-count
  };

: helper-count
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { k xs idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v k prim <
        [ acc 1 prim + idx 1 prim + xs k helper-count ]
        [ acc idx 1 prim + xs k helper-count ]
        if
      }
    ]
    [ acc ]
    if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  locals { x xs } {
    0 xs x -1 helper-index
  };

: helper-index
  (forall ρ; ρ idx:Int^many xs:Seq Int^many x:Int^many notfound:Int^many -- ρ result:Int^many)
  locals { notfound x xs idx } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at x prim =
      [ idx ]
      [ idx 1 prim + xs x notfound helper-index ]
      if
    ]
    [ notfound ]
    if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs prim seq-int.len 1 prim - xs helper-reverse
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs idx result } {
    idx 0 prim <
    [ result ]
    [
      xs idx prim seq-int.at result prim seq-int.push
      idx 1 prim - xs helper-reverse
    ]
    if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 0 xs helper-prefix
  };

: helper-prefix
  (forall ρ; ρ result:Seq Int^many acc:Int^many idx:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs idx acc result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at acc prim + locals { newsum } {
        result newsum prim seq-int.push
        idx 1 prim + newsum xs helper-prefix
      }
    ]
    [ result ]
    if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs helper-keep
  };

: helper-keep
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs idx result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v 0 prim <
        [ result idx 1 prim + xs helper-keep ]
        [ result v prim seq-int.push idx 1 prim + xs helper-keep ]
        if
      }
    ]
    [ result ]
    if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim <
    [ true ]
    [ 0 true xs helper-issorted ]
    if
  };

: helper-issorted
  (forall ρ; ρ idx:Int^many acc:Bool^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { xs acc idx } {
    acc prim not
    [ false ]
    [
      idx xs prim seq-int.len 1 prim - prim <
      [
        xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <
        [ idx 1 prim + false xs helper-issorted ]
        [ idx 1 prim + acc xs helper-issorted ]
        if
      ]
      [ acc ]
      if
    ]
    if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { ys xs } {
    0 0 xs ys helper-dot
  };

: helper-dot
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { ys xs idx acc } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim +
      idx 1 prim + xs ys helper-dot
    ]
    [ acc ]
    if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } {
    flags prim seq-bool.len 0 prim =
    [ true ]
    [ 0 true flags helper-alltrue ]
    if
  };

: helper-alltrue
  (forall ρ; ρ idx:Int^many acc:Bool^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { flags acc idx } {
    idx flags prim seq-bool.len prim <
    [
      flags idx prim seq-bool.at acc prim and
      idx 1 prim + flags helper-alltrue
    ]
    [ acc ]
    if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ 0 ]
    [
      xs 0 prim seq-int.at 1 1 0 xs helper-longrun
    ]
    if
  };

: helper-longrun
  (forall ρ; ρ idx:Int^many maxlen:Int^many curlen:Int^many prev:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { xs prev curlen maxlen idx } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v prev prim =
        [ curlen 1 prim + locals { newlen } {
            newlen maxlen prim <
            [ idx 1 prim + maxlen newlen v xs helper-longrun ]
            [ idx 1 prim + newlen newlen v xs helper-longrun ]
            if
          }
        ]
        [ 1 locals { newlen } {
            newlen maxlen prim <
            [ idx 1 prim + maxlen newlen v xs helper-longrun ]
            [ idx 1 prim + newlen newlen v xs helper-longrun ]
            if
          }
        ]
        if
      }
    ]
    [ maxlen ]
    if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { target xs } {
    0 xs target helper-pair
  };

: helper-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs i } {
    i xs prim seq-int.len prim <
    [
      i 1 prim + i xs target helper-pair-inner
      [ helper-pair-done ]
      [ i 1 prim + xs target helper-pair ]
      if
    ]
    [ false ]
    if
  };

: helper-pair-done
  (forall ρ; ρ -- ρ result:Bool^many)
  true;

: helper-pair-inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { target xs i j } {
    j xs prim seq-int.len prim <
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim =
      [ true ]
      [ j 1 prim + i xs target helper-pair-inner ]
      if
    ]
    [ false ]
    if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs helper-distinct
  };

: helper-distinct
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many seen:Seq Int^many -- ρ result:Int^many)
  locals { seen xs idx count } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        v seen helper-find
        [ count 1 prim + seen v prim seq-int.push idx 1 prim + xs helper-distinct ]
        [ count seen idx 1 prim + xs helper-distinct ]
        if
      }
    ]
    [ count ]
    if
  };

: helper-find
  (forall ρ; ρ v:Int^many seen:Seq Int^many -- ρ found:Bool^many)
  locals { seen v } {
    0 v seen helper-find-loop
  };

: helper-find-loop
  (forall ρ; ρ i:Int^many v:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { seen v i } {
    i seen prim seq-int.len prim <
    [
      seen i prim seq-int.at v prim =
      [ true ]
      [ i 1 prim + v seen helper-find-loop ]
      if
    ]
    [ false ]
    if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { ys xs } {
    prim seq-int.empty 0 0 xs ys helper-merge
  };

: helper-merge
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ out:Seq Int^many)
  locals { ys xs j i result } {
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and
    [
      xs i prim seq-int.at ys j prim seq-int.at prim <
      [
        result xs i prim seq-int.at prim seq-int.push
        i 1 prim + j xs ys helper-merge
      ]
      [
        result ys j prim seq-int.at prim seq-int.push
        i j 1 prim + xs ys helper-merge
      ]
      if
    ]
    [
      i xs prim seq-int.len prim <
      [ result xs i prim seq-int.at prim seq-int.push i 1 prim + j xs ys helper-merge ]
      [ j ys prim seq-int.len prim <
        [ result ys j prim seq-int.at prim seq-int.push i j 1 prim + xs ys helper-merge ]
        [ result ]
        if
      ]
      if
    ]
    if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim =
    [ prim seq-int.empty 0 prim seq-int.push ]
    [
      n 0 prim <
      [ n 0 prim - prim seq-int.empty helper-digits-loop ]
      [ n prim seq-int.empty helper-digits-loop ]
      if
    ]
    if
  };

: helper-digits-loop
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ out:Seq Int^many)
  locals { n result } {
    n 0 prim =
    [ result ]
    [
      n 10 prim mod
      result swap prim seq-int.push
      n 10 prim div
      helper-digits-loop
    ]
    if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n helper-primes
  };

: helper-primes
  (forall ρ; ρ result:Seq Int^many num:Int^many n:Int^many -- ρ out:Seq Int^many)
  locals { n num result } {
    num n prim <
    [
      num helper-is-prime
      [ result num prim seq-int.push ]
      [ result ]
      if
      num 1 prim + n helper-primes
    ]
    [ result ]
    if
  };

: helper-is-prime
  (forall ρ; ρ num:Int^many -- ρ is:Bool^many)
  locals { num } {
    num 2 prim <
    [ false ]
    [
      num 2 prim =
      [ true ]
      [ num 2 prim mod 0 prim = [ false ] [ 2 num helper-check-prime ] if ]
      if
    ]
    if
  };

: helper-check-prime
  (forall ρ; ρ i:Int^many num:Int^many -- ρ result:Bool^many)
  locals { num i } {
    i i prim * num prim <
    [
      num i prim mod 0 prim =
      [ false ]
      [ i 2 prim + num helper-check-prime ]
      if
    ]
    [ true ]
    if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { k xs } {
    prim seq-int.empty
    k 0 [ helper-init-histo ] call
    0 xs k helper-histogram
  };

: helper-init-histo
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ out:Seq Int^many)
  locals { k i result } {
    i k prim <
    [ result 0 prim seq-int.push i 1 prim + k helper-init-histo ]
    [ result ]
    if
  };

: helper-histogram
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many k:Int^many -- ρ out:Seq Int^many)
  locals { k xs idx result } {
    idx xs prim seq-int.len prim <
    [
      xs idx prim seq-int.at locals { v } {
        result v prim seq-int.at 1 prim + v result prim seq-int.set
      }
      idx 1 prim + xs k helper-histogram
    ]
    [ result ]
    if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs helper-insertion-sort
  };

: helper-insertion-sort
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs i result } {
    i xs prim seq-int.len prim <
    [
      xs i prim seq-int.at result 0 i xs helper-insert
      i 1 prim + xs helper-insertion-sort
    ]
    [ result ]
    if
  };

: helper-insert
  (forall ρ; ρ j:Int^many i:Int^many val:Int^many result:Seq Int^many xs:Seq Int^many -- ρ out:Seq Int^many)
  locals { xs result val i j } {
    j 0 prim <
    [ result val prim seq-int.push ]
    [
      result j prim seq-int.at val prim <
      [ result j prim seq-int.at prim seq-int.push j 1 prim - i val result xs helper-insert ]
      [ result val prim seq-int.push ]
      if
    ]
    if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { txs start } {
    start 0 0 txs helper-ledger
  };

: helper-ledger
  (forall ρ; ρ rejected:Int^many balance:Int^many idx:Int^many txs:Seq Int^many -- ρ b:Int^many r:Int^many)
  locals { txs idx balance rejected } {
    idx txs prim seq-int.len prim <
    [
      txs idx prim seq-int.at locals { tx } {
        balance tx prim + 0 prim <
        [ balance rejected 1 prim + idx 1 prim + txs helper-ledger ]
        [ balance tx prim + rejected idx 1 prim + txs helper-ledger ]
        if
      }
    ]
    [ balance rejected ]
    if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { whole qtys items stock } {
    stock prim seq-int.empty prim seq-int.empty prim seq-int.empty 0 items qtys whole helper-allocate
  };

: helper-allocate
  (forall ρ; ρ reasons:Seq Int^many allocated:Seq Int^many stock:Seq Int^many idx:Int^many whole:Seq Bool^many qtys:Seq Int^many items:Seq Int^many -- ρ s:Seq Int^many a:Seq Int^many r:Seq Int^many)
  locals { items qtys whole idx allocated reasons stock } {
    idx items prim seq-int.len prim <
    [
      items idx prim seq-int.at locals { item } {
        stock item prim seq-int.at locals { r } {
          qtys idx prim seq-int.at locals { q } {
            q r prim <
            [
              stock item prim seq-int.at q prim - item stock prim seq-int.set locals { newstock } {
                allocated q prim seq-int.push
                reasons 0 prim seq-int.push
                idx 1 prim + newstock allocated reasons items qtys whole helper-allocate
              }
            ]
            [
              r 0 prim =
              [
                allocated 0 prim seq-int.push
                reasons 2 prim seq-int.push
                idx 1 prim + stock allocated reasons items qtys whole helper-allocate
              ]
              [
                whole idx prim seq-bool.at
                [
                  allocated 0 prim seq-int.push
                  reasons 3 prim seq-int.push
                  idx 1 prim + stock allocated reasons items qtys whole helper-allocate
                ]
                [
                  stock item prim seq-int.at 0 item stock prim seq-int.set locals { newstock } {
                    allocated r prim seq-int.push
                    reasons 1 prim seq-int.push
                    idx 1 prim + newstock allocated reasons items qtys whole helper-allocate
                  }
                ]
                if
              ]
              if
            ]
            if
          }
        }
      }
    ]
    [ stock allocated reasons ]
    if
  };
```

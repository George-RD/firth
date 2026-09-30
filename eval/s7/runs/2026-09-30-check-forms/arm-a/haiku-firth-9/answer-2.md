### task: seq-sum
```firth
: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  0 swap 0 xs prim seq-int.len sum-loop;

: sum-loop
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim + locals { new_sum } {
        idx 1 prim + locals { new_idx } {
          new_idx new_sum len xs sum-loop
        }
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  seq-sum;
```

### task: seq-max
```firth
: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  dup 0 prim seq-int.at swap 1 max-iter;

: max-iter
  (forall ρ; ρ current:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { current idx xs } {
    xs prim seq-int.len idx prim >=
    [ current ]
    [
      xs idx prim seq-int.at current prim > locals { is-greater } {
        is-greater [ xs idx prim seq-int.at ] [ current ] if locals { new-current } {
          idx 1 prim + new-current new-current xs max-iter
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  seq-max;
```

### task: count-below
```firth
: count-below
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  swap 0 0 xs prim seq-int.len count-loop;

: count-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx len xs k } {
    idx len prim <
    [
      xs idx prim seq-int.at k prim < locals { is-below } {
        is-below [ count 1 prim + ] [ count ] if locals { new-count } {
          idx 1 prim + new-count new-count len xs k count-loop
        }
      }
    ]
    [ count ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  count-below;
```

### task: index-of
```firth
: index-of
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ index:Int^many)
  swap 0 xs prim seq-int.len find-loop;

: find-loop
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x } {
    idx len prim <
    [
      xs idx prim seq-int.at x prim = locals { found } {
        found [ idx ] [ idx 1 prim + found find-loop ] if
      }
    ]
    [ -1 ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  index-of;
```

### task: reverse
```firth
: reverse
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  prim seq-int.empty swap dup prim seq-int.len 1 prim - reverse-loop;

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx xs } {
    idx 0 prim >=
    [
      xs idx prim seq-int.at result prim seq-int.push locals { new-result } {
        idx 1 prim - new-result new-result xs reverse-loop
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  reverse;
```

### task: prefix-sums
```firth
: prefix-sums
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop;

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim + locals { new-sum } {
        result new-sum prim seq-int.push locals { new-result } {
          idx 1 prim + new-result new-sum new-sum len xs prefix-loop
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  prefix-sums;
```

### task: keep-positive
```firth
: keep-positive
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  prim seq-int.empty 0 xs prim seq-int.len filter-pos;

: filter-pos
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at dup 0 prim > locals { is-positive } {
        is-positive [ result swap prim seq-int.push ] [ drop result ] if locals { new-result } {
          idx 1 prim + new-result new-result len xs filter-pos
        }
      }
    ]
    [ result ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  keep-positive;
```

### task: is-sorted
```firth
: is-sorted
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  dup prim seq-int.len dup 1 prim <= [ drop drop true ] [ 1 prim - check-sorted ] if;

: check-sorted
  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs len idx } {
    idx len prim >=
    [ true ]
    [
      xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <= locals { is-le } {
        is-le [ idx 1 prim + check-sorted ] [ false ] if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Bool^many)
  is-sorted;
```

### task: dot
```firth
: dot
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  swap 0 0 xs prim seq-int.len dot-loop;

: dot-loop
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs ys } {
    idx len prim <
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + locals { new-sum } {
        idx 1 prim + new-sum new-sum len xs ys dot-loop
      }
    ]
    [ sum ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  dot;
```

### task: all-true
```firth
: all-true
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  0 flags prim seq-bool.len check-all;

: check-all
  (forall ρ; ρ idx:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { idx len flags } {
    idx len prim >=
    [ true ]
    [
      flags idx prim seq-bool.at [ idx 1 prim + check-all ] [ false ] if
    ]
    if
  };

: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ result:Bool^many)
  all-true;
```

### task: longest-run
```firth
: longest-run
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  dup prim seq-int.len 0 prim = [ drop 0 ] [ 1 1 find-longest ] if;

: find-longest
  (forall ρ; ρ current:Int^many max:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { current max idx xs } {
    xs prim seq-int.len idx prim >=
    [ max current prim > [ current ] [ max ] if ]
    [
      xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = locals { same } {
        same [ current 1 prim + ] [ 1 ] if locals { new-current } {
          new-current max prim > [ new-current ] [ max ] if locals { new-max } {
            idx 1 prim + new-current new-max idx xs find-longest
          }
        }
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  longest-run;
```

### task: has-pair-sum
```firth
: has-pair-sum
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  swap 0 xs prim seq-int.len check-pairs;

: check-pairs
  (forall ρ; ρ i:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i len xs target } {
    i len prim >=
    [ false ]
    [
      i 1 prim + locals { j } {
        i j len xs target inner-loop
      }
    ]
    if
  };

: inner-loop
  (forall ρ; ρ i:Int^many j:Int^many len:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i j len xs target } {
    j len prim >=
    [ i 1 prim + len xs target check-pairs ]
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = locals { match } {
        match [ true ] [ j 1 prim + inner-loop ] if
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  has-pair-sum;
```

### task: count-distinct
```firth
: count-distinct
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  prim seq-int.empty 0 xs prim seq-int.len count-dist;

: count-dist
  (forall ρ; ρ seen:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen idx len xs } {
    idx len prim >=
    [ seen prim seq-int.len ]
    [
      xs idx prim seq-int.at dup seen is-in locals { found } {
        found [ drop ] [ seen swap prim seq-int.push ] if locals { new-seen } {
          idx 1 prim + new-seen new-seen len xs count-dist
        }
      }
    ]
    if
  };

: is-in
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  0 seq prim seq-int.len check-in;

: check-in
  (forall ρ; ρ idx:Int^many len:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { idx len seq val } {
    idx len prim >=
    [ false ]
    [
      seq idx prim seq-int.at val prim = [ true ] [ idx 1 prim + check-in ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Int^many)
  count-distinct;
```

### task: merge-sorted
```firth
: merge-sorted
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  swap prim seq-int.empty swap 0 0 xs prim seq-int.len ys prim seq-int.len merge-loop;

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xlen ylen xs ys } {
    i xlen prim >=
    [
      j ylen prim < [ ys j prim seq-int.at result prim seq-int.push locals { r } { j 1 prim + r j ylen xs ys merge-loop } ] [ result ] if
    ]
    [
      j ylen prim >= 
      [ xs i prim seq-int.at result prim seq-int.push locals { r } { i 1 prim + r i j xlen ylen xs ys merge-loop } ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <= locals { xs-le } {
          xs-le 
          [ xs i prim seq-int.at result prim seq-int.push locals { r } { i 1 prim + r i j xlen ylen xs ys merge-loop } ]
          [ ys j prim seq-int.at result prim seq-int.push locals { r } { j 1 prim + r i j xlen ylen xs ys merge-loop } ]
          if
        }
      ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ result:Seq Int^many)
  merge-sorted;
```

### task: digits
```firth
: digits
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  dup 0 prim = [ drop { 0 } ] [ prim seq-int.empty swap extract-digits ] if;

: extract-digits
  (forall ρ; ρ result:Seq Int^many num:Int^many -- ρ final:Seq Int^many)
  locals { result num } {
    num 0 prim <=
    [ result ]
    [
      num 10 prim mod result prim seq-int.push locals { new-result } {
        new-result new-result num 10 prim div extract-digits
      }
    ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  digits;
```

### task: primes-up-to
```firth
: primes-up-to
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  prim seq-int.empty swap 2 sieve-primes;

: sieve-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <=
    [
      candidate is-prime locals { prime } {
        prime [ result candidate prim seq-int.push locals { r } { r candidate 1 prim + n sieve-primes } ]
        [ candidate 1 prim + sieve-primes ]
        if
      }
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim < [ false ]
    [ num 2 prim = [ true ]
      [ num 2 prim mod 0 prim = [ false ] [ 2 check-divisors ] if ]
      if ]
    if
  };

: check-divisors
  (forall ρ; ρ divisor:Int^many num:Int^many -- ρ result:Bool^many)
  locals { divisor num } {
    divisor divisor prim * num prim > [ true ]
    [ num divisor prim mod 0 prim = [ false ] [ divisor 1 prim + check-divisors ] if ]
    if
  };

: main
  (forall ρ; ρ n:Int^many -- ρ result:Seq Int^many)
  primes-up-to;
```

### task: histogram
```firth
: histogram
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  swap prim seq-int.empty 0 k build-counts;

: build-counts
  (forall ρ; ρ result:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx k xs } {
    idx k prim >=
    [ result ]
    [
      0 idx xs count-value-eq locals { count } {
        result count prim seq-int.push locals { new-result } {
          idx 1 prim + new-result new-result k xs build-counts
        }
      }
    ]
    if
  };

: count-value-eq
  (forall ρ; ρ count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count idx xs } {
    0 xs prim seq-int.len count-matches
  };

: count-matches
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many idx:Int^many xs:Seq Int^many -- ρ final:Int^many)
  locals { i len count idx xs } {
    i len prim >=
    [ count ]
    [
      xs i prim seq-int.at idx prim = [ count 1 prim + ] [ count ] if locals { new-count } {
        i 1 prim + new-count new-count idx xs count-matches
      }
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ result:Seq Int^many)
  histogram;
```

### task: sort
```firth
: sort
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  dup dup prim seq-int.len 0 insertion-sort;

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs len i } {
    i len prim >=
    [ xs ]
    [
      xs i find-insertion-pos locals { j } {
        xs i j prim seq-int.at prim seq-int.set locals { new-xs } {
          i 1 prim + new-xs len i insertion-sort
        }
      }
    ]
    if
  };

: find-insertion-pos
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ position:Int^many)
  locals { xs i } {
    i 0 prim <= [ 0 ]
    [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim > [ i ] [ i 1 prim - xs find-insertion-pos ] if
    ]
    if
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  sort;
```

### task: ledger
```firth
: ledger
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  swap start 0 0 txs prim seq-int.len apply-txs;

: apply-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx len start txs } {
    idx len prim >=
    [ balance rejected ]
    [
      txs idx prim seq-int.at dup balance prim + 0 prim < locals { would-go-neg } {
        would-go-neg
        [ drop rejected 1 prim + locals { new-rejected } { idx 1 prim + balance new-rejected new-rejected len start txs apply-txs } ]
        [ balance prim + rejected locals { new-balance } { idx 1 prim + new-balance new-balance new-balance len start txs apply-txs } ]
        if
      }
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  ledger;
```

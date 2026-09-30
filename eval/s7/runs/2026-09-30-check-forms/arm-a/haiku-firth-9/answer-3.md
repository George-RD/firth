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
      xs idx prim seq-int.at sum prim + locals { newsum } {
        idx 1 prim + newsum newsum len xs sum-loop
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
  locals { xs } { xs 0 prim seq-int.at xs 1 max-iter };

: max-iter
  (forall ρ; ρ current:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { current idx xs } {
    xs prim seq-int.len idx prim >=
    [ current ]
    [
      xs idx prim seq-int.at current prim > 
      [ xs idx prim seq-int.at idx 1 prim + xs max-iter ]
      [ current idx 1 prim + xs max-iter ]
      if
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
  swap locals { xs k } { 0 0 xs prim seq-int.len count-loop };

: count-loop
  (forall ρ; ρ count:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { count idx len xs k } {
    idx len prim <
    [
      xs idx prim seq-int.at k prim < 
      [ count 1 prim + ] 
      [ count ] 
      if locals { newcount } {
        idx 1 prim + newcount newcount len xs k count-loop
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
  swap locals { xs x } { 0 xs prim seq-int.len find-loop };

: find-loop
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x } {
    idx len prim <
    [
      xs idx prim seq-int.at x prim = 
      [ idx ] 
      [ idx 1 prim + idx len xs x find-loop ] 
      if
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
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - xs reverse-loop };

: reverse-loop
  (forall ρ; ρ result:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx xs } {
    idx 0 prim >=
    [
      xs idx prim seq-int.at result prim seq-int.push locals { newresult } {
        idx 1 prim - newresult newresult xs reverse-loop
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
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix-loop };

: prefix-loop
  (forall ρ; ρ result:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at sum prim + locals { newsum } {
        result newsum prim seq-int.push locals { newresult } {
          idx 1 prim + newresult newsum newsum len xs prefix-loop
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
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len filter-pos };

: filter-pos
  (forall ρ; ρ result:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx len xs } {
    idx len prim <
    [
      xs idx prim seq-int.at dup 0 prim > 
      [ result swap prim seq-int.push ] 
      [ drop result ] 
      if locals { newresult } {
        idx 1 prim + newresult newresult len xs filter-pos
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
  locals { xs } { xs prim seq-int.len dup 1 prim <= [ drop true ] [ 1 prim - xs check-sorted ] if;

: check-sorted
  (forall ρ; ρ xs:Seq Int^many len:Int^many idx:Int^many -- ρ result:Bool^many)
  locals { xs len idx } {
    idx len prim >=
    [ true ]
    [
      xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim <= 
      [ idx 1 prim + xs len check-sorted ]
      [ false ]
      if
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
  swap locals { xs ys } { 0 0 xs prim seq-int.len dot-loop };

: dot-loop
  (forall ρ; ρ sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { sum idx len xs ys } {
    idx len prim <
    [
      xs idx prim seq-int.at ys idx prim seq-int.at prim * sum prim + locals { newsum } {
        idx 1 prim + newsum newsum len xs ys dot-loop
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
  locals { flags } { 0 flags prim seq-bool.len check-all };

: check-all
  (forall ρ; ρ idx:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { idx len flags } {
    idx len prim >=
    [ true ]
    [
      flags idx prim seq-bool.at 
      [ idx 1 prim + idx len flags check-all ]
      [ false ]
      if
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
  locals { xs } { xs prim seq-int.len 0 prim = [ 0 ] [ xs 1 1 find-longest ] if;

: find-longest
  (forall ρ; ρ xs:Seq Int^many current:Int^many max:Int^many idx:Int^many -- ρ result:Int^many)
  locals { xs current max idx } {
    xs prim seq-int.len idx prim >=
    [ max current prim > [ current ] [ max ] if ]
    [
      xs idx 1 prim - prim seq-int.at xs idx prim seq-int.at prim = 
      [ current 1 prim + ]
      [ 1 ]
      if locals { newcurrent } {
        newcurrent max prim > [ newcurrent ] [ max ] if locals { newmax } {
          xs newcurrent newmax idx 1 prim + find-longest
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
  swap locals { xs target } { 0 xs prim seq-int.len check-pairs };

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
    [ i 1 prim + i len xs target check-pairs ]
    [
      xs i prim seq-int.at xs j prim seq-int.at prim + target prim = 
      [ true ]
      [ j 1 prim + j len xs target inner-loop ]
      if
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
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len count-dist };

: count-dist
  (forall ρ; ρ seen:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen idx len xs } {
    idx len prim >=
    [ seen prim seq-int.len ]
    [
      xs idx prim seq-int.at dup seen is-in 
      [ drop ]
      [ seen swap prim seq-int.push ]
      if locals { newseen } {
        idx 1 prim + newseen newseen len xs count-dist
      }
    ]
    if
  };

: is-in
  (forall ρ; ρ val:Int^many seq:Seq Int^many -- ρ found:Bool^many)
  locals { val seq } { 0 seq prim seq-int.len check-in };

: check-in
  (forall ρ; ρ idx:Int^many len:Int^many seq:Seq Int^many val:Int^many -- ρ result:Bool^many)
  locals { idx len seq val } {
    idx len prim >=
    [ false ]
    [
      seq idx prim seq-int.at val prim = 
      [ true ]
      [ idx 1 prim + idx len seq val check-in ]
      if
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
  swap locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge-loop };

: merge-loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xlen:Int^many ylen:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i j xlen ylen xs ys } {
    i xlen prim >=
    [
      j ylen prim < 
      [ ys j prim seq-int.at result prim seq-int.push locals { r } { r j 1 prim + j ylen xs ys merge-loop } ]
      [ result ]
      if
    ]
    [
      j ylen prim >= 
      [ xs i prim seq-int.at result prim seq-int.push locals { r } { r i 1 prim + i j xlen ylen xs ys merge-loop } ]
      [
        xs i prim seq-int.at ys j prim seq-int.at prim <= 
        [ xs i prim seq-int.at result prim seq-int.push locals { r } { r i 1 prim + i j xlen ylen xs ys merge-loop } ]
        [ ys j prim seq-int.at result prim seq-int.push locals { r } { r i j 1 prim + xlen ylen xs ys merge-loop } ]
        if
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
      num 10 prim mod result prim seq-int.push locals { newresult } {
        newresult newresult num 10 prim div extract-digits
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
  locals { n } { prim seq-int.empty 2 n sieve-primes };

: sieve-primes
  (forall ρ; ρ result:Seq Int^many candidate:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result candidate n } {
    candidate n prim <=
    [
      candidate is-prime 
      [ result candidate prim seq-int.push locals { r } { r candidate 1 prim + r n sieve-primes } ]
      [ candidate 1 prim + result candidate 1 prim + n sieve-primes ]
      if
    ]
    [ result ]
    if
  };

: is-prime
  (forall ρ; ρ num:Int^many -- ρ prime:Bool^many)
  locals { num } {
    num 2 prim < 
    [ false ]
    [ num 2 prim = 
      [ true ]
      [ num 2 prim mod 0 prim = 
        [ false ]
        [ num 2 check-divisors ]
        if
      ]
      if
    ]
    if
  };

: check-divisors
  (forall ρ; ρ num:Int^many divisor:Int^many -- ρ result:Bool^many)
  locals { num divisor } {
    divisor divisor prim * num prim > 
    [ true ]
    [ num divisor prim mod 0 prim = 
      [ false ]
      [ num divisor 1 prim + check-divisors ]
      if
    ]
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
  swap locals { xs k } { prim seq-int.empty 0 k build-counts };

: build-counts
  (forall ρ; ρ result:Seq Int^many idx:Int^many k:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result idx k xs } {
    idx k prim >=
    [ result ]
    [
      idx xs count-value-eq locals { count } {
        result count prim seq-int.push locals { newresult } {
          idx 1 prim + newresult newresult k xs build-counts
        }
      }
    ]
    if
  };

: count-value-eq
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx xs } {
    0 xs prim seq-int.len 0 count-matches idx xs count-matches-helper
  };

: count-matches-helper
  (forall ρ; ρ result:Int^many idx:Int^many xs:Seq Int^many -- ρ final:Int^many)
  result;

: count-matches
  (forall ρ; ρ i:Int^many len:Int^many count:Int^many idx:Int^many xs:Seq Int^many -- ρ final:Int^many)
  locals { i len count idx xs } {
    i len prim >=
    [ count ]
    [
      xs i prim seq-int.at idx prim = 
      [ count 1 prim + ]
      [ count ]
      if locals { newcount } {
        i 1 prim + newcount newcount idx xs count-matches
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
  locals { xs } { xs xs prim seq-int.len 0 insertion-sort };

: insertion-sort
  (forall ρ; ρ xs:Seq Int^many len:Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs len i } {
    i len prim >=
    [ xs ]
    [
      xs i find-insertion-pos locals { j } {
        xs i j prim seq-int.at prim seq-int.set locals { newxs } {
          newxs len i 1 prim + insertion-sort
        }
      }
    ]
    if
  };

: find-insertion-pos
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ position:Int^many)
  locals { xs i } {
    i 0 prim <= 
    [ 0 ]
    [
      xs i 1 prim - prim seq-int.at xs i prim seq-int.at prim > 
      [ i ]
      [ xs i 1 prim - find-insertion-pos ]
      if
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
  locals { start txs } { start 0 0 txs prim seq-int.len apply-txs };

: apply-txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many start:Int^many txs:Seq Int^many -- ρ final-balance:Int^many final-rejected:Int^many)
  locals { balance rejected idx len start txs } {
    idx len prim >=
    [ balance rejected ]
    [
      txs idx prim seq-int.at dup balance prim + 0 prim < 
      [ drop rejected 1 prim + locals { newrejected } { idx 1 prim + balance newrejected newrejected len start txs apply-txs } ]
      [ balance prim + rejected locals { newbalance } { idx 1 prim + newbalance newbalance newbalance len start txs apply-txs } ]
      if
    ]
    if
  };

: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  ledger;
```

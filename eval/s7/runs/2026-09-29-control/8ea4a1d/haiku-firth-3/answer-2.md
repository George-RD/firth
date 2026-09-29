### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ total:Int^many)
  locals { xs } { 0 0 xs helper-sum };

: helper-sum
  (forall ρ; ρ sum:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { sum i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + i 1 prim + xs helper-sum
    ] [
      sum
    ] if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ largest:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at 1 xs helper-max
  };

: helper-max
  (forall ρ; ρ i:Int^many xs:Seq Int^many max:Int^many -- ρ result:Int^many)
  locals { i xs max } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at max prim < [
        xs i prim seq-int.at max i 1 prim + xs helper-max
      ] [
        max i 1 prim + xs helper-max
      ] if
    ] [
      max
    ] if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - helper-reverse
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result xs i prim seq-int.at prim seq-int.push i 1 prim - xs helper-reverse
    ] [
      result
    ] if
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
  (forall ρ; ρ result:Seq Int^many sum:Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result sum i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at sum prim + result swap prim seq-int.push swap i 1 prim + xs helper-prefix
    ] [
      result
    ] if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ positives:Seq Int^many)
  locals { xs } {
    prim seq-int.empty 0 xs helper-keep-positive
  };

: helper-keep-positive
  (forall ρ; ρ result:Seq Int^many i:Int^many xs:Seq Int^many -- ρ final:Seq Int^many)
  locals { result i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at 0 prim < [
        result i 1 prim + xs helper-keep-positive
      ] [
        xs i prim seq-int.at 0 prim = [
          result i 1 prim + xs helper-keep-positive
        ] [
          result xs i prim seq-int.at prim seq-int.push i 1 prim + xs helper-keep-positive
        ] if
      ] if
    ] [
      result
    ] if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    xs prim seq-int.len 1 prim < [
      true
    ] [
      0 xs helper-is-sorted
    ] if
  };

: helper-is-sorted
  (forall ρ; ρ i:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { i xs } {
    i xs prim seq-int.len 1 prim - prim < [
      xs i prim seq-int.at xs i 1 prim + prim seq-int.at prim < [
        false
      ] [
        i 1 prim + xs helper-is-sorted
      ] if
    ] [
      true
    ] if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim = [
      0
    ] [
      xs 0 prim seq-int.at 1 1 0 xs helper-longest-run
    ] if
  };

: helper-longest-run
  (forall ρ; ρ prev:Int^many i:Int^many current-run:Int^many max-run:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { prev i current-run max-run xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at prev prim = [
        current-run 1 prim + max-run max i 1 prim + prev xs helper-longest-run
      ] [
        current-run 1 prim + max-run max prim < [
          xs i prim seq-int.at i 1 prim + 1 current-run 1 prim + max-run max xs helper-longest-run
        ] [
          xs i prim seq-int.at i 1 prim + 1 max-run xs helper-longest-run
        ] if
      ] if
    ] [
      current-run max-run prim < [
        max-run
      ] [
        current-run
      ] if
    ] if
  };

: max
  (forall ρ; ρ a:Int^many b:Int^many -- ρ result:Int^many)
  locals { a b } {
    a b prim < [
      b
    ] [
      a
    ] if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } {
    0 xs target helper-has-pair
  };

: helper-has-pair
  (forall ρ; ρ i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { i xs target } {
    i xs prim seq-int.len prim < [
      i 1 prim + xs target helper-pair-search [
        i 1 prim + xs target helper-has-pair
      ] if
    ] [
      false
    ] if
  };

: helper-pair-search
  (forall ρ; ρ j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j xs target } {
    j xs prim seq-int.len prim < [
      xs j prim seq-int.at target prim = [
        true
      ] [
        j 1 prim + xs target helper-pair-search
      ] if
    ] [
      false
    ] if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } {
    0 0 xs helper-count-distinct
  };

: helper-count-distinct
  (forall ρ; ρ count:Int^many i:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { count i xs } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at 0 i xs helper-has-earlier [
        count i 1 prim + xs helper-count-distinct
      ] [
        count 1 prim + i 1 prim + xs helper-count-distinct
      ] if
    ] [
      count
    ] if
  };

: helper-has-earlier
  (forall ρ; ρ val:Int^many j:Int^many search-end:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { val j search-end xs } {
    j search-end prim < [
      xs j prim seq-int.at val prim = [
        true
      ] [
        j 1 prim + search-end xs helper-has-earlier
      ] if
    ] [
      false
    ] if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    n 0 prim = [
      { 0 }
    ] [
      prim seq-int.empty n helper-digits-collect
    ] if
  };

: helper-digits-collect
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result n } {
    n 0 prim = [
      result helper-reverse-digits
    ] [
      n 10 prim mod result prim seq-int.push n 10 prim div helper-digits-collect
    ] if
  };

: helper-reverse-digits
  (forall ρ; ρ xs:Seq Int^many -- ρ reversed:Seq Int^many)
  locals { xs } {
    prim seq-int.empty xs xs prim seq-int.len 1 prim - helper-reverse
  };

: helper-reverse
  (forall ρ; ρ result:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { result xs i } {
    i 0 prim < [
      result xs i prim seq-int.at prim seq-int.push i 1 prim - xs helper-reverse
    ] [
      result
    ] if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    prim seq-int.empty 2 n helper-primes-up-to
  };

: helper-primes-up-to
  (forall ρ; ρ result:Seq Int^many i:Int^many n:Int^many -- ρ final:Seq Int^many)
  locals { result i n } {
    i n prim < [
      i result helper-is-prime [
        result i prim seq-int.push
      ] [
        result
      ] if i 1 prim + n helper-primes-up-to
    ] [
      result
    ] if
  };

: helper-is-prime
  (forall ρ; ρ num:Int^many primes:Seq Int^many -- ρ result:Bool^many)
  locals { num primes } {
    0 primes num helper-check-prime
  };

: helper-check-prime
  (forall ρ; ρ i:Int^many primes:Seq Int^many num:Int^many -- ρ result:Bool^many)
  locals { i primes num } {
    i primes prim seq-int.len prim < [
      primes i prim seq-int.at dup prim * num prim < [
        true
      ] [
        num primes i prim seq-int.at prim mod 0 prim = [
          false
        ] [
          i 1 prim + primes num helper-check-prime
        ] if
      ] if
    ] [
      true
    ] if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k helper-init-histogram
    locals { counts } {
      counts xs 0 helper-build-histogram
    }
  };

: helper-init-histogram
  (forall ρ; ρ result:Seq Int^many i:Int^many k:Int^many -- ρ final:Seq Int^many)
  locals { result i k } {
    i k prim < [
      result 0 prim seq-int.push i 1 prim + k helper-init-histogram
    ] [
      result
    ] if
  };

: helper-build-histogram
  (forall ρ; ρ counts:Seq Int^many xs:Seq Int^many i:Int^many -- ρ final:Seq Int^many)
  locals { counts xs i } {
    i xs prim seq-int.len prim < [
      xs i prim seq-int.at counts swap prim seq-int.at 1 prim + xs i prim seq-int.at counts prim seq-int.set i 1 prim + helper-build-histogram
    ] [
      counts
    ] if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } {
    xs 0 helper-insertion-sort
  };

: helper-insertion-sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    i xs prim seq-int.len prim < [
      xs i helper-insert i 1 prim + helper-insertion-sort
    ] [
      xs
    ] if
  };

: helper-insert
  (forall ρ; ρ xs:Seq Int^many j:Int^many -- ρ result:Seq Int^many)
  locals { xs j } {
    j 0 prim < [
      xs
    ] [
      xs j prim seq-int.at xs j 1 prim - prim seq-int.at prim < [
        xs j prim seq-int.at xs j 1 prim - prim seq-int.at swap xs j prim seq-int.set xs j 1 prim - prim seq-int.set j 1 prim - helper-insert
      ] [
        xs
      ] if
    ] if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 items qtys whole helper-allocate-batch
  };

: helper-allocate-batch
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many i:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock-left:Seq Int^many alloc-final:Seq Int^many reasons-final:Seq Int^many)
  locals { stock allocated reasons i items qtys whole } {
    i qtys prim seq-int.len prim < [
      items i prim seq-int.at stock swap prim seq-int.at qtys i prim seq-int.at whole i prim seq-bool.at helper-allocate-one
      locals { stock-change alloc reason } {
        stock items i prim seq-int.at stock-change prim seq-int.set allocated alloc prim seq-int.push reasons reason prim seq-int.push i 1 prim + items qtys whole helper-allocate-batch
      }
    ] [
      stock allocated reasons
    ] if
  };

: helper-allocate-one
  (forall ρ; ρ item-stock:Int^many qty:Int^many needs-full:Bool^many -- ρ stock-change:Int^many alloc:Int^many reason:Int^many)
  locals { item-stock qty needs-full } {
    qty item-stock prim < [
      qty 0 0
    ] [
      item-stock 0 prim = [
        0 0 2
      ] [
        needs-full [
          0 0 3
        ] [
          item-stock item-stock 1
        ] if
      ] if
    ] if
  };
```

### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sum:Int^many)
  locals { xs } { 0 [ xs locals { s } { s xs prim seq-int.len 0 xs_loop } ] };

: xs_loop
  (forall ρ; ρ idx:Int^many len:Int^many acc:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx len acc xs } {
    [ acc ] [ xs prim seq-int.at idx prim + locals { acc2 } { idx 1 prim + len acc2 xs_loop } ] 
    idx len prim < if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ max:Int^many)
  locals { xs } {
    xs 0 prim seq-int.at
    1 xs prim seq-int.len
    [ xs prim seq-int.at locals { v } { [ v ] [ ] v prim < if } ] dip
    prim call
  };

: loop_max
  (forall ρ; ρ idx:Int^many len:Int^many cur_max:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx len cur_max xs } {
    [ cur_max ] 
    [ xs idx prim seq-int.at locals { v } { [ v ] [ cur_max ] v cur_max prim < if } locals { new_max } { idx 1 prim + len new_max xs loop_max } ]
    idx len prim < if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs prim seq-int.len [ xs k count_loop ] };

: count_loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc idx len xs k } {
    [ acc ] [ xs idx prim seq-int.at k prim < [ acc 1 prim + ] [ acc ] if locals { new_acc } { idx 1 prim + len new_acc xs k count_loop } ] idx len prim < if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ idx:Int^many)
  locals { xs x } { 0 xs prim seq-int.len x find_index };

: find_index
  (forall ρ; ρ idx:Int^many len:Int^many x:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { idx len x xs } {
    [ -1 ] [ xs idx prim seq-int.at x prim = [ idx ] [ idx 1 prim + len x xs find_index ] if ] idx len prim < if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - [ xs reverse_loop ] };

: reverse_loop
  (forall ρ; ρ idx:Int^many acc:Seq Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { idx acc xs } {
    [ acc ] [ xs idx prim seq-int.at acc prim seq-int.push locals { new_acc } { idx 1 prim - new_acc xs reverse_loop } ]
    idx 0 prim < if [ acc ] swap if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 [ xs prim seq-int.len prefix_loop ] };

: prefix_loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc sum idx xs } {
    [ acc ] [ xs idx prim seq-int.at sum prim + locals { new_sum } { acc new_sum prim seq-int.push idx 1 prim + new_sum idx xs prefix_loop } ]
    idx xs prim seq-int.len prim < if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 [ xs keep_positive_loop ] };

: keep_positive_loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc idx xs } {
    [ acc ] [ xs idx prim seq-int.at locals { v } { [ acc v prim seq-int.push ] [ acc ] v 0 prim < if locals { new_acc } { new_acc idx 1 prim + xs keep_positive_loop } } ]
    idx xs prim seq-int.len prim < if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    [ true ] [ 0 check_sorted ] xs prim seq-int.len 1 prim <= if
  };

: check_sorted
  (forall ρ; ρ idx:Int^many xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { idx xs } {
    [ true ]
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at prim < [ false ] [ idx 1 prim + xs check_sorted ] if ]
    idx xs prim seq-int.len 1 prim - prim < if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 [ xs ys dot_loop ] };

: dot_loop
  (forall ρ; ρ acc:Int^many idx:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc idx xs ys } {
    [ acc ]
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim + locals { new_acc } { new_acc idx 1 prim + xs ys dot_loop } ]
    idx xs prim seq-int.len prim < if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 [ flags all_true_loop ] };

: all_true_loop
  (forall ρ; ρ acc:Bool^many idx:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { acc idx flags } {
    [ acc ] [ flags idx prim seq-bool.at prim and locals { new_acc } { new_acc idx 1 prim + flags all_true_loop } ]
    idx flags prim seq-bool.len prim < if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    [ 0 ] [ xs 0 prim seq-int.at 1 1 longest_run_loop ] xs prim seq-int.len 1 prim > if
  };

: longest_run_loop
  (forall ρ; ρ max_len:Int^many prev_val:Int^many cur_len:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max_len prev_val cur_len idx xs } {
    [ [ max_len ] [ cur_len max_len prim < [ cur_len ] [ max_len ] if ] cur_len max_len prim < if ]
    [ xs idx prim seq-int.at locals { v } {
      [ [ [ max_len ] [ cur_len max_len prim < [ cur_len ] [ max_len ] if ] cur_len max_len prim < if prev_val 1 prim + idx 1 prim + xs longest_run_loop ] ]
      [ [ max_len ] [ cur_len max_len prim < [ cur_len ] [ max_len ] if ] cur_len max_len prim < if 1 idx 1 prim + xs longest_run_loop ]
      v prev_val prim = if
    } ]
    idx xs prim seq-int.len prim < if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 0 [ xs target find_pair_sum ] };

: find_pair_sum
  (forall ρ; ρ found:Bool^many i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i j xs target } {
    [ found ]
    [ [ j xs prim seq-int.len prim < [ xs i prim seq-int.at xs j prim seq-int.at prim + target prim = [ true ] [ true found i j 1 prim + xs target find_pair_sum ] if ] [ i 1 prim + 0 xs target find_pair_sum ] if ] [ true ] found if ]
    i xs prim seq-int.len 1 prim - prim < if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 [ xs count_distinct_loop ] };

: count_distinct_loop
  (forall ρ; ρ seen:Seq Int^many count:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen count idx xs } {
    [ [ count ] [ count 1 prim + ] seen xs idx prim seq-int.at contains_in_seq if ]
    [ xs idx prim seq-int.at seen prim seq-int.push locals { new_seen } { new_seen count idx 1 prim + xs count_distinct_loop } ]
    if
  };

: contains_in_seq
  (forall ρ; ρ acc:Bool^many i:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { acc i val seen } {
    [ acc ] [ seen i prim seq-int.at val prim = [ true ] [ i 1 prim + val seen check_contains ] if ] i seen prim seq-int.len prim < if
  };

: check_contains
  (forall ρ; ρ i:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { i val seen } {
    false i [ seen check_contains_inner ]
  };

: check_contains_inner
  (forall ρ; ρ idx:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { idx val seen } {
    [ false ] [ seen idx prim seq-int.at val prim = [ true ] [ idx 1 prim + val seen check_contains_inner ] if ] idx seen prim seq-int.len prim < if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 [ xs ys merge_loop ] };

: merge_loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j xs ys } {
    [ [ [ result xs i prim seq-int.at prim seq-int.push ] [ result ys j prim seq-int.at prim seq-int.push ] xs i prim seq-int.at ys j prim seq-int.at prim < if locals { new_result } { [ [ new_result i 1 prim + j xs ys merge_loop ] [ new_result i j 1 prim + xs ys merge_loop ] j ys prim seq-int.len prim = if ] [ [ result ] [ new_result i 1 prim + j xs ys merge_loop ] i xs prim seq-int.len prim = if ] i xs prim seq-int.len prim = if ] ]
    [ [ result xs i prim seq-int.at prim seq-int.push locals { r } { r i 1 prim + j xs ys merge_loop } ] ]
    [ [ result ] [ i xs prim seq-int.len prim = ] if ]
    i xs prim seq-int.len prim < j ys prim seq-int.len prim < prim and if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ prim seq-int.empty 0 ] [ prim seq-int.empty [ n digits_loop ] ]
    n 0 prim = if
  };

: digits_loop
  (forall ρ; ρ digits:Seq Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { digits n } {
    [ digits ] [ n 10 prim mod digits prim seq-int.push n 10 prim div [ digits prim seq-int.len digits digits_rev ] ]
    n 0 prim > if
  };

: digits_rev
  (forall ρ; ρ rev:Seq Int^many orig:Seq Int^many -- ρ result:Seq Int^many)
  locals { rev orig } {
    prim seq-int.empty orig prim seq-int.len 1 prim - [ orig rev reverse_digits ]
  };

: reverse_digits
  (forall ρ; ρ idx:Int^many result:Seq Int^many orig:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx result orig } {
    [ result ] [ orig idx prim seq-int.at result prim seq-int.push idx 1 prim - [ orig reverse_digits ] ]
    idx 0 prim < if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    [ prim seq-int.empty ] [ 2 n prim seq-int.empty sieve_loop ]
    n 2 prim < if
  };

: sieve_loop
  (forall ρ; ρ current:Int^many n:Int^many primes:Seq Int^many -- ρ result:Seq Int^many)
  locals { current n primes } {
    [ primes current prim seq-int.push ] [ current 1 prim + n primes sieve_loop ]
    current n prim < if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    [ 0 prim seq-int.empty [ prim seq-int.empty [ k histogram_init ] ] ]
  };

: histogram_init
  (forall ρ; ρ acc:Seq Int^many i:Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { acc i k } {
    [ acc ] [ acc 0 prim seq-int.push i 1 prim + k histogram_init ] i k prim < if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 0 xs prim seq-int.len [ xs insertion_sort ] };

: insertion_sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { xs i n } {
    [ xs ] [ xs i [ xs sort_insert ] ] i n prim < if
  };

: sort_insert
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    [ xs ] [ xs i 1 prim - locals { j } { xs i prim seq-int.at xs j prim seq-int.at prim < [ xs i xs j prim seq-int.at prim seq-int.set j xs prim seq-int.at prim seq-int.set j [ xs sort_insert ] ] [ xs ] if } ]
    i 0 prim > if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 [ txs apply_transactions ] };

: apply_transactions
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many txs:Seq Int^many -- ρ final_balance:Int^many final_rejected:Int^many)
  locals { balance rejected idx txs } {
    [ balance rejected ] [ txs idx prim seq-int.at locals { tx } { [ balance tx prim + rejected idx 1 prim + txs apply_transactions ] [ balance rejected 1 prim + idx 1 prim + txs apply_transactions ] balance tx prim + 0 prim < if } ]
    idx txs prim seq-int.len prim < if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  locals { stock items qtys whole } {
    stock prim seq-int.empty prim seq-int.empty 0 [ items qtys whole allocate_orders ]
  };

: allocate_orders
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final_stock:Seq Int^many final_allocated:Seq Int^many final_reasons:Seq Int^many)
  locals { stock allocated reasons idx items qtys whole } {
    [ stock allocated reasons ]
    [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at stock item prim seq-int.at locals { qty r } { [ [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item r qty prim - prim seq-int.set idx 1 prim + items qtys whole allocate_orders ] ] [ [ [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push idx 1 prim + items qtys whole allocate_orders ] ] [ [ allocated r prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set idx 1 prim + items qtys whole allocate_orders ] [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push idx 1 prim + items qtys whole allocate_orders ] whole idx prim seq-bool.at if ] ] r 0 prim = if ] qty r prim < if } } ]
    idx items prim seq-int.len prim < if
  };
```

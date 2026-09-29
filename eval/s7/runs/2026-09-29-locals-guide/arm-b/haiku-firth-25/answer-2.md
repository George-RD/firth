### task: seq-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sum:Int^many)
  locals { xs } { 0 0 xs prim seq-int.len sum_loop };

: sum_loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { acc idx len xs } {
    [ acc ]
    [ xs idx prim seq-int.at acc prim + locals { new_acc } { new_acc idx 1 prim + len xs sum_loop } ]
    idx len prim < if
  };
```

### task: seq-max
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ max:Int^many)
  locals { xs } { xs 0 prim seq-int.at 1 xs prim seq-int.len max_loop };

: max_loop
  (forall ρ; ρ cur_max:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { cur_max idx len xs } {
    [ cur_max ]
    [ xs idx prim seq-int.at locals { v } { [ cur_max ] [ v ] v cur_max prim < if locals { new_max } { new_max idx 1 prim + len xs max_loop } } ]
    idx len prim < if
  };
```

### task: count-below
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ count:Int^many)
  locals { xs k } { 0 0 xs prim seq-int.len count_loop };

: count_loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many k:Int^many -- ρ result:Int^many)
  locals { acc idx len xs k } {
    [ acc ]
    [ xs idx prim seq-int.at locals { v } { [ acc 1 prim + ] [ acc ] v k prim < if locals { new_acc } { new_acc idx 1 prim + len xs k count_loop } } ]
    idx len prim < if
  };
```

### task: index-of
```firth
: main
  (forall ρ; ρ xs:Seq Int^many x:Int^many -- ρ idx:Int^many)
  locals { xs x } { 0 xs prim seq-int.len find_idx };

: find_idx
  (forall ρ; ρ idx:Int^many len:Int^many xs:Seq Int^many x:Int^many -- ρ result:Int^many)
  locals { idx len xs x } {
    [ -1 ]
    [ xs idx prim seq-int.at locals { v } { [ idx ] [ idx 1 prim + len xs x find_idx ] v x prim = if } ]
    idx len prim < if
  };
```

### task: reverse
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ rev:Seq Int^many)
  locals { xs } { prim seq-int.empty xs prim seq-int.len 1 prim - reverse_loop };

: reverse_loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc idx xs } {
    [ acc ]
    [ xs idx prim seq-int.at acc prim seq-int.push locals { new_acc } { new_acc idx 1 prim - xs reverse_loop } ]
    idx 0 prim < if
  };
```

### task: prefix-sums
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sums:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len prefix_loop };

: prefix_loop
  (forall ρ; ρ acc:Seq Int^many sum:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc sum idx len xs } {
    [ acc ]
    [ xs idx prim seq-int.at sum prim + locals { new_sum } { acc new_sum prim seq-int.push new_sum idx 1 prim + len xs prefix_loop } ]
    idx len prim < if
  };
```

### task: keep-positive
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { xs } { prim seq-int.empty 0 xs prim seq-int.len keep_loop };

: keep_loop
  (forall ρ; ρ acc:Seq Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Seq Int^many)
  locals { acc idx len xs } {
    [ acc ]
    [ xs idx prim seq-int.at locals { v } { [ acc v prim seq-int.push ] [ acc ] v 0 prim < if locals { new_acc } { new_acc idx 1 prim + len xs keep_loop } } ]
    idx len prim < if
  };
```

### task: is-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Bool^many)
  locals { xs } {
    [ true ]
    [ 0 xs prim seq-int.len 1 prim - check_sorted_loop ]
    xs prim seq-int.len 1 prim <= if
  };

: check_sorted_loop
  (forall ρ; ρ idx:Int^many end_idx:Int^many xs:Seq Int^many -- ρ result:Bool^many)
  locals { idx end_idx xs } {
    [ true ]
    [ xs idx prim seq-int.at xs idx 1 prim + prim seq-int.at locals { a b } { [ false ] [ idx 1 prim + end_idx xs check_sorted_loop ] a b prim < if } ]
    idx end_idx prim < if
  };
```

### task: dot
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ product:Int^many)
  locals { xs ys } { 0 0 xs prim seq-int.len dot_loop };

: dot_loop
  (forall ρ; ρ acc:Int^many idx:Int^many len:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ result:Int^many)
  locals { acc idx len xs ys } {
    [ acc ]
    [ xs idx prim seq-int.at ys idx prim seq-int.at prim * acc prim + locals { new_acc } { new_acc idx 1 prim + len xs ys dot_loop } ]
    idx len prim < if
  };
```

### task: all-true
```firth
: main
  (forall ρ; ρ flags:Seq Bool^many -- ρ all:Bool^many)
  locals { flags } { true 0 flags prim seq-bool.len alltrue_loop };

: alltrue_loop
  (forall ρ; ρ acc:Bool^many idx:Int^many len:Int^many flags:Seq Bool^many -- ρ result:Bool^many)
  locals { acc idx len flags } {
    [ acc ]
    [ flags idx prim seq-bool.at acc prim and locals { new_acc } { new_acc idx 1 prim + len flags alltrue_loop } ]
    idx len prim < if
  };
```

### task: longest-run
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ length:Int^many)
  locals { xs } {
    [ 0 ]
    [ xs 0 prim seq-int.at 1 1 1 longest_loop ]
    xs prim seq-int.len 1 prim > if
  };

: longest_loop
  (forall ρ; ρ max_len:Int^many prev_val:Int^many cur_len:Int^many idx:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { max_len prev_val cur_len idx xs } {
    [ [ cur_len ] [ max_len ] cur_len max_len prim < if ]
    [ xs idx prim seq-int.at locals { v } { [ max_len prev_val 1 prim + idx 1 prim + xs longest_loop ] [ [ cur_len ] [ max_len ] cur_len max_len prim < if 1 idx 1 prim + xs longest_loop ] v prev_val prim = if } ]
    idx xs prim seq-int.len prim < if
  };
```

### task: has-pair-sum
```firth
: main
  (forall ρ; ρ xs:Seq Int^many target:Int^many -- ρ found:Bool^many)
  locals { xs target } { false 0 0 pair_sum_outer };

: pair_sum_outer
  (forall ρ; ρ found:Bool^many i:Int^many j:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { found i j xs target } {
    [ found ]
    [ j 0 pair_sum_inner ]
    i xs prim seq-int.len 1 prim - prim < if
  };

: pair_sum_inner
  (forall ρ; ρ j:Int^many i:Int^many xs:Seq Int^many target:Int^many -- ρ result:Bool^many)
  locals { j i xs target } {
    [ i 1 prim + xs prim seq-int.len pair_sum_outer ]
    [ xs i prim seq-int.at xs j prim seq-int.at prim + locals { sum } { [ true ] [ j 1 prim + i xs target pair_sum_inner ] sum target prim = if } ]
    j xs prim seq-int.len prim < if
  };
```

### task: count-distinct
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ count:Int^many)
  locals { xs } { prim seq-int.empty 0 0 xs prim seq-int.len distinct_loop };

: distinct_loop
  (forall ρ; ρ seen:Seq Int^many count:Int^many idx:Int^many len:Int^many xs:Seq Int^many -- ρ result:Int^many)
  locals { seen count idx len xs } {
    [ [ count ] [ count 1 prim + ] 0 xs idx prim seq-int.at contains_check ]
    [ xs idx prim seq-int.at seen prim seq-int.push locals { new_seen } { new_seen count 1 prim + idx 1 prim + len xs distinct_loop } ]
    if
  };

: contains_check
  (forall ρ; ρ i:Int^many val:Int^many seen:Seq Int^many -- ρ result:Bool^many)
  locals { i val seen } {
    [ false ]
    [ seen i prim seq-int.at val prim = [ true ] [ i 1 prim + val seen contains_check ] if ]
    i seen prim seq-int.len prim < if
  };
```

### task: merge-sorted
```firth
: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { xs ys } { prim seq-int.empty 0 0 xs prim seq-int.len ys prim seq-int.len merge_loop };

: merge_loop
  (forall ρ; ρ result:Seq Int^many i:Int^many j:Int^many lenx:Int^many leny:Int^many xs:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { result i j lenx leny xs ys } {
    [ result i lenx prim + j leny prim + [ xs merge_x_tail ] ]
    [ [ [ result xs i prim seq-int.at prim seq-int.push ] [ result ys j prim seq-int.at prim seq-int.push ] xs i prim seq-int.at ys j prim seq-int.at prim < if locals { r2 } { r2 i 1 prim + j lenx leny xs ys merge_loop } ] [ result j leny prim + [ ys merge_y_tail ] ] i lenx prim = if ]
    i lenx prim < j leny prim < prim and if
  };

: merge_x_tail
  (forall ρ; ρ sum:Int^many result:Seq Int^many xs:Seq Int^many -- ρ merged:Seq Int^many)
  locals { sum result xs } {
    [ result ] [ xs sum prim seq-int.at result prim seq-int.push sum 1 prim + [ xs merge_x_tail ] ] sum xs prim seq-int.len prim < if
  };

: merge_y_tail
  (forall ρ; ρ sum:Int^many result:Seq Int^many ys:Seq Int^many -- ρ merged:Seq Int^many)
  locals { sum result ys } {
    [ result ] [ ys sum prim seq-int.at result prim seq-int.push sum 1 prim + [ ys merge_y_tail ] ] sum ys prim seq-int.len prim < if
  };
```

### task: digits
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ digits:Seq Int^many)
  locals { n } {
    [ prim seq-int.empty ]
    [ prim seq-int.empty n digits_extract ]
    n 0 prim = if
  };

: digits_extract
  (forall ρ; ρ result:Seq Int^many n:Int^many -- ρ digits:Seq Int^many)
  locals { result n } {
    [ result prim seq-int.len 1 prim - [ result digits_reverse ] ]
    [ n 10 prim mod result prim seq-int.push n 10 prim div [ digits_extract ] ]
    n 0 prim > if
  };

: digits_reverse
  (forall ρ; ρ idx:Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx result } {
    [ prim seq-int.empty idx [ result reverse_one ] ]
  };

: reverse_one
  (forall ρ; ρ idx:Int^many acc:Seq Int^many result:Seq Int^many -- ρ final:Seq Int^many)
  locals { idx acc result } {
    [ acc ] [ result idx prim seq-int.at acc prim seq-int.push idx 1 prim - [ result reverse_one ] ] idx 0 prim < if
  };
```

### task: primes-up-to
```firth
: main
  (forall ρ; ρ n:Int^many -- ρ primes:Seq Int^many)
  locals { n } {
    [ prim seq-int.empty ]
    [ prim seq-int.empty 2 n sieve_candidate ]
    n 2 prim < if
  };

: sieve_candidate
  (forall ρ; ρ primes:Seq Int^many current:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { primes current n } {
    [ primes current prim seq-int.push current 1 prim + n sieve_candidate ]
    [ primes ]
    current n prim < if
  };
```

### task: histogram
```firth
: main
  (forall ρ; ρ xs:Seq Int^many k:Int^many -- ρ counts:Seq Int^many)
  locals { xs k } {
    prim seq-int.empty 0 k init_counts
  };

: init_counts
  (forall ρ; ρ acc:Seq Int^many i:Int^many k:Int^many -- ρ initialized:Seq Int^many)
  locals { acc i k } {
    [ acc 0 xs prim seq-int.len count_items ]
    [ acc 0 prim seq-int.push i 1 prim + k init_counts ]
    i k prim < if
  };

: count_items
  (forall ρ; ρ counts:Seq Int^many idx:Int^many len:Int^many -- ρ result:Seq Int^many)
  locals { counts idx len } {
    [ counts ] [ idx xs prim seq-int.at locals { v } { counts v prim seq-int.at 1 prim + counts v prim seq-int.set idx 1 prim + len count_items } ] idx len prim < if
  };
```

### task: sort
```firth
: main
  (forall ρ; ρ xs:Seq Int^many -- ρ sorted:Seq Int^many)
  locals { xs } { xs 1 xs prim seq-int.len insertion_sort };

: insertion_sort
  (forall ρ; ρ xs:Seq Int^many i:Int^many n:Int^many -- ρ result:Seq Int^many)
  locals { xs i n } {
    [ xs ] [ xs i insert_element ] i n prim < if
  };

: insert_element
  (forall ρ; ρ xs:Seq Int^many i:Int^many -- ρ result:Seq Int^many)
  locals { xs i } {
    [ xs ] [ xs i 1 prim - locals { j } { xs i prim seq-int.at xs j prim seq-int.at locals { key prev } { [ xs j key prim seq-int.set i prev prim seq-int.set j [ xs insert_element ] ] [ xs ] key prev prim < if } } ]
    i 0 prim > if
  };
```

### task: ledger
```firth
: main
  (forall ρ; ρ start:Int^many txs:Seq Int^many -- ρ balance:Int^many rejected:Int^many)
  locals { start txs } { start 0 0 txs prim seq-int.len apply_txs };

: apply_txs
  (forall ρ; ρ balance:Int^many rejected:Int^many idx:Int^many len:Int^many txs:Seq Int^many -- ρ final_balance:Int^many final_rejected:Int^many)
  locals { balance rejected idx len txs } {
    [ balance rejected ]
    [ txs idx prim seq-int.at locals { tx } { [ balance tx prim + rejected idx 1 prim + len txs apply_txs ] [ balance rejected 1 prim + idx 1 prim + len txs apply_txs ] balance tx prim + 0 prim < if } ]
    idx len prim < if
  };
```

### task: allocate-batch
```firth
: main
  (forall ρ; ρ stock:Seq Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ stock_left:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many)
  stock prim seq-int.empty prim seq-int.empty 0 items prim seq-int.len allocate_order;

: allocate_order
  (forall ρ; ρ stock:Seq Int^many allocated:Seq Int^many reasons:Seq Int^many idx:Int^many end_idx:Int^many items:Seq Int^many qtys:Seq Int^many whole:Seq Bool^many -- ρ final_stock:Seq Int^many final_allocated:Seq Int^many final_reasons:Seq Int^many)
  locals { stock allocated reasons idx end_idx items qtys whole } {
    [ stock allocated reasons ]
    [ items idx prim seq-int.at locals { item } { qtys idx prim seq-int.at stock item prim seq-int.at locals { qty cur_stock } { [ allocated qty prim seq-int.push reasons 0 prim seq-int.push stock item cur_stock qty prim - prim seq-int.set ] [ [ allocated 0 prim seq-int.push reasons 2 prim seq-int.push ] [ [ allocated cur_stock prim seq-int.push reasons 1 prim seq-int.push stock item 0 prim seq-int.set ] [ allocated 0 prim seq-int.push reasons 3 prim seq-int.push ] whole idx prim seq-bool.at if ] cur_stock 0 prim = if ] qty cur_stock prim < if locals { new_stock new_allocated new_reasons } { new_stock new_allocated new_reasons idx 1 prim + end_idx items qtys whole allocate_order } } } ]
    idx end_idx prim < if
  };
```

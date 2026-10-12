### task: bowling
```firth
: frame-two
  (forall ρ; ρ r:Seq Int^many i:Int^many -- ρ s:Int^many adv:Int^many)
  locals { r i } {
    r i prim seq-int.at r i 1 prim + prim seq-int.at prim +
    locals { s } {
      s 10 prim =
      [ 10 r i 2 prim + prim seq-int.at prim + 2 ]
      [ s 2 ]
      if
    }
  }
;

: frame-score
  (forall ρ; ρ r:Seq Int^many i:Int^many -- ρ s:Int^many adv:Int^many)
  locals { r i } {
    r i prim seq-int.at 10 prim =
    [ 10 r i 1 prim + prim seq-int.at prim + r i 2 prim + prim seq-int.at prim + 1 ]
    [ r i frame-two ]
    if
  }
;

: frames
  (forall ρ; ρ r:Seq Int^many i:Int^many f:Int^many t:Int^many out:Seq Int^many -- ρ o:Seq Int^many)
  locals { r i f t out } {
    f 10 prim =
    [ out ]
    [ r i frame-score
      locals { s adv } {
        r i adv prim + f 1 prim + t s prim + out t s prim + prim seq-int.push frames
      }
    ]
    if
  }
;

: main
  (forall ρ; ρ rolls:Seq Int^many -- ρ totals:Seq Int^many)
  0 0 0 prim seq-int.empty frames
;
```

### task: lru
```firth
: find-at
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many -- ρ j:Int^many)
  locals { xs k i } {
    xs i prim seq-int.at k prim =
    [ i ]
    [ xs k i 1 prim + find ]
    if
  }
;

: find
  (forall ρ; ρ xs:Seq Int^many k:Int^many i:Int^many -- ρ j:Int^many)
  locals { xs k i } {
    i xs prim seq-int.len prim <
    [ xs k i find-at ]
    [ -1 ]
    if
  }
;

: keep
  (forall ρ; ρ xs:Seq Int^many j:Int^many k:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs j k out } {
    k j prim =
    [ out ]
    [ out xs k prim seq-int.at prim seq-int.push ]
    if
  }
;

: drop-loop
  (forall ρ; ρ xs:Seq Int^many j:Int^many k:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs j k out } {
    k xs prim seq-int.len prim <
    [ xs j k 1 prim + xs j k out keep drop-loop ]
    [ out ]
    if
  }
;

: add-miss
  (forall ρ; ρ cache:Seq Int^many cap:Int^many key:Int^many -- ρ r:Seq Int^many)
  locals { cache cap key } {
    cache prim seq-int.len cap prim =
    [ cache 0 0 prim seq-int.empty drop-loop key prim seq-int.push ]
    [ cache key prim seq-int.push ]
    if
  }
;

: lru-step
  (forall ρ; ρ cap:Int^many keys:Seq Int^many i:Int^many m:Int^many cache:Seq Int^many -- ρ misses:Int^many out:Seq Int^many)
  locals { cap keys i m cache } {
    keys i prim seq-int.at
    locals { key } {
      cache key 0 find
      locals { j } {
        j 0 prim >=
        [ cap keys i 1 prim + m cache j 0 prim seq-int.empty drop-loop key prim seq-int.push lru-loop ]
        [ cap keys i 1 prim + m 1 prim + cache cap key add-miss lru-loop ]
        if
      }
    }
  }
;

: lru-loop
  (forall ρ; ρ cap:Int^many keys:Seq Int^many i:Int^many m:Int^many cache:Seq Int^many -- ρ misses:Int^many out:Seq Int^many)
  locals { cap keys i m cache } {
    i keys prim seq-int.len prim <
    [ cap keys i m cache lru-step ]
    [ m cache ]
    if
  }
;

: main
  (forall ρ; ρ cap:Int^many keys:Seq Int^many -- ρ misses:Int^many cache:Seq Int^many)
  0 0 prim seq-int.empty lru-loop
;
```

### task: rpn
```firth
: abs
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  dup 0 prim < [ 0 swap prim - ] [ ] if
;

: xor
  (forall ρ; ρ x:Bool^many y:Bool^many -- ρ r:Bool^many)
  locals { x y } {
    x y prim or x y prim and prim not prim and
  }
;

: tdiv
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } {
    a abs b abs prim div
    locals { q } {
      a 0 prim < b 0 prim < xor
      [ 0 q prim - ]
      [ q ]
      if
    }
  }
;

: apply3
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 3 prim =
    [ a b prim * ]
    [ a b tdiv ]
    if
  }
;

: apply2
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 2 prim =
    [ a b prim - ]
    [ a b k apply3 ]
    if
  }
;

: apply
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 1 prim =
    [ a b prim + ]
    [ a b k apply2 ]
    if
  }
;

: op-push
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    kinds vals i 1 prim + st sp vals i prim seq-int.at prim seq-int.set sp 1 prim + rpn-loop
  }
;

: op-dup
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    sp 1 prim >=
    [ kinds vals i 1 prim + st sp st sp 1 prim - prim seq-int.at prim seq-int.set sp 1 prim + rpn-loop ]
    [ 0 1 ]
    if
  }
;

: bin-go
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    st sp 2 prim - prim seq-int.at
    st sp 1 prim - prim seq-int.at
    kinds i prim seq-int.at
    locals { a b k } {
      k 4 prim = b 0 prim = prim and
      [ 0 2 ]
      [ kinds vals i 1 prim + st sp 2 prim - a b k apply prim seq-int.set sp 1 prim - rpn-loop ]
      if
    }
  }
;

: op-bin
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    sp 2 prim >=
    [ kinds vals i st sp bin-go ]
    [ 0 1 ]
    if
  }
;

: rpn-step2
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    kinds i prim seq-int.at 5 prim =
    [ kinds vals i st sp op-dup ]
    [ kinds vals i st sp op-bin ]
    if
  }
;

: rpn-step
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    kinds i prim seq-int.at 0 prim =
    [ kinds vals i st sp op-push ]
    [ kinds vals i st sp rpn-step2 ]
    if
  }
;

: rpn-end
  (forall ρ; ρ st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { st sp } {
    sp 1 prim =
    [ st 0 prim seq-int.at 0 ]
    [ 0 3 ]
    if
  }
;

: rpn-loop
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many st:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals i st sp } {
    i kinds prim seq-int.len prim <
    [ kinds vals i st sp rpn-step ]
    [ st sp rpn-end ]
    if
  }
;

: zeros
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim - acc 0 prim seq-int.push zeros ]
    [ acc ]
    if
  }
;

: main
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many -- ρ result:Int^many status:Int^many)
  locals { kinds vals } {
    kinds vals 0 kinds prim seq-int.len 1 prim + prim seq-int.empty zeros 0 rpn-loop
  }
;
```

### task: edit-cost
```firth
: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b prim <
    [ a ]
    [ b ]
    if
  }
;

: sub-cost
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many cs:Seq Int^many i:Int^many j:Int^many -- ρ c:Int^many)
  locals { xs ys cs i j } {
    xs i 1 prim - prim seq-int.at ys j 1 prim - prim seq-int.at prim =
    [ 0 ]
    [ cs 2 prim seq-int.at ]
    if
  }
;

: cell
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many cs:Seq Int^many i:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many -- ρ v:Int^many)
  locals { xs ys cs i j prev cur } {
    prev j prim seq-int.at cs 1 prim seq-int.at prim +
    cur j 1 prim - prim seq-int.at cs 0 prim seq-int.at prim +
    min2
    prev j 1 prim - prim seq-int.at xs ys cs i j sub-cost prim +
    min2
  }
;

: row-loop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many cs:Seq Int^many i:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs ys cs i j prev cur } {
    j ys prim seq-int.len prim <=
    [ xs ys cs i j 1 prim + prev cur xs ys cs i j prev cur cell prim seq-int.push row-loop ]
    [ cur ]
    if
  }
;

: rows
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many cs:Seq Int^many i:Int^many prev:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs ys cs i prev } {
    i xs prim seq-int.len prim <=
    [ xs ys cs i 1 prim +
      xs ys cs i 1 prev prim seq-int.empty i cs 1 prim seq-int.at prim * prim seq-int.push row-loop
      rows ]
    [ prev ]
    if
  }
;

: init-row
  (forall ρ; ρ n:Int^many ins:Int^many j:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { n ins j acc } {
    j n prim <=
    [ n ins j 1 prim + acc j ins prim * prim seq-int.push init-row ]
    [ acc ]
    if
  }
;

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many insert:Int^many delete:Int^many replace:Int^many -- ρ cost:Int^many)
  locals { xs ys ins del rep } {
    prim seq-int.empty ins prim seq-int.push del prim seq-int.push rep prim seq-int.push
    locals { cs } {
      xs ys cs 1
      ys prim seq-int.len ins 0 prim seq-int.empty init-row
      rows
      locals { final } {
        final ys prim seq-int.len prim seq-int.at
      }
    }
  }
;
```

### task: shortest-hops
```firth
: relax
  (forall ρ; ρ froms:Seq Int^many tos:Seq Int^many ws:Seq Int^many k:Int^many dist:Seq Int^many hops:Seq Int^many -- ρ dist2:Seq Int^many hops2:Seq Int^many)
  locals { froms tos ws k dist hops } {
    froms k prim seq-int.at
    tos k prim seq-int.at
    locals { u v } {
      dist u prim seq-int.at ws k prim seq-int.at prim +
      hops u prim seq-int.at 1 prim +
      locals { nd nh } {
        dist u prim seq-int.at 0 prim >=
        dist v prim seq-int.at -1 prim =
        nd dist v prim seq-int.at prim <
        prim or
        nd dist v prim seq-int.at prim =
        nh hops v prim seq-int.at prim <
        prim and
        prim or
        prim and
        [ dist v nd prim seq-int.set hops v nh prim seq-int.set ]
        [ dist hops ]
        if
      }
    }
  }
;

: pass
  (forall ρ; ρ froms:Seq Int^many tos:Seq Int^many ws:Seq Int^many k:Int^many dist:Seq Int^many hops:Seq Int^many -- ρ dist2:Seq Int^many hops2:Seq Int^many)
  locals { froms tos ws k dist hops } {
    k froms prim seq-int.len prim <
    [ froms tos ws k 1 prim + froms tos ws k dist hops relax pass ]
    [ dist hops ]
    if
  }
;

: rounds
  (forall ρ; ρ froms:Seq Int^many tos:Seq Int^many ws:Seq Int^many r:Int^many dist:Seq Int^many hops:Seq Int^many -- ρ dist2:Seq Int^many hops2:Seq Int^many)
  locals { froms tos ws r dist hops } {
    r 0 prim >
    [ froms tos ws r 1 prim - froms tos ws 0 dist hops pass rounds ]
    [ dist hops ]
    if
  }
;

: fill
  (forall ρ; ρ n:Int^many v:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { n v acc } {
    n 0 prim >
    [ n 1 prim - v acc v prim seq-int.push fill ]
    [ acc ]
    if
  }
;

: main
  (forall ρ; ρ n:Int^many froms:Seq Int^many tos:Seq Int^many weights:Seq Int^many source:Int^many -- ρ dist:Seq Int^many hops:Seq Int^many)
  locals { n froms tos ws s } {
    froms tos ws n 1 prim -
    n -1 prim seq-int.empty fill s 0 prim seq-int.set
    n -1 prim seq-int.empty fill s 0 prim seq-int.set
    rounds
  }
;
```

### task: merge-ranges
```firth
: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } {
    a b prim >
    [ a ]
    [ b ]
    if
  }
;

: sift2
  (forall ρ; ρ ss:Seq Int^many es:Seq Int^many j:Int^many -- ρ ss2:Seq Int^many es2:Seq Int^many)
  locals { ss es j } {
    ss j 1 prim - prim seq-int.at ss j prim seq-int.at prim >
    [ ss j 1 prim - ss j prim seq-int.at prim seq-int.set
      j ss j 1 prim - prim seq-int.at prim seq-int.set
      es j 1 prim - es j prim seq-int.at prim seq-int.set
      j es j 1 prim - prim seq-int.at prim seq-int.set
      j 1 prim - sift ]
    [ ss es ]
    if
  }
;

: sift
  (forall ρ; ρ ss:Seq Int^many es:Seq Int^many j:Int^many -- ρ ss2:Seq Int^many es2:Seq Int^many)
  locals { ss es j } {
    j 0 prim >
    [ ss es j sift2 ]
    [ ss es ]
    if
  }
;

: isort
  (forall ρ; ρ ss:Seq Int^many es:Seq Int^many i:Int^many -- ρ ss2:Seq Int^many es2:Seq Int^many)
  locals { ss es i } {
    i ss prim seq-int.len prim <
    [ ss es i sift i 1 prim + isort ]
    [ ss es ]
    if
  }
;

: merge-step
  (forall ρ; ρ ss:Seq Int^many es:Seq Int^many i:Int^many os:Seq Int^many oe:Seq Int^many -- ρ os2:Seq Int^many oe2:Seq Int^many)
  locals { ss es i os oe } {
    oe oe prim seq-int.len 1 prim - prim seq-int.at
    locals { ce } {
      ss i prim seq-int.at ce 1 prim + prim <=
      [ ss es i 1 prim + os
        oe oe prim seq-int.len 1 prim - ce es i prim seq-int.at max2 prim seq-int.set
        merge-loop ]
      [ ss es i 1 prim + os ss i prim seq-int.at prim seq-int.push oe es i prim seq-int.at prim seq-int.push merge-loop ]
      if
    }
  }
;

: merge-loop
  (forall ρ; ρ ss:Seq Int^many es:Seq Int^many i:Int^many os:Seq Int^many oe:Seq Int^many -- ρ os2:Seq Int^many oe2:Seq Int^many)
  locals { ss es i os oe } {
    i ss prim seq-int.len prim <
    [ ss es i os oe merge-step ]
    [ os oe ]
    if
  }
;

: cover
  (forall ρ; ρ os:Seq Int^many oe:Seq Int^many k:Int^many acc:Int^many -- ρ r:Int^many)
  locals { os oe k acc } {
    k os prim seq-int.len prim <
    [ os oe k 1 prim + acc oe k prim seq-int.at os k prim seq-int.at prim - 1 prim + prim + cover ]
    [ acc ]
    if
  }
;

: merge-main
  (forall ρ; ρ ss:Seq Int^many es:Seq Int^many -- ρ os:Seq Int^many oe:Seq Int^many cov:Int^many)
  locals { ss es } {
    ss es 1 isort
    locals { s2 e2 } {
      s2 e2 1
      prim seq-int.empty s2 0 prim seq-int.at prim seq-int.push
      prim seq-int.empty e2 0 prim seq-int.at prim seq-int.push
      merge-loop
      locals { os oe } {
        os oe os oe 0 0 cover
      }
    }
  }
;

: main
  (forall ρ; ρ starts:Seq Int^many ends:Seq Int^many -- ρ ms:Seq Int^many me:Seq Int^many covered:Int^many)
  locals { ss es } {
    ss prim seq-int.len 0 prim =
    [ prim seq-int.empty prim seq-int.empty 0 ]
    [ ss es merge-main ]
    if
  }
;
```

### task: tiny-vm
```firth
: jump
  (forall ρ; ρ c:Bool^many pc:Int^many b:Int^many -- ρ r:Int^many)
  locals { c pc b } {
    c
    [ b ]
    [ pc 1 prim + ]
    if
  }
;

: next-pc2
  (forall ρ; ρ regs:Seq Int^many pc:Int^many op:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  locals { regs pc op a b } {
    op 7 prim =
    [ regs a prim seq-int.at 0 prim < pc b jump ]
    [ pc 1 prim + ]
    if
  }
;

: next-pc
  (forall ρ; ρ regs:Seq Int^many pc:Int^many op:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  locals { regs pc op a b } {
    op 6 prim =
    [ regs a prim seq-int.at 0 prim = prim not pc b jump ]
    [ regs pc op a b next-pc2 ]
    if
  }
;

: alu3
  (forall ρ; ρ x:Int^many y:Int^many op:Int^many -- ρ v:Int^many)
  locals { x y op } {
    op 4 prim =
    [ x y prim * ]
    [ y ]
    if
  }
;

: alu2
  (forall ρ; ρ x:Int^many y:Int^many op:Int^many -- ρ v:Int^many)
  locals { x y op } {
    op 3 prim =
    [ x y prim - ]
    [ x y op alu3 ]
    if
  }
;

: alu
  (forall ρ; ρ x:Int^many y:Int^many op:Int^many -- ρ v:Int^many)
  locals { x y op } {
    op 2 prim =
    [ x y prim + ]
    [ x y op alu2 ]
    if
  }
;

: regs-step2
  (forall ρ; ρ regs:Seq Int^many op:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { regs op a b } {
    op 2 prim >= op 5 prim <= prim and
    [ regs a regs a prim seq-int.at regs b prim seq-int.at op alu prim seq-int.set ]
    [ regs ]
    if
  }
;

: regs-step
  (forall ρ; ρ regs:Seq Int^many op:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { regs op a b } {
    op 1 prim =
    [ regs a b prim seq-int.set ]
    [ regs op a b regs-step2 ]
    if
  }
;

: vm-exec
  (forall ρ; ρ code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many limit:Int^many -- ρ regs-out:Seq Int^many executed:Int^many status:Int^many)
  locals { code regs pc cnt limit } {
    code pc 3 prim * prim seq-int.at
    code pc 3 prim * 1 prim + prim seq-int.at
    code pc 3 prim * 2 prim + prim seq-int.at
    locals { op a b } {
      op 0 prim =
      [ regs cnt 0 ]
      [ code regs op a b regs-step regs pc op a b next-pc cnt limit vm-loop ]
      if
    }
  }
;

: vm-chk
  (forall ρ; ρ code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many limit:Int^many -- ρ regs-out:Seq Int^many executed:Int^many status:Int^many)
  locals { code regs pc cnt limit } {
    cnt limit prim >=
    [ regs cnt 2 ]
    [ code regs pc cnt 1 prim + limit vm-exec ]
    if
  }
;

: vm-loop
  (forall ρ; ρ code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many limit:Int^many -- ρ regs-out:Seq Int^many executed:Int^many status:Int^many)
  locals { code regs pc cnt limit } {
    pc 0 prim >= pc code prim seq-int.len 3 prim div prim < prim and
    [ code regs pc cnt limit vm-chk ]
    [ regs cnt 1 ]
    if
  }
;

: main
  (forall ρ; ρ code:Seq Int^many regs:Seq Int^many limit:Int^many -- ρ regs-out:Seq Int^many executed:Int^many status:Int^many)
  locals { code regs limit } {
    code regs 0 0 limit vm-loop
  }
;
```

### task: lis-smallest
```firth
: zeros
  (forall ρ; ρ n:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim - acc 0 prim seq-int.push zeros ]
    [ acc ]
    if
  }
;

: scan-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many t:Int^many j:Int^many best:Int^many bl:Int^many bx:Int^many -- ρ r:Int^many)
  locals { xs ls t j best bl bx } {
    xs j prim seq-int.at ls j prim seq-int.at
    locals { xj lj } {
      xj t prim >
      lj bl prim >
      lj bl prim =
      xj bx prim <
      prim and
      prim or
      prim and
      [ xs ls t j 1 prim + j lj xj scan ]
      [ xs ls t j 1 prim + best bl bx scan ]
      if
    }
  }
;

: scan
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many t:Int^many j:Int^many best:Int^many bl:Int^many bx:Int^many -- ρ r:Int^many)
  locals { xs ls t j best bl bx } {
    j xs prim seq-int.len prim <
    [ xs ls t j best bl bx scan-step ]
    [ best ]
    if
  }
;

: dp-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many nx:Seq Int^many i:Int^many -- ρ ls2:Seq Int^many nx2:Seq Int^many)
  locals { xs ls nx i } {
    xs ls xs i prim seq-int.at i 1 prim + -1 0 0 scan
    locals { b } {
      b 0 prim >=
      [ xs ls i 1 ls b prim seq-int.at prim + prim seq-int.set nx i b prim seq-int.set i 1 prim - dp ]
      [ xs ls i 1 prim seq-int.set nx i -1 prim seq-int.set i 1 prim - dp ]
      if
    }
  }
;

: dp
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many nx:Seq Int^many i:Int^many -- ρ ls2:Seq Int^many nx2:Seq Int^many)
  locals { xs ls nx i } {
    i 0 prim >=
    [ xs ls nx i dp-step ]
    [ ls nx ]
    if
  }
;

: start-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many j:Int^many best:Int^many bl:Int^many bx:Int^many -- ρ r:Int^many)
  locals { xs ls j best bl bx } {
    xs j prim seq-int.at ls j prim seq-int.at
    locals { xj lj } {
      lj bl prim >
      lj bl prim =
      xj bx prim <
      prim and
      prim or
      [ xs ls j 1 prim + j lj xj start-scan ]
      [ xs ls j 1 prim + best bl bx start-scan ]
      if
    }
  }
;

: start-scan
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many j:Int^many best:Int^many bl:Int^many bx:Int^many -- ρ r:Int^many)
  locals { xs ls j best bl bx } {
    j xs prim seq-int.len prim <
    [ xs ls j best bl bx start-step ]
    [ best ]
    if
  }
;

: emit
  (forall ρ; ρ xs:Seq Int^many nx:Seq Int^many cur:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs nx cur out } {
    cur 0 prim >=
    [ xs nx nx cur prim seq-int.at out xs cur prim seq-int.at prim seq-int.push emit ]
    [ out ]
    if
  }
;

: lis
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len prim seq-int.empty zeros
    xs prim seq-int.len prim seq-int.empty zeros
    xs prim seq-int.len 1 prim -
    dp
    locals { ls nx } {
      xs nx xs ls 0 -1 0 0 start-scan prim seq-int.empty emit
    }
  }
;

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ lis:Seq Int^many)
  locals { xs } {
    xs prim seq-int.len 0 prim =
    [ prim seq-int.empty ]
    [ xs lis ]
    if
  }
;
```

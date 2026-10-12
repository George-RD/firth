### task: bowling
```firth
: main
  (forall ρ; ρ rolls:Seq Int -- ρ totals:Seq Int)
  0 0 0 prim seq-int.empty bowl-loop;

: bowl-loop
  (forall ρ; ρ rolls:Seq Int p:Int f:Int t:Int out:Seq Int -- ρ totals:Seq Int)
  locals { rolls p f t out } {
    f 9 prim =
    [ out t rolls p rest-sum prim + prim seq-int.push ]
    [ rolls p bowl-step
      locals { score adv } {
        rolls p adv prim + f 1 prim + t score prim + out t score prim + prim seq-int.push bowl-loop
      } ]
    if
  };

: bowl-step
  (forall ρ; ρ rolls:Seq Int p:Int -- ρ score:Int adv:Int)
  locals { rolls p } {
    rolls p prim seq-int.at
    locals { r1 } {
      r1 10 prim =
      [ 10 rolls p 1 prim + prim seq-int.at prim + rolls p 2 prim + prim seq-int.at prim + 1 ]
      [ rolls p 1 prim + prim seq-int.at
        locals { r2 } {
          r1 r2 prim + 10 prim =
          [ 10 rolls p 2 prim + prim seq-int.at prim + 2 ]
          [ r1 r2 prim + 2 ]
          if
        } ]
      if
    }
  };

: rest-sum
  (forall ρ; ρ rolls:Seq Int p:Int -- ρ total:Int)
  0 rest-sum-loop;

: rest-sum-loop
  (forall ρ; ρ rolls:Seq Int p:Int acc:Int -- ρ total:Int)
  locals { rolls p acc } {
    p rolls prim seq-int.len prim <
    [ rolls p 1 prim + acc rolls p prim seq-int.at prim + rest-sum-loop ]
    [ acc ]
    if
  };
```

### task: lru
```firth
: main
  (forall ρ; ρ cap:Int keys:Seq Int -- ρ misses:Int cache:Seq Int)
  0 0 prim seq-int.empty lru-loop;

: lru-loop
  (forall ρ; ρ cap:Int keys:Seq Int i:Int misses:Int cache:Seq Int -- ρ nmisses:Int ncache:Seq Int)
  locals { cap keys i misses cache } {
    i keys prim seq-int.len prim <
    [ keys i prim seq-int.at
      locals { k } {
        cache k 0 find-loop
        locals { idx } {
          idx 0 prim >=
          [ cap keys i 1 prim + misses cache idx remove-at k prim seq-int.push lru-loop ]
          [ cache prim seq-int.len cap prim >=
            [ cap keys i 1 prim + misses 1 prim + cache 0 remove-at k prim seq-int.push lru-loop ]
            [ cap keys i 1 prim + misses 1 prim + cache k prim seq-int.push lru-loop ]
            if ]
          if
        }
      } ]
    [ misses cache ]
    if
  };

: find-loop
  (forall ρ; ρ xs:Seq Int k:Int j:Int -- ρ idx:Int)
  locals { xs k j } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at k prim =
      [ j ]
      [ xs k j 1 prim + find-loop ]
      if ]
    [ -1 ]
    if
  };

: remove-at
  (forall ρ; ρ xs:Seq Int i:Int -- ρ ys:Seq Int)
  0 prim seq-int.empty remove-loop;

: remove-loop
  (forall ρ; ρ xs:Seq Int i:Int j:Int out:Seq Int -- ρ ys:Seq Int)
  locals { xs i j out } {
    j xs prim seq-int.len prim <
    [ j i prim =
      [ xs i j 1 prim + out remove-loop ]
      [ xs i j 1 prim + out xs j prim seq-int.at prim seq-int.push remove-loop ]
      if ]
    [ out ]
    if
  };
```

### task: rpn
```firth
: main
  (forall ρ; ρ kinds:Seq Int vals:Seq Int -- ρ result:Int status:Int)
  0 prim seq-int.empty 0 rpn-loop;

: rpn-loop
  (forall ρ; ρ kinds:Seq Int vals:Seq Int i:Int st:Seq Int sp:Int -- ρ result:Int status:Int)
  locals { kinds vals i st sp } {
    i kinds prim seq-int.len prim <
    [ kinds i prim seq-int.at
      locals { kind } {
        kind 0 prim =
        [ kinds vals i 1 prim + st sp vals i prim seq-int.at put sp 1 prim + rpn-loop ]
        [ kind 5 prim =
          [ sp 1 prim <
            [ 0 1 ]
            [ kinds vals i 1 prim + st sp st sp 1 prim - prim seq-int.at put sp 1 prim + rpn-loop ]
            if ]
          [ sp 2 prim <
            [ 0 1 ]
            [ kinds vals i 1 prim + st sp kind rpn-binop ]
            if ]
          if ]
        if
      } ]
    [ sp 1 prim =
      [ st 0 prim seq-int.at 0 ]
      [ 0 3 ]
      if ]
    if
  };

: rpn-binop
  (forall ρ; ρ kinds:Seq Int vals:Seq Int i:Int st:Seq Int sp:Int kind:Int -- ρ result:Int status:Int)
  locals { kinds vals i st sp kind } {
    st sp 2 prim - prim seq-int.at
    st sp 1 prim - prim seq-int.at
    locals { a b } {
      kind 4 prim = b 0 prim = prim and
      [ 0 2 ]
      [ kinds vals i st sp 2 prim - kind a b rpn-apply put sp 1 prim - rpn-loop ]
      if
    }
  };

: rpn-apply
  (forall ρ; ρ kind:Int a:Int b:Int -- ρ r:Int)
  locals { kind a b } {
    kind 1 prim =
    [ a b prim + ]
    [ kind 2 prim =
      [ a b prim - ]
      [ kind 3 prim =
        [ a b prim * ]
        [ a b trunc-div ]
        if ]
      if ]
    if
  };

: put
  (forall ρ; ρ st:Seq Int sp:Int v:Int -- ρ st2:Seq Int)
  locals { st sp v } {
    sp st prim seq-int.len prim <
    [ st sp v prim seq-int.set ]
    [ st v prim seq-int.push ]
    if
  };

: iabs
  (forall ρ; ρ x:Int -- ρ r:Int)
  locals { x } {
    x 0 prim <
    [ 0 x prim - ]
    [ x ]
    if
  };

: trunc-div
  (forall ρ; ρ a:Int b:Int -- ρ q:Int)
  locals { a b } {
    a 0 prim < b 0 prim >= prim and
    a 0 prim >= b 0 prim < prim and
    prim or
    [ 0 a iabs b iabs prim div prim - ]
    [ a iabs b iabs prim div ]
    if
  };
```

### task: edit-cost
```firth
: main
  (forall ρ; ρ xs:Seq Int ys:Seq Int ins:Int del:Int rep:Int -- ρ cost:Int)
  locals { xs ys ins del rep } {
    xs ys
    prim seq-int.empty ins prim seq-int.push del prim seq-int.push rep prim seq-int.push
    1
    ys prim seq-int.len ins init-row
    edit-loop
    ys prim seq-int.len prim seq-int.at
  };

: edit-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int cs:Seq Int i:Int prev:Seq Int -- ρ row:Seq Int)
  locals { xs ys cs i prev } {
    i xs prim seq-int.len prim <=
    [ xs ys cs i 1 prim +
      xs ys cs i 1 prev
      prim seq-int.empty i cs 1 prim seq-int.at prim * prim seq-int.push
      row-loop
      edit-loop ]
    [ prev ]
    if
  };

: row-loop
  (forall ρ; ρ xs:Seq Int ys:Seq Int cs:Seq Int i:Int j:Int prev:Seq Int cur:Seq Int -- ρ row:Seq Int)
  locals { xs ys cs i j prev cur } {
    j ys prim seq-int.len prim <=
    [ xs ys cs i j 1 prim + prev
      cur
      prev j prim seq-int.at cs 1 prim seq-int.at prim +
      cur j 1 prim - prim seq-int.at cs 0 prim seq-int.at prim +
      imin
      prev j 1 prim - prim seq-int.at
      xs i 1 prim - prim seq-int.at ys j 1 prim - prim seq-int.at prim =
      [ 0 ]
      [ cs 2 prim seq-int.at ]
      if
      prim +
      imin
      prim seq-int.push
      row-loop ]
    [ cur ]
    if
  };

: init-row
  (forall ρ; ρ n:Int ins:Int -- ρ row:Seq Int)
  0 prim seq-int.empty init-loop;

: init-loop
  (forall ρ; ρ n:Int ins:Int j:Int out:Seq Int -- ρ row:Seq Int)
  locals { n ins j out } {
    j n prim <=
    [ n ins j 1 prim + out j ins prim * prim seq-int.push init-loop ]
    [ out ]
    if
  };

: imin
  (forall ρ; ρ a:Int b:Int -- ρ m:Int)
  locals { a b } {
    a b prim <
    [ a ]
    [ b ]
    if
  };
```

### task: shortest-hops
```firth
: main
  (forall ρ; ρ n:Int froms:Seq Int tos:Seq Int weights:Seq Int source:Int -- ρ dist:Seq Int hops:Seq Int)
  locals { n froms tos weights source } {
    froms tos weights 0 n
    n -1 fill source 0 prim seq-int.set
    n -1 fill source 0 prim seq-int.set
    rounds-loop
  };

: rounds-loop
  (forall ρ; ρ froms:Seq Int tos:Seq Int ws:Seq Int r:Int n:Int dist:Seq Int hops:Seq Int -- ρ dist2:Seq Int hops2:Seq Int)
  locals { froms tos ws r n dist hops } {
    r n prim <
    [ froms tos ws r 1 prim + n froms tos ws 0 dist hops edges-loop rounds-loop ]
    [ dist hops ]
    if
  };

: edges-loop
  (forall ρ; ρ froms:Seq Int tos:Seq Int ws:Seq Int k:Int dist:Seq Int hops:Seq Int -- ρ dist2:Seq Int hops2:Seq Int)
  locals { froms tos ws k dist hops } {
    k froms prim seq-int.len prim <
    [ froms tos ws k 1 prim + froms tos ws k dist hops relax-edge edges-loop ]
    [ dist hops ]
    if
  };

: relax-edge
  (forall ρ; ρ froms:Seq Int tos:Seq Int ws:Seq Int k:Int dist:Seq Int hops:Seq Int -- ρ dist2:Seq Int hops2:Seq Int)
  locals { froms tos ws k dist hops } {
    froms k prim seq-int.at
    tos k prim seq-int.at
    locals { u v } {
      dist u prim seq-int.at 0 prim <
      [ dist hops ]
      [ dist u prim seq-int.at ws k prim seq-int.at prim +
        hops u prim seq-int.at 1 prim +
        locals { nd nh } {
          dist v prim seq-int.at 0 prim <
          dist v prim seq-int.at nd prim >
          prim or
          dist v prim seq-int.at nd prim =
          hops v prim seq-int.at nh prim >
          prim and
          prim or
          [ dist v nd prim seq-int.set hops v nh prim seq-int.set ]
          [ dist hops ]
          if
        } ]
      if
    }
  };

: fill
  (forall ρ; ρ n:Int v:Int -- ρ s:Seq Int)
  0 prim seq-int.empty fill-loop;

: fill-loop
  (forall ρ; ρ n:Int v:Int j:Int out:Seq Int -- ρ s:Seq Int)
  locals { n v j out } {
    j n prim <
    [ n v j 1 prim + out v prim seq-int.push fill-loop ]
    [ out ]
    if
  };
```

### task: merge-ranges
```firth
: main
  (forall ρ; ρ starts:Seq Int ends:Seq Int -- ρ ms:Seq Int me:Seq Int covered:Int)
  locals { starts ends } {
    starts prim seq-int.len 0 prim =
    [ prim seq-int.empty prim seq-int.empty 0 ]
    [ starts ends 1 sort-outer
      locals { s e } {
        s e 1 s 0 prim seq-int.at e 0 prim seq-int.at prim seq-int.empty prim seq-int.empty merge-loop
        locals { rs re } {
          rs re rs re 0 0 cover
        }
      } ]
    if
  };

: merge-loop
  (forall ρ; ρ s:Seq Int e:Seq Int k:Int cs:Int ce:Int os:Seq Int oe:Seq Int -- ρ ms:Seq Int me:Seq Int)
  locals { s e k cs ce os oe } {
    k s prim seq-int.len prim <
    [ s k prim seq-int.at ce 1 prim + prim <=
      [ s e k 1 prim + cs ce e k prim seq-int.at imax os oe merge-loop ]
      [ s e k 1 prim + s k prim seq-int.at e k prim seq-int.at os cs prim seq-int.push oe ce prim seq-int.push merge-loop ]
      if ]
    [ os cs prim seq-int.push oe ce prim seq-int.push ]
    if
  };

: cover
  (forall ρ; ρ os:Seq Int oe:Seq Int j:Int acc:Int -- ρ total:Int)
  locals { os oe j acc } {
    j os prim seq-int.len prim <
    [ os oe j 1 prim + acc oe j prim seq-int.at prim + os j prim seq-int.at prim - 1 prim + cover ]
    [ acc ]
    if
  };

: sort-outer
  (forall ρ; ρ s:Seq Int e:Seq Int i:Int -- ρ s2:Seq Int e2:Seq Int)
  locals { s e i } {
    i s prim seq-int.len prim <
    [ s e i sort-inner i 1 prim + sort-outer ]
    [ s e ]
    if
  };

: sort-inner
  (forall ρ; ρ s:Seq Int e:Seq Int j:Int -- ρ s2:Seq Int e2:Seq Int)
  locals { s e j } {
    j 0 prim >
    [ s j 1 prim - prim seq-int.at s j prim seq-int.at prim >
      [ s j swap-at e j swap-at j 1 prim - sort-inner ]
      [ s e ]
      if ]
    [ s e ]
    if
  };

: swap-at
  (forall ρ; ρ xs:Seq Int j:Int -- ρ ys:Seq Int)
  locals { xs j } {
    xs j 1 prim - xs j prim seq-int.at prim seq-int.set
    j xs j 1 prim - prim seq-int.at prim seq-int.set
  };

: imax
  (forall ρ; ρ a:Int b:Int -- ρ m:Int)
  locals { a b } {
    a b prim >
    [ a ]
    [ b ]
    if
  };
```

### task: tiny-vm
```firth
: main
  (forall ρ; ρ code:Seq Int regs:Seq Int limit:Int -- ρ out:Seq Int executed:Int status:Int)
  locals { code regs limit } {
    code regs 0 0 limit vm-loop
  };

: vm-loop
  (forall ρ; ρ code:Seq Int regs:Seq Int pc:Int count:Int limit:Int -- ρ out:Seq Int executed:Int status:Int)
  locals { code regs pc count limit } {
    pc 0 prim >=
    pc code prim seq-int.len 3 prim div prim <
    prim and
    [ count limit prim >=
      [ regs count 2 ]
      [ code pc 3 prim * prim seq-int.at
        code pc 3 prim * 1 prim + prim seq-int.at
        code pc 3 prim * 2 prim + prim seq-int.at
        locals { op a b } {
          op 0 prim =
          [ regs count 1 prim + 0 ]
          [ code regs op a b new-regs regs pc op a b new-pc count 1 prim + limit vm-loop ]
          if
        } ]
      if ]
    [ regs count 1 ]
    if
  };

: new-regs
  (forall ρ; ρ regs:Seq Int op:Int a:Int b:Int -- ρ out:Seq Int)
  locals { regs op a b } {
    op 1 prim =
    [ regs a b prim seq-int.set ]
    [ op 2 prim =
      [ regs a regs a prim seq-int.at regs b prim seq-int.at prim + prim seq-int.set ]
      [ op 3 prim =
        [ regs a regs a prim seq-int.at regs b prim seq-int.at prim - prim seq-int.set ]
        [ op 4 prim =
          [ regs a regs a prim seq-int.at regs b prim seq-int.at prim * prim seq-int.set ]
          [ op 5 prim =
            [ regs a regs b prim seq-int.at prim seq-int.set ]
            [ regs ]
            if ]
          if ]
        if ]
      if ]
    if
  };

: new-pc
  (forall ρ; ρ regs:Seq Int pc:Int op:Int a:Int b:Int -- ρ npc:Int)
  locals { regs pc op a b } {
    op 6 prim =
    [ regs a prim seq-int.at 0 prim =
      [ pc 1 prim + ]
      [ b ]
      if ]
    [ op 7 prim =
      [ regs a prim seq-int.at 0 prim <
        [ b ]
        [ pc 1 prim + ]
        if ]
      [ pc 1 prim + ]
      if ]
    if
  };
```

### task: lis-smallest
```firth
: main
  (forall ρ; ρ xs:Seq Int -- ρ lis:Seq Int)
  locals { xs } {
    xs xs prim seq-int.len 1 prim - xs prim seq-int.len 0 fill f-loop
    locals { f } {
      xs f f 0 0 maxseq -1 prim seq-int.empty build-loop
    }
  };

: f-loop
  (forall ρ; ρ xs:Seq Int i:Int f:Seq Int -- ρ f2:Seq Int)
  locals { xs i f } {
    i 0 prim >=
    [ xs i 1 prim - f i xs f i i 1 prim + 0 fbest-loop 1 prim + prim seq-int.set f-loop ]
    [ f ]
    if
  };

: fbest-loop
  (forall ρ; ρ xs:Seq Int f:Seq Int i:Int j:Int m:Int -- ρ best:Int)
  locals { xs f i j m } {
    j xs prim seq-int.len prim <
    [ xs j prim seq-int.at xs i prim seq-int.at prim >
      [ xs f i j 1 prim + m f j prim seq-int.at imax fbest-loop ]
      [ xs f i j 1 prim + m fbest-loop ]
      if ]
    [ m ]
    if
  };

: maxseq
  (forall ρ; ρ f:Seq Int j:Int m:Int -- ρ best:Int)
  locals { f j m } {
    j f prim seq-int.len prim <
    [ f j 1 prim + m f j prim seq-int.at imax maxseq ]
    [ m ]
    if
  };

: build-loop
  (forall ρ; ρ xs:Seq Int f:Seq Int rem:Int prev:Int out:Seq Int -- ρ lis:Seq Int)
  locals { xs f rem prev out } {
    rem 0 prim >
    [ xs f rem prev prev 1 prim + -1 pick-loop
      locals { idx } {
        xs f rem 1 prim - idx out xs idx prim seq-int.at prim seq-int.push build-loop
      } ]
    [ out ]
    if
  };

: pick-loop
  (forall ρ; ρ xs:Seq Int f:Seq Int rem:Int prev:Int j:Int best:Int -- ρ idx:Int)
  locals { xs f rem prev j best } {
    j xs prim seq-int.len prim <
    [ xs f rem prev j cand-ok
      [ best 0 prim <
        [ xs f rem prev j 1 prim + j pick-loop ]
        [ xs j prim seq-int.at xs best prim seq-int.at prim <
          [ xs f rem prev j 1 prim + j pick-loop ]
          [ xs f rem prev j 1 prim + best pick-loop ]
          if ]
        if ]
      [ xs f rem prev j 1 prim + best pick-loop ]
      if ]
    [ best ]
    if
  };

: cand-ok
  (forall ρ; ρ xs:Seq Int f:Seq Int rem:Int prev:Int j:Int -- ρ ok:Bool)
  locals { xs f rem prev j } {
    f j prim seq-int.at rem prim =
    [ prev 0 prim <
      [ true ]
      [ xs j prim seq-int.at xs prev prim seq-int.at prim > ]
      if ]
    [ false ]
    if
  };

: fill
  (forall ρ; ρ n:Int v:Int -- ρ s:Seq Int)
  0 prim seq-int.empty fill-loop;

: fill-loop
  (forall ρ; ρ n:Int v:Int j:Int out:Seq Int -- ρ s:Seq Int)
  locals { n v j out } {
    j n prim <
    [ n v j 1 prim + out v prim seq-int.push fill-loop ]
    [ out ]
    if
  };

: imax
  (forall ρ; ρ a:Int b:Int -- ρ m:Int)
  locals { a b } {
    a b prim >
    [ a ]
    [ b ]
    if
  };
```

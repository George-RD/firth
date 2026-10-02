### task: bowling
```firth
: bw-adv
  (forall ρ; ρ rolls:Seq Int^many p:Int^many -- ρ n:Int^many)
  locals { rolls p } {
    rolls p prim seq-int.at 10 prim =
    [ 1 ] [ 2 ] if
  };

: bw-spare
  (forall ρ; ρ s:Int^many rolls:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { s rolls p } {
    s 10 prim =
    [ s rolls p 2 prim + prim seq-int.at prim + ]
    [ s ]
    if
  };

: bw-open
  (forall ρ; ρ rolls:Seq Int^many p:Int^many -- ρ s:Int^many)
  locals { rolls p } {
    rolls p prim seq-int.at rolls p 1 prim + prim seq-int.at prim +
    rolls p bw-spare
  };

: bw-score
  (forall ρ; ρ rolls:Seq Int^many p:Int^many -- ρ s:Int^many)
  locals { rolls p } {
    rolls p prim seq-int.at 10 prim =
    [ rolls p 1 prim + prim seq-int.at
      rolls p 2 prim + prim seq-int.at prim +
      10 prim + ]
    [ rolls p bw-open ]
    if
  };

: bw-total
  (forall ρ; ρ rolls:Seq Int^many p:Int^many t:Int^many -- ρ tn:Int^many)
  locals { rolls p t } { rolls p bw-score t prim + };

: bw-step
  (forall ρ; ρ rolls:Seq Int^many p:Int^many t:Int^many out:Seq Int^many k:Int^many
    -- ρ rolls:Seq Int^many p:Int^many t:Int^many out:Seq Int^many k:Int^many flag:Bool^many)
  locals { rolls p t out k } {
    k 0 prim >
    [ rolls
      p rolls p bw-adv prim +
      rolls p t bw-total dup
      out swap prim seq-int.push
      k 1 prim -
      true ]
    [ rolls p t out k false ]
    if
  };

: bw-loop
  (forall ρ; ρ rolls:Seq Int^many p:Int^many t:Int^many out:Seq Int^many k:Int^many
    -- ρ rolls:Seq Int^many p:Int^many t:Int^many out:Seq Int^many k:Int^many)
  bw-step [ bw-loop ] [ ] if ;

: main
  (forall ρ; ρ rolls:Seq Int^many -- ρ totals:Seq Int^many)
  0 0 prim seq-int.empty 10 bw-loop
  locals { r p t out k } { out } ;
```

### task: lru
```firth
: lru-sel
  (forall ρ; ρ eq:Bool^many i:Int^many -- ρ r:Int^many)
  locals { eq i } { eq [ i ] [ -1 ] if };

: lru-fstep
  (forall ρ; ρ cache:Seq Int^many key:Int^many i:Int^many found:Int^many
    -- ρ cache:Seq Int^many key:Int^many i:Int^many found:Int^many flag:Bool^many)
  locals { cache key i found } {
    found 0 prim <
    i cache prim seq-int.len prim <
    prim and
    [ cache key i 1 prim +
      cache i prim seq-int.at key prim = i lru-sel
      true ]
    [ cache key i found false ]
    if
  };

: lru-floop
  (forall ρ; ρ cache:Seq Int^many key:Int^many i:Int^many found:Int^many
    -- ρ cache:Seq Int^many key:Int^many i:Int^many found:Int^many)
  lru-fstep [ lru-floop ] [ ] if ;

: lru-fpick
  (forall ρ; ρ cache:Seq Int^many key:Int^many i:Int^many found:Int^many -- ρ idx:Int^many)
  locals { cache key i found } { found };

: lru-find
  (forall ρ; ρ cache:Seq Int^many key:Int^many -- ρ idx:Int^many)
  0 -1 lru-floop lru-fpick ;

: lru-pushun
  (forall ρ; ρ out:Seq Int^many v:Int^many i:Int^many skip:Int^many -- ρ out2:Seq Int^many)
  locals { out v i skip } {
    i skip prim =
    [ out ] [ out v prim seq-int.push ] if
  };

: lru-cstep
  (forall ρ; ρ xs:Seq Int^many skip:Int^many i:Int^many out:Seq Int^many
    -- ρ xs:Seq Int^many skip:Int^many i:Int^many out:Seq Int^many flag:Bool^many)
  locals { xs skip i out } {
    i xs prim seq-int.len prim <
    [ xs skip i 1 prim +
      out xs i prim seq-int.at i skip lru-pushun
      true ]
    [ xs skip i out false ]
    if
  };

: lru-cloop
  (forall ρ; ρ xs:Seq Int^many skip:Int^many i:Int^many out:Seq Int^many
    -- ρ xs:Seq Int^many skip:Int^many i:Int^many out:Seq Int^many)
  lru-cstep [ lru-cloop ] [ ] if ;

: lru-cpick
  (forall ρ; ρ xs:Seq Int^many skip:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { xs skip i out } { out };

: lru-remove
  (forall ρ; ρ xs:Seq Int^many skip:Int^many -- ρ r:Seq Int^many)
  0 prim seq-int.empty lru-cloop lru-cpick ;

: lru-miss
  (forall ρ; ρ cap:Int^many cache:Seq Int^many key:Int^many -- ρ cache2:Seq Int^many m:Int^many)
  locals { cap cache key } {
    cache prim seq-int.len cap prim >=
    [ cache 0 lru-remove key prim seq-int.push 1 ]
    [ cache key prim seq-int.push 1 ]
    if
  };

: lru-access2
  (forall ρ; ρ cap:Int^many cache:Seq Int^many key:Int^many idx:Int^many
    -- ρ cache2:Seq Int^many m:Int^many)
  locals { cap cache key idx } {
    idx 0 prim <
    [ cap cache key lru-miss ]
    [ cache idx lru-remove key prim seq-int.push 0 ]
    if
  };

: lru-access
  (forall ρ; ρ cap:Int^many cache:Seq Int^many key:Int^many -- ρ cache2:Seq Int^many m:Int^many)
  locals { cap cache key } {
    cap cache key cache key lru-find lru-access2
  };

: lru-step
  (forall ρ; ρ cap:Int^many keys:Seq Int^many i:Int^many cache:Seq Int^many misses:Int^many
    -- ρ cap:Int^many keys:Seq Int^many i:Int^many cache:Seq Int^many misses:Int^many flag:Bool^many)
  locals { cap keys i cache misses } {
    i keys prim seq-int.len prim <
    [ cap keys i 1 prim +
      cap cache keys i prim seq-int.at lru-access
      misses prim +
      true ]
    [ cap keys i cache misses false ]
    if
  };

: lru-loop
  (forall ρ; ρ cap:Int^many keys:Seq Int^many i:Int^many cache:Seq Int^many misses:Int^many
    -- ρ cap:Int^many keys:Seq Int^many i:Int^many cache:Seq Int^many misses:Int^many)
  lru-step [ lru-loop ] [ ] if ;

: main
  (forall ρ; ρ cap:Int^many keys:Seq Int^many -- ρ misses:Int^many cache:Seq Int^many)
  0 prim seq-int.empty 0 lru-loop
  locals { c ks i cache misses } { misses cache } ;
```

### task: rpn
```firth
: rpn-abs
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 0 prim < [ 0 x prim - ] [ x ] if };

: rpn-tdiv
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } {
    a rpn-abs b rpn-abs prim div
    a 0 prim < b 0 prim < prim =
    [ ] [ 0 swap prim - ] if
  };

: rpn-op3
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 3 prim = [ a b prim * ] [ a b rpn-tdiv ] if
  };

: rpn-op2
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 2 prim = [ a b prim - ] [ a b k rpn-op3 ] if
  };

: rpn-op
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 1 prim = [ a b prim + ] [ a b k rpn-op2 ] if
  };

: rpn-push
  (forall ρ; ρ buf:Seq Int^many sp:Int^many v:Int^many -- ρ buf2:Seq Int^many sp2:Int^many)
  locals { buf sp v } {
    sp buf prim seq-int.len prim <
    [ buf sp v prim seq-int.set sp 1 prim + ]
    [ buf v prim seq-int.push sp 1 prim + ]
    if
  };

: rpn-dup
  (forall ρ; ρ buf:Seq Int^many sp:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp } {
    sp 1 prim <
    [ buf sp 1 ]
    [ buf sp buf sp 1 prim - prim seq-int.at rpn-push 0 ]
    if
  };

: rpn-bin2
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k } {
    k 4 prim =
    buf sp 1 prim - prim seq-int.at 0 prim =
    prim and
    [ buf sp 2 ]
    [ buf sp 2 prim -
      buf sp 2 prim - prim seq-int.at
      buf sp 1 prim - prim seq-int.at
      k rpn-op
      rpn-push 0 ]
    if
  };

: rpn-bin
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k } {
    sp 2 prim <
    [ buf sp 1 ]
    [ buf sp k rpn-bin2 ]
    if
  };

: rpn-tok2
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k } {
    k 5 prim =
    [ buf sp rpn-dup ]
    [ buf sp k rpn-bin ]
    if
  };

: rpn-tok
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many v:Int^many
    -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k v } {
    k 0 prim =
    [ buf sp v rpn-push 0 ]
    [ buf sp k rpn-tok2 ]
    if
  };

: rpn-step
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many
    -- ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many flag:Bool^many)
  locals { kinds vals i buf sp st } {
    st 0 prim =
    i kinds prim seq-int.len prim <
    prim and
    [ kinds vals i 1 prim +
      buf sp kinds i prim seq-int.at vals i prim seq-int.at rpn-tok
      true ]
    [ kinds vals i buf sp st false ]
    if
  };

: rpn-loop
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many
    -- ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many)
  rpn-step [ rpn-loop ] [ ] if ;

: rpn-fin2
  (forall ρ; ρ buf:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { buf sp } {
    sp 1 prim =
    [ buf 0 prim seq-int.at 0 ]
    [ 0 3 ]
    if
  };

: rpn-fin
  (forall ρ; ρ buf:Seq Int^many sp:Int^many st:Int^many -- ρ result:Int^many status:Int^many)
  locals { buf sp st } {
    st 0 prim =
    [ buf sp rpn-fin2 ]
    [ 0 st ]
    if
  };

: main
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many -- ρ result:Int^many status:Int^many)
  0 prim seq-int.empty 0 0 rpn-loop
  locals { ks vs i buf sp st } { buf sp st rpn-fin } ;
```

### task: edit-cost
```firth
: ec-min
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: ec-r0step
  (forall ρ; ρ n:Int^many ins:Int^many j:Int^many out:Seq Int^many
    -- ρ n:Int^many ins:Int^many j:Int^many out:Seq Int^many flag:Bool^many)
  locals { n ins j out } {
    j n prim <=
    [ n ins j 1 prim + out j ins prim * prim seq-int.push true ]
    [ n ins j out false ]
    if
  };

: ec-r0loop
  (forall ρ; ρ n:Int^many ins:Int^many j:Int^many out:Seq Int^many
    -- ρ n:Int^many ins:Int^many j:Int^many out:Seq Int^many)
  ec-r0step [ ec-r0loop ] [ ] if ;

: ec-r0pick
  (forall ρ; ρ n:Int^many ins:Int^many j:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { n ins j out } { out };

: ec-row0
  (forall ρ; ρ n:Int^many ins:Int^many -- ρ r:Seq Int^many)
  0 prim seq-int.empty ec-r0loop ec-r0pick ;

: ec-del
  (forall ρ; ρ prev:Seq Int^many j:Int^many pm:Seq Int^many -- ρ a:Int^many)
  locals { prev j pm } {
    prev j prim seq-int.at pm 1 prim seq-int.at prim +
  };

: ec-ins
  (forall ρ; ρ cur:Seq Int^many pm:Seq Int^many -- ρ b:Int^many)
  locals { cur pm } {
    cur cur prim seq-int.len 1 prim - prim seq-int.at pm 0 prim seq-int.at prim +
  };

: ec-sub
  (forall ρ; ρ prev:Seq Int^many ys:Seq Int^many xi:Int^many j:Int^many pm:Seq Int^many -- ρ c:Int^many)
  locals { prev ys xi j pm } {
    prev j 1 prim - prim seq-int.at
    ys j 1 prim - prim seq-int.at xi prim =
    [ 0 ] [ pm 2 prim seq-int.at ] if
    prim +
  };

: ec-istep
  (forall ρ; ρ ys:Seq Int^many pm:Seq Int^many xi:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many
    -- ρ ys:Seq Int^many pm:Seq Int^many xi:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many flag:Bool^many)
  locals { ys pm xi j prev cur } {
    j ys prim seq-int.len prim <=
    [ ys pm xi j 1 prim + prev
      cur
      prev j pm ec-del
      cur pm ec-ins ec-min
      prev ys xi j pm ec-sub ec-min
      prim seq-int.push
      true ]
    [ ys pm xi j prev cur false ]
    if
  };

: ec-iloop
  (forall ρ; ρ ys:Seq Int^many pm:Seq Int^many xi:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many
    -- ρ ys:Seq Int^many pm:Seq Int^many xi:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many)
  ec-istep [ ec-iloop ] [ ] if ;

: ec-ipick
  (forall ρ; ρ ys:Seq Int^many pm:Seq Int^many xi:Int^many j:Int^many prev:Seq Int^many cur:Seq Int^many
    -- ρ r:Seq Int^many)
  locals { ys pm xi j prev cur } { cur };

: ec-row
  (forall ρ; ρ ys:Seq Int^many pm:Seq Int^many xi:Int^many i:Int^many prev:Seq Int^many -- ρ cur:Seq Int^many)
  locals { ys pm xi i prev } {
    ys pm xi 1 prev
    prim seq-int.empty i pm 1 prim seq-int.at prim * prim seq-int.push
    ec-iloop ec-ipick
  };

: ec-ostep
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many pm:Seq Int^many i:Int^many prev:Seq Int^many
    -- ρ xs:Seq Int^many ys:Seq Int^many pm:Seq Int^many i:Int^many prev:Seq Int^many flag:Bool^many)
  locals { xs ys pm i prev } {
    i xs prim seq-int.len prim <=
    [ xs ys pm i 1 prim +
      ys pm xs i 1 prim - prim seq-int.at i prev ec-row
      true ]
    [ xs ys pm i prev false ]
    if
  };

: ec-oloop
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many pm:Seq Int^many i:Int^many prev:Seq Int^many
    -- ρ xs:Seq Int^many ys:Seq Int^many pm:Seq Int^many i:Int^many prev:Seq Int^many)
  ec-ostep [ ec-oloop ] [ ] if ;

: ec-fin
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many pm:Seq Int^many i:Int^many prev:Seq Int^many -- ρ cost:Int^many)
  locals { xs ys pm i prev } {
    prev ys prim seq-int.len prim seq-int.at
  };

: main
  (forall ρ; ρ xs:Seq Int^many ys:Seq Int^many insert:Int^many delete:Int^many replace:Int^many
    -- ρ cost:Int^many)
  locals { xs ys insert delete replace } {
    xs ys
    prim seq-int.empty insert prim seq-int.push delete prim seq-int.push replace prim seq-int.push
    1
    ys prim seq-int.len insert ec-row0
    ec-oloop
    ec-fin
  };
```

### task: shortest-hops
```firth
: sh-fstep
  (forall ρ; ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many
    -- ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many flag:Bool^many)
  locals { n v i out } {
    i n prim <
    [ n v i 1 prim + out v prim seq-int.push true ]
    [ n v i out false ]
    if
  };

: sh-floop
  (forall ρ; ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many
    -- ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many)
  sh-fstep [ sh-floop ] [ ] if ;

: sh-fpick
  (forall ρ; ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { n v i out } { out };

: sh-fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  0 prim seq-int.empty sh-floop sh-fpick ;

: sh-better
  (forall ρ; ρ nd:Int^many nh:Int^many od:Int^many oh:Int^many -- ρ b:Bool^many)
  locals { nd nh od oh } {
    od 0 prim <
    nd od prim < prim or
    nd od prim = nh oh prim < prim and prim or
  };

: sh-relax3
  (forall ρ; ρ dist:Seq Int^many hops:Seq Int^many u:Int^many v:Int^many wt:Int^many
    -- ρ dist2:Seq Int^many hops2:Seq Int^many)
  locals { dist hops u v wt } {
    dist u prim seq-int.at wt prim +
    hops u prim seq-int.at 1 prim +
    dist v prim seq-int.at
    hops v prim seq-int.at
    sh-better
    [ dist v dist u prim seq-int.at wt prim + prim seq-int.set
      hops v hops u prim seq-int.at 1 prim + prim seq-int.set ]
    [ dist hops ]
    if
  };

: sh-relax2
  (forall ρ; ρ dist:Seq Int^many hops:Seq Int^many u:Int^many v:Int^many wt:Int^many
    -- ρ dist2:Seq Int^many hops2:Seq Int^many)
  locals { dist hops u v wt } {
    dist u prim seq-int.at 0 prim >=
    [ dist hops u v wt sh-relax3 ]
    [ dist hops ]
    if
  };

: sh-estep
  (forall ρ; ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many k:Int^many
    -- ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many k:Int^many flag:Bool^many)
  locals { fr to w dist hops k } {
    k fr prim seq-int.len prim <
    [ fr to w
      dist hops fr k prim seq-int.at to k prim seq-int.at w k prim seq-int.at sh-relax2
      k 1 prim +
      true ]
    [ fr to w dist hops k false ]
    if
  };

: sh-eloop
  (forall ρ; ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many k:Int^many
    -- ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many k:Int^many)
  sh-estep [ sh-eloop ] [ ] if ;

: sh-rstep
  (forall ρ; ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many r:Int^many
    -- ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many r:Int^many flag:Bool^many)
  locals { fr to w dist hops r } {
    r 0 prim >
    [ fr to w dist hops 0 sh-eloop drop r 1 prim - true ]
    [ fr to w dist hops r false ]
    if
  };

: sh-rloop
  (forall ρ; ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many r:Int^many
    -- ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many r:Int^many)
  sh-rstep [ sh-rloop ] [ ] if ;

: sh-fin
  (forall ρ; ρ fr:Seq Int^many to:Seq Int^many w:Seq Int^many dist:Seq Int^many hops:Seq Int^many r:Int^many
    -- ρ dist2:Seq Int^many hops2:Seq Int^many)
  locals { fr to w dist hops r } { dist hops };

: main
  (forall ρ; ρ n:Int^many froms:Seq Int^many tos:Seq Int^many weights:Seq Int^many source:Int^many
    -- ρ dist:Seq Int^many hops:Seq Int^many)
  locals { n froms tos weights source } {
    froms tos weights
    n -1 sh-fill source 0 prim seq-int.set
    n -1 sh-fill source 0 prim seq-int.set
    n 1 prim -
    sh-rloop sh-fin
  };
```

### task: merge-ranges
```firth
: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: mr-swap
  (forall ρ; ρ xs:Seq Int^many j:Int^many -- ρ ys:Seq Int^many)
  locals { xs j } {
    xs j 1 prim - xs j prim seq-int.at prim seq-int.set
    j xs j 1 prim - prim seq-int.at prim seq-int.set
  };

: mr-cmp
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many j:Int^many
    -- ρ s2:Seq Int^many e2:Seq Int^many j2:Int^many flag:Bool^many)
  locals { s e j } {
    s j 1 prim - prim seq-int.at s j prim seq-int.at prim >
    [ s j mr-swap e j mr-swap j 1 prim - true ]
    [ s e j false ]
    if
  };

: mr-istep
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many j:Int^many
    -- ρ s2:Seq Int^many e2:Seq Int^many j2:Int^many flag:Bool^many)
  locals { s e j } {
    j 0 prim >
    [ s e j mr-cmp ]
    [ s e j false ]
    if
  };

: mr-iloop
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many j:Int^many
    -- ρ s2:Seq Int^many e2:Seq Int^many j2:Int^many)
  mr-istep [ mr-iloop ] [ ] if ;

: mr-ostep
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many i:Int^many
    -- ρ s2:Seq Int^many e2:Seq Int^many i2:Int^many flag:Bool^many)
  locals { s e i } {
    i s prim seq-int.len prim <
    [ s e i mr-iloop drop i 1 prim + true ]
    [ s e i false ]
    if
  };

: mr-oloop
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many i:Int^many
    -- ρ s2:Seq Int^many e2:Seq Int^many i2:Int^many)
  mr-ostep [ mr-oloop ] [ ] if ;

: mr-opick
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many i:Int^many -- ρ s2:Seq Int^many e2:Seq Int^many)
  locals { s e i } { s e };

: mr-sort
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many -- ρ s2:Seq Int^many e2:Seq Int^many)
  1 mr-oloop mr-opick ;

: mr-join
  (forall ρ; ρ ms:Seq Int^many me:Seq Int^many cs:Int^many ce:Int^many si:Int^many ei:Int^many
    -- ρ ms2:Seq Int^many me2:Seq Int^many cs2:Int^many ce2:Int^many)
  locals { ms me cs ce si ei } {
    si ce 1 prim + prim <=
    [ ms me cs ce ei max2 ]
    [ ms cs prim seq-int.push me ce prim seq-int.push si ei ]
    if
  };

: mr-mstep
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many i:Int^many ms:Seq Int^many me:Seq Int^many cs:Int^many ce:Int^many
    -- ρ s:Seq Int^many e:Seq Int^many i:Int^many ms:Seq Int^many me:Seq Int^many cs:Int^many ce:Int^many flag:Bool^many)
  locals { s e i ms me cs ce } {
    i s prim seq-int.len prim <
    [ s e i 1 prim +
      ms me cs ce s i prim seq-int.at e i prim seq-int.at mr-join
      true ]
    [ s e i ms me cs ce false ]
    if
  };

: mr-mloop
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many i:Int^many ms:Seq Int^many me:Seq Int^many cs:Int^many ce:Int^many
    -- ρ s:Seq Int^many e:Seq Int^many i:Int^many ms:Seq Int^many me:Seq Int^many cs:Int^many ce:Int^many)
  mr-mstep [ mr-mloop ] [ ] if ;

: mr-cstep
  (forall ρ; ρ ms:Seq Int^many me:Seq Int^many i:Int^many acc:Int^many
    -- ρ ms:Seq Int^many me:Seq Int^many i:Int^many acc:Int^many flag:Bool^many)
  locals { ms me i acc } {
    i ms prim seq-int.len prim <
    [ ms me i 1 prim +
      acc me i prim seq-int.at ms i prim seq-int.at prim - 1 prim + prim +
      true ]
    [ ms me i acc false ]
    if
  };

: mr-cloop
  (forall ρ; ρ ms:Seq Int^many me:Seq Int^many i:Int^many acc:Int^many
    -- ρ ms:Seq Int^many me:Seq Int^many i:Int^many acc:Int^many)
  mr-cstep [ mr-cloop ] [ ] if ;

: mr-cpick
  (forall ρ; ρ ms:Seq Int^many me:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { ms me i acc } { acc };

: mr-cov
  (forall ρ; ρ ms:Seq Int^many me:Seq Int^many -- ρ cov:Int^many)
  0 0 mr-cloop mr-cpick ;

: mr-fin2
  (forall ρ; ρ ms:Seq Int^many me:Seq Int^many -- ρ ms2:Seq Int^many me2:Seq Int^many cov:Int^many)
  locals { ms me } { ms me ms me mr-cov };

: mr-fin
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many i:Int^many ms:Seq Int^many me:Seq Int^many cs:Int^many ce:Int^many
    -- ρ ms2:Seq Int^many me2:Seq Int^many cov:Int^many)
  locals { s e i ms me cs ce } {
    ms cs prim seq-int.push
    me ce prim seq-int.push
    mr-fin2
  };

: mr-main2
  (forall ρ; ρ s:Seq Int^many e:Seq Int^many -- ρ ms:Seq Int^many me:Seq Int^many cov:Int^many)
  mr-sort
  locals { s2 e2 } {
    s2 e2 1 prim seq-int.empty prim seq-int.empty
    s2 0 prim seq-int.at e2 0 prim seq-int.at
    mr-mloop mr-fin
  } ;

: main
  (forall ρ; ρ starts:Seq Int^many ends:Seq Int^many
    -- ρ ms:Seq Int^many me:Seq Int^many covered:Int^many)
  locals { starts ends } {
    starts prim seq-int.len 0 prim =
    [ prim seq-int.empty prim seq-int.empty 0 ]
    [ starts ends mr-main2 ]
    if
  };
```

### task: tiny-vm
```firth
: vm-val3
  (forall ρ; ρ x:Int^many y:Int^many op:Int^many -- ρ v:Int^many)
  locals { x y op } {
    op 4 prim = [ x y prim * ] [ y ] if
  };

: vm-val2
  (forall ρ; ρ x:Int^many y:Int^many op:Int^many -- ρ v:Int^many)
  locals { x y op } {
    op 3 prim = [ x y prim - ] [ x y op vm-val3 ] if
  };

: vm-val
  (forall ρ; ρ x:Int^many y:Int^many op:Int^many -- ρ v:Int^many)
  locals { x y op } {
    op 2 prim = [ x y prim + ] [ x y op vm-val2 ] if
  };

: vm-alu
  (forall ρ; ρ regs:Seq Int^many a:Int^many b:Int^many op:Int^many -- ρ regs2:Seq Int^many)
  locals { regs a b op } {
    regs a
    regs a prim seq-int.at regs b prim seq-int.at op vm-val
    prim seq-int.set
  };

: vm-cond
  (forall ρ; ρ r:Int^many op:Int^many -- ρ c:Bool^many)
  locals { r op } {
    op 6 prim = r 0 prim = prim not prim and
    op 7 prim = r 0 prim < prim and
    prim or
  };

: vm-jmp
  (forall ρ; ρ regs:Seq Int^many pc:Int^many a:Int^many b:Int^many op:Int^many
    -- ρ regs2:Seq Int^many pc2:Int^many)
  locals { regs pc a b op } {
    regs
    regs a prim seq-int.at op vm-cond
    [ b ] [ pc 1 prim + ]
    if
  };

: vm-op2
  (forall ρ; ρ regs:Seq Int^many pc:Int^many a:Int^many b:Int^many op:Int^many
    -- ρ regs2:Seq Int^many pc2:Int^many)
  locals { regs pc a b op } {
    op 5 prim <=
    [ regs a b op vm-alu pc 1 prim + ]
    [ regs pc a b op vm-jmp ]
    if
  };

: vm-op
  (forall ρ; ρ regs:Seq Int^many pc:Int^many a:Int^many b:Int^many op:Int^many
    -- ρ regs2:Seq Int^many pc2:Int^many)
  locals { regs pc a b op } {
    op 1 prim <=
    [ regs a b prim seq-int.set pc 1 prim + ]
    [ regs pc a b op vm-op2 ]
    if
  };

: vm-exec2
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many
    -- ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many flag:Bool^many)
  locals { limit code regs pc cnt } {
    limit code
    regs pc
    code pc 3 prim * 1 prim + prim seq-int.at
    code pc 3 prim * 2 prim + prim seq-int.at
    code pc 3 prim * prim seq-int.at
    vm-op
    cnt 1 prim + -1 true
  };

: vm-exec
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many
    -- ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many flag:Bool^many)
  locals { limit code regs pc cnt } {
    code pc 3 prim * prim seq-int.at 0 prim =
    [ limit code regs pc cnt 1 prim + 0 false ]
    [ limit code regs pc cnt vm-exec2 ]
    if
  };

: vm-run2
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many
    -- ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many flag:Bool^many)
  locals { limit code regs pc cnt } {
    cnt limit prim >=
    [ limit code regs pc cnt 2 false ]
    [ limit code regs pc cnt vm-exec ]
    if
  };

: vm-run
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many
    -- ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many flag:Bool^many)
  locals { limit code regs pc cnt } {
    pc 0 prim <
    pc code prim seq-int.len 3 prim div prim >=
    prim or
    [ limit code regs pc cnt 1 false ]
    [ limit code regs pc cnt vm-run2 ]
    if
  };

: vm-step
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many
    -- ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many flag:Bool^many)
  locals { limit code regs pc cnt st } {
    st 0 prim <
    [ limit code regs pc cnt vm-run ]
    [ limit code regs pc cnt st false ]
    if
  };

: vm-loop
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many
    -- ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many)
  vm-step [ vm-loop ] [ ] if ;

: vm-fin
  (forall ρ; ρ limit:Int^many code:Seq Int^many regs:Seq Int^many pc:Int^many cnt:Int^many st:Int^many
    -- ρ regs2:Seq Int^many cnt2:Int^many st2:Int^many)
  locals { limit code regs pc cnt st } { regs cnt st };

: main
  (forall ρ; ρ code:Seq Int^many regs:Seq Int^many limit:Int^many
    -- ρ regs-out:Seq Int^many executed:Int^many status:Int^many)
  locals { code regs limit } {
    limit code regs 0 0 -1 vm-loop vm-fin
  };
```

### task: lis-smallest
```firth
: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: lis-fl-step
  (forall ρ; ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many
    -- ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many flag:Bool^many)
  locals { n v i out } {
    i n prim <
    [ n v i 1 prim + out v prim seq-int.push true ]
    [ n v i out false ]
    if
  };

: lis-fl-loop
  (forall ρ; ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many
    -- ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many)
  lis-fl-step [ lis-fl-loop ] [ ] if ;

: lis-fl-pick
  (forall ρ; ρ n:Int^many v:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { n v i out } { out };

: lis-fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  0 prim seq-int.empty lis-fl-loop lis-fl-pick ;

: lis-upd
  (forall ρ; ρ b:Int^many lj:Int^many gt:Bool^many -- ρ b2:Int^many)
  locals { b lj gt } { gt [ b lj max2 ] [ b ] if };

: lis-i-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many i:Int^many j:Int^many b:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many i:Int^many j:Int^many b:Int^many flag:Bool^many)
  locals { xs ls i j b } {
    j xs prim seq-int.len prim <
    [ xs ls i j 1 prim +
      b ls j prim seq-int.at xs j prim seq-int.at xs i prim seq-int.at prim > lis-upd
      true ]
    [ xs ls i j b false ]
    if
  };

: lis-i-loop
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many i:Int^many j:Int^many b:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many i:Int^many j:Int^many b:Int^many)
  lis-i-step [ lis-i-loop ] [ ] if ;

: lis-fin1
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many i:Int^many j:Int^many b:Int^many
    -- ρ xs:Seq Int^many ls2:Seq Int^many i2:Int^many)
  locals { xs ls i j b } {
    xs ls i b 1 prim + prim seq-int.set i 1 prim -
  };

: lis-o-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many i:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many i:Int^many flag:Bool^many)
  locals { xs ls i } {
    i 0 prim >=
    [ xs ls i i 1 prim + 0 lis-i-loop lis-fin1 true ]
    [ xs ls i false ]
    if
  };

: lis-o-loop
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many i:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many i:Int^many)
  lis-o-step [ lis-o-loop ] [ ] if ;

: lis-m-step
  (forall ρ; ρ ls:Seq Int^many i:Int^many m:Int^many
    -- ρ ls:Seq Int^many i:Int^many m:Int^many flag:Bool^many)
  locals { ls i m } {
    i ls prim seq-int.len prim <
    [ ls i 1 prim + m ls i prim seq-int.at max2 true ]
    [ ls i m false ]
    if
  };

: lis-m-loop
  (forall ρ; ρ ls:Seq Int^many i:Int^many m:Int^many
    -- ρ ls:Seq Int^many i:Int^many m:Int^many)
  lis-m-step [ lis-m-loop ] [ ] if ;

: lis-m-pick
  (forall ρ; ρ ls:Seq Int^many i:Int^many m:Int^many -- ρ r:Int^many)
  locals { ls i m } { m };

: lis-max
  (forall ρ; ρ ls:Seq Int^many -- ρ m:Int^many)
  0 0 lis-m-loop lis-m-pick ;

: lis-gt
  (forall ρ; ρ xs:Seq Int^many idx:Int^many j:Int^many -- ρ c:Bool^many)
  locals { xs idx j } {
    idx 0 prim <
    [ true ]
    [ xs j prim seq-int.at xs idx prim seq-int.at prim > ]
    if
  };

: lis-lt
  (forall ρ; ρ xs:Seq Int^many best:Int^many j:Int^many -- ρ c:Bool^many)
  locals { xs best j } {
    best 0 prim <
    [ true ]
    [ xs j prim seq-int.at xs best prim seq-int.at prim < ]
    if
  };

: lis-pick
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many j:Int^many best:Int^many
    -- ρ best2:Int^many)
  locals { xs ls idx rem j best } {
    ls j prim seq-int.at rem prim =
    xs idx j lis-gt prim and
    xs best j lis-lt prim and
    [ j ] [ best ] if
  };

: lis-f-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many j:Int^many best:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many j:Int^many best:Int^many flag:Bool^many)
  locals { xs ls idx rem j best } {
    j xs prim seq-int.len prim <
    [ xs ls idx rem j 1 prim +
      xs ls idx rem j best lis-pick
      true ]
    [ xs ls idx rem j best false ]
    if
  };

: lis-f-loop
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many j:Int^many best:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many j:Int^many best:Int^many)
  lis-f-step [ lis-f-loop ] [ ] if ;

: lis-bestof
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many j:Int^many best:Int^many
    -- ρ r:Int^many)
  locals { xs ls idx rem j best } { best };

: lis-find
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many -- ρ best:Int^many)
  locals { xs ls idx rem } {
    xs ls idx rem idx 1 prim + -1 lis-f-loop lis-bestof
  };

: lis-b2
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many rem:Int^many out:Seq Int^many best:Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem2:Int^many out2:Seq Int^many)
  locals { xs ls rem out best } {
    xs ls best rem 1 prim - out xs best prim seq-int.at prim seq-int.push
  };

: lis-b-step
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many out:Seq Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many out:Seq Int^many flag:Bool^many)
  locals { xs ls idx rem out } {
    rem 0 prim >
    [ xs ls rem out xs ls idx rem lis-find lis-b2 true ]
    [ xs ls idx rem out false ]
    if
  };

: lis-b-loop
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many out:Seq Int^many
    -- ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many out:Seq Int^many)
  lis-b-step [ lis-b-loop ] [ ] if ;

: lis-b-pick
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many idx:Int^many rem:Int^many out:Seq Int^many
    -- ρ r:Seq Int^many)
  locals { xs ls idx rem out } { out };

: lis-fin2
  (forall ρ; ρ xs:Seq Int^many ls:Seq Int^many i:Int^many -- ρ lis:Seq Int^many)
  locals { xs ls i } {
    xs ls -1 ls lis-max prim seq-int.empty lis-b-loop lis-b-pick
  };

: main
  (forall ρ; ρ xs:Seq Int^many -- ρ lis:Seq Int^many)
  locals { xs } {
    xs
    xs prim seq-int.len 0 lis-fill
    xs prim seq-int.len 1 prim -
    lis-o-loop
    lis-fin2
  };
```

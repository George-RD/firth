### task: poker
```firth
: elt
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many)
  prim seq-int.at ;

: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: zeros
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  0 fill ;

: count-go
  (forall ρ; ρ cnt:Seq Int^many ranks:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { cnt ranks i } {
    i 5 prim <
    [ ranks i prim seq-int.at
      locals { rk } {
        cnt rk cnt rk prim seq-int.at 1 prim + prim seq-int.set
        ranks i 1 prim + count-go } ]
    [ cnt ]
    if };

: count5
  (forall ρ; ρ ranks:Seq Int^many -- ρ cnt:Seq Int^many)
  locals { ranks } { 15 zeros ranks 0 count-go };

: key-go
  (forall ρ; ρ cnt:Seq Int^many acc:Int^many t:Int^many -- ρ r:Int^many)
  locals { cnt acc t } {
    t 52 prim <
    [ cnt
      cnt 14 t 13 prim mod prim - prim seq-int.at
      4 t 13 prim div prim - prim =
      [ acc 15 prim * 14 t 13 prim mod prim - prim + ]
      [ acc ]
      if
      t 1 prim + key-go ]
    [ acc ]
    if };

: key5
  (forall ρ; ρ cnt:Seq Int^many -- ρ k:Int^many)
  locals { cnt } { cnt 0 0 key-go };

: max5
  (forall ρ; ρ ranks:Seq Int^many -- ρ r:Int^many)
  locals { ranks } {
    ranks 0 elt ranks 1 elt max2
    ranks 2 elt max2
    ranks 3 elt max2
    ranks 4 elt max2 };

: min5
  (forall ρ; ρ ranks:Seq Int^many -- ρ r:Int^many)
  locals { ranks } {
    ranks 0 elt ranks 1 elt min2
    ranks 2 elt min2
    ranks 3 elt min2
    ranks 4 elt min2 };

: ssq
  (forall ρ; ρ cnt:Seq Int^many ranks:Seq Int^many -- ρ r:Int^many)
  locals { cnt ranks } {
    cnt ranks 0 elt elt
    cnt ranks 1 elt elt prim +
    cnt ranks 2 elt elt prim +
    cnt ranks 3 elt elt prim +
    cnt ranks 4 elt elt prim + };

: flush?
  (forall ρ; ρ suits:Seq Int^many -- ρ b:Bool^many)
  locals { suits } {
    suits 0 elt suits 1 elt prim =
    suits 0 elt suits 2 elt prim = prim and
    suits 0 elt suits 3 elt prim = prim and
    suits 0 elt suits 4 elt prim = prim and };

: wheel?
  (forall ρ; ρ cnt:Seq Int^many -- ρ b:Bool^many)
  locals { cnt } {
    cnt 14 elt 1 prim >=
    cnt 2 elt 1 prim >= prim and
    cnt 3 elt 1 prim >= prim and
    cnt 4 elt 1 prim >= prim and
    cnt 5 elt 1 prim >= prim and };

: run?
  (forall ρ; ρ cnt:Seq Int^many ranks:Seq Int^many -- ρ b:Bool^many)
  locals { cnt ranks } {
    cnt ranks ssq 5 prim =
    ranks max5 ranks min5 prim - 4 prim =
    prim and };

: straight?
  (forall ρ; ρ cnt:Seq Int^many ranks:Seq Int^many -- ρ b:Bool^many)
  locals { cnt ranks } { cnt ranks run? cnt wheel? prim or };

: high-card
  (forall ρ; ρ cnt:Seq Int^many ranks:Seq Int^many -- ρ h:Int^many)
  locals { cnt ranks } { cnt wheel? [ 5 ] [ ranks max5 ] if };

: category
  (forall ρ; ρ q:Int^many f:Bool^many st:Bool^many -- ρ c:Int^many)
  locals { q f st } {
    q 17 prim = [ 7 ] [
      q 13 prim = [ 6 ] [
        q 11 prim = [ 3 ] [
          q 9 prim = [ 2 ] [
            q 7 prim = [ 1 ] [
              f st prim and [ 8 ] [
                f [ 5 ] [ st [ 4 ] [ 0 ] if ] if
              ] if
            ] if
          ] if
        ] if
      ] if
    ] if };

: score
  (forall ρ; ρ ranks:Seq Int^many suits:Seq Int^many -- ρ s:Int^many)
  locals { ranks suits } {
    ranks count5
    locals { cnt } {
      cnt ranks ssq
      suits flush?
      cnt ranks straight?
      category
      locals { c } {
        c 4 prim = c 8 prim = prim or
        [ c 759375 prim * cnt ranks high-card prim + ]
        [ c 759375 prim * cnt key5 prim + ]
        if } } };

: main
  (forall ρ; ρ r1:Seq Int^many s1:Seq Int^many r2:Seq Int^many s2:Seq Int^many -- ρ w:Int^many c1:Int^many c2:Int^many)
  locals { r1 s1 r2 s2 } {
    r1 s1 score
    locals { sa } {
      r2 s2 score
      locals { sb } {
        sa sb prim > [ 1 ] [ sa sb prim < [ 2 ] [ 0 ] if ] if
        sa 759375 prim div
        sb 759375 prim div } } };
```

### task: league-table
```firth
: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: add-to
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { s i x } { s i s i prim seq-int.at x prim + prim seq-int.set };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: zeros
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  0 fill ;

: pts-of
  (forall ρ; ρ g:Int^many o:Int^many -- ρ p:Int^many)
  locals { g o } { g o prim > [ 3 ] [ g o prim = [ 1 ] [ 0 ] if ] if };

: stats-go
  (forall ρ; ρ pts:Seq Int^many gd:Seq Int^many gf:Seq Int^many k:Int^many homes:Seq Int^many aways:Seq Int^many hgs:Seq Int^many ags:Seq Int^many -- ρ pts2:Seq Int^many gd2:Seq Int^many gf2:Seq Int^many)
  locals { pts gd gf k homes aways hgs ags } {
    k homes prim seq-int.len prim <
    [ homes k prim seq-int.at
      aways k prim seq-int.at
      hgs k prim seq-int.at
      ags k prim seq-int.at
      locals { h a x y } {
        pts h x y pts-of add-to
        a y x pts-of add-to
        gd h x y prim - add-to
        a y x prim - add-to
        gf h x add-to
        a y add-to
        k 1 prim + homes aways hgs ags stats-go } ]
    [ pts gd gf ]
    if };

: k1-go
  (forall ρ; ρ pts:Seq Int^many gd:Seq Int^many gf:Seq Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { pts gd gf i out } {
    i pts prim seq-int.len prim <
    [ pts gd gf i 1 prim +
      out
      pts i prim seq-int.at 2001 prim *
      gd i prim seq-int.at prim + 1000 prim + 1001 prim *
      gf i prim seq-int.at prim +
      prim seq-int.push
      k1-go ]
    [ out ]
    if };

: h2h-go
  (forall ρ; ρ k1:Seq Int^many h2:Seq Int^many k:Int^many homes:Seq Int^many aways:Seq Int^many hgs:Seq Int^many ags:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 h2 k homes aways hgs ags } {
    k homes prim seq-int.len prim <
    [ homes k prim seq-int.at
      aways k prim seq-int.at
      hgs k prim seq-int.at
      ags k prim seq-int.at
      locals { h a x y } {
        k1
        k1 h prim seq-int.at k1 a prim seq-int.at prim =
        [ h2 h x y pts-of add-to a y x pts-of add-to ]
        [ h2 ]
        if
        k 1 prim + homes aways hgs ags h2h-go } ]
    [ h2 ]
    if };

: fin-go
  (forall ρ; ρ k1:Seq Int^many h2:Seq Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 h2 i out } {
    i k1 prim seq-int.len prim <
    [ k1 h2 i 1 prim +
      out
      k1 i prim seq-int.at 1000 prim * h2 i prim seq-int.at prim + 16 prim *
      15 i prim - prim +
      prim seq-int.push
      fin-go ]
    [ out ]
    if };

: argmax-go
  (forall ρ; ρ ks:Seq Int^many i:Int^many best:Int^many -- ρ r:Int^many)
  locals { ks i best } {
    i ks prim seq-int.len prim <
    [ ks i 1 prim +
      ks i prim seq-int.at ks best prim seq-int.at prim >
      [ i ] [ best ] if
      argmax-go ]
    [ best ]
    if };

: sel-go
  (forall ρ; ρ ks:Seq Int^many order:Seq Int^many -- ρ r:Seq Int^many)
  locals { ks order } {
    order prim seq-int.len ks prim seq-int.len prim <
    [ ks 0 0 argmax-go
      locals { b } {
        ks b -1 prim seq-int.set
        order b prim seq-int.push
        sel-go } ]
    [ order ]
    if };

: main
  (forall ρ; ρ n:Int^many homes:Seq Int^many aways:Seq Int^many hgs:Seq Int^many ags:Seq Int^many -- ρ order:Seq Int^many points:Seq Int^many)
  locals { n homes aways hgs ags } {
    n zeros n zeros n zeros 0 homes aways hgs ags stats-go
    locals { pts gd gf } {
      pts gd gf 0 prim seq-int.empty k1-go
      locals { k1 } {
        k1 n zeros 0 homes aways hgs ags h2h-go
        locals { h2 } {
          k1 h2 0 prim seq-int.empty fin-go
          prim seq-int.empty sel-go
          pts } } } };
```

### task: bank-ledger
```firth
: add-to
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { s i x } { s i s i prim seq-int.at x prim + prim seq-int.set };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: zeros
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  0 fill ;

: month-val
  (forall ρ; ρ v:Int^many -- ρ r:Int^many)
  locals { v } {
    v 0 prim <
    [ v 0 v prim - 9 prim + 10 prim div prim - ]
    [ v 100 prim >= [ v v 100 prim div prim + ] [ v ] if ]
    if };

: month-go
  (forall ρ; ρ bal:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { bal i } {
    i bal prim seq-int.len prim <
    [ bal i bal i prim seq-int.at month-val prim seq-int.set i 1 prim + month-go ]
    [ bal ]
    if };

: debit
  (forall ρ; ρ bal:Seq Int^many a:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { bal a amt } {
    bal a
    bal a prim seq-int.at amt prim -
    bal a prim seq-int.at 0 prim >=
    bal a prim seq-int.at amt prim - 0 prim <
    prim and
    [ 5 prim - ] [ ] if
    prim seq-int.set };

: rejected?
  (forall ρ; ρ bal:Seq Int^many rej:Seq Int^many kind:Int^many a:Int^many b:Int^many amt:Int^many limit:Int^many -- ρ f:Bool^many)
  locals { bal rej kind a b amt limit } {
    rej a prim seq-int.at 3 prim >=
    kind 3 prim =
    rej b prim seq-int.at 3 prim >=
    a b prim = prim or
    prim and
    prim or
    kind 2 prim >=
    bal a prim seq-int.at amt prim - 0 limit prim - prim <
    prim and
    prim or };

: apply
  (forall ρ; ρ bal:Seq Int^many kind:Int^many a:Int^many b:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { bal kind a b amt } {
    kind 1 prim =
    [ bal a amt add-to ]
    [ kind 2 prim =
      [ bal a amt debit ]
      [ bal a amt debit b amt add-to ]
      if ]
    if };

: step
  (forall ρ; ρ bal:Seq Int^many rej:Seq Int^many kind:Int^many a:Int^many b:Int^many amt:Int^many limit:Int^many -- ρ bal2:Seq Int^many rej2:Seq Int^many)
  locals { bal rej kind a b amt limit } {
    kind 4 prim =
    [ bal 0 month-go rej ]
    [ bal rej kind a b amt limit rejected?
      [ bal rej a 1 add-to ]
      [ bal kind a b amt apply rej ]
      if ]
    if };

: ops-go
  (forall ρ; ρ bal:Seq Int^many rej:Seq Int^many k:Int^many kinds:Seq Int^many accts:Seq Int^many others:Seq Int^many amounts:Seq Int^many limit:Int^many -- ρ bal2:Seq Int^many rej2:Seq Int^many)
  locals { bal rej k kinds accts others amounts limit } {
    k kinds prim seq-int.len prim <
    [ bal rej
      kinds k prim seq-int.at
      accts k prim seq-int.at
      others k prim seq-int.at
      amounts k prim seq-int.at
      limit step
      k 1 prim + kinds accts others amounts limit ops-go ]
    [ bal rej ]
    if };

: sum-go
  (forall ρ; ρ s:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { s i acc } {
    i s prim seq-int.len prim <
    [ s i 1 prim + acc s i prim seq-int.at prim + sum-go ]
    [ acc ]
    if };

: frozen-go
  (forall ρ; ρ rej:Seq Int^many i:Int^many out:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { rej i out } {
    i rej prim seq-int.len prim <
    [ rej i 1 prim + out rej i prim seq-int.at 3 prim >= prim seq-bool.push frozen-go ]
    [ out ]
    if };

: main
  (forall ρ; ρ balances:Seq Int^many limit:Int^many kinds:Seq Int^many accts:Seq Int^many others:Seq Int^many amounts:Seq Int^many -- ρ final:Seq Int^many rejected:Int^many frozen:Seq Bool^many)
  locals { balances limit kinds accts others amounts } {
    balances balances prim seq-int.len zeros 0 kinds accts others amounts limit ops-go
    locals { bal rej } {
      bal
      rej 0 0 sum-go
      rej 0 prim seq-bool.empty frozen-go } };
```

### task: order-book
```firth
: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: add-to
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { s i x } { s i s i prim seq-int.at x prim + prim seq-int.set };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: zeros
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  0 fill ;

: rkey
  (forall ρ; ρ s:Int^many p:Int^many i:Int^many -- ρ k:Int^many)
  locals { s p i } {
    s 0 prim =
    [ 2000 p prim - 64 prim * i prim + ]
    [ p 64 prim * i prim + ]
    if };

: pj-of
  (forall ρ; ρ key:Int^many s:Int^many -- ρ pj:Int^many)
  locals { key s } {
    s 0 prim =
    [ key 64 prim div ]
    [ 2000 key 64 prim div prim - ]
    if };

: acceptable?
  (forall ρ; ρ key:Int^many s:Int^many p:Int^many -- ρ b:Bool^many)
  locals { key s p } {
    key 1000000000 prim <
    p 0 prim =
    s 0 prim = key s pj-of p prim <= prim and
    s 1 prim = key s pj-of p prim >= prim and
    prim or prim or prim and };

: amin-go
  (forall ρ; ρ a:Seq Int^many i:Int^many hi:Int^many best:Int^many -- ρ r:Int^many)
  locals { a i hi best } {
    i hi prim <
    [ a i 1 prim + hi
      a i prim seq-int.at a best prim seq-int.at prim <
      [ i ] [ best ] if
      amin-go ]
    [ best ]
    if };

: trade
  (forall ρ; ρ s:Int^many bs:Seq Int^many rm:Seq Int^many filled:Seq Int^many st:Seq Int^many q:Int^many b:Int^many -- ρ bs2:Seq Int^many rm2:Seq Int^many filled2:Seq Int^many st2:Seq Int^many q2:Int^many)
  locals { s bs rm filled st q b } {
    bs b prim seq-int.at 64 prim mod
    locals { j } {
      q rm j prim seq-int.at min2
      locals { u } {
        rm j prim seq-int.at u prim - 0 prim =
        [ bs b 1000000000 prim seq-int.set ] [ bs ] if
        rm j rm j prim seq-int.at u prim - prim seq-int.set
        filled j u add-to
        st 0 u bs b prim seq-int.at s pj-of prim * add-to
        1 1 add-to
        q u prim - } } };

: match-go
  (forall ρ; ρ s:Int^many p:Int^many lo:Int^many hi:Int^many bs:Seq Int^many rm:Seq Int^many filled:Seq Int^many st:Seq Int^many q:Int^many -- ρ bs2:Seq Int^many rm2:Seq Int^many filled2:Seq Int^many st2:Seq Int^many q2:Int^many)
  locals { s p lo hi bs rm filled st q } {
    q 0 prim >
    [ bs lo hi lo amin-go
      locals { b } {
        bs b prim seq-int.at s p acceptable?
        [ s p lo hi s bs rm filled st q b trade match-go ]
        [ bs rm filled st q ]
        if } ]
    [ bs rm filled st q ]
    if };

: do-order
  (forall ρ; ρ bs:Seq Int^many rm:Seq Int^many filled:Seq Int^many st:Seq Int^many m:Int^many i:Int^many s:Int^many p:Int^many q:Int^many -- ρ bs3:Seq Int^many rm3:Seq Int^many filled3:Seq Int^many st3:Seq Int^many)
  locals { bs rm filled st m i s p q } {
    m 1 s prim - prim *
    locals { lo } {
      s p lo lo m prim + bs rm filled st q match-go
      locals { bs2 rm2 filled2 st2 q2 } {
        q2 0 prim > p 0 prim = prim not prim and
        locals { rest } {
          rest [ bs2 i s m prim * prim + s p i rkey prim seq-int.set ] [ bs2 ] if
          rest [ rm2 i q2 prim seq-int.set ] [ rm2 ] if
          filled2 i q q2 prim - add-to
          st2 } } } };

: do-cancel
  (forall ρ; ρ bs:Seq Int^many rm:Seq Int^many m:Int^many j:Int^many -- ρ bs2:Seq Int^many rm2:Seq Int^many)
  locals { bs rm m j } {
    rm j prim seq-int.at 0 prim >
    [ bs j 1000000000 prim seq-int.set
      j m prim + 1000000000 prim seq-int.set
      rm j 0 prim seq-int.set ]
    [ bs rm ]
    if };

: ops-go
  (forall ρ; ρ kinds:Seq Int^many sides:Seq Int^many prices:Seq Int^many qtys:Seq Int^many i:Int^many bs:Seq Int^many rm:Seq Int^many filled:Seq Int^many st:Seq Int^many -- ρ filled2:Seq Int^many st2:Seq Int^many)
  locals { kinds sides prices qtys i bs rm filled st } {
    i kinds prim seq-int.len prim <
    [ kinds sides prices qtys i 1 prim +
      kinds i prim seq-int.at 0 prim =
      [ bs rm filled st kinds prim seq-int.len i sides i prim seq-int.at prices i prim seq-int.at qtys i prim seq-int.at do-order ]
      [ bs rm kinds prim seq-int.len qtys i prim seq-int.at do-cancel filled st ]
      if
      ops-go ]
    [ filled st ]
    if };

: main
  (forall ρ; ρ kinds:Seq Int^many sides:Seq Int^many prices:Seq Int^many qtys:Seq Int^many -- ρ filled:Seq Int^many value:Int^many trades:Int^many)
  locals { kinds sides prices qtys } {
    kinds sides prices qtys 0
    kinds prim seq-int.len 2 prim * 1000000000 fill
    kinds prim seq-int.len zeros
    kinds prim seq-int.len zeros
    2 zeros
    ops-go
    locals { filled st } {
      filled
      st 0 prim seq-int.at
      st 1 prim seq-int.at } };
```

### task: spreadsheet
```firth
: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: zeros
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  0 fill ;

: abs
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 0 prim < [ 0 x prim - ] [ x ] if };

: tdiv
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } {
    a abs b abs prim div
    locals { m } {
      a 0 prim < b 0 prim >= prim and
      a 0 prim >= b 0 prim < prim and
      prim or
      [ 0 m prim - ] [ m ] if } };

: inr?
  (forall ρ; ρ r:Int^many n:Int^many -- ρ b:Bool^many)
  locals { r n } { r 0 prim >= r n prim < prim and };

: push-valid
  (forall ρ; ρ adj:Seq Int^many r:Int^many n:Int^many -- ρ r2:Seq Int^many)
  locals { adj r n } {
    r n inr?
    [ adj r prim seq-int.push ]
    [ adj ]
    if };

: push-range
  (forall ρ; ρ adj:Seq Int^many lo:Int^many hi:Int^many -- ρ r:Seq Int^many)
  locals { adj lo hi } {
    lo hi prim <=
    [ adj lo prim seq-int.push lo 1 prim + hi push-range ]
    [ adj ]
    if };

: append-refs
  (forall ρ; ρ adj:Seq Int^many kind:Int^many x:Int^many y:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { adj kind x y n } {
    kind 0 prim =
    [ adj ]
    [ kind 3 prim <=
      [ adj x n push-valid y n push-valid ]
      [ adj x 0 max2 y n 1 prim - min2 push-range ]
      if ]
    if };

: build-go
  (forall ρ; ρ kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many n:Int^many c:Int^many adj:Seq Int^many off:Seq Int^many -- ρ adj2:Seq Int^many off2:Seq Int^many)
  locals { kinds xs ys n c adj off } {
    c n prim <
    [ kinds xs ys n c 1 prim +
      adj kinds c prim seq-int.at xs c prim seq-int.at ys c prim seq-int.at n append-refs
      off adj prim seq-int.len prim seq-int.push
      build-go ]
    [ adj off adj prim seq-int.len prim seq-int.push ]
    if };

: refs1-go
  (forall ρ; ρ adj:Seq Int^many off:Seq Int^many vs:Seq Int^many cy:Seq Int^many ord:Seq Int^many c:Int^many j:Int^many hi:Int^many -- ρ vs2:Seq Int^many cy2:Seq Int^many ord2:Seq Int^many)
  locals { adj off vs cy ord c j hi } {
    j hi prim <
    [ adj off
      adj j prim seq-int.at
      locals { r } {
        vs r prim seq-int.at 0 prim =
        [ adj off vs cy ord r visit1 ] [ vs cy ord ] if
        locals { vs2 cy2 ord2 } {
          vs2
          vs2 r prim seq-int.at 1 prim = cy2 r prim seq-int.at 1 prim = prim or
          [ cy2 c 1 prim seq-int.set ] [ cy2 ] if
          ord2 c j 1 prim + hi refs1-go } } ]
    [ vs cy ord ]
    if };

: visit1
  (forall ρ; ρ adj:Seq Int^many off:Seq Int^many vs:Seq Int^many cy:Seq Int^many ord:Seq Int^many c:Int^many -- ρ vs2:Seq Int^many cy2:Seq Int^many ord2:Seq Int^many)
  locals { adj off vs cy ord c } {
    adj off vs c 1 prim seq-int.set cy ord c
    off c prim seq-int.at off c 1 prim + prim seq-int.at
    refs1-go
    locals { vs3 cy3 ord3 } {
      vs3 c 2 prim seq-int.set cy3 ord3 c prim seq-int.push } };

: top1-go
  (forall ρ; ρ adj:Seq Int^many off:Seq Int^many vs:Seq Int^many cy:Seq Int^many ord:Seq Int^many c:Int^many n:Int^many -- ρ vs2:Seq Int^many cy2:Seq Int^many ord2:Seq Int^many)
  locals { adj off vs cy ord c n } {
    c n prim <
    [ adj off
      vs c prim seq-int.at 0 prim =
      [ adj off vs cy ord c visit1 ] [ vs cy ord ] if
      c 1 prim + n top1-go ]
    [ vs cy ord ]
    if };

: calc123
  (forall ρ; ρ val:Seq Int^many er:Seq Int^many kind:Int^many x:Int^many y:Int^many -- ρ v:Int^many e:Int^many)
  locals { val er kind x y } {
    er x prim seq-int.at 1 prim = er y prim seq-int.at 1 prim = prim or
    [ 0 1 ]
    [ val x prim seq-int.at val y prim seq-int.at
      locals { vx vy } {
        kind 1 prim =
        [ vx vy prim + 0 ]
        [ kind 2 prim =
          [ vx vy prim - 0 ]
          [ vy 0 prim = [ 0 1 ] [ vx vy tdiv 0 ] if ]
          if ]
        if } ]
    if };

: rng-err-go
  (forall ρ; ρ er:Seq Int^many k:Int^many hi:Int^many -- ρ b:Bool^many)
  locals { er k hi } {
    k hi prim <=
    [ er k prim seq-int.at 1 prim =
      [ true ]
      [ er k 1 prim + hi rng-err-go ]
      if ]
    [ false ]
    if };

: rng-max-go
  (forall ρ; ρ val:Seq Int^many k:Int^many hi:Int^many acc:Int^many -- ρ r:Int^many)
  locals { val k hi acc } {
    k hi prim <=
    [ val k 1 prim + hi acc val k prim seq-int.at max2 rng-max-go ]
    [ acc ]
    if };

: rng-cnt-go
  (forall ρ; ρ val:Seq Int^many er:Seq Int^many k:Int^many hi:Int^many acc:Int^many -- ρ r:Int^many)
  locals { val er k hi acc } {
    k hi prim <=
    [ val er k 1 prim + hi
      er k prim seq-int.at 0 prim = val k prim seq-int.at 0 prim > prim and
      [ acc 1 prim + ] [ acc ] if
      rng-cnt-go ]
    [ acc ]
    if };

: calc
  (forall ρ; ρ val:Seq Int^many er:Seq Int^many n:Int^many kind:Int^many x:Int^many y:Int^many -- ρ v:Int^many e:Int^many)
  locals { val er n kind x y } {
    kind 0 prim =
    [ x 0 ]
    [ kind 3 prim <=
      [ x n inr? y n inr? prim and
        [ val er kind x y calc123 ]
        [ 0 1 ]
        if ]
      [ x 0 prim >= x y prim <= prim and y n prim < prim and
        [ kind 4 prim =
          [ er x y rng-err-go
            [ 0 1 ]
            [ val x y val x prim seq-int.at rng-max-go 0 ]
            if ]
          [ val er x y 0 rng-cnt-go 0 ]
          if ]
        [ 0 1 ]
        if ]
      if ]
    if };

: eval-cell
  (forall ρ; ρ val:Seq Int^many er:Seq Int^many cy:Seq Int^many n:Int^many kind:Int^many x:Int^many y:Int^many c:Int^many -- ρ val2:Seq Int^many er2:Seq Int^many)
  locals { val er cy n kind x y c } {
    cy c prim seq-int.at 1 prim =
    [ val c 0 prim seq-int.set er c 1 prim seq-int.set ]
    [ val er n kind x y calc
      locals { v e } { val c v prim seq-int.set er c e prim seq-int.set } ]
    if };

: eval-go
  (forall ρ; ρ val:Seq Int^many er:Seq Int^many cy:Seq Int^many n:Int^many kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many ord:Seq Int^many k:Int^many -- ρ val2:Seq Int^many er2:Seq Int^many)
  locals { val er cy n kinds xs ys ord k } {
    k ord prim seq-int.len prim <
    [ ord k prim seq-int.at
      locals { c } {
        val er cy n kinds c prim seq-int.at xs c prim seq-int.at ys c prim seq-int.at c eval-cell
        cy n kinds xs ys ord k 1 prim + eval-go } ]
    [ val er ]
    if };

: bools-go
  (forall ρ; ρ er:Seq Int^many i:Int^many out:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { er i out } {
    i er prim seq-int.len prim <
    [ er i 1 prim + out er i prim seq-int.at 1 prim = prim seq-bool.push bools-go ]
    [ out ]
    if };

: main
  (forall ρ; ρ kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ values:Seq Int^many errors:Seq Bool^many)
  locals { kinds xs ys } {
    kinds prim seq-int.len
    locals { n } {
      kinds xs ys n 0 prim seq-int.empty prim seq-int.empty build-go
      locals { adj off } {
        adj off n zeros n zeros prim seq-int.empty 0 n top1-go
        locals { vs cy ord } {
          n zeros n zeros cy n kinds xs ys ord 0 eval-go
          locals { val er } {
            val
            er 0 prim seq-bool.empty bools-go } } } } };
```

### task: elevator
```firth
: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: p2-table
  (forall ρ; ρ -- ρ t:Seq Int^many)
  { 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 } ;

: p2
  (forall ρ; ρ f:Int^many -- ρ v:Int^many)
  p2-table swap prim seq-int.at ;

: test-bit
  (forall ρ; ρ mask:Int^many f:Int^many -- ρ b:Bool^many)
  locals { mask f } { mask f p2 prim div 2 prim mod 1 prim = };

: set-bit
  (forall ρ; ρ mask:Int^many f:Int^many -- ρ r:Int^many)
  locals { mask f } { mask f test-bit [ mask ] [ mask f p2 prim + ] if };

: admit-go
  (forall ρ; ρ times:Seq Int^many floors:Seq Int^many ss:Seq Int^many mask:Int^many na:Int^many k:Int^many clock:Int^many -- ρ ss2:Seq Int^many mask2:Int^many na2:Int^many)
  locals { times floors ss mask na k clock } {
    k times prim seq-int.len prim <
    [ times floors
      ss k prim seq-int.at -2 prim =
      [ times k prim seq-int.at clock prim <=
        [ ss k -1 prim seq-int.set mask floors k prim seq-int.at set-bit na ]
        [ ss mask na times k prim seq-int.at min2 ]
        if ]
      [ ss mask na ]
      if
      k 1 prim + clock admit-go ]
    [ ss mask na ]
    if };

: admit
  (forall ρ; ρ times:Seq Int^many floors:Seq Int^many ss:Seq Int^many mask:Int^many na:Int^many clock:Int^many -- ρ ss2:Seq Int^many mask2:Int^many na2:Int^many)
  locals { times floors ss mask na clock } {
    clock na prim >=
    [ times floors ss mask 1000000000 0 clock admit-go ]
    [ ss mask na ]
    if };

: serve-go
  (forall ρ; ρ floors:Seq Int^many ss:Seq Int^many fl:Int^many clock:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { floors ss fl clock k } {
    k floors prim seq-int.len prim <
    [ floors
      ss k prim seq-int.at -1 prim =
      floors k prim seq-int.at fl prim = prim and
      [ ss k clock prim seq-int.set ] [ ss ] if
      fl clock k 1 prim + serve-go ]
    [ ss ]
    if };

: sim-go
  (forall ρ; ρ times:Seq Int^many floors:Seq Int^many ss:Seq Int^many mask:Int^many na:Int^many fl:Int^many dir:Int^many clock:Int^many moved:Int^many -- ρ ss2:Seq Int^many end:Int^many moved2:Int^many)
  locals { times floors ss mask na fl dir clock moved } {
    mask fl test-bit
    [ floors ss fl clock 0 serve-go
      locals { ss2 } {
        clock 2 prim +
        locals { c2 } {
          times floors
          times floors ss2 mask fl p2 prim - na c2 admit
          fl dir c2 moved sim-go } } ]
    [ mask 0 prim =
      [ na 1000000000 prim =
        [ ss clock moved ]
        [ times floors times floors ss mask na na admit fl dir na moved sim-go ]
        if ]
      [ dir 1 prim =
        [ mask fl 1 prim + p2 prim div 0 prim = ]
        [ mask fl p2 prim mod 0 prim = ]
        if
        [ 0 dir prim - ] [ dir ] if
        locals { d2 } {
          fl d2 prim +
          locals { f2 } {
            clock 1 prim +
            locals { c3 } {
              times floors
              times floors ss mask na c3 admit
              f2 d2 c3 moved 1 prim + sim-go } } } ]
      if ]
    if };

: main
  (forall ρ; ρ times:Seq Int^many floors:Seq Int^many -- ρ served:Seq Int^many end:Int^many moved:Int^many)
  locals { times floors } {
    times floors
    times floors times prim seq-int.len -2 fill 0 0 0 admit
    0 1 0 0 sim-go };
```

### task: date-diff
```firth
: leap
  (forall ρ; ρ y:Int^many -- ρ b:Bool^many)
  locals { y } {
    y 400 prim mod 0 prim =
    [ true ]
    [ y 100 prim mod 0 prim =
      [ false ]
      [ y 4 prim mod 0 prim = ]
      if ]
    if };

: cum-days
  (forall ρ; ρ -- ρ t:Seq Int^many)
  { 0 31 59 90 120 151 181 212 243 273 304 334 } ;

: doy
  (forall ρ; ρ y:Int^many m:Int^many d:Int^many -- ρ r:Int^many)
  locals { y m d } {
    cum-days m 1 prim - prim seq-int.at
    d prim +
    y leap m 2 prim > prim and
    [ 1 prim + ] [ ] if };

: days-before
  (forall ρ; ρ p:Int^many -- ρ r:Int^many)
  locals { p } {
    p 365 prim *
    p 4 prim div prim +
    p 100 prim div prim -
    p 400 prim div prim + };

: daynum
  (forall ρ; ρ y:Int^many m:Int^many d:Int^many -- ρ n:Int^many)
  locals { y m d } {
    y 1 prim - days-before
    y m d doy prim + };

: main
  (forall ρ; ρ y1:Int^many m1:Int^many d1:Int^many y2:Int^many m2:Int^many d2:Int^many -- ρ days:Int^many weekday:Int^many doy2:Int^many)
  locals { y1 m1 d1 y2 m2 d2 } {
    y2 m2 d2 daynum y1 m1 d1 daynum prim -
    y2 m2 d2 daynum 730115 prim - 7 prim mod
    y2 m2 d2 doy };
```

### task: heap-alloc
```firth
: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: fill-go
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    s prim seq-int.len n prim <
    [ s v prim seq-int.push n v fill-go ]
    [ s ]
    if };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-go };

: zeros
  (forall ρ; ρ n:Int^many -- ρ r:Seq Int^many)
  0 fill ;

: remove
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many nb:Int^many b:Int^many -- ρ bs2:Seq Int^many bl2:Seq Int^many nb2:Int^many)
  locals { bs bl nb b } {
    bs b bs nb 1 prim - prim seq-int.at prim seq-int.set
    bl b bl nb 1 prim - prim seq-int.at prim seq-int.set
    nb 1 prim - };

: adj?
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many t:Int^many mode:Int^many k:Int^many -- ρ b:Bool^many)
  locals { bs bl t mode k } {
    mode 0 prim =
    [ bs k prim seq-int.at bl k prim seq-int.at prim + t prim = ]
    [ bs k prim seq-int.at t prim = ]
    if };

: find-go
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many nb:Int^many t:Int^many mode:Int^many k:Int^many -- ρ idx:Int^many)
  locals { bs bl nb t mode k } {
    k nb prim <
    [ bs bl t mode k adj?
      [ k ]
      [ bs bl nb t mode k 1 prim + find-go ]
      if ]
    [ -1 ]
    if };

: insert
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many nb:Int^many s:Int^many l:Int^many -- ρ bs2:Seq Int^many bl2:Seq Int^many nb2:Int^many)
  locals { bs bl nb s l } {
    bs bl nb s 0 0 find-go
    locals { left } {
      bs bl nb s l prim + 1 0 find-go
      locals { right } {
        left 0 prim >=
        [ right 0 prim >=
          [ bs bl left bl left prim seq-int.at l prim + bl right prim seq-int.at prim + prim seq-int.set nb right remove ]
          [ bs bl left bl left prim seq-int.at l prim + prim seq-int.set nb ]
          if ]
        [ right 0 prim >=
          [ bs right s prim seq-int.set bl right l bl right prim seq-int.at prim + prim seq-int.set nb ]
          [ bs nb s prim seq-int.set bl nb l prim seq-int.set nb 1 prim + ]
          if ]
        if } } };

: best-go
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many nb:Int^many v:Int^many k:Int^many best:Int^many bkey:Int^many -- ρ r:Int^many)
  locals { bs bl nb v k best bkey } {
    k nb prim <
    [ bs bl nb v k 1 prim +
      bl k prim seq-int.at v prim >=
      bl k prim seq-int.at 1024 prim * bs k prim seq-int.at prim + bkey prim <
      prim and
      [ k bl k prim seq-int.at 1024 prim * bs k prim seq-int.at prim + ]
      [ best bkey ]
      if
      best-go ]
    [ best ]
    if };

: do-alloc
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many nb:Int^many ast:Seq Int^many al:Seq Int^many res:Seq Int^many i:Int^many v:Int^many -- ρ bs2:Seq Int^many bl2:Seq Int^many nb2:Int^many ast2:Seq Int^many al2:Seq Int^many res2:Seq Int^many)
  locals { bs bl nb ast al res i v } {
    bs bl nb v 0 -1 1000000000 best-go
    locals { b } {
      b 0 prim <
      [ bs bl nb ast al res -1 prim seq-int.push ]
      [ bs b bs b prim seq-int.at v prim + prim seq-int.set
        bl b bl b prim seq-int.at v prim - prim seq-int.set
        nb
        bl b prim seq-int.at v prim =
        [ b remove ] [ ] if
        ast i bs b prim seq-int.at prim seq-int.set
        al i v prim seq-int.set
        res bs b prim seq-int.at prim seq-int.push ]
      if } };

: do-free
  (forall ρ; ρ bs:Seq Int^many bl:Seq Int^many nb:Int^many ast:Seq Int^many al:Seq Int^many res:Seq Int^many i:Int^many j:Int^many -- ρ bs2:Seq Int^many bl2:Seq Int^many nb2:Int^many ast2:Seq Int^many al2:Seq Int^many res2:Seq Int^many)
  locals { bs bl nb ast al res i j } {
    j 0 prim >= j i prim < prim and
    [ ast j prim seq-int.at 0 prim >= ] [ false ] if
    [ bs bl nb ast j prim seq-int.at al j prim seq-int.at insert
      ast j -1 prim seq-int.set
      al
      res 0 prim seq-int.push ]
    [ bs bl nb ast al res -1 prim seq-int.push ]
    if };

: maxbl-go
  (forall ρ; ρ bl:Seq Int^many nb:Int^many k:Int^many acc:Int^many -- ρ r:Int^many)
  locals { bl nb k acc } {
    k nb prim <
    [ bl nb k 1 prim + acc bl k prim seq-int.at max2 maxbl-go ]
    [ acc ]
    if };

: ops-go
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many bs:Seq Int^many bl:Seq Int^many nb:Int^many ast:Seq Int^many al:Seq Int^many res:Seq Int^many -- ρ results:Seq Int^many blocks:Int^many largest:Int^many)
  locals { kinds vals i bs bl nb ast al res } {
    i kinds prim seq-int.len prim <
    [ kinds vals i 1 prim +
      kinds i prim seq-int.at 0 prim =
      [ bs bl nb ast al res i vals i prim seq-int.at do-alloc ]
      [ bs bl nb ast al res i vals i prim seq-int.at do-free ]
      if
      ops-go ]
    [ res nb bl nb 0 0 maxbl-go ]
    if };

: main
  (forall ρ; ρ size:Int^many kinds:Seq Int^many vals:Seq Int^many -- ρ results:Seq Int^many blocks:Int^many largest:Int^many)
  locals { size kinds vals } {
    kinds vals 0
    kinds prim seq-int.len 2 prim + zeros
    kinds prim seq-int.len 2 prim + zeros 0 size prim seq-int.set
    1
    kinds prim seq-int.len -1 fill
    kinds prim seq-int.len zeros
    prim seq-int.empty
    ops-go };
```

### task: poker
```firth
: zeros-loop
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    n 0 prim >
    [ s 0 prim seq-int.push n 1 prim - zeros-loop ]
    [ s ]
    if
  };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  prim seq-int.empty swap zeros-loop;

: imax
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: imin
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: tally
  (forall ρ; ρ ranks:Seq Int^many counts:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { ranks counts i } {
    i ranks prim seq-int.len prim <
    [ ranks
      counts ranks i prim seq-int.at
      counts ranks i prim seq-int.at prim seq-int.at 1 prim +
      prim seq-int.set
      i 1 prim + tally ]
    [ counts ]
    if
  };

: num-with-loop
  (forall ρ; ρ c:Seq Int^many k:Int^many r:Int^many acc:Int^many -- ρ n:Int^many)
  locals { c k r acc } {
    r 15 prim <
    [ c k r 1 prim +
      acc c r prim seq-int.at k prim = [ 1 ] [ 0 ] if prim +
      num-with-loop ]
    [ acc ]
    if
  };

: num-with
  (forall ρ; ρ c:Seq Int^many k:Int^many -- ρ n:Int^many)
  locals { c k } { c k 2 0 num-with-loop };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim + acc xs i prim seq-int.at prim + sum-loop ]
    [ acc ]
    if
  };

: seq-sum
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  locals { xs } { xs 0 0 sum-loop };

: max-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim + acc xs i prim seq-int.at imax max-loop ]
    [ acc ]
    if
  };

: seq-max
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at max-loop };

: min-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim + acc xs i prim seq-int.at imin min-loop ]
    [ acc ]
    if
  };

: seq-min
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  locals { xs } { xs 1 xs 0 prim seq-int.at min-loop };

: all-same
  (forall ρ; ρ s:Seq Int^many -- ρ b:Bool^many)
  locals { s } {
    s 0 prim seq-int.at s 1 prim seq-int.at prim =
    s 0 prim seq-int.at s 2 prim seq-int.at prim = prim and
    s 0 prim seq-int.at s 3 prim seq-int.at prim = prim and
    s 0 prim seq-int.at s 4 prim seq-int.at prim = prim and
  };

: key-loop
  (forall ρ; ρ c:Seq Int^many size:Int^many r:Int^many key:Int^many -- ρ k:Int^many)
  locals { c size r key } {
    size 0 prim >
    [ r 2 prim <
      [ c size 1 prim - 14 key key-loop ]
      [ c size r 1 prim -
        c r prim seq-int.at size prim =
        [ key 15 prim * r prim + ]
        [ key ]
        if
        key-loop ]
      if ]
    [ key ]
    if
  };

: category
  (forall ρ; ρ fl:Bool^many st:Bool^many n4:Int^many n3:Int^many n2:Int^many -- ρ cat:Int^many)
  locals { fl st n4 n3 n2 } {
    fl st prim and [ 8 ] [
    n4 1 prim = [ 7 ] [
    n3 1 prim = n2 1 prim = prim and [ 6 ] [
    fl [ 5 ] [
    st [ 4 ] [
    n3 1 prim = [ 3 ] [
    n2 2 prim = [ 2 ] [
    n2 1 prim = [ 1 ] [ 0 ] if
    ] if ] if ] if ] if ] if ] if ] if
  };

: final-score
  (forall ρ; ρ c:Seq Int^many fl:Bool^many st:Bool^many high:Int^many -- ρ score:Int^many)
  locals { c fl st high } {
    fl st c 4 num-with c 3 num-with c 2 num-with category
    759375 prim *
    st [ high ] [ c 4 14 0 key-loop ] if
    prim +
  };

: score-of
  (forall ρ; ρ c:Seq Int^many fl:Bool^many mx:Int^many mn:Int^many sm:Int^many -- ρ score:Int^many)
  locals { c fl mx mn sm } {
    c fl
    c 1 num-with 5 prim =
    mx mn prim - 4 prim =
    mx 14 prim = sm 28 prim = prim and
    prim or
    prim and
    mx 14 prim = sm 28 prim = prim and [ 5 ] [ mx ] if
    final-score
  };

: hand-score
  (forall ρ; ρ ranks:Seq Int^many suits:Seq Int^many -- ρ score:Int^many)
  locals { ranks suits } {
    ranks 15 zeros 0 tally
    suits all-same
    ranks seq-max
    ranks seq-min
    ranks seq-sum
    score-of
  };

: main
  (forall ρ; ρ r1:Seq Int^many s1:Seq Int^many r2:Seq Int^many s2:Seq Int^many -- ρ w:Int^many c1:Int^many c2:Int^many)
  locals { r1 s1 r2 s2 } {
    r1 s1 hand-score
    r2 s2 hand-score
    locals { a b } {
      a b prim > [ 1 ] [ a b prim < [ 2 ] [ 0 ] if ] if
      a 759375 prim div
      b 759375 prim div
    }
  };
```

### task: league-table
```firth
: zeros-loop
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    n 0 prim >
    [ s 0 prim seq-int.push n 1 prim - zeros-loop ]
    [ s ]
    if
  };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  prim seq-int.empty swap zeros-loop;

: add-at
  (forall ρ; ρ s:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { s i d } { s i s i prim seq-int.at d prim + prim seq-int.set };

: pts-for
  (forall ρ; ρ x:Int^many y:Int^many -- ρ p:Int^many)
  locals { x y } { x y prim > [ 3 ] [ x y prim = [ 1 ] [ 0 ] if ] if };

: award
  (forall ρ; ρ p:Seq Int^many h:Int^many a:Int^many x:Int^many y:Int^many -- ρ r:Seq Int^many)
  locals { p h a x y } {
    x y prim >
    [ p h 3 add-at ]
    [ x y prim =
      [ p h 1 add-at a 1 add-at ]
      [ p a 3 add-at ]
      if ]
    if
  };

: play
  (forall ρ; ρ hs:Seq Int^many aw:Seq Int^many hgs:Seq Int^many ags:Seq Int^many pts:Seq Int^many gf:Seq Int^many ga:Seq Int^many k:Int^many -- ρ pts2:Seq Int^many gf2:Seq Int^many ga2:Seq Int^many)
  locals { hs aw hgs ags pts gf ga k } {
    k hs prim seq-int.len prim <
    [ hs k prim seq-int.at aw k prim seq-int.at hgs k prim seq-int.at ags k prim seq-int.at
      locals { h a x y } {
        hs aw hgs ags
        pts h a x y award
        gf h x add-at a y add-at
        ga h y add-at a x add-at
        k 1 prim + play
      } ]
    [ pts gf ga ]
    if
  };

: mk-key1
  (forall ρ; ρ pts:Seq Int^many gf:Seq Int^many ga:Seq Int^many acc:Seq Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { pts gf ga acc t } {
    t pts prim seq-int.len prim <
    [ pts gf ga
      acc
        pts t prim seq-int.at 2002001 prim *
        gf t prim seq-int.at ga t prim seq-int.at prim - 1000 prim + 1001 prim * prim +
        gf t prim seq-int.at prim +
        prim seq-int.push
      t 1 prim + mk-key1 ]
    [ acc ]
    if
  };

: contrib
  (forall ρ; ρ key1:Seq Int^many t:Int^many h:Int^many a:Int^many x:Int^many y:Int^many -- ρ c:Int^many)
  locals { key1 t h a x y } {
    h t prim =
    [ key1 a prim seq-int.at key1 t prim seq-int.at prim = [ x y pts-for ] [ 0 ] if ]
    [ a t prim =
      [ key1 h prim seq-int.at key1 t prim seq-int.at prim = [ y x pts-for ] [ 0 ] if ]
      [ 0 ]
      if ]
    if
  };

: h2h-loop
  (forall ρ; ρ key1:Seq Int^many hs:Seq Int^many aw:Seq Int^many hgs:Seq Int^many ags:Seq Int^many t:Int^many k:Int^many acc:Int^many -- ρ r:Int^many)
  locals { key1 hs aw hgs ags t k acc } {
    k hs prim seq-int.len prim <
    [ key1 hs aw hgs ags t k 1 prim +
      acc
      key1 t hs k prim seq-int.at aw k prim seq-int.at hgs k prim seq-int.at ags k prim seq-int.at contrib
      prim +
      h2h-loop ]
    [ acc ]
    if
  };

: mk-key2
  (forall ρ; ρ key1:Seq Int^many hs:Seq Int^many aw:Seq Int^many hgs:Seq Int^many ags:Seq Int^many t:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { key1 hs aw hgs ags t acc } {
    t key1 prim seq-int.len prim <
    [ key1 hs aw hgs ags t 1 prim +
      acc
        key1 t prim seq-int.at 1000 prim *
        key1 hs aw hgs ags t 0 0 h2h-loop prim +
        16 prim *
        15 t prim - prim +
        prim seq-int.push
      mk-key2 ]
    [ acc ]
    if
  };

: argmax-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many bi:Int^many -- ρ r:Int^many)
  locals { s i bi } {
    i s prim seq-int.len prim <
    [ s i 1 prim +
      s i prim seq-int.at s bi prim seq-int.at prim >
      [ i ] [ bi ] if
      argmax-loop ]
    [ bi ]
    if
  };

: select-loop
  (forall ρ; ρ s:Seq Int^many order:Seq Int^many cnt:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s order cnt n } {
    cnt n prim <
    [ s 1 0 argmax-loop
      locals { idx } {
        s idx -1 prim seq-int.set
        order idx prim seq-int.push
        cnt 1 prim + n select-loop
      } ]
    [ order ]
    if
  };

: main
  (forall ρ; ρ n:Int^many hs:Seq Int^many aw:Seq Int^many hg:Seq Int^many ag:Seq Int^many -- ρ order:Seq Int^many pts:Seq Int^many)
  locals { n hs aw hg ag } {
    hs aw hg ag n zeros n zeros n zeros 0 play
    locals { pts gf ga } {
      pts gf ga prim seq-int.empty 0 mk-key1
      locals { key1 } {
        key1 hs aw hg ag 0 prim seq-int.empty mk-key2
        locals { key2 } {
          key2 prim seq-int.empty 0 n select-loop
          pts
        }
      }
    }
  };
```

### task: bank-ledger
```firth
: zeros-loop
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    n 0 prim >
    [ s 0 prim seq-int.push n 1 prim - zeros-loop ]
    [ s ]
    if
  };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  prim seq-int.empty swap zeros-loop;

: add-at
  (forall ρ; ρ s:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { s i d } { s i s i prim seq-int.at d prim + prim seq-int.set };

: sum-loop
  (forall ρ; ρ xs:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim + acc xs i prim seq-int.at prim + sum-loop ]
    [ acc ]
    if
  };

: fee
  (forall ρ; ρ old:Int^many amt:Int^many -- ρ f:Int^many)
  locals { old amt } {
    old 0 prim >= old amt prim - 0 prim < prim and
    [ 5 ] [ 0 ] if
  };

: debit
  (forall ρ; ρ bal:Seq Int^many a:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { bal a amt } {
    bal a
    bal a prim seq-int.at amt prim -
    bal a prim seq-int.at amt fee prim -
    prim seq-int.set
  };

: credit
  (forall ρ; ρ bal:Seq Int^many a:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { bal a amt } { bal a bal a prim seq-int.at amt prim + prim seq-int.set };

: rejected?
  (forall ρ; ρ bal:Seq Int^many rc:Seq Int^many kind:Int^many a:Int^many b:Int^many amt:Int^many limit:Int^many -- ρ r:Bool^many)
  locals { bal rc kind a b amt limit } {
    rc a prim seq-int.at 3 prim >=
    kind 3 prim = rc b prim seq-int.at 3 prim >= a b prim = prim or prim and
    prim or
    kind 1 prim > bal a prim seq-int.at amt prim - limit prim + 0 prim < prim and
    prim or
  };

: apply
  (forall ρ; ρ bal:Seq Int^many kind:Int^many a:Int^many b:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { bal kind a b amt } {
    kind 1 prim =
    [ bal a amt credit ]
    [ bal a amt debit
      kind 3 prim =
      [ b amt credit ]
      [ ]
      if ]
    if
  };

: grow
  (forall ρ; ρ b:Int^many -- ρ r:Int^many)
  locals { b } {
    b 0 prim <
    [ b 0 b prim - 9 prim + 10 prim div prim - ]
    [ b 100 prim >=
      [ b b 100 prim div prim + ]
      [ b ]
      if ]
    if
  };

: month-step
  (forall ρ; ρ bal:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { bal i } {
    i bal prim seq-int.len prim <
    [ bal i bal i prim seq-int.at grow prim seq-int.set i 1 prim + month-step ]
    [ bal ]
    if
  };

: ops
  (forall ρ; ρ bal:Seq Int^many rc:Seq Int^many limit:Int^many kinds:Seq Int^many accts:Seq Int^many others:Seq Int^many amts:Seq Int^many k:Int^many -- ρ bal2:Seq Int^many rc2:Seq Int^many)
  locals { bal rc limit kinds accts others amts k } {
    k kinds prim seq-int.len prim <
    [ kinds k prim seq-int.at 4 prim =
      [ bal 0 month-step rc ]
      [ bal rc kinds k prim seq-int.at accts k prim seq-int.at others k prim seq-int.at amts k prim seq-int.at limit rejected?
        [ bal rc accts k prim seq-int.at 1 add-at ]
        [ bal kinds k prim seq-int.at accts k prim seq-int.at others k prim seq-int.at amts k prim seq-int.at apply rc ]
        if ]
      if
      limit kinds accts others amts k 1 prim + ops ]
    [ bal rc ]
    if
  };

: frozen-flags
  (forall ρ; ρ rc:Seq Int^many i:Int^many acc:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { rc i acc } {
    i rc prim seq-int.len prim <
    [ rc i 1 prim + acc rc i prim seq-int.at 3 prim >= prim seq-bool.push frozen-flags ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ balances:Seq Int^many limit:Int^many kinds:Seq Int^many accts:Seq Int^many others:Seq Int^many amts:Seq Int^many -- ρ final:Seq Int^many rejected:Int^many frozen:Seq Bool^many)
  locals { balances limit kinds accts others amts } {
    balances
    balances prim seq-int.len zeros
    limit kinds accts others amts 0 ops
    locals { bal rc } {
      bal
      rc 0 0 sum-loop
      rc 0 prim seq-bool.empty frozen-flags
    }
  };
```

### task: order-book
```firth
: zeros-loop
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    n 0 prim >
    [ s 0 prim seq-int.push n 1 prim - zeros-loop ]
    [ s ]
    if
  };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  prim seq-int.empty swap zeros-loop;

: add-at
  (forall ρ; ρ s:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { s i d } { s i s i prim seq-int.at d prim + prim seq-int.set };

: imin
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: iabs
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 0 prim < [ 0 x prim - ] [ x ] if };

: best-loop
  (forall ρ; ρ rest:Seq Int^many lo:Int^many hi:Int^many j:Int^many n:Int^many bi:Int^many bt:Int^many -- ρ r:Int^many)
  locals { rest lo hi j n bi bt } {
    j n prim <
    [ rest lo hi j 1 prim + n
      rest j prim seq-int.at
      locals { r } {
        r lo prim >= r hi prim <= prim and r bt prim < prim and
        [ j r ] [ bi bt ] if
        best-loop
      } ]
    [ bi ]
    if
  };

: bounds
  (forall ρ; ρ side:Int^many p:Int^many -- ρ lo:Int^many hi:Int^many)
  locals { side p } {
    side 0 prim =
    [ 1 p 0 prim > [ p ] [ 1000 ] if ]
    [ -1000 p 0 prim > [ 0 p prim - ] [ -1 ] if ]
    if
  };

: match-loop
  (forall ρ; ρ rest:Seq Int^many rem:Seq Int^many filled:Seq Int^many lo:Int^many hi:Int^many q:Int^many i:Int^many val:Int^many tr:Int^many -- ρ rest2:Seq Int^many rem2:Seq Int^many filled2:Seq Int^many q2:Int^many val2:Int^many tr2:Int^many)
  locals { rest rem filled lo hi q i val tr } {
    q 0 prim >
    [ rest lo hi 0 i -1 1001 best-loop
      locals { j } {
        j -1 prim =
        [ rest rem filled q val tr ]
        [ rem j prim seq-int.at q imin
          locals { t } {
            rem j prim seq-int.at t prim =
            [ rest j 0 prim seq-int.set ]
            [ rest ]
            if
            rem j 0 t prim - add-at
            filled j t add-at i t add-at
            lo hi q t prim - i
            val t rest j prim seq-int.at iabs prim * prim +
            tr 1 prim +
            match-loop
          } ]
        if
      } ]
    [ rest rem filled q val tr ]
    if
  };

: ops-loop
  (forall ρ; ρ kinds:Seq Int^many sides:Seq Int^many prices:Seq Int^many qtys:Seq Int^many rest:Seq Int^many rem:Seq Int^many filled:Seq Int^many val:Int^many tr:Int^many i:Int^many -- ρ filled2:Seq Int^many val2:Int^many tr2:Int^many)
  locals { kinds sides prices qtys rest rem filled val tr i } {
    i kinds prim seq-int.len prim <
    [ kinds i prim seq-int.at 0 prim =
      [ rest rem filled
        sides i prim seq-int.at prices i prim seq-int.at bounds
        qtys i prim seq-int.at i val tr match-loop
        locals { rest2 rem2 filled2 q2 val2 tr2 } {
          kinds sides prices qtys
          q2 0 prim > prices i prim seq-int.at 0 prim > prim and
          [ rest2 i
            sides i prim seq-int.at 0 prim =
            [ 0 prices i prim seq-int.at prim - ]
            [ prices i prim seq-int.at ]
            if
            prim seq-int.set
            rem2 i q2 prim seq-int.set ]
          [ rest2 rem2 ]
          if
          filled2 val2 tr2 i 1 prim + ops-loop
        } ]
      [ qtys i prim seq-int.at
        locals { j } {
          kinds sides prices qtys
          j i prim <
          [ rest j 0 prim seq-int.set rem j 0 prim seq-int.set ]
          [ rest rem ]
          if
          filled val tr i 1 prim + ops-loop
        } ]
      if ]
    [ filled val tr ]
    if
  };

: main
  (forall ρ; ρ kinds:Seq Int^many sides:Seq Int^many prices:Seq Int^many qtys:Seq Int^many -- ρ filled:Seq Int^many value:Int^many trades:Int^many)
  locals { kinds sides prices qtys } {
    kinds sides prices qtys
    kinds prim seq-int.len zeros
    kinds prim seq-int.len zeros
    kinds prim seq-int.len zeros
    0 0 0 ops-loop
  };
```

### task: spreadsheet
```firth
: zeros-loop
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    n 0 prim >
    [ s 0 prim seq-int.push n 1 prim - zeros-loop ]
    [ s ]
    if
  };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  prim seq-int.empty swap zeros-loop;

: ff
  (forall ρ; ρ -- ρ b:Bool^many)
  0 1 prim =;

: imax
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: imin
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: iabs
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 0 prim < [ 0 x prim - ] [ x ] if };

: tdiv
  (forall ρ; ρ x:Int^many y:Int^many -- ρ q:Int^many)
  locals { x y } {
    x iabs y iabs prim div
    locals { q } {
      x 0 prim < y 0 prim >= prim and
      x 0 prim >= y 0 prim < prim and
      prim or
      [ 0 q prim - ] [ q ] if
    }
  };

: mk-cells
  (forall ρ; ρ kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many i:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { kinds xs ys i acc } {
    i kinds prim seq-int.len prim <
    [ kinds xs ys i 1 prim +
      acc
        kinds i prim seq-int.at 2000001 prim *
        xs i prim seq-int.at prim + 1000000 prim +
        201 prim *
        ys i prim seq-int.at prim + 100 prim +
        prim seq-int.push
      mk-cells ]
    [ acc ]
    if
  };

: decode
  (forall ρ; ρ code:Int^many -- ρ k:Int^many a:Int^many b:Int^many)
  locals { code } {
    code 201 prim div 2000001 prim div
    code 201 prim div 2000001 prim mod 1000000 prim -
    code 201 prim mod 100 prim -
  };

: binop
  (forall ρ; ρ x:Int^many y:Int^many k:Int^many -- ρ r:Int^many)
  locals { x y k } {
    x 1000000000000 prim = y 1000000000000 prim = prim or
    [ 1000000000000 ]
    [ k 1 prim =
      [ x y prim + ]
      [ k 2 prim =
        [ x y prim - ]
        [ y 0 prim = [ 1000000000000 ] [ x y tdiv ] if ]
        if ]
      if ]
    if
  };

: rmax
  (forall ρ; ρ val:Seq Int^many c:Int^many hi:Int^many acc:Int^many -- ρ r:Int^many)
  locals { val c hi acc } {
    c hi prim <=
    [ val c 1 prim + hi acc val c prim seq-int.at imax rmax ]
    [ acc ]
    if
  };

: rcount
  (forall ρ; ρ val:Seq Int^many c:Int^many hi:Int^many acc:Int^many -- ρ r:Int^many)
  locals { val c hi acc } {
    c hi prim <=
    [ val c 1 prim + hi
      acc
      val c prim seq-int.at 0 prim > val c prim seq-int.at 1000000000000 prim < prim and
      [ 1 ] [ 0 ] if
      prim +
      rcount ]
    [ acc ]
    if
  };

: compute
  (forall ρ; ρ cells:Seq Int^many n:Int^many val:Seq Int^many v:Int^many -- ρ r:Int^many)
  locals { cells n val v } {
    cells v prim seq-int.at decode
    locals { k a b } {
      k 0 prim =
      [ a ]
      [ k 4 prim <
        [ a 0 prim >= a n prim < prim and b 0 prim >= prim and b n prim < prim and
          [ val a prim seq-int.at val b prim seq-int.at k binop ]
          [ 1000000000000 ]
          if ]
        [ a b prim >
          [ 1000000000000 ]
          [ a 0 prim < b n prim >= prim or
            [ 1000000000000 ]
            [ k 4 prim =
              [ val a 1 prim + b val a prim seq-int.at rmax ]
              [ val a b 0 rcount ]
              if ]
            if ]
          if ]
        if ]
      if
    }
  };

: visit-child
  (forall ρ; ρ cells:Seq Int^many n:Int^many st:Seq Int^many val:Seq Int^many c:Int^many f:Bool^many -- ρ st2:Seq Int^many val2:Seq Int^many f2:Bool^many)
  locals { cells n st val c f } {
    c 0 prim >= c n prim < prim and
    [ st c prim seq-int.at 0 prim =
      [ cells n st val c visit ]
      [ st val ]
      if
      locals { st3 val3 } {
        st3 val3
        f st3 c prim seq-int.at 1 prim = prim or
        st3 c prim seq-int.at 3 prim = prim or
      } ]
    [ st val f ]
    if
  };

: range-loop
  (forall ρ; ρ cells:Seq Int^many n:Int^many st:Seq Int^many val:Seq Int^many c:Int^many hi:Int^many f:Bool^many -- ρ st2:Seq Int^many val2:Seq Int^many f2:Bool^many)
  locals { cells n st val c hi f } {
    c hi prim <=
    [ cells n st val c f visit-child
      locals { st3 val3 f3 } {
        cells n st3 val3 c 1 prim + hi f3 range-loop
      } ]
    [ st val f ]
    if
  };

: children
  (forall ρ; ρ cells:Seq Int^many n:Int^many st:Seq Int^many val:Seq Int^many v:Int^many -- ρ st2:Seq Int^many val2:Seq Int^many flag:Bool^many)
  locals { cells n st val v } {
    cells v prim seq-int.at decode
    locals { k a b } {
      k 0 prim =
      [ st val ff ]
      [ k 4 prim <
        [ cells n st val a ff visit-child
          locals { st1 val1 f1 } {
            cells n st1 val1 b f1 visit-child
          } ]
        [ a b prim <=
          [ cells n st val a 0 imax b n 1 prim - imin ff range-loop ]
          [ st val ff ]
          if ]
        if ]
      if
    }
  };

: visit
  (forall ρ; ρ cells:Seq Int^many n:Int^many st:Seq Int^many val:Seq Int^many v:Int^many -- ρ st2:Seq Int^many val2:Seq Int^many)
  locals { cells n st val v } {
    cells n st v 1 prim seq-int.set val v children
    locals { st3 val3 fl } {
      fl
      [ st3 v 3 prim seq-int.set val3 v 1000000000000 prim seq-int.set ]
      [ st3 v 2 prim seq-int.set val3 v cells n val3 v compute prim seq-int.set ]
      if
    }
  };

: outer-loop
  (forall ρ; ρ cells:Seq Int^many n:Int^many st:Seq Int^many val:Seq Int^many v:Int^many -- ρ st2:Seq Int^many val2:Seq Int^many)
  locals { cells n st val v } {
    v n prim <
    [ st v prim seq-int.at 0 prim =
      [ cells n st val v visit ]
      [ st val ]
      if
      locals { st2 val2 } {
        cells n st2 val2 v 1 prim + outer-loop
      } ]
    [ st val ]
    if
  };

: fin-vals
  (forall ρ; ρ val:Seq Int^many i:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { val i acc } {
    i val prim seq-int.len prim <
    [ val i 1 prim +
      acc
      val i prim seq-int.at 1000000000000 prim = [ 0 ] [ val i prim seq-int.at ] if
      prim seq-int.push
      fin-vals ]
    [ acc ]
    if
  };

: fin-errs
  (forall ρ; ρ val:Seq Int^many i:Int^many acc:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { val i acc } {
    i val prim seq-int.len prim <
    [ val i 1 prim +
      acc val i prim seq-int.at 1000000000000 prim = prim seq-bool.push
      fin-errs ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many -- ρ values:Seq Int^many errors:Seq Bool^many)
  locals { kinds xs ys } {
    kinds xs ys 0 prim seq-int.empty mk-cells
    locals { cells } {
      cells prim seq-int.len
      locals { n } {
        cells n n zeros n zeros 0 outer-loop
        locals { st val } {
          val 0 prim seq-int.empty fin-vals
          val 0 prim seq-bool.empty fin-errs
        }
      }
    }
  };
```

### task: elevator
```firth
: fill-loop
  (forall ρ; ρ s:Seq Int^many n:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s n v } {
    n 0 prim >
    [ s v prim seq-int.push n 1 prim - v fill-loop ]
    [ s ]
    if
  };

: fill
  (forall ρ; ρ n:Int^many v:Int^many -- ρ s:Seq Int^many)
  locals { n v } { prim seq-int.empty n v fill-loop };

: imin
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: sink
  (forall ρ; ρ s:Seq Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { s j } {
    j 0 prim >
    [ s j 1 prim - prim seq-int.at s j prim seq-int.at
      locals { a b } {
        a b prim >
        [ s j 1 prim - b prim seq-int.set j a prim seq-int.set j 1 prim - sink ]
        [ s ]
        if
      } ]
    [ s ]
    if
  };

: isort-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s prim seq-int.len prim <
    [ s i sink i 1 prim + isort-loop ]
    [ s ]
    if
  };

: mk-codes
  (forall ρ; ρ times:Seq Int^many floors:Seq Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { times floors k acc } {
    k times prim seq-int.len prim <
    [ times floors k 1 prim +
      acc
        times k prim seq-int.at 1024 prim *
        floors k prim seq-int.at 32 prim * prim +
        k prim +
        prim seq-int.push
      mk-codes ]
    [ acc ]
    if
  };

: arrive
  (forall ρ; ρ cd:Seq Int^many cnt:Seq Int^many p:Int^many t:Int^many -- ρ cnt2:Seq Int^many p2:Int^many)
  locals { cd cnt p t } {
    p cd prim seq-int.len prim <
    [ cd p prim seq-int.at 1024 prim div t prim <=
      [ cd p prim seq-int.at 32 prim div 32 prim mod
        locals { g } {
          cd
          cnt g cnt g prim seq-int.at 1 prim + prim seq-int.set
          p 1 prim + t arrive
        } ]
      [ cnt p ]
      if ]
    [ cnt p ]
    if
  };

: dist-loop
  (forall ρ; ρ cnt:Seq Int^many g:Int^many d:Int^many s:Int^many -- ρ m:Int^many)
  locals { cnt g d s } {
    g 0 prim >= g 20 prim <= prim and
    [ cnt g prim seq-int.at 0 prim >
      [ s ]
      [ cnt g d prim + d s 1 prim + dist-loop ]
      if ]
    [ 99 ]
    if
  };

: serve-scan
  (forall ρ; ρ cd:Seq Int^many svs:Seq Int^many t:Int^many f:Int^many j:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { cd svs t f j p } {
    j p prim <
    [ cd
      cd j prim seq-int.at 32 prim div 32 prim mod f prim =
      svs j prim seq-int.at -1 prim = prim and
      [ svs j t prim seq-int.set ]
      [ svs ]
      if
      t f j 1 prim + p serve-scan ]
    [ svs ]
    if
  };

: sim
  (forall ρ; ρ cd:Seq Int^many svs:Seq Int^many cnt:Seq Int^many t:Int^many f:Int^many d:Int^many moved:Int^many p:Int^many sc:Int^many -- ρ svs2:Seq Int^many t2:Int^many moved2:Int^many)
  locals { cd svs cnt t f d moved p sc } {
    cd cnt p t arrive
    locals { cnt2 p2 } {
      cnt2 f prim seq-int.at 0 prim >
      [ cd
        cd svs t f 0 p2 serve-scan
        cnt2 f 0 prim seq-int.set
        t 2 prim +
        f d moved p2
        sc cnt2 f prim seq-int.at prim +
        sim ]
      [ p2 sc prim =
        [ sc cd prim seq-int.len prim =
          [ svs t moved ]
          [ cd svs cnt2 cd p2 prim seq-int.at 1024 prim div f d moved p2 sc sim ]
          if ]
        [ cnt2 f d prim + d 1 dist-loop
          locals { m } {
            m 99 prim =
            [ cd svs cnt2 t f 0 d prim - moved p2 sc sim ]
            [ m
              p2 cd prim seq-int.len prim <
              [ cd p2 prim seq-int.at 1024 prim div t prim - ]
              [ 100000 ]
              if
              imin
              locals { s } {
                cd svs cnt2 t s prim + f s d prim * prim + d moved s prim + p2 sc sim
              } ]
            if
          } ]
        if ]
      if
    }
  };

: unsort
  (forall ρ; ρ cd:Seq Int^many svs:Seq Int^many out:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { cd svs out p } {
    p cd prim seq-int.len prim <
    [ cd svs
      out cd p prim seq-int.at 32 prim mod svs p prim seq-int.at prim seq-int.set
      p 1 prim + unsort ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ times:Seq Int^many floors:Seq Int^many -- ρ served:Seq Int^many endt:Int^many moved:Int^many)
  locals { times floors } {
    times floors 0 prim seq-int.empty mk-codes 1 isort-loop
    locals { cd } {
      cd
      cd prim seq-int.len -1 fill
      21 0 fill
      0 0 1 0 0 0 sim
      locals { svs t mv } {
        cd svs cd prim seq-int.len 0 fill 0 unsort
        t mv
      }
    }
  };
```

### task: date-diff
```firth
: iabs-unused
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x };

: dn
  (forall ρ; ρ y:Int^many m:Int^many d:Int^many -- ρ n:Int^many)
  locals { y m d } {
    y m 2 prim <= [ 1 prim - ] [ ] if
    locals { yy } {
      yy 400 prim div
      locals { era } {
        yy era 400 prim * prim -
        locals { yoe } {
          m 9 prim + 12 prim mod
          locals { mp } {
            153 mp prim * 2 prim + 5 prim div d prim + 1 prim -
            locals { doy } {
              era 146097 prim *
              yoe 365 prim * yoe 4 prim div prim + yoe 100 prim div prim - doy prim +
              prim +
              719468 prim -
            }
          }
        }
      }
    }
  };

: main
  (forall ρ; ρ y1:Int^many m1:Int^many d1:Int^many y2:Int^many m2:Int^many d2:Int^many -- ρ days:Int^many weekday:Int^many doy:Int^many)
  locals { y1 m1 d1 y2 m2 d2 } {
    y2 m2 d2 dn y1 m1 d1 dn prim -
    y2 m2 d2 dn 3 prim + 7 prim mod
    y2 m2 d2 dn y2 1 1 dn prim - 1 prim +
  };
```

### task: heap-alloc
```firth
: imax
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: best-loop
  (forall ρ; ρ fb:Seq Int^many need:Int^many j:Int^many bi:Int^many bl:Int^many -- ρ r:Int^many)
  locals { fb need j bi bl } {
    j fb prim seq-int.len prim <
    [ fb j prim seq-int.at 2048 prim mod
      locals { l } {
        l need prim >= l bl prim < prim and
        [ fb need j 1 prim + j l best-loop ]
        [ fb need j 1 prim + bi bl best-loop ]
        if
      } ]
    [ bi ]
    if
  };

: rem-at
  (forall ρ; ρ fb:Seq Int^many idx:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { fb idx i out } {
    i fb prim seq-int.len prim <
    [ fb idx i 1 prim +
      i idx prim =
      [ out ]
      [ out fb i prim seq-int.at prim seq-int.push ]
      if
      rem-at ]
    [ out ]
    if
  };

: take
  (forall ρ; ρ fb:Seq Int^many bi:Int^many need:Int^many -- ρ r:Seq Int^many)
  locals { fb bi need } {
    fb bi prim seq-int.at 2048 prim mod need prim =
    [ fb bi 0 prim seq-int.empty rem-at ]
    [ fb bi fb bi prim seq-int.at need 2048 prim * prim + need prim - prim seq-int.set ]
    if
  };

: ins-loop
  (forall ρ; ρ fb:Seq Int^many ms:Int^many ml:Int^many i:Int^many placed:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { fb ms ml i placed out } {
    i fb prim seq-int.len prim <
    [ fb i prim seq-int.at
      locals { c } {
        c 2048 prim div c 2048 prim mod
        locals { bs bl } {
          bs bl prim + ms prim =
          [ fb bs ml bl prim + i 1 prim + placed out ins-loop ]
          [ ms ml prim + bs prim =
            [ fb ms ml bl prim + i 1 prim + placed out ins-loop ]
            [ bs ms prim <
              [ fb ms ml i 1 prim + placed out c prim seq-int.push ins-loop ]
              [ placed 0 prim =
                [ fb ms ml i 1 prim + 1
                  out ms 2048 prim * ml prim + prim seq-int.push c prim seq-int.push
                  ins-loop ]
                [ fb ms ml i 1 prim + placed out c prim seq-int.push ins-loop ]
                if ]
              if ]
            if ]
          if
        }
      } ]
    [ placed 0 prim =
      [ out ms 2048 prim * ml prim + prim seq-int.push ]
      [ out ]
      if ]
    if
  };

: insert-free
  (forall ρ; ρ fb:Seq Int^many s:Int^many l:Int^many -- ρ r:Seq Int^many)
  locals { fb s l } { fb s l 0 0 prim seq-int.empty ins-loop };

: ops
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many fb:Seq Int^many res:Seq Int^many live:Seq Int^many i:Int^many -- ρ res2:Seq Int^many fb2:Seq Int^many)
  locals { kinds vals fb res live i } {
    i kinds prim seq-int.len prim <
    [ kinds i prim seq-int.at 0 prim =
      [ fb vals i prim seq-int.at 0 -1 100000 best-loop
        locals { bi } {
          bi -1 prim =
          [ kinds vals fb res -1 prim seq-int.push live 0 prim seq-int.push i 1 prim + ops ]
          [ kinds vals
            fb bi vals i prim seq-int.at take
            res fb bi prim seq-int.at 2048 prim div prim seq-int.push
            live 1 prim seq-int.push
            i 1 prim + ops ]
          if
        } ]
      [ vals i prim seq-int.at
        locals { j } {
          j 0 prim >= j i prim < prim and
          [ live j prim seq-int.at 1 prim = ]
          [ 0 1 prim = ]
          if
          [ kinds vals
            fb res j prim seq-int.at vals j prim seq-int.at insert-free
            res 0 prim seq-int.push
            live j 0 prim seq-int.set 0 prim seq-int.push
            i 1 prim + ops ]
          [ kinds vals fb res -1 prim seq-int.push live 0 prim seq-int.push i 1 prim + ops ]
          if
        } ]
      if ]
    [ res fb ]
    if
  };

: maxlen-loop
  (forall ρ; ρ fb:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { fb i acc } {
    i fb prim seq-int.len prim <
    [ fb i 1 prim + acc fb i prim seq-int.at 2048 prim mod imax maxlen-loop ]
    [ acc ]
    if
  };

: main
  (forall ρ; ρ size:Int^many kinds:Seq Int^many vals:Seq Int^many -- ρ results:Seq Int^many blocks:Int^many largest:Int^many)
  locals { size kinds vals } {
    kinds vals
    prim seq-int.empty size prim seq-int.push
    prim seq-int.empty
    prim seq-int.empty
    0 ops
    locals { res fb } {
      res
      fb prim seq-int.len
      fb 0 0 maxlen-loop
    }
  };
```

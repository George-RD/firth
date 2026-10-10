### task: mini-cpu
```firth
: ix (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.set;
: pu (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.push;
: bi (forall ρ; ρ b:Bool^many -- ρ n:Int^many) [ 1 ] [ 0 ] if;

: zeros (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ t:Seq Int^many)
  locals { s k } { k 0 prim <= [ s ] [ s 0 pu k 1 prim - zeros ] if };

: sl (forall ρ; ρ a:Seq Int^many m:Seq Int^many i:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { a m i e } { i e prim >= [ a ] [ a m i ix pu m i 1 prim + e sl ] if };

: catr (forall ρ; ρ x:Seq Int^many y:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { x y i } { i y prim seq-int.len prim >= [ x ] [ x y i ix pu y i 1 prim + catr ] if };

: cat (forall ρ; ρ x:Seq Int^many y:Seq Int^many -- ρ r:Seq Int^many)
  locals { x y } { x y 0 catr };

: wrap (forall ρ; ρ x:Int^many -- ρ w:Int^many)
  2147483648 prim + 4294967296 prim mod 2147483648 prim -;

: rd (forall ρ; ρ m:Seq Int^many r:Int^many -- ρ v:Int^many)
  10 prim + ix;

: wr (forall ρ; ρ m:Seq Int^many r:Int^many v:Int^many -- ρ m2:Seq Int^many)
  locals { m r v } { m r 10 prim + v st };

: flg (forall ρ; ρ m:Seq Int^many t:Int^many -- ρ m2:Seq Int^many)
  locals { m t } { t wrap locals { w } {
    m 3 w 0 prim = bi st
    4 w 0 prim < bi st
    5 w t prim = prim not bi st } };

: fin (forall ρ; ρ m:Seq Int^many a:Int^many t:Int^many -- ρ m2:Seq Int^many)
  locals { m a t } { m a t wrap wr t flg };

: p2 (forall ρ; ρ acc:Int^many c:Int^many -- ρ r:Int^many)
  locals { acc c } { c 0 prim <= [ acc ] [ acc 2 prim * c 1 prim - p2 ] if };

: pw (forall ρ; ρ c:Int^many -- ρ r:Int^many)
  1 swap p2;

: tdiv (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } { a b prim div locals { q } {
    a 0 prim < a b prim mod 0 prim > prim and
    [ b 0 prim > [ q 1 prim + ] [ q 1 prim - ] if ] [ q ] if } };

: trem (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a a b tdiv b prim * prim - };

: fault (forall ρ; ρ m:Seq Int^many s:Int^many -- ρ m2:Seq Int^many)
  locals { m s } { m 2 s st };

: exec (forall ρ; ρ inp:Seq Int^many m:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ m2:Seq Int^many)
  locals { inp m op a b c } {
  op 0 prim = [ m 2 0 st ] [
  op 1 prim = [ m a b wr ] [
  op 2 prim = [ m a m b rd wr ] [
  op 3 prim = [ m a m b rd m c rd prim + fin ] [
  op 4 prim = [ m a m b rd m c rd prim - fin ] [
  op 5 prim = [ m a m b rd m c rd prim * fin ] [
  op 6 prim = [ m c rd 0 prim = [ m 3 fault ] [ m a m b rd m c rd tdiv fin ] if ] [
  op 7 prim = [ m c rd 0 prim = [ m 3 fault ] [ m a m b rd m c rd trem fin ] if ] [
  op 8 prim = [ m a 0 m b rd prim - fin ] [
  op 9 prim = [ m a m b rd c pw prim * fin ] [
  op 10 prim = [ m a m b rd c pw prim div fin ] [
  op 11 prim = [ m m b rd m c rd prim - flg ] [
  op 12 prim = [ m b rd c prim + locals { ad } {
      ad 0 prim < ad 63 prim > prim or [ m 6 fault ] [ m a m ad 18 prim + ix wr ] if } ] [
  op 13 prim = [ m b rd c prim + locals { ad } {
      ad 0 prim < ad 63 prim > prim or [ m 6 fault ] [ m ad 18 prim + m a rd st ] if } ] [
  op 14 prim = [ m 0 b st ] [
  op 15 prim = [ m 3 ix 1 prim = [ m 0 b st ] [ m ] if ] [
  op 16 prim = [ m 3 ix 0 prim = [ m 0 b st ] [ m ] if ] [
  op 17 prim = [ m 4 ix m 5 ix prim = prim not [ m 0 b st ] [ m ] if ] [
  op 18 prim = [ m 4 ix m 5 ix prim = [ m 0 b st ] [ m ] if ] [
  op 19 prim = [ m 6 ix locals { d } {
      d 16 prim >= [ m 4 fault ] [ m 82 d prim + m a rd st 6 d 1 prim + st ] if } ] [
  op 20 prim = [ m 6 ix locals { d } {
      d 0 prim <= [ m 5 fault ] [ m a m 81 d prim + ix wr 6 d 1 prim - st ] if } ] [
  op 21 prim = [ m 7 ix locals { s } {
      s 8 prim >= [ m 4 fault ] [ m 98 s prim + m 0 ix st 7 s 1 prim + st 0 b st ] if } ] [
  op 22 prim = [ m 7 ix locals { s } {
      s 0 prim <= [ m 5 fault ] [ m 0 m 97 s prim + ix st 7 s 1 prim - st ] if } ] [
  op 23 prim = [ m 8 ix locals { k } {
      k inp prim seq-int.len prim >= [ m 7 fault ] [ m a inp k ix wr 8 k 1 prim + st ] if } ]
  [ m 9 ix locals { k } { m 106 k prim + m a rd st 9 k 1 prim + st } ]
  if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if ] if };

: step (forall ρ; ρ ops:Seq Int^many fa:Seq Int^many fb:Seq Int^many fc:Seq Int^many inp:Seq Int^many m:Seq Int^many -- ρ r:Seq Int^many)
  locals { ops fa fb fc inp m } {
  m 1 ix 300 prim >= [ m 2 1 st ] [
   m 0 ix locals { pc } {
    pc 0 prim < pc ops prim seq-int.len prim >= prim or
    [ m 2 2 st ] [
      inp m 0 pc 1 prim + st ops pc ix fa pc ix fb pc ix fc pc ix exec
      locals { m2 } { m2 2 ix locals { s } {
        s 3 prim >= [ m2 0 pc st ] [
          m2 1 m2 1 ix 1 prim + st locals { m3 } {
            s 0 prim = [ m3 0 pc st ] [ m3 ] if } ] if } } ] if } ] if };

: run (forall ρ; ρ ops:Seq Int^many fa:Seq Int^many fb:Seq Int^many fc:Seq Int^many inp:Seq Int^many m:Seq Int^many -- ρ o1:Seq Int^many o2:Seq Int^many o3:Seq Int^many o4:Seq Int^many o5:Seq Int^many o6:Seq Int^many)
  locals { ops fa fb fc inp m } {
  m 2 ix -1 prim =
  [ ops fa fb fc inp ops fa fb fc inp m step run ]
  [ ops fa fb fc inp m ] if };

: main (forall ρ; ρ ops:Seq Int^many fa:Seq Int^many fb:Seq Int^many fc:Seq Int^many regs:Seq Int^many mem:Seq Int^many inp:Seq Int^many -- ρ out:Seq Int^many status:Int^many executed:Int^many pc:Int^many r:Seq Int^many fm:Seq Int^many flags:Seq Bool^many)
  locals { ops fa fb fc regs mem inp } {
  ops fa fb fc inp
  { 0 0 -1 0 0 0 0 0 0 0 } regs cat mem cat 324 zeros
  run
  locals { po pa pb pc2 pi m } {
    prim seq-int.empty m 106 106 m 9 ix prim + sl
    m 2 ix m 1 ix m 0 ix
    prim seq-int.empty m 10 18 sl
    prim seq-int.empty m 18 82 sl
    prim seq-bool.empty m 3 ix 1 prim = prim seq-bool.push
    m 4 ix 1 prim = prim seq-bool.push
    m 5 ix 1 prim = prim seq-bool.push } };
```
NOTE: not run; written blind. State is one packed Seq Int; the instruction dispatch is a 25-deep nested if chain.

### task: stacker
```firth
: ix (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.set;
: pu (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.push;

: zeros (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ t:Seq Int^many)
  locals { s k } { k 0 prim <= [ s ] [ s 0 pu k 1 prim - zeros ] if };

: sl (forall ρ; ρ a:Seq Int^many m:Seq Int^many i:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { a m i e } { i e prim >= [ a ] [ a m i ix pu m i 1 prim + e sl ] if };

: catr (forall ρ; ρ x:Seq Int^many y:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { x y i } { i y prim seq-int.len prim >= [ x ] [ x y i ix pu y i 1 prim + catr ] if };

: cat (forall ρ; ρ x:Seq Int^many y:Seq Int^many -- ρ r:Seq Int^many)
  locals { x y } { x y 0 catr };

: tab (forall ρ; ρ -- ρ t:Seq Int^many)
  { 2 6 10 14  8 9 10 11  1 5 9 13  4 5 6 7
    5 9 6 10  5 9 6 10  5 9 6 10  5 9 6 10
    2 6 10 7  5 6 7 10  2 6 10 5  5 6 7 2
    2 6 7 11  7 6 10 9  1 5 6 10  3 2 6 5
    3 7 6 10  11 10 6 5  2 6 5 9  7 6 2 1
    2 6 10 11  7 6 5 9  1 2 6 10  3 7 6 5
    3 2 6 10  5 6 7 11  2 6 10 9  1 5 6 7 };

\ m layout: 0 kind 1 rot 2 x 3 y 4 held 5 canhold 6 score 7 rows 8 locks 9 status
\ 10 qpos 11 mpos 13 combo 15 last k 16 width 17 height 18.. board (y*w+x)

: fi (forall ρ; ρ m:Seq Int^many base:Int^many x:Int^many y:Int^many i:Int^many -- ρ ok:Bool^many)
  locals { m base x y i } {
  i 4 prim >= [ true ] [
    tab base i prim + ix locals { code } {
      x code 4 prim div prim + locals { cx } {
        y code 4 prim mod prim + locals { cy } {
          cx 0 prim < cx m 16 ix prim >= prim or cy 0 prim < prim or cy m 17 ix prim >= prim or
          [ false ]
          [ m 18 cy m 16 ix prim * prim + cx prim + ix 0 prim =
            [ m base x y i 1 prim + fi ] [ false ] if ] if } } } ] if };

: fits (forall ρ; ρ m:Seq Int^many k:Int^many r:Int^many x:Int^many y:Int^many -- ρ ok:Bool^many)
  locals { m k r x y } { m k 4 prim * r prim + 4 prim * x y 0 fi };

: spawn (forall ρ; ρ m:Seq Int^many k:Int^many ch:Int^many -- ρ m2:Seq Int^many)
  locals { m k ch } {
  m 0 k st 1 0 st 2 m 16 ix 4 prim - 2 prim div st 3 m 17 ix 4 prim - st 5 ch st
  locals { m2 } {
    m2 m2 0 ix 0 m2 2 ix m2 3 ix fits [ m2 ] [ m2 9 2 st ] if } };

: mvp (forall ρ; ρ m:Seq Int^many dx:Int^many dy:Int^many -- ρ m2:Seq Int^many)
  locals { m dx dy } {
  m m 0 ix m 1 ix m 2 ix dx prim + m 3 ix dy prim + fits
  [ m 2 m 2 ix dx prim + st 3 m 3 ix dy prim + st ] [ m ] if };

: rt (forall ρ; ρ m:Seq Int^many nr:Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m nr i } {
  i 6 prim >= [ m ] [
    { 0 -1 1 0 -2 2 } i ix locals { ox } {
      { 0 0 0 1 0 0 } i ix locals { oy } {
        m m 0 ix nr m 2 ix ox prim + m 3 ix oy prim + fits
        [ m 1 nr st 2 m 2 ix ox prim + st 3 m 3 ix oy prim + st ]
        [ m nr i 1 prim + rt ] if } } ] if };

: lk (forall ρ; ρ m:Seq Int^many base:Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m base i } {
  i 4 prim >= [ m ] [
    tab base i prim + ix locals { code } {
      m 18 m 3 ix code 4 prim mod prim + m 16 ix prim * prim + m 2 ix code 4 prim div prim + prim + 1 st
      base i 1 prim + lk } ] if };

: dn (forall ρ; ρ m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { m } {
  m m 0 ix m 1 ix m 2 ix m 3 ix 1 prim - fits
  [ m 3 m 3 ix 1 prim - st dn ] [ m ] if };

: rf (forall ρ; ρ m:Seq Int^many y:Int^many x:Int^many -- ρ ok:Bool^many)
  locals { m y x } {
  x m 16 ix prim >= [ true ] [
    m 18 y m 16 ix prim * prim + x prim + ix 0 prim = [ false ] [ m y x 1 prim + rf ] if ] if };

: ar (forall ρ; ρ m:Seq Int^many nb:Seq Int^many y:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m nb y x } {
  x m 16 ix prim >= [ nb ] [
    m nb m 18 y m 16 ix prim * prim + x prim + ix pu y x 1 prim + ar ] if };

: cr (forall ρ; ρ m:Seq Int^many nb:Seq Int^many y:Int^many -- ρ r:Seq Int^many)
  locals { m nb y } {
  y m 17 ix prim >= [ nb ] [
    m y 0 rf [ m nb y 1 prim + cr ] [ m nb y 0 ar m swap y 1 prim + cr ] if ] if };

: cl (forall ρ; ρ m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { m } {
  m prim seq-int.empty 0 cr locals { nb } {
    m 17 ix nb prim seq-int.len m 16 ix prim div prim - locals { k } {
      prim seq-int.empty m 0 18 sl nb cat k m 16 ix prim * zeros
      locals { m2 } {
        k 0 prim =
        [ m2 13 0 st 8 m2 8 ix 1 prim + st ]
        [ { 100 300 500 800 } k 1 prim - ix locals { b0 } {
            k 4 prim = m2 15 ix 4 prim = prim and [ 1200 ] [ b0 ] if
            m2 13 ix 50 prim * prim +
            1 m2 7 ix 10 prim div prim + prim *
            locals { gain } {
              m2 6 m2 6 ix gain prim + st 7 m2 7 ix k prim + st
              8 m2 8 ix 1 prim + st 13 m2 13 ix 1 prim + st 15 k st } } ] if } } } };

: dropc (forall ρ; ρ m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { m } {
  m dn locals { m1 } {
    m1 m1 0 ix 4 prim * m1 1 ix prim + 4 prim * 0 lk 0 -1 st cl } };

: nxt (forall ρ; ρ q:Seq Int^many m:Seq Int^many ch:Int^many -- ρ m2:Seq Int^many)
  locals { q m ch } {
  m 10 ix locals { p } {
    p q prim seq-int.len prim >= [ m 9 0 st ]
    [ m 10 p 1 prim + st q p ix ch spawn ] if } };

: hold (forall ρ; ρ q:Seq Int^many m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { q m } {
  m 5 ix 0 prim = [ m ] [
    m 4 ix -1 prim =
    [ m 4 m 0 ix st q swap 0 nxt ]
    [ m 4 m 0 ix st m 4 ix 0 spawn ] if ] if };

: cmd (forall ρ; ρ q:Seq Int^many m:Seq Int^many c:Int^many -- ρ m2:Seq Int^many)
  locals { q m c } {
  c 0 prim = [ m dropc ] [
  c 1 prim = [ m -1 0 mvp ] [
  c 2 prim = [ m 1 0 mvp ] [
  c 5 prim = [ m 0 -1 mvp ] [
  c 3 prim = [ m m 1 ix 1 prim + 4 prim mod 0 rt ] [
  c 4 prim = [ m m 1 ix 3 prim + 4 prim mod 0 rt ] [
  q m hold ] if ] if ] if ] if ] if ] if };

: play (forall ρ; ρ q:Seq Int^many mv:Seq Int^many m:Seq Int^many -- ρ r:Seq Int^many)
  locals { q mv m } {
  m 9 ix -1 prim = prim not [ m ] [
    m 0 ix -1 prim =
    [ q m 1 nxt locals { m2 } { q mv m2 play } ]
    [ m 11 ix locals { p } {
        p mv prim seq-int.len prim >= [ m 9 1 st ]
        [ q m 11 p 1 prim + st mv p ix cmd locals { m2 } { q mv m2 play } ] if } ] if ] if };

: ht (forall ρ; ρ m:Seq Int^many x:Int^many y:Int^many -- ρ h:Int^many)
  locals { m x y } {
  y 0 prim < [ 0 ] [
    m 18 y m 16 ix prim * prim + x prim + ix 0 prim = [ m x y 1 prim - ht ] [ y 1 prim + ] if ] if };

: hs (forall ρ; ρ m:Seq Int^many acc:Seq Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m acc x } {
  x m 16 ix prim >= [ acc ] [
    m acc m x m 17 ix 1 prim - ht pu x 1 prim + hs ] if };

: main (forall ρ; ρ w:Int^many h:Int^many q:Seq Int^many mv:Seq Int^many -- ρ hs:Seq Int^many score:Int^many rows:Int^many locks:Int^many status:Int^many held:Int^many)
  locals { w h q mv } {
  q mv
  { -1 0 0 0 -1 0 0 0 0 -1 0 0 0 0 0 0 } w pu h pu w h prim * zeros
  play
  locals { m } {
    m prim seq-int.empty 0 hs m 6 ix m 7 ix m 8 ix m 9 ix m 4 ix } };
```
NOTE: not run; written blind. Piece cells are packed in a 112-entry table as dx*4+dy codes.

### task: bank-days
```firth
: ix (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.set;
: pu (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.push;

: zeros (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ t:Seq Int^many)
  locals { s k } { k 0 prim <= [ s ] [ s 0 pu k 1 prim - zeros ] if };

: pd (forall ρ; ρ s:Seq Int^many size:Int^many -- ρ t:Seq Int^many)
  locals { s size } { s prim seq-int.len size prim >= [ s ] [ s 0 pu size pd ] if };

: sl (forall ρ; ρ a:Seq Int^many m:Seq Int^many i:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { a m i e } { i e prim >= [ a ] [ a m i ix pu m i 1 prim + e sl ] if };

: catr (forall ρ; ρ x:Seq Int^many y:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { x y i } { i y prim seq-int.len prim >= [ x ] [ x y i ix pu y i 1 prim + catr ] if };

: cat (forall ρ; ρ x:Seq Int^many y:Seq Int^many -- ρ r:Seq Int^many)
  locals { x y } { x y 0 catr };

\ m layout: 0 y 1 mo 2 d 3 rej 4 ia 5 it 6 fee 7 n 8 ntx 9 nso 10 credit 11 debit
\ 12 bal 18 acc 24 od 30 sorej 36 canc 42 lim 48 txd 108 txk 168 txa 228 txo
\ 288 txm 348 sod 354 sof 360 sot 366 som

: gk (forall ρ; ρ m:Seq Int^many b:Int^many k:Int^many -- ρ v:Int^many)
  locals { m b k } { m b k prim + ix };

: dim (forall ρ; ρ y:Int^many mo:Int^many -- ρ n:Int^many)
  locals { y mo } {
  mo 2 prim =
  [ y 4 prim mod 0 prim = y 100 prim mod 0 prim = prim not y 400 prim mod 0 prim = prim or prim and
    [ 29 ] [ 28 ] if ]
  [ mo 4 prim = mo 6 prim = prim or mo 9 prim = prim or mo 11 prim = prim or [ 30 ] [ 31 ] if ] if };

: pay (forall ρ; ρ m:Seq Int^many a:Int^many b:Int^many am:Int^many kd:Int^many -- ρ m2:Seq Int^many r:Int^many)
  locals { m a b am kd } {
  m 12 a prim + ix am prim - 0 m 42 a prim + ix prim - prim >=
  kd 3 prim = a b prim = prim and prim not prim and
  [ m 12 a prim + m 12 a prim + ix am prim - st locals { m1 } {
      kd 3 prim = [ m1 12 b prim + m1 12 b prim + ix am prim + st ] [ m1 ] if 0 } ]
  [ m 3 m 3 ix 1 prim + st 1 ] if };

: oo (forall ρ; ρ m:Seq Int^many dno:Int^many k:Int^many -- ρ m2:Seq Int^many)
  locals { m dno k } {
  k m 8 ix prim >= [ m ] [
    m 48 k gk dno prim =
    [ m 108 k gk locals { kd } { m 168 k gk locals { a } { m 228 k gk locals { b } { m 288 k gk locals { am } {
        kd 1 prim = [ m 12 a prim + m 12 a prim + ix am prim + st ]
        [ m a b am kd pay drop ] if } } } } ]
    [ m ] if
    dno k 1 prim + oo ] if };

: so (forall ρ; ρ m:Seq Int^many k:Int^many -- ρ m2:Seq Int^many)
  locals { m k } {
  k m 9 ix prim >= [ m ] [
    m 36 k gk 0 prim =
    m 348 k gk locals { dom } { m 0 ix m 1 ix dim locals { dm } {
      dom dm prim > [ dm ] [ dom ] if m 2 ix prim = } }
    prim and
    [ m m 354 k gk m 360 k gk m 366 k gk 3 pay locals { m1 r } {
        r 1 prim =
        [ m1 30 k prim + m1 30 k prim + ix 1 prim + st locals { m2 } {
            m2 30 k prim + ix 2 prim >= [ m2 36 k prim + 1 st ] [ m2 ] if } ]
        [ m1 30 k prim + 0 st ] if } ]
    [ m ] if
    k 1 prim + so ] if };

: ic (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 7 ix prim >= [ m ] [
    m 12 i prim + ix locals { b } {
      b 0 prim >
      [ m 18 i prim + m 18 i prim + ix b m 10 ix prim * prim + st ]
      [ b 0 prim <
        [ m 18 i prim + m 18 i prim + ix b m 11 ix prim * prim + st 24 i prim + 1 st ]
        [ m ] if ] if }
    i 1 prim + ic ] if };

: po (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 7 ix prim >= [ m ] [
    m 18 i prim + ix locals { s } {
      s 0 prim >=
      [ m 12 i prim + m 12 i prim + ix s 1000000 prim div prim + st
        4 m 4 ix s 1000000 prim div prim + st ]
      [ m 12 i prim + m 12 i prim + ix 0 s prim - 1000000 prim div prim - st
        5 m 5 ix 0 s prim - 1000000 prim div prim + st ] if
      18 i prim + 0 st
      locals { m1 } {
        m1 24 i prim + ix 1 prim =
        [ m1 12 i prim + m1 12 i prim + ix 1000 prim - st 6 m1 6 ix 1000 prim + st 24 i prim + 0 st ]
        [ m1 ] if } }
    i 1 prim + po ] if };

: adv (forall ρ; ρ m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { m } {
  m 2 ix m 0 ix m 1 ix dim prim >=
  [ m 2 1 st locals { m1 } {
      m1 1 ix 12 prim =
      [ m1 1 1 st 0 m1 0 ix 1 prim + st ]
      [ m1 1 m1 1 ix 1 prim + st ] if } ]
  [ m 2 m 2 ix 1 prim + st ] if };

: dstep (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  m i 0 oo 0 so 0 ic locals { m1 } {
    m1 2 ix m1 0 ix m1 1 ix dim prim = [ m1 0 po adv ] [ m1 adv ] if } };

: dl (forall ρ; ρ m:Seq Int^many i:Int^many dys:Int^many -- ρ m2:Seq Int^many)
  locals { m i dys } {
  i dys prim >= [ m ] [ m i dstep i 1 prim + dys dl ] if };

: cb (forall ρ; ρ m:Seq Int^many acc:Seq Bool^many k:Int^many -- ρ r:Seq Bool^many)
  locals { m acc k } {
  k m 9 ix prim >= [ acc ] [
    m acc m 36 k gk 1 prim = prim seq-bool.push k 1 prim + cb ] if };

: main (forall ρ; ρ yr:Int^many mo:Int^many dy:Int^many dys:Int^many bal:Seq Int^many lim:Seq Int^many cr:Int^many dr:Int^many td:Seq Int^many tk:Seq Int^many ta:Seq Int^many tov:Seq Int^many tm:Seq Int^many sd:Seq Int^many sf:Seq Int^many sto:Seq Int^many sm:Seq Int^many -- ρ final:Seq Int^many rej:Int^many canc:Seq Bool^many ia:Int^many it:Int^many fee:Int^many)
  locals { yr mo dy dys bal lim cr dr td tk ta tov tm sd sf sto sm } {
  prim seq-int.empty yr pu mo pu dy pu 0 pu 0 pu 0 pu 0 pu
  bal prim seq-int.len pu td prim seq-int.len pu sd prim seq-int.len pu cr pu dr pu
  bal cat 18 pd 24 zeros lim cat 48 pd td cat 108 pd tk cat 168 pd ta cat 228 pd
  tov cat 288 pd tm cat 348 pd sd cat 354 pd sf cat 360 pd sto cat 366 pd sm cat 372 pd
  0 dys dl
  locals { m } {
    prim seq-int.empty m 12 12 m 7 ix prim + sl
    m 3 ix
    m prim seq-bool.empty 0 cb
    m 4 ix m 5 ix m 6 ix } };
```
NOTE: not run; written blind. All state is packed into one Seq Int of 372 entries.

### task: formula-sheet
```firth
: ix (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.set;
: pu (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.push;
: bi (forall ρ; ρ b:Bool^many -- ρ n:Int^many) [ 1 ] [ 0 ] if;

: zeros (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ t:Seq Int^many)
  locals { s k } { k 0 prim <= [ s ] [ s 0 pu k 1 prim - zeros ] if };

: sl (forall ρ; ρ a:Seq Int^many m:Seq Int^many i:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { a m i e } { i e prim >= [ a ] [ a m i ix pu m i 1 prim + e sl ] if };

\ m layout: 0 n 1 L(20) 21 state(20) 41 bad(20) 61 V(20) 81 K 241 X 401 Y 561 Z (n*8 each)
\ 721 sp 722.. eval stack 731 error flag. Error value is 4000000000.

: lim (forall ρ; ρ r:Int^many -- ρ r2:Int^many)
  locals { r } { r 1000000000 prim > r -1000000000 prim < prim or [ 4000000000 ] [ r ] if };

: mn (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: mx (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: tdiv (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } { a b prim div locals { q } {
    a 0 prim < a b prim mod 0 prim > prim and
    [ b 0 prim > [ q 1 prim + ] [ q 1 prim - ] if ] [ q ] if } };

: calc (forall ρ; ρ x:Int^many c:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  locals { x c a b } {
  x 7 prim =
  [ c 4000000000 prim = [ 4000000000 ] [ c 0 prim = [ b ] [ a ] if ] if ]
  [ x 8 prim =
    [ b 4000000000 prim = [ 4000000000 ] [ 0 b prim - lim ] if ]
    [ a 4000000000 prim = b 4000000000 prim = prim or
      [ 4000000000 ]
      [ x 1 prim = [ a b prim + lim ]
        [ x 2 prim = [ a b prim - lim ]
          [ x 3 prim = [ a b prim * lim ]
            [ x 4 prim = [ b 0 prim = [ 4000000000 ] [ a b tdiv lim ] if ]
              [ x 5 prim = [ a b prim < bi ] [ a b prim = bi ] if ] if ] if ] if ] if ] if ] if ] if };

: pv (forall ρ; ρ m:Seq Int^many v:Int^many -- ρ m2:Seq Int^many)
  locals { m v } { m 721 ix locals { sp } { m 722 sp prim + v st 721 sp 1 prim + st } };

: opx (forall ρ; ρ m:Seq Int^many x:Int^many -- ρ m2:Seq Int^many)
  locals { m x } {
  m 721 ix locals { sp } {
    x 8 prim = [ 1 ] [ x 7 prim = [ 3 ] [ 2 ] if ] if locals { ar } {
      sp ar prim < [ m 731 1 st ]
      [ m 722 sp prim + ar prim -
        x m 722 sp prim + 3 prim - ix m 722 sp prim + 2 prim - ix m 722 sp prim + 1 prim - ix calc
        st 721 sp ar prim - 1 prim + st ] if } } };

: fl (forall ρ; ρ m:Seq Int^many x:Int^many c:Int^many z:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m x c z acc } {
  c z prim > [ acc ] [
    m 61 c prim + ix locals { v } {
      m x c 1 prim + z
      x 4 prim =
      [ v 4000000000 prim = [ acc ] [ acc 1 prim + ] if ]
      [ acc 4000000000 prim = v 4000000000 prim = prim or
        [ 4000000000 ]
        [ x 1 prim = [ acc v prim + ] [ x 2 prim = [ acc v mn ] [ acc v mx ] if ] if ] if ] if
      fl } ] if };

: fnc (forall ρ; ρ m:Seq Int^many x:Int^many y:Int^many z:Int^many -- ρ m2:Seq Int^many)
  locals { m x y z } {
  y 0 prim < z m 0 ix prim >= prim or y z prim > prim or
  [ m 4000000000 pv ]
  [ x 1 prim = x 4 prim = prim or
    [ y 0 ] [ y 1 prim + m 61 y prim + ix ] if
    locals { c0 acc0 } { m x c0 z acc0 fl lim locals { r } { m r pv } } ] if };

: ev (forall ρ; ρ m:Seq Int^many i:Int^many j:Int^many -- ρ m2:Seq Int^many)
  locals { m i j } {
  j m 1 i prim + ix prim >= [ m ] [
    m 81 i 8 prim * prim + j prim + ix locals { k } {
    m 241 i 8 prim * prim + j prim + ix locals { x } {
    m 401 i 8 prim * prim + j prim + ix locals { y } {
    m 561 i 8 prim * prim + j prim + ix locals { z } {
      k 0 prim = [ m x pv ]
      [ k 1 prim =
        [ m x 0 prim < x m 0 ix prim >= prim or [ 4000000000 ] [ m 61 x prim + ix ] if pv ]
        [ k 2 prim = [ m x opx ] [ m x y z fnc ] if ] if ] if
      i j 1 prim + ev } } } } ] if };

: res (forall ρ; ρ m:Seq Int^many -- ρ v:Int^many)
  locals { m } {
  m 731 ix 0 prim = m 721 ix 1 prim = prim and [ m 722 ix ] [ 4000000000 ] if };

: visit (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  m 21 i prim + ix 0 prim = prim not [ m ] [
    m 21 i prim + 1 st i 0 rl locals { m1 } {
      m1 21 i prim + 2 st locals { m2 } {
        m2 41 i prim + ix 0 prim =
        [ m2 721 0 st 731 0 st i 0 ev locals { m3 } { m3 61 i prim + m3 res st } ]
        [ m2 61 i prim + 4000000000 st ] if } } ] if };

: ref (forall ρ; ρ m:Seq Int^many i:Int^many c:Int^many -- ρ m2:Seq Int^many)
  locals { m i c } {
  m c visit locals { m1 } {
    m1 21 c prim + ix 1 prim = m1 41 c prim + ix 1 prim = prim or
    [ m1 41 i prim + 1 st ] [ m1 ] if } };

: rng (forall ρ; ρ m:Seq Int^many i:Int^many c:Int^many z:Int^many -- ρ m2:Seq Int^many)
  locals { m i c z } {
  c z prim > [ m ] [ m i c ref i c 1 prim + z rng ] if };

: rl (forall ρ; ρ m:Seq Int^many i:Int^many j:Int^many -- ρ m2:Seq Int^many)
  locals { m i j } {
  j m 1 i prim + ix prim >= [ m ] [
    m 81 i 8 prim * prim + j prim + ix locals { k } {
    m 241 i 8 prim * prim + j prim + ix locals { x } {
    m 401 i 8 prim * prim + j prim + ix locals { y } {
    m 561 i 8 prim * prim + j prim + ix locals { z } {
      k 1 prim = x 0 prim >= prim and x m 0 ix prim < prim and
      [ m i x ref ]
      [ k 3 prim = y 0 prim >= prim and z m 0 ix prim < prim and y z prim <= prim and
        [ m i y z rng ] [ m ] if ] if
      i j 1 prim + rl } } } } ] if };

: sf (forall ρ; ρ m:Seq Int^many cell:Int^many len:Int^many k:Seq Int^many xs:Seq Int^many ys:Seq Int^many zs:Seq Int^many off:Int^many j:Int^many -- ρ m2:Seq Int^many)
  locals { m cell len k xs ys zs off j } {
  j len prim >= [ m ] [
    m 81 cell 8 prim * prim + j prim + k off j prim + ix st
    241 cell 8 prim * prim + j prim + xs off j prim + ix st
    401 cell 8 prim * prim + j prim + ys off j prim + ix st
    561 cell 8 prim * prim + j prim + zs off j prim + ix st
    cell len k xs ys zs off j 1 prim + sf ] if };

: setf (forall ρ; ρ m:Seq Int^many cell:Int^many len:Int^many k:Seq Int^many xs:Seq Int^many ys:Seq Int^many zs:Seq Int^many off:Int^many -- ρ m2:Seq Int^many)
  locals { m cell len k xs ys zs off } {
  m 1 cell prim + len st cell len k xs ys zs off 0 sf };

: ld (forall ρ; ρ m:Seq Int^many lens:Seq Int^many k:Seq Int^many xs:Seq Int^many ys:Seq Int^many zs:Seq Int^many i:Int^many off:Int^many -- ρ m2:Seq Int^many)
  locals { m lens k xs ys zs i off } {
  i m 0 ix prim >= [ m ] [
    lens i ix locals { len } {
      m i len k xs ys zs off setf
      lens k xs ys zs i 1 prim + off len prim + ld } ] if };

: rs (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 0 ix prim >= [ m ] [ m 21 i prim + 0 st 41 i prim + 0 st i 1 prim + rs ] if };

: all (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 0 ix prim >= [ m ] [ m i visit i 1 prim + all ] if };

: cd (forall ρ; ρ m:Seq Int^many pv:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m pv i acc } {
  i m 0 ix prim >= [ acc ] [
    m pv i 1 prim + acc m 61 i prim + ix pv i ix prim = prim not bi prim + cd ] if };

: edl (forall ρ; ρ m:Seq Int^many ec:Seq Int^many el:Seq Int^many ek:Seq Int^many ex:Seq Int^many ey:Seq Int^many ez:Seq Int^many e:Int^many off:Int^many chg:Seq Int^many -- ρ m2:Seq Int^many c2:Seq Int^many)
  locals { m ec el ek ex ey ez e off chg } {
  e ec prim seq-int.len prim >= [ m chg ] [
    prim seq-int.empty m 61 61 m 0 ix prim + sl locals { pv0 } {
      m ec e ix el e ix ek ex ey ez off setf 0 rs 0 all locals { m2 } {
        m2 pv0 0 0 cd locals { cnt } {
          m2 ec el ek ex ey ez e 1 prim + off el e ix prim + chg cnt pu edl } } } ] if };

: vo (forall ρ; ρ m:Seq Int^many a:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m a i } {
  i m 0 ix prim >= [ a ] [
    m a m 61 i prim + ix locals { v } { v 4000000000 prim = [ 0 ] [ v ] if } pu
    i 1 prim + vo ] if };

: eo (forall ρ; ρ m:Seq Int^many a:Seq Bool^many i:Int^many -- ρ r:Seq Bool^many)
  locals { m a i } {
  i m 0 ix prim >= [ a ] [
    m a m 61 i prim + ix 4000000000 prim = prim seq-bool.push i 1 prim + eo ] if };

: main (forall ρ; ρ lens:Seq Int^many kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many zs:Seq Int^many ec:Seq Int^many el:Seq Int^many ek:Seq Int^many ex:Seq Int^many ey:Seq Int^many ez:Seq Int^many -- ρ values:Seq Int^many errors:Seq Bool^many changed:Seq Int^many)
  locals { lens kinds xs ys zs ec el ek ex ey ez } {
  prim seq-int.empty 732 zeros 0 lens prim seq-int.len st
  locals { m0 } {
    m0 lens kinds xs ys zs 0 0 ld 0 all locals { m1 } {
      m1 ec el ek ex ey ez 0 0 prim seq-int.empty edl locals { m2 chg } {
        m2 prim seq-int.empty 0 vo
        m2 prim seq-bool.empty 0 eo
        chg } } } };
```
NOTE: not run; written blind. Cells are evaluated by a depth-first walk that also detects cycles; the eval stack lives inside the single packed Seq Int. Fuel use over five sheet evaluations is unmeasured.

### task: blackjack
```firth
: ix (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.set;
: pu (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ t:Seq Int^many) prim seq-int.push;
: bi (forall ρ; ρ b:Bool^many -- ρ n:Int^many) [ 1 ] [ 0 ] if;

: zeros (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ t:Seq Int^many)
  locals { s k } { k 0 prim <= [ s ] [ s 0 pu k 1 prim - zeros ] if };

: sl (forall ρ; ρ a:Seq Int^many m:Seq Int^many i:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { a m i e } { i e prim >= [ a ] [ a m i ix pu m i 1 prim + e sl ] if };

: cp (forall ρ; ρ m:Seq Int^many s:Seq Int^many base:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m s base i } {
  i s prim seq-int.len prim >= [ m ] [ m base i prim + s i ix st s base i 1 prim + cp ] if };

\ m layout: 0 pos 1 fail 2 rounds 3 busts 4 nats 5 stop 6 bustflag 7 live 8 up/count 9 np
\ 10 bankroll(5) 15 bet(5) 20+6i: part c1 c2 nat nh delta
\ hands 50+(2i+h)*4: hard ace ncards stake. dealer hand at 90.

: cv (forall ρ; ρ c:Int^many -- ρ v:Int^many) locals { c } { c 10 prim > [ 10 ] [ c ] if };

: hb (forall ρ; ρ i:Int^many h:Int^many -- ρ b:Int^many)
  locals { i h } { 50 i 2 prim * h prim + 4 prim * prim + };

: draw (forall ρ; ρ sh:Seq Int^many m:Seq Int^many -- ρ m2:Seq Int^many c:Int^many)
  locals { sh m } {
  m 0 ix locals { p } {
    p sh prim seq-int.len prim >= [ m 1 1 st 1 ] [ m 0 p 1 prim + st sh p ix ] if } };

: hadd (forall ρ; ρ m:Seq Int^many b:Int^many c:Int^many -- ρ m2:Seq Int^many)
  locals { m b c } {
  c 1 prim = [ m b 1 prim + 1 st ] [ m ] if
  locals { m1 } { m1 b m1 b ix c cv prim + st
    locals { m2 } { m2 b 2 prim + m2 b 2 prim + ix 1 prim + st } } };

: htot (forall ρ; ρ m:Seq Int^many b:Int^many -- ρ t:Int^many sf:Int^many)
  locals { m b } {
  m b ix locals { hs } {
    m b 1 prim + ix 1 prim = hs 11 prim <= prim and
    [ hs 10 prim + 1 ] [ hs 0 ] if } };

: hset (forall ρ; ρ m:Seq Int^many b:Int^many c:Int^many bt:Int^many -- ρ m2:Seq Int^many)
  locals { m b c bt } {
  m b c cv st b 1 prim + c 1 prim = bi st b 2 prim + 1 st b 3 prim + bt st };

: dh (forall ρ; ρ sh:Seq Int^many m:Seq Int^many b:Int^many -- ρ m2:Seq Int^many)
  locals { sh m b } { sh m draw locals { m1 c } { m1 b c hadd } };

: ts (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ n:Int^many)
  locals { m i } {
  m i 0 hb 3 prim + ix
  m 20 i 6 prim * prim + 4 prim + ix 2 prim = [ m i 1 hb 3 prim + ix ] [ 0 ] if prim + };

: lv (forall ρ; ρ m:Seq Int^many i:Int^many h:Int^many -- ρ m2:Seq Int^many)
  locals { m i h } {
  m i h hb htot drop 21 prim <= [ m 7 1 st ] [ m ] if };

: hl (forall ρ; ρ sh:Seq Int^many m:Seq Int^many b:Int^many up:Int^many -- ρ m2:Seq Int^many)
  locals { sh m b up } {
  m b htot locals { t sf } {
    m 1 ix 0 prim = t 21 prim <= prim and
    sf 1 prim = t 17 prim <= prim and
    sf 0 prim = t 11 prim <= t 16 prim <= up 1 prim = up 7 prim >= prim or prim and prim or prim and
    prim or prim and
    [ sh m b dh sh swap b up hl ] [ m ] if } };

: ph (forall ρ; ρ sh:Seq Int^many m:Seq Int^many i:Int^many h:Int^many up:Int^many -- ρ m2:Seq Int^many)
  locals { sh m i h up } {
  i h hb locals { b } {
    m b htot locals { t sf } {
      m b 2 prim + ix 2 prim = sf 0 prim = prim and t 10 prim = t 11 prim = prim or prim and
      up 2 prim >= up 9 prim <= prim and prim and
      m 10 i prim + ix m i ts m 15 i prim + ix prim + prim >= prim and
      [ m b 3 prim + m b 3 prim + ix 2 prim * st sh swap b dh i h lv ]
      [ sh m b up hl i h lv ] if } } };

: pp (forall ρ; ρ sh:Seq Int^many m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { sh m i } {
  20 i 6 prim * prim + locals { rb } {
  m rb 1 prim + ix locals { c1 } { m rb 2 prim + ix locals { c2 } { m 15 i prim + ix locals { bt } {
    c1 c2 prim = c1 1 prim = c1 8 prim = prim or prim and
    m 10 i prim + ix bt 2 prim * prim >= prim and
    [ m i 0 hb c1 bt hset i 1 hb c2 bt hset rb 4 prim + 2 st
      sh swap i 0 hb dh sh swap i 1 hb dh
      c1 1 prim =
      [ i 0 lv i 1 lv ]
      [ sh swap i 0 m 8 ix ph sh swap i 1 m 8 ix ph ] if ]
    [ sh m i 0 m 8 ix ph ] if } } } } };

: dl (forall ρ; ρ sh:Seq Int^many m:Seq Int^many i:Int^many ps:Int^many -- ρ m2:Seq Int^many)
  locals { sh m i ps } {
  i m 9 ix prim >= [ m ] [
    m 20 i 6 prim * prim + ix 1 prim =
    [ sh m draw locals { m1 c } {
        m1 20 i 6 prim * prim + 1 prim + ps prim + c st i 0 hb c hadd } ]
    [ m ] if
    sh swap i 1 prim + ps dl ] if };

: zr (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } { i 95 prim >= [ m ] [ m i 0 st i 1 prim + zr ] if };

: ini (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 9 ix prim >= [ m ] [
    m 20 i 6 prim * prim + m 10 i prim + ix m 15 i prim + ix prim >= bi st
    locals { m1 } {
      m1 20 i 6 prim * prim + ix 1 prim =
      [ m1 i 0 hb 3 prim + m1 15 i prim + ix st
        20 i 6 prim * prim + 4 prim + 1 st
        8 m1 8 ix 1 prim + st ]
      [ m1 ] if }
    i 1 prim + ini ] if };

: nt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 9 ix prim >= [ m ] [
    m 20 i 6 prim * prim + ix 1 prim = m i 0 hb htot drop 21 prim = prim and
    [ m 20 i 6 prim * prim + 3 prim + 1 st ] [ m ] if
    i 1 prim + nt ] if };

: dnl (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 9 ix prim >= [ m ] [
    m 20 i 6 prim * prim + ix 1 prim = m 20 i 6 prim * prim + 3 prim + ix 0 prim = prim and
    [ m 20 i 6 prim * prim + 5 prim + 0 m 15 i prim + ix prim - st ] [ m ] if
    i 1 prim + dnl ] if };

: pall (forall ρ; ρ sh:Seq Int^many m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { sh m i } {
  i m 9 ix prim >= [ m ] [
    m 20 i 6 prim * prim + ix 1 prim =
    [ m 20 i 6 prim * prim + 3 prim + ix 1 prim =
      [ m 20 i 6 prim * prim + 5 prim + m 15 i prim + ix 3 prim * 2 prim div st ]
      [ sh m i pp ] if ]
    [ m ] if
    sh swap i 1 prim + pall ] if };

: dd (forall ρ; ρ sh:Seq Int^many m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { sh m } {
  m 90 htot drop locals { t } {
    m 1 ix 0 prim = t 17 prim < prim and
    [ sh m 90 dh sh swap dd ] [ m ] if } };

: s1 (forall ρ; ρ m:Seq Int^many i:Int^many h:Int^many d:Int^many -- ρ m2:Seq Int^many)
  locals { m i h d } {
  i h hb locals { b } {
    m b htot locals { t sf } {
      m b 3 prim + ix locals { sk } {
        t 21 prim > [ 0 sk prim - ]
        [ d 21 prim > d t prim < prim or [ sk ]
          [ d t prim > [ 0 sk prim - ] [ 0 ] if ] if ] if
        locals { dl2 } {
          m 20 i 6 prim * prim + 5 prim + m 20 i 6 prim * prim + 5 prim + ix dl2 prim + st } } } } };

: se (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ m2:Seq Int^many)
  locals { m i d } {
  m i 0 d s1 locals { m1 } {
    m1 20 i 6 prim * prim + 4 prim + ix 2 prim = [ m1 i 1 d s1 ] [ m1 ] if } };

: sa (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ m2:Seq Int^many)
  locals { m i d } {
  i m 9 ix prim >= [ m ] [
    m 20 i 6 prim * prim + ix 1 prim = m 20 i 6 prim * prim + 3 prim + ix 0 prim = prim and
    [ m i d se ] [ m ] if
    i 1 prim + d sa ] if };

: ap (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ m2:Seq Int^many)
  locals { m i } {
  i m 9 ix prim >= [ m ] [
    m 10 i prim + m 10 i prim + ix m 20 i 6 prim * prim + 5 prim + ix prim + st
    4 m 4 ix m 20 i 6 prim * prim + 3 prim + ix prim + st
    i 1 prim + ap ] if };

: fz (forall ρ; ρ m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { m } {
  m 1 ix 1 prim = [ m 5 1 st ] [
    m 2 m 2 ix 1 prim + st
    3 m 3 ix m 92 ix 2 prim > m 90 htot drop 21 prim > prim and bi prim + st
    0 ap ] if };

: rnd (forall ρ; ρ sh:Seq Int^many m:Seq Int^many -- ρ m2:Seq Int^many)
  locals { sh m } {
  m 1 0 st 6 0 st 7 0 st 8 0 st 20 zr 0 ini locals { m1 } {
    m1 8 ix 0 prim = [ m1 5 1 st ] [
      sh m1 0 0 dl
      sh swap draw locals { m2 c } { m2 8 c st 90 c hadd }
      sh swap 0 1 dl
      sh swap draw locals { m3 c } { m3 90 c hadd }
      0 nt locals { m4 } {
        m4 8 ix cv 10 prim = m4 8 ix 1 prim = prim or m4 90 htot drop 21 prim = prim and
        [ m4 0 dnl ]
        [ sh m4 0 pall locals { m5 } {
            m5 7 ix 1 prim = m5 1 ix 0 prim = prim and [ sh m5 dd ] [ m5 ] if
            locals { m6 } { m6 90 htot drop locals { d } { m6 0 d sa } } } ] if
        fz } ] if } };

: game (forall ρ; ρ sh:Seq Int^many m:Seq Int^many r:Int^many -- ρ m2:Seq Int^many)
  locals { sh m r } {
  r 0 prim <= m 5 ix 1 prim = prim or [ m ] [ sh m rnd sh swap r 1 prim - game ] if };

: main (forall ρ; ρ shoe:Seq Int^many bk:Seq Int^many bt:Seq Int^many rounds:Int^many -- ρ final:Seq Int^many played:Int^many busts:Int^many nats:Int^many)
  locals { shoe bk bt rounds } {
  shoe
  prim seq-int.empty 96 zeros 9 bk prim seq-int.len st bk 10 0 cp bt 15 0 cp
  rounds game
  locals { m } {
    prim seq-int.empty m 10 10 m 9 ix prim + sl
    m 2 ix m 3 ix m 4 ix } };
```
NOTE: not run; written blind. Hands, round state and the shoe position live in one packed Seq Int; a shoe-exhausted flag voids the round.

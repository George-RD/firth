### task: warehouse
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: inc (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int) 1 addto ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;
: col (forall ρ; ρ m:Seq Int b:Int k:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m b k n acc } {
    k n prim >= [ acc ]
    [ m b k 1 prim + n acc m b k prim + rd prim seq-int.push col ] if } ;
: cpyin (forall ρ; ρ m:Seq Int s:Seq Int dst:Int k:Int -- ρ r:Seq Int)
  locals { m s dst k } {
    k s prim seq-int.len prim >= [ m ]
    [ m dst k prim + s k prim seq-int.at wr s dst k 1 prim + cpyin ] if } ;

: qi (forall ρ; ρ p:Int k:Int -- ρ i:Int) swap 120 prim * prim + 600 prim + ;
: xi (forall ρ; ρ p:Int k:Int -- ρ i:Int) qi 600 prim + ;
: bqi (forall ρ; ρ p:Int k:Int -- ρ i:Int) swap 84 prim * prim + 1800 prim + ;

: shl (forall ρ; ρ m:Seq Int p:Int k:Int -- ρ r:Seq Int)
  locals { m p k } {
    k m 10 p prim + rd prim >=
    [ m 10 p prim + m 10 p prim + rd 1 prim - wr ]
    [ m p k 1 prim - qi m p k qi rd wr
      p k 1 prim - xi m p k xi rd wr
      p k 1 prim + shl ] if } ;
: shu (forall ρ; ρ m:Seq Int p:Int k:Int pos:Int -- ρ r:Seq Int)
  locals { m p k pos } {
    k pos prim <= [ m ]
    [ m p k qi m p k 1 prim - qi rd wr
      p k xi m p k 1 prim - xi rd wr
      p k 1 prim - pos shu ] if } ;
: fpos (forall ρ; ρ m:Seq Int p:Int e:Int k:Int -- ρ r:Int)
  locals { m p e k } {
    k m 10 p prim + rd prim >=
    [ k ]
    [ m p k xi rd e prim > [ k ] [ m p e k 1 prim + fpos ] if ] if } ;
: insert (forall ρ; ρ m:Seq Int p:Int q:Int e:Int -- ρ r:Seq Int)
  locals { m p q e } {
    m p e 0 fpos
    locals { pos } {
      m p m 10 p prim + rd pos shu
      p pos qi q wr
      p pos xi e wr
      10 p prim + 1 addto } } ;
: takeq (forall ρ; ρ m:Seq Int p:Int q:Int -- ρ r:Seq Int)
  locals { m p q } {
    q 0 prim <= m 10 p prim + rd 0 prim = prim or
    [ m ]
    [ m p 0 qi rd
      locals { f } {
        f q prim < [ f ] [ q ] if
        locals { t } {
          m p 0 qi f t prim - wr
          20 p prim + 0 t prim - addto
          521 t addto
          520 t m 60 p prim + rd prim * addto
          526 t addto
          f t prim = [ p 1 shl ] [ ] if
          p q t prim - takeq } } ] if } ;
: fillb (forall ρ; ρ m:Seq Int p:Int -- ρ r:Seq Int)
  locals { m p } {
    m 30 p prim + rd m 40 p prim + rd prim <
    m 20 p prim + rd 0 prim > prim and
    [ m 526 0 wr p m p m 30 p prim + rd bqi rd takeq
      locals { m2 } {
        m2 p m2 30 p prim + rd bqi
        m2 p m2 30 p prim + rd bqi rd m2 526 rd prim - wr
        locals { m3 } {
          m3
          m3 p m3 30 p prim + rd bqi rd 0 prim =
          [ 30 p prim + 1 addto ] [ ] if
          p fillb } } ]
    [ m ] if } ;
: arrive (forall ρ; ρ m:Seq Int p:Int q:Int e:Int -- ρ r:Seq Int)
  locals { m p q e } {
    m p q e insert 20 p prim + q addto p fillb } ;
: addbo (forall ρ; ρ m:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { m p q d } {
    m p m 40 p prim + rd bqi q wr
    p m 40 p prim + rd bqi 420 prim + d wr
    40 p prim + 1 addto } ;
: order (forall ρ; ρ m:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { m p q d } {
    m 30 p prim + rd m 40 p prim + rd prim <
    [ m p q d addbo ]
    [ m 526 0 wr p q takeq
      locals { m2 } {
        m2 526 rd q prim <
        [ m2 p q m2 526 rd prim - d addbo ] [ m2 ] if } ] if } ;
: disc (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 10 p prim + rd 0 prim >
    [ m p 0 xi rd d prim < ] [ false ] if
    [ m 522 m p 0 qi rd addto
      20 p prim + 0 m p 0 qi rd prim - addto
      p 1 shl p d disc ]
    [ m ] if } ;
: canc (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 30 p prim + rd m 40 p prim + rd prim <
    [ m p m 30 p prim + rd bqi 420 prim + rd d 7 prim - prim <= ] [ false ] if
    [ m 523 m p m 30 p prim + rd bqi rd addto
      30 p prim + 1 addto p d canc ]
    [ m ] if } ;
: suparr (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 50 p prim + rd d 1 prim + prim =
    [ m 50 p prim + 0 wr
      p m 80 p prim + rd d m 100 p prim + rd prim + arrive ]
    [ m ] if } ;
: reord (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 50 p prim + rd 0 prim =
    m 20 p prim + rd m 70 p prim + rd prim <= prim and
    [ m 50 p prim + d m 90 p prim + rd prim + 1 prim + wr 524 inc ]
    [ m ] if } ;
: ph1 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d disc p 1 prim + np d ph1 ] if } ;
: ph2 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d suparr p 1 prim + np d ph2 ] if } ;
: ph4 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d canc p 1 prim + np d ph4 ] if } ;
: ph5 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d reord p 1 prim + np d ph5 ] if } ;
: evs (forall ρ; ρ m:Seq Int d:Int -- ρ r:Seq Int)
  locals { m d } {
    m 527 rd m 528 rd prim <
    [ m 110 m 527 rd prim + rd d prim = ] [ false ] if
    [ m 270 m 527 rd prim + rd
      m 350 m 527 rd prim + rd
      locals { p q } {
        m 190 m 527 rd prim + rd 1 prim =
        [ m p q m 430 m 527 rd prim + rd arrive ]
        [ m p q d order ] if
        527 1 addto d evs } ]
    [ m ] if } ;
: dayloop (forall ρ; ρ m:Seq Int d:Int dys:Int np:Int -- ρ r:Seq Int)
  locals { m d dys np } {
    d dys prim >= [ m ]
    [ m 0 np d ph1
      0 np d ph2
      d evs
      0 np d ph4
      0 np d ph5
      d 1 prim + dys np dayloop ] if } ;
: ow1 (forall ρ; ρ m:Seq Int p:Int k:Int acc:Int -- ρ r:Int)
  locals { m p k acc } {
    k m 40 p prim + rd prim >= [ acc ]
    [ m p k 1 prim + acc m p k bqi rd prim + ow1 ] if } ;
: owall (forall ρ; ρ m:Seq Int p:Int np:Int acc:Int -- ρ r:Int)
  locals { m p np acc } {
    p np prim >= [ acc ]
    [ m p 1 prim + np m p m 30 p prim + rd acc ow1 owall ] if } ;

: main
  (forall ρ; ρ dys:Int pr:Seq Int rpl:Seq Int rq:Seq Int ld:Seq Int sh:Seq Int
   ed:Seq Int ek:Seq Int ep:Seq Int eq:Seq Int ex:Seq Int --
   ρ stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int
   supplies:Int owed:Int)
  locals { dys pr rpl rq ld sh ed ek ep eq ex } {
    pr prim seq-int.len
    locals { np } {
      prim seq-int.empty 2650 pad
      pr 60 0 cpyin
      rpl 70 0 cpyin
      rq 80 0 cpyin
      ld 90 0 cpyin
      sh 100 0 cpyin
      ed 110 0 cpyin
      ek 190 0 cpyin
      ep 270 0 cpyin
      eq 350 0 cpyin
      ex 430 0 cpyin
      528 ed prim seq-int.len wr
      0 dys np dayloop
      locals { m } {
        m 20 0 np prim seq-int.empty col
        m 520 rd m 521 rd m 522 rd m 523 rd m 524 rd
        m 0 np 0 owall } } } ;
```

Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## warehouse
Run a warehouse for days days, numbered from 0, and report the totals. There are products 0 to P - 1, where P is the length of price; product p sells for price[p] a unit. Stock is held in lots, each with a quantity, an expiry day and the order in which it arrived. A pending order for a product waits in that product's backorder queue with the quantity still owed and the day it was placed. Taking q units of a product means taking them from its lots with the earliest expiry first, and among equal expiries the lot that arrived first; a lot that reaches 0 is gone. When a lot of a product arrives, it is added, and then while that product has a backorder and units in stock, the oldest backorder is filled as far as the stock allows: the units taken are shipped, and the backorder is gone once nothing is owed. On each day d, in this order: first, every lot whose expiry day is before d is thrown away. Second, for each product in order, a supply ordered earlier that is due on day d arrives as a lot of rq[p] units expiring on day d + shelf[p]. Third, the events of day d happen in the order listed: event e is on day ev_day[e], for product ev_prod[e], with quantity ev_qty[e]. Kind 1 is a delivery: a lot of that quantity arrives, expiring on day ev_expiry[e]. Kind 2 is a customer order: if the product has any backorder, the whole order joins the end of its backorder queue; otherwise as many units as are in stock, up to the quantity, are taken and shipped, and any units not shipped join the end of the queue as a backorder placed on day d. Fourth, every backorder placed on day d - 7 or earlier is cancelled, and the units it still owes (even if it was partly filled) count as cancelled. Fifth, for each product in order, if it has no supply on the way and its units in stock are at most rp[p], a supply is ordered, due on day d + lead[p]; a supply stops being on the way when it arrives in the second step, so another can be ordered that same day. Every unit shipped earns its product's price. Return the units in stock of each product at the end, the total earned, the units shipped, the units thrown away, the units cancelled, the number of supplies ordered, and the units still owed on backorder at the end. price, rp, rq, lead and shelf have the same length P, 1 to 5; each price is 1 to 1,000, each rp 0 to 100, each rq 1 to 200, each lead 1 to 10 and each shelf 1 to 30; days is 1 to 60. The five event sequences have the same length, at most 80; ev_day is 0 to days - 1 and never decreases from one event to the next; ev_kind is 1 or 2; ev_prod is 0 to P - 1; ev_qty is 1 to 200; ev_expiry is ev_day to ev_day + 60 for a delivery and 0 for an order.
Inputs on the stack, bottom to top: days: Int, price: Seq Int, rp: Seq Int, rq: Seq Int, lead: Seq Int, shelf: Seq Int, ev_day: Seq Int, ev_kind: Seq Int, ev_prod: Seq Int, ev_qty: Seq Int, ev_expiry: Seq Int.
Outputs left on the stack, bottom to top: stock: Seq Int, earned: Int, shipped: Int, discarded: Int, cancelled: Int, supplies: Int, owed: Int.
Example: stack [12, { 3 }, { 0 }, { 1 }, { 10 }, { 1 }, { 0 0 3 4 }, { 1 2 2 2 }, { 0 0 0 0 }, { 5 2 4 1 }, { 1 0 0 0 }] becomes [{ 0 }, 6, 2, 3, 5, 1, 0].

Your answer:
```
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
On the example, the run failed:
code: firth.type.branch-mismatch
word: fillb
at: line 74, column 11
message: The two branches of `if` in `fillb` leave different numbers of values: the true branch takes 1 value from the stack below the `if` and leaves 1 value, and the false branch pushes 1 value. The true branch takes 1 value from below the `if` that this code does not have: everything it was given is bound to locals or already used, so that value belongs to the caller.
hint: Push what the branch needs inside the branch, by writing a local's name or computing the value there, or remove the operation that takes it if it should not be there. If the branch means to use a value computed before the `if`, keep a copy of it before the condition (for example with `dup`). Adding a `drop` or pushing values to even out the branches would only move the mistake.

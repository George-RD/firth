Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## checkers
Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus 1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 for a black man and 4 for a black king. White men move up (towards row 0) and black men down; kings move both ways. A step moves a piece to an empty square diagonally next to it, in a direction it may move. A jump moves a piece over a diagonally next square holding a piece of the other side, in a direction it may move, to the empty square just beyond; the piece jumped over is taken off the board at once, and the square the capturing piece started from counts as empty during the capture, so it may land there. A capture is a sequence of jumps by one piece: after each jump, if that piece can jump again from where it landed, it must, and a capture is complete only when it cannot, except that a man that lands on the far row (row 0 for white, row 7 for black) is crowned king and its capture ends there. A man that steps onto its far row is crowned too. The side to move must capture if any of its pieces can; then it plays the complete capture that takes the most pieces, choosing among equals the one whose piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first place the lists differ, whatever its last landing. If it cannot capture it makes the step whose piece starts on the lowest-numbered square, and among those the step to the lowest-numbered square. White moves first if turn is 0 and black if turn is 1, then the sides alternate. Before each move, if the side to move has no capture or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on either side), and the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40.
Inputs on the stack, bottom to top: board: Seq Int, turn: Int, plies: Int.
Outputs left on the stack, bottom to top: board: Seq Int, played: Int, white_took: Int, black_took: Int, crowned: Int, result: Int.
Example: stack [{ 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 3 3 0 0 0 0 0 0 3 0 0 0 1 0 0 0 }, 0, 2] becomes [{ 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }, 2, 3, 0, 0, 0].

Your answer:
```
: nbr
  (forall ρ; ρ sq:Int^many d:Int^many -- ρ r:Int^many)
  locals { sq d } {
    { -1 -1 4 5
      -1 -1 5 6
      -1 -1 6 7
      -1 -1 7 -1
      -1 0 -1 8
      0 1 8 9
      1 2 9 10
      2 3 10 11
      4 5 12 13
      5 6 13 14
      6 7 14 15
      7 -1 15 -1
      -1 8 -1 16
      8 9 16 17
      9 10 17 18
      10 11 18 19
      12 13 20 21
      13 14 21 22
      14 15 22 23
      15 -1 23 -1
      -1 16 -1 24
      16 17 24 25
      17 18 25 26
      18 19 26 27
      20 21 28 29
      21 22 29 30
      22 23 30 31
      23 -1 31 -1
      -1 24 -1 -1
      24 25 -1 -1
      25 26 -1 -1
      26 27 -1 -1 }
    sq 4 prim * d prim + prim seq-int.at };

: side
  (forall ρ; ρ p:Int^many -- ρ s:Int^many)
  3 prim < [ 0 ] [ 1 ] if ;

: can-dir
  (forall ρ; ρ pt:Int^many d:Int^many -- ρ ok:Bool^many)
  locals { pt d } {
    pt 1 prim =
    [ d 2 prim < ]
    [ pt 3 prim =
      [ d 1 prim > ]
      [ true ]
      if ]
    if };

: opp?
  (forall ρ; ρ mp:Int^many pt:Int^many -- ρ ok:Bool^many)
  locals { mp pt } {
    mp 0 prim = prim not
    mp side pt side prim = prim not
    prim and };

: land-ok
  (forall ρ; ρ b:Seq Int^many l:Int^many -- ρ r:Int^many)
  locals { b l } {
    l 0 prim >=
    [ b l prim seq-int.at 0 prim = [ l ] [ -1 ] if ]
    [ -1 ]
    if };

: jump-land
  (forall ρ; ρ b:Seq Int^many pos:Int^many pt:Int^many d:Int^many -- ρ l:Int^many)
  locals { b pos pt d } {
    pt d can-dir
    [ pos d nbr
      locals { mid } {
        mid 0 prim >=
        [ b mid prim seq-int.at pt opp?
          [ b mid d nbr land-ok ]
          [ -1 ]
          if ]
        [ -1 ]
        if } ]
    [ -1 ]
    if };

: far?
  (forall ρ; ρ pt:Int^many l:Int^many -- ρ ok:Bool^many)
  locals { pt l } {
    pt 1 prim =
    [ l 4 prim < ]
    [ pt 3 prim =
      [ l 27 prim > ]
      [ false ]
      if ]
    if };

: place
  (forall ρ; ρ rb:Seq Int^many rp:Int^many pt:Int^many -- ρ nb2:Seq Int^many cr:Int^many)
  locals { rb rp pt } {
    pt rp far?
    [ rb rp pt 1 prim + prim seq-int.set 1 ]
    [ rb rp pt prim seq-int.set 0 ]
    if };

: cand
  (forall ρ; ρ b:Seq Int^many pos:Int^many pt:Int^many l:Int^many d:Int^many -- ρ cb:Seq Int^many cc:Int^many cp:Int^many)
  locals { b pos pt l d } {
    b pos d nbr 0 prim seq-int.set
    locals { b2 } {
      pt l far?
      [ b2 1 l ]
      [ b2 l pt dfs
        locals { rb rc rp } { rb rc 1 prim + rp } ]
      if } };

: dfs-dirs
  (forall ρ; ρ b:Seq Int^many pos:Int^many pt:Int^many d:Int^many bb:Seq Int^many bc:Int^many bp:Int^many -- ρ rb:Seq Int^many rc:Int^many rp:Int^many)
  locals { b pos pt d bb bc bp } {
    d 4 prim <
    [ b pos pt d jump-land
      locals { l } {
        l 0 prim >=
        [ b pos pt l d cand
          locals { cb cc cp } {
            cc bc prim >
            [ b pos pt d 1 prim + cb cc cp dfs-dirs ]
            [ b pos pt d 1 prim + bb bc bp dfs-dirs ]
            if } ]
        [ b pos pt d 1 prim + bb bc bp dfs-dirs ]
        if } ]
    [ bb bc bp ]
    if };

: dfs
  (forall ρ; ρ b:Seq Int^many pos:Int^many pt:Int^many -- ρ rb:Seq Int^many rc:Int^many rp:Int^many)
  locals { b pos pt } { b pos pt 0 b 0 pos dfs-dirs };

: cap-scan
  (forall ρ; ρ b:Seq Int^many sd:Int^many s:Int^many bb:Seq Int^many bc:Int^many bcr:Int^many -- ρ rb:Seq Int^many rc:Int^many rcr:Int^many)
  locals { b sd s bb bc bcr } {
    s 32 prim <
    [ b s prim seq-int.at
      locals { pt } {
        pt 0 prim = prim not
        pt side sd prim =
        prim and
        [ b s 0 prim seq-int.set s pt dfs
          locals { rb rc rp } {
            rc bc prim >
            [ rb rp pt place
              locals { nb2 cr2 } { b sd s 1 prim + nb2 rc cr2 cap-scan } ]
            [ b sd s 1 prim + bb bc bcr cap-scan ]
            if } ]
        [ b sd s 1 prim + bb bc bcr cap-scan ]
        if } ]
    [ bb bc bcr ]
    if };

: step-ok
  (forall ρ; ρ b:Seq Int^many sd:Int^many s:Int^many d:Int^many -- ρ ok:Bool^many)
  locals { b sd s d } {
    b s prim seq-int.at
    locals { pt } {
      pt 0 prim =
      [ false ]
      [ pt side sd prim =
        [ pt d can-dir
          [ s d nbr
            locals { n } {
              n 0 prim >=
              [ b n prim seq-int.at 0 prim = ]
              [ false ]
              if } ]
          [ false ]
          if ]
        [ false ]
        if ]
      if } };

: step-scan
  (forall ρ; ρ b:Seq Int^many sd:Int^many idx:Int^many -- ρ r:Int^many)
  locals { b sd idx } {
    idx 128 prim <
    [ b sd idx 4 prim div idx 4 prim mod step-ok
      [ idx ]
      [ b sd idx 1 prim + step-scan ]
      if ]
    [ -1 ]
    if };

: do-step
  (forall ρ; ρ b:Seq Int^many idx:Int^many -- ρ mb:Seq Int^many x:Int^many)
  locals { b idx } {
    idx 4 prim div
    locals { s } {
      b s prim seq-int.at
      locals { pt } {
        b s 0 prim seq-int.set s idx 4 prim mod nbr pt place } } };

: advance
  (forall ρ; ρ b:Seq Int^many turn:Int^many played:Int^many wt:Int^many bt:Int^many cr:Int^many plies:Int^many mb:Seq Int^many k:Int^many x:Int^many -- ρ rb:Seq Int^many rp:Int^many rw:Int^many rbk:Int^many rc:Int^many res:Int^many)
  locals { b turn played wt bt cr plies mb k x } {
    mb 1 turn prim - played 1 prim +
    wt turn 0 prim = [ k ] [ 0 ] if prim +
    bt turn 1 prim = [ k ] [ 0 ] if prim +
    cr x prim +
    plies play };

: play
  (forall ρ; ρ b:Seq Int^many turn:Int^many played:Int^many wt:Int^many bt:Int^many cr:Int^many plies:Int^many -- ρ rb:Seq Int^many rp:Int^many rw:Int^many rbk:Int^many rc:Int^many res:Int^many)
  locals { b turn played wt bt cr plies } {
    b turn 0 b 0 0 cap-scan
    locals { cb cc ccr } {
      cc 0 prim >
      [ played plies prim >=
        [ b played wt bt cr 0 ]
        [ b turn played wt bt cr plies cb cc ccr advance ]
        if ]
      [ b turn 0 step-scan
        locals { idx } {
          idx 0 prim <
          [ b played wt bt cr turn 0 prim = [ 2 ] [ 1 ] if ]
          [ played plies prim >=
            [ b played wt bt cr 0 ]
            [ b turn played wt bt cr plies b idx do-step 0 swap advance ]
            if ]
          if } ]
      if } };

: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ rb:Seq Int^many played:Int^many white_took:Int^many black_took:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } { board turn 0 0 0 0 plies play };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 229, column 106
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## warehouse
Run a warehouse for days days, numbered from 0, and report the totals. There are products 0 to P - 1, where P is the length of price; product p sells for price[p] a unit. Stock is held in lots, each with a quantity, an expiry day and the order in which it arrived. A pending order for a product waits in that product's backorder queue with the quantity still owed and the day it was placed. Taking q units of a product means taking them from its lots with the earliest expiry first, and among equal expiries the lot that arrived first; a lot that reaches 0 is gone. When a lot of a product arrives, it is added, and then while that product has a backorder and units in stock, the oldest backorder is filled as far as the stock allows: the units taken are shipped, and the backorder is gone once nothing is owed. On each day d, in this order: first, every lot whose expiry day is before d is thrown away. Second, for each product in order, a supply ordered earlier that is due on day d arrives as a lot of rq[p] units expiring on day d + shelf[p]. Third, the events of day d happen in the order listed: event e is on day ev_day[e], for product ev_prod[e], with quantity ev_qty[e]. Kind 1 is a delivery: a lot of that quantity arrives, expiring on day ev_expiry[e]. Kind 2 is a customer order: if the product has any backorder, the whole order joins the end of its backorder queue; otherwise as many units as are in stock, up to the quantity, are taken and shipped, and any units not shipped join the end of the queue as a backorder placed on day d. Fourth, every backorder placed on day d - 7 or earlier is cancelled, and the units it still owes (even if it was partly filled) count as cancelled. Fifth, for each product in order, if it has no supply on the way and its units in stock are at most rp[p], a supply is ordered, due on day d + lead[p]; a supply stops being on the way when it arrives in the second step, so another can be ordered that same day. Every unit shipped earns its product's price. Return the units in stock of each product at the end, the total earned, the units shipped, the units thrown away, the units cancelled, the number of supplies ordered, and the units still owed on backorder at the end. price, rp, rq, lead and shelf have the same length P, 1 to 5; each price is 1 to 1,000, each rp 0 to 100, each rq 1 to 200, each lead 1 to 10 and each shelf 1 to 30; days is 1 to 60. The five event sequences have the same length, at most 80; ev_day is 0 to days - 1 and never decreases from one event to the next; ev_kind is 1 or 2; ev_prod is 0 to P - 1; ev_qty is 1 to 200; ev_expiry is ev_day to ev_day + 60 for a delivery and 0 for an order.
Inputs on the stack, bottom to top: days: Int, price: Seq Int, rp: Seq Int, rq: Seq Int, lead: Seq Int, shelf: Seq Int, ev_day: Seq Int, ev_kind: Seq Int, ev_prod: Seq Int, ev_qty: Seq Int, ev_expiry: Seq Int.
Outputs left on the stack, bottom to top: stock: Seq Int, earned: Int, shipped: Int, discarded: Int, cancelled: Int, supplies: Int, owed: Int.
Example: stack [12, { 3 }, { 0 }, { 1 }, { 10 }, { 1 }, { 0 0 3 4 }, { 1 2 2 2 }, { 0 0 0 0 }, { 5 2 4 1 }, { 1 0 0 0 }] becomes [{ 0 }, 6, 2, 3, 5, 1, 0].

Your answer:
```
: zeros-from
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ t:Seq Int^many)
  locals { s n } {
    s prim seq-int.len n prim <
    [ s 0 prim seq-int.push n zeros-from ]
    [ s ]
    if };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  locals { n } { prim seq-int.empty n zeros-from };

: addto
  (forall ρ; ρ st:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { st i v } { st i st i prim seq-int.at v prim + prim seq-int.set };

: getf
  (forall ρ; ρ st:Seq Int^many p:Int^many k:Int^many -- ρ v:Int^many)
  locals { st p k } { st p 8 prim * k prim + prim seq-int.at };

: setf
  (forall ρ; ρ st:Seq Int^many p:Int^many k:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { st p k v } { st p 8 prim * k prim + v prim seq-int.set };

: addf
  (forall ρ; ρ st:Seq Int^many p:Int^many k:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { st p k v } { st p k st p k getf v prim + setf };

: lq-i
  (forall ρ; ρ p:Int^many k:Int^many -- ρ i:Int^many)
  locals { p k } { 64 p 144 prim * prim + k prim + };

: le-i
  (forall ρ; ρ p:Int^many k:Int^many -- ρ i:Int^many)
  locals { p k } { 784 p 144 prim * prim + k prim + };

: bq-i
  (forall ρ; ρ p:Int^many k:Int^many -- ρ i:Int^many)
  locals { p k } { 1504 p 80 prim * prim + k prim + };

: bd-i
  (forall ρ; ρ p:Int^many k:Int^many -- ρ i:Int^many)
  locals { p k } { 1904 p 80 prim * prim + k prim + };

: take-loop
  (forall ρ; ρ st:Seq Int^many p:Int^many need:Int^many taken:Int^many -- ρ r:Seq Int^many t:Int^many)
  locals { st p need taken } {
    need 0 prim >
    st p 0 getf st p 1 getf prim <
    prim and
    [ st p 0 getf
      locals { h } {
        st p h lq-i prim seq-int.at
        locals { qty } {
          need qty prim < [ need ] [ qty ] if
          locals { m } {
            st p h lq-i qty m prim - prim seq-int.set
            p 2 0 m prim - addf
            40 m st 2304 p prim + prim seq-int.at prim * addto
            41 m addto
            qty m prim =
            [ p 0 1 addf ]
            [ ]
            if
            p need m prim - taken m prim + take-loop } } } ]
    [ st taken ]
    if };

: fill
  (forall ρ; ρ st:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st p } {
    st p 3 getf st p 4 getf prim <
    st p 2 getf 0 prim >
    prim and
    [ st p 3 getf
      locals { bh } {
        st p bh bq-i prim seq-int.at
        locals { owed } {
          st p owed 0 take-loop
          locals { s1 taken } {
            s1 p bh bq-i owed taken prim - prim seq-int.set
            owed taken prim =
            [ p 3 1 addf ]
            [ ]
            if
            p fill } } } ]
    [ st ]
    if };

: shift
  (forall ρ; ρ st:Seq Int^many p:Int^many idx:Int^many e:Int^many -- ρ r:Seq Int^many i:Int^many)
  locals { st p idx e } {
    idx st p 0 getf prim >
    [ st p idx 1 prim - le-i prim seq-int.at e prim >
      [ st p idx lq-i st p idx 1 prim - lq-i prim seq-int.at prim seq-int.set
        p idx le-i st p idx 1 prim - le-i prim seq-int.at prim seq-int.set
        p idx 1 prim - e shift ]
      [ st idx ]
      if ]
    [ st idx ]
    if };

: add-lot
  (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { st p q e } {
    st p st p 1 getf e shift
    locals { s1 idx } {
      s1 p idx lq-i q prim seq-int.set
      p idx le-i e prim seq-int.set
      p 1 1 addf
      p 2 q addf
      p fill } };

: expire
  (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    st p 0 getf st p 1 getf prim <
    [ st p 0 getf
      locals { h } {
        st p h le-i prim seq-int.at d prim <
        [ st p h lq-i prim seq-int.at
          locals { q } {
            st 42 q addto
            p 2 0 q prim - addf
            p 0 1 addf
            p d expire } ]
        [ st ]
        if } ]
    [ st ]
    if };

: enqueue
  (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p q d } {
    st p 4 getf
    locals { bt } {
      st p bt bq-i q prim seq-int.set
      p bt bd-i d prim seq-int.set
      p 4 1 addf } };

: cust
  (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p q d } {
    st p 3 getf st p 4 getf prim <
    [ st p q d enqueue ]
    [ st p q 0 take-loop
      locals { s1 taken } {
        taken q prim <
        [ s1 p q taken prim - d enqueue ]
        [ s1 ]
        if } ]
    if };

: cancel
  (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    st p 3 getf st p 4 getf prim <
    [ st p 3 getf
      locals { bh } {
        st p bh bd-i prim seq-int.at d 7 prim - prim <=
        [ st 43 st p bh bq-i prim seq-int.at addto
          p 3 1 addf
          p d cancel ]
        [ st ]
        if } ]
    [ st ]
    if };

: expire-loop
  (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    p st 2329 prim seq-int.at prim <
    [ st p d expire p 1 prim + d expire-loop ]
    [ st ]
    if };

: cancel-loop
  (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    p st 2329 prim seq-int.at prim <
    [ st p d cancel p 1 prim + d cancel-loop ]
    [ st ]
    if };

: arrive-loop
  (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    p st 2329 prim seq-int.at prim <
    [ st p 5 getf 1 prim = st p 6 getf d prim = prim and
      [ st p
        st 2314 p prim + prim seq-int.at
        d st 2324 p prim + prim seq-int.at prim +
        add-lot
        p 5 0 setf
        p 1 prim + d arrive-loop ]
      [ st p 1 prim + d arrive-loop ]
      if ]
    [ st ]
    if };

: supply-loop
  (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    p st 2329 prim seq-int.at prim <
    [ st p 5 getf 0 prim = st p 2 getf st 2309 p prim + prim seq-int.at prim <= prim and
      [ st 44 1 addto
        p 5 1 setf
        p 6 d st 2319 p prim + prim seq-int.at prim + setf
        p 1 prim + d supply-loop ]
      [ st p 1 prim + d supply-loop ]
      if ]
    [ st ]
    if };

: ev-apply
  (forall ρ; ρ st:Seq Int^many ei:Int^many -- ρ r:Seq Int^many)
  locals { st ei } {
    st 2420 ei prim + prim seq-int.at 1 prim =
    [ st
      st 2500 ei prim + prim seq-int.at
      st 2580 ei prim + prim seq-int.at
      st 2660 ei prim + prim seq-int.at
      add-lot ]
    [ st
      st 2500 ei prim + prim seq-int.at
      st 2580 ei prim + prim seq-int.at
      st 2340 ei prim + prim seq-int.at
      cust ]
    if };

: ev-loop
  (forall ρ; ρ st:Seq Int^many ei:Int^many d:Int^many -- ρ r:Seq Int^many e:Int^many)
  locals { st ei d } {
    ei st 2330 prim seq-int.at prim <
    [ st 2340 ei prim + prim seq-int.at d prim =
      [ st ei ev-apply ei 1 prim + d ev-loop ]
      [ st ei ]
      if ]
    [ st ei ]
    if };

: day-loop
  (forall ρ; ρ st:Seq Int^many d:Int^many days:Int^many ei:Int^many -- ρ r:Seq Int^many)
  locals { st d days ei } {
    d days prim <
    [ st 0 d expire-loop 0 d arrive-loop ei d ev-loop
      locals { s3 e3 } {
        s3 0 d cancel-loop 0 d supply-loop
        d 1 prim + days e3 day-loop } ]
    [ st ]
    if };

: cpy
  (forall ρ; ρ st:Seq Int^many src:Seq Int^many base:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { st src base i } {
    i src prim seq-int.len prim <
    [ st base i prim + src i prim seq-int.at prim seq-int.set src base i 1 prim + cpy ]
    [ st ]
    if };

: stk-loop
  (forall ρ; ρ st:Seq Int^many p:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { st p acc } {
    p st 2329 prim seq-int.at prim <
    [ st p 1 prim + acc st p 2 getf prim seq-int.push stk-loop ]
    [ acc ]
    if };

: owed-k
  (forall ρ; ρ st:Seq Int^many p:Int^many k:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p k acc } {
    k st p 4 getf prim <
    [ st p k 1 prim + acc st p k bq-i prim seq-int.at prim + owed-k ]
    [ acc ]
    if };

: owed-all
  (forall ρ; ρ st:Seq Int^many p:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p acc } {
    p st 2329 prim seq-int.at prim <
    [ st p 1 prim + st p st p 3 getf acc owed-k owed-all ]
    [ acc ]
    if };

: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many ev_day:Seq Int^many ev_kind:Seq Int^many ev_prod:Seq Int^many ev_qty:Seq Int^many ev_expiry:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf ev_day ev_kind ev_prod ev_qty ev_expiry } {
    2740 zeros
    2329 price prim seq-int.len prim seq-int.set
    2330 ev_day prim seq-int.len prim seq-int.set
    price 2304 0 cpy
    rp 2309 0 cpy
    rq 2314 0 cpy
    lead 2319 0 cpy
    shelf 2324 0 cpy
    ev_day 2340 0 cpy
    ev_kind 2420 0 cpy
    ev_prod 2500 0 cpy
    ev_qty 2580 0 cpy
    ev_expiry 2660 0 cpy
    0 days 0 day-loop
    locals { st } {
      st 0 prim seq-int.empty stk-loop
      st 40 prim seq-int.at
      st 41 prim seq-int.at
      st 42 prim seq-int.at
      st 43 prim seq-int.at
      st 44 prim seq-int.at
      st 0 0 owed-all } };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 286, column 120
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## cache-sim
Simulate a two-level cache and report its counters. Memory is made of blocks numbered 0 to 255. The first level has s1 sets of w1 places and the second level s2 sets of w2 places; block a belongs to set a mod s1 in the first level and a mod s2 in the second. Each place holds a block and a dirty mark. Each set keeps its blocks in order of use, least recently used first; using a block moves it to the most recent end, and putting a block into a set adds it at the most recent end after removing the least recently used block if the set is full (that block is evicted). Access i is to block addrs[i], a write if writes[i] is true and a read otherwise. If the block is in the first level, that is a first-level hit: it is used, and marked dirty if the access is a write. Otherwise it is a first-level miss, and: if the block is in the second level, that is a second-level hit and it is used there; otherwise it is a second-level miss, the block is read from memory and put into the second level unmarked, and if that evicts a dirty block, that block is written to memory. Then the block is put into the first level, marked dirty if the access is a write. If that evicts a dirty block b from the first level, b is written to the second level: if b is there it is used and marked dirty; otherwise it is put into the second level marked dirty, and if that evicts a dirty block, that block is written to memory. A clean evicted block is simply dropped. Return the number of first-level hits, first-level misses, second-level hits, second-level misses, memory reads and memory writes, the number of places in either level holding a dirty block at the end (a block dirty in both levels counts twice), and the blocks left in the first level, set 0 first, each set least recently used first. s1, w1 are 1 to 4 and s2, w2 are 1 to 8; addrs and writes have the same length, at most 200; every value of addrs is 0 to 255.
Inputs on the stack, bottom to top: s1: Int, w1: Int, s2: Int, w2: Int, addrs: Seq Int, writes: Seq Bool.
Outputs left on the stack, bottom to top: l1_hits: Int, l1_misses: Int, l2_hits: Int, l2_misses: Int, mem_reads: Int, mem_writes: Int, dirty: Int, l1_blocks: Seq Int.
Example: stack [1, 2, 1, 2, { 1 2 1 3 2 4 5 }, { false true false false false true false }] becomes [1, 6, 1, 5, 5, 1, 1, { 4 5 }].

Your answer:
```
: zeros-from
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ t:Seq Int^many)
  locals { s n } {
    s prim seq-int.len n prim <
    [ s 0 prim seq-int.push n zeros-from ]
    [ s ]
    if };

: zeros
  (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  locals { n } { prim seq-int.empty n zeros-from };

: inc
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ t:Seq Int^many)
  locals { s i } { s i s i prim seq-int.at 1 prim + prim seq-int.set };

: iB
  (forall ρ; ρ lv:Int^many set:Int^many w:Int^many k:Int^many -- ρ i:Int^many)
  locals { lv set w k } { lv set w prim * prim + k prim + };

: iD
  (forall ρ; ρ lv:Int^many set:Int^many w:Int^many k:Int^many -- ρ i:Int^many)
  locals { lv set w k } { lv 100 prim + set w prim * prim + k prim + };

: iN
  (forall ρ; ρ lv:Int^many set:Int^many -- ρ i:Int^many)
  locals { lv set } { lv 200 prim + set prim + };

: find-loop
  (forall ρ; ρ st:Seq Int^many lv:Int^many set:Int^many w:Int^many a:Int^many k:Int^many -- ρ r:Int^many)
  locals { st lv set w a k } {
    k st lv set iN prim seq-int.at prim <
    [ st lv set w k iB prim seq-int.at a prim =
      [ k ]
      [ st lv set w a k 1 prim + find-loop ]
      if ]
    [ -1 ]
    if };

: shl-loop
  (forall ρ; ρ st:Seq Int^many lv:Int^many set:Int^many w:Int^many k:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { st lv set w k n } {
    k n 1 prim - prim <
    [ st lv set w k iB st lv set w k 1 prim + iB prim seq-int.at prim seq-int.set
      lv set w k iD st lv set w k 1 prim + iD prim seq-int.at prim seq-int.set
      lv set w k 1 prim + n shl-loop ]
    [ st ]
    if };

: touch
  (forall ρ; ρ st:Seq Int^many lv:Int^many set:Int^many w:Int^many pos:Int^many -- ρ r:Seq Int^many)
  locals { st lv set w pos } {
    st lv set w pos iB prim seq-int.at
    st lv set w pos iD prim seq-int.at
    locals { b d } {
      st lv set w pos st lv set iN prim seq-int.at shl-loop
      locals { s1 } {
        s1 lv set w st lv set iN prim seq-int.at 1 prim - iB b prim seq-int.set
        lv set w st lv set iN prim seq-int.at 1 prim - iD d prim seq-int.set } } };

: mark
  (forall ρ; ρ st:Seq Int^many lv:Int^many set:Int^many w:Int^many -- ρ r:Seq Int^many)
  locals { st lv set w } {
    st lv set w st lv set iN prim seq-int.at 1 prim - iD 1 prim seq-int.set };

: put
  (forall ρ; ρ st:Seq Int^many lv:Int^many set:Int^many w:Int^many a:Int^many dirty:Int^many -- ρ r:Seq Int^many eb:Int^many ed:Int^many)
  locals { st lv set w a dirty } {
    st lv set iN prim seq-int.at
    locals { n } {
      n w prim =
      [ st lv set w 0 iB prim seq-int.at
        st lv set w 0 iD prim seq-int.at
        locals { eb ed } {
          st lv set w 0 n shl-loop
          locals { s1 } {
            s1 lv set w n 1 prim - iB a prim seq-int.set
            lv set w n 1 prim - iD dirty prim seq-int.set
            eb ed } } ]
      [ st lv set w n iB a prim seq-int.set
        lv set w n iD dirty prim seq-int.set
        lv set iN n 1 prim + prim seq-int.set
        -1 0 ]
      if } };

: wb2
  (forall ρ; ρ st:Seq Int^many s2:Int^many w2:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { st s2 w2 b } {
    b s2 prim mod
    locals { q } {
      st 20 q w2 b 0 find-loop
      locals { pos } {
        pos 0 prim >=
        [ st 20 q w2 pos touch 20 q w2 mark ]
        [ st 20 q w2 b 1 put
          locals { s9 eb ed } {
            ed 1 prim =
            [ s9 245 inc ]
            [ s9 ]
            if } ]
        if } } };

: l1-miss
  (forall ρ; ρ st:Seq Int^many s1:Int^many w1:Int^many s2:Int^many w2:Int^many a:Int^many wi:Int^many -- ρ r:Seq Int^many)
  locals { st s1 w1 s2 w2 a wi } {
    a s2 prim mod
    locals { q2 } {
      st 20 q2 w2 a 0 find-loop
      locals { pos2 } {
        pos2 0 prim >=
        [ st 242 inc 20 q2 w2 pos2 touch ]
        [ st 243 inc 244 inc 20 q2 w2 a 0 put
          locals { s5 eb ed } {
            ed 1 prim =
            [ s5 245 inc ]
            [ s5 ]
            if } ]
        if
        a s1 prim mod
        locals { q1 } {
          0 q1 w1 a wi put
          locals { s6 eb ed } {
            ed 1 prim =
            [ s6 s2 w2 eb wb2 ]
            [ s6 ]
            if } } } } };

: access
  (forall ρ; ρ st:Seq Int^many s1:Int^many w1:Int^many s2:Int^many w2:Int^many a:Int^many wi:Int^many -- ρ r:Seq Int^many)
  locals { st s1 w1 s2 w2 a wi } {
    a s1 prim mod
    locals { q1 } {
      st 0 q1 w1 a 0 find-loop
      locals { pos } {
        pos 0 prim >=
        [ st 240 inc 0 q1 w1 pos touch
          wi 1 prim =
          [ 0 q1 w1 mark ]
          [ ]
          if ]
        [ st 241 inc s1 w1 s2 w2 a wi l1-miss ]
        if } } };

: sim-loop
  (forall ρ; ρ st:Seq Int^many s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many i:Int^many -- ρ r:Seq Int^many)
  locals { st s1 w1 s2 w2 addrs writes i } {
    i addrs prim seq-int.len prim <
    [ st s1 w1 s2 w2 addrs i prim seq-int.at
      writes i prim seq-bool.at [ 1 ] [ 0 ] if
      access
      s1 w1 s2 w2 addrs writes i 1 prim + sim-loop ]
    [ st ]
    if };

: sumr
  (forall ρ; ρ st:Seq Int^many i:Int^many hi:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st i hi acc } {
    i hi prim <
    [ st i 1 prim + hi acc st i prim seq-int.at prim + sumr ]
    [ acc ]
    if };

: blk-loop
  (forall ρ; ρ st:Seq Int^many s1:Int^many w1:Int^many q:Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { st s1 w1 q k acc } {
    q s1 prim <
    [ k st 0 q iN prim seq-int.at prim <
      [ st s1 w1 q k 1 prim + acc st 0 q w1 k iB prim seq-int.at prim seq-int.push blk-loop ]
      [ st s1 w1 q 1 prim + 0 acc blk-loop ]
      if ]
    [ acc ]
    if };

: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1_hits:Int^many l1_misses:Int^many l2_hits:Int^many l2_misses:Int^many mem_reads:Int^many mem_writes:Int^many dirty:Int^many l1_blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    250 zeros s1 w1 s2 w2 addrs writes 0 sim-loop
    locals { st } {
      st 240 prim seq-int.at
      st 241 prim seq-int.at
      st 242 prim seq-int.at
      st 243 prim seq-int.at
      st 244 prim seq-int.at
      st 245 prim seq-int.at
      st 100 116 0 sumr st 120 184 0 sumr prim +
      st s1 w1 0 0 prim seq-int.empty blk-loop } };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 175, column 111
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

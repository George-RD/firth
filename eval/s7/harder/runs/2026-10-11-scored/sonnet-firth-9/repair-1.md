Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## checkers
Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus 1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 for a black man and 4 for a black king. White men move up (towards row 0) and black men down; kings move both ways. A step moves a piece to an empty square diagonally next to it, in a direction it may move. A jump moves a piece over a diagonally next square holding a piece of the other side, in a direction it may move, to the empty square just beyond; the piece jumped over is taken off the board at once, and the square the capturing piece started from counts as empty during the capture, so it may land there. A capture is a sequence of jumps by one piece: after each jump, if that piece can jump again from where it landed, it must, and a capture is complete only when it cannot, except that a man that lands on the far row (row 0 for white, row 7 for black) is crowned king and its capture ends there. A man that steps onto its far row is crowned too. The side to move must capture if any of its pieces can; then it plays the complete capture that takes the most pieces, choosing among equals the one whose piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first place the lists differ, whatever its last landing. If it cannot capture it makes the step whose piece starts on the lowest-numbered square, and among those the step to the lowest-numbered square. White moves first if turn is 0 and black if turn is 1, then the sides alternate. Before each move, if the side to move has no capture or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on either side), and the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40.
Inputs on the stack, bottom to top: board: Seq Int, turn: Int, plies: Int.
Outputs left on the stack, bottom to top: board: Seq Int, played: Int, white_took: Int, black_took: Int, crowned: Int, result: Int.
Example: stack [{ 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 3 3 0 0 0 0 0 0 3 0 0 0 1 0 0 0 }, 0, 2] becomes [{ 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }, 2, 3, 0, 0, 0].

Your answer:
```
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: addto (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { m i v } { m i m i gt v prim + st };
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i 1 addto };
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: sq (forall ρ; ρ r:Int^many c:Int^many -- ρ s:Int^many)
  locals { r c } {
    r 0 prim >= r 8 prim < prim and c 0 prim >= prim and c 8 prim < prim and
    [ r 4 prim * c 2 prim div prim + ] [ -1 ] if };
: col (forall ρ; ρ i:Int^many -- ρ c:Int^many)
  locals { i } { i 4 prim mod 2 prim * 1 prim + i 4 prim div 2 prim mod prim - };
: nb (forall ρ; ρ pos:Int^many dr:Int^many dc:Int^many -- ρ s:Int^many)
  locals { pos dr dc } { pos 4 prim div dr prim + pos col dc prim + sq };
: mid (forall ρ; ρ a:Int^many b:Int^many -- ρ s:Int^many)
  locals { a b } { a 4 prim div b 4 prim div prim + 2 prim div a col b col prim + 2 prim div sq };
: okdir (forall ρ; ρ piece:Int^many dr:Int^many -- ρ r:Bool^many)
  locals { piece dr } {
    piece 2 prim = piece 4 prim = prim or
    piece 1 prim = dr -1 prim = prim and prim or
    piece 3 prim = dr 1 prim = prim and prim or };
: en (forall ρ; ρ piece:Int^many x:Int^many -- ρ r:Bool^many)
  locals { piece x } {
    piece 3 prim < x 3 prim >= prim and
    piece 3 prim >= x 1 prim >= prim and x 2 prim <= prim and prim or };
: mine (forall ρ; ρ x:Int^many side:Int^many -- ρ r:Bool^many)
  locals { x side } { x 1 prim - 2 prim div side prim = };
: cpl (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m i d } {
    i d prim >= [ m ] [ m 40 i prim + m 70 i prim + gt st i 1 prim + d cpl ] if };
: leaf (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    d m 33 gt prim > [ m 33 d st 35 m 36 gt st 0 d cpl ] [ m ] if };
: jump2 (forall ρ; ρ m:Seq Int^many over:Int^many ep:Int^many piece:Int^many land:Int^many depth:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m over ep piece land depth } {
    m over 0 st 70 depth prim + land st
    piece 1 prim = land 4 prim < prim and piece 3 prim = land 28 prim >= prim and prim or
    [ depth 1 prim + leaf ] [ land depth 1 prim + piece dfs ] if
    over ep st 1 };
: tr4 (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many over:Int^many land:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m pos depth piece over land } {
    over 0 prim >= land 0 prim >= prim and
    [ m land gt 0 prim = piece m over gt en prim and
      [ m over m over gt piece land depth jump2 ] [ m 0 ] if ]
    [ m 0 ] if };
: tr2 (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many dr:Int^many dc:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m pos depth piece dr dc } {
    piece dr okdir
    [ m pos depth piece pos dr dc nb pos dr 2 prim * dc 2 prim * nb tr4 ]
    [ m 0 ] if };
: tr (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many idx:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m pos depth piece idx } {
    m pos depth piece idx 2 prim < [ -1 ] [ 1 ] if idx 2 prim mod 0 prim = [ -1 ] [ 1 ] if tr2 };
: jl2 (forall ρ; ρ pos:Int^many depth:Int^many piece:Int^many idx:Int^many found:Int^many m:Seq Int^many n:Int^many -- ρ r:Seq Int^many f:Int^many)
  locals { pos depth piece idx found m n } {
    m pos depth piece idx 1 prim + found n prim + jl };
: jl (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many idx:Int^many found:Int^many -- ρ r:Seq Int^many f:Int^many)
  locals { m pos depth piece idx found } {
    idx 4 prim >= [ m found ]
    [ pos depth piece idx found m pos depth piece idx tr jl2 ] if };
: dfs2 (forall ρ; ρ depth:Int^many m:Seq Int^many found:Int^many -- ρ r:Seq Int^many)
  locals { depth m found } {
    found 0 prim = depth 0 prim > prim and [ m depth leaf ] [ m ] if };
: dfs (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many -- ρ r:Seq Int^many)
  locals { m pos depth piece } { depth m pos depth piece 0 0 jl dfs2 };
: fc4 (forall ρ; ρ m:Seq Int^many s:Int^many pc:Int^many -- ρ r:Seq Int^many)
  locals { m s pc } { m s 0 st s 0 pc dfs s pc st };
: fc3 (forall ρ; ρ m:Seq Int^many s:Int^many -- ρ r:Seq Int^many)
  locals { m s } { m 36 s st s m s gt fc4 };
: fc (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m s side } {
    s 32 prim >= [ m ]
    [ m s gt side mine [ m s fc3 ] [ m ] if s 1 prim + side fc ] if };
: findcap (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m side } { m 0 side fc };
: ap1 (forall ρ; ρ m:Seq Int^many j:Int^many from:Int^many cnt:Int^many -- ρ r:Seq Int^many)
  locals { m j from cnt } {
    j cnt prim >= [ m ]
    [ m from m 40 j prim + gt mid 0 st j 1 prim + m 40 j prim + gt cnt ap1 ] if };
: ac2 (forall ρ; ρ m:Seq Int^many L:Int^many pc:Int^many side:Int^many cnt:Int^many -- ρ r:Seq Int^many)
  locals { m L pc side cnt } {
    pc 1 prim = L 4 prim < prim and pc 3 prim = L 28 prim >= prim and prim or
    [ m L pc 1 prim + st 39 bump ] [ m L pc st ] if
    side 0 prim = [ 37 cnt addto ] [ 38 cnt addto ] if };
: ac (forall ρ; ρ m:Seq Int^many cnt:Int^many s:Int^many pc:Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m cnt s pc side } {
    m s 0 st 0 s cnt ap1 m 40 cnt 1 prim - gt pc side cnt ac2 };
: applycap (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m side } { m m 33 gt m 35 gt m m 35 gt gt side ac };
: mvs2 (forall ρ; ρ m:Seq Int^many d:Int^many pc:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m d pc } {
    pc 1 prim = d 4 prim < prim and pc 3 prim = d 28 prim >= prim and prim or
    [ m d pc 1 prim + st 39 bump 1 ] [ m d pc st 1 ] if };
: mvs (forall ρ; ρ m:Seq Int^many s:Int^many d:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s d } { m s 0 st d m s gt mvs2 };
: st3 (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many idx:Int^many d:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side idx d } {
    d 0 prim < [ m s side idx 1 prim + stp1 ]
    [ m d gt 0 prim = [ m s d mvs ] [ m s side idx 1 prim + stp1 ] if ] if };
: st2 (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many idx:Int^many dr:Int^many dc:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side idx dr dc } {
    m s gt dr okdir
    [ m s side idx s dr dc nb st3 ]
    [ m s side idx 1 prim + stp1 ] if };
: stp1 (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many idx:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side idx } {
    idx 4 prim >= [ m 0 ]
    [ m s side idx idx 2 prim < [ -1 ] [ 1 ] if idx 2 prim mod 0 prim = [ -1 ] [ 1 ] if st2 ] if };
: fs2 (forall ρ; ρ m:Seq Int^many ok:Int^many s:Int^many side:Int^many -- ρ r:Seq Int^many o:Int^many)
  locals { m ok s side } { ok 1 prim = [ m 1 ] [ m s 1 prim + side fs ] if };
: fs (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side } {
    s 32 prim >= [ m 0 ]
    [ m s gt side mine [ m s side 0 stp1 ] [ m 0 ] if s side fs2 ] if };
: findstep (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m side } { m 0 side fs };
: mv2 (forall ρ; ρ side:Int^many m:Seq Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { side m } {
    m 33 gt 0 prim > [ m side applycap 1 ] [ m side findstep ] if };
: mover (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m side } { side m 33 0 st side findcap mv2 };
: gm2 (forall ρ; ρ m0:Seq Int^many m1:Seq Int^many ok:Int^many -- ρ r:Seq Int^many)
  locals { m0 m1 ok } {
    ok 0 prim = [ m0 95 2 m0 96 gt prim - st ]
    [ m0 94 gt m0 97 gt prim >= [ m0 ]
      [ m1 94 bump 96 1 m0 96 gt prim - st gm ] if ] if };
: gm (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m m m 96 gt mover gm2 };
: bd (forall ρ; ρ out:Seq Int^many m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { out m i } {
    i 32 prim >= [ out ] [ out m i gt prim seq-int.push m i 1 prim + bd ] if };
: fin2 (forall ρ; ρ m:Seq Int^many -- ρ b:Seq Int^many a:Int^many c:Int^many d:Int^many e:Int^many f:Int^many)
  locals { m } {
    prim seq-int.empty m 0 bd m 94 gt m 37 gt m 38 gt m 39 gt m 95 gt };
: main (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ b:Seq Int^many a:Int^many c:Int^many d:Int^many e:Int^many f:Int^many)
  locals { board turn plies } {
    board 100 pad 96 turn st 97 plies st gm fin2 };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ac
at: line 89, column 44
message: `gt` in `ac` takes m:Seq Int, i:Int, bottom to top, but here it gets, bottom to top, `40` (Int) and the result of `prim -` (Int).
expected: .. Seq Int Int
actual: ρ Int Int Int Seq Int Seq Int Int Int
hint: The second value from the top, `40` (Int), is not what `gt` takes there (Seq Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## regex
Match strings against a regular expression given as tokens. Token 0 to 25 is that letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one or more sequences separated by '|'; a sequence is zero or more items, one after another; an item is an atom followed by zero or more postfix operators; an atom is a letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one after another (an empty sequence matches the empty string), and an alternation matches if any of its sequences does. A pattern that does not fit the grammar, such as one with an operator where an atom should start, a '(' never closed or a ')' with no '(' open, is invalid. The strings are given together: string j has lens[j] letters, and chars holds every string's letters, string 0 first. For each string, return whether the whole string matches the pattern, and the length of the longest start of it (from no letters up to all of them) that matches, or -1 if none does. Also return how many strings match whole and whether the pattern is valid; for an invalid pattern every string gives false and -1, the count is 0 and validity is false. pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, adding up to the length of chars; every value of chars is 0 to 25.
Inputs on the stack, bottom to top: pattern: Seq Int, lens: Seq Int, chars: Seq Int.
Outputs left on the stack, bottom to top: full: Seq Bool, longest: Seq Int, count: Int, valid: Bool.
Example: stack [{ 0 27 1 30 31 2 3 32 28 }, { 3 2 4 0 3 1 3 }, { 0 0 1 2 3 2 3 2 3 2 3 2 1 0 1 1 }] becomes [{ true true true false false true false }, { 3 2 4 -1 2 1 2 }, 4, true].

Your answer:
```
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: zs (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  locals { n } { prim seq-int.empty n pad };
: tok (forall ρ; ρ pt:Seq Int^many pos:Int^many -- ρ t:Int^many)
  locals { pt pos } { pos pt prim seq-int.len prim < [ pt pos prim seq-int.at ] [ -1 ] if };
: mk3 (forall ρ; ρ T:Seq Int^many base:Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { T base ty a b } { T base ty st base 1 prim + a st base 2 prim + b st };
: mk2 (forall ρ; ρ T:Seq Int^many n:Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many k:Int^many)
  locals { T n ty a b } { T 1 n 1 prim + st n 3 prim * 10 prim + ty a b mk3 n };
: mk (forall ρ; ρ T:Seq Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many k:Int^many)
  locals { T ty a b } { T T 1 gt ty a b mk2 };
: nt (forall ρ; ρ T:Seq Int^many n:Int^many k:Int^many -- ρ v:Int^many)
  locals { T n k } { T 10 n 3 prim * prim + k prim + gt };
: failn (forall ρ; ρ T:Seq Int^many -- ρ r:Seq Int^many n:Int^many pos:Int^many)
  locals { T } { T 0 1 st 0 99 };
: pa3 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many p2:Int^many -- ρ r:Seq Int^many k:Int^many pos:Int^many)
  locals { pt T n p2 } {
    p2 pt tok 32 prim = [ T n p2 1 prim + ] [ T failn ] if };
: patom2 (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many t:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos t } {
    t 0 prim >= t 25 prim <= prim and
    [ T 1 t 0 mk pos 1 prim + ]
    [ t 26 prim = [ T 2 0 0 mk pos 1 prim + ]
      [ t 31 prim = [ pt T pt pos 1 prim + palt pa3 ] [ T failn ] if ] if ] if };
: patom (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { T pt pos pt pos tok patom2 };
: pf2 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many t:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos t } {
    t 27 prim >= t 29 prim <= prim and
    [ pt T t 24 prim - n 0 mk pos 1 prim + pf ] [ T n pos ] if };
: pf (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos } { pt T n pos pt pos tok pf2 };
: pitem (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { pt T pt pos patom pf };
: sq2 (forall ρ; ρ n:Int^many pt:Seq Int^many T:Seq Int^many n2:Int^many pos2:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { n pt T n2 pos2 } { pt T 6 n n2 mk pos2 sq };
: sq1 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many t:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos t } {
    t 0 prim < t 30 prim = prim or t 32 prim = prim or
    [ T n pos ]
    [ t 27 prim >= t 29 prim <= prim and
      [ T failn ] [ n pt T pt pos pitem sq2 ] if ] if };
: sq (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos } { pt T n pos pt pos tok sq1 };
: pseq (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { pt T 0 0 0 mk pos sq };
: al2 (forall ρ; ρ n:Int^many pt:Seq Int^many T:Seq Int^many n2:Int^many pos2:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { n pt T n2 pos2 } { pt T 7 n n2 mk pos2 al };
: al (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos } {
    pos pt tok 30 prim = [ n pt T pt pos 1 prim + pseq al2 ] [ T n pos ] if };
: palt (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { pt T pt pos pseq al };
: pr2 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many v:Bool^many)
  locals { pt T n pos } {
    T n T 0 gt 0 prim = pos pt prim seq-int.len prim = prim and };
: parse (forall ρ; ρ pt:Seq Int^many -- ρ r:Seq Int^many k:Int^many v:Bool^many)
  locals { pt } { pt 300 zs pt 0 palt pr2 };
: sh (forall ρ; ρ R:Seq Int^many sx:Seq Int^many S:Seq Int^many c:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { R sx S c i } {
    i sx prim seq-int.len prim >= [ R ]
    [ S i gt 1 prim = c 0 prim < sx i gt c prim = prim or prim and
      [ R i 1 prim + 1 st ] [ R ] if sx S c i 1 prim + sh ] if };
: shf (forall ρ; ρ sx:Seq Int^many S:Seq Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { sx S c } { sx prim seq-int.len 1 prim + zs sx S c 0 sh };
: cl (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 1 prim > [ 1 ] [ x ] if };
: unl (forall ρ; ρ A:Seq Int^many B:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { A B i } {
    i A prim seq-int.len prim >= [ A ]
    [ A i A i gt B i gt prim + cl st B i 1 prim + unl ] if };
: un (forall ρ; ρ A:Seq Int^many B:Seq Int^many -- ρ r:Seq Int^many)
  locals { A B } { A B 0 unl };
: smn (forall ρ; ρ S:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { S i acc } {
    i S prim seq-int.len prim >= [ acc ] [ S i 1 prim + acc S i gt prim + smn ] if };
: sm (forall ρ; ρ S:Seq Int^many -- ρ r:Int^many)
  locals { S } { S 0 0 smn };
: fx2 (forall ρ; ρ T:Seq Int^many sx:Seq Int^many a:Int^many R:Seq Int^many R2:Seq Int^many -- ρ r:Seq Int^many)
  locals { T sx a R R2 } {
    R2 sm R sm prim = [ R2 ] [ T sx a R2 fx ] if };
: fx (forall ρ; ρ T:Seq Int^many sx:Seq Int^many a:Int^many R:Seq Int^many -- ρ r:Seq Int^many)
  locals { T sx a R } { T sx a R R T sx a R ev un fx2 };
: ev2 (forall ρ; ρ T:Seq Int^many sx:Seq Int^many n:Int^many S:Seq Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { T sx n S ty a b } {
    ty 0 prim = [ S ]
    [ ty 1 prim = [ sx S a shf ]
    [ ty 2 prim = [ sx S -1 shf ]
    [ ty 3 prim = [ T sx a S fx ]
    [ ty 4 prim = [ T sx a T sx a S ev fx ]
    [ ty 5 prim = [ S T sx a S ev un ]
    [ ty 6 prim = [ T sx b T sx a S ev ev ]
    [ T sx a S ev T sx b S ev un ] if ] if ] if ] if ] if ] if ] if };
: ev (forall ρ; ρ T:Seq Int^many sx:Seq Int^many n:Int^many S:Seq Int^many -- ρ r:Seq Int^many)
  locals { T sx n S } { T sx n S T n 0 nt T n 1 nt T n 2 nt ev2 };
: lg (forall ρ; ρ R:Seq Int^many i:Int^many -- ρ r:Int^many)
  locals { R i } {
    i 0 prim < [ -1 ] [ R i gt 1 prim = [ i ] [ R i 1 prim - lg ] if ] if };
: one (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many sx:Seq Int^many -- ρ r:Seq Int^many)
  locals { T root valid sx } {
    valid [ T sx root sx prim seq-int.len 1 prim + zs 0 1 st ev ]
          [ sx prim seq-int.len 1 prim + zs ] if };
: sb (forall ρ; ρ chars:Seq Int^many i:Int^many end:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { chars i end out } {
    i end prim >= [ out ] [ chars i 1 prim + end out chars i gt prim seq-int.push sb ] if };
: sub (forall ρ; ρ chars:Seq Int^many off:Int^many len:Int^many -- ρ r:Seq Int^many)
  locals { chars off len } { chars off off len prim + prim seq-int.empty sb };
: strs2 (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many chars:Seq Int^many lens:Seq Int^many j:Int^many off:Int^many fa:Seq Bool^many la:Seq Int^many cnt:Int^many R:Seq Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many)
  locals { T root valid chars lens j off fa la cnt R } {
    T root valid chars lens j 1 prim + off lens j gt prim +
    fa R lens j gt gt 1 prim = prim seq-bool.push
    la R lens j gt lg prim seq-int.push
    cnt R lens j gt gt prim +
    strs };
: strs (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many chars:Seq Int^many lens:Seq Int^many j:Int^many off:Int^many fa:Seq Bool^many la:Seq Int^many cnt:Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many)
  locals { T root valid chars lens j off fa la cnt } {
    j lens prim seq-int.len prim >= [ fa la cnt ]
    [ T root valid chars lens j off fa la cnt
      T root valid chars off lens j gt sub one strs2 ] if };
: main2 (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many lens:Seq Int^many chars:Seq Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many v:Bool^many)
  locals { T root valid lens chars } {
    T root valid chars lens 0 0 prim seq-bool.empty prim seq-int.empty 0 strs valid };
: main (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many v:Bool^many)
  locals { pattern lens chars } { pattern parse lens chars main2 };

```
On the example, the run failed:
The checker found 2 errors, one for each word it did not accept. Fix them all before you run it again.

error 1 of 2
code: firth.type.word-input-mismatch
word: pa3
at: line 21, column 11
message: `tok` in `pa3` takes pt:Seq Int, pos:Int, bottom to top, but here it gets, bottom to top, `p2` (Int) and `pt` (Seq Int).
expected: .. Seq Int Int
actual: ρ Seq Int Int Int Int Seq Int
hint: These are the values `tok` takes, in another order. To push them in its order, write `pt p2` in place of `p2 pt` on line 21. With that edit `pa3` checks.

error 2 of 2
code: firth.type.word-input-mismatch
word: al
at: line 54, column 12
message: `tok` in `al` takes pt:Seq Int, pos:Int, bottom to top, but here it gets, bottom to top, `pos` (Int) and `pt` (Seq Int).
expected: .. Seq Int Int
actual: ρ Seq Int Seq Int Int Int Int Seq Int
hint: These are the values `tok` takes, in another order. To push them in its order, write `pt pos` in place of `pos pt` on line 54. With that edit `al` checks.

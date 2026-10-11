Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sokoban
Play moves in a warehouse puzzle and report what happened. The floor is a grid of width columns and height rows; cell (row r, column c) is number r times width plus c, and cells[i] is 0 for floor, 1 for wall and 2 for a goal (a goal is also floor). The worker stands on cell player, and boxes lists the cells holding boxes: box k starts on boxes[k]. Each move is 0 up (to the cell width lower in number), 1 right (one higher), 2 down (width higher), 3 left (one lower) or 4 undo. Read the moves in order. Before reading each move, the first one included, if every box is on a goal, stop: the puzzle is solved and the moves not yet read are not used. A move in a direction looks at the next cell t that way from the worker. If t is a wall, the move is blocked and nothing changes. If t holds a box, look at the cell u beyond it in the same direction: if u is a wall or holds a box, the move is blocked; otherwise the box moves to u and the worker to t, which is a push. Otherwise the worker moves to t, which is a step. A push or a step is recorded in the history, the latest last; a blocked move is not. A pushed box is dead if, after the push, it is not on a goal, has a wall above or below it, and also has a wall to its left or right. An undo takes back the latest move in the history and removes it from the history: the worker moves back the way it came, and if that move was a push, its box moves back too. An undo with an empty history does nothing. Return the worker's final cell, the final cell of each box (in the order of boxes), the number of moves read, the number of moves left in the history, the number of pushes made (an undone push still counts), the number of blocked moves, the number of undos that took a move back, the number of pushes that left a box dead (again counting undone ones), and whether every box is on a goal at the end. width and height are 3 to 12; cells has width times height values, each 0 to 2, and every cell in the first or last row or column is a wall; player and every value of boxes are cells that are not walls, boxes has 1 to 6 values, and no two of player and the boxes are the same cell; moves has at most 200 values, each 0 to 4.
Inputs on the stack, bottom to top: width: Int, height: Int, cells: Seq Int, player: Int, boxes: Seq Int, moves: Seq Int.
Outputs left on the stack, bottom to top: player: Int, boxes: Seq Int, read: Int, history: Int, pushes: Int, blocked: Int, undos: Int, dead: Int, solved: Bool.
Example: stack [6, 5, { 1 1 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1 0 0 0 2 1 1 1 1 1 1 1 }, 9, { 15 }, { 2 1 2 3 3 4 4 0 3 3 4 1 1 }] becomes [16, { 21 }, 13, 6, 3, 1, 3, 1, false].

Your answer:
```
: sget
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Int^many)
  prim seq-int.at;

: sput
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: add
  (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m i x } { m i m i sget x prim + sput };

: bump
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i 1 add };

: grow
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    s prim seq-int.len n prim <
    [ s 0 prim seq-int.push n grow ]
    [ s ] if };

: blit
  (forall ρ; ρ d:Seq Int^many o:Int^many src:Seq Int^many i:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { d o src i n } {
    i n prim <
    [ d o i prim + src i prim seq-int.at prim seq-int.set o src i 1 prim + n blit ]
    [ d ] if };

: sl
  (forall ρ; ρ m:Seq Int^many k:Int^many h:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m k h acc } {
    k h prim <
    [ m k 1 prim + h acc m k sget prim seq-int.push sl ]
    [ acc ] if };

: allg
  (forall ρ; ρ m:Seq Int^many k:Int^many -- ρ b:Bool^many)
  locals { m k } {
    k m 8 sget prim <
    [ m 16 m 160 k prim + sget prim + sget 2 prim =
      [ m k 1 prim + allg ] [ false ] if ]
    [ true ] if };

: dlt
  (forall ρ; ρ m:Seq Int^many mv:Int^many -- ρ d:Int^many)
  locals { m mv } {
    mv 0 prim = [ 0 m 0 sget prim - ]
    [ mv 1 prim = [ 1 ]
      [ mv 2 prim = [ m 0 sget ] [ -1 ] if ] if ] if };

: fb
  (forall ρ; ρ m:Seq Int^many c:Int^many k:Int^many -- ρ r:Int^many)
  locals { m c k } {
    k m 8 sget prim <
    [ m 160 k prim + sget c prim =
      [ k ] [ m c k 1 prim + fb ] if ]
    [ -1 ] if };

: iswall
  (forall ρ; ρ m:Seq Int^many c:Int^many -- ρ b:Bool^many)
  locals { m c } { m 16 c prim + sget 1 prim = };

: hpush
  (forall ρ; ρ m:Seq Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m e } { m 372 m 3 sget prim + e sput 3 bump };

: chk
  (forall ρ; ρ m:Seq Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { m u } {
    m 16 u prim + sget 2 prim = prim not
    m u m 0 sget prim - iswall m u m 0 sget prim + iswall prim or
    m u 1 prim - iswall m u 1 prim + iswall prim or
    prim and prim and
    [ m 7 bump ] [ m ] if };

: dopush
  (forall ρ; ρ m:Seq Int^many mv:Int^many d:Int^many t:Int^many bi:Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { m mv d t bi u } {
    m 160 bi prim + u sput 1 t sput
    mv 16 prim * bi 1 prim + prim + hpush
    4 bump u chk };

: move5
  (forall ρ; ρ m:Seq Int^many mv:Int^many d:Int^many t:Int^many bi:Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { m mv d t bi u } {
    m 16 u prim + sget 1 prim = m u 0 fb 0 prim >= prim or
    [ m 5 bump ]
    [ m mv d t bi u dopush ] if };

: move4
  (forall ρ; ρ m:Seq Int^many mv:Int^many d:Int^many t:Int^many bi:Int^many -- ρ r:Seq Int^many)
  locals { m mv d t bi } {
    bi 0 prim <
    [ m 1 t sput mv 16 prim * hpush ]
    [ m mv d t bi t d prim + move5 ] if };

: move3
  (forall ρ; ρ m:Seq Int^many mv:Int^many d:Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { m mv d t } {
    m 16 t prim + sget 1 prim =
    [ m 5 bump ]
    [ m mv d t m t 0 fb move4 ] if };

: mv2
  (forall ρ; ρ m:Seq Int^many mv:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m mv d } { m mv d m 1 sget d prim + move3 };

: mvto
  (forall ρ; ρ m:Seq Int^many mv:Int^many -- ρ r:Seq Int^many)
  locals { m mv } { m mv m mv dlt mv2 };

: undo5
  (forall ρ; ρ m:Seq Int^many e:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m e d } {
    e 16 prim mod 0 prim >
    [ m 159 e 16 prim mod prim + m 159 e 16 prim mod prim + sget d prim - sput ]
    [ m ] if };

: undo4
  (forall ρ; ρ m:Seq Int^many e:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m e d } {
    m 1 m 1 sget d prim - sput e d undo5 };

: undo3
  (forall ρ; ρ m:Seq Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m e } { m e m m e 16 prim div dlt undo4 };

: undo2
  (forall ρ; ρ m:Seq Int^many h:Int^many -- ρ r:Seq Int^many)
  locals { m h } {
    m 3 h sput 6 bump m 372 h prim + sget undo3 };

: unw
  (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } {
    m 3 sget 0 prim >
    [ m m 3 sget 1 prim - undo2 ]
    [ m ] if };

: domove
  (forall ρ; ρ m:Seq Int^many mv:Int^many -- ρ r:Seq Int^many)
  locals { m mv } {
    mv 4 prim = [ m unw ] [ m mv mvto ] if };

: stp
  (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m 2 bump m 170 m 2 sget prim + sget domove };

: run
  (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } {
    m 2 sget m 9 sget prim <
    [ m 0 allg [ m ] [ m stp run ] if ]
    [ m ] if };

: bx
  (forall ρ; ρ m:Seq Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m k acc } {
    k m 8 sget prim <
    [ m k 1 prim + acc m 160 k prim + sget prim seq-int.push bx ]
    [ acc ] if };

: outp
  (forall ρ; ρ m:Seq Int^many -- ρ p:Int^many bs:Seq Int^many rd:Int^many h:Int^many pu:Int^many bl:Int^many un:Int^many dd:Int^many sv:Bool^many)
  locals { m } {
    m 1 sget
    m 0 prim seq-int.empty bx
    m 2 sget m 3 sget m 4 sget m 5 sget m 6 sget m 7 sget
    m 0 allg };

: main
  (forall ρ; ρ w:Int^many h:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ p:Int^many bs:Seq Int^many rd:Int^many hi:Int^many pu:Int^many bl:Int^many un:Int^many dd:Int^many sv:Bool^many)
  locals { w h cells player boxes moves } {
    prim seq-int.empty 576 grow
    0 w sput
    1 player sput
    8 boxes prim seq-int.len sput
    9 moves prim seq-int.len sput
    16 cells 0 cells prim seq-int.len blit
    160 boxes 0 boxes prim seq-int.len blit
    170 moves 0 moves prim seq-int.len blit
    run outp };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: undo3
at: line 128, column 46
message: `undo4` in `undo3` takes m:Seq Int, e:Int, d:Int, bottom to top, but here it gets, bottom to top, `e` (Int), `m` (Seq Int) and the result of `dlt` (Int).
expected: .. Seq Int Int Int
actual: ρ Seq Int Int Seq Int Int
hint: The second value from the top, `m` (Seq Int), is not what `undo4` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

## regex
Match strings against a regular expression given as tokens. Token 0 to 25 is that letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one or more sequences separated by '|'; a sequence is zero or more items, one after another; an item is an atom followed by zero or more postfix operators; an atom is a letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one after another (an empty sequence matches the empty string), and an alternation matches if any of its sequences does. A pattern that does not fit the grammar, such as one with an operator where an atom should start, a '(' never closed or a ')' with no '(' open, is invalid. The strings are given together: string j has lens[j] letters, and chars holds every string's letters, string 0 first. For each string, return whether the whole string matches the pattern, and the length of the longest start of it (from no letters up to all of them) that matches, or -1 if none does. Also return how many strings match whole and whether the pattern is valid; for an invalid pattern every string gives false and -1, the count is 0 and validity is false. pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, adding up to the length of chars; every value of chars is 0 to 25.
Inputs on the stack, bottom to top: pattern: Seq Int, lens: Seq Int, chars: Seq Int.
Outputs left on the stack, bottom to top: full: Seq Bool, longest: Seq Int, count: Int, valid: Bool.
Example: stack [{ 0 27 1 30 31 2 3 32 28 }, { 3 2 4 0 3 1 3 }, { 0 0 1 2 3 2 3 2 3 2 3 2 1 0 1 1 }] becomes [{ true true true false false true false }, { 3 2 4 -1 2 1 2 }, 4, true].

Your answer:
```
: sget
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Int^many)
  prim seq-int.at;

: sput
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: add
  (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m i x } { m i m i sget x prim + sput };

: grow
  (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } {
    s prim seq-int.len n prim <
    [ s 0 prim seq-int.push n grow ]
    [ s ] if };

: blit
  (forall ρ; ρ d:Seq Int^many o:Int^many src:Seq Int^many i:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { d o src i n } {
    i n prim <
    [ d o i prim + src i prim seq-int.at prim seq-int.set o src i 1 prim + n blit ]
    [ d ] if };

: bor2
  (forall ρ; ρ a:Int^many b:Int^many w:Int^many acc:Int^many -- ρ r:Int^many)
  locals { a b w acc } {
    a 0 prim > b 0 prim > prim or
    [ a 2 prim div b 2 prim div w 2 prim *
      acc a 2 prim mod b 2 prim mod prim + 0 prim > [ w ] [ 0 ] if prim +
      bor2 ]
    [ acc ] if };

: bor
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b 1 0 bor2 };

: cl
  (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Int^many)
  locals { m i d } {
    m i sget 31 prim =
    [ m i 1 prim + d 1 prim + cl ]
    [ m i sget 32 prim =
      [ d 1 prim = [ i ] [ m i 1 prim + d 1 prim - cl ] if ]
      [ m i 1 prim + d cl ] if ] if };

: ae
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } {
    m p sget 31 prim =
    [ m p 1 prim + 1 cl 1 prim + ]
    [ p 1 prim + ] if };

: so
  (forall ρ; ρ m:Seq Int^many q:Int^many -- ρ r:Int^many)
  locals { m q } {
    q m 20 sget prim <
    [ m q sget 27 prim >= m q sget 29 prim <= prim and
      [ m q 1 prim + so ] [ q ] if ]
    [ q ] if };

: ie
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } { m m p ae so };

: se
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } {
    p m 20 sget prim <
    [ m p sget 30 prim = m p sget 32 prim = prim or
      [ p ] [ m m p ie se ] if ]
    [ p ] if };

: sh
  (forall ρ; ρ m:Seq Int^many t:Int^many s:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m t s i acc } {
    i m 21 sget prim <
    [ s m 40 i prim + sget prim div 2 prim mod 1 prim =
      t 26 prim = m 24 i prim + sget t prim = prim or prim and
      [ m t s i 1 prim + acc m 41 i prim + sget prim + sh ]
      [ m t s i 1 prim + acc sh ] if ]
    [ acc ] if };

: ea
  (forall ρ; ρ m:Seq Int^many p:Int^many s:Int^many -- ρ r:Int^many)
  locals { m p s } {
    m p sget 31 prim =
    [ m p 1 prim + s al ]
    [ m m p sget s 0 0 sh ] if };

: st2
  (forall ρ; ρ m:Seq Int^many p:Int^many k:Int^many r:Int^many r2:Int^many -- ρ x:Int^many)
  locals { m p k r r2 } {
    r2 r prim = [ r ] [ m p k r2 st ] if };

: st
  (forall ρ; ρ m:Seq Int^many p:Int^many k:Int^many r:Int^many -- ρ x:Int^many)
  locals { m p k r } {
    m p k r r m p k r it bor st2 };

: it
  (forall ρ; ρ m:Seq Int^many p:Int^many k:Int^many s:Int^many -- ρ x:Int^many)
  locals { m p k s } {
    k m p ae 1 prim - prim =
    [ m p s ea ]
    [ m k sget 29 prim =
      [ s m p k 1 prim - s it bor ]
      [ m k sget 27 prim =
        [ m p k 1 prim - s st ]
        [ m p k 1 prim - m p k 1 prim - s it st ] if ] if ] if };

: ei
  (forall ρ; ρ m:Seq Int^many p:Int^many s:Int^many -- ρ x:Int^many)
  locals { m p s } { m p m m p ie 1 prim - s it };

: sqv
  (forall ρ; ρ m:Seq Int^many p:Int^many s:Int^many -- ρ x:Int^many)
  locals { m p s } {
    p m 20 sget prim <
    [ m p sget 30 prim = m p sget 32 prim = prim or
      [ s ]
      [ m m p ie m p s ei sqv ] if ]
    [ s ] if };

: alp2
  (forall ρ; ρ m:Seq Int^many q:Int^many s:Int^many acc:Int^many -- ρ x:Int^many)
  locals { m q s acc } {
    q m 20 sget prim < m q sget 30 prim = prim and
    [ m q 1 prim + s acc alp ]
    [ acc ] if };

: alp
  (forall ρ; ρ m:Seq Int^many p:Int^many s:Int^many acc:Int^many -- ρ x:Int^many)
  locals { m p s acc } {
    m m p se s acc m p s sqv bor alp2 };

: al
  (forall ρ; ρ m:Seq Int^many p:Int^many s:Int^many -- ρ x:Int^many)
  locals { m p s } { m p s 0 alp };

: pa2
  (forall ρ; ρ m:Seq Int^many q:Int^many -- ρ r:Int^many)
  locals { m q } {
    q 0 prim <
    [ -1 ]
    [ q m 20 sget prim < m q sget 32 prim = prim and
      [ q 1 prim + ] [ -1 ] if ] if };

: pa
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } {
    p m 20 sget prim >=
    [ -1 ]
    [ m p sget 26 prim <=
      [ p 1 prim + ]
      [ m p sget 31 prim = [ m m p 1 prim + pal pa2 ] [ -1 ] if ] if ] if };

: pi2
  (forall ρ; ρ m:Seq Int^many q:Int^many -- ρ r:Int^many)
  locals { m q } {
    q 0 prim < [ -1 ] [ m q so ] if };

: pi
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } { m m p pa pi2 };

: ps2
  (forall ρ; ρ m:Seq Int^many q:Int^many -- ρ r:Int^many)
  locals { m q } {
    q 0 prim < [ -1 ] [ m q ps ] if };

: ps
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } {
    p m 20 sget prim <
    [ m p sget 26 prim <= m p sget 31 prim = prim or
      [ m m p pi ps2 ] [ p ] if ]
    [ p ] if };

: pal2
  (forall ρ; ρ m:Seq Int^many q:Int^many -- ρ r:Int^many)
  locals { m q } {
    q 0 prim <
    [ -1 ]
    [ q m 20 sget prim < m q sget 30 prim = prim and
      [ m q 1 prim + pal ] [ q ] if ] if };

: pal
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { m p } { m m p ps pal2 };

: vld
  (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } {
    m 23 m 0 pal m 20 sget prim = [ 1 ] [ 0 ] if sput };

: pw1
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } {
    i 12 prim <
    [ m 41 i prim + m 40 i prim + sget 2 prim * sput i 1 prim + pw1 ]
    [ m ] if };

: hb
  (forall ρ; ρ m:Seq Int^many s:Int^many i:Int^many -- ρ r:Int^many)
  locals { m s i } {
    i 0 prim <
    [ -1 ]
    [ s m 40 i prim + sget prim div 2 prim mod 1 prim =
      [ i ] [ m s i 1 prim - hb ] if ] if };

: rc2
  (forall ρ; ρ m:Seq Int^many j:Int^many s:Int^many f:Int^many -- ρ r:Seq Int^many)
  locals { m j s f } {
    m 60 j prim + f sput
    22 f add
    70 j prim + m s m 21 sget hb sput };

: rc
  (forall ρ; ρ m:Seq Int^many j:Int^many s:Int^many -- ρ r:Seq Int^many)
  locals { m j s } {
    m j s s m 40 m 21 sget prim + sget prim div 2 prim mod rc2 };

: rs
  (forall ρ; ρ m:Seq Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m j } {
    m 23 sget 1 prim =
    [ m j m 0 1 al rc ]
    [ m 70 j prim + -1 sput ] if };

: go2
  (forall ρ; ρ m:Seq Int^many chars:Seq Int^many j:Int^many off:Int^many ll:Int^many -- ρ r:Seq Int^many)
  locals { m chars j off ll } {
    m 21 ll sput 24 off prim - chars off off ll prim + blit
    j rs
    chars j 1 prim + off ll prim + go };

: go
  (forall ρ; ρ m:Seq Int^many chars:Seq Int^many j:Int^many off:Int^many -- ρ r:Seq Int^many)
  locals { m chars j off } {
    j m 25 sget prim <
    [ m chars j off m 80 j prim + sget go2 ]
    [ m ] if };

: fl
  (forall ρ; ρ m:Seq Int^many j:Int^many acc:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { m j acc } {
    j m 25 sget prim <
    [ m j 1 prim + acc m 60 j prim + sget 1 prim = prim seq-bool.push fl ]
    [ acc ] if };

: ll
  (forall ρ; ρ m:Seq Int^many j:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m j acc } {
    j m 25 sget prim <
    [ m j 1 prim + acc m 70 j prim + sget prim seq-int.push ll ]
    [ acc ] if };

: fin
  (forall ρ; ρ m:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { m } {
    m 0 prim seq-bool.empty fl
    m 0 prim seq-int.empty ll
    m 22 sget
    m 23 sget 1 prim = };

: main
  (forall ρ; ρ pat:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pat lens chars } {
    prim seq-int.empty 100 grow
    0 pat 0 pat prim seq-int.len blit
    20 pat prim seq-int.len sput
    25 lens prim seq-int.len sput
    80 lens 0 lens prim seq-int.len blit
    40 1 sput 0 pw1
    vld
    chars 0 0 go
    fin };

```
On the example, the run failed:
code: firth.type.word-input-mismatch
word: ei
at: line 116, column 46
message: `it` in `ei` takes m:Seq Int, p:Int, k:Int, s:Int, bottom to top, but here it gets, bottom to top, `p` (Int), `m` (Seq Int), the result of `prim -` (Int) and `s` (Int).
expected: .. Seq Int Int Int Int
actual: ρ Seq Int Int Seq Int Int Int
hint: The third value from the top, `m` (Seq Int), is not what `it` takes there (Int). Check that it gets the values it should, in its order (`swap` exchanges the top two values), or the operation.

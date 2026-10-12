Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## checkers
Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus 1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 for a black man and 4 for a black king. White men move up (towards row 0) and black men down; kings move both ways. A step moves a piece to an empty square diagonally next to it, in a direction it may move. A jump moves a piece over a diagonally next square holding a piece of the other side, in a direction it may move, to the empty square just beyond; the piece jumped over is taken off the board at once, and the square the capturing piece started from counts as empty during the capture, so it may land there. A capture is a sequence of jumps by one piece: after each jump, if that piece can jump again from where it landed, it must, and a capture is complete only when it cannot, except that a man that lands on the far row (row 0 for white, row 7 for black) is crowned king and its capture ends there. A man that steps onto its far row is crowned too. The side to move must capture if any of its pieces can; then it plays the complete capture that takes the most pieces, choosing among equals the one whose piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first place the lists differ, whatever its last landing. If it cannot capture it makes the step whose piece starts on the lowest-numbered square, and among those the step to the lowest-numbered square. White moves first if turn is 0 and black if turn is 1, then the sides alternate. Before each move, if the side to move has no capture or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on either side), and the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40.
Inputs on the stack, bottom to top: board: Seq Int, turn: Int, plies: Int.
Outputs left on the stack, bottom to top: board: Seq Int, played: Int, white_took: Int, black_took: Int, crowned: Int, result: Int.
Example: stack [{ 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 3 3 0 0 0 0 0 0 3 0 0 0 1 0 0 0 }, 0, 2] becomes [{ 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }, 2, 3, 0, 0, 0].

Your answer:
```
: colof
  (forall ρ; ρ sq:Int -- ρ c:Int)
  locals { sq } { 2 sq 4 prim mod prim * 1 prim + sq 4 prim div 2 prim mod prim - };

: nbr
  (forall ρ; ρ sq:Int d:Int -- ρ r:Int)
  locals { sq d } {
    sq 4 prim div
    locals { r } {
      sq colof
      locals { c } {
        r d 2 prim < [ -1 ] [ 1 ] if prim +
        locals { r2 } {
          c d 2 prim mod 0 prim = [ -1 ] [ 1 ] if prim +
          locals { c2 } {
            r2 0 prim < r2 7 prim > prim or c2 0 prim < c2 7 prim > prim or prim or
            [ -1 ]
            [ r2 4 prim * c2 2 prim div prim + ]
            if } } } } };

: mayd
  (forall ρ; ρ p:Int d:Int -- ρ r:Bool)
  locals { p d } {
    p 2 prim mod 0 prim =
    p 1 prim = d 2 prim < prim and prim or
    p 3 prim = d 1 prim > prim and prim or };

: isfar
  (forall ρ; ρ p:Int sq:Int -- ρ r:Bool)
  locals { p sq } {
    p 1 prim = sq 4 prim div 0 prim = prim and
    p 3 prim = sq 4 prim div 7 prim = prim and prim or };

: midsq
  (forall ρ; ρ a:Int b:Int -- ρ m:Int)
  locals { a b } {
    a 4 prim div b 4 prim div prim + 2 prim div 4 prim *
    a colof b colof prim + 2 prim div 2 prim div prim + };

: addto
  (forall ρ; ρ st:Seq Int i:Int k:Int -- ρ r:Seq Int)
  locals { st i k } { st i st i prim seq-int.at k prim + prim seq-int.set };

: minint
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } { a b prim < [ a ] [ b ] if };

: jumpland
  (forall ρ; ρ board:Seq Int sq:Int p:Int d:Int -- ρ r:Int)
  locals { board sq p d } {
    p d mayd
    [ sq d nbr
      locals { m } {
        m 0 prim <
        [ -1 ]
        [ board m prim seq-int.at
          locals { q } {
            q 0 prim > q 1 prim - 2 prim div p 1 prim - 2 prim div prim = prim not prim and
            [ m d nbr
              locals { l } {
                l 0 prim <
                [ -1 ]
                [ board l prim seq-int.at 0 prim = [ l ] [ -1 ] if ]
                if } ]
            [ -1 ]
            if } ]
        if } ]
    [ -1 ]
    if };

: anyjump
  (forall ρ; ρ board:Seq Int sq:Int p:Int -- ρ r:Bool)
  locals { board sq p } {
    board sq p 0 jumpland 0 prim >=
    board sq p 1 jumpland 0 prim >= prim or
    board sq p 2 jumpland 0 prim >= prim or
    board sq p 3 jumpland 0 prim >= prim or };

: cmpfrom
  (forall ρ; ρ a:Seq Int b:Seq Int i:Int -- ρ r:Bool)
  locals { a b i } {
    i a prim seq-int.len prim >=
    [ false ]
    [ a i prim seq-int.at b i prim seq-int.at prim <
      [ true ]
      [ a i prim seq-int.at b i prim seq-int.at prim >
        [ false ]
        [ a b i 1 prim + cmpfrom ]
        if ]
      if ]
    if };

: better
  (forall ρ; ρ cand:Seq Int best:Seq Int -- ρ r:Bool)
  locals { cand best } {
    best prim seq-int.len 0 prim =
    [ true ]
    [ cand 0 prim seq-int.at best 0 prim seq-int.at prim >
      [ true ]
      [ cand 0 prim seq-int.at best 0 prim seq-int.at prim <
        [ false ]
        [ cand best 1 cmpfrom ]
        if ]
      if ]
    if };

: pick
  (forall ρ; ρ path:Seq Int best:Seq Int -- ρ r:Seq Int)
  locals { path best } { path best better [ path ] [ best ] if };

: dfs
  (forall ρ; ρ board:Seq Int sq:Int p:Int path:Seq Int best:Seq Int -- ρ r:Seq Int)
  locals { board sq p path best } {
    board sq p anyjump
    [ board sq p path best 0 tryd
      locals { b0 } {
        board sq p path b0 1 tryd
        locals { b1 } {
          board sq p path b1 2 tryd
          locals { b2 } { board sq p path b2 3 tryd } } } ]
    [ path best pick ]
    if };

: tryd
  (forall ρ; ρ board:Seq Int sq:Int p:Int path:Seq Int best:Seq Int d:Int -- ρ r:Seq Int)
  locals { board sq p path best d } {
    board sq p d jumpland
    locals { l } {
      l 0 prim <
      [ best ]
      [ sq d nbr
        locals { m } {
          path 0 path 0 prim seq-int.at 1 prim + prim seq-int.set l prim seq-int.push
          locals { path2 } {
            p l isfar
            [ path2 best pick ]
            [ board m 0 prim seq-int.set l p path2 best dfs ]
            if } } ]
      if } };

: scan
  (forall ρ; ρ board:Seq Int side:Int s:Int best:Seq Int -- ρ r:Seq Int)
  locals { board side s best } {
    s 32 prim >=
    [ best ]
    [ board s prim seq-int.at
      locals { p } {
        p 0 prim > p 1 prim - 2 prim div side prim = prim and
        [ board s 0 prim seq-int.set
          locals { b2 } {
            b2 s p anyjump
            [ board side s 1 prim +
              b2 s p prim seq-int.empty 0 prim seq-int.push s prim seq-int.push best dfs
              scan ]
            [ board side s 1 prim + best scan ]
            if } ]
        [ board side s 1 prim + best scan ]
        if } ]
    if };

: stepd
  (forall ρ; ρ board:Seq Int s:Int p:Int d:Int -- ρ r:Int)
  locals { board s p d } {
    p d mayd
    [ s d nbr
      locals { t } {
        t 0 prim <
        [ 99 ]
        [ board t prim seq-int.at 0 prim = [ t ] [ 99 ] if ]
        if } ]
    [ 99 ]
    if };

: minstep
  (forall ρ; ρ board:Seq Int s:Int p:Int -- ρ r:Int)
  locals { board s p } {
    board s p 0 stepd board s p 1 stepd minint board s p 2 stepd minint board s p 3 stepd minint };

: findstep
  (forall ρ; ρ board:Seq Int side:Int s:Int -- ρ r:Int)
  locals { board side s } {
    s 32 prim >=
    [ -1 ]
    [ board s prim seq-int.at
      locals { p } {
        p 0 prim > p 1 prim - 2 prim div side prim = prim and
        [ board s p minstep
          locals { m } {
            m 99 prim <
            [ s 100 prim * m prim + ]
            [ board side s 1 prim + findstep ]
            if } ]
        [ board side s 1 prim + findstep ]
        if } ]
    if };

: replay
  (forall ρ; ρ board:Seq Int cur:Int best:Seq Int i:Int -- ρ b2:Seq Int c2:Int)
  locals { board cur best i } {
    i best 0 prim seq-int.at prim >=
    [ board cur ]
    [ best i 2 prim + prim seq-int.at
      locals { l } {
        board cur l midsq 0 prim seq-int.set l best i 1 prim + replay } ]
    if };

: game
  (forall ρ; ρ board:Seq Int turn:Int plies:Int st:Seq Int -- ρ b2:Seq Int st2:Seq Int result:Int)
  locals { board turn plies st } {
    board turn 0 prim seq-int.empty scan
    locals { best } {
      board turn 0 findstep
      locals { e } {
        best prim seq-int.len 0 prim > e 0 prim >= prim or
        [ st 0 prim seq-int.at plies prim >=
          [ board st 0 ]
          [ best prim seq-int.len 0 prim >
            [ best 1 prim seq-int.at
              locals { s0 } {
                board s0 prim seq-int.at
                locals { p } {
                  board s0 0 prim seq-int.set s0 best 0 replay
                  locals { b2 cur } {
                    p cur isfar [ 1 ] [ 0 ] if
                    locals { cf } {
                      b2 cur p cf prim + prim seq-int.set
                      st 1 turn prim + best 0 prim seq-int.at addto 3 cf addto 0 1 addto
                      locals { nb ns } { nb 1 turn prim - plies ns game } } } } } ]
            [ e 100 prim div
              locals { s0 } {
                e 100 prim mod
                locals { t } {
                  board s0 prim seq-int.at
                  locals { p } {
                    p t isfar [ 1 ] [ 0 ] if
                    locals { cf } {
                      board s0 0 prim seq-int.set t p cf prim + prim seq-int.set
                      st 3 cf addto 0 1 addto
                      locals { nb ns } { nb 1 turn prim - plies ns game } } } } } ]
            if ]
          if ]
        [ board st 2 turn prim - ]
        if } } };

: main
  (forall ρ; ρ board:Seq Int turn:Int plies:Int
   -- ρ board2:Seq Int played:Int white-took:Int black-took:Int crowned:Int result:Int)
  locals { board turn plies } {
    board turn plies
    prim seq-int.empty 0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    game
    locals { fb st r } {
      fb st 0 prim seq-int.at st 1 prim seq-int.at st 2 prim seq-int.at st 3 prim seq-int.at r } };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 107, column 3
message: Unexpected `pick`, expected `word name`.
expected: word name
actual: pick
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

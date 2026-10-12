Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sokoban
Play moves in a warehouse puzzle and report what happened. The floor is a grid of width columns and height rows; cell (row r, column c) is number r times width plus c, and cells[i] is 0 for floor, 1 for wall and 2 for a goal (a goal is also floor). The worker stands on cell player, and boxes lists the cells holding boxes: box k starts on boxes[k]. Each move is 0 up (to the cell width lower in number), 1 right (one higher), 2 down (width higher), 3 left (one lower) or 4 undo. Read the moves in order. Before reading each move, the first one included, if every box is on a goal, stop: the puzzle is solved and the moves not yet read are not used. A move in a direction looks at the next cell t that way from the worker. If t is a wall, the move is blocked and nothing changes. If t holds a box, look at the cell u beyond it in the same direction: if u is a wall or holds a box, the move is blocked; otherwise the box moves to u and the worker to t, which is a push. Otherwise the worker moves to t, which is a step. A push or a step is recorded in the history, the latest last; a blocked move is not. A pushed box is dead if, after the push, it is not on a goal, has a wall above or below it, and also has a wall to its left or right. An undo takes back the latest move in the history and removes it from the history: the worker moves back the way it came, and if that move was a push, its box moves back too. An undo with an empty history does nothing. Return the worker's final cell, the final cell of each box (in the order of boxes), the number of moves read, the number of moves left in the history, the number of pushes made (an undone push still counts), the number of blocked moves, the number of undos that took a move back, the number of pushes that left a box dead (again counting undone ones), and whether every box is on a goal at the end. width and height are 3 to 12; cells has width times height values, each 0 to 2, and every cell in the first or last row or column is a wall; player and every value of boxes are cells that are not walls, boxes has 1 to 6 values, and no two of player and the boxes are the same cell; moves has at most 200 values, each 0 to 4.
Inputs on the stack, bottom to top: width: Int, height: Int, cells: Seq Int, player: Int, boxes: Seq Int, moves: Seq Int.
Outputs left on the stack, bottom to top: player: Int, boxes: Seq Int, read: Int, history: Int, pushes: Int, blocked: Int, undos: Int, dead: Int, solved: Bool.
Example: stack [6, 5, { 1 1 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1 0 0 0 2 1 1 1 1 1 1 1 }, 9, { 15 }, { 2 1 2 3 3 4 4 0 3 3 4 1 1 }] becomes [16, { 21 }, 13, 6, 3, 1, 3, 1, false].

Your answer:
```
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: bump (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many) 1 incr;
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };
: app (forall ρ; ρ d:Seq Int^many s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { d s i } { i s prim seq-int.len prim >= [ d ] [ d s i get prim seq-int.push s i 1 prim + app ] if };

: delta (forall ρ; ρ w:Int^many d:Int^many -- ρ r:Int^many)
  locals { w d } {
    d 0 prim = [ 0 w prim - ]
    [ d 1 prim = [ 1 ]
      [ d 2 prim = [ w ] [ -1 ] if ] if ] if };

: boxat-loop (forall ρ; ρ st:Seq Int^many cell:Int^many k:Int^many -- ρ r:Int^many)
  locals { st cell k } {
    k st 8 get prim >=
    [ -1 ]
    [ st k 9 prim + get cell prim =
      [ k ] [ st cell k 1 prim + boxat-loop ] if ] if };

: alldone (forall ρ; ρ st:Seq Int^many cells:Seq Int^many k:Int^many -- ρ b:Bool^many)
  locals { st cells k } {
    k st 8 get prim >=
    [ true ]
    [ cells st k 9 prim + get get 2 prim =
      [ st cells k 1 prim + alldone ] [ false ] if ] if };

: isdead (forall ρ; ρ st:Seq Int^many cells:Seq Int^many u:Int^many -- ρ b:Bool^many)
  locals { st cells u } {
    st 0 get locals { w } {
      cells u get 2 prim = prim not
      cells u w prim - get 1 prim = cells u w prim + get 1 prim = prim or prim and
      cells u 1 prim - get 1 prim = cells u 1 prim + get 1 prim = prim or prim and } };

: record (forall ρ; ρ st:Seq Int^many code:Int^many -- ρ r:Seq Int^many)
  locals { st code } { st st 3 get 15 prim + code put 3 bump };

: undo (forall ρ; ρ st:Seq Int^many -- ρ r:Seq Int^many)
  locals { st } {
    st 3 get 0 prim =
    [ st ]
    [ st 3 get 1 prim - locals { h } {
        st 15 h prim + get locals { code } {
          code 8 prim div locals { d } {
            code 8 prim mod 1 prim - locals { k } {
              st 0 get d delta locals { dd } {
                st 3 h put 1 st 1 get dd prim - put 6 bump
                locals { s2 } {
                  k 0 prim >=
                  [ s2 k 9 prim + s2 k 9 prim + get dd prim - put ]
                  [ s2 ] if } } } } } ]
    if };

: domove (forall ρ; ρ st:Seq Int^many cells:Seq Int^many m:Int^many -- ρ r:Seq Int^many)
  locals { st cells m } {
    st 0 get m delta locals { d } {
      st 1 get d prim + locals { t } {
        cells t get 1 prim =
        [ st 5 bump ]
        [ st t 0 boxat-loop locals { k } {
            k 0 prim <
            [ st 1 t put m 8 prim * record ]
            [ t d prim + locals { u } {
                cells u get 1 prim = st u 0 boxat-loop 0 prim >= prim or
                [ st 5 bump ]
                [ st k 9 prim + u put 1 t put 4 bump
                  m 8 prim * k 1 prim + prim + record
                  locals { s3 } {
                    s3 cells u isdead [ s3 7 bump ] [ s3 ] if } ] if } ] if } ] if } } };

: step (forall ρ; ρ st:Seq Int^many cells:Seq Int^many moves:Seq Int^many -- ρ r:Seq Int^many)
  locals { st cells moves } {
    moves st 2 get get st 2 st 2 get 1 prim + put
    locals { m s1 } {
      m 4 prim = [ s1 undo ] [ s1 cells m domove ] if } };

: play (forall ρ; ρ st:Seq Int^many cells:Seq Int^many moves:Seq Int^many -- ρ r:Seq Int^many)
  locals { st cells moves } {
    st cells 0 alldone
    [ st ]
    [ st 2 get moves prim seq-int.len prim >=
      [ st ]
      [ st cells moves step cells moves play ] if ] if };

: init (forall ρ; ρ w:Int^many player:Int^many boxes:Seq Int^many -- ρ r:Seq Int^many)
  locals { w player boxes } {
    prim seq-int.empty w prim seq-int.push player prim seq-int.push
    0 6 pushn boxes prim seq-int.len prim seq-int.push
    boxes 0 app 0 6 boxes prim seq-int.len prim - pushn 0 200 pushn };

: outboxes-loop (forall ρ; ρ st:Seq Int^many out:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { st out k } {
    k st 8 get prim >=
    [ out ]
    [ st out st k 9 prim + get prim seq-int.push k 1 prim + outboxes-loop ] if };

: main
  (forall ρ; ρ w:Int^many h:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many
   -- ρ p:Int^many bx:Seq Int^many rd:Int^many hs:Int^many ps:Int^many bl:Int^many un:Int^many dd:Int^many sv:Bool^many)
  locals { w h cells player boxes moves } {
    w player boxes init cells moves play
    locals { st } {
      st 1 get
      st prim seq-int.empty 0 outboxes-loop
      st 2 get st 3 get st 4 get st 5 get st 6 get st 7 get
      st cells 0 alldone } };

```
On the example, the run failed:
code: firth.syntax.invalid-item
at: line 54, column 39
message: `]` cannot start an item in a word's body.
actual: ]
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## swiss
Run a Swiss-system chess tournament and report the standings. Player p has rating ratings[p]. Scores count half points: a win is 2, a draw 1, a loss 0. Play rounds rounds. At the start of each round, rank the players by score, highest first, then by rating, highest first, then by player number, lowest first. If the number of players is odd, the lowest-ranked player who has not yet had a bye gets one: they score 2 and do not play this round. This is done before pairing, and that player is left out of it. Then pair the others: repeatedly take the highest-ranked player not yet paired this round, and pair them with the highest-ranked unpaired player they have not played before in this tournament; if they have played every unpaired player, pair them with the highest-ranked unpaired player anyway, which is a rematch. In each pair, white goes to the player who has had white fewer times so far; if equal, to the player whose last game was played as black, if exactly one of them (a player who has played no game has no last game); otherwise to the player taken first. A bye is not a game and does not count as a last game. The games of a round are played in the order they were paired, and their results are read from results in that order, round after round: 0 means white won, 1 a draw, 2 black won. Return each player's final score; each player's Buchholz score, the sum of the final scores of the opponents of every game they played (an opponent met twice counts twice; a bye adds nothing); the player numbers ranked by final score, then Buchholz score, then rating, each highest first, then player number, lowest first; the number of times each player had white; and the number of rematches. ratings has 2 to 12 values, each 1,000 to 3,000; rounds is 1 to 7 and below the number of players; results has rounds times (the number of players divided by 2, rounded down) values, each 0 to 2.
Inputs on the stack, bottom to top: ratings: Seq Int, rounds: Int, results: Seq Int.
Outputs left on the stack, bottom to top: scores: Seq Int, buchholz: Seq Int, ranking: Seq Int, whites: Seq Int, rematches: Int.
Example: stack [{ 1500 1600 1400 1700 }, 2, { 0 1 2 0 }] becomes [{ 3 0 3 2 }, { 5 5 3 3 }, { 0 2 3 1 }, { 1 0 1 2 }, 0].

Your answer:
```
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };

: better3 (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many a:Int^many b:Int^many -- ρ r:Bool^many)
  locals { k1 k2 k3 a b } {
    k1 a get k1 b get prim > k1 a get k1 b get prim =
    k2 a get k2 b get prim > k2 a get k2 b get prim =
    k3 a get k3 b get prim > k3 a get k3 b get prim =
    a b prim <
    prim and prim or prim and prim or prim and prim or };

: pick (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many used:Seq Int^many q:Int^many best:Int^many -- ρ r:Int^many)
  locals { k1 k2 k3 n used q best } {
    q n prim >=
    [ best ]
    [ used q get 1 prim =
      [ k1 k2 k3 n used q 1 prim + best pick ]
      [ k1 k2 k3 n used q 1 prim +
        best 0 prim < [ q ] [ k1 k2 k3 q best better3 [ q ] [ best ] if ] if
        pick ] if ] if };

: selloop (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many used:Seq Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 n used out } {
    out prim seq-int.len n prim >=
    [ out ]
    [ k1 k2 k3 n used 0 -1 pick locals { b } {
        k1 k2 k3 n used b 1 put out b prim seq-int.push selloop } ] if };

: sortrank (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 n } {
    k1 k2 k3 n prim seq-int.empty 0 n pushn prim seq-int.empty selloop };

: findbye (forall ρ; ρ st:Seq Int^many rank:Seq Int^many i:Int^many -- ρ p:Int^many)
  locals { st rank i } {
    rank i get locals { p } {
      st 12 p prim + get 0 prim =
      [ p ] [ st rank i 1 prim - findbye ] if } };

: dobye (forall ρ; ρ st:Seq Int^many rank:Seq Int^many r:Int^many -- ρ s2:Seq Int^many)
  locals { st rank r } {
    st 218 get 2 prim mod 1 prim =
    [ st rank st 218 get 1 prim - findbye locals { p } {
        st p 2 incr 12 p prim + 1 put 60 p prim + r 1 prim + put } ]
    [ st ] if };

: findq (forall ρ; ρ st:Seq Int^many rank:Seq Int^many r:Int^many p:Int^many mode:Int^many i:Int^many -- ρ q:Int^many)
  locals { st rank r p mode i } {
    i st 218 get prim >=
    [ -1 ]
    [ rank i get locals { q } {
        st 60 q prim + get r 1 prim + prim = prim not
        mode 1 prim = st 72 p 12 prim * prim + q prim + get 0 prim = prim or
        prim and
        [ q ] [ st rank r p mode i 1 prim + findq ] if } ]
    if };

: play (forall ρ; ρ st:Seq Int^many rs:Seq Int^many w:Int^many b:Int^many -- ρ s2:Seq Int^many)
  locals { st rs w b } {
    rs st 217 get get locals { res } {
      st 217 st 217 get 1 prim + put locals { s0 } {
        s0 216 s0 72 w 12 prim * prim + b prim + get 0 prim > [ 1 ] [ 0 ] if incr
        72 w 12 prim * prim + b prim + 1 incr
        72 b 12 prim * prim + w prim + 1 incr
        24 w prim + 1 incr
        36 w prim + 1 put
        36 b prim + 2 put
        locals { s3 } {
          res 0 prim = [ s3 w 2 incr ]
          [ res 1 prim = [ s3 w 1 incr b 1 incr ] [ s3 b 2 incr ] if ] if } } } };

: game (forall ρ; ρ st:Seq Int^many rs:Seq Int^many p:Int^many q:Int^many -- ρ s2:Seq Int^many)
  locals { st rs p q } {
    st 24 p prim + get st 24 q prim + get prim <
    st 24 p prim + get st 24 q prim + get prim =
    st 36 q prim + get 2 prim = st 36 p prim + get 2 prim = prim not prim and prim not
    prim and prim or
    [ st rs p q play ] [ st rs q p play ] if };

: pairs (forall ρ; ρ st:Seq Int^many rank:Seq Int^many rs:Seq Int^many r:Int^many i:Int^many -- ρ s2:Seq Int^many)
  locals { st rank rs r i } {
    i st 218 get prim >=
    [ st ]
    [ rank i get locals { p } {
        st 60 p prim + get r 1 prim + prim =
        [ st rank rs r i 1 prim + pairs ]
        [ st 60 p prim + r 1 prim + put locals { s1 } {
            s1 rank r p 0 0 findq locals { q0 } {
              q0 0 prim < [ s1 rank r p 1 0 findq ] [ q0 ] if locals { q } {
                s1 60 q prim + r 1 prim + put rs p q game
                rank rs r i 1 prim + pairs } } } ] if } ]
    if };

: round (forall ρ; ρ st:Seq Int^many rt:Seq Int^many rs:Seq Int^many r:Int^many nr:Int^many -- ρ s2:Seq Int^many)
  locals { st rt rs r nr } {
    r nr prim >=
    [ st ]
    [ st rt rt st 218 get sortrank locals { rank } {
        st rank r dobye rank rs r 0 pairs
        locals { s2 } { s2 rt rs r 1 prim + nr round } } ] if };

: bsum (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many n:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p q n acc } {
    q n prim >=
    [ acc ]
    [ st p q 1 prim + n acc st 72 p 12 prim * prim + q prim + get st q get prim * prim + bsum ] if };

: buchl (forall ρ; ρ st:Seq Int^many p:Int^many n:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st p n out } {
    p n prim >=
    [ out ]
    [ st p 1 prim + n out st p 0 n 0 bsum prim seq-int.push buchl ] if };

: blk (forall ρ; ρ st:Seq Int^many base:Int^many n:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st base n i out } {
    i n prim >=
    [ out ]
    [ st base n i 1 prim + out st base i prim + get prim seq-int.push blk ] if };

: main (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buch:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rem:Int^many)
  locals { rt rounds rs } {
    prim seq-int.empty 0 219 pushn 218 rt prim seq-int.len put
    rt rs 0 rounds round locals { st } {
      st 0 rt prim seq-int.len 0 prim seq-int.empty blk locals { sc } {
        st 0 rt prim seq-int.len prim seq-int.empty buchl locals { bh } {
          sc bh sc bh rt rt prim seq-int.len sortrank
          st 24 rt prim seq-int.len 0 prim seq-int.empty blk
          st 216 get } } } };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 16, column 3
message: Unexpected `pick`, expected `word name`.
expected: word name
actual: pick
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

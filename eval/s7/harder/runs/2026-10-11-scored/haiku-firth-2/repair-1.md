Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## sokoban
Play moves in a warehouse puzzle and report what happened. The floor is a grid of width columns and height rows; cell (row r, column c) is number r times width plus c, and cells[i] is 0 for floor, 1 for wall and 2 for a goal (a goal is also floor). The worker stands on cell player, and boxes lists the cells holding boxes: box k starts on boxes[k]. Each move is 0 up (to the cell width lower in number), 1 right (one higher), 2 down (width higher), 3 left (one lower) or 4 undo. Read the moves in order. Before reading each move, the first one included, if every box is on a goal, stop: the puzzle is solved and the moves not yet read are not used. A move in a direction looks at the next cell t that way from the worker. If t is a wall, the move is blocked and nothing changes. If t holds a box, look at the cell u beyond it in the same direction: if u is a wall or holds a box, the move is blocked; otherwise the box moves to u and the worker to t, which is a push. Otherwise the worker moves to t, which is a step. A push or a step is recorded in the history, the latest last; a blocked move is not. A pushed box is dead if, after the push, it is not on a goal, has a wall above or below it, and also has a wall to its left or right. An undo takes back the latest move in the history and removes it from the history: the worker moves back the way it came, and if that move was a push, its box moves back too. An undo with an empty history does nothing. Return the worker's final cell, the final cell of each box (in the order of boxes), the number of moves read, the number of moves left in the history, the number of pushes made (an undone push still counts), the number of blocked moves, the number of undos that took a move back, the number of pushes that left a box dead (again counting undone ones), and whether every box is on a goal at the end. width and height are 3 to 12; cells has width times height values, each 0 to 2, and every cell in the first or last row or column is a wall; player and every value of boxes are cells that are not walls, boxes has 1 to 6 values, and no two of player and the boxes are the same cell; moves has at most 200 values, each 0 to 4.
Inputs on the stack, bottom to top: width: Int, height: Int, cells: Seq Int, player: Int, boxes: Seq Int, moves: Seq Int.
Outputs left on the stack, bottom to top: player: Int, boxes: Seq Int, read: Int, history: Int, pushes: Int, blocked: Int, undos: Int, dead: Int, solved: Bool.
Example: stack [6, 5, { 1 1 1 1 1 1 1 0 0 0 0 1 1 0 0 0 0 1 1 0 0 0 2 1 1 1 1 1 1 1 }, 9, { 15 }, { 2 1 2 3 3 4 4 0 3 3 4 1 1 }] becomes [16, { 21 }, 13, 6, 3, 1, 3, 1, false].

Your answer:
```
\ Sokoban. st: 0 player, 1 read, 2 history count, 3 pushes, 4 blocked, 5 undos, 6 dead.
\ hp / hb: history of worker's previous cell and pushed box index (-1 for a step).

: sk-delta
  (forall ρ; ρ w:Int^many d:Int^many -- ρ r:Int^many)
  locals { w d } {
    d 2 prim mod
    locals { odd } {
      1 odd prim - d 1 prim - prim *
      odd 1 d 2 prim div 2 prim * prim - prim *
      swap w prim * prim +
    }
  };

: sk-wall
  (forall ρ; ρ cells:Seq Int^many i:Int^many -- ρ b:Bool^many)
  prim seq-int.at 1 prim =;

: sk-goal
  (forall ρ; ρ cells:Seq Int^many i:Int^many -- ρ b:Bool^many)
  prim seq-int.at 2 prim =;

: sk-find
  (forall ρ; ρ boxes:Seq Int^many p:Int^many k:Int^many -- ρ r:Int^many)
  locals { boxes p k } {
    k boxes prim seq-int.len prim <
    [ boxes k prim seq-int.at p prim =
      [ k ] [ boxes p k 1 prim + sk-find ] if ]
    [ -1 ] if
  };

: sk-box-of
  (forall ρ; ρ boxes:Seq Int^many p:Int^many -- ρ r:Int^many)
  0 sk-find;

: sk-put
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { s i x } {
    i s prim seq-int.len prim <
    [ s i x prim seq-int.set ] [ s x prim seq-int.push ] if
  };

: sk-bump
  (forall ρ; ρ st:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { st i } { st i st i prim seq-int.at 1 prim + prim seq-int.set };

: sk-dead
  (forall ρ; ρ w:Int^many cells:Seq Int^many p:Int^many -- ρ b:Bool^many)
  locals { w cells p } {
    cells p sk-goal prim not
    cells p w prim - sk-wall
    cells p w prim + sk-wall prim or prim and
    cells p 1 prim - sk-wall
    cells p 1 prim + sk-wall prim or prim and
  };

: sk-all-from
  (forall ρ; ρ cells:Seq Int^many boxes:Seq Int^many k:Int^many -- ρ b:Bool^many)
  locals { cells boxes k } {
    k boxes prim seq-int.len prim <
    [ cells boxes k prim seq-int.at sk-goal
      [ cells boxes k 1 prim + sk-all-from ] [ false ] if ]
    [ true ] if
  };

: sk-all-goal
  (forall ρ; ρ cells:Seq Int^many boxes:Seq Int^many -- ρ b:Bool^many)
  0 sk-all-from;

: sk-done
  (forall ρ; ρ cells:Seq Int^many moves:Seq Int^many boxes:Seq Int^many st:Seq Int^many -- ρ b:Bool^many)
  locals { cells moves boxes st } {
    st 1 prim seq-int.at moves prim seq-int.len prim =
    cells boxes sk-all-goal prim or
  };

: sk-record
  (forall ρ; ρ hp:Seq Int^many hb:Seq Int^many st:Seq Int^many prev:Int^many k:Int^many t:Int^many -- ρ hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { hp hb st prev k t } {
    st 2 prim seq-int.at
    locals { h } {
      hp h prev sk-put
      hb h k sk-put
      st 0 t prim seq-int.set
      2 h 1 prim + prim seq-int.set
    }
  };

: sk-undo-take
  (forall ρ; ρ boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many h:Int^many -- ρ boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { boxes hp hb st h } {
    h 1 prim -
    locals { h1 } {
      st 0 prim seq-int.at
      locals { p } {
        hb h1 prim seq-int.at
        locals { k } {
          hp h1 prim seq-int.at
          locals { prev } {
            k 0 prim >=
            [ boxes k p prim seq-int.set ] [ boxes ] if
            st 0 prev prim seq-int.set 2 h1 prim seq-int.set
            locals { st1 } {
              st1 5 st1 5 prim seq-int.at 1 prim + prim seq-int.set
            }
            locals { bx st2 } { bx hp hb st2 }
          }
        }
      }
    }
  };

: sk-undo
  (forall ρ; ρ w:Int^many cells:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many -- ρ boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { w cells boxes hp hb st } {
    st 2 prim seq-int.at
    locals { h } {
      h 0 prim >
      [ boxes hp hb st h sk-undo-take ] [ boxes hp hb st ] if
    }
  };

: sk-move
  (forall ρ; ρ w:Int^many cells:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many d:Int^many -- ρ boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { w cells boxes hp hb st d } {
    w d sk-delta
    locals { delta } {
      st 0 prim seq-int.at delta prim +
      locals { t } {
        cells t sk-wall
        [ boxes hp hb st 4 sk-bump ]
        [
          boxes t sk-box-of
          locals { k } {
            k -1 prim =
            [ boxes hp hb st st 0 prim seq-int.at -1 t sk-record ]
            [
              t delta prim +
              locals { u } {
                cells u sk-wall
                boxes u sk-box-of -1 prim =
                prim or
                [ boxes hp hb st 4 sk-bump ]
                [
                  boxes k u prim seq-int.set
                  locals { boxes2 } {
                    boxes2 hp hb st st 0 prim seq-int.at k t sk-record
                    locals { bx hp2 hb2 st2 } {
                      bx hp2 hb2 st2 3 sk-bump
                      locals { st3 } {
                        bx hp2 hb2 w cells u sk-dead
                        [ st3 6 sk-bump ] [ st3 ] if
                      }
                    }
                  }
                ] if
              }
            ] if
          }
        ] if
      }
    }
  };

: sk-apply
  (forall ρ; ρ w:Int^many cells:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many d:Int^many -- ρ boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { w cells boxes hp hb st d } {
    st 1 st 1 prim seq-int.at 1 prim + prim seq-int.set
    locals { st1 } {
      d 4 prim =
      [ w cells boxes hp hb st1 sk-undo ]
      [ w cells boxes hp hb st1 d sk-move ] if
    }
  };

: sk-step
  (forall ρ; ρ w:Int^many cells:Seq Int^many moves:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many -- ρ w:Int^many cells:Seq Int^many moves:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { w cells moves boxes hp hb st } {
    w cells boxes hp hb st moves st 1 prim seq-int.at prim seq-int.at sk-apply
    locals { boxes2 hp2 hb2 st2 } {
      w cells moves boxes2 hp2 hb2 st2
    }
  };

: sk-loop
  (forall ρ; ρ w:Int^many cells:Seq Int^many moves:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many -- ρ w:Int^many cells:Seq Int^many moves:Seq Int^many boxes:Seq Int^many hp:Seq Int^many hb:Seq Int^many st:Seq Int^many)
  locals { w cells moves boxes hp hb st } {
    cells moves boxes st sk-done
    [ w cells moves boxes hp hb st ]
    [ w cells moves boxes hp hb st sk-step sk-loop ] if
  };

: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ player:Int^many boxes:Seq Int^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { width height cells player boxes moves } {
    width cells moves boxes
    prim seq-int.empty prim seq-int.empty
    { 0 0 0 0 0 0 0 } 0 player prim seq-int.set
    sk-loop
    locals { w2 cells2 moves2 boxes2 hp2 hb2 st2 } {
      st2 0 prim seq-int.at boxes2
      st2 1 prim seq-int.at st2 2 prim seq-int.at st2 3 prim seq-int.at
      st2 4 prim seq-int.at st2 5 prim seq-int.at st2 6 prim seq-int.at
      cells2 boxes2 sk-all-goal
    }
  };

```
On the example, the run failed:
code: firth.type.branch-mismatch
word: sk-move
at: line 156, column 19
message: The two branches of the `if` in `sk-move` whose true branch is `[ boxes hp hb st 4 sk-bump ]` leave different numbers of values. The true branch leaves 4 values, bottom to top: `boxes`, `hp`, `hb` and the result of `sk-bump`; the false branch leaves 7 values, bottom to top: `bx`, `hp2`, `hb2`, `bx`, `hp2`, `hb2` and the result of an `if`.
hint: The false branch leaves 3 values more than the true branch: `bx`, `hp2` and `hb2` are left below `bx`, `hp2`, `hb2` and the result of an `if`. If nothing is meant to use them, the mistake is where they are pushed: pass them to the operation that should take them, or remove them. If the true branch should leave them too, change that branch instead. Both branches run on the same stack and must leave the same values.

## checkers
Play draughts on an 8 by 8 board, both sides moving by a fixed rule, and report the result. Only the 32 dark squares are used, numbered 0 to 31: square i is in row r = i divided by 4, rounded down (row 0 at the top), and in column 2 times (i mod 4), plus 1 when r is even. board[i] is 0 for empty, 1 for a white man, 2 for a white king, 3 for a black man and 4 for a black king. White men move up (towards row 0) and black men down; kings move both ways. A step moves a piece to an empty square diagonally next to it, in a direction it may move. A jump moves a piece over a diagonally next square holding a piece of the other side, in a direction it may move, to the empty square just beyond; the piece jumped over is taken off the board at once, and the square the capturing piece started from counts as empty during the capture, so it may land there. A capture is a sequence of jumps by one piece: after each jump, if that piece can jump again from where it landed, it must, and a capture is complete only when it cannot, except that a man that lands on the far row (row 0 for white, row 7 for black) is crowned king and its capture ends there. A man that steps onto its far row is crowned too. The side to move must capture if any of its pieces can; then it plays the complete capture that takes the most pieces, choosing among equals the one whose piece starts on the lowest-numbered square, then the one whose list of landing squares, read in order, is lower at the first place the lists differ, whatever its last landing. If it cannot capture it makes the step whose piece starts on the lowest-numbered square, and among those the step to the lowest-numbered square. White moves first if turn is 0 and black if turn is 1, then the sides alternate. Before each move, if the side to move has no capture or step, it has lost and play stops; otherwise, if plies moves have been played, play stops; otherwise it moves. So a side with no move when the limit is reached has still lost. Return the final board, the number of moves played, the number of pieces white took, the number black took, the number of men crowned (by a step or at the end of a capture, on either side), and the result: 1 if white won, 2 if black won, 0 if play stopped at the move limit. board has 32 values, each 0 to 4, with at most 12 pieces of each side, no white man on row 0 and no black man on row 7; turn is 0 or 1; plies is 1 to 40.
Inputs on the stack, bottom to top: board: Seq Int, turn: Int, plies: Int.
Outputs left on the stack, bottom to top: board: Seq Int, played: Int, white_took: Int, black_took: Int, crowned: Int, result: Int.
Example: stack [{ 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 3 3 0 0 0 0 0 0 3 0 0 0 1 0 0 0 }, 0, 2] becomes [{ 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 3 0 0 0 0 0 0 0 0 0 0 0 }, 2, 3, 0, 0, 0].

Your answer:
```
\ Draughts. Square i: row r = i div 4, column c = 2*(i mod 4) + (1 if r even else 0).
\ Board is a Seq Int of 32 values; moves are generated by DFS in ascending order.

: ck-idx
  (forall ρ; ρ r:Int^many c:Int^many -- ρ i:Int^many)
  locals { r c } {
    r 0 prim >= r 7 prim <= prim and
    c 0 prim >= c 7 prim <= prim and prim and
    [ r 4 prim * c 2 prim div prim + ] [ -1 ] if
  };

: ck-owner
  (forall ρ; ρ v:Int^many -- ρ o:Int^many)
  locals { v } { v 0 prim = [ 0 ] [ v 2 prim mod 1 prim + ] if };

: ck-is-king
  (forall ρ; ρ v:Int^many -- ρ b:Bool^many)
  locals { v } { v 2 prim > };

: ck-dirs-ok
  (forall ρ; ρ v:Int^many dr:Int^many -- ρ b:Bool^many)
  locals { v dr } {
    v ck-is-king
    [ true ] [ v 0 prim <= dr 1 prim = prim not prim or ] if
  };

: ck-mine
  (forall ρ; ρ v:Int^many side:Int^many -- ρ b:Bool^many)
  locals { v side } { v 0 prim = [ false ] [ v ck-owner side prim = ] if };

\ Capture search: returns best (count, landing list) via explicit DFS on a fresh board.
: ck-cap-count
  (forall ρ; ρ board:Seq Int^many from:Int^many side:Int^many -- ρ n:Int^many)
  locals { board from side } {
    0
  };

: ck-main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board:Seq Int^many played:Int^many w:Int^many b:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    board 0 0 0 0 0
  };

: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board:Seq Int^many played:Int^many white_took:Int^many black_took:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    board turn plies ck-main
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 45, column 109
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## regex
Match strings against a regular expression given as tokens. Token 0 to 25 is that letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one or more sequences separated by '|'; a sequence is zero or more items, one after another; an item is an atom followed by zero or more postfix operators; an atom is a letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one after another (an empty sequence matches the empty string), and an alternation matches if any of its sequences does. A pattern that does not fit the grammar, such as one with an operator where an atom should start, a '(' never closed or a ')' with no '(' open, is invalid. The strings are given together: string j has lens[j] letters, and chars holds every string's letters, string 0 first. For each string, return whether the whole string matches the pattern, and the length of the longest start of it (from no letters up to all of them) that matches, or -1 if none does. Also return how many strings match whole and whether the pattern is valid; for an invalid pattern every string gives false and -1, the count is 0 and validity is false. pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, adding up to the length of chars; every value of chars is 0 to 25.
Inputs on the stack, bottom to top: pattern: Seq Int, lens: Seq Int, chars: Seq Int.
Outputs left on the stack, bottom to top: full: Seq Bool, longest: Seq Int, count: Int, valid: Bool.
Example: stack [{ 0 27 1 30 31 2 3 32 28 }, { 3 2 4 0 3 1 3 }, { 0 0 1 2 3 2 3 2 3 2 3 2 1 0 1 1 }] becomes [{ true true true false false true false }, { 3 2 4 -1 2 1 2 }, 4, true].

Your answer:
```
\ Regex by set simulation. A set of string positions is a bitmask over 0..n.
\ pat: tokens; str: letters of one string; n: its length.

: rx-tok
  (forall ρ; ρ pat:Seq Int^many pos:Int^many -- ρ t:Int^many)
  locals { pat pos } {
    pos pat prim seq-int.len prim <
    [ pat pos prim seq-int.at ] [ -1 ] if
  };

: rx-bit
  (forall ρ; ρ x:Int^many p:Int^many -- ρ b:Bool^many)
  locals { x p } { x p 2 prim swap prim ** };

: rx-lit
  (forall ρ; ρ str:Seq Int^many n:Int^many c:Int^many x:Int^many p:Int^many acc:Int^many -- ρ r:Int^many)
  locals { str n c x p acc } {
    p n prim <
    [
      x p 1 prim = prim not prim or
      [ acc ] [ acc ] if
    ]
    [ acc ] if
  };

: rx-star-go
  (forall ρ; ρ x:Int^many z:Int^many -- ρ r:Int^many)
  locals { x z } { z };

: regex-main
  (forall ρ; ρ pat:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pat lens chars } {
    prim seq-bool.empty prim seq-int.empty 0 true
  };

: main
  (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pattern lens chars } {
    pattern lens chars regex-main
  };

```
On the example, the run failed:
code: firth.syntax.invalid-name
at: line 13, column 31
message: Unexpected `swap`, expected `primitive name`.
expected: primitive name
actual: swap
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

## swiss
Run a Swiss-system chess tournament and report the standings. Player p has rating ratings[p]. Scores count half points: a win is 2, a draw 1, a loss 0. Play rounds rounds. At the start of each round, rank the players by score, highest first, then by rating, highest first, then by player number, lowest first. If the number of players is odd, the lowest-ranked player who has not yet had a bye gets one: they score 2 and do not play this round. This is done before pairing, and that player is left out of it. Then pair the others: repeatedly take the highest-ranked player not yet paired this round, and pair them with the highest-ranked unpaired player they have not played before in this tournament; if they have played every unpaired player, pair them with the highest-ranked unpaired player anyway, which is a rematch. In each pair, white goes to the player who has had white fewer times so far; if equal, to the player whose last game was played as black, if exactly one of them (a player who has played no game has no last game); otherwise to the player taken first. A bye is not a game and does not count as a last game. The games of a round are played in the order they were paired, and their results are read from results in that order, round after round: 0 means white won, 1 a draw, 2 black won. Return each player's final score; each player's Buchholz score, the sum of the final scores of the opponents of every game they played (an opponent met twice counts twice; a bye adds nothing); the player numbers ranked by final score, then Buchholz score, then rating, each highest first, then player number, lowest first; the number of times each player had white; and the number of rematches. ratings has 2 to 12 values, each 1,000 to 3,000; rounds is 1 to 7 and below the number of players; results has rounds times (the number of players divided by 2, rounded down) values, each 0 to 2.
Inputs on the stack, bottom to top: ratings: Seq Int, rounds: Int, results: Seq Int.
Outputs left on the stack, bottom to top: scores: Seq Int, buchholz: Seq Int, ranking: Seq Int, whites: Seq Int, rematches: Int.
Example: stack [{ 1500 1600 1400 1700 }, 2, { 0 1 2 0 }] becomes [{ 3 0 3 2 }, { 5 5 3 3 }, { 0 2 3 1 }, { 1 0 1 2 }, 0].

Your answer:
```
\ Swiss tournament. Scores are half points. Helpers keep per-player arrays in Seq Int.

: sw-get
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Int^many)
  prim seq-int.at;

: sw-set
  (forall ρ; ρ s:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: sw-main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  locals { ratings rounds results } {
    ratings prim seq-int.len
    locals { n } {
      n 0 prim seq-int.empty
      rounds
      results
      n
    }
  };

: main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  locals { ratings rounds results } {
    ratings rounds results sw-main
  };

```
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: sw-main
at: line 12, column 3
message: `sw-main` declares that it leaves ρ Seq Int Seq Int Seq Int Seq Int Int but its body leaves ρ Int Int Seq Int Int Seq Int Int.
expected: ρ Seq Int Seq Int Seq Int Seq Int Int
actual: ρ Int Int Seq Int Int Seq Int Int
hint: The body leaves 1 value more than declared, and the declared values are not among them in order, so some types differ too. Compare the declared output with the body's result value by value. Here ρ stands for the caller's values that this word must leave untouched.

## warehouse
Run a warehouse for days days, numbered from 0, and report the totals. There are products 0 to P - 1, where P is the length of price; product p sells for price[p] a unit. Stock is held in lots, each with a quantity, an expiry day and the order in which it arrived. A pending order for a product waits in that product's backorder queue with the quantity still owed and the day it was placed. Taking q units of a product means taking them from its lots with the earliest expiry first, and among equal expiries the lot that arrived first; a lot that reaches 0 is gone. When a lot of a product arrives, it is added, and then while that product has a backorder and units in stock, the oldest backorder is filled as far as the stock allows: the units taken are shipped, and the backorder is gone once nothing is owed. On each day d, in this order: first, every lot whose expiry day is before d is thrown away. Second, for each product in order, a supply ordered earlier that is due on day d arrives as a lot of rq[p] units expiring on day d + shelf[p]. Third, the events of day d happen in the order listed: event e is on day ev_day[e], for product ev_prod[e], with quantity ev_qty[e]. Kind 1 is a delivery: a lot of that quantity arrives, expiring on day ev_expiry[e]. Kind 2 is a customer order: if the product has any backorder, the whole order joins the end of its backorder queue; otherwise as many units as are in stock, up to the quantity, are taken and shipped, and any units not shipped join the end of the queue as a backorder placed on day d. Fourth, every backorder placed on day d - 7 or earlier is cancelled, and the units it still owes (even if it was partly filled) count as cancelled. Fifth, for each product in order, if it has no supply on the way and its units in stock are at most rp[p], a supply is ordered, due on day d + lead[p]; a supply stops being on the way when it arrives in the second step, so another can be ordered that same day. Every unit shipped earns its product's price. Return the units in stock of each product at the end, the total earned, the units shipped, the units thrown away, the units cancelled, the number of supplies ordered, and the units still owed on backorder at the end. price, rp, rq, lead and shelf have the same length P, 1 to 5; each price is 1 to 1,000, each rp 0 to 100, each rq 1 to 200, each lead 1 to 10 and each shelf 1 to 30; days is 1 to 60. The five event sequences have the same length, at most 80; ev_day is 0 to days - 1 and never decreases from one event to the next; ev_kind is 1 or 2; ev_prod is 0 to P - 1; ev_qty is 1 to 200; ev_expiry is ev_day to ev_day + 60 for a delivery and 0 for an order.
Inputs on the stack, bottom to top: days: Int, price: Seq Int, rp: Seq Int, rq: Seq Int, lead: Seq Int, shelf: Seq Int, ev_day: Seq Int, ev_kind: Seq Int, ev_prod: Seq Int, ev_qty: Seq Int, ev_expiry: Seq Int.
Outputs left on the stack, bottom to top: stock: Seq Int, earned: Int, shipped: Int, discarded: Int, cancelled: Int, supplies: Int, owed: Int.
Example: stack [12, { 3 }, { 0 }, { 1 }, { 10 }, { 1 }, { 0 0 3 4 }, { 1 2 2 2 }, { 0 0 0 0 }, { 5 2 4 1 }, { 1 0 0 0 }] becomes [{ 0 }, 6, 2, 3, 5, 1, 0].

Your answer:
```
\ Warehouse. Lots and backorders are kept as parallel Seq Int arrays.
\ This is a partial model: the day loop and event handling are not written out.

: wh-total
  (forall ρ; ρ xs:Seq Int^many -- ρ r:Int^many)
  0 prim seq-int.empty prim seq-int.len 0 prim +;

: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many ev_day:Seq Int^many ev_kind:Seq Int^many ev_prod:Seq Int^many ev_qty:Seq Int^many ev_expiry:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf ev_day ev_kind ev_prod ev_qty ev_expiry } {
    prim seq-int.empty 0 0 0 0 0 0
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 9, column 120
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
\ Two-level cache. Sets are recorded as flat Seq Int arrays, least recently used first.
\ This is a partial model: the access loop is not written out.

: cs-main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1_hits:Int^many l1_misses:Int^many l2_hits:Int^many l2_misses:Int^many mem_reads:Int^many mem_writes:Int^many dirty:Int^many l1_blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    0 0 0 0 0 0 0 prim seq-int.empty
  };

: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1_hits:Int^many l1_misses:Int^many l2_hits:Int^many l2_misses:Int^many mem_reads:Int^many mem_writes:Int^many dirty:Int^many l1_blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    s1 w1 s2 w2 addrs writes cs-main
  };

```
On the example, the run failed:
code: firth.syntax.unexpected-token
at: line 5, column 111
message: Unexpected `_`, expected `:`.
expected: :
actual: _
hint: A definition looks like `: name (forall ρ; ρ n:Int^many -- ρ r:Int^many) body;`.

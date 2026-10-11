### task: sokoban
```firth
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

### task: checkers
```firth
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

### task: regex
```firth
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

### task: swiss
```firth
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

### task: warehouse
```firth
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

### task: cache-sim
```firth
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

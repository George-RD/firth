### task: sokoban
```firth
: all-goals-loop ( cells:Seq Int boxes:Seq Int i:Int -- Bool )
  locals { cells boxes i } {
    i boxes prim seq-int.len prim >=
    [ true ]
    [ boxes i prim seq-int.at cells swap prim seq-int.at 2 prim =
      [ i 1 prim + all-goals-loop ]
      [ false ]
      if
    ]
    if
  };

: all-goals? ( cells:Seq Int boxes:Seq Int -- Bool )
  0 all-goals-loop ;

: delta ( dir:Int w:Int -- Int )
  locals { dir w } {
    dir 0 prim =
    [ 0 w prim - ]
    [ dir 1 prim =
      [ 1 ]
      [ dir 2 prim =
        [ w ]
        [ -1 ]
        if
      ]
      if
    ]
    if
  };

: find-box-loop ( boxes:Seq Int u:Int i:Int -- Int )
  locals { boxes u i } {
    boxes i prim seq-int.at u prim =
    [ i ]
    [ i 1 prim + find-box-loop ]
    if
  };

: find-box ( boxes:Seq Int u:Int -- Int )
  0 find-box-loop ;

: has-box-loop ( boxes:Seq Int t:Int i:Int -- Bool )
  locals { boxes t i } {
    i boxes prim seq-int.len prim >=
    [ false ]
    [ boxes i prim seq-int.at t prim =
      [ true ]
      [ i 1 prim + has-box-loop ]
      if
    ]
    if
  };

: has-box? ( boxes:Seq Int t:Int -- Bool )
  0 has-box-loop ;

: set-box-at-cell ( boxes:Seq Int cell:Int new_cell:Int -- new_boxes:Seq Int )
  locals { boxes cell new_cell } {
    boxes cell find-box  \ i
    boxes swap new_cell prim seq-int.set
  };

: undo-player-boxes ( player:Int boxes:Seq Int hist:Seq Int hist_len:Int w:Int -- new_player:Int new_boxes:Seq Int )
  locals { player boxes hist hist_len w } {
    hist_len 0 prim >
    [ \ non-empty
      hist hist_len 1 prim - prim seq-int.at  \ last
      dup 4 prim mod  \ last dir
      swap 4 prim >=  \ dir is_push
      locals { dir is_push } {
        dir 2 prim + 4 prim mod  \ opp_dir
        opp_dir w delta player swap prim +  \ new_player
        locals { new_player } {
          is_push
          [ \ push
            dir w delta player swap prim +  \ u
            dir w delta new_player swap prim +  \ t
            boxes u find-box  \ i
            boxes i t prim seq-int.set  \ new_boxes
          ]
          [ \ step
            boxes
          ]
          if
          \ stack: new_boxes
          new_player  \ push new_player
          swap        \ swap to get new_player, new_boxes
        }
      }
    ]
    [ \ empty
      player boxes
    ]
    if
  };

: is-dead? ( cells:Seq Int u:Int w:Int -- Bool )
  locals { cells u w } {
    cells u prim seq-int.at 2 prim = prim not
    cells u w prim - prim seq-int.at 1 prim =
    cells u w prim + prim seq-int.at 1 prim =
    prim or
    cells u 1 prim - prim seq-int.at 1 prim =
    cells u 1 prim + prim seq-int.at 1 prim =
    prim or
    prim and
    prim and
  };

: hist-push ( hist:Seq Int hist_len:Int value:Int -- new_hist:Seq Int )
  locals { hist hist_len value } {
    hist_len hist prim seq-int.len prim <
    [ hist hist_len value prim seq-int.set ]
    [ hist value prim seq-int.push ]
    if
  };

: solve
  (forall ρ; ρ w:Int h:Int cells:Seq Int player:Int boxes:Seq Int moves:Seq Int read:Int hist:Seq Int hist_len:Int pushes:Int blocked:Int undos:Int dead:Int -- ρ w:Int h:Int cells:Seq Int player:Int boxes:Seq Int moves:Seq Int read:Int hist:Seq Int hist_len:Int pushes:Int blocked:Int undos:Int dead:Int)
  locals { w h cells player boxes moves read hist hist_len pushes blocked undos dead } {
    cells boxes all-goals?
    read moves prim seq-int.len prim >=
    prim or
    [ \ terminate
      w h cells player boxes moves read hist hist_len pushes blocked undos dead
    ]
    [ \ process move
      moves read prim seq-int.at  \ d
      read 1 prim +  \ new_read
      locals { d new_read } {
        d 4 prim =
        [ \ undo
          w h cells
          player boxes hist hist_len w undo-player-boxes
          moves
          new_read
          hist
          hist_len 0 prim >
          [ hist_len 1 prim - ]
          [ hist_len ]
          if
          pushes
          blocked
          hist_len 0 prim >
          [ undos 1 prim + ]
          [ undos ]
          if
          dead
          solve
        ]
        [ \ move
          d w delta player swap prim +  \ t
          cells t prim seq-int.at 1 prim =
          [ \ blocked wall
            w h cells
            player
            boxes
            moves
            new_read
            hist
            hist_len
            pushes
            blocked 1 prim +
            undos
            dead
            solve
          ]
          [ \ not wall
            boxes t has-box?
            [ \ box at t
              d w delta t swap prim +  \ u
              cells u prim seq-int.at 1 prim =
              boxes u has-box?
              prim or
              [ \ blocked u
                w h cells
                player
                boxes
                moves
                new_read
                hist
                hist_len
                pushes
                blocked 1 prim +
                undos
                dead
                solve
              ]
              [ \ push
                w h cells
                t
                boxes t u set-box-at-cell
                moves
                new_read
                hist hist_len d 4 prim + hist-push
                hist_len 1 prim +
                pushes 1 prim +
                blocked
                undos
                cells u w is-dead?
                [ dead 1 prim + ]
                [ dead ]
                if
                solve
              ]
              if
            ]
            [ \ step
              w h cells
              t
              boxes
              moves
              new_read
              hist hist_len d hist-push
              hist_len 1 prim +
              pushes
              blocked
              undos
              dead
              solve
            ]
            if
          ]
          if
        ]
        if
      }
    ]
    if
  };

: main
  ( width:Int height:Int cells:Seq Int player:Int boxes:Seq Int moves:Seq Int -- player:Int boxes:Seq Int read:Int history:Int pushes:Int blocked:Int undos:Int dead:Int solved:Bool )
  locals { width height cells player boxes moves } {
    width height cells player boxes moves
    0
    prim seq-int.empty
    0
    0
    0
    0
    0
    solve
    locals { w h c p b m r hist hist_len pus blk und de } {
      p b r hist_len pus blk und de
      c b all-goals?
    }
  };
```
### task: sokoban
```firth
: fill0
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc 0 prim seq-int.push n 1 prim - fill0 ] if };

: bump
  (forall ρ; ρ regs:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { regs k } { regs k regs k prim seq-int.at 1 prim + prim seq-int.set };

: delta
  (forall ρ; ρ w:Int^many d:Int^many -- ρ r:Int^many)
  locals { w d } {
    d 0 prim =
    [ 0 w prim - ]
    [ d 1 prim =
      [ 1 ]
      [ d 2 prim = [ w ] [ -1 ] if ] if ] if };

: find-box
  (forall ρ; ρ boxes:Seq Int^many cell:Int^many k:Int^many -- ρ r:Int^many)
  locals { boxes cell k } {
    k boxes prim seq-int.len prim >=
    [ -1 ]
    [ boxes k prim seq-int.at cell prim =
      [ k ]
      [ boxes cell k 1 prim + find-box ] if ] if };

: all-on-goal
  (forall ρ; ρ cells:Seq Int^many boxes:Seq Int^many k:Int^many -- ρ r:Bool^many)
  locals { cells boxes k } {
    k boxes prim seq-int.len prim >=
    [ true ]
    [ cells boxes k prim seq-int.at prim seq-int.at 2 prim =
      [ cells boxes k 1 prim + all-on-goal ]
      [ false ] if ] if };

: is-dead
  (forall ρ; ρ cells:Seq Int^many u:Int^many w:Int^many -- ρ r:Bool^many)
  locals { cells u w } {
    cells u prim seq-int.at 2 prim = prim not
    cells u w prim - prim seq-int.at 1 prim =
    cells u w prim + prim seq-int.at 1 prim = prim or
    prim and
    cells u 1 prim - prim seq-int.at 1 prim =
    cells u 1 prim + prim seq-int.at 1 prim = prim or
    prim and };

: record
  (forall ρ; ρ hist:Seq Int^many regs:Seq Int^many code:Int^many -- ρ hist2:Seq Int^many regs2:Seq Int^many)
  locals { hist regs code } {
    hist regs 1 prim seq-int.at code prim seq-int.set
    regs 1 bump };

: do-push
  (forall ρ; ρ w:Int^many cells:Seq Int^many boxes:Seq Int^many hist:Seq Int^many regs:Seq Int^many d:Int^many bi:Int^many t:Int^many u:Int^many -- ρ boxes2:Seq Int^many hist2:Seq Int^many regs2:Seq Int^many)
  locals { w cells boxes hist regs d bi t u } {
    boxes bi u prim seq-int.set
    hist regs d 2 prim * 1 prim + record
    0 t prim seq-int.set
    2 bump
    cells u w is-dead
    [ 5 bump ] [ ] if };

: do-move
  (forall ρ; ρ w:Int^many cells:Seq Int^many boxes:Seq Int^many hist:Seq Int^many regs:Seq Int^many d:Int^many -- ρ boxes2:Seq Int^many hist2:Seq Int^many regs2:Seq Int^many)
  locals { w cells boxes hist regs d } {
    w d delta
    locals { dl } {
      regs 0 prim seq-int.at dl prim +
      locals { t } {
        cells t prim seq-int.at 1 prim =
        [ boxes hist regs 3 bump ]
        [ boxes t 0 find-box
          locals { bi } {
            bi 0 prim >=
            [ t dl prim +
              locals { u } {
                cells u prim seq-int.at 1 prim =
                boxes u 0 find-box 0 prim >= prim or
                [ boxes hist regs 3 bump ]
                [ w cells boxes hist regs d bi t u do-push ] if } ]
            [ boxes hist regs d 2 prim * record 0 t prim seq-int.set ] if } ] if } } };

: do-undo
  (forall ρ; ρ w:Int^many boxes:Seq Int^many hist:Seq Int^many regs:Seq Int^many -- ρ boxes2:Seq Int^many hist2:Seq Int^many regs2:Seq Int^many)
  locals { w boxes hist regs } {
    regs 1 prim seq-int.at 0 prim =
    [ boxes hist regs ]
    [ regs 1 prim seq-int.at 1 prim -
      locals { hl } {
        hist hl prim seq-int.at
        locals { e } {
          w e 2 prim div delta
          locals { dl } {
            regs 0 prim seq-int.at
            locals { p } {
              e 2 prim mod 1 prim =
              [ boxes boxes p dl prim + 0 find-box p prim seq-int.set ]
              [ boxes ] if
              hist
              regs 0 p dl prim - prim seq-int.set 1 hl prim seq-int.set 4 bump } } } } ] if };

: play
  (forall ρ; ρ w:Int^many cells:Seq Int^many moves:Seq Int^many boxes:Seq Int^many hist:Seq Int^many regs:Seq Int^many -- ρ boxes2:Seq Int^many hist2:Seq Int^many regs2:Seq Int^many)
  locals { w cells moves boxes hist regs } {
    regs 6 prim seq-int.at
    locals { i } {
      i moves prim seq-int.len prim >=
      [ boxes hist regs ]
      [ cells boxes 0 all-on-goal
        [ boxes hist regs ]
        [ moves i prim seq-int.at
          locals { m } {
            w cells moves
            m 4 prim =
            [ w boxes hist regs 6 bump do-undo ]
            [ w cells boxes hist regs 6 bump m do-move ] if
            play } ] if ] if } };

: main
  (forall ρ; ρ width:Int^many height:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ player2:Int^many boxes2:Seq Int^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { width height cells player boxes moves } {
    width cells moves boxes
    prim seq-int.empty moves prim seq-int.len fill0
    { 0 0 0 0 0 0 0 } 0 player prim seq-int.set
    play
    locals { b2 h2 r2 } {
      r2 0 prim seq-int.at
      b2
      r2 6 prim seq-int.at
      r2 1 prim seq-int.at
      r2 2 prim seq-int.at
      r2 3 prim seq-int.at
      r2 4 prim seq-int.at
      r2 5 prim seq-int.at
      cells b2 0 all-on-goal } };
```

### task: checkers
```firth
: z26
  (forall ρ; ρ -- ρ r:Seq Int^many)
  { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 };

: nbr
  (forall ρ; ρ i:Int^many dr:Int^many dc:Int^many -- ρ j:Int^many)
  locals { i dr dc } {
    i 4 prim div dr prim +
    i 4 prim mod 2 prim * 1 prim + i 4 prim div 2 prim mod prim - dc prim +
    locals { r2 c2 } {
      r2 0 prim < r2 7 prim > prim or
      c2 0 prim < c2 7 prim > prim or prim or
      [ -1 ]
      [ r2 4 prim * c2 2 prim div prim + ] if } };

: nbd
  (forall ρ; ρ i:Int^many d:Int^many -- ρ j:Int^many)
  locals { i d } {
    i d 2 prim div 2 prim * 1 prim - d 2 prim mod 2 prim * 1 prim - nbr };

: is-mine
  (forall ρ; ρ p:Int^many side:Int^many -- ρ r:Bool^many)
  locals { p side } { p 0 prim > p 1 prim - 2 prim div side prim = prim and };

: is-opp
  (forall ρ; ρ p:Int^many side:Int^many -- ρ r:Bool^many)
  locals { p side } { p 0 prim > p 1 prim - 2 prim div side prim = prim not prim and };

: kingflag
  (forall ρ; ρ p:Int^many -- ρ r:Int^many)
  locals { p } { 1 p 2 prim mod prim - };

: allowed
  (forall ρ; ρ king:Int^many side:Int^many d:Int^many -- ρ r:Bool^many)
  locals { king side d } { king 1 prim = d 2 prim div side prim = prim or };

: jump-target
  (forall ρ; ρ board:Seq Int^many side:Int^many king:Int^many pos:Int^many d:Int^many -- ρ l:Int^many)
  locals { board side king pos d } {
    king side d allowed
    [ pos d nbd
      locals { m } {
        m 0 prim >=
        [ board m prim seq-int.at side is-opp
          [ m d nbd
            locals { l } {
              l 0 prim >=
              [ board l prim seq-int.at 0 prim = [ l ] [ -1 ] if ]
              [ -1 ] if } ]
          [ -1 ] if ]
        [ -1 ] if } ]
    [ -1 ] if };

: can-jump
  (forall ρ; ρ board:Seq Int^many side:Int^many king:Int^many pos:Int^many d:Int^many -- ρ r:Bool^many)
  locals { board side king pos d } {
    d 4 prim >=
    [ false ]
    [ board side king pos d jump-target 0 prim >=
      [ true ]
      [ board side king pos d 1 prim + can-jump ] if ] if };

: path-add
  (forall ρ; ρ cur:Seq Int^many l:Int^many m:Int^many -- ρ r:Seq Int^many)
  locals { cur l m } {
    cur 0 prim seq-int.at
    locals { n } {
      cur 0 n 1 prim + prim seq-int.set
      2 n 2 prim * prim + l prim seq-int.set
      3 n 2 prim * prim + m prim seq-int.set } };

: lex-less
  (forall ρ; ρ a:Seq Int^many b:Seq Int^many k:Int^many -- ρ r:Bool^many)
  locals { a b k } {
    k a 0 prim seq-int.at prim >=
    [ false ]
    [ a 2 k 2 prim * prim + prim seq-int.at
      b 2 k 2 prim * prim + prim seq-int.at
      locals { x y } {
        x y prim <
        [ true ]
        [ x y prim >
          [ false ]
          [ a b k 1 prim + lex-less ] if ] if } ] if };

: better
  (forall ρ; ρ cur:Seq Int^many best:Seq Int^many -- ρ r:Bool^many)
  locals { cur best } {
    cur 0 prim seq-int.at best 0 prim seq-int.at
    locals { cn bn } {
      cn bn prim >
      [ true ]
      [ cn bn prim =
        [ cur 1 prim seq-int.at best 1 prim seq-int.at
          locals { cs bs } {
            cs bs prim <
            [ true ]
            [ cs bs prim =
              [ cur best 0 lex-less ]
              [ false ] if ] if } ]
        [ false ] if ] if } };

: consider
  (forall ρ; ρ cur:Seq Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { cur best } { cur best better [ cur ] [ best ] if };

: explore
  (forall ρ; ρ board:Seq Int^many side:Int^many king:Int^many pos:Int^many cur:Seq Int^many best:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { board side king pos cur best d } {
    d 4 prim >=
    [ best ]
    [ board side king pos d jump-target
      locals { l } {
        l 0 prim <
        [ board side king pos cur best d 1 prim + explore ]
        [ pos d nbd
          locals { m } {
            board m 0 prim seq-int.set
            locals { b2 } {
              cur l m path-add
              locals { c2 } {
                king 0 prim = l 4 prim div side 7 prim * prim = prim and
                b2 side king l 0 can-jump prim not
                prim or
                [ c2 best consider ]
                [ b2 side king l c2 best 0 explore ] if
                locals { best2 } {
                  board side king pos cur best2 d 1 prim + explore } } } } ] if } ] if };

: capture-search
  (forall ρ; ρ board:Seq Int^many side:Int^many s:Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { board side s best } {
    s 32 prim >=
    [ best ]
    [ board s prim seq-int.at
      locals { p } {
        p side is-mine
        [ board s 0 prim seq-int.set side p kingflag s z26 1 s prim seq-int.set best 0 explore
          locals { best2 } { board side s 1 prim + best2 capture-search } ]
        [ board side s 1 prim + best capture-search ] if } ] if };

: remove-caps
  (forall ρ; ρ board:Seq Int^many best:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { board best k } {
    k best 0 prim seq-int.at prim >=
    [ board ]
    [ board best 3 k 2 prim * prim + prim seq-int.at 0 prim seq-int.set best k 1 prim + remove-caps ] if };

: addreg
  (forall ρ; ρ regs:Seq Int^many k:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { regs k v } { regs k regs k prim seq-int.at v prim + prim seq-int.set };

: apply-capture
  (forall ρ; ρ board:Seq Int^many side:Int^many best:Seq Int^many regs:Seq Int^many -- ρ board2:Seq Int^many regs2:Seq Int^many)
  locals { board side best regs } {
    best 1 prim seq-int.at
    locals { s } {
      board s prim seq-int.at
      locals { p } {
        best 0 prim seq-int.at
        locals { n } {
          best 2 n 1 prim - 2 prim * prim + prim seq-int.at
          locals { l } {
            p kingflag 0 prim = l 4 prim div side 7 prim * prim = prim and
            [ 1 ] [ 0 ] if
            locals { cr } {
              board s 0 prim seq-int.set best 0 remove-caps
              l p cr prim + prim seq-int.set
              regs 0 1 addreg 1 side prim + n addreg 3 cr addreg } } } } } };

: step-target
  (forall ρ; ρ board:Seq Int^many side:Int^many king:Int^many s:Int^many d:Int^many -- ρ t:Int^many)
  locals { board side king s d } {
    king side d allowed
    [ s d nbd
      locals { t } {
        t 0 prim >=
        [ board t prim seq-int.at 0 prim = [ t ] [ -1 ] if ]
        [ -1 ] if } ]
    [ -1 ] if };

: min-step
  (forall ρ; ρ board:Seq Int^many side:Int^many king:Int^many s:Int^many d:Int^many best:Int^many -- ρ t:Int^many)
  locals { board side king s d best } {
    d 4 prim >=
    [ best ]
    [ board side king s d step-target
      locals { t } {
        t 0 prim >=
        best 0 prim < best t prim > prim or prim and
        [ board side king s d 1 prim + t min-step ]
        [ board side king s d 1 prim + best min-step ] if } ] if };

: find-step
  (forall ρ; ρ board:Seq Int^many side:Int^many s:Int^many -- ρ code:Int^many)
  locals { board side s } {
    s 32 prim >=
    [ -1 ]
    [ board s prim seq-int.at
      locals { p } {
        p side is-mine
        [ board side p kingflag s 0 -1 min-step
          locals { t } {
            t 0 prim >=
            [ s 32 prim * t prim + ]
            [ board side s 1 prim + find-step ] if } ]
        [ board side s 1 prim + find-step ] if } ] if };

: apply-step
  (forall ρ; ρ board:Seq Int^many side:Int^many code:Int^many regs:Seq Int^many -- ρ board2:Seq Int^many regs2:Seq Int^many)
  locals { board side code regs } {
    code 32 prim div
    locals { s } {
      code 32 prim mod
      locals { t } {
        board s prim seq-int.at
        locals { p } {
          p kingflag 0 prim = t 4 prim div side 7 prim * prim = prim and
          [ 1 ] [ 0 ] if
          locals { cr } {
            board s 0 prim seq-int.set t p cr prim + prim seq-int.set
            regs 0 1 addreg 3 cr addreg } } } } };

: game
  (forall ρ; ρ board:Seq Int^many side:Int^many plies:Int^many regs:Seq Int^many -- ρ board2:Seq Int^many regs2:Seq Int^many result:Int^many)
  locals { board side plies regs } {
    board side 0 z26 capture-search
    locals { best } {
      best 0 prim seq-int.at 0 prim >
      [ regs 0 prim seq-int.at plies prim >=
        [ board regs 0 ]
        [ board side best regs apply-capture
          locals { b2 r2 } { b2 1 side prim - plies r2 game } ] if ]
      [ board side 0 find-step
        locals { code } {
          code 0 prim <
          [ board regs 2 side prim - ]
          [ regs 0 prim seq-int.at plies prim >=
            [ board regs 0 ]
            [ board side code regs apply-step
              locals { b3 r3 } { b3 1 side prim - plies r3 game } ] if ] if } ] if } };

: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ board2:Seq Int^many played:Int^many white-took:Int^many black-took:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    board turn plies { 0 0 0 0 } game
    locals { b2 r2 res } {
      b2 r2 0 prim seq-int.at r2 1 prim seq-int.at r2 2 prim seq-int.at r2 3 prim seq-int.at res } };
```

### task: regex
```firth
: fill0
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc 0 prim seq-int.push n 1 prim - fill0 ] if };

: fillf
  (forall ρ; ρ acc:Seq Bool^many n:Int^many -- ρ r:Seq Bool^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc false prim seq-bool.push n 1 prim - fillf ] if };

: fillneg
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc -1 prim seq-int.push n 1 prim - fillneg ] if };

: slice
  (forall ρ; ρ acc:Seq Int^many src:Seq Int^many off:Int^many n:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { acc src off n k } {
    k n prim >=
    [ acc ]
    [ acc src off k prim + prim seq-int.at prim seq-int.push src off n k 1 prim + slice ] if };

: union
  (forall ρ; ρ a:Seq Int^many b:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { a b k } {
    k a prim seq-int.len prim >=
    [ a ]
    [ b k prim seq-int.at 1 prim =
      [ a k 1 prim seq-int.set b k 1 prim + union ]
      [ a b k 1 prim + union ] if ] if };

: same
  (forall ρ; ρ a:Seq Int^many b:Seq Int^many k:Int^many -- ρ r:Bool^many)
  locals { a b k } {
    k a prim seq-int.len prim >=
    [ true ]
    [ a k prim seq-int.at b k prim seq-int.at prim =
      [ a b k 1 prim + same ]
      [ false ] if ] if };

: lstep
  (forall ρ; ρ r:Seq Int^many s:Seq Int^many str:Seq Int^many tok:Int^many p:Int^many -- ρ r2:Seq Int^many)
  locals { r s str tok p } {
    p str prim seq-int.len prim >=
    [ r ]
    [ s p prim seq-int.at 1 prim =
      tok 26 prim = str p prim seq-int.at tok prim = prim or prim and
      [ r p 1 prim + 1 prim seq-int.set s str tok p 1 prim + lstep ]
      [ r s str tok p 1 prim + lstep ] if ] if };

: seq-end
  (forall ρ; ρ pe:Seq Int^many i:Int^many b:Int^many -- ρ e:Int^many)
  locals { pe i b } {
    i b prim >=
    [ b ]
    [ pe i prim seq-int.at
      locals { t } {
        t 30 prim =
        [ i ]
        [ t 100 prim >=
          [ pe t 99 prim - b seq-end ]
          [ pe i 1 prim + b seq-end ] if ] if } ] if };

: ops-end
  (forall ρ; ρ pe:Seq Int^many j:Int^many e:Int^many -- ρ r:Int^many)
  locals { pe j e } {
    j e prim >=
    [ j ]
    [ pe j prim seq-int.at
      locals { t } {
        t 27 prim >= t 29 prim <= prim and
        [ pe j 1 prim + e ops-end ]
        [ j ] if } ] if };

: atom-eval
  (forall ρ; ρ pe:Seq Int^many str:Seq Int^many z:Seq Int^many a:Int^many aend:Int^many s:Seq Int^many -- ρ r:Seq Int^many)
  locals { pe str z a aend s } {
    pe a prim seq-int.at
    locals { t } {
      t 100 prim >=
      [ pe str z a 1 prim + aend 1 prim - s alt ]
      [ z s str t 0 lstep ] if } };

: alt
  (forall ρ; ρ pe:Seq Int^many str:Seq Int^many z:Seq Int^many a:Int^many b:Int^many s:Seq Int^many -- ρ r:Seq Int^many)
  locals { pe str z a b s } {
    pe a b seq-end
    locals { e } {
      pe str z a e s seq-eval
      locals { r1 } {
        e b prim >=
        [ r1 ]
        [ r1 pe str z e 1 prim + b s alt 0 union ] if } } };

: seq-eval
  (forall ρ; ρ pe:Seq Int^many str:Seq Int^many z:Seq Int^many a:Int^many e:Int^many s:Seq Int^many -- ρ r:Seq Int^many)
  locals { pe str z a e s } {
    a e prim >=
    [ s ]
    [ pe a prim seq-int.at
      locals { t } {
        t 100 prim >= [ t 99 prim - ] [ a 1 prim + ] if
        locals { aend } {
          pe aend e ops-end
          locals { j } {
            pe str z a aend j aend prim - s ev
            locals { s2 } {
              pe str z j e s2 seq-eval } } } } ] if };

: ev
  (forall ρ; ρ pe:Seq Int^many str:Seq Int^many z:Seq Int^many a:Int^many aend:Int^many k:Int^many s:Seq Int^many -- ρ r:Seq Int^many)
  locals { pe str z a aend k s } {
    k 0 prim =
    [ pe str z a aend s atom-eval ]
    [ pe aend k prim + 1 prim - prim seq-int.at
      locals { t } {
        t 27 prim =
        [ pe str z a aend k 1 prim - s clos ]
        [ t 28 prim =
          [ pe str z a aend k 1 prim - pe str z a aend k 1 prim - s ev clos ]
          [ s pe str z a aend k 1 prim - s ev 0 union ] if ] if } ] if };

: clos
  (forall ρ; ρ pe:Seq Int^many str:Seq Int^many z:Seq Int^many a:Int^many aend:Int^many k1:Int^many r:Seq Int^many -- ρ r2:Seq Int^many)
  locals { pe str z a aend k1 r } {
    r pe str z a aend k1 r ev 0 union
    locals { r2 } {
      r2 r 0 same
      [ r ]
      [ pe str z a aend k1 r2 clos ] if } };

: prev-ok
  (forall ρ; ρ pat:Seq Int^many i:Int^many -- ρ r:Bool^many)
  locals { pat i } {
    i 0 prim >
    [ pat i 1 prim - prim seq-int.at
      locals { q } { q 29 prim <= q 32 prim = prim or } ]
    [ false ] if };

: vloop
  (forall ρ; ρ pat:Seq Int^many pe:Seq Int^many stk:Seq Int^many i:Int^many sp:Int^many -- ρ pe2:Seq Int^many ok:Bool^many)
  locals { pat pe stk i sp } {
    i pat prim seq-int.len prim >=
    [ pe sp 0 prim = ]
    [ pat i prim seq-int.at
      locals { t } {
        t 27 prim >= t 29 prim <= prim and
        [ pat i prev-ok
          [ pat pe stk i 1 prim + sp vloop ]
          [ pe false ] if ]
        [ t 31 prim =
          [ pat pe stk sp i prim seq-int.set i 1 prim + sp 1 prim + vloop ]
          [ t 32 prim =
            [ sp 0 prim =
              [ pe false ]
              [ pat pe stk sp 1 prim - prim seq-int.at 100 i prim + prim seq-int.set stk i 1 prim + sp 1 prim - vloop ] if ]
            [ pat pe stk i 1 prim + sp vloop ] if ] if ] if } ] if };

: last-one
  (forall ρ; ρ r:Seq Int^many p:Int^many -- ρ q:Int^many)
  locals { r p } {
    p 0 prim <
    [ -1 ]
    [ r p prim seq-int.at 1 prim =
      [ p ]
      [ r p 1 prim - last-one ] if ] if };

: rloop
  (forall ρ; ρ pe:Seq Int^many n:Int^many lens:Seq Int^many chars:Seq Int^many j:Int^many off:Int^many full:Seq Bool^many longest:Seq Int^many count:Int^many -- ρ full2:Seq Bool^many longest2:Seq Int^many count2:Int^many)
  locals { pe n lens chars j off full longest count } {
    j lens prim seq-int.len prim >=
    [ full longest count ]
    [ lens j prim seq-int.at
      locals { len } {
        prim seq-int.empty chars off len 0 slice
        locals { str } {
          prim seq-int.empty len 1 prim + fill0
          locals { z } {
            pe str z 0 n z 0 1 prim seq-int.set alt
            locals { r } {
              r len prim seq-int.at 1 prim =
              locals { fl } {
                pe n lens chars j 1 prim + off len prim +
                full fl prim seq-bool.push
                longest r len last-one prim seq-int.push
                count fl [ 1 ] [ 0 ] if prim +
                rloop } } } } } ] if };

: main
  (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pattern lens chars } {
    pattern pattern prim seq-int.empty 21 fill0 0 0 vloop
    locals { pe ok } {
      ok
      [ pe pattern prim seq-int.len lens chars 0 0 prim seq-bool.empty prim seq-int.empty 0 rloop true ]
      [ prim seq-bool.empty lens prim seq-int.len fillf
        prim seq-int.empty lens prim seq-int.len fillneg
        0 false ] if } };
```

### task: swiss
```firth
: fill0
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc 0 prim seq-int.push n 1 prim - fill0 ] if };

: slice
  (forall ρ; ρ acc:Seq Int^many src:Seq Int^many off:Int^many n:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { acc src off n k } {
    k n prim >=
    [ acc ]
    [ acc src off k prim + prim seq-int.at prim seq-int.push src off n k 1 prim + slice ] if };

: sadd
  (forall ρ; ρ st:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st i d } { st i st i prim seq-int.at d prim + prim seq-int.set };

: rbase
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  locals { n } { 5 n prim * n n prim * prim + };

: ahead
  (forall ρ; ρ ka:Seq Int^many kb:Seq Int^many kc:Seq Int^many a:Int^many b:Int^many -- ρ r:Bool^many)
  locals { ka kb kc a b } {
    ka a prim seq-int.at ka b prim seq-int.at
    locals { x y } {
      x y prim >
      [ true ]
      [ x y prim <
        [ false ]
        [ kb a prim seq-int.at kb b prim seq-int.at
          locals { x2 y2 } {
            x2 y2 prim >
            [ true ]
            [ x2 y2 prim <
              [ false ]
              [ kc a prim seq-int.at kc b prim seq-int.at
                locals { x3 y3 } {
                  x3 y3 prim >
                  [ true ]
                  [ x3 y3 prim <
                    [ false ]
                    [ a b prim < ] if ] if } ] if ] if } ] if ] if } };

: count-ahead
  (forall ρ; ρ ka:Seq Int^many kb:Seq Int^many kc:Seq Int^many n:Int^many p:Int^many q:Int^many cnt:Int^many -- ρ r:Int^many)
  locals { ka kb kc n p q cnt } {
    q n prim >=
    [ cnt ]
    [ ka kb kc q p ahead
      [ ka kb kc n p q 1 prim + cnt 1 prim + count-ahead ]
      [ ka kb kc n p q 1 prim + cnt count-ahead ] if ] if };

: rank-sort
  (forall ρ; ρ ka:Seq Int^many kb:Seq Int^many kc:Seq Int^many n:Int^many p:Int^many ranking:Seq Int^many -- ρ r:Seq Int^many)
  locals { ka kb kc n p ranking } {
    p n prim >=
    [ ranking ]
    [ ka kb kc n p 0 0 count-ahead
      locals { pos } {
        ka kb kc n p 1 prim + ranking pos p prim seq-int.set rank-sort } ] if };

: pick-white
  (forall ρ; ρ st:Seq Int^many n:Int^many x:Int^many y:Int^many -- ρ w:Int^many)
  locals { st n x y } {
    st n x prim + prim seq-int.at st n y prim + prim seq-int.at
    locals { wx wy } {
      wx wy prim <
      [ x ]
      [ wy wx prim <
        [ y ]
        [ st 2 n prim * y prim + prim seq-int.at 2 prim =
          st 2 n prim * x prim + prim seq-int.at 2 prim = prim not prim and
          [ y ] [ x ] if ] if ] if } };

: play-game
  (forall ρ; ρ st:Seq Int^many results:Seq Int^many n:Int^many x:Int^many y:Int^many rem:Int^many -- ρ st2:Seq Int^many)
  locals { st results n x y rem } {
    st n x y pick-white
    locals { w } {
      x y prim + w prim -
      locals { b } {
        n rbase
        locals { r } {
          st r 2 prim + prim seq-int.at
          locals { g } {
            results st r prim seq-int.at prim seq-int.at
            locals { res } {
              st
              r 3 prim + g prim + w prim seq-int.set
              r 45 prim + g prim + b prim seq-int.set
              r 2 prim + 1 sadd
              r 1 prim + rem sadd
              r 1 sadd
              n w prim + 1 sadd
              2 n prim * w prim + 1 prim seq-int.set
              2 n prim * b prim + 2 prim seq-int.set
              5 n prim * w n prim * prim + b prim + 1 prim seq-int.set
              5 n prim * b n prim * prim + w prim + 1 prim seq-int.set
              res 0 prim =
              [ w 2 sadd ]
              [ res 1 prim =
                [ w 1 sadd b 1 sadd ]
                [ b 2 sadd ] if ] if } } } } } };

: find-partner
  (forall ρ; ρ st:Seq Int^many n:Int^many rank:Seq Int^many x:Int^many j:Int^many fb:Int^many -- ρ code:Int^many)
  locals { st n rank x j fb } {
    j n prim >=
    [ fb 2 prim * 1 prim + ]
    [ rank j prim seq-int.at
      locals { y } {
        st 4 n prim * y prim + prim seq-int.at 1 prim =
        [ st n rank x j 1 prim + fb find-partner ]
        [ st 5 n prim * x n prim * prim + y prim + prim seq-int.at 0 prim =
          [ y 2 prim * ]
          [ fb 0 prim <
            [ st n rank x j 1 prim + y find-partner ]
            [ st n rank x j 1 prim + fb find-partner ] if ] if ] if } ] if };

: pair-loop
  (forall ρ; ρ st:Seq Int^many results:Seq Int^many n:Int^many rank:Seq Int^many i:Int^many -- ρ st2:Seq Int^many)
  locals { st results n rank i } {
    i n prim >=
    [ st ]
    [ rank i prim seq-int.at
      locals { x } {
        st 4 n prim * x prim + prim seq-int.at 1 prim =
        [ st results n rank i 1 prim + pair-loop ]
        [ st n rank x i 1 prim + -1 find-partner
          locals { code } {
            code 2 prim div
            locals { y } {
              st 4 n prim * x prim + 1 prim seq-int.set
              4 n prim * y prim + 1 prim seq-int.set
              results n x y code 2 prim mod play-game
              results n rank i 1 prim + pair-loop } } ] if } ] if };

: clear-paired
  (forall ρ; ρ st:Seq Int^many n:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st n p } {
    p n prim >=
    [ st ]
    [ st 4 n prim * p prim + 0 prim seq-int.set n p 1 prim + clear-paired ] if };

: find-bye
  (forall ρ; ρ st:Seq Int^many n:Int^many rank:Seq Int^many k:Int^many -- ρ x:Int^many)
  locals { st n rank k } {
    rank k prim seq-int.at
    locals { x } {
      st 3 n prim * x prim + prim seq-int.at 0 prim =
      [ x ]
      [ st n rank k 1 prim - find-bye ] if } };

: do-bye
  (forall ρ; ρ st:Seq Int^many n:Int^many rank:Seq Int^many -- ρ st2:Seq Int^many)
  locals { st n rank } {
    n 2 prim mod 0 prim =
    [ st ]
    [ st n rank n 1 prim - find-bye
      locals { x } {
        st x 2 sadd 3 n prim * x prim + 1 prim seq-int.set 4 n prim * x prim + 1 prim seq-int.set } ] if };

: rounds-loop
  (forall ρ; ρ st:Seq Int^many ratings:Seq Int^many results:Seq Int^many n:Int^many r:Int^many total:Int^many -- ρ st2:Seq Int^many)
  locals { st ratings results n r total } {
    r total prim >=
    [ st ]
    [ st n 0 clear-paired
      locals { st1 } {
        st1 ratings ratings n 0 prim seq-int.empty n fill0 rank-sort
        locals { rank } {
          st1 n rank do-bye results n rank 0 pair-loop
          locals { st2 } {
            st2 ratings results n r 1 prim + total rounds-loop } } } ] if };

: buch-loop
  (forall ρ; ρ st:Seq Int^many r:Int^many g:Int^many acc:Seq Int^many -- ρ acc2:Seq Int^many)
  locals { st r g acc } {
    g st r 2 prim + prim seq-int.at prim >=
    [ acc ]
    [ st r 3 prim + g prim + prim seq-int.at
      st r 45 prim + g prim + prim seq-int.at
      locals { w b } {
        st r g 1 prim +
        acc w st b prim seq-int.at sadd b st w prim seq-int.at sadd
        buch-loop } ] if };

: main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  locals { ratings rounds results } {
    ratings prim seq-int.len
    locals { n } {
      prim seq-int.empty n rbase 87 prim + fill0
      ratings results n 0 rounds rounds-loop
      locals { st } {
        prim seq-int.empty st 0 n 0 slice
        locals { scores } {
          prim seq-int.empty st n n 0 slice
          locals { wh } {
            st n rbase 0 prim seq-int.empty n fill0 buch-loop
            locals { buch } {
              scores
              buch
              scores buch ratings n 0 prim seq-int.empty n fill0 rank-sort
              wh
              st n rbase 1 prim + prim seq-int.at } } } } } };
```

### task: warehouse
```firth
: fill0
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc 0 prim seq-int.push n 1 prim - fill0 ] if };

: wadd
  (forall ρ; ρ w:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w i d } { w i w i prim seq-int.at d prim + prim seq-int.set };

: ins
  (forall ρ; ρ w:Seq Int^many b:Int^many h:Int^many i:Int^many code:Int^many -- ρ r:Seq Int^many)
  locals { w b h i code } {
    i h prim >
    w b i prim + 1 prim - prim seq-int.at code prim >
    prim and
    [ w b i prim + w b i prim + 1 prim - prim seq-int.at prim seq-int.set b h i 1 prim - code ins ]
    [ w b i prim + code prim seq-int.set ] if };

: arrive
  (forall ρ; ρ w:Seq Int^many p:Int^many q:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { w p q x } {
    w 30 prim seq-int.at
    locals { a } {
      x 512 prim * a prim + 256 prim * q prim +
      locals { code } {
        w 5 p prim + prim seq-int.at
        locals { c } {
          w 36 p 144 prim * prim + w p prim seq-int.at c code ins
          5 p prim + c 1 prim + prim seq-int.set
          30 1 wadd
          31 p prim + q wadd } } } };

: take-loop
  (forall ρ; ρ w:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { w p q } {
    q 0 prim <=
    [ w ]
    [ w 36 p 144 prim * prim + w p prim seq-int.at prim + prim seq-int.at
      locals { code } {
        code 256 prim mod
        locals { f } {
          f q prim <=
          [ w p 1 wadd p q f prim - take-loop ]
          [ w 36 p 144 prim * prim + w p prim seq-int.at prim + code q prim - prim seq-int.set ] if } } ] if };

: take
  (forall ρ; ρ w:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { w p q } {
    w p q take-loop 31 p prim + 0 q prim - wadd };

: discard
  (forall ρ; ρ w:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w p d } {
    w p prim seq-int.at w 5 p prim + prim seq-int.at prim <
    [ w 36 p 144 prim * prim + w p prim seq-int.at prim + prim seq-int.at
      locals { code } {
        code 131072 prim div d prim <
        [ w 27 code 256 prim mod wadd
          31 p prim + 0 code 256 prim mod prim - wadd
          p 1 wadd p d discard ]
        [ w ] if } ]
    [ w ] if };

: discard-all
  (forall ρ; ρ w:Seq Int^many p:Int^many np:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w p np d } {
    p np prim >=
    [ w ]
    [ w p d discard p 1 prim + np d discard-all ] if };

: ship
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many p:Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { w price p u } {
    w 25 price p prim seq-int.at u prim * wadd 26 u wadd };

: fill-one
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { w price p } {
    w 10 p prim + prim seq-int.at
    locals { bh } {
      w 756 p 80 prim * prim + bh prim + prim seq-int.at
      locals { owed } {
        w 31 p prim + prim seq-int.at
        locals { s } {
          owed s prim < [ owed ] [ s ] if
          locals { t } {
            w p t take price p t ship
            756 p 80 prim * prim + bh prim + owed t prim - prim seq-int.set
            owed t prim - 0 prim =
            [ 10 p prim + 1 wadd ] [ ] if } } } } };

: fill
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { w price p } {
    w 10 p prim + prim seq-int.at w 15 p prim + prim seq-int.at prim <
    w 31 p prim + prim seq-int.at 0 prim > prim and
    [ w price p fill-one price p fill ]
    [ w ] if };

: append-bo
  (forall ρ; ρ w:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w p q d } {
    w 15 p prim + prim seq-int.at
    locals { bc } {
      w 756 p 80 prim * prim + bc prim + q prim seq-int.set
      1156 p 80 prim * prim + bc prim + d prim seq-int.set
      15 p prim + bc 1 prim + prim seq-int.set } };

: order
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w price p q d } {
    w 10 p prim + prim seq-int.at w 15 p prim + prim seq-int.at prim <
    [ w p q d append-bo ]
    [ w 31 p prim + prim seq-int.at
      locals { s } {
        q s prim < [ q ] [ s ] if
        locals { t } {
          w p t take price p t ship
          q t prim - 0 prim >
          [ p q t prim - d append-bo ] [ ] if } } ] if };

: supply-arrivals
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many rq:Seq Int^many shelf:Seq Int^many p:Int^many np:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w price rq shelf p np d } {
    p np prim >=
    [ w ]
    [ w 20 p prim + prim seq-int.at
      locals { due } {
        due 0 prim > due d prim = prim and
        [ w p rq p prim seq-int.at d shelf p prim seq-int.at prim + arrive
          20 p prim + 0 prim seq-int.set
          price p fill
          price rq shelf p 1 prim + np d supply-arrivals ]
        [ w price rq shelf p 1 prim + np d supply-arrivals ] if } ] if };

: events
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many eve:Seq Int^many ei:Int^many d:Int^many -- ρ w2:Seq Int^many ei2:Int^many)
  locals { w price evd evk evp evq eve ei d } {
    ei evd prim seq-int.len prim >=
    [ w ei ]
    [ evd ei prim seq-int.at d prim =
      [ evk ei prim seq-int.at 1 prim =
        [ w evp ei prim seq-int.at evq ei prim seq-int.at eve ei prim seq-int.at arrive
          price evp ei prim seq-int.at fill ]
        [ w price evp ei prim seq-int.at evq ei prim seq-int.at d order ] if
        price evd evk evp evq eve ei 1 prim + d events ]
      [ w ei ] if ] if };

: cancel
  (forall ρ; ρ w:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w p d } {
    w 10 p prim + prim seq-int.at
    locals { bh } {
      bh w 15 p prim + prim seq-int.at prim <
      [ w 1156 p 80 prim * prim + bh prim + prim seq-int.at d 7 prim - prim <=
        [ w 28 w 756 p 80 prim * prim + bh prim + prim seq-int.at wadd
          10 p prim + 1 wadd p d cancel ]
        [ w ] if ]
      [ w ] if } };

: cancel-all
  (forall ρ; ρ w:Seq Int^many p:Int^many np:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w p np d } {
    p np prim >=
    [ w ]
    [ w p d cancel p 1 prim + np d cancel-all ] if };

: reorder-all
  (forall ρ; ρ w:Seq Int^many rp:Seq Int^many lead:Seq Int^many p:Int^many np:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { w rp lead p np d } {
    p np prim >=
    [ w ]
    [ w 20 p prim + prim seq-int.at 0 prim =
      w 31 p prim + prim seq-int.at rp p prim seq-int.at prim <= prim and
      [ w 20 p prim + d lead p prim seq-int.at prim + prim seq-int.set 29 1 wadd
        rp lead p 1 prim + np d reorder-all ]
      [ w rp lead p 1 prim + np d reorder-all ] if ] if };

: day-loop
  (forall ρ; ρ w:Seq Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many eve:Seq Int^many np:Int^many days:Int^many d:Int^many ei:Int^many -- ρ r:Seq Int^many)
  locals { w price rp rq lead shelf evd evk evp evq eve np days d ei } {
    d days prim >=
    [ w ]
    [ w 0 np d discard-all
      price rq shelf 0 np d supply-arrivals
      price evd evk evp evq eve ei d events
      locals { w3 ei2 } {
        w3 0 np d cancel-all
        rp lead 0 np d reorder-all
        locals { w4 } {
          w4 price rp rq lead shelf evd evk evp evq eve np days d 1 prim + ei2 day-loop } } ] if };

: stk-out
  (forall ρ; ρ acc:Seq Int^many w:Seq Int^many p:Int^many np:Int^many -- ρ r:Seq Int^many)
  locals { acc w p np } {
    p np prim >=
    [ acc ]
    [ acc w 31 p prim + prim seq-int.at prim seq-int.push w p 1 prim + np stk-out ] if };

: owed-inner
  (forall ρ; ρ w:Seq Int^many p:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { w p i acc } {
    i w 15 p prim + prim seq-int.at prim >=
    [ acc ]
    [ w p i 1 prim + acc w 756 p 80 prim * prim + i prim + prim seq-int.at prim + owed-inner ] if };

: owed-sum
  (forall ρ; ρ w:Seq Int^many p:Int^many np:Int^many acc:Int^many -- ρ r:Int^many)
  locals { w p np acc } {
    p np prim >=
    [ acc ]
    [ w p 1 prim + np w p w 10 p prim + prim seq-int.at acc owed-inner owed-sum ] if };

: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many eve:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf evd evk evp evq eve } {
    prim seq-int.empty 1556 fill0
    price rp rq lead shelf evd evk evp evq eve price prim seq-int.len days 0 0 day-loop
    locals { w } {
      prim seq-int.empty w 0 price prim seq-int.len stk-out
      w 25 prim seq-int.at
      w 26 prim seq-int.at
      w 27 prim seq-int.at
      w 28 prim seq-int.at
      w 29 prim seq-int.at
      w 0 price prim seq-int.len 0 owed-sum } };
```

### task: cache-sim
```firth
: fill0
  (forall ρ; ρ acc:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { acc n } {
    n 0 prim <=
    [ acc ]
    [ acc 0 prim seq-int.push n 1 prim - fill0 ] if };

: bump
  (forall ρ; ρ regs:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { regs k } { regs k regs k prim seq-int.at 1 prim + prim seq-int.set };

: shift-left
  (forall ρ; ρ lv:Seq Int^many base:Int^many i:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { lv base i e } {
    i e 1 prim - prim >=
    [ lv ]
    [ lv base i prim + lv base i prim + 1 prim + prim seq-int.at prim seq-int.set base i 1 prim + e shift-left ] if };

: rm-at
  (forall ρ; ρ lv:Seq Int^many sets:Int^many ways:Int^many si:Int^many pos:Int^many -- ρ lv2:Seq Int^many)
  locals { lv sets ways si pos } {
    lv sets ways prim * si prim + prim seq-int.at
    locals { c } {
      lv si ways prim * pos c shift-left
      sets ways prim * si prim + c 1 prim - prim seq-int.set } };

: push-end
  (forall ρ; ρ lv:Seq Int^many sets:Int^many ways:Int^many si:Int^many v:Int^many -- ρ lv2:Seq Int^many)
  locals { lv sets ways si v } {
    lv sets ways prim * si prim + prim seq-int.at
    locals { c } {
      lv si ways prim * c prim + v prim seq-int.set
      sets ways prim * si prim + c 1 prim + prim seq-int.set } };

: find-pos
  (forall ρ; ρ lv:Seq Int^many sets:Int^many ways:Int^many si:Int^many b:Int^many i:Int^many -- ρ pos:Int^many)
  locals { lv sets ways si b i } {
    i lv sets ways prim * si prim + prim seq-int.at prim >=
    [ -1 ]
    [ lv si ways prim * i prim + prim seq-int.at 2 prim div b prim =
      [ i ]
      [ lv sets ways si b i 1 prim + find-pos ] if ] if };

: l-touch
  (forall ρ; ρ lv:Seq Int^many sets:Int^many ways:Int^many b:Int^many w:Int^many -- ρ lv2:Seq Int^many)
  locals { lv sets ways b w } {
    b sets prim mod
    locals { si } {
      lv sets ways si b 0 find-pos
      locals { pos } {
        lv si ways prim * pos prim + prim seq-int.at
        locals { e } {
          lv sets ways si pos rm-at
          sets ways si
          b 2 prim * e 2 prim mod w prim + 1 prim + 2 prim div prim +
          push-end } } } };

: l-put
  (forall ρ; ρ lv:Seq Int^many sets:Int^many ways:Int^many b:Int^many d:Int^many -- ρ lv2:Seq Int^many ev:Int^many)
  locals { lv sets ways b d } {
    b sets prim mod
    locals { si } {
      lv sets ways prim * si prim + prim seq-int.at ways prim >=
      [ lv si ways prim * prim seq-int.at
        locals { vic } {
          lv sets ways si 0 rm-at sets ways si b 2 prim * d prim + push-end vic } ]
      [ lv sets ways si b 2 prim * d prim + push-end -1 ] if } };

: dirty?
  (forall ρ; ρ ev:Int^many -- ρ r:Bool^many)
  locals { ev } { ev 0 prim >= ev 2 prim mod 1 prim = prim and };

: mw
  (forall ρ; ρ regs:Seq Int^many ev:Int^many -- ρ r:Seq Int^many)
  locals { regs ev } { ev dirty? [ regs 5 bump ] [ regs ] if };

: wb
  (forall ρ; ρ l2:Seq Int^many s2:Int^many w2:Int^many regs:Seq Int^many ev:Int^many -- ρ l2b:Seq Int^many regsb:Seq Int^many)
  locals { l2 s2 w2 regs ev } {
    ev 2 prim div
    locals { b } {
      l2 s2 w2 b s2 prim mod b 0 find-pos 0 prim >=
      [ l2 s2 w2 b 1 l-touch regs ]
      [ l2 s2 w2 b 1 l-put
        locals { l2x ev2 } { l2x regs ev2 mw } ] if } };

: miss
  (forall ρ; ρ l1:Seq Int^many l2:Seq Int^many regs:Seq Int^many s1:Int^many w1:Int^many s2:Int^many w2:Int^many b:Int^many w:Int^many -- ρ l1b:Seq Int^many l2b:Seq Int^many regsb:Seq Int^many)
  locals { l1 l2 regs s1 w1 s2 w2 b w } {
    l2 s2 w2 b s2 prim mod b 0 find-pos 0 prim >=
    [ l2 s2 w2 b 0 l-touch regs 1 bump 2 bump ]
    [ l2 s2 w2 b 0 l-put
      locals { l2x ev } {
        l2x regs 1 bump 3 bump 4 bump ev mw } ] if
    locals { l2a regsa } {
      l1 s1 w1 b w l-put
      locals { l1b ev1 } {
        ev1 dirty?
        [ l1b l2a s2 w2 regsa ev1 wb ]
        [ l1b l2a regsa ] if } } };

: access
  (forall ρ; ρ l1:Seq Int^many l2:Seq Int^many regs:Seq Int^many s1:Int^many w1:Int^many s2:Int^many w2:Int^many b:Int^many w:Int^many -- ρ l1b:Seq Int^many l2b:Seq Int^many regsb:Seq Int^many)
  locals { l1 l2 regs s1 w1 s2 w2 b w } {
    l1 s1 w1 b s1 prim mod b 0 find-pos 0 prim >=
    [ l1 s1 w1 b w l-touch l2 regs 0 bump ]
    [ l1 l2 regs s1 w1 s2 w2 b w miss ] if };

: sim
  (forall ρ; ρ l1:Seq Int^many l2:Seq Int^many regs:Seq Int^many s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many i:Int^many -- ρ l1b:Seq Int^many l2b:Seq Int^many regsb:Seq Int^many)
  locals { l1 l2 regs s1 w1 s2 w2 addrs writes i } {
    i addrs prim seq-int.len prim >=
    [ l1 l2 regs ]
    [ l1 l2 regs s1 w1 s2 w2 addrs i prim seq-int.at writes i prim seq-bool.at [ 1 ] [ 0 ] if access
      s1 w1 s2 w2 addrs writes i 1 prim + sim ] if };

: count-dirty
  (forall ρ; ρ lv:Seq Int^many sets:Int^many ways:Int^many si:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { lv sets ways si i acc } {
    si sets prim >=
    [ acc ]
    [ i lv sets ways prim * si prim + prim seq-int.at prim >=
      [ lv sets ways si 1 prim + 0 acc count-dirty ]
      [ lv sets ways si i 1 prim + acc lv si ways prim * i prim + prim seq-int.at 2 prim mod prim + count-dirty ] if ] if };

: blocks
  (forall ρ; ρ out:Seq Int^many lv:Seq Int^many sets:Int^many ways:Int^many si:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { out lv sets ways si i } {
    si sets prim >=
    [ out ]
    [ i lv sets ways prim * si prim + prim seq-int.at prim >=
      [ out lv sets ways si 1 prim + 0 blocks ]
      [ out lv si ways prim * i prim + prim seq-int.at 2 prim div prim seq-int.push lv sets ways si i 1 prim + blocks ] if ] if };

: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1-hits:Int^many l1-misses:Int^many l2-hits:Int^many l2-misses:Int^many mem-reads:Int^many mem-writes:Int^many dirty:Int^many l1-blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    prim seq-int.empty s1 w1 prim * s1 prim + fill0
    prim seq-int.empty s2 w2 prim * s2 prim + fill0
    prim seq-int.empty 6 fill0
    s1 w1 s2 w2 addrs writes 0 sim
    locals { l1 l2 regs } {
      regs 0 prim seq-int.at
      regs 1 prim seq-int.at
      regs 2 prim seq-int.at
      regs 3 prim seq-int.at
      regs 4 prim seq-int.at
      regs 5 prim seq-int.at
      l1 s1 w1 0 0 0 count-dirty l2 s2 w2 0 0 0 count-dirty prim +
      prim seq-int.empty l1 s1 w1 0 0 blocks } };
```

NOTE: Nothing here was run; I could not check it against the runner. I guessed the source spelling of sequence types in stack effects (`Seq Int^many`).

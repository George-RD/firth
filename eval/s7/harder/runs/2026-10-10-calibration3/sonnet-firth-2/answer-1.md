### task: mini-cpu
```firth
: get
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many)
  prim seq-int.at;

: put
  (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: pu
  (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.push;

: b2i
  (forall ρ; ρ b:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if;

: wrap
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  2147483648 prim + 4294967296 prim mod 2147483648 prim -;

: iabs
  (forall ρ; ρ n:Int^many -- ρ m:Int^many)
  dup 0 prim < [ 0 swap prim - ] [ ] if;

: tdiv
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } {
    a iabs b iabs prim div
    a b prim * 0 prim <
    [ 0 swap prim - ] [ ] if
  };

: pow2-loop
  (forall ρ; ρ acc:Int^many c:Int^many -- ρ p:Int^many)
  locals { acc c } {
    c 0 prim <=
    [ acc ]
    [ acc 2 prim * c 1 prim - pow2-loop ]
    if
  };

: pow2
  (forall ρ; ρ c:Int^many -- ρ p:Int^many)
  1 swap pow2-loop;

: fld
  (forall ρ; ρ s:Seq Int^many base:Int^many pc:Int^many -- ρ v:Int^many)
  prim + prim seq-int.at;

: setflags
  (forall ρ; ρ s:Seq Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { s t } {
    s 8 t wrap 0 prim = b2i put
      9 t wrap 0 prim < b2i put
      10 t wrap t prim = prim not b2i put
  };

: arith-store
  (forall ρ; ρ s:Seq Int^many a:Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { s a t } { s t setflags a t wrap put };

: adv
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 11 s 11 get 1 prim + put 12 s 12 get 1 prim + put
  };

: jump
  (forall ρ; ρ s:Seq Int^many tg:Int^many -- ρ r:Seq Int^many)
  locals { s tg } {
    s 11 tg put 12 s 12 get 1 prim + put
  };

: fault
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } { s 13 k put };

: halt
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 13 0 put 12 s 12 get 1 prim + put
  };

: arith-t
  (forall ρ; ρ s:Seq Int^many op:Int^many b:Int^many c:Int^many -- ρ t:Int^many)
  locals { s op b c } {
    s b get
    locals { x } {
      op 3 prim = [ x s c get prim + ]
      [ op 4 prim = [ x s c get prim - ]
        [ op 5 prim = [ x s c get prim * ]
          [ op 8 prim = [ 0 x prim - ]
            [ op 9 prim = [ x c pow2 prim * ]
              [ op 10 prim = [ x c pow2 prim div ]
                [ x s c get prim - ]
                if ]
              if ]
            if ]
          if ]
        if ]
      if
    }
  };

: op-arith
  (forall ρ; ρ s:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s op a b c } {
    s op b c arith-t
    locals { t } {
      op 11 prim =
      [ s t setflags adv ]
      [ s a t arith-store adv ]
      if
    }
  };

: op-divrem
  (forall ρ; ρ s:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s op a b c } {
    s c get 0 prim =
    [ s 3 fault ]
    [ s b get s c get tdiv
      locals { q } {
        op 6 prim =
        [ s a q arith-store ]
        [ s a s b get q s c get prim * prim - arith-store ]
        if
      }
      adv ]
    if
  };

: op-mem
  (forall ρ; ρ s:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s op a b c } {
    s b get c prim +
    locals { ad } {
      ad 0 prim < ad 63 prim > prim or
      [ s 6 fault ]
      [ op 12 prim =
        [ s a s 20 ad prim + get put adv ]
        [ s 20 ad prim + s a get put adv ]
        if ]
      if
    }
  };

: op-jump
  (forall ρ; ρ s:Seq Int^many op:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { s op b } {
    op 14 prim =
    [ 0 0 prim = ]
    [ op 15 prim = [ s 8 get 1 prim = ]
      [ op 16 prim = [ s 8 get 0 prim = ]
        [ op 17 prim = [ s 9 get s 10 get prim = prim not ]
          [ s 9 get s 10 get prim = ]
          if ]
        if ]
      if ]
    if
    [ s b jump ]
    [ s adv ]
    if
  };

: op-push
  (forall ρ; ρ s:Seq Int^many a:Int^many -- ρ r:Seq Int^many)
  locals { s a } {
    s 14 get
    locals { d } {
      d 16 prim >=
      [ s 4 fault ]
      [ s 84 d prim + s a get put 14 d 1 prim + put adv ]
      if
    }
  };

: op-pop
  (forall ρ; ρ s:Seq Int^many a:Int^many -- ρ r:Seq Int^many)
  locals { s a } {
    s 14 get
    locals { d } {
      d 0 prim =
      [ s 5 fault ]
      [ s a s 84 d 1 prim - prim + get put 14 d 1 prim - put adv ]
      if
    }
  };

: op-call
  (forall ρ; ρ s:Seq Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { s b } {
    s 15 get
    locals { k } {
      k 8 prim >=
      [ s 4 fault ]
      [ s 100 k prim + s 11 get 1 prim + put 15 k 1 prim + put b jump ]
      if
    }
  };

: op-ret
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 15 get
    locals { k } {
      k 0 prim =
      [ s 5 fault ]
      [ s 15 k 1 prim - put s 100 k 1 prim - prim + get jump ]
      if
    }
  };

: op-input
  (forall ρ; ρ s:Seq Int^many a:Int^many -- ρ r:Seq Int^many)
  locals { s a } {
    s 16 get
    locals { ip } {
      ip s 17 get prim >=
      [ s 7 fault ]
      [ s a s 376 ip prim + get put 16 ip 1 prim + put adv ]
      if
    }
  };

: op-output
  (forall ρ; ρ s:Seq Int^many a:Int^many -- ρ r:Seq Int^many)
  locals { s a } {
    s s a get prim seq-int.push adv
  };

: exec-lo
  (forall ρ; ρ s:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s op a b c } {
    op 0 prim = [ s halt ]
    [ op 1 prim = [ s a b put adv ]
      [ op 2 prim = [ s a s b get put adv ]
        [ op 6 prim = op 7 prim = prim or [ s op a b c op-divrem ]
          [ op 12 prim >= [ s op a b c op-mem ]
            [ s op a b c op-arith ]
            if ]
          if ]
        if ]
      if ]
    if
  };

: exec-hi
  (forall ρ; ρ s:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s op a b c } {
    op 19 prim <
    [ s op b op-jump ]
    [ op 19 prim = [ s a op-push ]
      [ op 20 prim = [ s a op-pop ]
        [ op 21 prim = [ s b op-call ]
          [ op 22 prim = [ s op-ret ]
            [ op 23 prim = [ s a op-input ]
              [ s a op-output ]
              if ]
            if ]
          if ]
        if ]
      if ]
    if
  };

: exec
  (forall ρ; ρ s:Seq Int^many op:Int^many a:Int^many b:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s op a b c } {
    op 14 prim >=
    [ s op a b c exec-hi ]
    [ s op a b c exec-lo ]
    if
  };

: step
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 11 get
    locals { pc } {
      s s 120 pc fld s 184 pc fld s 248 pc fld s 312 pc fld exec
    }
  };

: pc-ok
  (forall ρ; ρ s:Seq Int^many -- ρ b:Bool^many)
  locals { s } {
    s 11 get 0 prim >= s 11 get s 18 get prim < prim and
  };

: run
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 13 get 0 prim <
    [ s 12 get 300 prim >=
      [ s 13 1 put ]
      [ s pc-ok
        [ s step run ]
        [ s 13 2 put ]
        if ]
      if ]
    [ s ]
    if
  };

: pad-to
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    s prim seq-int.len k prim >=
    [ s ]
    [ s 0 prim seq-int.push k pad-to ]
    if
  };

: append-from
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s xs i } {
    i xs prim seq-int.len prim >=
    [ s ]
    [ s xs i prim seq-int.at prim seq-int.push xs i 1 prim + append-from ]
    if
  };

: append
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many -- ρ r:Seq Int^many)
  0 append-from;

: slice-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many hi:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { s i hi acc } {
    i hi prim >=
    [ acc ]
    [ s i 1 prim + hi acc s i prim seq-int.at prim seq-int.push slice-loop ]
    if
  };

: slice
  (forall ρ; ρ s:Seq Int^many lo:Int^many hi:Int^many -- ρ r:Seq Int^many)
  locals { s lo hi } {
    s lo hi prim seq-int.empty slice-loop
  };

: main
  (forall ρ; ρ ops:Seq Int^many fa:Seq Int^many fb:Seq Int^many fc:Seq Int^many regs:Seq Int^many memory:Seq Int^many inputs:Seq Int^many -- ρ output:Seq Int^many status:Int^many executed:Int^many pc:Int^many registers:Seq Int^many final-memory:Seq Int^many flag-seq:Seq Bool^many)
  locals { ops fa fb fc regs memory inputs } {
    regs
    0 pu 0 pu 0 pu 0 pu 0 pu -1 pu 0 pu 0 pu 0 pu
    inputs prim seq-int.len pu
    ops prim seq-int.len pu
    20 pad-to
    memory append
    120 pad-to
    ops append 184 pad-to
    fa append 248 pad-to
    fb append 312 pad-to
    fc append 376 pad-to
    inputs append 416 pad-to
    run
    locals { s } {
      s 416 s prim seq-int.len slice
      s 13 get
      s 12 get
      s 11 get
      s 0 8 slice
      s 20 84 slice
      prim seq-bool.empty
      s 8 get 1 prim = prim seq-bool.push
      s 9 get 1 prim = prim seq-bool.push
      s 10 get 1 prim = prim seq-bool.push
    }
  };
```

### task: stacker
```firth
: get
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many)
  prim seq-int.at;

: put
  (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: pu
  (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.push;

: b2i
  (forall ρ; ρ b:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if;

: tt
  (forall ρ; ρ -- ρ b:Bool^many)
  0 0 prim =;

: ff
  (forall ρ; ρ -- ρ b:Bool^many)
  0 1 prim =;

: tbl
  (forall ρ; ρ kind:Int^many rot:Int^many j:Int^many off:Int^many -- ρ v:Int^many)
  locals { kind rot j off } {
    { 0 2 1 2 2 2 3 2
      2 0 2 1 2 2 2 3
      0 1 1 1 2 1 3 1
      1 0 1 1 1 2 1 3
      1 1 2 1 1 2 2 2
      1 1 2 1 1 2 2 2
      1 1 2 1 1 2 2 2
      1 1 2 1 1 2 2 2
      0 2 1 2 2 2 1 3
      1 1 1 2 1 3 2 2
      0 2 1 2 2 2 1 1
      1 1 1 2 1 3 0 2
      0 2 1 2 1 3 2 3
      1 3 1 2 2 2 2 1
      0 1 1 1 1 2 2 2
      0 3 0 2 1 2 1 1
      0 3 1 3 1 2 2 2
      2 3 2 2 1 2 1 1
      0 2 1 2 1 1 2 1
      1 3 1 2 0 2 0 1
      0 2 1 2 2 2 2 3
      1 3 1 2 1 1 2 1
      0 1 0 2 1 2 2 2
      0 3 1 3 1 2 1 1
      0 3 0 2 1 2 2 2
      1 1 1 2 1 3 2 3
      0 2 1 2 2 2 2 1
      0 1 1 1 1 2 1 3 }
    kind 4 prim * rot prim + 8 prim * j 2 prim * prim + off prim + prim seq-int.at
  };

: fits-from
  (forall ρ; ρ s:Seq Int^many kind:Int^many rot:Int^many x:Int^many y:Int^many j:Int^many -- ρ r:Bool^many)
  locals { s kind rot x y j } {
    j 4 prim >=
    [ tt ]
    [ x kind rot j 0 tbl prim +
      y kind rot j 1 tbl prim +
      locals { cx cy } {
        cx 0 prim >= cx s 14 get prim < prim and
        cy 0 prim >= prim and cy s 15 get prim < prim and
        [ s 24 cy s 14 get prim * prim + cx prim + get 0 prim =
          [ s kind rot x y j 1 prim + fits-from ]
          [ ff ]
          if ]
        [ ff ]
        if
      } ]
    if
  };

: fits
  (forall ρ; ρ s:Seq Int^many kind:Int^many rot:Int^many x:Int^many y:Int^many -- ρ r:Bool^many)
  0 fits-from;

: spawn
  (forall ρ; ρ s:Seq Int^many k:Int^many ch:Int^many -- ρ r:Seq Int^many)
  locals { s k ch } {
    s 0 k put 1 0 put 2 s 14 get 4 prim - 2 prim div put 3 s 15 get 4 prim - put 4 ch put
    locals { s2 } {
      s2 s2 0 get 0 s2 2 get s2 3 get fits
      [ s2 ] [ s2 13 2 put ] if
    }
  };

: next-piece
  (forall ρ; ρ s:Seq Int^many ch:Int^many -- ρ r:Seq Int^many)
  locals { s ch } {
    s 6 get s 17 get prim >=
    [ s 13 0 put ]
    [ s 6 s 6 get 1 prim + put
      locals { s1 } { s1 s 130 s 6 get prim + get ch spawn } ]
    if
  };

: try-move
  (forall ρ; ρ s:Seq Int^many dx:Int^many dy:Int^many -- ρ r:Seq Int^many)
  locals { s dx dy } {
    s s 0 get s 1 get s 2 get dx prim + s 3 get dy prim + fits
    [ s 2 s 2 get dx prim + put 3 s 3 get dy prim + put ]
    [ s ]
    if
  };

: rot-try
  (forall ρ; ρ s:Seq Int^many nr:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s nr i } {
    i 6 prim >=
    [ s ]
    [ { 0 -1 1 0 -2 2 } i prim seq-int.at
      { 0 0 0 1 0 0 } i prim seq-int.at
      locals { ox oy } {
        s s 0 get nr s 2 get ox prim + s 3 get oy prim + fits
        [ s 1 nr put 2 s 2 get ox prim + put 3 s 3 get oy prim + put ]
        [ s nr i 1 prim + rot-try ]
        if
      } ]
    if
  };

: place
  (forall ρ; ρ s:Seq Int^many kind:Int^many rot:Int^many x:Int^many y:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { s kind rot x y j } {
    j 4 prim >=
    [ s ]
    [ s 24 y kind rot j 1 tbl prim + s 14 get prim * prim + x kind rot j 0 tbl prim + prim + 1 put
      kind rot x y j 1 prim + place ]
    if
  };

: row-sum
  (forall ρ; ρ s:Seq Int^many y:Int^many i:Int^many acc:Int^many -- ρ n:Int^many)
  locals { s y i acc } {
    i s 14 get prim >=
    [ acc ]
    [ s y i 1 prim + acc s 24 y s 14 get prim * prim + i prim + get prim + row-sum ]
    if
  };

: row-full
  (forall ρ; ρ s:Seq Int^many y:Int^many -- ρ b:Bool^many)
  locals { s y } { s y 0 0 row-sum s 14 get prim = };

: copy-cells
  (forall ρ; ρ s:Seq Int^many y:Int^many d:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s y d i } {
    i s 14 get prim >=
    [ s ]
    [ s 24 d s 14 get prim * prim + i prim +
      s 24 y s 14 get prim * prim + i prim + get
      put
      y d i 1 prim + copy-cells ]
    if
  };

: zero-cells
  (forall ρ; ρ s:Seq Int^many i:Int^many end:Int^many -- ρ r:Seq Int^many)
  locals { s i end } {
    i end prim >=
    [ s ]
    [ s i 0 put i 1 prim + end zero-cells ]
    if
  };

: zero-rows
  (forall ρ; ρ s:Seq Int^many d:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s d k } {
    s 19 k put
    24 d s 14 get prim * prim +
    24 s 15 get s 14 get prim * prim +
    zero-cells
  };

: compact
  (forall ρ; ρ s:Seq Int^many y:Int^many d:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s y d k } {
    y s 15 get prim >=
    [ s d k zero-rows ]
    [ s y row-full
      [ s y 1 prim + d k 1 prim + compact ]
      [ s y d 0 copy-cells y 1 prim + d 1 prim + k compact ]
      if ]
    if
  };

: score-lock
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    k 0 prim >
    [ { 0 100 300 500 800 } k prim seq-int.at
      locals { base0 } {
        k 4 prim = s 12 get 4 prim = prim and
        [ 1200 ] [ base0 ] if
        locals { base } {
          s 8
            s 8 get base s 11 get 50 prim * prim + 1 s 9 get 10 prim div prim + prim * prim +
            put
          9 s 9 get k prim + put
          11 s 11 get 1 prim + put
          12 k put
        }
      } ]
    [ s 11 0 put ]
    if
  };

: place-cells
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } { s s 0 get s 1 get s 2 get s 3 get 0 place };

: lock
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s place-cells
    10 s 10 get 1 prim + put
    0 0 0 compact
    locals { s3 } { s3 s3 19 get score-lock 0 -1 put }
  };

: hard-drop
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s s 0 get s 1 get s 2 get s 3 get 1 prim - fits
    [ s 3 s 3 get 1 prim - put hard-drop ]
    [ s lock ]
    if
  };

: do-hold
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 4 get 0 prim =
    [ s ]
    [ s 5 get 0 prim <
      [ s 5 s 0 get put
        locals { s1 } { s1 0 next-piece } ]
      [ s 5 s 0 get put
        locals { s1 } { s1 s 5 get 0 spawn } ]
      if ]
    if
  };

: do-cmd
  (forall ρ; ρ s:Seq Int^many cmd:Int^many -- ρ r:Seq Int^many)
  locals { s cmd } {
    cmd 0 prim = [ s hard-drop ]
    [ cmd 1 prim = [ s -1 0 try-move ]
      [ cmd 2 prim = [ s 1 0 try-move ]
        [ cmd 3 prim = [ s s 1 get 1 prim + 4 prim mod 0 rot-try ]
          [ cmd 4 prim = [ s s 1 get 3 prim + 4 prim mod 0 rot-try ]
            [ cmd 5 prim = [ s 0 -1 try-move ]
              [ s do-hold ]
              if ]
            if ]
          if ]
        if ]
      if ]
    if
  };

: cmd-stage
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 7 get s 18 get prim >=
    [ s 13 1 put ]
    [ s 7 s 7 get 1 prim + put
      locals { s1 } { s1 s 160 s 7 get prim + get do-cmd } ]
    if
  };

: step-game
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 0 get 0 prim <
    [ s 1 next-piece ]
    [ s ]
    if
    locals { s1 } {
      s1 13 get 0 prim <
      [ s1 cmd-stage ]
      [ s1 ]
      if
    }
  };

: play
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 13 get 0 prim <
    [ s step-game play ]
    [ s ]
    if
  };

: col-height
  (forall ρ; ρ s:Seq Int^many x:Int^many y:Int^many -- ρ h:Int^many)
  locals { s x y } {
    y 0 prim <
    [ 0 ]
    [ s 24 y s 14 get prim * prim + x prim + get 0 prim =
      [ s x y 1 prim - col-height ]
      [ y 1 prim + ]
      if ]
    if
  };

: heights-loop
  (forall ρ; ρ s:Seq Int^many x:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { s x acc } {
    x s 14 get prim >=
    [ acc ]
    [ s x 1 prim + acc s x s 15 get 1 prim - col-height prim seq-int.push heights-loop ]
    if
  };

: pad-to
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    s prim seq-int.len k prim >=
    [ s ]
    [ s 0 prim seq-int.push k pad-to ]
    if
  };

: append-from
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s xs i } {
    i xs prim seq-int.len prim >=
    [ s ]
    [ s xs i prim seq-int.at prim seq-int.push xs i 1 prim + append-from ]
    if
  };

: append
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many -- ρ r:Seq Int^many)
  0 append-from;

: main
  (forall ρ; ρ width:Int^many height:Int^many queue:Seq Int^many moves:Seq Int^many -- ρ heights:Seq Int^many score:Int^many rows:Int^many locks:Int^many status:Int^many held:Int^many)
  locals { width height queue moves } {
    prim seq-int.empty
    -1 pu 0 pu 0 pu 0 pu 0 pu -1 pu
    0 pu 0 pu 0 pu 0 pu 0 pu 0 pu 0 pu
    -1 pu
    width pu height pu 0 pu
    queue prim seq-int.len pu moves prim seq-int.len pu
    0 pu 0 pu 0 pu 0 pu 0 pu
    130 pad-to queue append 160 pad-to moves append
    play
    locals { s } {
      s 0 prim seq-int.empty heights-loop
      s 8 get
      s 9 get
      s 10 get
      s 13 get
      s 5 get
    }
  };
```

### task: bank-days
```firth
: get
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many)
  prim seq-int.at;

: put
  (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: pu
  (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.push;

: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: leap
  (forall ρ; ρ y:Int^many -- ρ b:Bool^many)
  locals { y } {
    y 4 prim mod 0 prim =
    y 100 prim mod 0 prim = prim not y 400 prim mod 0 prim = prim or
    prim and
  };

: dim
  (forall ρ; ρ y:Int^many m:Int^many -- ρ d:Int^many)
  locals { y m } {
    m 2 prim =
    [ y leap [ 29 ] [ 28 ] if ]
    [ m 4 prim = m 6 prim = prim or m 9 prim = prim or m 11 prim = prim or
      [ 30 ] [ 31 ] if ]
    if
  };

: pay
  (forall ρ; ρ s:Seq Int^many src:Int^many dst:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { s src dst amt } {
    s 20 src prim + get amt prim - 0 s 26 src prim + get prim - prim <
    dst 0 prim >= dst src prim = prim and prim or
    [ s 6 s 6 get 1 prim + put 14 0 put ]
    [ s 20 src prim + s 20 src prim + get amt prim - put
      locals { s1 } {
        dst 0 prim >=
        [ s1 20 dst prim + s1 20 dst prim + get amt prim + put 14 1 put ]
        [ s1 14 1 put ]
        if
      } ]
    if
  };

: apply-tx
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    s 120 k prim + get
    s 180 k prim + get
    s 300 k prim + get
    locals { kd a amt } {
      kd 1 prim =
      [ s 20 a prim + s 20 a prim + get amt prim + put ]
      [ kd 2 prim =
        [ s a -1 amt pay ]
        [ s a s 240 k prim + get amt pay ]
        if ]
      if
    }
  };

: tx-chain
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    k 0 prim <
    [ s ]
    [ s k apply-tx s 520 k prim + get tx-chain ]
    if
  };

: so-pay
  (forall ρ; ρ s:Seq Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { s j } {
    s s 366 j prim + get s 372 j prim + get s 378 j prim + get pay
    locals { s1 } {
      s1 14 get 0 prim =
      [ s1 50 j prim + s1 50 j prim + get 1 prim + put
        locals { s2 } {
          s2 50 j prim + get 2 prim >=
          [ s2 44 j prim + 1 put ]
          [ s2 ]
          if
        } ]
      [ s1 50 j prim + 0 put ]
      if
    }
  };

: so-loop
  (forall ρ; ρ s:Seq Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { s j } {
    j s 11 get prim >=
    [ s ]
    [ s 44 j prim + get 0 prim =
      s 2 get s 360 j prim + get s 15 get min2 prim = prim and
      [ s j so-pay j 1 prim + so-loop ]
      [ s j 1 prim + so-loop ]
      if ]
    if
  };

: int-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 20 i prim + get
      locals { bal } {
        bal 0 prim >
        [ s 32 i prim + s 32 i prim + get bal s 4 get prim * prim + put ]
        [ bal 0 prim <
          [ s 32 i prim + s 32 i prim + get bal s 5 get prim * prim + put 38 i prim + 1 put ]
          [ s ]
          if ]
        if
        i 1 prim + int-loop
      } ]
    if
  };

: post-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 32 i prim + get
      locals { sm } {
        sm 0 prim >=
        [ sm 1000000 prim div
          locals { a } {
            s 20 i prim + s 20 i prim + get a prim + put 7 s 7 get a prim + put
          } ]
        [ 0 sm prim - 1000000 prim div
          locals { a } {
            s 20 i prim + s 20 i prim + get a prim - put 8 s 8 get a prim + put
          } ]
        if
        32 i prim + 0 put
        locals { s1 } {
          s1 38 i prim + get 1 prim =
          [ s1 20 i prim + s1 20 i prim + get 1000 prim - put
            9 s1 9 get 1000 prim + put
            38 i prim + 0 put ]
          [ s1 ]
          if
          i 1 prim + post-loop
        }
      } ]
    if
  };

: advance
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 2 get 1 prim +
    locals { nd } {
      nd s 15 get prim >
      [ s 2 1 put 1 s 1 get 1 prim + put
        locals { s1 } {
          s1 1 get 12 prim >
          [ s1 1 1 put 0 s1 0 get 1 prim + put ]
          [ s1 ]
          if
        } ]
      [ s 2 nd put ]
      if
    }
  };

: day-loop
  (forall ρ; ρ s:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { s d } {
    d s 13 get prim >=
    [ s ]
    [ s 15 s 0 get s 1 get dim put
      locals { s1 } {
        s1 s1 400 d prim + get tx-chain
        0 so-loop
        0 int-loop
        locals { s2 } {
          s2 2 get s2 15 get prim =
          [ s2 0 post-loop ]
          [ s2 ]
          if
          advance
          d 1 prim + day-loop
        }
      } ]
    if
  };

: link-loop
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    k 0 prim <
    [ s ]
    [ s 520 k prim + s 400 s 60 k prim + get prim + get put
      400 s 60 k prim + get prim + k put
      k 1 prim - link-loop ]
    if
  };

: pad-to
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    s prim seq-int.len k prim >=
    [ s ]
    [ s 0 prim seq-int.push k pad-to ]
    if
  };

: padv
  (forall ρ; ρ s:Seq Int^many v:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s v k } {
    s prim seq-int.len k prim >=
    [ s ]
    [ s v prim seq-int.push v k padv ]
    if
  };

: append-from
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s xs i } {
    i xs prim seq-int.len prim >=
    [ s ]
    [ s xs i prim seq-int.at prim seq-int.push xs i 1 prim + append-from ]
    if
  };

: append
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many -- ρ r:Seq Int^many)
  0 append-from;

: slice-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many hi:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { s i hi acc } {
    i hi prim >=
    [ acc ]
    [ s i 1 prim + hi acc s i prim seq-int.at prim seq-int.push slice-loop ]
    if
  };

: slice
  (forall ρ; ρ s:Seq Int^many lo:Int^many hi:Int^many -- ρ r:Seq Int^many)
  locals { s lo hi } {
    s lo hi prim seq-int.empty slice-loop
  };

: canc-loop
  (forall ρ; ρ s:Seq Int^many j:Int^many acc:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { s j acc } {
    j s 11 get prim >=
    [ acc ]
    [ s j 1 prim + acc s 44 j prim + get 1 prim = prim seq-bool.push canc-loop ]
    if
  };

: main
  (forall ρ; ρ year:Int^many month:Int^many day:Int^many days:Int^many balances:Seq Int^many limits:Seq Int^many credit-ppm:Int^many debit-ppm:Int^many tx-day:Seq Int^many tx-kind:Seq Int^many tx-acct:Seq Int^many tx-other:Seq Int^many tx-amount:Seq Int^many so-dom:Seq Int^many so-from:Seq Int^many so-to:Seq Int^many so-amount:Seq Int^many -- ρ final:Seq Int^many rejected:Int^many cancelled:Seq Bool^many interest-added:Int^many interest-taken:Int^many fees:Int^many)
  locals { year month day days balances limits credit-ppm debit-ppm tx-day tx-kind tx-acct tx-other tx-amount so-dom so-from so-to so-amount } {
    prim seq-int.empty
    year pu month pu day pu balances prim seq-int.len pu credit-ppm pu debit-ppm pu
    0 pu 0 pu 0 pu 0 pu
    tx-day prim seq-int.len pu so-dom prim seq-int.len pu
    0 pu days pu 0 pu 0 pu
    20 pad-to balances append
    26 pad-to limits append
    60 pad-to tx-day append
    120 pad-to tx-kind append
    180 pad-to tx-acct append
    240 pad-to tx-other append
    300 pad-to tx-amount append
    360 pad-to so-dom append
    366 pad-to so-from append
    372 pad-to so-to append
    378 pad-to so-amount append
    400 pad-to
    -1 520 padv
    580 pad-to
    locals { s0 } { s0 s0 10 get 1 prim - link-loop }
    0 day-loop
    locals { r } {
      r 20 20 r 3 get prim + slice
      r 6 get
      r 0 prim seq-bool.empty canc-loop
      r 7 get
      r 8 get
      r 9 get
    }
  };
```

### task: formula-sheet
```firth
: get
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many)
  prim seq-int.at;

: put
  (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: pu
  (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.push;

: b2i
  (forall ρ; ρ b:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if;

: err
  (forall ρ; ρ -- ρ e:Int^many)
  5000000000;

: iabs
  (forall ρ; ρ n:Int^many -- ρ m:Int^many)
  dup 0 prim < [ 0 swap prim - ] [ ] if;

: tdiv
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } {
    a iabs b iabs prim div
    a b prim * 0 prim <
    [ 0 swap prim - ] [ ] if
  };

: min2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: max2
  (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } { a b prim > [ a ] [ b ] if };

: lim
  (forall ρ; ρ r:Int^many -- ρ q:Int^many)
  dup iabs 1000000000 prim > [ drop err ] [ ] if;

: neg
  (forall ρ; ρ a:Int^many -- ρ r:Int^many)
  dup err prim = [ ] [ 0 swap prim - lim ] if;

: ifv
  (forall ρ; ρ c:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  locals { c a b } {
    c err prim =
    [ err ]
    [ c 0 prim = [ b ] [ a ] if ]
    if
  };

: compute2
  (forall ρ; ρ op:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  locals { op a b } {
    a err prim = b err prim = prim or
    [ err ]
    [ op 1 prim = [ a b prim + lim ]
      [ op 2 prim = [ a b prim - lim ]
        [ op 3 prim = [ a b prim * lim ]
          [ op 4 prim = [ b 0 prim = [ err ] [ a b tdiv lim ] if ]
            [ op 5 prim = [ a b prim < b2i ] [ a b prim = b2i ] if ]
            if ]
          if ]
        if ]
      if ]
    if
  };

: tokf
  (forall ρ; ρ s:Seq Int^many base:Int^many c:Int^many t:Int^many -- ρ v:Int^many)
  locals { s base c t } {
    s base s 20 c prim + get prim + t prim + get
  };

: reset-cells
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 0 get prim >=
    [ s ]
    [ s 60 i prim + 0 put 80 i prim + 0 put 100 i prim + err put
      i 1 prim + reset-cells ]
    if
  };

: ref-range
  (forall ρ; ρ s:Seq Int^many c:Int^many lo:Int^many hi:Int^many -- ρ r:Seq Int^many)
  locals { s c lo hi } {
    lo hi prim >
    [ s ]
    [ s c lo ref-one c lo 1 prim + hi ref-range ]
    if
  };

: ref-one
  (forall ρ; ρ s:Seq Int^many c:Int^many r:Int^many -- ρ q:Seq Int^many)
  locals { s c r } {
    s 60 r prim + get 0 prim =
    [ s r visit ]
    [ s ]
    if
    locals { s1 } {
      s1 60 r prim + get 1 prim = s1 80 r prim + get 1 prim = prim or
      [ s1 80 c prim + 1 put ]
      [ s1 ]
      if
    }
  };

: visit-toks
  (forall ρ; ρ s:Seq Int^many c:Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { s c t } {
    t s 40 c prim + get prim >=
    [ s ]
    [ s 200 c t tokf
      locals { kd } {
        kd 1 prim =
        [ s 400 c t tokf
          locals { x } {
            x 0 prim >= x s 0 get prim < prim and
            [ s c x ref-one ]
            [ s ]
            if
          } ]
        [ kd 3 prim =
          [ s 600 c t tokf s 800 c t tokf
            locals { y z } {
              y 0 prim >= y z prim <= prim and z s 0 get prim < prim and
              [ s c y z ref-range ]
              [ s ]
              if
            } ]
          [ s ]
          if ]
        if
        c t 1 prim + visit-toks
      } ]
    if
  };

: visit
  (forall ρ; ρ s:Seq Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s c } {
    s 60 c prim + 1 put 80 c prim + 0 put
    c 0 visit-toks
    locals { s1 } {
      s1 60 c prim + 2 put
      locals { s2 } {
        s2 80 c prim + get 0 prim =
        [ s2 140 s2 4 get prim + c put 4 s2 4 get 1 prim + put ]
        [ s2 ]
        if
      }
    }
  };

: visit-all
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 0 get prim >=
    [ s ]
    [ s 60 i prim + get 0 prim =
      [ s i visit ]
      [ s ]
      if
      i 1 prim + visit-all ]
    if
  };

: vpush
  (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s v } {
    s 160 s 2 get prim + v put 2 s 2 get 1 prim + put
  };

: popn
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } { s 2 s 2 get k prim - put };

: peek
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ v:Int^many)
  locals { s k } { s 159 s 2 get prim + k prim - get };

: apply-op
  (forall ρ; ρ s:Seq Int^many op:Int^many -- ρ r:Seq Int^many)
  locals { s op } {
    op 7 prim = [ 3 ] [ op 8 prim = [ 1 ] [ 2 ] if ] if
    locals { ar } {
      s 2 get ar prim <
      [ s 1 1 put 2 0 put ]
      [ s ar popn
        ar 1 prim =
        [ s 0 peek neg ]
        [ ar 2 prim =
          [ op s 1 peek s 0 peek compute2 ]
          [ s 2 peek s 1 peek s 0 peek ifv ]
          if ]
        if
        vpush ]
      if
    }
  };

: fn-loop
  (forall ρ; ρ s:Seq Int^many fn:Int^many i:Int^many z:Int^many acc:Int^many -- ρ r:Int^many)
  locals { s fn i z acc } {
    i z prim >
    [ acc lim ]
    [ s 100 i prim + get
      locals { v } {
        s fn i 1 prim + z
        fn 4 prim =
        [ acc v err prim = [ 0 ] [ 1 ] if prim + ]
        [ acc err prim = v err prim = prim or
          [ err ]
          [ fn 1 prim = [ acc v prim + ]
            [ fn 2 prim = [ acc v min2 ] [ acc v max2 ] if ]
            if ]
          if ]
        if
        fn-loop
      } ]
    if
  };

: fn-run
  (forall ρ; ρ s:Seq Int^many fn:Int^many y:Int^many z:Int^many -- ρ r:Int^many)
  locals { s fn y z } {
    y 0 prim >= y z prim <= prim and z s 0 get prim < prim and
    [ s fn y z
      fn 2 prim = [ 2000000000 ] [ fn 3 prim = [ -2000000000 ] [ 0 ] if ] if
      fn-loop ]
    [ err ]
    if
  };

: eval-toks
  (forall ρ; ρ s:Seq Int^many c:Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { s c t } {
    t s 40 c prim + get prim >=
    [ s ]
    [ s 200 c t tokf s 400 c t tokf s 600 c t tokf s 800 c t tokf
      locals { kd x y z } {
        kd 0 prim = [ s x vpush ]
        [ kd 1 prim =
          [ s x 0 prim >= x s 0 get prim < prim and
            [ s 100 x prim + get ] [ err ] if
            vpush ]
          [ kd 2 prim =
            [ s x apply-op ]
            [ s s x y z fn-run vpush ]
            if ]
          if ]
        if
        c t 1 prim + eval-toks
      } ]
    if
  };

: eval-cell
  (forall ρ; ρ s:Seq Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { s c } {
    s 2 0 put 1 0 put
    c 0 eval-toks
    locals { s1 } {
      s1 1 get 0 prim = s1 2 get 1 prim = prim and
      [ s1 100 c prim + s1 160 get put ]
      [ s1 ]
      if
    }
  };

: eval-order
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    k s 4 get prim >=
    [ s ]
    [ s s 140 k prim + get eval-cell k 1 prim + eval-order ]
    if
  };

: evaluate
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 4 0 put
    0 reset-cells
    0 visit-all
    0 eval-order
  };

: copy-old
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 0 get prim >=
    [ s ]
    [ s 120 i prim + s 100 i prim + get put i 1 prim + copy-old ]
    if
  };

: diff-count
  (forall ρ; ρ s:Seq Int^many i:Int^many acc:Int^many -- ρ n:Int^many)
  locals { s i acc } {
    i s 0 get prim >=
    [ acc ]
    [ s i 1 prim + acc
      s 100 i prim + get s 120 i prim + get prim = [ 0 ] [ 1 ] if
      prim + diff-count ]
    if
  };

: edit-loop
  (forall ρ; ρ s:Seq Int^many e:Int^many off:Int^many -- ρ r:Seq Int^many)
  locals { s e off } {
    e s 5 get prim >=
    [ s ]
    [ s 180 e prim + get
      s 184 e prim + get
      locals { cell ln } {
        s 20 cell prim + s 6 get off prim + put 40 cell prim + ln put
        0 copy-old
        evaluate
        locals { s1 } {
          s1 s1 0 0 diff-count prim seq-int.push
          e 1 prim + off ln prim + edit-loop
        }
      } ]
    if
  };

: pref
  (forall ρ; ρ s:Seq Int^many i:Int^many acc:Int^many -- ρ r:Seq Int^many)
  locals { s i acc } {
    i s 0 get prim >=
    [ s ]
    [ s 20 i prim + acc put i 1 prim + acc s 40 i prim + get prim + pref ]
    if
  };

: pad-to
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    s prim seq-int.len k prim >=
    [ s ]
    [ s 0 prim seq-int.push k pad-to ]
    if
  };

: append-from
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s xs i } {
    i xs prim seq-int.len prim >=
    [ s ]
    [ s xs i prim seq-int.at prim seq-int.push xs i 1 prim + append-from ]
    if
  };

: append
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many -- ρ r:Seq Int^many)
  0 append-from;

: slice-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many hi:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { s i hi acc } {
    i hi prim >=
    [ acc ]
    [ s i 1 prim + hi acc s i prim seq-int.at prim seq-int.push slice-loop ]
    if
  };

: slice
  (forall ρ; ρ s:Seq Int^many lo:Int^many hi:Int^many -- ρ r:Seq Int^many)
  locals { s lo hi } {
    s lo hi prim seq-int.empty slice-loop
  };

: vals-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { s i acc } {
    i s 0 get prim >=
    [ acc ]
    [ s i 1 prim + acc
      s 100 i prim + get dup err prim = [ drop 0 ] [ ] if
      prim seq-int.push vals-loop ]
    if
  };

: errs-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many acc:Seq Bool^many -- ρ r:Seq Bool^many)
  locals { s i acc } {
    i s 0 get prim >=
    [ acc ]
    [ s i 1 prim + acc s 100 i prim + get err prim = prim seq-bool.push errs-loop ]
    if
  };

: main
  (forall ρ; ρ lens:Seq Int^many kinds:Seq Int^many xs:Seq Int^many ys:Seq Int^many zs:Seq Int^many edit-cells:Seq Int^many edit-lens:Seq Int^many e-kinds:Seq Int^many e-xs:Seq Int^many e-ys:Seq Int^many e-zs:Seq Int^many -- ρ values:Seq Int^many errors:Seq Bool^many changed:Seq Int^many)
  locals { lens kinds xs ys zs edit-cells edit-lens e-kinds e-xs e-ys e-zs } {
    prim seq-int.empty
    lens prim seq-int.len pu 0 pu 0 pu 0 pu 0 pu
    edit-cells prim seq-int.len pu
    kinds prim seq-int.len pu
    40 pad-to lens append
    180 pad-to edit-cells append
    184 pad-to edit-lens append
    200 pad-to kinds append e-kinds append
    400 pad-to xs append e-xs append
    600 pad-to ys append e-ys append
    800 pad-to zs append e-zs append
    1000 pad-to
    0 0 pref
    evaluate
    0 0 edit-loop
    locals { s } {
      s 0 prim seq-int.empty vals-loop
      s 0 prim seq-bool.empty errs-loop
      s 1000 s prim seq-int.len slice
    }
  };
```

### task: blackjack
```firth
: get
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many)
  prim seq-int.at;

: put
  (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.set;

: pu
  (forall ρ; ρ s:Seq Int^many v:Int^many -- ρ r:Seq Int^many)
  prim seq-int.push;

: b2i
  (forall ρ; ρ b:Bool^many -- ρ n:Int^many)
  [ 1 ] [ 0 ] if;

: tt
  (forall ρ; ρ -- ρ b:Bool^many)
  0 0 prim =;

: ff
  (forall ρ; ρ -- ρ b:Bool^many)
  0 1 prim =;

: cv
  (forall ρ; ρ r:Int^many -- ρ v:Int^many)
  dup 10 prim > [ drop 10 ] [ ] if;

: htotal
  (forall ρ; ρ sm:Int^many ac:Int^many -- ρ t:Int^many)
  locals { sm ac } {
    ac 0 prim > sm 10 prim + 21 prim <= prim and
    [ sm 10 prim + ] [ sm ] if
  };

: hsoft
  (forall ρ; ρ sm:Int^many ac:Int^many -- ρ b:Bool^many)
  locals { sm ac } {
    ac 0 prim > sm 10 prim + 21 prim <= prim and
  };

: draw
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 0 get s 4 get prim >=
    [ s 1 1 put 2 1 put ]
    [ s 2 s 100 s 0 get prim + get put 0 s 0 get 1 prim + put ]
    if
  };

: draw-to
  (forall ρ; ρ s:Seq Int^many idx:Int^many -- ρ r:Seq Int^many)
  locals { s idx } {
    s draw
    locals { s1 } { s1 idx s1 2 get put }
  };

: add-card
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s draw
    locals { s1 } {
      s1 15 s1 15 get s1 2 get cv prim + put
         16 s1 16 get s1 2 get 1 prim = b2i prim + put
         17 s1 17 get 1 prim + put
    }
  };

: dealer-add
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s draw
    locals { s1 } {
      s1 9 s1 9 get s1 2 get cv prim + put
         10 s1 10 get s1 2 get 1 prim = b2i prim + put
    }
  };

: want
  (forall ρ; ρ s:Seq Int^many -- ρ b:Bool^many)
  locals { s } {
    s 15 get s 16 get htotal
    locals { t } {
      t 21 prim >
      [ ff ]
      [ s 15 get s 16 get hsoft
        [ t 17 prim <= ]
        [ t 11 prim <=
          t 12 prim >= t 16 prim <= prim and
          s 8 get 1 prim = s 8 get 7 prim >= prim or
          prim and
          prim or ]
        if ]
      if
    }
  };

: hit-loop
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 1 get 0 prim = s want prim and
    [ s add-card hit-loop ]
    [ s ]
    if
  };

: finish-hand
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    s 11 get
    locals { k } {
      s 60 k prim + i put
        70 k prim + s 15 get s 16 get htotal put
        80 k prim + s 18 get put
        11 k 1 prim + put
    }
  };

: play-hand
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    s 15 get s 16 get htotal
    locals { t } {
      s 17 get 2 prim =
      s 15 get s 16 get hsoft prim not prim and
      t 10 prim = t 11 prim = prim or prim and
      s 8 get 2 prim >= s 8 get 9 prim <= prim and prim and
      s 20 i prim + get s 14 get s 25 i prim + get prim + prim >= prim and
      [ s add-card
        18 s 18 get 2 prim * put
        14 s 14 get s 18 get prim + put
        i finish-hand ]
      [ s hit-loop i finish-hand ]
      if
    }
  };

: setup-hand
  (forall ρ; ρ s:Seq Int^many c:Int^many bet:Int^many -- ρ r:Seq Int^many)
  locals { s c bet } {
    s 15 c cv put 16 c 1 prim = b2i put 17 1 put 18 bet put
  };

: load-hand
  (forall ρ; ρ s:Seq Int^many sm:Int^many ac:Int^many bet:Int^many -- ρ r:Seq Int^many)
  locals { s sm ac bet } {
    s 15 sm put 16 ac put 17 2 put 18 bet put
  };

: play-split
  (forall ρ; ρ s:Seq Int^many i:Int^many c1:Int^many c2:Int^many bet:Int^many -- ρ r:Seq Int^many)
  locals { s i c1 c2 bet } {
    s 14 bet 2 prim * put c1 bet setup-hand add-card
    locals { s1 } {
      s1 90 s1 15 get put 91 s1 16 get put
      c2 bet setup-hand add-card
      locals { s2 } {
        s2 92 s2 15 get put 93 s2 16 get put
        locals { s2b } {
          s2b s2b 90 get s2b 91 get bet load-hand
          c1 1 prim = [ i finish-hand ] [ i play-hand ] if
          locals { s3 } {
            s3 s3 92 get s3 93 get bet load-hand
            c2 1 prim = [ i finish-hand ] [ i play-hand ] if
          }
        }
      }
    }
  };

: play-single
  (forall ρ; ρ s:Seq Int^many i:Int^many c1:Int^many c2:Int^many bet:Int^many -- ρ r:Seq Int^many)
  locals { s i c1 c2 bet } {
    s 14 bet put
      15 c1 cv c2 cv prim + put
      16 c1 1 prim = b2i c2 1 prim = b2i prim + put
      17 2 put
      18 bet put
    i play-hand
  };

: play-player
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    s 45 i prim + get
    s 50 i prim + get
    s 25 i prim + get
    locals { c1 c2 bet } {
      c1 c2 prim = c1 1 prim = c1 8 prim = prim or prim and
      s 20 i prim + get bet 2 prim * prim >= prim and
      [ s i c1 c2 bet play-split ]
      [ s i c1 c2 bet play-single ]
      if
    }
  };

: tp-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 35 i prim + s 20 i prim + get s 25 i prim + get prim >= b2i put
      i 1 prim + tp-loop ]
    if
  };

: sum-range
  (forall ρ; ρ s:Seq Int^many base:Int^many i:Int^many acc:Int^many -- ρ n:Int^many)
  locals { s base i acc } {
    i s 3 get prim >=
    [ acc ]
    [ s base i 1 prim + acc s base i prim + get prim + sum-range ]
    if
  };

: zero-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 30 i prim + 0 put 40 i prim + 0 put i 1 prim + zero-loop ]
    if
  };

: deal-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many base:Int^many -- ρ r:Seq Int^many)
  locals { s i base } {
    i s 3 get prim >=
    [ s ]
    [ s 35 i prim + get 1 prim =
      [ s base i prim + draw-to ]
      [ s ]
      if
      i 1 prim + base deal-loop ]
    if
  };

: nat-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 45 i prim + get s 50 i prim + get
      locals { c1 c2 } {
        s 40 i prim +
        s 35 i prim + get 1 prim =
        c1 cv c2 cv prim + c1 1 prim = b2i c2 1 prim = b2i prim + htotal 21 prim =
        prim and b2i put
      }
      i 1 prim + nat-loop ]
    if
  };

: dn-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 35 i prim + get 1 prim =
      [ s 40 i prim + get 1 prim =
        [ s ]
        [ s 30 i prim + 0 s 25 i prim + get prim - put ]
        if ]
      [ s ]
      if
      i 1 prim + dn-loop ]
    if
  };

: players-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 35 i prim + get 1 prim =
      [ s 40 i prim + get 1 prim =
        [ s 30 i prim + s 25 i prim + get 3 prim * 2 prim div put ]
        [ s i play-player ]
        if ]
      [ s ]
      if
      i 1 prim + players-loop ]
    if
  };

: live
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ b:Bool^many)
  locals { s k } {
    k s 11 get prim >=
    [ ff ]
    [ s 70 k prim + get 21 prim <=
      [ tt ]
      [ s k 1 prim + live ]
      if ]
    if
  };

: dealer-loop
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 1 get 0 prim = s 9 get s 10 get htotal 17 prim < prim and
    [ s dealer-add dealer-loop ]
    [ s ]
    if
  };

: settle-loop
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    k s 11 get prim >=
    [ s ]
    [ s 70 k prim + get
      s 80 k prim + get
      s 9 get s 10 get htotal
      locals { t stake d } {
        s 30 s 60 k prim + get prim +
        s 30 s 60 k prim + get prim + get
        t 21 prim >
        [ 0 stake prim - ]
        [ d 21 prim > d t prim < prim or
          [ stake ]
          [ d t prim > [ 0 stake prim - ] [ 0 ] if ]
          if ]
        if
        prim + put
        k 1 prim + settle-loop
      } ]
    if
  };

: apply-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s i } {
    i s 3 get prim >=
    [ s ]
    [ s 20 i prim + s 20 i prim + get s 30 i prim + get prim + put
      i 1 prim + apply-loop ]
    if
  };

: complete
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 0 apply-loop
    locals { s1 } {
      s1 5 s1 5 get 1 prim + put
         7 s1 7 get s1 40 0 0 sum-range prim + put
         6 s1 6 get s1 9 get s1 10 get htotal 21 prim > b2i prim + put
    }
  };

: round-main
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 9 s 8 get cv s 13 get cv prim + put
      10 s 8 get 1 prim = b2i s 13 get 1 prim = b2i prim + put
    0 nat-loop
    locals { s1 } {
      s1 9 get s1 10 get htotal 21 prim =
      [ s1 0 dn-loop complete ]
      [ s1 0 players-loop
        locals { s2 } {
          s2 0 live
          [ s2 dealer-loop ]
          [ s2 ]
          if
          0 settle-loop
          locals { s3 } {
            s3 1 get 1 prim =
            [ s3 12 1 put ]
            [ s3 complete ]
            if
          }
        } ]
      if
    }
  };

: do-round
  (forall ρ; ρ s:Seq Int^many -- ρ r:Seq Int^many)
  locals { s } {
    s 1 0 put 11 0 put
    0 zero-loop
    0 45 deal-loop
    8 draw-to
    0 50 deal-loop
    13 draw-to
    locals { s1 } {
      s1 1 get 1 prim =
      [ s1 12 1 put ]
      [ s1 round-main ]
      if
    }
  };

: game
  (forall ρ; ρ s:Seq Int^many r:Int^many -- ρ q:Seq Int^many)
  locals { s r } {
    s 12 get 0 prim = r s 19 get prim < prim and
    [ s 0 tp-loop
      locals { s1 } {
        s1 35 0 0 sum-range 0 prim >
        [ s1 do-round r 1 prim + game ]
        [ s1 ]
        if
      } ]
    [ s ]
    if
  };

: pad-to
  (forall ρ; ρ s:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { s k } {
    s prim seq-int.len k prim >=
    [ s ]
    [ s 0 prim seq-int.push k pad-to ]
    if
  };

: append-from
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { s xs i } {
    i xs prim seq-int.len prim >=
    [ s ]
    [ s xs i prim seq-int.at prim seq-int.push xs i 1 prim + append-from ]
    if
  };

: append
  (forall ρ; ρ s:Seq Int^many xs:Seq Int^many -- ρ r:Seq Int^many)
  0 append-from;

: slice-loop
  (forall ρ; ρ s:Seq Int^many i:Int^many hi:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { s i hi acc } {
    i hi prim >=
    [ acc ]
    [ s i 1 prim + hi acc s i prim seq-int.at prim seq-int.push slice-loop ]
    if
  };

: slice
  (forall ρ; ρ s:Seq Int^many lo:Int^many hi:Int^many -- ρ r:Seq Int^many)
  locals { s lo hi } {
    s lo hi prim seq-int.empty slice-loop
  };

: main
  (forall ρ; ρ shoe:Seq Int^many bankrolls:Seq Int^many bets:Seq Int^many rounds:Int^many -- ρ final:Seq Int^many rounds-played:Int^many dealer-busts:Int^many naturals:Int^many)
  locals { shoe bankrolls bets rounds } {
    prim seq-int.empty
    0 pu 0 pu 0 pu
    bankrolls prim seq-int.len pu
    shoe prim seq-int.len pu
    0 pu 0 pu 0 pu
    0 pu 0 pu 0 pu 0 pu 0 pu 0 pu 0 pu 0 pu 0 pu 0 pu 0 pu
    rounds pu
    20 pad-to bankrolls append
    25 pad-to bets append
    100 pad-to shoe append
    0 game
    locals { s } {
      s 20 20 s 3 get prim + slice
      s 5 get
      s 6 get
      s 7 get
    }
  };
```

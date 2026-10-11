### task: sokoban
```firth
: add
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int)
  locals { s i v } { s i s i prim seq-int.at v prim + prim seq-int.set };

: zs
  (forall ρ; ρ xs:Seq Int n:Int -- ρ r:Seq Int)
  locals { xs n } { n 0 prim > [ xs 0 prim seq-int.push n 1 prim - zs ] [ xs ] if };

: delta
  (forall ρ; ρ w:Int d:Int -- ρ r:Int)
  locals { w d } {
    d 0 prim = [ 0 w prim - ]
    [ d 1 prim = [ 1 ] [ d 2 prim = [ w ] [ -1 ] if ] if ] if };

: fb
  (forall ρ; ρ s:Seq Int c:Int k:Int -- ρ r:Int)
  locals { s c k } {
    k s 7 prim seq-int.at prim <
    [ s 10 k prim + prim seq-int.at c prim =
      [ k ] [ s c k 1 prim + fb ] if ]
    [ -1 ] if };

: dead
  (forall ρ; ρ cells:Seq Int u:Int w:Int -- ρ r:Bool)
  locals { cells u w } {
    cells u prim seq-int.at 2 prim = prim not
    cells u w prim - prim seq-int.at 1 prim =
    cells u w prim + prim seq-int.at 1 prim = prim or prim and
    cells u 1 prim - prim seq-int.at 1 prim =
    cells u 1 prim + prim seq-int.at 1 prim = prim or prim and };

: allg
  (forall ρ; ρ cells:Seq Int s:Seq Int k:Int -- ρ r:Bool)
  locals { cells s k } {
    k s 7 prim seq-int.at prim <
    [ cells s 10 k prim + prim seq-int.at prim seq-int.at 2 prim =
      [ cells s k 1 prim + allg ] [ false ] if ]
    [ true ] if };

: rec
  (forall ρ; ρ s:Seq Int code:Int -- ρ r:Seq Int)
  locals { s code } {
    s 20 s 1 prim seq-int.at prim + code prim seq-int.set 1 1 add };

: dopush
  (forall ρ; ρ w:Int cells:Seq Int m:Int s:Seq Int k:Int t:Int u:Int -- ρ r:Seq Int)
  locals { w cells m s k t u } {
    s 10 k prim + u prim seq-int.set
    0 t prim seq-int.set
    2 1 add
    cells u w dead [ 5 1 add ] [ ] if
    m 2 prim * 1 prim + rec };

: go
  (forall ρ; ρ w:Int cells:Seq Int m:Int s:Seq Int -- ρ r:Seq Int)
  locals { w cells m s } {
    s 0 prim seq-int.at w m delta prim +
    locals { t } {
      cells t prim seq-int.at 1 prim =
      [ s 3 1 add ]
      [ s t 0 fb
        locals { k } {
          k 0 prim <
          [ s 0 t prim seq-int.set m 2 prim * rec ]
          [ t w m delta prim +
            locals { u } {
              cells u prim seq-int.at 1 prim =
              s u 0 fb 0 prim >= prim or
              [ s 3 1 add ]
              [ w cells m s k t u dopush ] if } ] if } ] if } };

: unbox
  (forall ρ; ρ s:Seq Int a:Int b:Int -- ρ r:Seq Int)
  locals { s a b } { s 10 s a 0 fb prim + b prim seq-int.set };

: undo2
  (forall ρ; ρ s:Seq Int h:Int w:Int -- ρ r:Seq Int)
  locals { s h w } {
    s 20 h prim + prim seq-int.at
    locals { code } {
      w code 2 prim div delta
      s 0 prim seq-int.at
      locals { dl p } {
        s 0 p dl prim - prim seq-int.set
        1 h prim seq-int.set
        4 1 add
        code 2 prim mod 1 prim =
        [ p dl prim + p unbox ] [ ] if } } };

: undo
  (forall ρ; ρ w:Int s:Seq Int -- ρ r:Seq Int)
  locals { w s } {
    s 1 prim seq-int.at 0 prim >
    [ s s 1 prim seq-int.at 1 prim - w undo2 ]
    [ s ] if };

: domove
  (forall ρ; ρ w:Int cells:Seq Int moves:Seq Int s:Seq Int -- ρ r:Seq Int)
  locals { w cells moves s } {
    moves s 6 prim seq-int.at prim seq-int.at
    s 6 1 add
    locals { m s1 } {
      m 4 prim =
      [ w s1 undo ]
      [ w cells m s1 go ] if } };

: play
  (forall ρ; ρ w:Int cells:Seq Int moves:Seq Int s:Seq Int -- ρ r:Seq Int)
  locals { w cells moves s } {
    s 6 prim seq-int.at moves prim seq-int.len prim <
    cells s 0 allg prim not prim and
    [ w cells moves w cells moves s domove play ]
    [ s ] if };

: cp
  (forall ρ; ρ s:Seq Int bx:Seq Int k:Int -- ρ r:Seq Int)
  locals { s bx k } {
    k bx prim seq-int.len prim <
    [ s 10 k prim + bx k prim seq-int.at prim seq-int.set bx k 1 prim + cp ]
    [ s ] if };

: gb
  (forall ρ; ρ s:Seq Int k:Int out:Seq Int -- ρ r:Seq Int)
  locals { s k out } {
    k s 7 prim seq-int.at prim <
    [ s k 1 prim + out s 10 k prim + prim seq-int.at prim seq-int.push gb ]
    [ out ] if };

: main
  (forall ρ; ρ width:Int height:Int cells:Seq Int player:Int boxes:Seq Int moves:Seq Int
   -- ρ p:Int bx:Seq Int rd:Int hist:Int pushes:Int blocked:Int undos:Int dd:Int solved:Bool)
  locals { width height cells player boxes moves } {
    prim seq-int.empty 220 zs
    0 player prim seq-int.set
    7 boxes prim seq-int.len prim seq-int.set
    boxes 0 cp
    locals { s0 } {
      width cells moves s0 play
      locals { s } {
        s 0 prim seq-int.at
        s 0 prim seq-int.empty gb
        s 6 prim seq-int.at
        s 1 prim seq-int.at
        s 2 prim seq-int.at
        s 3 prim seq-int.at
        s 4 prim seq-int.at
        s 5 prim seq-int.at
        cells s 0 allg } } };
```

### task: checkers
```firth
: add
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int)
  locals { s i v } { s i s i prim seq-int.at v prim + prim seq-int.set };

: tbl
  (forall ρ; ρ -- ρ t:Seq Int)
  { -1 -1 4 5  -1 -1 5 6  -1 -1 6 7  -1 -1 7 -1
    -1 0 -1 8  0 1 8 9  1 2 9 10  2 3 10 11
    4 5 12 13  5 6 13 14  6 7 14 15  7 -1 15 -1
    -1 8 -1 16  8 9 16 17  9 10 17 18  10 11 18 19
    12 13 20 21  13 14 21 22  14 15 22 23  15 -1 23 -1
    -1 16 -1 24  16 17 24 25  17 18 25 26  18 19 26 27
    20 21 28 29  21 22 29 30  22 23 30 31  23 -1 31 -1
    -1 24 -1 -1  24 25 -1 -1  25 26 -1 -1  26 27 -1 -1 };

: app
  (forall ρ; ρ b:Seq Int t:Seq Int k:Int -- ρ r:Seq Int)
  locals { b t k } {
    k 128 prim <
    [ b t k prim seq-int.at prim seq-int.push t k 1 prim + app ]
    [ b ] if };

: fst
  (forall ρ; ρ b:Seq Int k:Int out:Seq Int -- ρ r:Seq Int)
  locals { b k out } {
    k 32 prim <
    [ b k 1 prim + out b k prim seq-int.at prim seq-int.push fst ]
    [ out ] if };

: side
  (forall ρ; ρ p:Int -- ρ s:Int)
  2 prim > [ 1 ] [ 0 ] if;

: allowed
  (forall ρ; ρ pc:Int d:Int -- ρ r:Bool)
  locals { pc d } {
    pc 1 prim = [ d 2 prim < ]
    [ pc 3 prim = [ d 1 prim > ] [ true ] if ] if };

: nb
  (forall ρ; ρ b:Seq Int i:Int d:Int -- ρ j:Int)
  locals { b i d } { b 32 i 4 prim * prim + d prim + prim seq-int.at };

: jl2
  (forall ρ; ρ b:Seq Int m:Int pc:Int d:Int -- ρ l:Int)
  locals { b m pc d } {
    b m prim seq-int.at
    locals { q } {
      q 0 prim > q side pc side prim = prim not prim and
      [ b m d nb
        locals { l } {
          l 0 prim >=
          [ b l prim seq-int.at 0 prim = [ l ] [ -1 ] if ]
          [ -1 ] if } ]
      [ -1 ] if } };

: jl
  (forall ρ; ρ b:Seq Int pos:Int pc:Int d:Int -- ρ l:Int)
  locals { b pos pc d } {
    pc d allowed
    [ b pos d nb
      locals { m } {
        m 0 prim >=
        [ b m pc d jl2 ] [ -1 ] if } ]
    [ -1 ] if };

: canj
  (forall ρ; ρ b:Seq Int pos:Int pc:Int -- ρ r:Bool)
  locals { b pos pc } {
    b pos pc 0 jl 0 prim >=
    b pos pc 1 jl 0 prim >= prim or
    b pos pc 2 jl 0 prim >= prim or
    b pos pc 3 jl 0 prim >= prim or };

: upd
  (forall ρ; ρ bs:Seq Int bb:Seq Int b:Seq Int cnt:Int crown:Int -- ρ r1:Seq Int r2:Seq Int)
  locals { bs bb b cnt crown } {
    cnt bs 0 prim seq-int.at prim >
    [ prim seq-int.empty cnt prim seq-int.push crown prim seq-int.push b ]
    [ bs bb ] if };

: dd
  (forall ρ; ρ bs:Seq Int bb:Seq Int b:Seq Int pos:Int pc:Int cnt:Int d:Int -- ρ r1:Seq Int r2:Seq Int)
  locals { bs bb b pos pc cnt d } {
    b pos pc d jl
    locals { l } {
      l 0 prim >=
      [ b b pos d nb 0 prim seq-int.set
        locals { b2 } {
          pc 1 prim = l 4 prim < prim and
          pc 3 prim = l 27 prim > prim and prim or
          [ bs bb b2 l pc 1 prim + prim seq-int.set cnt 1 prim + 1 upd ]
          [ bs bb b2 l pc cnt 1 prim + dfs ] if } ]
      [ bs bb ] if } };

: dfs
  (forall ρ; ρ bs:Seq Int bb:Seq Int b:Seq Int pos:Int pc:Int cnt:Int -- ρ r1:Seq Int r2:Seq Int)
  locals { bs bb b pos pc cnt } {
    b pos pc canj
    [ bs bb b pos pc cnt 0 dd  b pos pc cnt 1 dd  b pos pc cnt 2 dd  b pos pc cnt 3 dd ]
    [ bs bb b pos pc prim seq-int.set cnt 0 upd ] if };

: scan
  (forall ρ; ρ sd:Int bs:Seq Int bb:Seq Int b:Seq Int s:Int -- ρ r1:Seq Int r2:Seq Int)
  locals { sd bs bb b s } {
    s 32 prim <
    [ b s prim seq-int.at
      locals { pc } {
        pc 0 prim > pc side sd prim = prim and
        [ bs bb b s 0 prim seq-int.set s pc 0 dfs
          locals { bs2 bb2 } { sd bs2 bb2 b s 1 prim + scan } ]
        [ sd bs bb b s 1 prim + scan ] if } ]
    [ bs bb ] if };

: td
  (forall ρ; ρ b:Seq Int s:Int pc:Int d:Int -- ρ to:Int)
  locals { b s pc d } {
    pc d allowed
    [ b s d nb
      locals { t } {
        t 0 prim >=
        [ b t prim seq-int.at 0 prim = [ t ] [ -1 ] if ]
        [ -1 ] if } ]
    [ -1 ] if };

: st
  (forall ρ; ρ b:Seq Int s:Int pc:Int d:Int -- ρ to:Int)
  locals { b s pc d } {
    d 4 prim <
    [ b s pc d td
      locals { r } { r 0 prim >= [ r ] [ b s pc d 1 prim + st ] if } ]
    [ -1 ] if };

: fs
  (forall ρ; ρ sd:Int b:Seq Int s:Int -- ρ from:Int to:Int)
  locals { sd b s } {
    s 32 prim <
    [ b s prim seq-int.at
      locals { pc } {
        pc 0 prim > pc side sd prim = prim and
        [ b s pc 0 st
          locals { t } { t 0 prim >= [ s t ] [ sd b s 1 prim + fs ] if } ]
        [ sd b s 1 prim + fs ] if } ]
    [ -1 -1 ] if };

: capg
  (forall ρ; ρ g:Seq Int bs:Seq Int sd:Int -- ρ r:Seq Int)
  locals { g bs sd } {
    g 1 1 add
    2 sd prim + bs 0 prim seq-int.at add
    4 bs 1 prim seq-int.at add
    0 1 sd prim - prim seq-int.set };

: stepg
  (forall ρ; ρ g:Seq Int sd:Int f:Int t:Int b:Seq Int -- ρ g2:Seq Int b2:Seq Int)
  locals { g sd f t b } {
    b f prim seq-int.at
    locals { pc } {
      pc 1 prim = t 4 prim < prim and
      pc 3 prim = t 27 prim > prim and prim or
      locals { cr } {
        g 1 1 add
        4 cr [ 1 ] [ 0 ] if add
        0 1 sd prim - prim seq-int.set
        b f 0 prim seq-int.set
        t pc cr [ 1 ] [ 0 ] if prim +
        prim seq-int.set } } };

: game
  (forall ρ; ρ g:Seq Int b:Seq Int plies:Int -- ρ g2:Seq Int b2:Seq Int)
  locals { g b plies } {
    g 0 prim seq-int.at
    locals { sd } {
      sd prim seq-int.empty 0 prim seq-int.push 0 prim seq-int.push b b 0 scan
      locals { bs bb } {
        bs 0 prim seq-int.at 0 prim >
        [ g 1 prim seq-int.at plies prim >=
          [ g b ]
          [ g bs sd capg bb plies game ] if ]
        [ sd b 0 fs
          locals { f t } {
            t 0 prim >=
            [ g 1 prim seq-int.at plies prim >=
              [ g b ]
              [ g sd f t b stepg plies game ] if ]
            [ g 5 sd 0 prim = [ 2 ] [ 1 ] if prim seq-int.set b ] if } ] if } } };

: main
  (forall ρ; ρ board:Seq Int turn:Int plies:Int
   -- ρ board2:Seq Int played:Int wt:Int bt:Int cr:Int res:Int)
  locals { board turn plies } {
    prim seq-int.empty turn prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    board tbl 0 app
    plies game
    locals { g b } {
      b 0 prim seq-int.empty fst
      g 1 prim seq-int.at g 2 prim seq-int.at g 3 prim seq-int.at
      g 4 prim seq-int.at g 5 prim seq-int.at } };
```

### task: regex
```firth
: add
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int)
  locals { s i v } { s i s i prim seq-int.at v prim + prim seq-int.set };

: cat
  (forall ρ; ρ a:Seq Int b:Seq Int k:Int -- ρ r:Seq Int)
  locals { a b k } {
    k b prim seq-int.len prim <
    [ a b k prim seq-int.at prim seq-int.push b k 1 prim + cat ]
    [ a ] if };

: padn
  (forall ρ; ρ xs:Seq Int v:Int n:Int -- ρ r:Seq Int)
  locals { xs v n } {
    n 0 prim > [ xs v prim seq-int.push v n 1 prim - padn ] [ xs ] if };

: fb13
  (forall ρ; ρ xs:Seq Bool n:Int -- ρ r:Seq Bool)
  locals { xs n } { n 0 prim > [ xs false prim seq-bool.push n 1 prim - fb13 ] [ xs ] if };

: nsb
  (forall ρ; ρ -- ρ r:Seq Bool)
  prim seq-bool.empty 13 fb13;

: tk
  (forall ρ; ρ cx:Seq Int i:Int -- ρ t:Int)
  locals { cx i } { cx 2 i prim + prim seq-int.at };

: mp2
  (forall ρ; ρ cx:Seq Int i:Int d:Int -- ρ q:Int)
  locals { cx i d } {
    cx i tk
    locals { t } {
      t 31 prim = [ cx i 1 prim + d 1 prim + mp2 ]
      [ t 32 prim =
        [ d 1 prim = [ i ] [ cx i 1 prim + d 1 prim - mp2 ] if ]
        [ cx i 1 prim + d mp2 ] if ] if } };

: mp
  (forall ρ; ρ cx:Seq Int p:Int -- ρ q:Int)
  locals { cx p } { cx p 1 prim + 1 mp2 };

: vops
  (forall ρ; ρ cx:Seq Int j:Int -- ρ r:Int)
  locals { cx j } {
    cx j tk
    locals { t } {
      t 27 prim >= t 29 prim <= prim and
      [ cx j 1 prim + vops ] [ j ] if } };

: vitem
  (forall ρ; ρ cx:Seq Int i:Int -- ρ r:Int)
  locals { cx i } {
    cx i tk 31 prim =
    [ cx i 1 prim + valt
      locals { j } {
        j 0 prim <
        [ -1 ]
        [ cx j tk 32 prim = [ cx j 1 prim + vops ] [ -1 ] if ] if } ]
    [ cx i 1 prim + vops ] if };

: vseq
  (forall ρ; ρ cx:Seq Int i:Int -- ρ r:Int)
  locals { cx i } {
    cx i tk
    locals { t } {
      t 26 prim <= t 31 prim = prim or
      [ cx i vitem
        locals { j } { j 0 prim < [ -1 ] [ cx j vseq ] if } ]
      [ i ] if } };

: valt
  (forall ρ; ρ cx:Seq Int i:Int -- ρ r:Int)
  locals { cx i } {
    cx i vseq
    locals { j } {
      j 0 prim <
      [ -1 ]
      [ cx j tk 30 prim = [ cx j 1 prim + valt ] [ j ] if ] if } };

: nxt
  (forall ρ; ρ cx:Seq Int p:Int hi:Int -- ρ q:Int)
  locals { cx p hi } {
    p hi prim <
    [ cx p tk
      locals { t } {
        t 30 prim =
        [ p ]
        [ t 31 prim = [ cx p mp 1 prim + ] [ p 1 prim + ] if
          locals { p2 } { cx p2 hi nxt } ] if } ]
    [ hi ] if };

: iend
  (forall ρ; ρ cx:Seq Int lo:Int -- ρ e:Int)
  locals { cx lo } {
    cx lo tk 31 prim = [ cx lo mp 1 prim + ] [ lo 1 prim + ] if
    locals { a } { cx a vops } };

: un
  (forall ρ; ρ r:Seq Bool t:Seq Bool k:Int -- ρ r2:Seq Bool)
  locals { r t k } {
    k 13 prim <
    [ r k r k prim seq-bool.at t k prim seq-bool.at prim or prim seq-bool.set t k 1 prim + un ]
    [ r ] if };

: mx
  (forall ρ; ρ r:Seq Bool k:Int -- ρ m:Int)
  locals { r k } {
    k 0 prim <
    [ -1 ]
    [ r k prim seq-bool.at [ k ] [ r k 1 prim - mx ] if ] if };

: atom
  (forall ρ; ρ cx:Seq Int lo:Int a:Int r:Seq Bool j:Int -- ρ r2:Seq Bool)
  locals { cx lo a r j } {
    cx lo tk
    locals { t } {
      t 31 prim =
      [ cx lo 1 prim + a 1 prim - r j ev-alt ]
      [ j cx 0 prim seq-int.at prim <
        [ t 26 prim =
          cx 25 cx 24 prim seq-int.at prim + j prim + prim seq-int.at t prim = prim or
          [ r j 1 prim + true prim seq-bool.set ] [ r ] if ]
        [ r ] if ] if } };

: sw
  (forall ρ; ρ cx:Seq Int lo:Int e:Int t:Seq Bool k:Int -- ρ r:Seq Bool)
  locals { cx lo e t k } {
    k 13 prim <
    [ t k prim seq-bool.at
      [ cx lo e t k ie
        locals { t2 } { cx lo e t2 k 1 prim + sw } ]
      [ cx lo e t k 1 prim + sw ] if ]
    [ t ] if };

: ie
  (forall ρ; ρ cx:Seq Int lo:Int e:Int r:Seq Bool j:Int -- ρ r2:Seq Bool)
  locals { cx lo e r j } {
    cx lo tk 31 prim = [ cx lo mp 1 prim + ] [ lo 1 prim + ] if
    locals { a } {
      e a prim =
      [ cx lo a r j atom ]
      [ cx e 1 prim - tk
        locals { op } {
          op 29 prim =
          [ r j true prim seq-bool.set
            locals { r2 } { cx lo e 1 prim - r2 j ie } ]
          [ op 27 prim =
            [ cx lo e 1 prim - nsb j true prim seq-bool.set j sw
              locals { t } { r t 0 un } ]
            [ cx lo e 1 prim - nsb j ie
              locals { t } {
                cx lo e 1 prim - t j sw
                locals { t3 } { r t3 0 un } } ] if ] if } ] if } };

: apl
  (forall ρ; ρ cx:Seq Int lo:Int e:Int s:Seq Bool t:Seq Bool k:Int -- ρ r:Seq Bool)
  locals { cx lo e s t k } {
    k 13 prim <
    [ s k prim seq-bool.at
      [ cx lo e t k ie
        locals { t2 } { cx lo e s t2 k 1 prim + apl } ]
      [ cx lo e s t k 1 prim + apl ] if ]
    [ t ] if };

: sl
  (forall ρ; ρ cx:Seq Int lo:Int hi:Int s:Seq Bool -- ρ r:Seq Bool)
  locals { cx lo hi s } {
    lo hi prim <
    [ cx lo iend
      locals { e } {
        cx lo e s nsb 0 apl
        locals { t2 } { cx e hi t2 sl } } ]
    [ s ] if };

: ev-seq
  (forall ρ; ρ cx:Seq Int lo:Int hi:Int r:Seq Bool i:Int -- ρ r2:Seq Bool)
  locals { cx lo hi r i } {
    nsb i true prim seq-bool.set
    locals { s0 } {
      cx lo hi s0 sl
      locals { s1 } { r s1 0 un } } };

: ev-alt
  (forall ρ; ρ cx:Seq Int lo:Int hi:Int r:Seq Bool i:Int -- ρ r2:Seq Bool)
  locals { cx lo hi r i } {
    cx lo hi nxt
    locals { q } {
      cx lo q r i ev-seq
      locals { r3 } {
        q hi prim <
        [ cx q 1 prim + hi r3 i ev-alt ]
        [ r3 ] if } } };

: strs
  (forall ρ; ρ cx:Seq Int lens:Seq Int j:Int full:Seq Bool lg:Seq Int st:Seq Int
   -- ρ f2:Seq Bool l2:Seq Int s2:Seq Int)
  locals { cx lens j full lg st } {
    j lens prim seq-int.len prim <
    [ lens j prim seq-int.at
      locals { n } {
        cx 0 n prim seq-int.set 24 st 0 prim seq-int.at prim seq-int.set
        locals { cx2 } {
          cx2 0 cx2 1 prim seq-int.at nsb 0 ev-alt
          locals { r } {
            cx2 lens j 1 prim +
            full r n prim seq-bool.at prim seq-bool.push
            lg r n mx prim seq-int.push
            st 0 n add 1 r n prim seq-bool.at [ 1 ] [ 0 ] if add
            strs } } } ]
    [ full lg st ] if };

: inv
  (forall ρ; ρ lens:Seq Int j:Int full:Seq Bool lg:Seq Int -- ρ f2:Seq Bool l2:Seq Int)
  locals { lens j full lg } {
    j lens prim seq-int.len prim <
    [ lens j 1 prim + full false prim seq-bool.push lg -1 prim seq-int.push inv ]
    [ full lg ] if };

: main
  (forall ρ; ρ pat:Seq Int lens:Seq Int chars:Seq Int
   -- ρ full:Seq Bool longest:Seq Int count:Int valid:Bool)
  locals { pat lens chars } {
    prim seq-int.empty 0 prim seq-int.push pat prim seq-int.len prim seq-int.push
    pat 0 cat
    99 22 pat prim seq-int.len prim - padn
    0 prim seq-int.push
    chars 0 cat
    locals { cx } {
      cx 0 valt pat prim seq-int.len prim =
      [ cx lens 0 prim seq-bool.empty prim seq-int.empty
        prim seq-int.empty 0 prim seq-int.push 0 prim seq-int.push strs
        locals { f l st } { f l st 1 prim seq-int.at true } ]
      [ lens 0 prim seq-bool.empty prim seq-int.empty inv 0 false ] if } };
```

### task: swiss
```firth
: add
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int)
  locals { s i v } { s i s i prim seq-int.at v prim + prim seq-int.set };

: zs
  (forall ρ; ρ xs:Seq Int n:Int -- ρ r:Seq Int)
  locals { xs n } { n 0 prim > [ xs 0 prim seq-int.push n 1 prim - zs ] [ xs ] if };

: ord
  (forall ρ; ρ x:Int y:Int rest:Bool -- ρ r:Bool)
  locals { x y rest } { x y prim = [ rest ] [ x y prim > ] if };

: bef
  (forall ρ; ρ s:Seq Int a:Int b:Int -- ρ r:Bool)
  locals { s a b } {
    s a prim seq-int.at s b prim seq-int.at
    s 232 a prim + prim seq-int.at s 232 b prim + prim seq-int.at
    s 220 a prim + prim seq-int.at s 220 b prim + prim seq-int.at
    a b prim <
    ord ord ord };

: bub
  (forall ρ; ρ s:Seq Int j:Int -- ρ r:Seq Int)
  locals { s j } {
    j 0 prim >
    [ s 192 j prim + prim seq-int.at  s 192 j prim + 1 prim - prim seq-int.at
      locals { a b } {
        s a b bef
        [ s 192 j prim + b prim seq-int.set 192 j prim + 1 prim - a prim seq-int.set j 1 prim - bub ]
        [ s ] if } ]
    [ s ] if };

: isort
  (forall ρ; ρ s:Seq Int i:Int -- ρ r:Seq Int)
  locals { s i } {
    i s 218 prim seq-int.at prim <
    [ s i bub i 1 prim + isort ]
    [ s ] if };

: fnb
  (forall ρ; ρ s:Seq Int k:Int -- ρ r:Seq Int)
  locals { s k } {
    k 0 prim >=
    [ s 192 k prim + prim seq-int.at
      locals { p } {
        s 36 p prim + prim seq-int.at 0 prim =
        [ s p 2 add 36 p prim + 1 prim seq-int.set 204 p prim + 1 prim seq-int.set ]
        [ s k 1 prim - fnb ] if } ]
    [ s ] if };

: bye
  (forall ρ; ρ s:Seq Int -- ρ r:Seq Int)
  locals { s } {
    s 218 prim seq-int.at 2 prim mod 1 prim =
    [ s s 218 prim seq-int.at 1 prim - fnb ]
    [ s ] if };

: fy
  (forall ρ; ρ s:Seq Int x:Int j:Int mode:Int -- ρ y:Int)
  locals { s x j mode } {
    j s 218 prim seq-int.at prim <
    [ s 192 j prim + prim seq-int.at
      locals { q } {
        s 204 q prim + prim seq-int.at 0 prim =
        mode 1 prim = s 48 x 12 prim * prim + q prim + prim seq-int.at 0 prim = prim or
        prim and
        [ q ] [ s x j 1 prim + mode fy ] if } ]
    [ -1 ] if };

: apply
  (forall ρ; ρ s:Seq Int res:Seq Int w:Int b:Int -- ρ r:Seq Int)
  locals { s res w b } {
    res s 216 prim seq-int.at prim seq-int.at
    locals { r } {
      s 216 1 add
      w 2 r prim - add
      b r add
      12 w prim + 1 add
      24 w prim + 1 prim seq-int.set
      24 b prim + 2 prim seq-int.set
      48 w 12 prim * prim + b prim + 1 add
      48 b 12 prim * prim + w prim + 1 add
      204 w prim + 1 prim seq-int.set
      204 b prim + 1 prim seq-int.set } };

: game
  (forall ρ; ρ s:Seq Int res:Seq Int x:Int y:Int -- ρ r:Seq Int)
  locals { s res x y } {
    s 12 x prim + prim seq-int.at s 12 y prim + prim seq-int.at
    locals { wx wy } {
      wx wy prim < [ x y ]
      [ wy wx prim < [ y x ]
        [ s 24 x prim + prim seq-int.at 2 prim = s 24 y prim + prim seq-int.at 2 prim = prim not prim and
          [ x y ]
          [ s 24 y prim + prim seq-int.at 2 prim = s 24 x prim + prim seq-int.at 2 prim = prim not prim and
            [ y x ] [ x y ] if ] if ] if ] if
      locals { w b } { s res w b apply } } };

: dopair
  (forall ρ; ρ s:Seq Int res:Seq Int i:Int x:Int -- ρ r:Seq Int)
  locals { s res i x } {
    s x i 1 prim + 0 fy
    locals { y0 } {
      y0 0 prim >=
      [ s res x y0 game ]
      [ s 217 1 add
        locals { s1 } {
          s1 x i 1 prim + 1 fy
          locals { y1 } { s1 res x y1 game } } ] if } };

: pairs
  (forall ρ; ρ s:Seq Int res:Seq Int i:Int -- ρ r:Seq Int)
  locals { s res i } {
    i s 218 prim seq-int.at prim <
    [ s 192 i prim + prim seq-int.at
      locals { x } {
        s 204 x prim + prim seq-int.at 0 prim =
        [ s res i x dopair
          locals { s2 } { s2 res i 1 prim + pairs } ]
        [ s res i 1 prim + pairs ] if } ]
    [ s ] if };

: clr
  (forall ρ; ρ s:Seq Int k:Int -- ρ r:Seq Int)
  locals { s k } {
    k s 218 prim seq-int.at prim <
    [ s 204 k prim + 0 prim seq-int.set k 1 prim + clr ]
    [ s ] if };

: round
  (forall ρ; ρ s:Seq Int res:Seq Int -- ρ r:Seq Int)
  locals { s res } { s 0 clr 1 isort bye res 0 pairs };

: rl
  (forall ρ; ρ s:Seq Int res:Seq Int k:Int -- ρ r:Seq Int)
  locals { s res k } {
    k 0 prim >
    [ s res round res k 1 prim - rl ]
    [ s ] if };

: bq
  (forall ρ; ρ s:Seq Int p:Int q:Int acc:Int -- ρ r:Int)
  locals { s p q acc } {
    q s 218 prim seq-int.at prim <
    [ s p q 1 prim + acc
      s 48 p 12 prim * prim + q prim + prim seq-int.at s q prim seq-int.at prim * prim +
      bq ]
    [ acc ] if };

: bu
  (forall ρ; ρ s:Seq Int p:Int -- ρ r:Seq Int)
  locals { s p } {
    p s 218 prim seq-int.at prim <
    [ s 232 p prim + s p 0 0 bq prim seq-int.set p 1 prim + bu ]
    [ s ] if };

: init
  (forall ρ; ρ s:Seq Int rt:Seq Int k:Int -- ρ r:Seq Int)
  locals { s rt k } {
    k rt prim seq-int.len prim <
    [ s 220 k prim + rt k prim seq-int.at prim seq-int.set
      192 k prim + k prim seq-int.set
      rt k 1 prim + init ]
    [ s ] if };

: ex
  (forall ρ; ρ s:Seq Int base:Int k:Int out:Seq Int -- ρ r:Seq Int)
  locals { s base k out } {
    k s 218 prim seq-int.at prim <
    [ s base k 1 prim + out s base k prim + prim seq-int.at prim seq-int.push ex ]
    [ out ] if };

: main
  (forall ρ; ρ ratings:Seq Int rounds:Int results:Seq Int
   -- ρ scores:Seq Int buch:Seq Int ranking:Seq Int whites:Seq Int rematches:Int)
  locals { ratings rounds results } {
    prim seq-int.empty 240 zs
    218 ratings prim seq-int.len prim seq-int.set
    ratings 0 init
    results rounds rl
    0 bu
    1 isort
    locals { s } {
      s 0 0 prim seq-int.empty ex
      s 232 0 prim seq-int.empty ex
      s 192 0 prim seq-int.empty ex
      s 12 0 prim seq-int.empty ex
      s 217 prim seq-int.at } };
```

### task: warehouse
```firth
: add
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int)
  locals { s i v } { s i s i prim seq-int.at v prim + prim seq-int.set };

: zs
  (forall ρ; ρ xs:Seq Int n:Int -- ρ r:Seq Int)
  locals { xs n } { n 0 prim > [ xs 0 prim seq-int.push n 1 prim - zs ] [ xs ] if };

: mn
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } { a b prim < [ a ] [ b ] if };

: lqi
  (forall ρ; ρ p:Int i:Int -- ρ r:Int)
  locals { p i } { 100 p 160 prim * prim + i prim + };

: lei
  (forall ρ; ρ p:Int i:Int -- ρ r:Int)
  locals { p i } { 900 p 160 prim * prim + i prim + };

: bqi
  (forall ρ; ρ p:Int i:Int -- ρ r:Int)
  locals { p i } { 1700 p 80 prim * prim + i prim + };

: bdi
  (forall ρ; ρ p:Int i:Int -- ρ r:Int)
  locals { p i } { 2100 p 80 prim * prim + i prim + };

: shp
  (forall ρ; ρ w:Seq Int p:Int x:Int -- ρ r:Seq Int)
  locals { w p x } {
    w 0 x add
    1 w 2500 p prim + prim seq-int.at x prim * add };

: take
  (forall ρ; ρ w:Seq Int p:Int x:Int -- ρ r:Seq Int)
  locals { w p x } {
    x 0 prim >
    [ w 10 p prim + prim seq-int.at
      locals { h } {
        w p h lqi prim seq-int.at
        locals { q } {
          q x mn
          locals { y } {
            w p h lqi q y prim - prim seq-int.set
            20 p prim + 0 y prim - add
            q y prim = [ 10 p prim + 1 add ] [ ] if
            p x y prim - take } } } ]
    [ w ] if };

: fpos
  (forall ρ; ρ w:Seq Int p:Int ex:Int i:Int -- ρ r:Int)
  locals { w p ex i } {
    i w 15 p prim + prim seq-int.at prim <
    [ w p i lei prim seq-int.at ex prim > [ i ] [ w p ex i 1 prim + fpos ] if ]
    [ i ] if };

: shu
  (forall ρ; ρ w:Seq Int p:Int i:Int k:Int -- ρ r:Seq Int)
  locals { w p i k } {
    k i prim >=
    [ w p k 1 prim + lqi w p k lqi prim seq-int.at prim seq-int.set
      p k 1 prim + lei w p k lei prim seq-int.at prim seq-int.set
      p i k 1 prim - shu ]
    [ w ] if };

: fill
  (forall ρ; ρ w:Seq Int p:Int -- ρ r:Seq Int)
  locals { w p } {
    w 35 p prim + prim seq-int.at w 40 p prim + prim seq-int.at prim <
    w 20 p prim + prim seq-int.at 0 prim > prim and
    [ w 35 p prim + prim seq-int.at
      locals { qh } {
        w p qh bqi prim seq-int.at
        locals { ow } {
          ow w 20 p prim + prim seq-int.at mn
          locals { x } {
            w p x take p x shp
            p qh bqi 0 x prim - add
            ow x prim = [ 35 p prim + 1 add ] [ ] if
            p fill } } } ]
    [ w ] if };

: addlot
  (forall ρ; ρ w:Seq Int p:Int q:Int ex:Int -- ρ r:Seq Int)
  locals { w p q ex } {
    w p ex w 10 p prim + prim seq-int.at fpos
    locals { i } {
      w p i w 15 p prim + prim seq-int.at 1 prim - shu
      p i lqi q prim seq-int.set
      p i lei ex prim seq-int.set
      15 p prim + 1 add
      20 p prim + q add
      p fill } };

: enq
  (forall ρ; ρ w:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { w p q d } {
    w 40 p prim + prim seq-int.at
    locals { qt } {
      w p qt bqi q prim seq-int.set
      p qt bdi d prim seq-int.set
      40 p prim + 1 add } };

: ordr
  (forall ρ; ρ w:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { w p q d } {
    w 35 p prim + prim seq-int.at w 40 p prim + prim seq-int.at prim <
    [ w p q d enq ]
    [ w 20 p prim + prim seq-int.at q mn
      locals { x } {
        w p x take p x shp
        q x prim -
        locals { rem } { rem 0 prim > [ p rem d enq ] [ ] if } } ] if };

: hev
  (forall ρ; ρ w:Seq Int d:Int e:Int -- ρ r:Seq Int)
  locals { w d e } {
    w 3103 1 add
    w 2800 e prim + prim seq-int.at
    w 2900 e prim + prim seq-int.at
    w 3000 e prim + prim seq-int.at
    locals { p q ex } {
      w 2700 e prim + prim seq-int.at 1 prim =
      [ p q ex addlot ]
      [ p q d ordr ] if } };

: evs
  (forall ρ; ρ w:Seq Int d:Int -- ρ r:Seq Int)
  locals { w d } {
    w 3103 prim seq-int.at
    locals { e } {
      e w 3100 prim seq-int.at prim <
      [ w 2600 e prim + prim seq-int.at d prim =
        [ w d e hev d evs ] [ w ] if ]
      [ w ] if } };

: dis
  (forall ρ; ρ w:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { w p d } {
    w 10 p prim + prim seq-int.at w 15 p prim + prim seq-int.at prim <
    [ w 10 p prim + prim seq-int.at
      locals { h } {
        w p h lei prim seq-int.at d prim <
        [ w 2 w p h lqi prim seq-int.at add
          20 p prim + 0 w p h lqi prim seq-int.at prim - add
          10 p prim + 1 add
          p d dis ]
        [ w ] if } ]
    [ w ] if };

: arr
  (forall ρ; ρ w:Seq Int d:Int p:Int -- ρ r:Seq Int)
  locals { w d p } {
    w 25 p prim + prim seq-int.at 1 prim =
    w 30 p prim + prim seq-int.at d prim = prim and
    [ w p w 2510 p prim + prim seq-int.at d w 2520 p prim + prim seq-int.at prim + addlot
      25 p prim + 0 prim seq-int.set ]
    [ w ] if };

: canc
  (forall ρ; ρ w:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { w p d } {
    w 35 p prim + prim seq-int.at w 40 p prim + prim seq-int.at prim <
    [ w 35 p prim + prim seq-int.at
      locals { k } {
        w p k bdi prim seq-int.at d 7 prim - prim <=
        [ w 3 w p k bqi prim seq-int.at add
          35 p prim + 1 add
          p d canc ]
        [ w ] if } ]
    [ w ] if };

: reo
  (forall ρ; ρ w:Seq Int d:Int p:Int -- ρ r:Seq Int)
  locals { w d p } {
    w 25 p prim + prim seq-int.at 0 prim =
    w 20 p prim + prim seq-int.at w 2505 p prim + prim seq-int.at prim <= prim and
    [ w 25 p prim + 1 prim seq-int.set
      30 p prim + d w 2515 p prim + prim seq-int.at prim + prim seq-int.set
      4 1 add ]
    [ w ] if };

: each
  (forall ρ; ρ w:Seq Int d:Int p:Int mode:Int -- ρ r:Seq Int)
  locals { w d p mode } {
    p w 3101 prim seq-int.at prim <
    [ mode 0 prim = [ w p d dis ]
      [ mode 1 prim = [ w d p arr ]
        [ mode 2 prim = [ w p d canc ] [ w d p reo ] if ] if ] if
      d p 1 prim + mode each ]
    [ w ] if };

: days
  (forall ρ; ρ w:Seq Int d:Int -- ρ r:Seq Int)
  locals { w d } {
    d w 3102 prim seq-int.at prim <
    [ w d 0 0 each d 0 1 each d evs d 0 2 each d 0 3 each d 1 prim + days ]
    [ w ] if };

: cpy
  (forall ρ; ρ w:Seq Int src:Seq Int base:Int k:Int -- ρ r:Seq Int)
  locals { w src base k } {
    k src prim seq-int.len prim <
    [ w base k prim + src k prim seq-int.at prim seq-int.set src base k 1 prim + cpy ]
    [ w ] if };

: pst
  (forall ρ; ρ w:Seq Int k:Int out:Seq Int -- ρ r:Seq Int)
  locals { w k out } {
    k w 3101 prim seq-int.at prim <
    [ w k 1 prim + out w 20 k prim + prim seq-int.at prim seq-int.push pst ]
    [ out ] if };

: ow1
  (forall ρ; ρ w:Seq Int p:Int k:Int acc:Int -- ρ r:Int)
  locals { w p k acc } {
    k w 40 p prim + prim seq-int.at prim <
    [ w p k 1 prim + acc w p k bqi prim seq-int.at prim + ow1 ]
    [ acc ] if };

: owall
  (forall ρ; ρ w:Seq Int p:Int acc:Int -- ρ r:Int)
  locals { w p acc } {
    p w 3101 prim seq-int.at prim <
    [ w p 1 prim + acc w p w 35 p prim + prim seq-int.at 0 ow1 prim + owall ]
    [ acc ] if };

: main
  (forall ρ; ρ dys:Int price:Seq Int rp:Seq Int rq:Seq Int lead:Seq Int shelf:Seq Int
   eday:Seq Int ekind:Seq Int eprod:Seq Int eqty:Seq Int eexp:Seq Int
   -- ρ stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int supplies:Int owed:Int)
  locals { dys price rp rq lead shelf eday ekind eprod eqty eexp } {
    prim seq-int.empty 3110 zs
    3100 eday prim seq-int.len prim seq-int.set
    3101 price prim seq-int.len prim seq-int.set
    3102 dys prim seq-int.set
    price 2500 0 cpy
    rp 2505 0 cpy
    rq 2510 0 cpy
    lead 2515 0 cpy
    shelf 2520 0 cpy
    eday 2600 0 cpy
    ekind 2700 0 cpy
    eprod 2800 0 cpy
    eqty 2900 0 cpy
    eexp 3000 0 cpy
    0 days
    locals { w } {
      w 0 prim seq-int.empty pst
      w 1 prim seq-int.at
      w 0 prim seq-int.at
      w 2 prim seq-int.at
      w 3 prim seq-int.at
      w 4 prim seq-int.at
      w 0 0 owall } };
```

### task: cache-sim
```firth
: add
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int)
  locals { s i v } { s i s i prim seq-int.at v prim + prim seq-int.set };

: zs
  (forall ρ; ρ xs:Seq Int n:Int -- ρ r:Seq Int)
  locals { xs n } { n 0 prim > [ xs 0 prim seq-int.push n 1 prim - zs ] [ xs ] if };

: bi
  (forall ρ; ρ lv:Int k:Int j:Int -- ρ r:Int)
  locals { lv k j } { 100 lv 300 prim * prim + k 8 prim * prim + j prim + };

: di
  (forall ρ; ρ lv:Int k:Int j:Int -- ρ r:Int)
  locals { lv k j } { lv k j bi 100 prim + };

: ci
  (forall ρ; ρ lv:Int k:Int -- ρ r:Int)
  locals { lv k } { 300 lv 300 prim * prim + k prim + };

: ps
  (forall ρ; ρ m:Seq Int lv:Int k:Int a:Int j:Int -- ρ r:Int)
  locals { m lv k a j } {
    j m lv k ci prim seq-int.at prim <
    [ m lv k j bi prim seq-int.at a prim = [ j ] [ m lv k a j 1 prim + ps ] if ]
    [ -1 ] if };

: pos
  (forall ρ; ρ m:Seq Int lv:Int a:Int -- ρ r:Int)
  locals { m lv a } {
    a m 10 lv 2 prim * prim + prim seq-int.at prim mod
    locals { k } { m lv k a 0 ps } };

: shd
  (forall ρ; ρ m:Seq Int lv:Int k:Int t:Int cnt:Int -- ρ r:Seq Int)
  locals { m lv k t cnt } {
    t cnt 1 prim - prim <
    [ m lv k t bi m lv k t 1 prim + bi prim seq-int.at prim seq-int.set
      lv k t di m lv k t 1 prim + di prim seq-int.at prim seq-int.set
      lv k t 1 prim + cnt shd ]
    [ m ] if };

: usb
  (forall ρ; ρ m:Seq Int lv:Int a:Int fl:Int -- ρ r:Seq Int)
  locals { m lv a fl } {
    a m 10 lv 2 prim * prim + prim seq-int.at prim mod
    locals { k } {
      m lv a pos
      locals { j } {
        m lv k j di prim seq-int.at fl prim + 0 prim > [ 1 ] [ 0 ] if
        m lv k ci prim seq-int.at
        locals { dm cnt } {
          m lv k j cnt shd
          lv k cnt 1 prim - bi a prim seq-int.set
          lv k cnt 1 prim - di dm prim seq-int.set } } } };

: put
  (forall ρ; ρ m:Seq Int lv:Int a:Int dy:Int -- ρ r:Seq Int ev:Int evd:Int)
  locals { m lv a dy } {
    a m 10 lv 2 prim * prim + prim seq-int.at prim mod
    locals { k } {
      m lv k ci prim seq-int.at
      locals { cnt } {
        cnt m 11 lv 2 prim * prim + prim seq-int.at prim >=
        [ m lv k 0 bi prim seq-int.at m lv k 0 di prim seq-int.at
          locals { ev evd } {
            m lv k 0 cnt shd
            lv k cnt 1 prim - bi a prim seq-int.set
            lv k cnt 1 prim - di dy prim seq-int.set
            ev evd } ]
        [ m lv k cnt bi a prim seq-int.set
          lv k cnt di dy prim seq-int.set
          lv k ci 1 add
          -1 0 ] if } } };

: wb
  (forall ρ; ρ m:Seq Int ev:Int evd:Int -- ρ r:Seq Int)
  locals { m ev evd } {
    ev 0 prim >= evd 1 prim = prim and
    [ m 5 1 add ] [ m ] if };

: l2w
  (forall ρ; ρ m:Seq Int b:Int -- ρ r:Seq Int)
  locals { m b } {
    m 1 b pos
    locals { p } {
      p 0 prim >=
      [ m 1 b 1 usb ]
      [ m 1 b 1 put wb ] if } };

: miss
  (forall ρ; ρ m:Seq Int a:Int fl:Int -- ρ r:Seq Int)
  locals { m a fl } {
    m 1 1 add
    locals { m1 } {
      m1 1 a pos 0 prim >=
      [ m1 1 a 0 usb 2 1 add ]
      [ m1 3 1 add 4 1 add 1 a 0 put wb ] if
      locals { m2 } {
        m2 0 a fl put
        locals { m3 ev evd } {
          ev 0 prim >= evd 1 prim = prim and
          [ m3 ev l2w ] [ m3 ] if } } } };

: access
  (forall ρ; ρ m:Seq Int a:Int wr:Bool -- ρ r:Seq Int)
  locals { m a wr } {
    wr [ 1 ] [ 0 ] if
    locals { fl } {
      m 0 a pos 0 prim >=
      [ m 0 a fl usb 0 1 add ]
      [ m a fl miss ] if } };

: lp
  (forall ρ; ρ m:Seq Int ad:Seq Int wr:Seq Bool i:Int -- ρ r:Seq Int)
  locals { m ad wr i } {
    i ad prim seq-int.len prim <
    [ m ad i prim seq-int.at wr i prim seq-bool.at access ad wr i 1 prim + lp ]
    [ m ] if };

: dj
  (forall ρ; ρ m:Seq Int lv:Int k:Int j:Int acc:Int -- ρ r:Int)
  locals { m lv k j acc } {
    j m lv k ci prim seq-int.at prim <
    [ m lv k j 1 prim + acc m lv k j di prim seq-int.at prim + dj ]
    [ acc ] if };

: dk
  (forall ρ; ρ m:Seq Int lv:Int k:Int acc:Int -- ρ r:Int)
  locals { m lv k acc } {
    k m 10 lv 2 prim * prim + prim seq-int.at prim <
    [ m lv k 1 prim + acc m lv k 0 0 dj prim + dk ]
    [ acc ] if };

: bj
  (forall ρ; ρ m:Seq Int k:Int j:Int out:Seq Int -- ρ r:Seq Int)
  locals { m k j out } {
    j m 0 k ci prim seq-int.at prim <
    [ m k j 1 prim + out m 0 k j bi prim seq-int.at prim seq-int.push bj ]
    [ out ] if };

: bk
  (forall ρ; ρ m:Seq Int k:Int out:Seq Int -- ρ r:Seq Int)
  locals { m k out } {
    k m 10 prim seq-int.at prim <
    [ m k 1 prim + m k 0 out bj bk ]
    [ out ] if };

: main
  (forall ρ; ρ s1:Int w1:Int s2:Int w2:Int addrs:Seq Int writes:Seq Bool
   -- ρ h1:Int m1:Int h2:Int m2:Int rd:Int wrt:Int dirty:Int blocks:Seq Int)
  locals { s1 w1 s2 w2 addrs writes } {
    prim seq-int.empty 700 zs
    10 s1 prim seq-int.set
    11 w1 prim seq-int.set
    12 s2 prim seq-int.set
    13 w2 prim seq-int.set
    addrs writes 0 lp
    locals { m } {
      m 0 prim seq-int.at
      m 1 prim seq-int.at
      m 2 prim seq-int.at
      m 3 prim seq-int.at
      m 4 prim seq-int.at
      m 5 prim seq-int.at
      m 0 0 0 dk m 1 0 0 dk prim +
      m 0 prim seq-int.empty bk } };
```

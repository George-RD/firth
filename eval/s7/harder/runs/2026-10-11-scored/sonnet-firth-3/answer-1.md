### task: sokoban
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: inc (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int) 1 addto ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;
: col (forall ρ; ρ m:Seq Int b:Int k:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m b k n acc } {
    k n prim >= [ acc ]
    [ m b k 1 prim + n acc m b k prim + rd prim seq-int.push col ] if } ;
: cpyin (forall ρ; ρ m:Seq Int s:Seq Int dst:Int k:Int -- ρ r:Seq Int)
  locals { m s dst k } {
    k s prim seq-int.len prim >= [ m ]
    [ m dst k prim + s k prim seq-int.at wr s dst k 1 prim + cpyin ] if } ;

: delta (forall ρ; ρ w:Int d:Int -- ρ dl:Int)
  locals { w d } {
    d 0 prim = [ 0 w prim - ]
    [ d 1 prim = [ 1 ] [ d 2 prim = [ w ] [ -1 ] if ] if ] if } ;
: wallat (forall ρ; ρ m:Seq Int i:Int -- ρ b:Bool)
  locals { m i } { m i rd 1 prim = } ;
: tgt (forall ρ; ρ m:Seq Int d:Int -- ρ t:Int)
  locals { m d } { m 150 rd m 151 rd d delta prim + } ;
: record (forall ρ; ρ m:Seq Int d:Int f:Int -- ρ r:Seq Int)
  locals { m d f } {
    m 153 rd
    locals { h } {
      m 170 h 2 prim * prim + d wr
      171 h 2 prim * prim + f wr
      153 h 1 prim + wr } } ;
: dostep (forall ρ; ρ m:Seq Int d:Int -- ρ r:Seq Int)
  locals { m d } { m 150 m d tgt wr d 0 record } ;
: boxat (forall ρ; ρ m:Seq Int t:Int k:Int -- ρ r:Int)
  locals { m t k } {
    k m 152 rd prim >=
    [ -1 ]
    [ m 160 k prim + rd t prim =
      [ k ]
      [ m t k 1 prim + boxat ] if ] if } ;
: deadchk (forall ρ; ρ m:Seq Int u:Int -- ρ r:Seq Int)
  locals { m u } {
    m 151 rd
    locals { w } {
      m u rd 2 prim =
      [ m ]
      [ m u w prim - wallat m u w prim + wallat prim or
        m u 1 prim - wallat m u 1 prim + wallat prim or prim and
        [ m 157 inc ] [ m ] if ] if } } ;
: dopush (forall ρ; ρ m:Seq Int d:Int b:Int -- ρ r:Seq Int)
  locals { m d b } {
    m d tgt m 151 rd d delta prim +
    locals { u } {
      m 160 b prim + u wr
      150 m d tgt wr
      d 1 record
      154 inc
      u deadchk } } ;
: trypush (forall ρ; ρ m:Seq Int d:Int b:Int -- ρ r:Seq Int)
  locals { m d b } {
    m d tgt m 151 rd d delta prim +
    locals { u } {
      m u wallat m u 0 boxat 0 prim >= prim or
      [ m 155 inc ] [ m d b dopush ] if } } ;
: domove (forall ρ; ρ m:Seq Int d:Int -- ρ r:Seq Int)
  locals { m d } {
    m d tgt
    locals { t } {
      m t wallat
      [ m 155 inc ]
      [ m t 0 boxat
        locals { b } {
          b 0 prim >=
          [ m d b trypush ] [ m d dostep ] if } ] if } } ;
: undo (forall ρ; ρ m:Seq Int -- ρ r:Seq Int)
  locals { m } {
    m 153 rd 0 prim =
    [ m ]
    [ m 153 rd 1 prim -
      locals { h } {
        m 170 h 2 prim * prim + rd
        m 171 h 2 prim * prim + rd
        locals { d f } {
          m 151 rd d delta
          locals { dl } {
            m 150 rd
            locals { p } {
              f 1 prim =
              [ m p dl prim + 0 boxat
                locals { b } {
                  m 160 b prim + p wr
                  150 p dl prim - wr
                  153 h wr
                  156 inc } ]
              [ m 150 p dl prim - wr
                153 h wr
                156 inc ] if } } } } ] if } ;
: allgoal (forall ρ; ρ m:Seq Int k:Int -- ρ b:Bool)
  locals { m k } {
    k m 152 rd prim >=
    [ true ]
    [ m m 160 k prim + rd rd 2 prim =
      [ m k 1 prim + allgoal ] [ false ] if ] if } ;
: run (forall ρ; ρ m:Seq Int mv:Seq Int i:Int -- ρ r:Seq Int)
  locals { m mv i } {
    i mv prim seq-int.len prim >=
    [ m ]
    [ m 0 allgoal
      [ m ]
      [ mv i prim seq-int.at
        locals { c } {
          m 158 i 1 prim + wr
          c 4 prim =
          [ undo ] [ c domove ] if
          mv i 1 prim + run } ] if ] if } ;

: main
  (forall ρ; ρ w:Int h:Int cells:Seq Int p:Int bx:Seq Int mv:Seq Int --
   ρ pl:Int bs:Seq Int nr:Int hl:Int pu:Int bl:Int un:Int dd:Int sv:Bool)
  locals { w h cells p bx mv } {
    cells 600 pad
    150 p wr 151 w wr 152 bx prim seq-int.len wr
    bx 160 0 cpyin
    mv 0 run
    locals { mm } {
      mm 150 rd
      mm 160 0 mm 152 rd prim seq-int.empty col
      mm 158 rd mm 153 rd mm 154 rd mm 155 rd mm 156 rd mm 157 rd
      mm 0 allgoal } } ;
```

### task: checkers
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: inc (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int) 1 addto ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;
: col (forall ρ; ρ m:Seq Int b:Int k:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m b k n acc } {
    k n prim >= [ acc ]
    [ m b k 1 prim + n acc m b k prim + rd prim seq-int.push col ] if } ;

: own (forall ρ; ρ p:Int -- ρ s:Int)
  dup 0 prim = [ drop -1 ] [ 3 prim >= [ 1 ] [ 0 ] if ] if ;
: allowed (forall ρ; ρ p:Int d:Int -- ρ b:Bool)
  locals { p d } {
    p 1 prim = [ d 2 prim < ] [ p 3 prim = [ d 2 prim >= ] [ true ] if ] if } ;
: nb (forall ρ; ρ i:Int d:Int -- ρ j:Int)
  locals { i d } {
    i 4 prim div d 2 prim div 2 prim * prim + 1 prim -
    i 4 prim mod 2 prim * 1 prim + i 4 prim div 2 prim mod prim -
    d 2 prim mod 2 prim * prim + 1 prim -
    locals { r c } {
      r 0 prim >= r 7 prim <= prim and c 0 prim >= c 7 prim <= prim and prim and
      [ r 4 prim * c 2 prim div prim + ] [ -1 ] if } } ;
: jmp (forall ρ; ρ m:Seq Int pos:Int pc:Int d:Int -- ρ b:Bool)
  locals { m pos pc d } {
    pc d allowed
    [ pos d nb
      locals { mid } {
        mid 0 prim >=
        [ mid d nb
          locals { land } {
            land 0 prim >=
            [ m land rd 0 prim =
              m mid rd own pc own prim = prim not prim and
              m mid rd 0 prim = prim not prim and ]
            [ false ] if } ]
        [ false ] if } ]
    [ false ] if } ;
: anyj (forall ρ; ρ m:Seq Int pos:Int pc:Int d:Int -- ρ b:Bool)
  locals { m pos pc d } {
    d 4 prim >= [ false ]
    [ m pos pc d jmp [ true ] [ m pos pc d 1 prim + anyj ] if ] if } ;
: cp (forall ρ; ρ m:Seq Int k:Int n:Int -- ρ r:Seq Int)
  locals { m k n } {
    k n prim >= [ m ]
    [ m 60 k prim + m 40 k prim + rd wr k 1 prim + n cp ] if } ;
: leaf (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } {
    n m 33 rd prim >
    [ m 33 n wr 34 m 35 rd wr 0 n cp ]
    [ m ] if } ;
: dfs (forall ρ; ρ m:Seq Int pos:Int pc:Int dep:Int -- ρ r:Seq Int)
  locals { m pos pc dep } {
    m pos pc 0 anyj
    [ m pos pc dep 0 dfsdir ]
    [ m dep leaf ] if } ;
: dstep (forall ρ; ρ m:Seq Int land:Int pc:Int n:Int -- ρ r:Seq Int)
  locals { m land pc n } {
    pc 1 prim = land 4 prim < prim and
    pc 3 prim = land 28 prim >= prim and prim or
    [ m n leaf ] [ m land pc n dfs ] if } ;
: dojump (forall ρ; ρ m:Seq Int pos:Int pc:Int dep:Int d:Int -- ρ r:Seq Int)
  locals { m pos pc dep d } {
    pos d nb
    locals { mid } {
      mid d nb
      locals { land } {
        m mid rd
        locals { cap } {
          m mid 0 wr 40 dep prim + d wr
          land pc dep 1 prim + dstep
          mid cap wr } } } } ;
: dfsdir (forall ρ; ρ m:Seq Int pos:Int pc:Int dep:Int d:Int -- ρ r:Seq Int)
  locals { m pos pc dep d } {
    d 4 prim >= [ m ]
    [ m pos pc d jmp
      [ m pos pc dep d dojump ] [ m ] if
      pos pc dep d 1 prim + dfsdir ] if } ;
: findcap (forall ρ; ρ m:Seq Int side:Int s:Int -- ρ r:Seq Int)
  locals { m side s } {
    s 32 prim >= [ m ]
    [ m s rd own side prim =
      [ m s rd
        locals { pc } { m s 0 wr 35 s wr s pc 0 dfs s pc wr } ]
      [ m ] if
      side s 1 prim + findcap ] if } ;
: fin (forall ρ; ρ m:Seq Int pos:Int -- ρ r:Seq Int)
  locals { m pos } {
    m 36 rd
    locals { pc } {
      pc 1 prim = pos 4 prim < prim and
      pc 3 prim = pos 28 prim >= prim and prim or
      [ m pos pc 1 prim + wr 82 inc ]
      [ m pos pc wr ] if } } ;
: execk (forall ρ; ρ m:Seq Int pos:Int k:Int n:Int sd:Int -- ρ r:Seq Int)
  locals { m pos k n sd } {
    k n prim >= [ m pos fin ]
    [ m 60 k prim + rd
      locals { d } {
        pos d nb
        locals { mid } {
          m mid 0 wr 80 sd prim + inc
          mid d nb k 1 prim + n sd execk } } ] if } ;
: docap (forall ρ; ρ m:Seq Int sd:Int -- ρ r:Seq Int)
  locals { m sd } {
    m 34 rd
    locals { st } {
      m 36 m st rd wr st 0 wr
      st 0 m 33 rd sd execk 83 inc } } ;
: stepdir (forall ρ; ρ m:Seq Int s:Int pc:Int d:Int -- ρ r:Int)
  locals { m s pc d } {
    d 4 prim >= [ -1 ]
    [ pc d allowed
      [ s d nb
        locals { t } { t 0 prim >= [ m t rd 0 prim = ] [ false ] if } ]
      [ false ] if
      [ d ] [ m s pc d 1 prim + stepdir ] if ] if } ;
: findstep (forall ρ; ρ m:Seq Int side:Int s:Int -- ρ r:Int)
  locals { m side s } {
    s 32 prim >= [ -1 ]
    [ m s rd own side prim =
      [ m s m s rd 0 stepdir ] [ -1 ] if
      locals { dd } {
        dd 0 prim >=
        [ s 4 prim * dd prim + ]
        [ m side s 1 prim + findstep ] if } ] if } ;
: dostep (forall ρ; ρ m:Seq Int code:Int -- ρ r:Seq Int)
  locals { m code } {
    code 4 prim div code 4 prim mod
    locals { s d } {
      m s rd
      locals { pc } {
        s d nb
        locals { t } {
          m s 0 wr
          pc 1 prim = t 4 prim < prim and
          pc 3 prim = t 28 prim >= prim and prim or
          [ t pc 1 prim + wr 82 inc ]
          [ t pc wr ] if } } } } ;
: game (forall ρ; ρ m:Seq Int sd:Int plies:Int -- ρ r:Seq Int)
  locals { m sd plies } {
    m 33 0 wr sd 0 findcap
    locals { m1 } {
      m1 33 rd 0 prim >
      [ m1 83 rd plies prim >=
        [ m1 ]
        [ m1 sd docap 1 sd prim - plies game ] if ]
      [ m1 sd 0 findstep
        locals { code } {
          code 0 prim <
          [ m1 84 2 sd prim - wr ]
          [ m1 83 rd plies prim >=
            [ m1 ]
            [ m1 code dostep 83 inc 1 sd prim - plies game ] if ] if } ] if } } ;

: main
  (forall ρ; ρ b:Seq Int turn:Int plies:Int --
   ρ bd:Seq Int played:Int wt:Int bt:Int cr:Int res:Int)
  locals { b turn plies } {
    b 100 pad turn plies game
    locals { m } {
      m 0 0 32 prim seq-int.empty col
      m 83 rd m 80 rd m 81 rd m 82 rd m 84 rd } } ;
```

### task: regex
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: inc (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int) 1 addto ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;

: skops (forall ρ; ρ pat:Seq Int n:Int j:Int -- ρ r:Int)
  locals { pat n j } {
    j n prim <
    [ pat j prim seq-int.at locals { t } { t 27 prim >= t 29 prim <= prim and } ]
    [ false ] if
    [ pat n j 1 prim + skops ] [ j ] if } ;
: skitem (forall ρ; ρ pat:Seq Int n:Int i:Int -- ρ r:Int)
  locals { pat n i } {
    pat i prim seq-int.at
    locals { t } {
      t 26 prim <=
      [ pat n i 1 prim + skops ]
      [ t 31 prim =
        [ pat n i 1 prim + skalt
          locals { k } {
            k 0 prim >=
            [ k n prim < [ pat k prim seq-int.at 32 prim = ] [ false ] if ]
            [ false ] if
            [ pat n k 1 prim + skops ] [ -1 ] if } ]
        [ -1 ] if ] if } } ;
: sksq (forall ρ; ρ pat:Seq Int n:Int i:Int -- ρ r:Int)
  locals { pat n i } {
    i n prim >=
    [ i ]
    [ pat i prim seq-int.at
      locals { t } {
        t 30 prim = t 32 prim = prim or
        [ i ]
        [ pat n i skitem
          locals { j } { j 0 prim < [ -1 ] [ pat n j sksq ] if } ] if } ] if } ;
: skalt (forall ρ; ρ pat:Seq Int n:Int i:Int -- ρ r:Int)
  locals { pat n i } {
    pat n i sksq
    locals { j } {
      j 0 prim < [ -1 ]
      [ j n prim <
        [ pat j prim seq-int.at 30 prim = ] [ false ] if
        [ pat n j 1 prim + skalt ] [ j ] if ] if } } ;

: ctok (forall ρ; ρ m:Seq Int pat:Seq Int x:Int L:Int -- ρ r:Seq Int)
  locals { m pat x L } {
    x L prim >= [ m ]
    [ m 50 x prim +
      x 0 prim = [ 31 ]
      [ x L 1 prim - prim = [ 32 ] [ pat x 1 prim - prim seq-int.at ] if ] if
      wr
      pat x 1 prim + L ctok ] if } ;
: scan1 (forall ρ; ρ m:Seq Int t:Int x:Int -- ρ r:Seq Int)
  locals { m t x } {
    t 31 prim =
    [ m 320 m 350 rd prim + x wr 350 1 addto ]
    [ t 32 prim =
      [ m 350 -1 addto
        locals { m1 } {
          m1 320 m1 350 rd prim + rd
          locals { q } {
            m1 80 x prim + q wr 80 q prim + x wr 110 x prim + q wr } } ]
      [ t 30 prim =
        [ m 320 m 350 rd 1 prim - prim + rd
          locals { q } {
            m 140 x prim + q wr
            m 200 q prim + rd 0 prim =
            [ 170 q prim + x 1 prim + wr ]
            [ 230 m 200 q prim + rd prim + 1 prim - x 1 prim + wr ] if
            200 q prim + x 1 prim + wr } ]
        [ t 26 prim <=
          [ m 110 x prim + x wr ]
          [ m 110 x prim + m 110 x 1 prim - prim + rd wr
            locals { m1 } {
              t 28 prim =
              [ m1 ]
              [ m1 110 x prim + rd
                locals { b } {
                  m1 m1 290 b prim + rd 0 prim =
                  [ 290 b prim + x 1 prim + wr ] [ ] if } ] if } ] if ] if ] if ] if } ;
: scan (forall ρ; ρ m:Seq Int x:Int L:Int -- ρ r:Seq Int)
  locals { m x L } {
    x L prim >= [ m ]
    [ m 50 x prim + rd
      locals { t } { m t x scan1 x 1 prim + L scan } ] if } ;
: fixb (forall ρ; ρ m:Seq Int x:Int L:Int -- ρ r:Seq Int)
  locals { m x L } {
    x L prim >= [ m ]
    [ m 50 x prim + rd 30 prim =
      [ m 260 x prim + m 80 m 140 x prim + rd prim + rd wr ] [ m ] if
      x 1 prim + L fixb ] if } ;
: clr (forall ρ; ρ m:Seq Int b:Int k:Int -- ρ r:Seq Int)
  locals { m b k } {
    k 24 prim >= [ m ] [ m b k prim + 0 wr b k 1 prim + clr ] if } ;
: chain (forall ρ; ρ m:Seq Int bs:Int e:Int -- ρ r:Seq Int)
  locals { m bs e } {
    e 0 prim = [ m ]
    [ m bs e visit bs m 230 e 1 prim - prim + rd chain ] if } ;
: edges (forall ρ; ρ m:Seq Int bs:Int x:Int t:Int -- ρ r:Seq Int)
  locals { m bs x t } {
    t 26 prim <= [ m ]
    [ t 31 prim =
      [ m bs x 1 prim + visit bs m 170 x prim + rd chain ]
      [ t 32 prim =
        [ m bs x 1 prim + visit ]
        [ t 30 prim =
          [ m bs m 260 x prim + rd visit ]
          [ t 29 prim =
            [ m bs x 1 prim + visit ]
            [ m bs x 1 prim + visit bs m 110 x prim + rd visit ] if ] if ] if ] if ] if } ;
: visit2 (forall ρ; ρ m:Seq Int bs:Int x:Int -- ρ r:Seq Int)
  locals { m bs x } {
    m 290 x prim + rd
    locals { sk } {
      sk 0 prim >
      [ m bs sk 1 prim - visit ] [ m ] if
      bs x m 50 x prim + rd edges } } ;
: visit (forall ρ; ρ m:Seq Int bs:Int x:Int -- ρ r:Seq Int)
  locals { m bs x } {
    m bs x prim + rd 0 prim =
    [ m bs x prim + 1 wr bs x visit2 ] [ m ] if } ;
: stepc (forall ρ; ρ m:Seq Int cb:Int nbs:Int x:Int c:Int L:Int -- ρ r:Seq Int)
  locals { m cb nbs x c L } {
    x L prim >= [ m ]
    [ m cb x prim + rd 1 prim =
      m 50 x prim + rd locals { t } { t 26 prim = t c prim = prim or } prim and
      [ m nbs x 1 prim + visit ] [ m ] if
      cb nbs x 1 prim + c L stepc ] if } ;
: runstr (forall ρ; ρ m:Seq Int ch:Seq Int cb:Int k:Int len:Int off:Int L:Int -- ρ r:Seq Int)
  locals { m ch cb k len off L } {
    m cb L prim + rd 1 prim =
    [ m 351 k wr ] [ m ] if
    locals { m1 } {
      k len prim >=
      [ m1 352 m1 cb L prim + rd wr ]
      [ m1 24 cb prim - 0 clr
        cb 24 cb prim - 0 ch off k prim + prim seq-int.at L stepc
        ch 24 cb prim - k 1 prim + len off L runstr ] if } } ;
: strs (forall ρ; ρ m:Seq Int ch:Seq Int ln:Seq Int j:Int off:Int L:Int -- ρ r:Seq Int)
  locals { m ch ln j off L } {
    j ln prim seq-int.len prim >= [ m ]
    [ ln j prim seq-int.at
      locals { len } {
        m 0 0 clr 0 0 visit 351 -1 wr
        ch 0 0 len off L runstr
        locals { m2 } {
          m2 400 j prim + m2 352 rd wr 410 j prim + m2 351 rd wr
          m2 352 rd 1 prim = [ 353 inc ] [ ] if
          ch ln j 1 prim + off len prim + L strs } } ] if } ;
: ini (forall ρ; ρ m:Seq Int j:Int -- ρ r:Seq Int)
  locals { m j } {
    j 8 prim >= [ m ] [ m 410 j prim + -1 wr j 1 prim + ini ] if } ;
: build (forall ρ; ρ m:Seq Int pat:Seq Int ln:Seq Int ch:Seq Int n:Int -- ρ r:Seq Int)
  locals { m pat ln ch n } {
    m pat 0 n 2 prim + ctok
    0 n 2 prim + scan
    0 n 2 prim + fixb
    ch ln 0 0 n 2 prim + strs } ;
: outf (forall ρ; ρ m:Seq Int j:Int n:Int acc:Seq Bool -- ρ r:Seq Bool)
  locals { m j n acc } {
    j n prim >= [ acc ]
    [ m j 1 prim + n acc m 400 j prim + rd 1 prim = prim seq-bool.push outf ] if } ;
: outl (forall ρ; ρ m:Seq Int j:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m j n acc } {
    j n prim >= [ acc ]
    [ m j 1 prim + n acc m 410 j prim + rd prim seq-int.push outl ] if } ;

: main
  (forall ρ; ρ pat:Seq Int ln:Seq Int ch:Seq Int --
   ρ full:Seq Bool lg:Seq Int cnt:Int ok:Bool)
  locals { pat ln ch } {
    pat prim seq-int.len
    locals { n } {
      prim seq-int.empty 430 pad 0 ini
      locals { m0 } {
        pat n 0 skalt n prim =
        locals { ok } {
          ok [ m0 pat ln ch n build ] [ m0 ] if
          locals { m } {
            m 0 ln prim seq-int.len prim seq-bool.empty outf
            m 0 ln prim seq-int.len prim seq-int.empty outl
            m 353 rd
            ok } } } } } ;
```

### task: swiss
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;
: col (forall ρ; ρ m:Seq Int b:Int k:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m b k n acc } {
    k n prim >= [ acc ]
    [ m b k 1 prim + n acc m b k prim + rd prim seq-int.push col ] if } ;
: cpyin (forall ρ; ρ m:Seq Int s:Seq Int dst:Int k:Int -- ρ r:Seq Int)
  locals { m s dst k } {
    k s prim seq-int.len prim >= [ m ]
    [ m dst k prim + s k prim seq-int.at wr s dst k 1 prim + cpyin ] if } ;

: beats (forall ρ; ρ m:Seq Int p:Int q:Int md:Int -- ρ b:Bool)
  locals { m p q md } {
    m p rd m q rd prim =
    [ md 1 prim = m 20 p prim + rd m 20 q prim + rd prim = prim not prim and
      [ m 20 p prim + rd m 20 q prim + rd prim > ]
      [ m 40 p prim + rd m 40 q prim + rd prim =
        [ p q prim < ]
        [ m 40 p prim + rd m 40 q prim + rd prim > ] if ] if ]
    [ m p rd m q rd prim > ] if } ;
: cntb (forall ρ; ρ m:Seq Int p:Int q:Int n:Int md:Int acc:Int -- ρ r:Int)
  locals { m p q n md acc } {
    q n prim >= [ acc ]
    [ m p q 1 prim + n md
      m q p md beats [ acc 1 prim + ] [ acc ] if
      cntb ] if } ;
: rankall (forall ρ; ρ m:Seq Int p:Int n:Int md:Int base:Int -- ρ r:Seq Int)
  locals { m p n md base } {
    p n prim >= [ m ]
    [ m base m p 0 n md 0 cntb prim + p wr
      p 1 prim + n md base rankall ] if } ;
: zu (forall ρ; ρ m:Seq Int i:Int n:Int -- ρ r:Seq Int)
  locals { m i n } {
    i n prim >= [ m ] [ m 140 i prim + 0 wr i 1 prim + n zu ] if } ;
: dobye (forall ρ; ρ m:Seq Int pos:Int -- ρ r:Seq Int)
  locals { m pos } {
    m 120 pos prim + rd
    locals { p } {
      m 100 p prim + rd 0 prim =
      [ m 100 p prim + 1 wr p m p rd 2 prim + wr 140 pos prim + 1 wr ]
      [ m pos 1 prim - dobye ] if } } ;
: findj (forall ρ; ρ m:Seq Int i:Int j:Int pass:Int -- ρ r:Int)
  locals { m i j pass } {
    j m 503 rd prim >= [ -1 ]
    [ m 140 j prim + rd 0 prim =
      pass 1 prim =
      m 160 m 120 i prim + rd 12 prim * prim + m 120 j prim + rd prim + rd 0 prim =
      prim or
      prim and
      [ j ] [ m i j 1 prim + pass findj ] if ] if } ;
: pickw (forall ρ; ρ m:Seq Int p:Int q:Int -- ρ w:Int)
  locals { m p q } {
    m 60 p prim + rd m 60 q prim + rd prim <
    [ p ]
    [ m 60 p prim + rd m 60 q prim + rd prim >
      [ q ]
      [ m 80 p prim + rd 2 prim = m 80 q prim + rd 2 prim = prim not prim and
        [ p ]
        [ m 80 q prim + rd 2 prim = m 80 p prim + rd 2 prim = prim not prim and
          [ q ] [ p ] if ] if ] if ] if } ;
: play (forall ρ; ρ m:Seq Int w:Int b:Int -- ρ r:Seq Int)
  locals { m w b } {
    m 320 m 501 rd prim + rd
    locals { r } {
      m 370 m 500 rd prim + w wr
      420 m 500 rd prim + b wr
      500 1 addto
      501 1 addto
      60 w prim + 1 addto
      80 w prim + 1 wr
      80 b prim + 2 wr
      160 w 12 prim * prim + b prim + 1 wr
      160 b 12 prim * prim + w prim + 1 wr
      r 0 prim = [ w 2 addto ]
      [ r 1 prim = [ w 1 addto b 1 addto ] [ b 2 addto ] if ] if } } ;
: pair1 (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int)
  locals { m i } {
    m 140 i prim + 1 wr
    locals { m1 } {
      m1 i i 1 prim + 0 findj
      locals { j0 } {
        j0 0 prim < [ m1 i i 1 prim + 1 findj ] [ j0 ] if
        locals { j } {
          m1 j0 0 prim < [ 504 1 addto ] [ ] if 140 j prim + 1 wr
          locals { m2 } {
            m2 120 i prim + rd m2 120 j prim + rd
            locals { p q } {
              m2 p q pickw
              locals { w } { m2 w p q prim + w prim - play } } } } } } } ;
: pairs (forall ρ; ρ m:Seq Int i:Int n:Int -- ρ r:Seq Int)
  locals { m i n } {
    i n prim >= [ m ]
    [ m 140 i prim + rd 1 prim = [ m ] [ m i pair1 ] if
      i 1 prim + n pairs ] if } ;
: round (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } {
    m 0 n zu 0 n 0 120 rankall
    n 2 prim mod 1 prim = [ n 1 prim - dobye ] [ ] if
    0 n pairs } ;
: rounds (forall ρ; ρ m:Seq Int r:Int nr:Int n:Int -- ρ x:Seq Int)
  locals { m r nr n } {
    r nr prim >= [ m ] [ m n round r 1 prim + nr n rounds ] if } ;
: buch (forall ρ; ρ m:Seq Int g:Int -- ρ r:Seq Int)
  locals { m g } {
    g m 500 rd prim >= [ m ]
    [ m 370 g prim + rd m 420 g prim + rd
      locals { w b } {
        m 20 w prim + m b rd addto
        20 b prim + m w rd addto }
      g 1 prim + buch ] if } ;

: main
  (forall ρ; ρ rt:Seq Int nr:Int rs:Seq Int --
   ρ sc:Seq Int bu:Seq Int rk:Seq Int wh:Seq Int rm:Int)
  locals { rt nr rs } {
    rt prim seq-int.len
    locals { n } {
      prim seq-int.empty 540 pad
      rt 40 0 cpyin
      rs 320 0 cpyin
      503 n wr
      0 nr n rounds
      0 buch
      locals { m } {
        m 0 n 1 520 rankall
        locals { m2 } {
          m2 0 0 n prim seq-int.empty col
          m2 20 0 n prim seq-int.empty col
          m2 520 0 n prim seq-int.empty col
          m2 60 0 n prim seq-int.empty col
          m2 504 rd } } } } ;
```

### task: warehouse
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: inc (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int) 1 addto ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;
: col (forall ρ; ρ m:Seq Int b:Int k:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m b k n acc } {
    k n prim >= [ acc ]
    [ m b k 1 prim + n acc m b k prim + rd prim seq-int.push col ] if } ;
: cpyin (forall ρ; ρ m:Seq Int s:Seq Int dst:Int k:Int -- ρ r:Seq Int)
  locals { m s dst k } {
    k s prim seq-int.len prim >= [ m ]
    [ m dst k prim + s k prim seq-int.at wr s dst k 1 prim + cpyin ] if } ;

: qi (forall ρ; ρ p:Int k:Int -- ρ i:Int) swap 120 prim * prim + 600 prim + ;
: xi (forall ρ; ρ p:Int k:Int -- ρ i:Int) qi 600 prim + ;
: bqi (forall ρ; ρ p:Int k:Int -- ρ i:Int) swap 84 prim * prim + 1800 prim + ;

: shl (forall ρ; ρ m:Seq Int p:Int k:Int -- ρ r:Seq Int)
  locals { m p k } {
    k m 10 p prim + rd prim >=
    [ m 10 p prim + m 10 p prim + rd 1 prim - wr ]
    [ m p k 1 prim - qi m p k qi rd wr
      p k 1 prim - xi m p k xi rd wr
      p k 1 prim + shl ] if } ;
: shu (forall ρ; ρ m:Seq Int p:Int k:Int pos:Int -- ρ r:Seq Int)
  locals { m p k pos } {
    k pos prim <= [ m ]
    [ m p k qi m p k 1 prim - qi rd wr
      p k xi m p k 1 prim - xi rd wr
      p k 1 prim - pos shu ] if } ;
: fpos (forall ρ; ρ m:Seq Int p:Int e:Int k:Int -- ρ r:Int)
  locals { m p e k } {
    k m 10 p prim + rd prim >=
    [ k ]
    [ m p k xi rd e prim > [ k ] [ m p e k 1 prim + fpos ] if ] if } ;
: insert (forall ρ; ρ m:Seq Int p:Int q:Int e:Int -- ρ r:Seq Int)
  locals { m p q e } {
    m p e 0 fpos
    locals { pos } {
      m p m 10 p prim + rd pos shu
      p pos qi q wr
      p pos xi e wr
      10 p prim + 1 addto } } ;
: takeq (forall ρ; ρ m:Seq Int p:Int q:Int -- ρ r:Seq Int)
  locals { m p q } {
    q 0 prim <= m 10 p prim + rd 0 prim = prim or
    [ m ]
    [ m p 0 qi rd
      locals { f } {
        f q prim < [ f ] [ q ] if
        locals { t } {
          m p 0 qi f t prim - wr
          20 p prim + 0 t prim - addto
          521 t addto
          520 t m 60 p prim + rd prim * addto
          526 t addto
          f t prim = [ p 1 shl ] [ ] if
          p q t prim - takeq } } ] if } ;
: fillb (forall ρ; ρ m:Seq Int p:Int -- ρ r:Seq Int)
  locals { m p } {
    m 30 p prim + rd m 40 p prim + rd prim <
    m 20 p prim + rd 0 prim > prim and
    [ m 526 0 wr p m p m 30 p prim + rd bqi rd takeq
      locals { m2 } {
        m2 p m2 30 p prim + rd bqi
        m2 p m2 30 p prim + rd bqi rd m2 526 rd prim - wr
        locals { m3 } {
          m3 p m3 30 p prim + rd bqi rd 0 prim =
          [ 30 p prim + 1 addto ] [ ] if
          p fillb } } ]
    [ m ] if } ;
: arrive (forall ρ; ρ m:Seq Int p:Int q:Int e:Int -- ρ r:Seq Int)
  locals { m p q e } {
    m p q e insert 20 p prim + q addto p fillb } ;
: addbo (forall ρ; ρ m:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { m p q d } {
    m p m 40 p prim + rd bqi q wr
    p m 40 p prim + rd bqi 420 prim + d wr
    40 p prim + 1 addto } ;
: order (forall ρ; ρ m:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { m p q d } {
    m 30 p prim + rd m 40 p prim + rd prim <
    [ m p q d addbo ]
    [ m 526 0 wr p q takeq
      locals { m2 } {
        m2 526 rd q prim <
        [ m2 p q m2 526 rd prim - d addbo ] [ m2 ] if } ] if } ;
: disc (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 10 p prim + rd 0 prim >
    [ m p 0 xi rd d prim < ] [ false ] if
    [ m 522 m p 0 qi rd addto
      20 p prim + 0 m p 0 qi rd prim - addto
      p 1 shl p d disc ]
    [ m ] if } ;
: canc (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 30 p prim + rd m 40 p prim + rd prim <
    [ m p m 30 p prim + rd bqi 420 prim + rd d 7 prim - prim <= ] [ false ] if
    [ m 523 m p m 30 p prim + rd bqi rd addto
      30 p prim + 1 addto p d canc ]
    [ m ] if } ;
: suparr (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 50 p prim + rd d 1 prim + prim =
    [ m 50 p prim + 0 wr
      p m 80 p prim + rd d m 100 p prim + rd prim + arrive ]
    [ m ] if } ;
: reord (forall ρ; ρ m:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { m p d } {
    m 50 p prim + rd 0 prim =
    m 20 p prim + rd m 70 p prim + rd prim <= prim and
    [ m 50 p prim + d m 90 p prim + rd prim + 1 prim + wr 524 inc ]
    [ m ] if } ;
: ph1 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d disc p 1 prim + np d ph1 ] if } ;
: ph2 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d suparr p 1 prim + np d ph2 ] if } ;
: ph4 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d canc p 1 prim + np d ph4 ] if } ;
: ph5 (forall ρ; ρ m:Seq Int p:Int np:Int d:Int -- ρ r:Seq Int)
  locals { m p np d } {
    p np prim >= [ m ] [ m p d reord p 1 prim + np d ph5 ] if } ;
: evs (forall ρ; ρ m:Seq Int d:Int -- ρ r:Seq Int)
  locals { m d } {
    m 527 rd m 528 rd prim <
    [ m 110 m 527 rd prim + rd d prim = ] [ false ] if
    [ m 270 m 527 rd prim + rd
      m 350 m 527 rd prim + rd
      locals { p q } {
        m 190 m 527 rd prim + rd 1 prim =
        [ m p q m 430 m 527 rd prim + rd arrive ]
        [ m p q d order ] if
        527 1 addto d evs } ]
    [ m ] if } ;
: dayloop (forall ρ; ρ m:Seq Int d:Int dys:Int np:Int -- ρ r:Seq Int)
  locals { m d dys np } {
    d dys prim >= [ m ]
    [ m 0 np d ph1
      0 np d ph2
      d evs
      0 np d ph4
      0 np d ph5
      d 1 prim + dys np dayloop ] if } ;
: ow1 (forall ρ; ρ m:Seq Int p:Int k:Int acc:Int -- ρ r:Int)
  locals { m p k acc } {
    k m 40 p prim + rd prim >= [ acc ]
    [ m p k 1 prim + acc m p k bqi rd prim + ow1 ] if } ;
: owall (forall ρ; ρ m:Seq Int p:Int np:Int acc:Int -- ρ r:Int)
  locals { m p np acc } {
    p np prim >= [ acc ]
    [ m p 1 prim + np m p m 30 p prim + rd acc ow1 owall ] if } ;

: main
  (forall ρ; ρ dys:Int pr:Seq Int rpl:Seq Int rq:Seq Int ld:Seq Int sh:Seq Int
   ed:Seq Int ek:Seq Int ep:Seq Int eq:Seq Int ex:Seq Int --
   ρ stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int
   supplies:Int owed:Int)
  locals { dys pr rpl rq ld sh ed ek ep eq ex } {
    pr prim seq-int.len
    locals { np } {
      prim seq-int.empty 2650 pad
      pr 60 0 cpyin
      rpl 70 0 cpyin
      rq 80 0 cpyin
      ld 90 0 cpyin
      sh 100 0 cpyin
      ed 110 0 cpyin
      ek 190 0 cpyin
      ep 270 0 cpyin
      eq 350 0 cpyin
      ex 430 0 cpyin
      528 ed prim seq-int.len wr
      0 dys np dayloop
      locals { m } {
        m 20 0 np prim seq-int.empty col
        m 520 rd m 521 rd m 522 rd m 523 rd m 524 rd
        m 0 np 0 owall } } } ;
```

### task: cache-sim
```firth
: rd (forall ρ; ρ m:Seq Int i:Int -- ρ v:Int) prim seq-int.at ;
: wr (forall ρ; ρ m:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set ;
: addto (forall ρ; ρ m:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { m i d } { m i m i rd d prim + wr } ;
: inc (forall ρ; ρ m:Seq Int i:Int -- ρ r:Seq Int) 1 addto ;
: pad (forall ρ; ρ m:Seq Int n:Int -- ρ r:Seq Int)
  locals { m n } { m prim seq-int.len n prim >= [ m ] [ m 0 prim seq-int.push n pad ] if } ;

: bi (forall ρ; ρ lb:Int s:Int k:Int -- ρ i:Int)
  locals { lb s k } { lb s 8 prim * prim + k prim + } ;
: di (forall ρ; ρ lb:Int s:Int k:Int -- ρ i:Int)
  locals { lb s k } { lb s k bi 64 prim + } ;
: lenof (forall ρ; ρ m:Seq Int lb:Int s:Int -- ρ n:Int)
  locals { m lb s } { m lb 128 prim + s prim + rd } ;
: find (forall ρ; ρ m:Seq Int lb:Int s:Int k:Int b:Int -- ρ r:Int)
  locals { m lb s k b } {
    k m lb s lenof prim >= [ -1 ]
    [ m lb s k bi rd b prim = [ k ] [ m lb s k 1 prim + b find ] if ] if } ;
: shl2 (forall ρ; ρ m:Seq Int lb:Int s:Int k:Int L:Int -- ρ r:Seq Int)
  locals { m lb s k L } {
    k L 1 prim - prim >= [ m ]
    [ m lb s k bi m lb s k 1 prim + bi rd wr
      lb s k di m lb s k 1 prim + di rd wr
      lb s k 1 prim + L shl2 ] if } ;
: usep (forall ρ; ρ m:Seq Int lb:Int s:Int pos:Int -- ρ r:Seq Int)
  locals { m lb s pos } {
    m lb s lenof
    locals { L } {
      m lb s pos bi rd m lb s pos di rd
      locals { b d } {
        m lb s pos L shl2
        lb s L 1 prim - bi b wr
        lb s L 1 prim - di d wr } } } ;
: put (forall ρ; ρ m:Seq Int lb:Int s:Int w:Int b:Int d:Int -- ρ r:Seq Int)
  locals { m lb s w b d } {
    m lb s lenof
    locals { L } {
      L w prim >=
      [ m 410 m lb s 0 bi rd wr
        411 m lb s 0 di rd wr
        lb s 0 L shl2
        lb s L 1 prim - bi b wr
        lb s L 1 prim - di d wr ]
      [ m 410 -1 wr
        lb s L bi b wr
        lb s L di d wr
        lb 128 prim + s prim + L 1 prim + wr ] if } } ;
: markd (forall ρ; ρ m:Seq Int lb:Int s:Int -- ρ r:Seq Int)
  locals { m lb s } { m lb s m lb s lenof 1 prim - di 1 wr } ;
: evw (forall ρ; ρ m:Seq Int -- ρ r:Seq Int)
  locals { m } {
    m 410 rd 0 prim >= m 411 rd 1 prim = prim and
    [ m 405 inc ] [ m ] if } ;
: wback (forall ρ; ρ m:Seq Int b:Int -- ρ r:Seq Int)
  locals { m b } {
    b m 422 rd prim mod
    locals { s } {
      m 200 s 0 b find
      locals { p } {
        p 0 prim >=
        [ m 200 s p usep 200 s markd ]
        [ m 200 s m 423 rd b 1 put evw ] if } } } ;
: l2fetch (forall ρ; ρ m:Seq Int a:Int -- ρ r:Seq Int)
  locals { m a } {
    a m 422 rd prim mod
    locals { s2 } {
      m 200 s2 0 a find
      locals { p } {
        p 0 prim >=
        [ m 402 inc 200 s2 p usep ]
        [ m 403 inc 404 inc 200 s2 m 423 rd a 0 put evw ] if } } } ;
: l1put (forall ρ; ρ m:Seq Int a:Int s1:Int wf:Bool -- ρ r:Seq Int)
  locals { m a s1 wf } {
    m 0 s1 m 421 rd a wf [ 1 ] [ 0 ] if put
    locals { m1 } {
      m1 410 rd
      locals { eb } {
        eb 0 prim >= m1 411 rd 1 prim = prim and
        [ m1 eb wback ] [ m1 ] if } } } ;
: access (forall ρ; ρ m:Seq Int a:Int wf:Bool -- ρ r:Seq Int)
  locals { m a wf } {
    a m 420 rd prim mod
    locals { s1 } {
      m 0 s1 0 a find
      locals { p } {
        p 0 prim >=
        [ m 400 inc 0 s1 p usep wf [ 0 s1 markd ] [ ] if ]
        [ m 401 inc a l2fetch a s1 wf l1put ] if } } } ;
: sim (forall ρ; ρ m:Seq Int ad:Seq Int wrs:Seq Bool i:Int -- ρ r:Seq Int)
  locals { m ad wrs i } {
    i ad prim seq-int.len prim >= [ m ]
    [ m ad i prim seq-int.at wrs i prim seq-bool.at access
      ad wrs i 1 prim + sim ] if } ;
: dc (forall ρ; ρ m:Seq Int lb:Int s:Int ns:Int k:Int acc:Int -- ρ r:Int)
  locals { m lb s ns k acc } {
    s ns prim >= [ acc ]
    [ k m lb s lenof prim >=
      [ m lb s 1 prim + ns 0 acc dc ]
      [ m lb s ns k 1 prim + acc m lb s k di rd prim + dc ] if ] if } ;
: l1b (forall ρ; ρ m:Seq Int s:Int k:Int acc:Seq Int -- ρ r:Seq Int)
  locals { m s k acc } {
    s m 420 rd prim >= [ acc ]
    [ k m 0 s lenof prim >=
      [ m s 1 prim + 0 acc l1b ]
      [ m s k 1 prim + acc m 0 s k bi rd prim seq-int.push l1b ] if ] if } ;

: main
  (forall ρ; ρ s1:Int w1:Int s2:Int w2:Int ad:Seq Int wrs:Seq Bool --
   ρ hit1:Int miss1:Int hit2:Int miss2:Int rds:Int wts:Int dirty:Int blks:Seq Int)
  locals { s1 w1 s2 w2 ad wrs } {
    prim seq-int.empty 430 pad
    420 s1 wr 421 w1 wr 422 s2 wr 423 w2 wr
    ad wrs 0 sim
    locals { m } {
      m 400 rd m 401 rd m 402 rd m 403 rd m 404 rd m 405 rd
      m 0 0 m 420 rd 0 0 dc
      m 200 0 m 422 rd 0 0 dc prim +
      m 0 0 prim seq-int.empty l1b } } ;
```

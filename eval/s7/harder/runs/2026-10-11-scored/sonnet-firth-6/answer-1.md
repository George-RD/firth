### task: sokoban
```firth
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

### task: checkers
```firth
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

: sl
  (forall ρ; ρ m:Seq Int^many k:Int^many h:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m k h acc } {
    k h prim <
    [ m k 1 prim + h acc m k sget prim seq-int.push sl ]
    [ acc ] if };

: nb3
  (forall ρ; ρ r:Int^many c:Int^many -- ρ n:Int^many)
  locals { r c } {
    r 0 prim >= r 7 prim <= prim and c 0 prim >= c 7 prim <= prim and prim and
    [ r 4 prim * c 2 prim div prim + ] [ -1 ] if };

: nb2
  (forall ρ; ρ r:Int^many c:Int^many d:Int^many -- ρ n:Int^many)
  locals { r c d } {
    r d 2 prim div 2 prim * prim + 1 prim -
    c d 2 prim mod 2 prim * prim + 1 prim -
    nb3 };

: nb
  (forall ρ; ρ sq:Int^many d:Int^many -- ρ n:Int^many)
  locals { sq d } {
    sq 4 prim div
    sq 4 prim mod 2 prim * 1 prim + sq 4 prim div 2 prim mod prim -
    d nb2 };

: ft
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } {
    i 128 prim <
    [ m 32 i prim + i 4 prim div i 4 prim mod nb sput i 1 prim + ft ]
    [ m ] if };

: allowed
  (forall ρ; ρ pc:Int^many d:Int^many -- ρ b:Bool^many)
  locals { pc d } {
    pc 2 prim mod 0 prim =
    pc 1 prim = d 2 prim < prim and prim or
    pc 3 prim = d 1 prim > prim and prim or };

: enemy
  (forall ρ; ρ x:Int^many pc:Int^many -- ρ b:Bool^many)
  locals { x pc } {
    x 0 prim > x 1 prim - 2 prim div pc 1 prim - 2 prim div prim = prim not prim and };

: crown
  (forall ρ; ρ pc:Int^many j:Int^many -- ρ b:Bool^many)
  locals { pc j } {
    pc 1 prim = j 4 prim div 0 prim = prim and
    pc 3 prim = j 4 prim div 7 prim = prim and prim or };

: jl3
  (forall ρ; ρ m:Seq Int^many n2:Int^many -- ρ j:Int^many)
  locals { m n2 } {
    n2 0 prim >=
    [ m n2 sget 0 prim = [ n2 ] [ -1 ] if ]
    [ -1 ] if };

: jl2
  (forall ρ; ρ m:Seq Int^many pc:Int^many d:Int^many n1:Int^many -- ρ j:Int^many)
  locals { m pc d n1 } {
    n1 0 prim >=
    [ m n1 sget pc enemy
      [ m m 32 n1 4 prim * d prim + prim + sget jl3 ]
      [ -1 ] if ]
    [ -1 ] if };

: jl
  (forall ρ; ρ m:Seq Int^many sq:Int^many pc:Int^many d:Int^many -- ρ j:Int^many)
  locals { m sq pc d } {
    pc d allowed
    [ m pc d m 32 sq 4 prim * d prim + prim + sget jl2 ]
    [ -1 ] if };

: rec
  (forall ρ; ρ m:Seq Int^many sq:Int^many pc:Int^many cnt:Int^many crowned:Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { m sq pc cnt crowned best } {
    cnt best 32 sget prim >
    [ best 32 cnt sput 33 crowned sput 0 m sq pc sput 0 32 blit ]
    [ best ] if };

: tk2
  (forall ρ; ρ m2:Seq Int^many j:Int^many pc:Int^many cnt:Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { m2 j pc cnt best } {
    pc j crown
    [ m2 j pc 1 prim + cnt 1 prim + 1 best rec ]
    [ m2 j pc cnt 1 prim + best 0 0 dd ] if };

: tk
  (forall ρ; ρ m:Seq Int^many sq:Int^many pc:Int^many cnt:Int^many best:Seq Int^many d:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m sq pc cnt best d j } {
    m m 32 sq 4 prim * d prim + prim + sget 0 sput j pc cnt best tk2 };

: dd2
  (forall ρ; ρ m:Seq Int^many sq:Int^many pc:Int^many cnt:Int^many best:Seq Int^many d:Int^many any:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m sq pc cnt best d any j } {
    j 0 prim <
    [ m sq pc cnt best d 1 prim + any dd ]
    [ m sq pc cnt m sq pc cnt best d j tk d 1 prim + 1 dd ] if };

: dd
  (forall ρ; ρ m:Seq Int^many sq:Int^many pc:Int^many cnt:Int^many best:Seq Int^many d:Int^many any:Int^many -- ρ r:Seq Int^many)
  locals { m sq pc cnt best d any } {
    d 4 prim =
    [ any 0 prim = cnt 0 prim > prim and
      [ m sq pc cnt 0 best rec ] [ best ] if ]
    [ m sq pc cnt best d any m sq pc d jl dd2 ] if };

: fc
  (forall ρ; ρ m:Seq Int^many sq:Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { m sq best } {
    sq 32 prim <
    [ m sq sget 1 prim - 2 prim div m 164 sget prim =
      [ m sq 1 prim + m sq 0 sput sq m sq sget 0 best 0 0 dd fc ]
      [ m sq 1 prim + best fc ] if ]
    [ best ] if };

: emp
  (forall ρ; ρ m:Seq Int^many n:Int^many -- ρ b:Bool^many)
  locals { m n } {
    n 0 prim >= [ m n sget 0 prim = ] [ false ] if };

: cs2
  (forall ρ; ρ m:Seq Int^many i:Int^many pc:Int^many -- ρ b:Bool^many)
  locals { m i pc } {
    pc 1 prim - 2 prim div m 164 sget prim =
    [ pc i 4 prim mod allowed
      [ m m 32 i prim + sget emp ] [ false ] if ]
    [ false ] if };

: cs
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ b:Bool^many)
  locals { m i } { m i m i 4 prim div sget cs2 };

: fs
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many)
  locals { m i } {
    i 128 prim <
    [ m i cs [ i ] [ m i 1 prim + fs ] if ]
    [ -1 ] if };

: applycap
  (forall ρ; ρ m:Seq Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { m best } {
    m 0 best 0 32 blit
    160 1 add
    161 m 164 sget prim + best 32 sget add
    163 best 33 sget add
    164 1 m 164 sget prim - sput };

: as2
  (forall ρ; ρ m:Seq Int^many sq:Int^many n:Int^many pc:Int^many -- ρ r:Seq Int^many)
  locals { m sq n pc } {
    m sq 0 sput n pc pc n crown [ 1 prim + ] [ ] if sput
    160 1 add
    163 pc n crown [ 1 ] [ 0 ] if add
    164 1 m 164 sget prim - sput };

: applystep
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } {
    m i 4 prim div m 32 i prim + sget m i 4 prim div sget as2 };

: play3
  (forall ρ; ρ m:Seq Int^many idx:Int^many -- ρ r:Seq Int^many)
  locals { m idx } {
    idx 0 prim <
    [ m 166 m 164 sget 0 prim = [ 2 ] [ 1 ] if sput ]
    [ m 165 sget m 160 sget prim <=
      [ m ]
      [ m idx applystep play ] if ] if };

: play2
  (forall ρ; ρ m:Seq Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { m best } {
    best 32 sget 0 prim >
    [ m 165 sget m 160 sget prim <=
      [ m ]
      [ m best applycap play ] if ]
    [ m m 0 fs play3 ] if };

: play
  (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } {
    m m 0 prim seq-int.empty 34 grow fc play2 };

: fin
  (forall ρ; ρ m:Seq Int^many -- ρ b:Seq Int^many played:Int^many wt:Int^many bt:Int^many cr:Int^many res:Int^many)
  locals { m } {
    m 0 32 prim seq-int.empty sl
    m 160 sget m 161 sget m 162 sget m 163 sget m 166 sget };

: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ b:Seq Int^many played:Int^many wt:Int^many bt:Int^many cr:Int^many res:Int^many)
  locals { board turn plies } {
    prim seq-int.empty 170 grow
    0 board 0 32 blit
    164 turn sput
    165 plies sput
    0 ft
    play
    fin };
```

### task: regex
```firth
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

### task: swiss
```firth
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

: sl
  (forall ρ; ρ m:Seq Int^many k:Int^many h:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m k h acc } {
    k h prim <
    [ m k 1 prim + h acc m k sget prim seq-int.push sl ]
    [ acc ] if };

: mk
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    p m 230 sget prim <
    [ m 192 p prim + m p sget 4096 prim * m 232 p prim + sget prim + 16 prim * 15 p prim - prim + sput
      p 1 prim + mk ]
    [ m ] if };

: mk2
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    p m 230 sget prim <
    [ m 192 p prim + m p sget 128 prim * m 250 p prim + sget prim + 4096 prim * m 232 p prim + sget prim + 16 prim * 15 p prim - prim + sput
      p 1 prim + mk2 ]
    [ m ] if };

: am
  (forall ρ; ρ m:Seq Int^many i:Int^many b:Int^many bi:Int^many -- ρ r:Int^many)
  locals { m i b bi } {
    i m 230 sget prim <
    [ m 192 i prim + sget b prim >
      [ m i 1 prim + m 192 i prim + sget i am ]
      [ m i 1 prim + b bi am ] if ]
    [ bi ] if };

: ob2
  (forall ρ; ρ m:Seq Int^many t:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m t k } {
    m 204 t prim + k sput 192 k prim + -1 sput t 1 prim + ob };

: ob
  (forall ρ; ρ m:Seq Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { m t } {
    t m 230 sget prim <
    [ m t m 0 -1 0 am ob2 ]
    [ m ] if };

: cl0
  (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } {
    i 12 prim <
    [ m 216 i prim + 0 sput i 1 prim + cl0 ]
    [ m ] if };

: by2
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    m 216 p prim + 1 sput 36 p prim + 1 sput 0 p prim + 2 add };

: by
  (forall ρ; ρ m:Seq Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { m t } {
    m 36 m 204 t prim + sget prim + sget 0 prim =
    [ m m 204 t prim + sget by2 ]
    [ m t 1 prim - by ] if };

: fq2
  (forall ρ; ρ m:Seq Int^many p:Int^many u:Int^many md:Int^many q:Int^many -- ρ r:Int^many)
  locals { m p u md q } {
    m 216 q prim + sget 0 prim =
    md 1 prim = m 48 p 12 prim * prim + q prim + sget 0 prim = prim or
    prim and
    [ q ] [ m p u 1 prim + md fq ] if };

: fq
  (forall ρ; ρ m:Seq Int^many p:Int^many u:Int^many md:Int^many -- ρ r:Int^many)
  locals { m p u md } {
    u m 230 sget prim <
    [ m p u md m 204 u prim + sget fq2 ]
    [ -1 ] if };

: wh
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many -- ρ w:Int^many)
  locals { m p q } {
    m 12 p prim + sget m 12 q prim + sget prim <
    [ p ]
    [ m 12 q prim + sget m 12 p prim + sget prim <
      [ q ]
      [ m 24 p prim + sget 2 prim = m 24 q prim + sget 2 prim = prim not prim and
        [ p ]
        [ m 24 q prim + sget 2 prim = m 24 p prim + sget 2 prim = prim not prim and
          [ q ] [ p ] if ] if ] if ] if };

: sc
  (forall ρ; ρ m:Seq Int^many w:Int^many b:Int^many r:Int^many -- ρ x:Seq Int^many)
  locals { m w b r } {
    r 0 prim =
    [ m w 2 add ]
    [ r 1 prim = [ m w 1 add b 1 add ] [ m b 2 add ] if ] if };

: pg3
  (forall ρ; ρ m:Seq Int^many t:Int^many p:Int^many q:Int^many w:Int^many b:Int^many -- ρ x:Seq Int^many)
  locals { m t p q w b } {
    m 216 p prim + 1 sput 216 q prim + 1 sput
    12 w prim + 1 add
    24 w prim + 1 sput 24 b prim + 2 sput
    48 p 12 prim * prim + q prim + 1 add
    48 q 12 prim * prim + p prim + 1 add
    w b m 244 m 229 sget prim + sget sc
    229 1 add
    t 1 prim + pr };

: pg2
  (forall ρ; ρ m:Seq Int^many t:Int^many p:Int^many q:Int^many w:Int^many -- ρ x:Seq Int^many)
  locals { m t p q w } {
    m t p q w w p prim = [ q ] [ p ] if pg3 };

: pg
  (forall ρ; ρ m:Seq Int^many t:Int^many p:Int^many q:Int^many -- ρ x:Seq Int^many)
  locals { m t p q } {
    m t p q m p q wh pg2 };

: pr4
  (forall ρ; ρ m:Seq Int^many t:Int^many p:Int^many q:Int^many -- ρ x:Seq Int^many)
  locals { m t p q } {
    q 0 prim <
    [ m 228 1 add t p m p t 1 prim + 1 fq pg ]
    [ m t p q pg ] if };

: pr3
  (forall ρ; ρ m:Seq Int^many t:Int^many p:Int^many -- ρ x:Seq Int^many)
  locals { m t p } {
    m t p m p t 1 prim + 0 fq pr4 };

: pr
  (forall ρ; ρ m:Seq Int^many t:Int^many -- ρ x:Seq Int^many)
  locals { m t } {
    t m 230 sget prim <
    [ m 216 m 204 t prim + sget prim + sget 1 prim =
      [ m t 1 prim + pr ]
      [ m t m 204 t prim + sget pr3 ] if ]
    [ m ] if };

: rd2
  (forall ρ; ρ m:Seq Int^many -- ρ x:Seq Int^many)
  locals { m } {
    m 230 sget 2 prim mod 1 prim =
    [ m m 230 sget 1 prim - by ]
    [ m ] if
    0 pr };

: round
  (forall ρ; ρ m:Seq Int^many -- ρ x:Seq Int^many)
  locals { m } {
    m 0 mk 0 ob 0 cl0 rd2 };

: rl
  (forall ρ; ρ m:Seq Int^many r:Int^many rr:Int^many -- ρ x:Seq Int^many)
  locals { m r rr } {
    r rr prim <
    [ m round r 1 prim + rr rl ]
    [ m ] if };

: bs
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many acc:Int^many -- ρ x:Int^many)
  locals { m p q acc } {
    q m 230 sget prim <
    [ m p q 1 prim + acc m 48 p 12 prim * prim + q prim + sget m q sget prim * prim + bs ]
    [ acc ] if };

: bu
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ x:Seq Int^many)
  locals { m p } {
    p m 230 sget prim <
    [ m 250 p prim + m p 0 0 bs sput p 1 prim + bu ]
    [ m ] if };

: fo
  (forall ρ; ρ m:Seq Int^many -- ρ sc:Seq Int^many bh:Seq Int^many rk:Seq Int^many wt:Seq Int^many rm:Int^many)
  locals { m } {
    m 0 m 230 sget prim seq-int.empty sl
    m 250 m 230 sget 250 prim + prim seq-int.empty sl
    m 204 m 230 sget 204 prim + prim seq-int.empty sl
    m 12 m 230 sget 12 prim + prim seq-int.empty sl
    m 228 sget };

: fin
  (forall ρ; ρ m:Seq Int^many -- ρ sc:Seq Int^many bh:Seq Int^many rk:Seq Int^many wt:Seq Int^many rm:Int^many)
  locals { m } {
    m 0 bu 0 mk2 0 ob fo };

: main
  (forall ρ; ρ rt:Seq Int^many rr:Int^many res:Seq Int^many -- ρ sc:Seq Int^many bh:Seq Int^many rk:Seq Int^many wt:Seq Int^many rm:Int^many)
  locals { rt rr res } {
    prim seq-int.empty 290 grow
    230 rt prim seq-int.len sput
    232 rt 0 rt prim seq-int.len blit
    244 res 0 res prim seq-int.len blit
    0 rr rl
    fin };
```

### task: warehouse
```firth
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

: sl
  (forall ρ; ρ m:Seq Int^many k:Int^many h:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m k h acc } {
    k h prim <
    [ m k 1 prim + h acc m k sget prim seq-int.push sl ]
    [ acc ] if };

: la
  (forall ρ; ρ p:Int^many i:Int^many -- ρ r:Int^many)
  locals { p i } { 470 p 144 prim * prim + i prim + };

: ea
  (forall ρ; ρ p:Int^many i:Int^many -- ρ r:Int^many)
  locals { p i } { 1190 p 144 prim * prim + i prim + };

: ba
  (forall ρ; ρ p:Int^many i:Int^many -- ρ r:Int^many)
  locals { p i } { 1910 p 80 prim * prim + i prim + };

: bda
  (forall ρ; ρ p:Int^many i:Int^many -- ρ r:Int^many)
  locals { p i } { 2310 p 80 prim * prim + i prim + };

: ship
  (forall ρ; ρ m:Seq Int^many p:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m p x } { m 3 x add 2 x m 20 p prim + sget prim * add };

: tk4
  (forall ρ; ρ m:Seq Int^many p:Int^many x:Int^many h:Int^many q:Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { m p x h q t } {
    m p h la q t prim - sput
    10 p prim + 0 t prim - add
    q t prim = [ 45 p prim + 1 add ] [ ] if
    p x t prim - take };

: tk3
  (forall ρ; ρ m:Seq Int^many p:Int^many x:Int^many h:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { m p x h q } {
    m p x h q q x prim < [ q ] [ x ] if tk4 };

: tk2
  (forall ρ; ρ m:Seq Int^many p:Int^many x:Int^many h:Int^many -- ρ r:Seq Int^many)
  locals { m p x h } { m p x h m p h la sget tk3 };

: take
  (forall ρ; ρ m:Seq Int^many p:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m p x } {
    x 0 prim >
    [ m p x m 45 p prim + sget tk2 ]
    [ m ] if };

: tas
  (forall ρ; ρ m:Seq Int^many p:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m p x } { m p x take p x ship };

: fill3
  (forall ρ; ρ m:Seq Int^many p:Int^many o:Int^many s:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m p o s x } {
    m p x tas
    p m 55 p prim + sget ba o x prim - sput
    x o prim = [ 55 p prim + 1 add ] [ ] if
    p fill };

: fill2
  (forall ρ; ρ m:Seq Int^many p:Int^many o:Int^many s:Int^many -- ρ r:Seq Int^many)
  locals { m p o s } {
    m p o s o s prim < [ o ] [ s ] if fill3 };

: fill
  (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    m 55 p prim + sget m 60 p prim + sget prim <
    m 10 p prim + sget 0 prim > prim and
    [ m p m p m 55 p prim + sget ba sget m 10 p prim + sget fill2 ]
    [ m ] if };

: place
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m p q e j } {
    m p j la q sput p j ea e sput
    50 p prim + 1 add
    10 p prim + q add
    p fill };

: sh
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m p q e i } {
    m p i 1 prim + la m p i la sget sput
    p i 1 prim + ea m p i ea sget sput
    p q e i 1 prim - ins };

: ins
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m p q e i } {
    i m 45 p prim + sget prim >=
    [ m p i ea sget e prim >
      [ m p q e i sh ]
      [ m p q e i 1 prim + place ] if ]
    [ m p q e i 1 prim + place ] if };

: arrive
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m p q e } {
    m p q e m 50 p prim + sget 1 prim - ins };

: enq
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p q d } {
    m p m 60 p prim + sget ba q sput
    p m 60 p prim + sget bda d sput
    60 p prim + 1 add };

: enq0
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p q d } {
    q 0 prim > [ m p q d enq ] [ m ] if };

: ord2
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many d:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m p q d x } {
    m p x tas p q x prim - d enq0 };

: order
  (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p q d } {
    m 55 p prim + sget m 60 p prim + sget prim <
    [ m p q d enq ]
    [ m p q d m 10 p prim + sget q prim < [ m 10 p prim + sget ] [ q ] if ord2 ] if };

: ev1
  (forall ρ; ρ m:Seq Int^many d:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m d e } {
    m 150 e prim + sget 1 prim =
    [ m m 230 e prim + sget m 310 e prim + sget m 390 e prim + sget arrive
      7 1 add d evl ]
    [ m m 230 e prim + sget m 310 e prim + sget d order
      7 1 add d evl ] if };

: evl
  (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    m 7 sget m 8 sget prim <
    [ m 70 m 7 sget prim + sget d prim =
      [ m d m 7 sget ev1 ] [ m ] if ]
    [ m ] if };

: dsc3
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { m p d q } {
    m 4 q add
    10 p prim + 0 q prim - add
    45 p prim + 1 add
    p d dsc };

: dsc2
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    m p d m p m 45 p prim + sget la sget dsc3 };

: dsc
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    m 45 p prim + sget m 50 p prim + sget prim <
    [ m p m 45 p prim + sget ea sget d prim <
      [ m p d dsc2 ] [ m ] if ]
    [ m ] if };

: dall
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    p m 0 sget prim <
    [ m p d dsc p 1 prim + d dall ]
    [ m ] if };

: sup
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    p m 0 sget prim <
    [ m 15 p prim + sget d prim =
      [ m p m 30 p prim + sget d m 40 p prim + sget prim + arrive
        15 p prim + -1 sput p 1 prim + d sup ]
      [ m p 1 prim + d sup ] if ]
    [ m ] if };

: cnl
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    p m 0 sget prim <
    [ m 55 p prim + sget m 60 p prim + sget prim <
      [ m p m 55 p prim + sget bda sget d 7 prim - prim <=
        [ m 5 m p m 55 p prim + sget ba sget add 55 p prim + 1 add p d cnl ]
        [ m p 1 prim + d cnl ] if ]
      [ m p 1 prim + d cnl ] if ]
    [ m ] if };

: reo
  (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    p m 0 sget prim <
    [ m 15 p prim + sget 0 prim < m 10 p prim + sget m 25 p prim + sget prim <= prim and
      [ m 15 p prim + d m 35 p prim + sget prim + sput 6 1 add p 1 prim + d reo ]
      [ m p 1 prim + d reo ] if ]
    [ m ] if };

: day
  (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    d m 1 sget prim <
    [ m 0 d dall 0 d sup d evl 0 d cnl 0 d reo d 1 prim + day ]
    [ m ] if };

: owp
  (forall ρ; ρ m:Seq Int^many p:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m p i acc } {
    i m 60 p prim + sget prim <
    [ m p i 1 prim + acc m p i ba sget prim + owp ]
    [ acc ] if };

: owa
  (forall ρ; ρ m:Seq Int^many p:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m p acc } {
    p m 0 sget prim <
    [ m p 1 prim + acc m p m 55 p prim + sget 0 owp prim + owa ]
    [ acc ] if };

: fin
  (forall ρ; ρ m:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { m } {
    m 10 m 0 sget 10 prim + prim seq-int.empty sl
    m 2 sget m 3 sget m 4 sget m 5 sget m 6 sget
    m 0 0 owa };

: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many eve:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf evd evk evp evq eve } {
    prim seq-int.empty 2720 grow
    0 price prim seq-int.len sput
    1 days sput
    8 evd prim seq-int.len sput
    15 -1 sput 16 -1 sput 17 -1 sput 18 -1 sput 19 -1 sput
    20 price 0 price prim seq-int.len blit
    25 rp 0 rp prim seq-int.len blit
    30 rq 0 rq prim seq-int.len blit
    35 lead 0 lead prim seq-int.len blit
    40 shelf 0 shelf prim seq-int.len blit
    70 evd 0 evd prim seq-int.len blit
    150 evk 0 evk prim seq-int.len blit
    230 evp 0 evp prim seq-int.len blit
    310 evq 0 evq prim seq-int.len blit
    390 eve 0 eve prim seq-int.len blit
    0 day
    fin };
```

### task: cache-sim
```firth
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

: ba
  (forall ρ; ρ lv:Int^many s:Int^many i:Int^many -- ρ r:Int^many)
  locals { lv s i } { 32 lv 128 prim * prim + s 8 prim * prim + i prim + };

: da
  (forall ρ; ρ lv:Int^many s:Int^many i:Int^many -- ρ r:Int^many)
  locals { lv s i } { 96 lv 128 prim * prim + s 8 prim * prim + i prim + };

: cn
  (forall ρ; ρ lv:Int^many s:Int^many -- ρ r:Int^many)
  locals { lv s } { 16 lv 8 prim * prim + s prim + };

: fd
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many b:Int^many i:Int^many -- ρ r:Int^many)
  locals { m lv s b i } {
    i m lv s cn sget prim <
    [ m lv s i ba sget b prim =
      [ i ] [ m lv s b i 1 prim + fd ] if ]
    [ -1 ] if };

: sf
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m lv s j } {
    j m lv s cn sget 1 prim - prim <
    [ m lv s j ba m lv s j 1 prim + ba sget sput
      lv s j da m lv s j 1 prim + da sget sput
      lv s j 1 prim + sf ]
    [ m ] if };

: ua2
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many i:Int^many b:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m lv s i b d } {
    m lv s i sf
    lv s m lv s cn sget 1 prim - ba b sput
    lv s m lv s cn sget 1 prim - da d sput };

: ua
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m lv s i } {
    m lv s i m lv s i ba sget m lv s i da sget ua2 };

: mkd
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many -- ρ r:Seq Int^many)
  locals { m lv s } {
    m lv s m lv s cn sget 1 prim - da 1 sput };

: pf
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many b:Int^many dv:Int^many -- ρ r:Seq Int^many ev:Int^many)
  locals { m lv s b dv } {
    m lv s 0 sf
    lv s m lv s cn sget 1 prim - ba b sput
    lv s m lv s cn sget 1 prim - da dv sput
    m lv s 0 ba sget 2 prim * m lv s 0 da sget prim + };

: pn
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many b:Int^many dv:Int^many -- ρ r:Seq Int^many ev:Int^many)
  locals { m lv s b dv } {
    m lv s m lv s cn sget ba b sput
    lv s m lv s cn sget da dv sput
    lv s cn 1 add
    -1 };

: put
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many b:Int^many dv:Int^many -- ρ r:Seq Int^many ev:Int^many)
  locals { m lv s b dv } {
    m lv s cn sget m 9 lv 2 prim * prim + sget prim >=
    [ m lv s b dv pf ]
    [ m lv s b dv pn ] if };

: mw
  (forall ρ; ρ m:Seq Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m e } {
    e 0 prim >=
    [ e 2 prim mod 1 prim = [ m 5 1 add ] [ m ] if ]
    [ m ] if };

: wb3
  (forall ρ; ρ m:Seq Int^many x:Int^many s:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m x s k } {
    k 0 prim >=
    [ m 1 s k ua 1 s mkd ]
    [ m 1 s x 1 put mw ] if };

: wb2
  (forall ρ; ρ m:Seq Int^many x:Int^many s:Int^many -- ρ r:Seq Int^many)
  locals { m x s } {
    m x s m 1 s x 0 fd wb3 };

: wb
  (forall ρ; ρ m:Seq Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m x } {
    m x x m 10 sget prim mod wb2 };

: l1e
  (forall ρ; ρ m:Seq Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m e } {
    e 0 prim >=
    [ e 2 prim mod 1 prim = [ m e 2 prim div wb ] [ m ] if ]
    [ m ] if };

: a6
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many s1:Int^many -- ρ r:Seq Int^many)
  locals { m b w s1 } {
    m 0 s1 b w put l1e };

: a5
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many s1:Int^many s2:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m b w s1 s2 j } {
    j 0 prim >=
    [ m 2 1 add 1 s2 j ua b w s1 a6 ]
    [ m 3 1 add 4 1 add 1 s2 b 0 put mw b w s1 a6 ] if };

: a4b
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many s1:Int^many s2:Int^many -- ρ r:Seq Int^many)
  locals { m b w s1 s2 } {
    m b w s1 s2 m 1 s2 b 0 fd a5 };

: a4
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many s1:Int^many -- ρ r:Seq Int^many)
  locals { m b w s1 } {
    m b w s1 b m 10 sget prim mod a4b };

: a3
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many s1:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m b w s1 i } {
    i 0 prim >=
    [ m 0 1 add 0 s1 i ua w 1 prim = [ 0 s1 mkd ] [ ] if ]
    [ m 1 1 add b w s1 a4 ] if };

: acs
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many -- ρ r:Seq Int^many)
  locals { m b w } {
    m b w b m 8 sget prim mod acs2 };

: acs2
  (forall ρ; ρ m:Seq Int^many b:Int^many w:Int^many s1:Int^many -- ρ r:Seq Int^many)
  locals { m b w s1 } {
    m b w s1 m 0 s1 b 0 fd a3 };

: lp
  (forall ρ; ρ m:Seq Int^many a:Seq Int^many w:Seq Bool^many i:Int^many -- ρ r:Seq Int^many)
  locals { m a w i } {
    i a prim seq-int.len prim <
    [ m a i prim seq-int.at w i prim seq-bool.at [ 1 ] [ 0 ] if acs
      a w i 1 prim + lp ]
    [ m ] if };

: dcs
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m lv s i acc } {
    i m lv s cn sget prim <
    [ m lv s i 1 prim + acc m lv s i da sget prim + dcs ]
    [ acc ] if };

: dcl
  (forall ρ; ρ m:Seq Int^many lv:Int^many s:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m lv s acc } {
    s m 8 lv 2 prim * prim + sget prim <
    [ m lv s 1 prim + acc m lv s 0 0 dcs prim + dcl ]
    [ acc ] if };

: bls
  (forall ρ; ρ m:Seq Int^many s:Int^many i:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m s i acc } {
    i m 0 s cn sget prim <
    [ m s i 1 prim + acc m 0 s i ba sget prim seq-int.push bls ]
    [ acc ] if };

: bll
  (forall ρ; ρ m:Seq Int^many s:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m s acc } {
    s m 8 sget prim <
    [ m s 1 prim + m s 0 acc bls bll ]
    [ acc ] if };

: fin
  (forall ρ; ρ m:Seq Int^many -- ρ h1:Int^many m1:Int^many h2:Int^many m2:Int^many rd:Int^many wr:Int^many dirty:Int^many blocks:Seq Int^many)
  locals { m } {
    m 0 sget m 1 sget m 2 sget m 3 sget m 4 sget m 5 sget
    m 0 0 0 dcl m 1 0 0 dcl prim +
    m 0 prim seq-int.empty bll };

: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ h1:Int^many m1:Int^many h2:Int^many m2:Int^many rd:Int^many wr:Int^many dirty:Int^many blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    prim seq-int.empty 290 grow
    8 s1 sput 9 w1 sput 10 s2 sput 11 w2 sput
    addrs writes 0 lp
    fin };
```

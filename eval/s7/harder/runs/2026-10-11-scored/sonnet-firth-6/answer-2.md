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
  locals { m e } { m e m e 16 prim div dlt undo4 };

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
  locals { m p s } { m p m p ie 1 prim - s it };

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

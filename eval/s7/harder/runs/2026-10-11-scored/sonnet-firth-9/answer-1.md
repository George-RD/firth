### task: sokoban
```firth
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i m i gt 1 prim + st };
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: delta (forall ρ; ρ w:Int^many dir:Int^many -- ρ d:Int^many)
  locals { w dir } { dir 0 prim = [ 0 w prim - ] [ dir 1 prim = [ 1 ] [ dir 2 prim = [ w ] [ -1 ] if ] if ] if };
: bx (forall ρ; ρ m:Seq Int^many cell:Int^many k:Int^many -- ρ r:Int^many)
  locals { m cell k } {
    k m 152 gt prim >= [ -1 ]
    [ m k 160 prim + gt cell prim = [ k ] [ m cell k 1 prim + bx ] if ] if };
: boxat (forall ρ; ρ m:Seq Int^many cell:Int^many -- ρ r:Int^many)
  locals { m cell } { m cell 0 bx };
: ag (forall ρ; ρ m:Seq Int^many k:Int^many -- ρ r:Bool^many)
  locals { m k } {
    k m 152 gt prim >= [ true ]
    [ m m k 160 prim + gt gt 2 prim = [ m k 1 prim + ag ] [ false ] if ] if };
: allgoal (forall ρ; ρ m:Seq Int^many -- ρ r:Bool^many)
  locals { m } { m 0 ag };
: deadw (forall ρ; ρ m:Seq Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { m u } {
    m u gt 2 prim = prim not
    m u m 151 gt prim - gt 1 prim = m u m 151 gt prim + gt 1 prim = prim or prim and
    m u 1 prim - gt 1 prim = m u 1 prim + gt 1 prim = prim or prim and
    [ m 150 bump ] [ m ] if };
: rec (forall ρ; ρ m:Seq Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m e } { m 170 m 146 gt prim + e st 146 bump };
: stp (forall ρ; ρ m:Seq Int^many t:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m t e } { m 144 t st e rec };
: mv5 (forall ρ; ρ m:Seq Int^many dir:Int^many t:Int^many k:Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { m dir t k u } {
    m u gt 1 prim = m u boxat 0 prim >= prim or
    [ m 148 bump ]
    [ m 160 k prim + u st 144 t st dir 2 prim * 1 prim + rec 147 bump u deadw ] if };
: mv4 (forall ρ; ρ m:Seq Int^many dir:Int^many d:Int^many t:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m dir d t k } {
    k 0 prim < [ m t dir 2 prim * stp ] [ m dir t k t d prim + mv5 ] if };
: mv3 (forall ρ; ρ m:Seq Int^many dir:Int^many d:Int^many t:Int^many -- ρ r:Seq Int^many)
  locals { m dir d t } {
    m t gt 1 prim = [ m 148 bump ] [ m dir d t m t boxat mv4 ] if };
: mva (forall ρ; ρ m:Seq Int^many dir:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m dir d } { m dir d m 144 gt d prim + mv3 };
: domv (forall ρ; ρ m:Seq Int^many dir:Int^many -- ρ r:Seq Int^many)
  locals { m dir } { m dir m 151 gt dir delta mva };
: ub (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } { m 160 m m 144 gt d prim + boxat prim + m 144 gt st };
: und5 (forall ρ; ρ m:Seq Int^many h:Int^many e:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m h e d } {
    m 146 h st 149 bump
    e 2 prim mod 1 prim = [ d ub ] [ ] if
    144 m 144 gt d prim - st };
: und4 (forall ρ; ρ m:Seq Int^many h:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m h e } { m h e m 151 gt e 2 prim div delta und5 };
: und3 (forall ρ; ρ m:Seq Int^many h:Int^many -- ρ r:Seq Int^many)
  locals { m h } { m h m 170 h prim + gt und4 };
: undo2 (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m m 146 gt 1 prim - und3 };
: undo (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m 146 gt 0 prim > [ m undo2 ] [ m ] if };
: ap (forall ρ; ρ m:Seq Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { m c } { c 4 prim = [ m undo ] [ m c domv ] if };
: lp (forall ρ; ρ m:Seq Int^many moves:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m moves i } {
    i moves prim seq-int.len prim >= m allgoal prim or
    [ m 145 i st ]
    [ m moves i prim seq-int.at ap moves i 1 prim + lp ] if };
: colb (forall ρ; ρ out:Seq Int^many m:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { out m k } {
    k m 152 gt prim >= [ out ]
    [ out m k 160 prim + gt prim seq-int.push m k 1 prim + colb ] if };
: cpb (forall ρ; ρ m:Seq Int^many boxes:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m boxes i } {
    i boxes prim seq-int.len prim >= [ m ]
    [ m 160 i prim + boxes i prim seq-int.at st boxes i 1 prim + cpb ] if };
: fin (forall ρ; ρ m:Seq Int^many -- ρ a:Int^many b:Seq Int^many c:Int^many d:Int^many e:Int^many f:Int^many g:Int^many h:Int^many i:Bool^many)
  locals { m } {
    m 144 gt prim seq-int.empty m 0 colb
    m 145 gt m 146 gt m 147 gt m 148 gt m 149 gt m 150 gt m allgoal };
: main (forall ρ; ρ width:Int^many height:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ a:Int^many b:Seq Int^many c:Int^many d:Int^many e:Int^many f:Int^many g:Int^many h:Int^many i:Bool^many)
  locals { w h cells pl boxes moves } {
    cells 400 pad 144 pl st 151 w st 152 boxes prim seq-int.len st
    boxes 0 cpb moves 0 lp fin };
```

### task: checkers
```firth
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: addto (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { m i v } { m i m i gt v prim + st };
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i 1 addto };
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: sq (forall ρ; ρ r:Int^many c:Int^many -- ρ s:Int^many)
  locals { r c } {
    r 0 prim >= r 8 prim < prim and c 0 prim >= prim and c 8 prim < prim and
    [ r 4 prim * c 2 prim div prim + ] [ -1 ] if };
: col (forall ρ; ρ i:Int^many -- ρ c:Int^many)
  locals { i } { i 4 prim mod 2 prim * 1 prim + i 4 prim div 2 prim mod prim - };
: nb (forall ρ; ρ pos:Int^many dr:Int^many dc:Int^many -- ρ s:Int^many)
  locals { pos dr dc } { pos 4 prim div dr prim + pos col dc prim + sq };
: mid (forall ρ; ρ a:Int^many b:Int^many -- ρ s:Int^many)
  locals { a b } { a 4 prim div b 4 prim div prim + 2 prim div a col b col prim + 2 prim div sq };
: okdir (forall ρ; ρ piece:Int^many dr:Int^many -- ρ r:Bool^many)
  locals { piece dr } {
    piece 2 prim = piece 4 prim = prim or
    piece 1 prim = dr -1 prim = prim and prim or
    piece 3 prim = dr 1 prim = prim and prim or };
: en (forall ρ; ρ piece:Int^many x:Int^many -- ρ r:Bool^many)
  locals { piece x } {
    piece 3 prim < x 3 prim >= prim and
    piece 3 prim >= x 1 prim >= prim and x 2 prim <= prim and prim or };
: mine (forall ρ; ρ x:Int^many side:Int^many -- ρ r:Bool^many)
  locals { x side } { x 1 prim - 2 prim div side prim = };
: cpl (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m i d } {
    i d prim >= [ m ] [ m 40 i prim + m 70 i prim + gt st i 1 prim + d cpl ] if };
: leaf (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    d m 33 gt prim > [ m 33 d st 35 m 36 gt st 0 d cpl ] [ m ] if };
: jump2 (forall ρ; ρ m:Seq Int^many over:Int^many ep:Int^many piece:Int^many land:Int^many depth:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m over ep piece land depth } {
    m over 0 st 70 depth prim + land st
    piece 1 prim = land 4 prim < prim and piece 3 prim = land 28 prim >= prim and prim or
    [ depth 1 prim + leaf ] [ land depth 1 prim + piece dfs ] if
    over ep st 1 };
: tr4 (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many over:Int^many land:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m pos depth piece over land } {
    over 0 prim >= land 0 prim >= prim and
    [ m land gt 0 prim = piece m over gt en prim and
      [ m over m over gt piece land depth jump2 ] [ m 0 ] if ]
    [ m 0 ] if };
: tr2 (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many dr:Int^many dc:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m pos depth piece dr dc } {
    piece dr okdir
    [ m pos depth piece pos dr dc nb pos dr 2 prim * dc 2 prim * nb tr4 ]
    [ m 0 ] if };
: tr (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many idx:Int^many -- ρ r:Seq Int^many n:Int^many)
  locals { m pos depth piece idx } {
    m pos depth piece idx 2 prim < [ -1 ] [ 1 ] if idx 2 prim mod 0 prim = [ -1 ] [ 1 ] if tr2 };
: jl2 (forall ρ; ρ pos:Int^many depth:Int^many piece:Int^many idx:Int^many found:Int^many m:Seq Int^many n:Int^many -- ρ r:Seq Int^many f:Int^many)
  locals { pos depth piece idx found m n } {
    m pos depth piece idx 1 prim + found n prim + jl };
: jl (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many idx:Int^many found:Int^many -- ρ r:Seq Int^many f:Int^many)
  locals { m pos depth piece idx found } {
    idx 4 prim >= [ m found ]
    [ pos depth piece idx found m pos depth piece idx tr jl2 ] if };
: dfs2 (forall ρ; ρ depth:Int^many m:Seq Int^many found:Int^many -- ρ r:Seq Int^many)
  locals { depth m found } {
    found 0 prim = depth 0 prim > prim and [ m depth leaf ] [ m ] if };
: dfs (forall ρ; ρ m:Seq Int^many pos:Int^many depth:Int^many piece:Int^many -- ρ r:Seq Int^many)
  locals { m pos depth piece } { depth m pos depth piece 0 0 jl dfs2 };
: fc4 (forall ρ; ρ m:Seq Int^many s:Int^many pc:Int^many -- ρ r:Seq Int^many)
  locals { m s pc } { m s 0 st s 0 pc dfs s pc st };
: fc3 (forall ρ; ρ m:Seq Int^many s:Int^many -- ρ r:Seq Int^many)
  locals { m s } { m 36 s st s m s gt fc4 };
: fc (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m s side } {
    s 32 prim >= [ m ]
    [ m s gt side mine [ m s fc3 ] [ m ] if s 1 prim + side fc ] if };
: findcap (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m side } { m 0 side fc };
: ap1 (forall ρ; ρ m:Seq Int^many j:Int^many from:Int^many cnt:Int^many -- ρ r:Seq Int^many)
  locals { m j from cnt } {
    j cnt prim >= [ m ]
    [ m from m 40 j prim + gt mid 0 st j 1 prim + m 40 j prim + gt cnt ap1 ] if };
: ac2 (forall ρ; ρ m:Seq Int^many L:Int^many pc:Int^many side:Int^many cnt:Int^many -- ρ r:Seq Int^many)
  locals { m L pc side cnt } {
    pc 1 prim = L 4 prim < prim and pc 3 prim = L 28 prim >= prim and prim or
    [ m L pc 1 prim + st 39 bump ] [ m L pc st ] if
    side 0 prim = [ 37 cnt addto ] [ 38 cnt addto ] if };
: ac (forall ρ; ρ m:Seq Int^many cnt:Int^many s:Int^many pc:Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m cnt s pc side } {
    m s 0 st 0 s cnt ap1 m 40 cnt 1 prim - gt pc side cnt ac2 };
: applycap (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many)
  locals { m side } { m m 33 gt m 35 gt m m 35 gt gt side ac };
: mvs2 (forall ρ; ρ m:Seq Int^many d:Int^many pc:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m d pc } {
    pc 1 prim = d 4 prim < prim and pc 3 prim = d 28 prim >= prim and prim or
    [ m d pc 1 prim + st 39 bump 1 ] [ m d pc st 1 ] if };
: mvs (forall ρ; ρ m:Seq Int^many s:Int^many d:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s d } { m s 0 st d m s gt mvs2 };
: st3 (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many idx:Int^many d:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side idx d } {
    d 0 prim < [ m s side idx 1 prim + stp1 ]
    [ m d gt 0 prim = [ m s d mvs ] [ m s side idx 1 prim + stp1 ] if ] if };
: st2 (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many idx:Int^many dr:Int^many dc:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side idx dr dc } {
    m s gt dr okdir
    [ m s side idx s dr dc nb st3 ]
    [ m s side idx 1 prim + stp1 ] if };
: stp1 (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many idx:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side idx } {
    idx 4 prim >= [ m 0 ]
    [ m s side idx idx 2 prim < [ -1 ] [ 1 ] if idx 2 prim mod 0 prim = [ -1 ] [ 1 ] if st2 ] if };
: fs2 (forall ρ; ρ m:Seq Int^many ok:Int^many s:Int^many side:Int^many -- ρ r:Seq Int^many o:Int^many)
  locals { m ok s side } { ok 1 prim = [ m 1 ] [ m s 1 prim + side fs ] if };
: fs (forall ρ; ρ m:Seq Int^many s:Int^many side:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m s side } {
    s 32 prim >= [ m 0 ]
    [ m s gt side mine [ m s side 0 stp1 ] [ m 0 ] if s side fs2 ] if };
: findstep (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m side } { m 0 side fs };
: mv2 (forall ρ; ρ side:Int^many m:Seq Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { side m } {
    m 33 gt 0 prim > [ m side applycap 1 ] [ m side findstep ] if };
: mover (forall ρ; ρ m:Seq Int^many side:Int^many -- ρ r:Seq Int^many ok:Int^many)
  locals { m side } { side m 33 0 st side findcap mv2 };
: gm2 (forall ρ; ρ m0:Seq Int^many m1:Seq Int^many ok:Int^many -- ρ r:Seq Int^many)
  locals { m0 m1 ok } {
    ok 0 prim = [ m0 95 2 m0 96 gt prim - st ]
    [ m0 94 gt m0 97 gt prim >= [ m0 ]
      [ m1 94 bump 96 1 m0 96 gt prim - st gm ] if ] if };
: gm (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m m m 96 gt mover gm2 };
: bd (forall ρ; ρ out:Seq Int^many m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { out m i } {
    i 32 prim >= [ out ] [ out m i gt prim seq-int.push m i 1 prim + bd ] if };
: fin2 (forall ρ; ρ m:Seq Int^many -- ρ b:Seq Int^many a:Int^many c:Int^many d:Int^many e:Int^many f:Int^many)
  locals { m } {
    prim seq-int.empty m 0 bd m 94 gt m 37 gt m 38 gt m 39 gt m 95 gt };
: main (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ b:Seq Int^many a:Int^many c:Int^many d:Int^many e:Int^many f:Int^many)
  locals { board turn plies } {
    board 100 pad 96 turn st 97 plies st gm fin2 };
```

### task: regex
```firth
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: zs (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  locals { n } { prim seq-int.empty n pad };
: tok (forall ρ; ρ pt:Seq Int^many pos:Int^many -- ρ t:Int^many)
  locals { pt pos } { pos pt prim seq-int.len prim < [ pt pos prim seq-int.at ] [ -1 ] if };
: mk3 (forall ρ; ρ T:Seq Int^many base:Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { T base ty a b } { T base ty st base 1 prim + a st base 2 prim + b st };
: mk2 (forall ρ; ρ T:Seq Int^many n:Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many k:Int^many)
  locals { T n ty a b } { T 1 n 1 prim + st n 3 prim * 10 prim + ty a b mk3 n };
: mk (forall ρ; ρ T:Seq Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many k:Int^many)
  locals { T ty a b } { T T 1 gt ty a b mk2 };
: nt (forall ρ; ρ T:Seq Int^many n:Int^many k:Int^many -- ρ v:Int^many)
  locals { T n k } { T 10 n 3 prim * prim + k prim + gt };
: failn (forall ρ; ρ T:Seq Int^many -- ρ r:Seq Int^many n:Int^many pos:Int^many)
  locals { T } { T 0 1 st 0 99 };
: pa3 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many p2:Int^many -- ρ r:Seq Int^many k:Int^many pos:Int^many)
  locals { pt T n p2 } {
    p2 pt tok 32 prim = [ T n p2 1 prim + ] [ T failn ] if };
: patom2 (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many t:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos t } {
    t 0 prim >= t 25 prim <= prim and
    [ T 1 t 0 mk pos 1 prim + ]
    [ t 26 prim = [ T 2 0 0 mk pos 1 prim + ]
      [ t 31 prim = [ pt T pt pos 1 prim + palt pa3 ] [ T failn ] if ] if ] if };
: patom (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { T pt pos pt pos tok patom2 };
: pf2 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many t:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos t } {
    t 27 prim >= t 29 prim <= prim and
    [ pt T t 24 prim - n 0 mk pos 1 prim + pf ] [ T n pos ] if };
: pf (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos } { pt T n pos pt pos tok pf2 };
: pitem (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { pt T pt pos patom pf };
: sq2 (forall ρ; ρ n:Int^many pt:Seq Int^many T:Seq Int^many n2:Int^many pos2:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { n pt T n2 pos2 } { pt T 6 n n2 mk pos2 sq };
: sq1 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many t:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos t } {
    t 0 prim < t 30 prim = prim or t 32 prim = prim or
    [ T n pos ]
    [ t 27 prim >= t 29 prim <= prim and
      [ T failn ] [ n pt T pt pos pitem sq2 ] if ] if };
: sq (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos } { pt T n pos pt pos tok sq1 };
: pseq (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { pt T 0 0 0 mk pos sq };
: al2 (forall ρ; ρ n:Int^many pt:Seq Int^many T:Seq Int^many n2:Int^many pos2:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { n pt T n2 pos2 } { pt T 7 n n2 mk pos2 al };
: al (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many q:Int^many)
  locals { pt T n pos } {
    pos pt tok 30 prim = [ n pt T pt pos 1 prim + pseq al2 ] [ T n pos ] if };
: palt (forall ρ; ρ T:Seq Int^many pt:Seq Int^many pos:Int^many -- ρ r:Seq Int^many n:Int^many q:Int^many)
  locals { T pt pos } { pt T pt pos pseq al };
: pr2 (forall ρ; ρ pt:Seq Int^many T:Seq Int^many n:Int^many pos:Int^many -- ρ r:Seq Int^many k:Int^many v:Bool^many)
  locals { pt T n pos } {
    T n T 0 gt 0 prim = pos pt prim seq-int.len prim = prim and };
: parse (forall ρ; ρ pt:Seq Int^many -- ρ r:Seq Int^many k:Int^many v:Bool^many)
  locals { pt } { pt 300 zs pt 0 palt pr2 };
: sh (forall ρ; ρ R:Seq Int^many sx:Seq Int^many S:Seq Int^many c:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { R sx S c i } {
    i sx prim seq-int.len prim >= [ R ]
    [ S i gt 1 prim = c 0 prim < sx i gt c prim = prim or prim and
      [ R i 1 prim + 1 st ] [ R ] if sx S c i 1 prim + sh ] if };
: shf (forall ρ; ρ sx:Seq Int^many S:Seq Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { sx S c } { sx prim seq-int.len 1 prim + zs sx S c 0 sh };
: cl (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 1 prim > [ 1 ] [ x ] if };
: unl (forall ρ; ρ A:Seq Int^many B:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { A B i } {
    i A prim seq-int.len prim >= [ A ]
    [ A i A i gt B i gt prim + cl st B i 1 prim + unl ] if };
: un (forall ρ; ρ A:Seq Int^many B:Seq Int^many -- ρ r:Seq Int^many)
  locals { A B } { A B 0 unl };
: smn (forall ρ; ρ S:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { S i acc } {
    i S prim seq-int.len prim >= [ acc ] [ S i 1 prim + acc S i gt prim + smn ] if };
: sm (forall ρ; ρ S:Seq Int^many -- ρ r:Int^many)
  locals { S } { S 0 0 smn };
: fx2 (forall ρ; ρ T:Seq Int^many sx:Seq Int^many a:Int^many R:Seq Int^many R2:Seq Int^many -- ρ r:Seq Int^many)
  locals { T sx a R R2 } {
    R2 sm R sm prim = [ R2 ] [ T sx a R2 fx ] if };
: fx (forall ρ; ρ T:Seq Int^many sx:Seq Int^many a:Int^many R:Seq Int^many -- ρ r:Seq Int^many)
  locals { T sx a R } { T sx a R R T sx a R ev un fx2 };
: ev2 (forall ρ; ρ T:Seq Int^many sx:Seq Int^many n:Int^many S:Seq Int^many ty:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { T sx n S ty a b } {
    ty 0 prim = [ S ]
    [ ty 1 prim = [ sx S a shf ]
    [ ty 2 prim = [ sx S -1 shf ]
    [ ty 3 prim = [ T sx a S fx ]
    [ ty 4 prim = [ T sx a T sx a S ev fx ]
    [ ty 5 prim = [ S T sx a S ev un ]
    [ ty 6 prim = [ T sx b T sx a S ev ev ]
    [ T sx a S ev T sx b S ev un ] if ] if ] if ] if ] if ] if ] if };
: ev (forall ρ; ρ T:Seq Int^many sx:Seq Int^many n:Int^many S:Seq Int^many -- ρ r:Seq Int^many)
  locals { T sx n S } { T sx n S T n 0 nt T n 1 nt T n 2 nt ev2 };
: lg (forall ρ; ρ R:Seq Int^many i:Int^many -- ρ r:Int^many)
  locals { R i } {
    i 0 prim < [ -1 ] [ R i gt 1 prim = [ i ] [ R i 1 prim - lg ] if ] if };
: one (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many sx:Seq Int^many -- ρ r:Seq Int^many)
  locals { T root valid sx } {
    valid [ T sx root sx prim seq-int.len 1 prim + zs 0 1 st ev ]
          [ sx prim seq-int.len 1 prim + zs ] if };
: sb (forall ρ; ρ chars:Seq Int^many i:Int^many end:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { chars i end out } {
    i end prim >= [ out ] [ chars i 1 prim + end out chars i gt prim seq-int.push sb ] if };
: sub (forall ρ; ρ chars:Seq Int^many off:Int^many len:Int^many -- ρ r:Seq Int^many)
  locals { chars off len } { chars off off len prim + prim seq-int.empty sb };
: strs2 (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many chars:Seq Int^many lens:Seq Int^many j:Int^many off:Int^many fa:Seq Bool^many la:Seq Int^many cnt:Int^many R:Seq Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many)
  locals { T root valid chars lens j off fa la cnt R } {
    T root valid chars lens j 1 prim + off lens j gt prim +
    fa R lens j gt gt 1 prim = prim seq-bool.push
    la R lens j gt lg prim seq-int.push
    cnt R lens j gt gt prim +
    strs };
: strs (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many chars:Seq Int^many lens:Seq Int^many j:Int^many off:Int^many fa:Seq Bool^many la:Seq Int^many cnt:Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many)
  locals { T root valid chars lens j off fa la cnt } {
    j lens prim seq-int.len prim >= [ fa la cnt ]
    [ T root valid chars lens j off fa la cnt
      T root valid chars off lens j gt sub one strs2 ] if };
: main2 (forall ρ; ρ T:Seq Int^many root:Int^many valid:Bool^many lens:Seq Int^many chars:Seq Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many v:Bool^many)
  locals { T root valid lens chars } {
    T root valid chars lens 0 0 prim seq-bool.empty prim seq-int.empty 0 strs valid };
: main (forall ρ; ρ pattern:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ a:Seq Bool^many b:Seq Int^many c:Int^many v:Bool^many)
  locals { pattern lens chars } { pattern parse lens chars main2 };
```

### task: swiss
```firth
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: addto (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { m i v } { m i m i gt v prim + st };
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i 1 addto };
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: cp (forall ρ; ρ m:Seq Int^many dst:Int^many src:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m dst src i } {
    i src prim seq-int.len prim >= [ m ]
    [ m dst i prim + src i prim seq-int.at st dst src i 1 prim + cp ] if };
: key (forall ρ; ρ m:Seq Int^many p:Int^many sec:Int^many -- ρ k:Int^many)
  locals { m p sec } {
    m p gt 1000 prim * m p sec prim + gt prim + 4000 prim * m 260 p prim + gt prim +
    16 prim * 15 p prim - prim + };
: ps3 (forall ρ; ρ m:Seq Int^many sec:Int^many i:Int^many a:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { m sec i a b } {
    m b sec key m a sec key prim > [ m 280 i prim + b st 281 i prim + a st ] [ m ] if };
: ps2 (forall ρ; ρ m:Seq Int^many sec:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m sec i } { m sec i m 280 i prim + gt m 281 i prim + gt ps3 };
: ps (forall ρ; ρ m:Seq Int^many sec:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m sec i } {
    i m 252 gt 1 prim - prim >= [ m ] [ m sec i ps2 sec i 1 prim + ps ] if };
: sortr (forall ρ; ρ m:Seq Int^many sec:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m sec k } {
    k m 252 gt prim >= [ m ] [ m sec 0 ps sec k 1 prim + sortr ] if };
: clr (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { i 12 prim >= [ m ] [ m 300 i prim + 0 st i 1 prim + clr ] if };
: idn (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { i m 252 gt prim >= [ m ] [ m 280 i prim + i st i 1 prim + idn ] if };
: fb2 (forall ρ; ρ m:Seq Int^many i:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m i p } {
    m 210 p prim + gt 0 prim =
    [ m p 2 addto 210 p prim + 1 st 300 p prim + 1 st ]
    [ m i 1 prim - fb ] if };
: fb (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i m 280 i prim + gt fb2 };
: bye (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m 252 gt 2 prim mod 1 prim = [ m m 252 gt 1 prim - fb ] [ m ] if };
: fq2 (forall ρ; ρ m:Seq Int^many p:Int^many j:Int^many mode:Int^many q:Int^many -- ρ r:Int^many)
  locals { m p j mode q } {
    m 300 q prim + gt 0 prim = mode 1 prim = m 20 p 12 prim * prim + q prim + gt 0 prim = prim or prim and
    [ q ] [ m p j 1 prim + mode fq ] if };
: fq (forall ρ; ρ m:Seq Int^many p:Int^many j:Int^many mode:Int^many -- ρ r:Int^many)
  locals { m p j mode } {
    j m 252 gt prim >= [ -1 ] [ m p j mode m 280 j prim + gt fq2 ] if };
: cw (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many wp:Int^many wq:Int^many lp:Bool^many lq:Bool^many -- ρ w:Int^many b:Int^many)
  locals { m p q wp wq lp lq } {
    wq wp prim < wq wp prim = lq lp prim not prim and prim and prim or [ q p ] [ p q ] if };
: colors (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many -- ρ w:Int^many b:Int^many)
  locals { m p q } {
    m p q m 170 p prim + gt m 170 q prim + gt m 190 p prim + gt 1 prim = m 190 q prim + gt 1 prim = cw };
: scorep (forall ρ; ρ m:Seq Int^many res:Int^many w:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { m res w b } {
    res 0 prim = [ m w 2 addto ]
    [ res 1 prim = [ m w 1 addto b 1 addto ] [ m b 2 addto ] if ] if };
: play2 (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many w:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { m p q w b } {
    m 300 p prim + 1 st 300 q prim + 1 st 250 bump
    20 p 12 prim * prim + q prim + bump 20 q 12 prim * prim + p prim + bump
    170 w prim + bump 190 w prim + 0 st 190 b prim + 1 st
    m 400 m 250 gt prim + gt w b scorep };
: play (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { m p q } { m p q m p q colors play2 };
: pr2 (forall ρ; ρ m:Seq Int^many i:Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { m i p q } {
    q 0 prim >= [ m p q play ]
    [ m 251 bump p m p i 1 prim + 1 fq play ] if };
: pr1 (forall ρ; ρ m:Seq Int^many i:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m i p } {
    m 300 p prim + gt 0 prim = [ m i p m p i 1 prim + 0 fq pr2 ] [ m ] if };
: pairone (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i m 280 i prim + gt pr1 };
: pairall (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } {
    i m 252 gt prim >= [ m ] [ m i pairone i 1 prim + pairall ] if };
: rnd (forall ρ; ρ m:Seq Int^many -- ρ r:Seq Int^many)
  locals { m } { m 0 clr 0 idn 340 0 sortr bye 0 pairall };
: rloop (forall ρ; ρ m:Seq Int^many r:Int^many -- ρ x:Seq Int^many)
  locals { m r } {
    r m 253 gt prim >= [ m ] [ m rnd r 1 prim + rloop ] if };
: bq (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m p q acc } {
    q m 252 gt prim >= [ acc ]
    [ m p q 1 prim + acc m 20 p 12 prim * prim + q prim + gt m q gt prim * prim + bq ] if };
: bh (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    p m 252 gt prim >= [ m ] [ m 230 p prim + m p 0 0 bq st p 1 prim + bh ] if };
: exl (forall ρ; ρ m:Seq Int^many off:Int^many n:Int^many out:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m off n out i } {
    i n prim >= [ out ]
    [ m off n out m off i prim + gt prim seq-int.push i 1 prim + exl ] if };
: ex (forall ρ; ρ m:Seq Int^many off:Int^many -- ρ r:Seq Int^many)
  locals { m off } { m off m 252 gt prim seq-int.empty 0 exl };
: fin (forall ρ; ρ m:Seq Int^many -- ρ a:Seq Int^many b:Seq Int^many c:Seq Int^many d:Seq Int^many e:Int^many)
  locals { m } { m 0 ex m 230 ex m 280 ex m 170 ex m 251 gt };
: main (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ a:Seq Int^many b:Seq Int^many c:Seq Int^many d:Seq Int^many e:Int^many)
  locals { ratings rounds results } {
    prim seq-int.empty 450 pad 252 ratings prim seq-int.len st 253 rounds st
    260 ratings 0 cp 400 results 0 cp
    0 rloop 0 bh 0 idn 230 0 sortr fin };
```

### task: warehouse
```firth
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: addto (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { m i v } { m i m i gt v prim + st };
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i 1 addto };
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: cp (forall ρ; ρ m:Seq Int^many dst:Int^many src:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m dst src i } {
    i src prim seq-int.len prim >= [ m ]
    [ m dst i prim + src i prim seq-int.at st dst src i 1 prim + cp ] if };
: qa (forall ρ; ρ p:Int^many h:Int^many -- ρ base:Int^many)
  locals { p h } { p 80 prim * h prim + 2 prim * 100 prim + };
: enq2 (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many d:Int^many base:Int^many -- ρ r:Seq Int^many)
  locals { m p q d base } { m base q st base 1 prim + d st 70 p prim + bump };
: enq (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p q d } { m p q d p m 70 p prim + gt qa enq2 };
: bst (forall ρ; ρ b:Int^many m:Seq Int^many p:Int^many i:Int^many -- ρ r:Int^many)
  locals { b m p i } {
    i m 0 gt prim >= [ b ]
    [ m 1400 i 3 prim * prim + gt p prim = m 1401 i 3 prim * prim + gt 0 prim > prim and
      [ b 0 prim <
        [ i ]
        [ m 1402 i 3 prim * prim + gt m 1402 b 3 prim * prim + gt prim < [ i ] [ b ] if ] if ]
      [ b ] if
      m p i 1 prim + bst ] if };
: tk3 (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many b:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { m p q b amt } {
    m 1401 b 3 prim * prim + m 1401 b 3 prim * prim + gt amt prim - st
    20 p prim + 0 amt prim - addto p q amt prim - tk };
: tk2 (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { m p q b } {
    m p q b q m 1401 b 3 prim * prim + gt prim <= [ q ] [ m 1401 b 3 prim * prim + gt ] if tk3 };
: tk (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { m p q } {
    q 0 prim <= [ m ] [ m p q -1 m p 0 bst tk2 ] if };
: ship (forall ρ; ρ m:Seq Int^many p:Int^many u:Int^many -- ρ r:Seq Int^many)
  locals { m p u } {
    m p u tk 1 m 40 p prim + gt u prim * addto 2 u addto };
: fb3 (forall ρ; ρ m:Seq Int^many p:Int^many base:Int^many amt:Int^many -- ρ r:Seq Int^many)
  locals { m p base amt } {
    m p amt ship base m base gt amt prim - st
    m base gt amt prim - 0 prim = [ 65 p prim + bump ] [ ] if
    p fb };
: fb2 (forall ρ; ρ m:Seq Int^many p:Int^many base:Int^many -- ρ r:Seq Int^many)
  locals { m p base } {
    m p base m base gt m 20 p prim + gt prim <= [ m base gt ] [ m 20 p prim + gt ] if fb3 };
: fb (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    m 65 p prim + gt m 70 p prim + gt prim >= m 20 p prim + gt 0 prim <= prim or
    [ m ] [ m p p m 65 p prim + gt qa fb2 ] if };
: nl2 (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { m p q e n } {
    m 1400 n 3 prim * prim + p st 1401 n 3 prim * prim + q st 1402 n 3 prim * prim + e st
    0 n 1 prim + st 20 p prim + q addto };
: newlot (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m p q e } { m p q e m 0 gt nl2 };
: arrive (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m p q e } { m p q e newlot p fb };
: putlot (forall ρ; ρ m:Seq Int^many w:Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m w p q e } {
    m 1400 w 3 prim * prim + p st 1401 w 3 prim * prim + q st 1402 w 3 prim * prim + e st };
: cmp2 (forall ρ; ρ m:Seq Int^many d:Int^many i:Int^many w:Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m d i w p q e } {
    q 0 prim <= [ m d i 1 prim + w cmp ]
    [ e d prim <
      [ m 3 q addto 20 p prim + 0 q prim - addto d i 1 prim + w cmp ]
      [ m w p q e putlot d i 1 prim + w 1 prim + cmp ] if ] if };
: cmp (forall ρ; ρ m:Seq Int^many d:Int^many i:Int^many w:Int^many -- ρ r:Seq Int^many)
  locals { m d i w } {
    i m 0 gt prim >= [ m 0 w st ]
    [ m d i w m 1400 i 3 prim * prim + gt m 1401 i 3 prim * prim + gt m 1402 i 3 prim * prim + gt cmp2 ] if };
: sup (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m d p } {
    p m 7 gt prim >= [ m ]
    [ m 25 p prim + gt 1 prim = m 30 p prim + gt d prim = prim and
      [ m p m 50 p prim + gt d m 60 p prim + gt prim + arrive 25 p prim + 0 st ] [ m ] if
      d p 1 prim + sup ] if };
: ordr2 (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many q:Int^many sh:Int^many -- ρ r:Seq Int^many)
  locals { m d p q sh } {
    m p sh ship q sh prim - 0 prim > [ p q sh prim - d enq ] [ ] if };
: ordr (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { m d p q } {
    m 65 p prim + gt m 70 p prim + gt prim <
    [ m p q d enq ]
    [ m d p q q m 20 p prim + gt prim <= [ q ] [ m 20 p prim + gt ] if ordr2 ] if };
: evx (forall ρ; ρ m:Seq Int^many d:Int^many kind:Int^many p:Int^many q:Int^many ex:Int^many -- ρ r:Seq Int^many)
  locals { m d kind p q ex } {
    kind 1 prim = [ m p q ex arrive ] [ m d p q ordr ] if };
: evstep (forall ρ; ρ m:Seq Int^many d:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m d i } {
    m d m 980 i prim + gt m 1060 i prim + gt m 1140 i prim + gt m 1220 i prim + gt evx
    6 bump d evl };
: evl (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    m 6 gt m 9 gt prim >= [ m ]
    [ m 900 m 6 gt prim + gt d prim = [ m d m 6 gt evstep ] [ m ] if ] if };
: cq2 (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many base:Int^many -- ρ r:Seq Int^many)
  locals { m d p base } {
    m base 1 prim + gt d 7 prim - prim <=
    [ m 4 m base gt addto 65 p prim + bump d p cq ] [ m ] if };
: cq (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m d p } {
    m 65 p prim + gt m 70 p prim + gt prim >= [ m ]
    [ m d p p m 65 p prim + gt qa cq2 ] if };
: canc (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m d p } {
    p m 7 gt prim >= [ m ] [ m d p cq d p 1 prim + canc ] if };
: reo (forall ρ; ρ m:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m d p } {
    p m 7 gt prim >= [ m ]
    [ m 25 p prim + gt 0 prim = m 20 p prim + gt m 45 p prim + gt prim <= prim and
      [ m 25 p prim + 1 st 30 p prim + d m 55 p prim + gt prim + st 5 bump ] [ m ] if
      d p 1 prim + reo ] if };
: dayl (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    d m 8 gt prim >= [ m ]
    [ m d 0 0 cmp d 0 sup d evl d 0 canc d 0 reo d 1 prim + dayl ] if };
: exl (forall ρ; ρ m:Seq Int^many off:Int^many n:Int^many out:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m off n out i } {
    i n prim >= [ out ]
    [ m off n out m off i prim + gt prim seq-int.push i 1 prim + exl ] if };
: ow2 (forall ρ; ρ m:Seq Int^many p:Int^many h:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m p h acc } {
    h m 70 p prim + gt prim >= [ acc ]
    [ m p h 1 prim + m p h qa gt acc prim + ow2 ] if };
: ow1 (forall ρ; ρ acc:Int^many m:Seq Int^many p:Int^many -- ρ r:Int^many)
  locals { acc m p } {
    p m 7 gt prim >= [ acc ]
    [ m p m 65 p prim + gt acc ow2 m p 1 prim + ow1 ] if };
: fin (forall ρ; ρ m:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { m } {
    m 20 m 7 gt prim seq-int.empty 0 exl
    m 1 gt m 2 gt m 3 gt m 4 gt m 5 gt
    0 m 0 ow1 };
: main (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many eve:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { days price rp rq lead shelf evd evk evp evq eve } {
    prim seq-int.empty 2600 pad 7 price prim seq-int.len st 8 days st 9 evd prim seq-int.len st
    40 price 0 cp 45 rp 0 cp 50 rq 0 cp 55 lead 0 cp 60 shelf 0 cp
    900 evd 0 cp 980 evk 0 cp 1060 evp 0 cp 1140 evq 0 cp 1220 eve 0 cp
    0 dayl fin };
```

### task: cache-sim
```firth
: gt (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: st (forall ρ; ρ m:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i m i gt 1 prim + st };
: pad (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { s prim seq-int.len n prim < [ s 0 prim seq-int.push n pad ] [ s ] if };
: cl (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 1 prim > [ 1 ] [ x ] if };
: cbs (forall ρ; ρ lvl:Int^many -- ρ n:Int^many)
  locals { lvl } { lvl 1 prim = [ 0 ] [ 10 ] if };
: bbs (forall ρ; ρ lvl:Int^many -- ρ n:Int^many)
  locals { lvl } { lvl 1 prim = [ 100 ] [ 200 ] if };
: dbs (forall ρ; ρ lvl:Int^many -- ρ n:Int^many)
  locals { lvl } { lvl 1 prim = [ 140 ] [ 300 ] if };
: ba (forall ρ; ρ lvl:Int^many si:Int^many k:Int^many -- ρ n:Int^many)
  locals { lvl si k } { lvl bbs si 8 prim * prim + k prim + };
: da (forall ρ; ρ lvl:Int^many si:Int^many k:Int^many -- ρ n:Int^many)
  locals { lvl si k } { lvl dbs si 8 prim * prim + k prim + };
: wys (forall ρ; ρ m:Seq Int^many lvl:Int^many -- ρ n:Int^many)
  locals { m lvl } { lvl 1 prim = [ m 31 gt ] [ m 33 gt ] if };
: nsets (forall ρ; ρ m:Seq Int^many lvl:Int^many -- ρ n:Int^many)
  locals { m lvl } { lvl 1 prim = [ m 30 gt ] [ m 32 gt ] if };
: sidx (forall ρ; ρ m:Seq Int^many lvl:Int^many a:Int^many -- ρ si:Int^many)
  locals { m lvl a } { a m lvl nsets prim mod };
: fn1 (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { m lvl si b k } {
    k m lvl cbs si prim + gt prim >= [ -1 ]
    [ m lvl si k ba gt b prim = [ k ] [ m lvl si b k 1 prim + fn1 ] if ] if };
: fnd (forall ρ; ρ m:Seq Int^many lvl:Int^many b:Int^many -- ρ r:Int^many)
  locals { m lvl b } { m lvl m lvl b sidx b 0 fn1 };
: rm1 (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { m lvl si j } {
    j 1 prim + m lvl cbs si prim + gt prim >=
    [ m lvl cbs si prim + m lvl cbs si prim + gt 1 prim - st ]
    [ m lvl si j ba m lvl si j 1 prim + ba gt st
      lvl si j da m lvl si j 1 prim + da gt st
      lvl si j 1 prim + rm1 ] if };
: rmv (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m lvl si k } { m lvl si k rm1 };
: app2 (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many b:Int^many d:Int^many c:Int^many -- ρ r:Seq Int^many)
  locals { m lvl si b d c } {
    m lvl si c ba b st lvl si c da d st lvl cbs si prim + c 1 prim + st };
: app (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many b:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m lvl si b d } { m lvl si b d m lvl cbs si prim + gt app2 };
: usek (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many k:Int^many o:Int^many -- ρ r:Seq Int^many)
  locals { m lvl si k o } {
    m lvl si k rmv lvl si m lvl si k ba gt m lvl si k da gt o prim + cl app };
: putx (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many b:Int^many d:Int^many -- ρ r:Seq Int^many eb:Int^many ed:Int^many)
  locals { m lvl si b d } {
    m lvl cbs si prim + gt m lvl wys prim >=
    [ m lvl si 0 rmv lvl si b d app m lvl si 0 ba gt m lvl si 0 da gt ]
    [ m lvl si b d app -1 0 ] if };
: put (forall ρ; ρ m:Seq Int^many lvl:Int^many b:Int^many d:Int^many -- ρ r:Seq Int^many eb:Int^many ed:Int^many)
  locals { m lvl b d } { m lvl m lvl b sidx b d putx };
: put2 (forall ρ; ρ m:Seq Int^many eb:Int^many ed:Int^many -- ρ r:Seq Int^many)
  locals { m eb ed } { ed 1 prim = [ m 25 bump ] [ m ] if };
: wb2 (forall ρ; ρ m:Seq Int^many eb:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m eb k } {
    k 0 prim >= [ m 2 m 2 eb sidx k 1 usek ] [ m 2 eb 1 put put2 ] if };
: wb (forall ρ; ρ m:Seq Int^many eb:Int^many ed:Int^many -- ρ r:Seq Int^many)
  locals { m eb ed } {
    ed 1 prim = [ m eb m 2 eb fnd wb2 ] [ m ] if };
: ins1 (forall ρ; ρ m:Seq Int^many a:Int^many w:Int^many -- ρ r:Seq Int^many)
  locals { m a w } { m 1 a w put wb };
: acc2 (forall ρ; ρ m:Seq Int^many a:Int^many w:Int^many k2:Int^many -- ρ r:Seq Int^many)
  locals { m a w k2 } {
    k2 0 prim >=
    [ m 22 bump 2 m 2 a sidx k2 0 usek ]
    [ m 23 bump 24 bump 2 a 0 put put2 ] if
    a w ins1 };
: acc1 (forall ρ; ρ m:Seq Int^many a:Int^many w:Int^many k1:Int^many -- ρ r:Seq Int^many)
  locals { m a w k1 } {
    k1 0 prim >=
    [ m 20 bump 1 m 1 a sidx k1 w usek ]
    [ m 21 bump a w m 2 a fnd acc2 ] if };
: acc (forall ρ; ρ m:Seq Int^many a:Int^many w:Int^many -- ρ r:Seq Int^many)
  locals { m a w } { m a w m 1 a fnd acc1 };
: lp (forall ρ; ρ m:Seq Int^many addrs:Seq Int^many writes:Seq Bool^many i:Int^many -- ρ r:Seq Int^many)
  locals { m addrs writes i } {
    i addrs prim seq-int.len prim >= [ m ]
    [ m addrs i prim seq-int.at writes i prim seq-bool.at [ 1 ] [ 0 ] if acc
      addrs writes i 1 prim + lp ] if };
: dsum (forall ρ; ρ m:Seq Int^many lvl:Int^many si:Int^many k:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m lvl si k acc } {
    si m lvl nsets prim >= [ acc ]
    [ k m lvl cbs si prim + gt prim >=
      [ m lvl si 1 prim + 0 acc dsum ]
      [ m lvl si k 1 prim + m lvl si k da gt acc prim + dsum ] if ] if };
: l1 (forall ρ; ρ m:Seq Int^many si:Int^many k:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { m si k out } {
    si m 30 gt prim >= [ out ]
    [ k m 1 cbs si prim + gt prim >=
      [ m si 1 prim + 0 out l1 ]
      [ m si k 1 prim + out m 1 si k ba gt prim seq-int.push l1 ] if ] if };
: main (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ a:Int^many b:Int^many c:Int^many d:Int^many e:Int^many f:Int^many g:Int^many h:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    prim seq-int.empty 400 pad 30 s1 st 31 w1 st 32 s2 st 33 w2 st
    addrs writes 0 lp
    locals { m } {
      m 20 gt m 21 gt m 22 gt m 23 gt m 24 gt m 25 gt
      m 1 0 0 0 dsum m 2 0 0 0 dsum prim +
      m 0 0 prim seq-int.empty l1 } };
```

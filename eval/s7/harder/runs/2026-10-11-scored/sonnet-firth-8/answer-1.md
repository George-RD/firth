### task: sokoban
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: bump (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ r:Seq Int^many) 1 incr;
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };
: app (forall ρ; ρ d:Seq Int^many s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { d s i } { i s prim seq-int.len prim >= [ d ] [ d s i get prim seq-int.push s i 1 prim + app ] if };

: delta (forall ρ; ρ w:Int^many d:Int^many -- ρ r:Int^many)
  locals { w d } {
    d 0 prim = [ 0 w prim - ]
    [ d 1 prim = [ 1 ]
      [ d 2 prim = [ w ] [ -1 ] if ] if ] if };

: boxat-loop (forall ρ; ρ st:Seq Int^many cell:Int^many k:Int^many -- ρ r:Int^many)
  locals { st cell k } {
    k st 8 get prim >=
    [ -1 ]
    [ st k 9 prim + get cell prim =
      [ k ] [ st cell k 1 prim + boxat-loop ] if ] if };

: alldone (forall ρ; ρ st:Seq Int^many cells:Seq Int^many k:Int^many -- ρ b:Bool^many)
  locals { st cells k } {
    k st 8 get prim >=
    [ true ]
    [ cells st k 9 prim + get get 2 prim =
      [ st cells k 1 prim + alldone ] [ false ] if ] if };

: isdead (forall ρ; ρ st:Seq Int^many cells:Seq Int^many u:Int^many -- ρ b:Bool^many)
  locals { st cells u } {
    st 0 get locals { w } {
      cells u get 2 prim = prim not
      cells u w prim - get 1 prim = cells u w prim + get 1 prim = prim or prim and
      cells u 1 prim - get 1 prim = cells u 1 prim + get 1 prim = prim or prim and } };

: record (forall ρ; ρ st:Seq Int^many code:Int^many -- ρ r:Seq Int^many)
  locals { st code } { st st 3 get 15 prim + code put 3 bump };

: undo (forall ρ; ρ st:Seq Int^many -- ρ r:Seq Int^many)
  locals { st } {
    st 3 get 0 prim =
    [ st ]
    [ st 3 get 1 prim - locals { h } {
        st 15 h prim + get locals { code } {
          code 8 prim div locals { d } {
            code 8 prim mod 1 prim - locals { k } {
              st 0 get d delta locals { dd } {
                st 3 h put 1 st 1 get dd prim - put 6 bump
                locals { s2 } {
                  k 0 prim >=
                  [ s2 k 9 prim + s2 k 9 prim + get dd prim - put ]
                  [ s2 ] if } } } } } ]
    if };

: domove (forall ρ; ρ st:Seq Int^many cells:Seq Int^many m:Int^many -- ρ r:Seq Int^many)
  locals { st cells m } {
    st 0 get m delta locals { d } {
      st 1 get d prim + locals { t } {
        cells t get 1 prim =
        [ st 5 bump ]
        [ st t 0 boxat-loop locals { k } {
            k 0 prim <
            [ st 1 t put m 8 prim * record ]
            [ t d prim + locals { u } {
                cells u get 1 prim = st u 0 boxat-loop 0 prim >= prim or
                [ st 5 bump ]
                [ st k 9 prim + u put 1 t put 4 bump
                  m 8 prim * k 1 prim + prim + record
                  locals { s3 } {
                    s3 cells u isdead [ s3 7 bump ] [ s3 ] if } ] if } ] if } ] if } } };

: step (forall ρ; ρ st:Seq Int^many cells:Seq Int^many moves:Seq Int^many -- ρ r:Seq Int^many)
  locals { st cells moves } {
    moves st 2 get get st 2 st 2 get 1 prim + put
    locals { m s1 } {
      m 4 prim = [ s1 undo ] [ s1 cells m domove ] if } };

: play (forall ρ; ρ st:Seq Int^many cells:Seq Int^many moves:Seq Int^many -- ρ r:Seq Int^many)
  locals { st cells moves } {
    st cells 0 alldone
    [ st ]
    [ st 2 get moves prim seq-int.len prim >=
      [ st ]
      [ st cells moves step cells moves play ] if ] if };

: init (forall ρ; ρ w:Int^many player:Int^many boxes:Seq Int^many -- ρ r:Seq Int^many)
  locals { w player boxes } {
    prim seq-int.empty w prim seq-int.push player prim seq-int.push
    0 6 pushn boxes prim seq-int.len prim seq-int.push
    boxes 0 app 0 6 boxes prim seq-int.len prim - pushn 0 200 pushn };

: outboxes-loop (forall ρ; ρ st:Seq Int^many out:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { st out k } {
    k st 8 get prim >=
    [ out ]
    [ st out st k 9 prim + get prim seq-int.push k 1 prim + outboxes-loop ] if };

: main
  (forall ρ; ρ w:Int^many h:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many
   -- ρ p:Int^many bx:Seq Int^many rd:Int^many hs:Int^many ps:Int^many bl:Int^many un:Int^many dd:Int^many sv:Bool^many)
  locals { w h cells player boxes moves } {
    w player boxes init cells moves play
    locals { st } {
      st 1 get
      st prim seq-int.empty 0 outboxes-loop
      st 2 get st 3 get st 4 get st 5 get st 6 get st 7 get
      st cells 0 alldone } };
```

### task: checkers
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: app (forall ρ; ρ d:Seq Int^many s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { d s i } { i s prim seq-int.len prim >= [ d ] [ d s i get prim seq-int.push s i 1 prim + app ] if };

: sidof (forall ρ; ρ p:Int^many -- ρ r:Int^many) 3 prim >= [ 1 ] [ 0 ] if;
: drof (forall ρ; ρ j:Int^many -- ρ r:Int^many) 2 prim < [ -1 ] [ 1 ] if;
: dcof (forall ρ; ρ j:Int^many -- ρ r:Int^many) 2 prim mod 0 prim = [ -1 ] [ 1 ] if;

: isopp (forall ρ; ρ x:Int^many p:Int^many -- ρ b:Bool^many)
  locals { x p } {
    x 3 prim >= p 3 prim < prim and
    x 0 prim > x 3 prim < prim and p 3 prim >= prim and prim or };

: colof (forall ρ; ρ i:Int^many -- ρ c:Int^many)
  locals { i } { i 4 prim mod 2 prim * 1 prim + i 4 prim div 2 prim mod prim - };

: nb (forall ρ; ρ i:Int^many dr:Int^many dc:Int^many -- ρ n:Int^many)
  locals { i dr dc } {
    i 4 prim div dr prim + locals { r2 } {
      i colof dc prim + locals { c2 } {
        r2 0 prim >= r2 7 prim <= prim and c2 0 prim >= prim and c2 7 prim <= prim and
        [ r2 4 prim * c2 2 prim div prim + ] [ -1 ] if } } };

: midsq (forall ρ; ρ a:Int^many b:Int^many -- ρ m:Int^many)
  locals { a b } {
    a 4 prim div b 4 prim div prim + 2 prim div 4 prim *
    a colof b colof prim + 2 prim div 2 prim div prim + };

: canmove (forall ρ; ρ p:Int^many dr:Int^many -- ρ b:Bool^many)
  locals { p dr } {
    p 2 prim = p 4 prim = prim or
    p 1 prim = dr -1 prim = prim and prim or
    p 3 prim = dr 1 prim = prim and prim or };

: jland (forall ρ; ρ bd:Seq Int^many sq:Int^many p:Int^many j:Int^many -- ρ b:Int^many)
  locals { bd sq p j } {
    j drof j dcof locals { dr dc } {
      p dr canmove
      [ sq dr dc nb locals { a } {
          a 0 prim >=
          [ bd a get p isopp
            [ a dr dc nb locals { b } {
                b 0 prim >=
                [ bd b get 0 prim = [ b ] [ -1 ] if ]
                [ -1 ] if } ]
            [ -1 ] if ]
          [ -1 ] if } ]
      [ -1 ] if } };

: hasj (forall ρ; ρ bd:Seq Int^many sq:Int^many p:Int^many j:Int^many -- ρ b:Bool^many)
  locals { bd sq p j } {
    j 4 prim >=
    [ false ]
    [ bd sq p j jland 0 prim >= [ true ] [ bd sq p j 1 prim + hasj ] if ] if };

: finish (forall ρ; ρ cnt:Int^many path:Seq Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { cnt path best } {
    cnt best 0 get prim >
    [ prim seq-int.empty cnt prim seq-int.push path 0 app ]
    [ best ] if };

: dfsl (forall ρ; ρ bd:Seq Int^many sq:Int^many p:Int^many cnt:Int^many path:Seq Int^many best:Seq Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { bd sq p cnt path best j } {
    j 4 prim >=
    [ best ]
    [ bd sq p j jland locals { b } {
        b 0 prim >=
        [ sq j drof j dcof nb locals { a } {
            path b prim seq-int.push locals { np } {
              p 1 prim = b 4 prim div 0 prim = prim and
              p 3 prim = b 4 prim div 7 prim = prim and prim or
              [ cnt 1 prim + np best finish ]
              [ bd a 0 put b p cnt 1 prim + np best dfs ] if
              locals { best2 } { bd sq p cnt path best2 j 1 prim + dfsl } } } ]
        [ bd sq p cnt path best j 1 prim + dfsl ] if } ]
    if };

: dfs (forall ρ; ρ bd:Seq Int^many sq:Int^many p:Int^many cnt:Int^many path:Seq Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { bd sq p cnt path best } {
    bd sq p 0 hasj
    [ bd sq p cnt path best 0 dfsl ]
    [ cnt path best finish ] if };

: trystart (forall ρ; ρ bd:Seq Int^many side:Int^many s:Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { bd side s best } {
    bd s get locals { p } {
      p 0 prim > p sidof side prim = prim and
      [ bd s 0 put locals { b2 } {
          b2 s p 0 hasj
          [ b2 s p 0 prim seq-int.empty s prim seq-int.push best dfs ]
          [ best ] if } ]
      [ best ] if } };

: findcap (forall ρ; ρ bd:Seq Int^many side:Int^many s:Int^many best:Seq Int^many -- ρ r:Seq Int^many)
  locals { bd side s best } {
    s 32 prim >=
    [ best ]
    [ bd side s best trystart locals { b2 } { bd side s 1 prim + b2 findcap } ] if };

: stepscan (forall ρ; ρ bd:Seq Int^many side:Int^many s:Int^many j:Int^many -- ρ r:Int^many)
  locals { bd side s j } {
    s 32 prim >=
    [ -1 ]
    [ j 4 prim >=
      [ bd side s 1 prim + 0 stepscan ]
      [ bd s get locals { p } {
          p 0 prim > p sidof side prim = prim and
          [ s j drof j dcof nb locals { d } {
              d 0 prim >=
              [ p j drof canmove bd d get 0 prim = prim and ]
              [ false ] if
              [ s 32 prim * d prim + ]
              [ bd side s j 1 prim + stepscan ] if } ]
          [ bd side s j 1 prim + stepscan ] if } ] if ] if };

: replay (forall ρ; ρ bd:Seq Int^many best:Seq Int^many cur:Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { bd best cur i } {
    i best prim seq-int.len prim >=
    [ bd ]
    [ best i get locals { land } {
        bd cur land midsq 0 put best land i 1 prim + replay } ] if };

: capres (forall ρ; ρ bd:Seq Int^many best:Seq Int^many -- ρ r:Seq Int^many c:Int^many)
  locals { bd best } {
    bd best 1 get get locals { p } {
      best best prim seq-int.len 1 prim - get locals { last } {
        p 1 prim = last 4 prim div 0 prim = prim and
        p 3 prim = last 4 prim div 7 prim = prim and prim or
        locals { cr } {
          bd best 1 get 0 put best best 1 get 2 replay
          last cr [ p 1 prim + ] [ p ] if put
          cr [ 1 ] [ 0 ] if } } } };

: stepres (forall ρ; ρ bd:Seq Int^many sc:Int^many -- ρ r:Seq Int^many c:Int^many)
  locals { bd sc } {
    sc 32 prim div locals { s } {
      sc 32 prim mod locals { d } {
        bd s get locals { p } {
          p 1 prim = d 4 prim div 0 prim = prim and
          p 3 prim = d 4 prim div 7 prim = prim and prim or
          locals { cr } {
            bd s 0 put d cr [ p 1 prim + ] [ p ] if put
            cr [ 1 ] [ 0 ] if } } } } };

: finished (forall ρ; ρ g:Seq Int^many -- ρ b:Bool^many)
  locals { g } { g 1 get g 6 get prim >= };

: game (forall ρ; ρ bd:Seq Int^many g:Seq Int^many -- ρ b2:Seq Int^many g2:Seq Int^many)
  locals { bd g } {
    bd g 0 get 0 { 0 } findcap locals { best } {
      best 0 get 0 prim >
      [ g finished
        [ bd g ]
        [ bd best capres locals { nbd crf } {
            nbd
            g 1 1 incr 2 g 0 get prim + best 0 get incr 4 crf incr 0 1 g 0 get prim - put
            game } ] if ]
      [ bd g 0 get 0 0 stepscan locals { sc } {
          sc 0 prim <
          [ bd g 5 g 0 get 1 prim = [ 1 ] [ 2 ] if put ]
          [ g finished
            [ bd g ]
            [ bd sc stepres locals { nbd crf } {
                nbd
                g 1 1 incr 4 crf incr 0 1 g 0 get prim - put
                game } ] if ] if } ]
      if } };

: main (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ b:Seq Int^many played:Int^many wt:Int^many bt:Int^many cr:Int^many res:Int^many)
  locals { bd turn plies } {
    bd { 0 0 0 0 0 0 0 } 0 turn put 6 plies put game
    locals { b2 g } { b2 g 1 get g 2 get g 3 get g 4 get g 5 get } };
```

### task: regex
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };
: zeros (forall ρ; ρ n:Int^many -- ρ s:Seq Int^many)
  locals { n } { prim seq-int.empty 0 n 1 prim + pushn };

: sumf (forall ρ; ρ s:Seq Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { s i acc } { i s prim seq-int.len prim >= [ acc ] [ s i 1 prim + acc s i get prim + sumf ] if };

: unionl (forall ρ; ρ a:Seq Int^many b:Seq Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { a b i out } {
    i a prim seq-int.len prim >=
    [ out ]
    [ a b i 1 prim + out a i get b i get prim + a i get b i get prim * prim - prim seq-int.push unionl ] if };

: uni (forall ρ; ρ a:Seq Int^many b:Seq Int^many -- ρ r:Seq Int^many)
  locals { a b } { a b 0 prim seq-int.empty unionl };

: lt (forall ρ; ρ sc:Seq Int^many c:Int^many s:Seq Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { sc c s i out } {
    i sc prim seq-int.len prim >=
    [ out ]
    [ sc c s i 1 prim +
      s i get 1 prim = c 0 prim < sc i get c prim = prim or prim and
      [ out i 1 prim + 1 put ] [ out ] if
      lt ] if };

: ev (forall ρ; ρ nd:Seq Int^many sc:Seq Int^many node:Int^many s:Seq Int^many -- ρ r:Seq Int^many)
  locals { nd sc node s } {
    nd node 3 prim * get locals { k } {
      nd node 3 prim * 1 prim + get locals { a } {
        nd node 3 prim * 2 prim + get locals { b } {
          k 0 prim = [ sc a s 0 sc prim seq-int.len zeros lt ]
          [ k 1 prim = [ s ]
          [ k 2 prim = [ nd sc b nd sc a s ev ev ]
          [ k 3 prim = [ nd sc a s ev nd sc b s ev uni ]
          [ k 4 prim = [ nd sc a s closure ]
          [ k 5 prim = [ nd sc a nd sc a s ev closure ]
          [ s nd sc a s ev uni ] if ] if ] if ] if ] if ] if } } } };

: closure (forall ρ; ρ nd:Seq Int^many sc:Seq Int^many a:Int^many r:Seq Int^many -- ρ r2:Seq Int^many)
  locals { nd sc a r } {
    r nd sc a r ev uni locals { r2 } {
      r2 0 0 sumf r 0 0 sumf prim =
      [ r2 ] [ nd sc a r2 closure ] if } };

: tok (forall ρ; ρ pat:Seq Int^many pos:Int^many -- ρ t:Int^many)
  locals { pat pos } { pos pat prim seq-int.len prim >= [ -1 ] [ pat pos get ] if };

: mk (forall ρ; ρ nd:Seq Int^many k:Int^many a:Int^many b:Int^many -- ρ nd2:Seq Int^many id:Int^many)
  locals { nd k a b } {
    nd prim seq-int.len 3 prim div
    nd k prim seq-int.push a prim seq-int.push b prim seq-int.push
    swap };

: patom (forall ρ; ρ pat:Seq Int^many nd:Seq Int^many pos:Int^many -- ρ nd2:Seq Int^many pos2:Int^many root:Int^many)
  locals { pat nd pos } {
    pat pos tok locals { t } {
      t 0 prim >= t 26 prim <= prim and
      [ nd 0 t 26 prim = [ -1 ] [ t ] if 0 mk pos 1 prim + swap ]
      [ t 31 prim =
        [ pat nd pos 1 prim + palt locals { nd2 pos2 r } {
            pat pos2 tok 32 prim =
            [ nd2 pos2 1 prim + r ] [ nd2 1000 r ] if } ]
        [ nd 1000 0 ] if ] if } };

: ppost (forall ρ; ρ pat:Seq Int^many nd:Seq Int^many pos:Int^many root:Int^many -- ρ nd2:Seq Int^many pos2:Int^many r:Int^many)
  locals { pat nd pos root } {
    pat pos tok locals { t } {
      t 27 prim >= t 29 prim <= prim and
      [ nd t 27 prim - 4 prim + root 0 mk locals { nd2 id } { pat nd2 pos 1 prim + id ppost } ]
      [ nd pos root ] if } };

: pitem (forall ρ; ρ pat:Seq Int^many nd:Seq Int^many pos:Int^many -- ρ nd2:Seq Int^many pos2:Int^many root:Int^many)
  locals { pat nd pos } { pat nd pos patom locals { nd2 pos2 r } { pat nd2 pos2 r ppost } };

: pseq (forall ρ; ρ pat:Seq Int^many nd:Seq Int^many pos:Int^many acc:Int^many -- ρ nd2:Seq Int^many pos2:Int^many root:Int^many)
  locals { pat nd pos acc } {
    pat pos tok locals { t } {
      t 0 prim < t 30 prim = prim or t 32 prim = prim or
      [ nd pos acc ]
      [ pat nd pos pitem locals { nd2 pos2 r } {
          nd2 2 acc r mk locals { nd3 id } { pat nd3 pos2 id pseq } } ] if } };

: palt-tail (forall ρ; ρ pat:Seq Int^many nd:Seq Int^many pos:Int^many root:Int^many -- ρ nd2:Seq Int^many pos2:Int^many r:Int^many)
  locals { pat nd pos root } {
    pat pos tok 30 prim =
    [ nd 1 0 0 mk locals { nd1 e } {
        pat nd1 pos 1 prim + e pseq locals { nd2 pos2 r2 } {
          nd2 3 root r2 mk locals { nd3 id } { pat nd3 pos2 id palt-tail } } } ]
    [ nd pos root ] if };

: palt (forall ρ; ρ pat:Seq Int^many nd:Seq Int^many pos:Int^many -- ρ nd2:Seq Int^many pos2:Int^many root:Int^many)
  locals { pat nd pos } {
    nd 1 0 0 mk locals { nd1 e } {
      pat nd1 pos e pseq locals { nd2 pos2 r } {
        pat nd2 pos2 r palt-tail } } };

: slice (forall ρ; ρ ch:Seq Int^many off:Int^many n:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { ch off n i out } {
    i n prim >=
    [ out ]
    [ ch off n i 1 prim + out ch off i prim + get prim seq-int.push slice ] if };

: hi (forall ρ; ρ r:Seq Int^many i:Int^many -- ρ res:Int^many)
  locals { r i } { i 0 prim < [ -1 ] [ r i get 1 prim = [ i ] [ r i 1 prim - hi ] if ] if };

: strs (forall ρ; ρ nd:Seq Int^many root:Int^many chars:Seq Int^many lens:Seq Int^many j:Int^many off:Int^many full:Seq Bool^many longest:Seq Int^many -- ρ f2:Seq Bool^many l2:Seq Int^many)
  locals { nd root chars lens j off full longest } {
    j lens prim seq-int.len prim >=
    [ full longest ]
    [ lens j get locals { n } {
        chars off n 0 prim seq-int.empty slice locals { sc } {
          nd sc root n zeros 0 1 put ev locals { r } {
            nd root chars lens j 1 prim + off n prim +
            full r n get 1 prim = prim seq-bool.push
            longest r n hi prim seq-int.push
            strs } } } ]
    if };

: cntb (forall ρ; ρ f:Seq Bool^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { f i acc } {
    i f prim seq-bool.len prim >=
    [ acc ]
    [ f i 1 prim + f i prim seq-bool.at [ acc 1 prim + ] [ acc ] if cntb ] if };

: main (forall ρ; ρ pat:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pat lens chars } {
    pat prim seq-int.empty 0 palt locals { nd pos root } {
      pos pat prim seq-int.len prim = locals { v } {
        v [ nd root ]
          [ prim seq-int.empty 0 prim seq-int.push 99 prim seq-int.push 0 prim seq-int.push 0 ] if
        locals { nd2 root2 } {
          nd2 root2 chars lens 0 0 prim seq-bool.empty prim seq-int.empty strs
          locals { full longest } {
            full longest full 0 0 cntb v } } } } };
```

### task: swiss
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };

: better3 (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many a:Int^many b:Int^many -- ρ r:Bool^many)
  locals { k1 k2 k3 a b } {
    k1 a get k1 b get prim > k1 a get k1 b get prim =
    k2 a get k2 b get prim > k2 a get k2 b get prim =
    k3 a get k3 b get prim > k3 a get k3 b get prim =
    a b prim <
    prim and prim or prim and prim or prim and prim or };

: pick (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many used:Seq Int^many q:Int^many best:Int^many -- ρ r:Int^many)
  locals { k1 k2 k3 n used q best } {
    q n prim >=
    [ best ]
    [ used q get 1 prim =
      [ k1 k2 k3 n used q 1 prim + best pick ]
      [ k1 k2 k3 n used q 1 prim +
        best 0 prim < [ q ] [ k1 k2 k3 q best better3 [ q ] [ best ] if ] if
        pick ] if ] if };

: selloop (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many used:Seq Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 n used out } {
    out prim seq-int.len n prim >=
    [ out ]
    [ k1 k2 k3 n used 0 -1 pick locals { b } {
        k1 k2 k3 n used b 1 put out b prim seq-int.push selloop } ] if };

: sortrank (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 n } {
    k1 k2 k3 n prim seq-int.empty 0 n pushn prim seq-int.empty selloop };

: findbye (forall ρ; ρ st:Seq Int^many rank:Seq Int^many i:Int^many -- ρ p:Int^many)
  locals { st rank i } {
    rank i get locals { p } {
      st 12 p prim + get 0 prim =
      [ p ] [ st rank i 1 prim - findbye ] if } };

: dobye (forall ρ; ρ st:Seq Int^many rank:Seq Int^many r:Int^many -- ρ s2:Seq Int^many)
  locals { st rank r } {
    st 218 get 2 prim mod 1 prim =
    [ st rank st 218 get 1 prim - findbye locals { p } {
        st p 2 incr 12 p prim + 1 put 60 p prim + r 1 prim + put } ]
    [ st ] if };

: findq (forall ρ; ρ st:Seq Int^many rank:Seq Int^many r:Int^many p:Int^many mode:Int^many i:Int^many -- ρ q:Int^many)
  locals { st rank r p mode i } {
    i st 218 get prim >=
    [ -1 ]
    [ rank i get locals { q } {
        st 60 q prim + get r 1 prim + prim = prim not
        mode 1 prim = st 72 p 12 prim * prim + q prim + get 0 prim = prim or
        prim and
        [ q ] [ st rank r p mode i 1 prim + findq ] if } ]
    if };

: play (forall ρ; ρ st:Seq Int^many rs:Seq Int^many w:Int^many b:Int^many -- ρ s2:Seq Int^many)
  locals { st rs w b } {
    rs st 217 get get locals { res } {
      st 217 st 217 get 1 prim + put locals { s0 } {
        s0 216 s0 72 w 12 prim * prim + b prim + get 0 prim > [ 1 ] [ 0 ] if incr
        72 w 12 prim * prim + b prim + 1 incr
        72 b 12 prim * prim + w prim + 1 incr
        24 w prim + 1 incr
        36 w prim + 1 put
        36 b prim + 2 put
        locals { s3 } {
          res 0 prim = [ s3 w 2 incr ]
          [ res 1 prim = [ s3 w 1 incr b 1 incr ] [ s3 b 2 incr ] if ] if } } } };

: game (forall ρ; ρ st:Seq Int^many rs:Seq Int^many p:Int^many q:Int^many -- ρ s2:Seq Int^many)
  locals { st rs p q } {
    st 24 p prim + get st 24 q prim + get prim <
    st 24 p prim + get st 24 q prim + get prim =
    st 36 q prim + get 2 prim = st 36 p prim + get 2 prim = prim not prim and prim not
    prim and prim or
    [ st rs p q play ] [ st rs q p play ] if };

: pairs (forall ρ; ρ st:Seq Int^many rank:Seq Int^many rs:Seq Int^many r:Int^many i:Int^many -- ρ s2:Seq Int^many)
  locals { st rank rs r i } {
    i st 218 get prim >=
    [ st ]
    [ rank i get locals { p } {
        st 60 p prim + get r 1 prim + prim =
        [ st rank rs r i 1 prim + pairs ]
        [ st 60 p prim + r 1 prim + put locals { s1 } {
            s1 rank r p 0 0 findq locals { q0 } {
              q0 0 prim < [ s1 rank r p 1 0 findq ] [ q0 ] if locals { q } {
                s1 60 q prim + r 1 prim + put rs p q game
                rank rs r i 1 prim + pairs } } } ] if } ]
    if };

: round (forall ρ; ρ st:Seq Int^many rt:Seq Int^many rs:Seq Int^many r:Int^many nr:Int^many -- ρ s2:Seq Int^many)
  locals { st rt rs r nr } {
    r nr prim >=
    [ st ]
    [ st rt rt st 218 get sortrank locals { rank } {
        st rank r dobye rank rs r 0 pairs
        locals { s2 } { s2 rt rs r 1 prim + nr round } } ] if };

: bsum (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many n:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p q n acc } {
    q n prim >=
    [ acc ]
    [ st p q 1 prim + n acc st 72 p 12 prim * prim + q prim + get st q get prim * prim + bsum ] if };

: buchl (forall ρ; ρ st:Seq Int^many p:Int^many n:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st p n out } {
    p n prim >=
    [ out ]
    [ st p 1 prim + n out st p 0 n 0 bsum prim seq-int.push buchl ] if };

: blk (forall ρ; ρ st:Seq Int^many base:Int^many n:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st base n i out } {
    i n prim >=
    [ out ]
    [ st base n i 1 prim + out st base i prim + get prim seq-int.push blk ] if };

: main (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buch:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rem:Int^many)
  locals { rt rounds rs } {
    prim seq-int.empty 0 219 pushn 218 rt prim seq-int.len put
    rt rs 0 rounds round locals { st } {
      st 0 rt prim seq-int.len 0 prim seq-int.empty blk locals { sc } {
        st 0 rt prim seq-int.len prim seq-int.empty buchl locals { bh } {
          sc bh sc bh rt rt prim seq-int.len sortrank
          st 24 rt prim seq-int.len 0 prim seq-int.empty blk
          st 216 get } } } };
```
NOTE: in swiss, the output order must be scores, buchholz, ranking, whites, rematches; the final lines of main above push `sc bh` first as the first two outputs only if left on the stack, so main is rewritten correctly below.

### task: swiss
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };

: better3 (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many a:Int^many b:Int^many -- ρ r:Bool^many)
  locals { k1 k2 k3 a b } {
    k1 a get k1 b get prim > k1 a get k1 b get prim =
    k2 a get k2 b get prim > k2 a get k2 b get prim =
    k3 a get k3 b get prim > k3 a get k3 b get prim =
    a b prim <
    prim and prim or prim and prim or prim and prim or };

: pick (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many used:Seq Int^many q:Int^many best:Int^many -- ρ r:Int^many)
  locals { k1 k2 k3 n used q best } {
    q n prim >=
    [ best ]
    [ used q get 1 prim =
      [ k1 k2 k3 n used q 1 prim + best pick ]
      [ k1 k2 k3 n used q 1 prim +
        best 0 prim < [ q ] [ k1 k2 k3 q best better3 [ q ] [ best ] if ] if
        pick ] if ] if };

: selloop (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many used:Seq Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 n used out } {
    out prim seq-int.len n prim >=
    [ out ]
    [ k1 k2 k3 n used 0 -1 pick locals { b } {
        k1 k2 k3 n used b 1 put out b prim seq-int.push selloop } ] if };

: sortrank (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 n } {
    k1 k2 k3 n prim seq-int.empty 0 n pushn prim seq-int.empty selloop };

: findbye (forall ρ; ρ st:Seq Int^many rank:Seq Int^many i:Int^many -- ρ p:Int^many)
  locals { st rank i } {
    rank i get locals { p } {
      st 12 p prim + get 0 prim =
      [ p ] [ st rank i 1 prim - findbye ] if } };

: dobye (forall ρ; ρ st:Seq Int^many rank:Seq Int^many r:Int^many -- ρ s2:Seq Int^many)
  locals { st rank r } {
    st 218 get 2 prim mod 1 prim =
    [ st rank st 218 get 1 prim - findbye locals { p } {
        st p 2 incr 12 p prim + 1 put 60 p prim + r 1 prim + put } ]
    [ st ] if };

: findq (forall ρ; ρ st:Seq Int^many rank:Seq Int^many r:Int^many p:Int^many mode:Int^many i:Int^many -- ρ q:Int^many)
  locals { st rank r p mode i } {
    i st 218 get prim >=
    [ -1 ]
    [ rank i get locals { q } {
        st 60 q prim + get r 1 prim + prim = prim not
        mode 1 prim = st 72 p 12 prim * prim + q prim + get 0 prim = prim or
        prim and
        [ q ] [ st rank r p mode i 1 prim + findq ] if } ]
    if };

: play (forall ρ; ρ st:Seq Int^many rs:Seq Int^many w:Int^many b:Int^many -- ρ s2:Seq Int^many)
  locals { st rs w b } {
    rs st 217 get get locals { res } {
      st 217 st 217 get 1 prim + put locals { s0 } {
        s0 216 s0 72 w 12 prim * prim + b prim + get 0 prim > [ 1 ] [ 0 ] if incr
        72 w 12 prim * prim + b prim + 1 incr
        72 b 12 prim * prim + w prim + 1 incr
        24 w prim + 1 incr
        36 w prim + 1 put
        36 b prim + 2 put
        locals { s3 } {
          res 0 prim = [ s3 w 2 incr ]
          [ res 1 prim = [ s3 w 1 incr b 1 incr ] [ s3 b 2 incr ] if ] if } } } };

: game (forall ρ; ρ st:Seq Int^many rs:Seq Int^many p:Int^many q:Int^many -- ρ s2:Seq Int^many)
  locals { st rs p q } {
    st 24 p prim + get st 24 q prim + get prim <
    st 24 p prim + get st 24 q prim + get prim =
    st 36 q prim + get 2 prim = st 36 p prim + get 2 prim = prim not prim and prim not
    prim and prim or
    [ st rs p q play ] [ st rs q p play ] if };

: pairs (forall ρ; ρ st:Seq Int^many rank:Seq Int^many rs:Seq Int^many r:Int^many i:Int^many -- ρ s2:Seq Int^many)
  locals { st rank rs r i } {
    i st 218 get prim >=
    [ st ]
    [ rank i get locals { p } {
        st 60 p prim + get r 1 prim + prim =
        [ st rank rs r i 1 prim + pairs ]
        [ st 60 p prim + r 1 prim + put locals { s1 } {
            s1 rank r p 0 0 findq locals { q0 } {
              q0 0 prim < [ s1 rank r p 1 0 findq ] [ q0 ] if locals { q } {
                s1 60 q prim + r 1 prim + put rs p q game
                rank rs r i 1 prim + pairs } } } ] if } ]
    if };

: round (forall ρ; ρ st:Seq Int^many rt:Seq Int^many rs:Seq Int^many r:Int^many nr:Int^many -- ρ s2:Seq Int^many)
  locals { st rt rs r nr } {
    r nr prim >=
    [ st ]
    [ st rt rt st 218 get sortrank locals { rank } {
        st rank r dobye rank rs r 0 pairs
        locals { s2 } { s2 rt rs r 1 prim + nr round } } ] if };

: bsum (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many n:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p q n acc } {
    q n prim >=
    [ acc ]
    [ st p q 1 prim + n acc st 72 p 12 prim * prim + q prim + get st q get prim * prim + bsum ] if };

: buchl (forall ρ; ρ st:Seq Int^many p:Int^many n:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st p n out } {
    p n prim >=
    [ out ]
    [ st p 1 prim + n out st p 0 n 0 bsum prim seq-int.push buchl ] if };

: blk (forall ρ; ρ st:Seq Int^many base:Int^many n:Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st base n i out } {
    i n prim >=
    [ out ]
    [ st base n i 1 prim + out st base i prim + get prim seq-int.push blk ] if };

: main (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buch:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rem:Int^many)
  locals { rt rounds rs } {
    prim seq-int.empty 0 219 pushn 218 rt prim seq-int.len put
    rt rs 0 rounds round locals { st } {
      st 0 rt prim seq-int.len 0 prim seq-int.empty blk locals { sc } {
        st 0 rt prim seq-int.len prim seq-int.empty buchl locals { bh } {
          sc bh sc bh rt rt prim seq-int.len sortrank
          st 24 rt prim seq-int.len 0 prim seq-int.empty blk
          st 216 get } } } };
```
NOTE: the first swiss block above is a duplicate draft of the second and its main is wrong (its `buchl` call omitted the start index); please use the second swiss block only. In the second block `main` calls `sortrank` with `sc bh rt` as k1 k2 k3 but leaves `sc bh` below as the first two outputs, which is the intended output order.

### task: warehouse
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };
: app (forall ρ; ρ d:Seq Int^many s:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { d s i } { i s prim seq-int.len prim >= [ d ] [ d s i get prim seq-int.push s i 1 prim + app ] if };
: app5 (forall ρ; ρ st:Seq Int^many src:Seq Int^many -- ρ r:Seq Int^many)
  locals { st src } { st src 0 app 0 5 src prim seq-int.len prim - pushn };

: rg (forall ρ; ρ p:Int^many k:Int^many -- ρ i:Int^many)
  locals { p k } { 1600 p 8 prim * prim + k prim + };
: slot (forall ρ; ρ p:Int^many i:Int^many f:Int^many -- ρ x:Int^many)
  locals { p i f } { p 320 prim * i 2 prim * prim + f prim + };
: bq (forall ρ; ρ p:Int^many j:Int^many f:Int^many -- ρ x:Int^many)
  locals { p j f } { 1640 p 160 prim * prim + j 2 prim * prim + f prim + };

: place (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many e:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { st p q e j } { st p j 0 slot q put p j 1 slot e put };

: ins (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many e:Int^many h:Int^many j:Int^many -- ρ r:Seq Int^many)
  locals { st p q e h j } {
    j h prim >
    [ st p j 1 prim - 1 slot get e prim >
      [ st p j 0 slot st p j 1 prim - 0 slot get put
        p j 1 slot st p j 1 prim - 1 slot get put
        p q e h j 1 prim - ins ]
      [ st p q e j place ] if ]
    [ st p q e j place ] if };

: takeloop (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { st p q } {
    q 0 prim <=
    [ st ]
    [ st p 0 rg get locals { h } {
        st p h 0 slot get locals { a } {
          a q prim <=
          [ st p 0 rg 1 incr p q a prim - takeloop ]
          [ st p h 0 slot a q prim - put ] if } } ]
    if };

: take (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many)
  locals { st p q } {
    st p q takeloop locals { s1 } {
      s1 2440 st 2448 p prim + get q prim * incr 2441 q incr p 5 rg 0 q prim - incr } };

: fillbo (forall ρ; ρ st:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st p } {
    st p 2 rg get st p 3 rg get prim <
    st p 5 rg get 0 prim > prim and
    [ st p 2 rg get locals { bh } {
        st p bh 0 bq get locals { o } {
          st p 5 rg get locals { s } {
            o s prim <= [ o ] [ s ] if locals { tk } {
              st p tk take locals { s1 } {
                s1 p bh 0 bq o tk prim - put locals { s2 } {
                  o tk prim = [ s2 p 2 rg 1 incr ] [ s2 ] if
                  p fillbo } } } } } } ]
    [ st ] if };

: lotadd (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { st p q e } {
    st p 0 rg get st p 1 rg get locals { h t } {
      st p q e h t ins locals { s1 } {
        s1 p 1 rg 1 incr p 5 rg q incr p fillbo } } };

: enq (forall ρ; ρ st:Seq Int^many p:Int^many o:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p o d } {
    st p 3 rg get locals { tl } {
      st p tl 0 bq o put p tl 1 bq d put p 3 rg 1 incr } };

: order (forall ρ; ρ st:Seq Int^many p:Int^many q:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p q d } {
    st p 2 rg get st p 3 rg get prim <
    [ st p q d enq ]
    [ st p 5 rg get locals { s } {
        s q prim <= [ s ] [ q ] if locals { t } {
          st p t take locals { s1 } {
            q t prim - locals { r } {
              r 0 prim > [ s1 p r d enq ] [ s1 ] if } } } } ]
    if };

: disc1 (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    st p 0 rg get st p 1 rg get prim <
    [ st p 0 rg get locals { h } {
        st p h 1 slot get d prim <
        [ st p h 0 slot get locals { a } {
            st 2442 a incr p 5 rg 0 a prim - incr p 0 rg 1 incr p d disc1 } ]
        [ st ] if } ]
    [ st ] if };

: arr1 (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    st p 4 rg get d 1 prim + prim =
    [ st p st 2458 p prim + get d st 2468 p prim + get prim + lotadd p 4 rg 0 put ]
    [ st ] if };

: canc1 (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    st p 2 rg get st p 3 rg get prim <
    [ st p 2 rg get locals { bh } {
        st p bh 1 bq get d 7 prim - prim <=
        [ st 2443 st p bh 0 bq get incr p 2 rg 1 incr p d canc1 ]
        [ st ] if } ]
    [ st ] if };

: reord1 (forall ρ; ρ st:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st p d } {
    st p 4 rg get 0 prim = st p 5 rg get st 2453 p prim + get prim <= prim and
    [ st p 4 rg d st 2463 p prim + get prim + 1 prim + put 2444 1 incr ]
    [ st ] if };

: pdisc (forall ρ; ρ st:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st d p } { p st 2473 get prim >= [ st ] [ st p d disc1 d p 1 prim + pdisc ] if };
: parr (forall ρ; ρ st:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st d p } { p st 2473 get prim >= [ st ] [ st p d arr1 d p 1 prim + parr ] if };
: pcanc (forall ρ; ρ st:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st d p } { p st 2473 get prim >= [ st ] [ st p d canc1 d p 1 prim + pcanc ] if };
: preord (forall ρ; ρ st:Seq Int^many d:Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { st d p } { p st 2473 get prim >= [ st ] [ st p d reord1 d p 1 prim + preord ] if };

: doev (forall ρ; ρ st:Seq Int^many ev:Seq Int^many e:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st ev e d } {
    ev e 5 prim * 2 prim + get locals { p } {
      ev e 5 prim * 3 prim + get locals { q } {
        ev e 5 prim * 1 prim + get 1 prim =
        [ st p q ev e 5 prim * 4 prim + get lotadd ]
        [ st p q d order ] if } } };

: events (forall ρ; ρ st:Seq Int^many ev:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st ev d } {
    st 2445 get locals { e } {
      e ev prim seq-int.len 5 prim div prim <
      [ ev e 5 prim * get d prim =
        [ st ev e d doev 2445 1 incr ev d events ]
        [ st ] if ]
      [ st ] if } };

: rundays (forall ρ; ρ st:Seq Int^many ev:Seq Int^many d:Int^many nd:Int^many -- ρ r:Seq Int^many)
  locals { st ev d nd } {
    d nd prim >=
    [ st ]
    [ st d 0 pdisc d 0 parr ev d events d 0 pcanc d 0 preord ev d 1 prim + nd rundays ] if };

: pack (forall ρ; ρ d:Seq Int^many k:Seq Int^many p:Seq Int^many q:Seq Int^many x:Seq Int^many i:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { d k p q x i out } {
    i d prim seq-int.len prim >=
    [ out ]
    [ d k p q x i 1 prim + out
      d i get prim seq-int.push k i get prim seq-int.push p i get prim seq-int.push
      q i get prim seq-int.push x i get prim seq-int.push pack ] if };

: stk (forall ρ; ρ st:Seq Int^many p:Int^many n:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st p n out } {
    p n prim >=
    [ out ]
    [ st p 1 prim + n out st p 5 rg get prim seq-int.push stk ] if };

: owedp (forall ρ; ρ st:Seq Int^many p:Int^many j:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p j acc } {
    j st p 3 rg get prim >=
    [ acc ]
    [ st p j 1 prim + acc st p j 0 bq get prim + owedp ] if };

: owedall (forall ρ; ρ st:Seq Int^many p:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st p acc } {
    p st 2473 get prim >=
    [ acc ]
    [ st p 1 prim + acc st p st p 2 rg get 0 owedp prim + owedall ] if };

: main (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many evx:Seq Int^many
   -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many disc:Int^many canc:Int^many supp:Int^many owed:Int^many)
  locals { days price rp rq lead shelf evd evk evp evq evx } {
    prim seq-int.empty 0 2448 pushn
    price app5 rp app5 rq app5 lead app5 shelf app5
    price prim seq-int.len prim seq-int.push
    locals { st } {
      evd evk evp evq evx 0 prim seq-int.empty pack locals { ev } {
        st ev 0 days rundays locals { fin } {
          fin 0 fin 2473 get prim seq-int.empty stk
          fin 2440 get fin 2441 get fin 2442 get fin 2443 get fin 2444 get
          fin 0 0 owedall } } } };
```

### task: cache-sim
```firth
: get (forall ρ; ρ s:Seq Int^many i:Int^many -- ρ v:Int^many) prim seq-int.at;
: put (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: incr (forall ρ; ρ s:Seq Int^many i:Int^many v:Int^many -- ρ r:Seq Int^many)
  locals { s i v } { s i s i get v prim + put };
: pushn (forall ρ; ρ s:Seq Int^many v:Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s v n } { n 0 prim <= [ s ] [ s v prim seq-int.push v n 1 prim - pushn ] if };

: ea (forall ρ; ρ sb:Int^many k:Int^many -- ρ i:Int^many)
  locals { sb k } { sb 1 prim + k 2 prim * prim + };

: find (forall ρ; ρ st:Seq Int^many sb:Int^many a:Int^many k:Int^many -- ρ pos:Int^many)
  locals { st sb a k } {
    k st sb get prim >=
    [ -1 ]
    [ st sb k ea get a prim = [ k ] [ st sb a k 1 prim + find ] if ] if };

: shl (forall ρ; ρ st:Seq Int^many sb:Int^many k:Int^many last:Int^many -- ρ r:Seq Int^many)
  locals { st sb k last } {
    k last prim >=
    [ st ]
    [ st sb k ea st sb k 1 prim + ea get put
      sb k ea 1 prim + st sb k 1 prim + ea 1 prim + get put
      sb k 1 prim + last shl ] if };

: removeat (forall ρ; ρ st:Seq Int^many sb:Int^many pos:Int^many -- ρ r:Seq Int^many)
  locals { st sb pos } { st sb pos st sb get 1 prim - shl sb -1 incr };

: lapp (forall ρ; ρ st:Seq Int^many sb:Int^many a:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { st sb a d } {
    st sb st sb get ea a put sb st sb get ea 1 prim + d put sb 1 incr };

: ins (forall ρ; ρ st:Seq Int^many sb:Int^many w:Int^many a:Int^many d:Int^many -- ρ r:Seq Int^many eb:Int^many ed:Int^many)
  locals { st sb w a d } {
    st sb get w prim >=
    [ st sb 0 ea get st sb 0 ea 1 prim + get locals { eb ed } {
        st sb 0 removeat sb a d lapp eb ed } ]
    [ st sb a d lapp -1 0 ] if };

: touch (forall ρ; ρ st:Seq Int^many sb:Int^many pos:Int^many wr:Int^many -- ρ r:Seq Int^many)
  locals { st sb pos wr } {
    st sb pos ea get st sb pos ea 1 prim + get locals { a d } {
      st sb pos removeat sb a d wr prim + 0 prim > [ 1 ] [ 0 ] if lapp } };

: sbl (forall ρ; ρ st:Seq Int^many lvl:Int^many a:Int^many -- ρ sb:Int^many)
  locals { st lvl a } {
    lvl 0 prim = [ 0 st 210 get ] [ 68 st 212 get ] if
    locals { base s } { base a s prim mod 17 prim * prim + } };

: wl (forall ρ; ρ st:Seq Int^many lvl:Int^many -- ρ w:Int^many)
  locals { st lvl } { lvl 0 prim = [ st 211 get ] [ st 213 get ] if };

: wb (forall ρ; ρ st:Seq Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { st b } {
    st 1 b sbl locals { sb2 } {
      st sb2 b 0 find locals { pos } {
        pos 0 prim >=
        [ st sb2 pos 1 touch ]
        [ st sb2 st 1 wl b 1 ins locals { s1 eb ed } {
            ed 1 prim = [ s1 209 1 incr ] [ s1 ] if } ]
        if } } };

: l1put (forall ρ; ρ st:Seq Int^many a:Int^many wr:Int^many -- ρ r:Seq Int^many)
  locals { st a wr } {
    st st 0 a sbl st 0 wl a wr ins locals { s1 eb ed } {
      ed 1 prim = [ s1 eb wb ] [ s1 ] if } };

: miss (forall ρ; ρ st:Seq Int^many a:Int^many wr:Int^many -- ρ r:Seq Int^many)
  locals { st a wr } {
    st 1 a sbl locals { sb2 } {
      st sb2 a 0 find locals { pos2 } {
        pos2 0 prim >=
        [ st 206 1 incr sb2 pos2 0 touch ]
        [ st 207 1 incr 208 1 incr sb2 st 1 wl a 0 ins locals { s1 eb ed } {
            ed 1 prim = [ s1 209 1 incr ] [ s1 ] if } ]
        if
        a wr l1put } } };

: access (forall ρ; ρ st:Seq Int^many a:Int^many wr:Int^many -- ρ r:Seq Int^many)
  locals { st a wr } {
    st 0 a sbl locals { sb1 } {
      st sb1 a 0 find locals { pos1 } {
        pos1 0 prim >=
        [ st 204 1 incr sb1 pos1 wr touch ]
        [ st 205 1 incr a wr miss ] if } } };

: run (forall ρ; ρ st:Seq Int^many addrs:Seq Int^many writes:Seq Bool^many i:Int^many -- ρ r:Seq Int^many)
  locals { st addrs writes i } {
    i addrs prim seq-int.len prim >=
    [ st ]
    [ st addrs i get writes i prim seq-bool.at [ 1 ] [ 0 ] if access
      addrs writes i 1 prim + run ] if };

: dsum (forall ρ; ρ st:Seq Int^many sb:Int^many k:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st sb k acc } {
    k st sb get prim >=
    [ acc ]
    [ st sb k 1 prim + acc st sb k ea 1 prim + get prim + dsum ] if };

: dsets (forall ρ; ρ st:Seq Int^many lb:Int^many s:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { st lb s i acc } {
    i s prim >=
    [ acc ]
    [ st lb s i 1 prim + acc st lb i 17 prim * prim + 0 0 dsum prim + dsets ] if };

: blks (forall ρ; ρ st:Seq Int^many sb:Int^many k:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st sb k out } {
    k st sb get prim >=
    [ out ]
    [ st sb k 1 prim + out st sb k ea get prim seq-int.push blks ] if };

: blkall (forall ρ; ρ st:Seq Int^many i:Int^many ns:Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { st i ns out } {
    i ns prim >=
    [ out ]
    [ st i 1 prim + ns st i 17 prim * 0 out blks blkall ] if };

: main (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many
   -- ρ h1:Int^many m1:Int^many h2:Int^many m2:Int^many rd:Int^many wrt:Int^many dirty:Int^many blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    prim seq-int.empty 0 214 pushn 210 s1 put 211 w1 put 212 s2 put 213 w2 put
    addrs writes 0 run locals { st } {
      st 204 get st 205 get st 206 get st 207 get st 208 get st 209 get
      st 0 st 210 get 0 0 dsets st 68 st 212 get 0 0 dsets prim +
      st 0 st 210 get prim seq-int.empty blkall } };
```

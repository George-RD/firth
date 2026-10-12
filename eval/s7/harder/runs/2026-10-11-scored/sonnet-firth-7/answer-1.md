### task: sokoban
```firth
: allgoal
  (forall ρ; ρ cells:Seq Int boxes:Seq Int k:Int -- ρ r:Bool)
  locals { cells boxes k } {
    k boxes prim seq-int.len prim >=
    [ true ]
    [ cells boxes k prim seq-int.at prim seq-int.at 2 prim =
      [ cells boxes k 1 prim + allgoal ]
      [ false ]
      if ]
    if };

: delta
  (forall ρ; ρ w:Int d:Int -- ρ r:Int)
  locals { w d } {
    d 0 prim =
    [ 0 w prim - ]
    [ d 1 prim =
      [ 1 ]
      [ d 2 prim = [ w ] [ -1 ] if ]
      if ]
    if };

: findbox
  (forall ρ; ρ boxes:Seq Int c:Int k:Int -- ρ r:Int)
  locals { boxes c k } {
    k boxes prim seq-int.len prim >=
    [ -1 ]
    [ boxes k prim seq-int.at c prim =
      [ k ]
      [ boxes c k 1 prim + findbox ]
      if ]
    if };

: bump
  (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } { st i st i prim seq-int.at 1 prim + prim seq-int.set };

: rec
  (forall ρ; ρ st:Seq Int mv:Seq Int e:Int -- ρ st2:Seq Int mv2:Seq Int)
  locals { st mv e } {
    st 2 prim seq-int.at
    locals { hl } {
      st 2 hl 1 prim + prim seq-int.set
      mv hl e prim seq-int.set } };

: isdead
  (forall ρ; ρ cells:Seq Int u:Int w:Int -- ρ r:Bool)
  locals { cells u w } {
    cells u prim seq-int.at 2 prim = prim not
    cells u w prim - prim seq-int.at 1 prim =
    cells u w prim + prim seq-int.at 1 prim = prim or prim and
    cells u 1 prim - prim seq-int.at 1 prim =
    cells u 1 prim + prim seq-int.at 1 prim = prim or prim and };

: fwd
  (forall ρ; ρ w:Int cells:Seq Int boxes:Seq Int st:Seq Int mv:Seq Int d:Int
   -- ρ w2:Int cells2:Seq Int boxes2:Seq Int st2:Seq Int mv2:Seq Int)
  locals { w cells boxes st mv d } {
    w d delta
    locals { dl } {
      st 0 prim seq-int.at dl prim +
      locals { t } {
        cells t prim seq-int.at 1 prim =
        [ w cells boxes st 4 bump mv ]
        [ boxes t 0 findbox
          locals { bi } {
            bi 0 prim <
            [ w cells boxes st 0 t prim seq-int.set mv d 2 prim * rec ]
            [ t dl prim +
              locals { u } {
                cells u prim seq-int.at 1 prim =
                boxes u 0 findbox 0 prim >= prim or
                [ w cells boxes st 4 bump mv ]
                [ w cells boxes bi u prim seq-int.set
                  st 0 t prim seq-int.set 3 bump
                  cells u w isdead [ 6 bump ] [ ] if
                  mv d 2 prim * 1 prim + rec ]
                if } ]
            if } ]
        if } } };

: undo
  (forall ρ; ρ w:Int cells:Seq Int boxes:Seq Int st:Seq Int mv:Seq Int
   -- ρ w2:Int cells2:Seq Int boxes2:Seq Int st2:Seq Int mv2:Seq Int)
  locals { w cells boxes st mv } {
    st 2 prim seq-int.at
    locals { hl } {
      hl 0 prim <=
      [ w cells boxes st mv ]
      [ mv hl 1 prim - prim seq-int.at
        locals { e } {
          e 2 prim div
          locals { d } {
            w d delta
            locals { dl } {
              st 0 prim seq-int.at
              locals { p } {
                w cells
                e 2 prim mod 1 prim =
                [ boxes boxes p dl prim + 0 findbox p prim seq-int.set ]
                [ boxes ]
                if
                st 0 p dl prim - prim seq-int.set 2 hl 1 prim - prim seq-int.set 5 bump
                mv } } } } ]
      if } };

: apply
  (forall ρ; ρ w:Int cells:Seq Int boxes:Seq Int st:Seq Int mv:Seq Int
   -- ρ w2:Int cells2:Seq Int boxes2:Seq Int st2:Seq Int mv2:Seq Int)
  locals { w cells boxes st mv } {
    mv st 1 prim seq-int.at prim seq-int.at
    locals { m } {
      st 1 st 1 prim seq-int.at 1 prim + prim seq-int.set
      locals { st1 } {
        m 4 prim =
        [ w cells boxes st1 mv undo ]
        [ w cells boxes st1 mv m fwd ]
        if } } };

: play
  (forall ρ; ρ w:Int cells:Seq Int boxes:Seq Int st:Seq Int mv:Seq Int
   -- ρ boxes2:Seq Int st2:Seq Int)
  locals { w cells boxes st mv } {
    st 1 prim seq-int.at mv prim seq-int.len prim >=
    [ boxes st ]
    [ cells boxes 0 allgoal
      [ boxes st ]
      [ w cells boxes st mv apply play ]
      if ]
    if };

: main
  (forall ρ; ρ width:Int height:Int cells:Seq Int player:Int boxes:Seq Int moves:Seq Int
   -- ρ player:Int boxes:Seq Int read:Int history:Int pushes:Int blocked:Int undos:Int dead:Int solved:Bool)
  locals { width height cells player boxes moves } {
    width cells boxes
    prim seq-int.empty player prim seq-int.push
    0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    moves play
    locals { fb st } {
      st 0 prim seq-int.at
      fb
      st 1 prim seq-int.at
      st 2 prim seq-int.at
      st 3 prim seq-int.at
      st 4 prim seq-int.at
      st 5 prim seq-int.at
      st 6 prim seq-int.at
      cells fb 0 allgoal } };
```

### task: checkers
```firth
: colof
  (forall ρ; ρ sq:Int -- ρ c:Int)
  locals { sq } { 2 sq 4 prim mod prim * 1 prim + sq 4 prim div 2 prim mod prim - };

: nbr
  (forall ρ; ρ sq:Int d:Int -- ρ r:Int)
  locals { sq d } {
    sq 4 prim div
    locals { r } {
      sq colof
      locals { c } {
        r d 2 prim < [ -1 ] [ 1 ] if prim +
        locals { r2 } {
          c d 2 prim mod 0 prim = [ -1 ] [ 1 ] if prim +
          locals { c2 } {
            r2 0 prim < r2 7 prim > prim or c2 0 prim < c2 7 prim > prim or prim or
            [ -1 ]
            [ r2 4 prim * c2 2 prim div prim + ]
            if } } } } };

: mayd
  (forall ρ; ρ p:Int d:Int -- ρ r:Bool)
  locals { p d } {
    p 2 prim mod 0 prim =
    p 1 prim = d 2 prim < prim and prim or
    p 3 prim = d 1 prim > prim and prim or };

: isfar
  (forall ρ; ρ p:Int sq:Int -- ρ r:Bool)
  locals { p sq } {
    p 1 prim = sq 4 prim div 0 prim = prim and
    p 3 prim = sq 4 prim div 7 prim = prim and prim or };

: midsq
  (forall ρ; ρ a:Int b:Int -- ρ m:Int)
  locals { a b } {
    a 4 prim div b 4 prim div prim + 2 prim div 4 prim *
    a colof b colof prim + 2 prim div 2 prim div prim + };

: addto
  (forall ρ; ρ st:Seq Int i:Int k:Int -- ρ r:Seq Int)
  locals { st i k } { st i st i prim seq-int.at k prim + prim seq-int.set };

: minint
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } { a b prim < [ a ] [ b ] if };

: jumpland
  (forall ρ; ρ board:Seq Int sq:Int p:Int d:Int -- ρ r:Int)
  locals { board sq p d } {
    p d mayd
    [ sq d nbr
      locals { m } {
        m 0 prim <
        [ -1 ]
        [ board m prim seq-int.at
          locals { q } {
            q 0 prim > q 1 prim - 2 prim div p 1 prim - 2 prim div prim = prim not prim and
            [ m d nbr
              locals { l } {
                l 0 prim <
                [ -1 ]
                [ board l prim seq-int.at 0 prim = [ l ] [ -1 ] if ]
                if } ]
            [ -1 ]
            if } ]
        if } ]
    [ -1 ]
    if };

: anyjump
  (forall ρ; ρ board:Seq Int sq:Int p:Int -- ρ r:Bool)
  locals { board sq p } {
    board sq p 0 jumpland 0 prim >=
    board sq p 1 jumpland 0 prim >= prim or
    board sq p 2 jumpland 0 prim >= prim or
    board sq p 3 jumpland 0 prim >= prim or };

: cmpfrom
  (forall ρ; ρ a:Seq Int b:Seq Int i:Int -- ρ r:Bool)
  locals { a b i } {
    i a prim seq-int.len prim >=
    [ false ]
    [ a i prim seq-int.at b i prim seq-int.at prim <
      [ true ]
      [ a i prim seq-int.at b i prim seq-int.at prim >
        [ false ]
        [ a b i 1 prim + cmpfrom ]
        if ]
      if ]
    if };

: better
  (forall ρ; ρ cand:Seq Int best:Seq Int -- ρ r:Bool)
  locals { cand best } {
    best prim seq-int.len 0 prim =
    [ true ]
    [ cand 0 prim seq-int.at best 0 prim seq-int.at prim >
      [ true ]
      [ cand 0 prim seq-int.at best 0 prim seq-int.at prim <
        [ false ]
        [ cand best 1 cmpfrom ]
        if ]
      if ]
    if };

: pick
  (forall ρ; ρ path:Seq Int best:Seq Int -- ρ r:Seq Int)
  locals { path best } { path best better [ path ] [ best ] if };

: dfs
  (forall ρ; ρ board:Seq Int sq:Int p:Int path:Seq Int best:Seq Int -- ρ r:Seq Int)
  locals { board sq p path best } {
    board sq p anyjump
    [ board sq p path best 0 tryd
      locals { b0 } {
        board sq p path b0 1 tryd
        locals { b1 } {
          board sq p path b1 2 tryd
          locals { b2 } { board sq p path b2 3 tryd } } } ]
    [ path best pick ]
    if };

: tryd
  (forall ρ; ρ board:Seq Int sq:Int p:Int path:Seq Int best:Seq Int d:Int -- ρ r:Seq Int)
  locals { board sq p path best d } {
    board sq p d jumpland
    locals { l } {
      l 0 prim <
      [ best ]
      [ sq d nbr
        locals { m } {
          path 0 path 0 prim seq-int.at 1 prim + prim seq-int.set l prim seq-int.push
          locals { path2 } {
            p l isfar
            [ path2 best pick ]
            [ board m 0 prim seq-int.set l p path2 best dfs ]
            if } } ]
      if } };

: scan
  (forall ρ; ρ board:Seq Int side:Int s:Int best:Seq Int -- ρ r:Seq Int)
  locals { board side s best } {
    s 32 prim >=
    [ best ]
    [ board s prim seq-int.at
      locals { p } {
        p 0 prim > p 1 prim - 2 prim div side prim = prim and
        [ board s 0 prim seq-int.set
          locals { b2 } {
            b2 s p anyjump
            [ board side s 1 prim +
              b2 s p prim seq-int.empty 0 prim seq-int.push s prim seq-int.push best dfs
              scan ]
            [ board side s 1 prim + best scan ]
            if } ]
        [ board side s 1 prim + best scan ]
        if } ]
    if };

: stepd
  (forall ρ; ρ board:Seq Int s:Int p:Int d:Int -- ρ r:Int)
  locals { board s p d } {
    p d mayd
    [ s d nbr
      locals { t } {
        t 0 prim <
        [ 99 ]
        [ board t prim seq-int.at 0 prim = [ t ] [ 99 ] if ]
        if } ]
    [ 99 ]
    if };

: minstep
  (forall ρ; ρ board:Seq Int s:Int p:Int -- ρ r:Int)
  locals { board s p } {
    board s p 0 stepd board s p 1 stepd minint board s p 2 stepd minint board s p 3 stepd minint };

: findstep
  (forall ρ; ρ board:Seq Int side:Int s:Int -- ρ r:Int)
  locals { board side s } {
    s 32 prim >=
    [ -1 ]
    [ board s prim seq-int.at
      locals { p } {
        p 0 prim > p 1 prim - 2 prim div side prim = prim and
        [ board s p minstep
          locals { m } {
            m 99 prim <
            [ s 100 prim * m prim + ]
            [ board side s 1 prim + findstep ]
            if } ]
        [ board side s 1 prim + findstep ]
        if } ]
    if };

: replay
  (forall ρ; ρ board:Seq Int cur:Int best:Seq Int i:Int -- ρ b2:Seq Int c2:Int)
  locals { board cur best i } {
    i best 0 prim seq-int.at prim >=
    [ board cur ]
    [ best i 2 prim + prim seq-int.at
      locals { l } {
        board cur l midsq 0 prim seq-int.set l best i 1 prim + replay } ]
    if };

: game
  (forall ρ; ρ board:Seq Int turn:Int plies:Int st:Seq Int -- ρ b2:Seq Int st2:Seq Int result:Int)
  locals { board turn plies st } {
    board turn 0 prim seq-int.empty scan
    locals { best } {
      board turn 0 findstep
      locals { e } {
        best prim seq-int.len 0 prim > e 0 prim >= prim or
        [ st 0 prim seq-int.at plies prim >=
          [ board st 0 ]
          [ best prim seq-int.len 0 prim >
            [ best 1 prim seq-int.at
              locals { s0 } {
                board s0 prim seq-int.at
                locals { p } {
                  board s0 0 prim seq-int.set s0 best 0 replay
                  locals { b2 cur } {
                    p cur isfar [ 1 ] [ 0 ] if
                    locals { cf } {
                      b2 cur p cf prim + prim seq-int.set
                      st 1 turn prim + best 0 prim seq-int.at addto 3 cf addto 0 1 addto
                      locals { nb ns } { nb 1 turn prim - plies ns game } } } } } ]
            [ e 100 prim div
              locals { s0 } {
                e 100 prim mod
                locals { t } {
                  board s0 prim seq-int.at
                  locals { p } {
                    p t isfar [ 1 ] [ 0 ] if
                    locals { cf } {
                      board s0 0 prim seq-int.set t p cf prim + prim seq-int.set
                      st 3 cf addto 0 1 addto
                      locals { nb ns } { nb 1 turn prim - plies ns game } } } } } ]
            if ]
          if ]
        [ board st 2 turn prim - ]
        if } } };

: main
  (forall ρ; ρ board:Seq Int turn:Int plies:Int
   -- ρ board2:Seq Int played:Int white-took:Int black-took:Int crowned:Int result:Int)
  locals { board turn plies } {
    board turn plies
    prim seq-int.empty 0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    game
    locals { fb st r } {
      fb st 0 prim seq-int.at st 1 prim seq-int.at st 2 prim seq-int.at st 3 prim seq-int.at r } };
```

### task: regex
```firth
: zeros
  (forall ρ; ρ n:Int out:Seq Int -- ρ r:Seq Int)
  locals { n out } {
    n 0 prim <=
    [ out ]
    [ n 1 prim - out 0 prim seq-int.push zeros ]
    if };

: slice
  (forall ρ; ρ chars:Seq Int k:Int end:Int out:Seq Int -- ρ r:Seq Int)
  locals { chars k end out } {
    k end prim >=
    [ out ]
    [ chars k 1 prim + end out chars k prim seq-int.at prim seq-int.push slice ]
    if };

: unionl
  (forall ρ; ρ a:Seq Int b:Seq Int i:Int out:Seq Int -- ρ r:Seq Int)
  locals { a b i out } {
    i a prim seq-int.len prim >=
    [ out ]
    [ a b i 1 prim + out
      a i prim seq-int.at b i prim seq-int.at prim + 0 prim > [ 1 ] [ 0 ] if
      prim seq-int.push
      unionl ]
    if };

: union
  (forall ρ; ρ a:Seq Int b:Seq Int -- ρ r:Seq Int)
  locals { a b } { a b 0 prim seq-int.empty unionl };

: eqset
  (forall ρ; ρ a:Seq Int b:Seq Int i:Int -- ρ r:Bool)
  locals { a b i } {
    i a prim seq-int.len prim >=
    [ true ]
    [ a i prim seq-int.at b i prim seq-int.at prim =
      [ a b i 1 prim + eqset ]
      [ false ]
      if ]
    if };

: stepl
  (forall ρ; ρ s:Seq Int str:Seq Int c:Int j:Int out:Seq Int -- ρ r:Seq Int)
  locals { s str c j out } {
    j str prim seq-int.len prim >=
    [ out ]
    [ s str c j 1 prim + out
      s j prim seq-int.at 1 prim =
      c 26 prim = str j prim seq-int.at c prim = prim or prim and
      [ 1 ] [ 0 ] if
      prim seq-int.push stepl ]
    if };

: tokat
  (forall ρ; ρ pat:Seq Int i:Int -- ρ t:Int)
  locals { pat i } { i pat prim seq-int.len prim >= [ -1 ] [ pat i prim seq-int.at ] if };

: skipto
  (forall ρ; ρ pat:Seq Int i:Int d:Int -- ρ r:Int)
  locals { pat i d } {
    pat i tokat
    locals { t } {
      t 0 prim <
      [ i ]
      [ t 31 prim =
        [ pat i 1 prim + d 1 prim + skipto ]
        [ t 32 prim =
          [ d 1 prim = [ i 1 prim + ] [ pat i 1 prim + d 1 prim - skipto ] if ]
          [ pat i 1 prim + d skipto ]
          if ]
        if ]
      if } };

: skipatom
  (forall ρ; ρ pat:Seq Int i:Int -- ρ e:Int)
  locals { pat i } {
    pat i tokat 31 prim =
    [ pat i 1 prim + 1 skipto ]
    [ i 1 prim + ]
    if };

: opsend
  (forall ρ; ρ pat:Seq Int k:Int -- ρ r:Int)
  locals { pat k } {
    pat k tokat
    locals { t } {
      t 27 prim >= t 29 prim <= prim and
      [ pat k 1 prim + opsend ]
      [ k ]
      if } };

: lastone
  (forall ρ; ρ e:Seq Int k:Int -- ρ r:Int)
  locals { e k } {
    k 0 prim <
    [ -1 ]
    [ e k prim seq-int.at 1 prim = [ k ] [ e k 1 prim - lastone ] if ]
    if };

: valid
  (forall ρ; ρ pat:Seq Int i:Int d:Int ie:Int -- ρ r:Bool)
  locals { pat i d ie } {
    i pat prim seq-int.len prim >=
    [ d 0 prim = ]
    [ pat i prim seq-int.at
      locals { t } {
        t 26 prim <=
        [ pat i 1 prim + d 1 valid ]
        [ t 29 prim <=
          [ ie 1 prim =
            [ pat i 1 prim + d 1 valid ]
            [ false ]
            if ]
          [ t 30 prim =
            [ pat i 1 prim + d 0 valid ]
            [ t 31 prim =
              [ pat i 1 prim + d 1 prim + 0 valid ]
              [ d 0 prim >
                [ pat i 1 prim + d 1 prim - 1 valid ]
                [ false ]
                if ]
              if ]
            if ]
          if ]
        if } ]
    if };

: atomset
  (forall ρ; ρ pat:Seq Int str:Seq Int a:Int tt:Seq Int -- ρ r:Seq Int)
  locals { pat str a tt } {
    pat a tokat
    locals { t } {
      t 31 prim =
      [ pat str a 1 prim + tt alt swap drop ]
      [ tt str t 0 { 0 } stepl ]
      if } };

: gset
  (forall ρ; ρ pat:Seq Int str:Seq Int a:Int e:Int k:Int tt:Seq Int -- ρ r:Seq Int)
  locals { pat str a e k tt } {
    k e prim =
    [ pat str a tt atomset ]
    [ k 1 prim -
      locals { k1 } {
        pat k1 tokat
        locals { op } {
          op 29 prim =
          [ tt pat str a e k1 tt gset union ]
          [ op 27 prim =
            [ pat str a e k1 tt closure ]
            [ pat str a e k1 tt gset
              locals { u0 } { pat str a e k1 u0 closure } ]
            if ]
          if } } ]
    if };

: closure
  (forall ρ; ρ pat:Seq Int str:Seq Int a:Int e:Int k:Int u:Seq Int -- ρ r:Seq Int)
  locals { pat str a e k u } {
    u pat str a e k u gset union
    locals { v } {
      v u 0 eqset
      [ u ]
      [ pat str a e k v closure ]
      if } };

: item
  (forall ρ; ρ pat:Seq Int str:Seq Int i:Int s:Seq Int -- ρ i2:Int s2:Seq Int)
  locals { pat str i s } {
    pat i skipatom
    locals { e } {
      pat e opsend
      locals { k } {
        k pat str i e k s gset } } };

: seql
  (forall ρ; ρ pat:Seq Int str:Seq Int i:Int s:Seq Int -- ρ i2:Int s2:Seq Int)
  locals { pat str i s } {
    pat i tokat
    locals { t } {
      t 0 prim < t 30 prim = prim or t 32 prim = prim or
      [ i s ]
      [ pat str i s item
        locals { j s2 } { pat str j s2 seql } ]
      if } };

: altl
  (forall ρ; ρ pat:Seq Int str:Seq Int i:Int s:Seq Int acc:Seq Int -- ρ i2:Int s2:Seq Int)
  locals { pat str i s acc } {
    pat str i s seql
    locals { j s2 } {
      acc s2 union
      locals { acc2 } {
        pat j tokat 30 prim =
        [ pat str j 1 prim + s acc2 altl ]
        [ j acc2 ]
        if } } };

: alt
  (forall ρ; ρ pat:Seq Int str:Seq Int i:Int s:Seq Int -- ρ i2:Int s2:Seq Int)
  locals { pat str i s } {
    pat str i s str prim seq-int.len 1 prim + prim seq-int.empty zeros altl };

: strs
  (forall ρ; ρ pat:Seq Int lens:Seq Int chars:Seq Int j:Int base:Int full:Seq Bool longest:Seq Int count:Int ok:Bool
   -- ρ full2:Seq Bool longest2:Seq Int count2:Int)
  locals { pat lens chars j base full longest count ok } {
    j lens prim seq-int.len prim >=
    [ full longest count ]
    [ lens j prim seq-int.at
      locals { n } {
        ok
        [ chars base base n prim + prim seq-int.empty slice
          locals { str } {
            pat str 0 n { 1 } zeros alt swap drop
            locals { e } {
              full e n prim seq-int.at 1 prim = prim seq-bool.push
              longest e n lastone prim seq-int.push
              count e n prim seq-int.at prim + } } ]
        [ full false prim seq-bool.push longest -1 prim seq-int.push count ]
        if
        locals { f l c } { pat lens chars j 1 prim + base n prim + f l c ok strs } } ]
    if };

: main
  (forall ρ; ρ pat:Seq Int lens:Seq Int chars:Seq Int
   -- ρ full:Seq Bool longest:Seq Int count:Int valid:Bool)
  locals { pat lens chars } {
    pat 0 0 0 valid
    locals { ok } {
      pat lens chars 0 0 prim seq-bool.empty prim seq-int.empty 0 ok strs
      ok } };
```

### task: swiss
```firth
: zeros
  (forall ρ; ρ n:Int out:Seq Int -- ρ r:Seq Int)
  locals { n out } {
    n 0 prim <=
    [ out ]
    [ n 1 prim - out 0 prim seq-int.push zeros ]
    if };

: slice
  (forall ρ; ρ chars:Seq Int k:Int end:Int out:Seq Int -- ρ r:Seq Int)
  locals { chars k end out } {
    k end prim >=
    [ out ]
    [ chars k 1 prim + end out chars k prim seq-int.at prim seq-int.push slice ]
    if };

: wget
  (forall ρ; ρ w:Seq Int i:Int -- ρ v:Int)
  prim seq-int.at;

: adj
  (forall ρ; ρ s:Seq Int i:Int k:Int -- ρ r:Seq Int)
  locals { s i k } { s i s i prim seq-int.at k prim + prim seq-int.set };

: mkkeys
  (forall ρ; ρ rat:Seq Int n:Int s:Seq Int bh:Seq Int i:Int out:Seq Int -- ρ r:Seq Int)
  locals { rat n s bh i out } {
    i n prim >=
    [ out ]
    [ rat n s bh i 1 prim + out
      s i prim seq-int.at 256 prim * bh i prim seq-int.at prim + 4096 prim *
      rat i prim seq-int.at prim + 16 prim * 15 i prim - prim +
      prim seq-int.push mkkeys ]
    if };

: argmax
  (forall ρ; ρ keys:Seq Int i:Int best:Int bi:Int -- ρ r:Int)
  locals { keys i best bi } {
    i keys prim seq-int.len prim >=
    [ bi ]
    [ keys i prim seq-int.at best prim >
      [ keys i 1 prim + keys i prim seq-int.at i argmax ]
      [ keys i 1 prim + best bi argmax ]
      if ]
    if };

: sortdesc
  (forall ρ; ρ keys:Seq Int out:Seq Int -- ρ r:Seq Int)
  locals { keys out } {
    out prim seq-int.len keys prim seq-int.len prim >=
    [ out ]
    [ keys 0 -1 -1 argmax
      locals { m } {
        keys m -1 prim seq-int.set out m prim seq-int.push sortdesc } ]
    if };

: findbye
  (forall ρ; ρ s:Seq Int order:Seq Int k:Int -- ρ p:Int)
  locals { s order k } {
    order k prim seq-int.at
    locals { p } {
      s 36 p prim + prim seq-int.at 0 prim =
      [ p ]
      [ s order k 1 prim - findbye ]
      if } };

: findq
  (forall ρ; ρ order:Seq Int paired:Seq Int s:Seq Int p:Int j:Int st:Int -- ρ q:Int)
  locals { order paired s p j st } {
    j order prim seq-int.len prim >=
    [ -1 ]
    [ order j prim seq-int.at
      locals { q } {
        paired q prim seq-int.at 0 prim =
        st 0 prim = s 64 p 12 prim * prim + q prim + prim seq-int.at 0 prim = prim or
        prim and
        [ q ]
        [ order paired s p j 1 prim + st findq ]
        if } ]
    if };

: finish
  (forall ρ; ρ s:Seq Int w:Int b:Int r:Int -- ρ s2:Seq Int)
  locals { s w b r } {
    s 12 w prim + 1 adj
    24 w prim + 1 prim seq-int.set
    24 b prim + 2 prim seq-int.set
    64 w 12 prim * prim + b prim + 1 adj
    64 b 12 prim * prim + w prim + 1 adj
    locals { s2 } {
      r 0 prim =
      [ s2 w 2 adj ]
      [ r 1 prim =
        [ s2 w 1 adj b 1 adj ]
        [ s2 b 2 adj ]
        if ]
      if } };

: playgame
  (forall ρ; ρ s:Seq Int p:Int q:Int r:Int -- ρ s2:Seq Int)
  locals { s p q r } {
    s 64 p 12 prim * prim + q prim + prim seq-int.at 0 prim >
    [ s 48 1 adj ]
    [ s ]
    if
    locals { s1 } {
      s1 12 p prim + prim seq-int.at
      s1 12 q prim + prim seq-int.at
      locals { wp wq } {
        s1 24 p prim + prim seq-int.at 2 prim =
        s1 24 q prim + prim seq-int.at 2 prim =
        locals { lp lq } {
          wp wq prim < wp wq prim = lq lp prim not prim and prim not prim and prim or
          [ p q ]
          [ q p ]
          if
          locals { wh bl } { s1 wh bl r finish } } } } };

: pairs
  (forall ρ; ρ order:Seq Int n:Int i:Int paired:Seq Int s:Seq Int res:Seq Int -- ρ r:Seq Int)
  locals { order n i paired s res } {
    i n prim >=
    [ s ]
    [ order i prim seq-int.at
      locals { p } {
        paired p prim seq-int.at 0 prim =
        [ order paired s p i 1 prim + 1 findq
          locals { q0 } {
            q0 0 prim <
            [ order paired s p i 1 prim + 0 findq ]
            [ q0 ]
            if
            locals { q } {
              res s 49 prim seq-int.at prim seq-int.at
              locals { r } {
                s 49 1 adj p q r playgame
                locals { s3 } {
                  order n i 1 prim + paired p 1 prim seq-int.set q 1 prim seq-int.set s3 res pairs } } } } ]
        [ order n i 1 prim + paired s res pairs ]
        if } ]
    if };

: playround
  (forall ρ; ρ rat:Seq Int n:Int s:Seq Int res:Seq Int -- ρ r:Seq Int)
  locals { rat n s res } {
    rat n s n prim seq-int.empty zeros 0 prim seq-int.empty mkkeys prim seq-int.empty sortdesc
    locals { order } {
      n 2 prim mod 1 prim =
      [ s order n 1 prim - findbye
        locals { bp } {
          12 prim seq-int.empty zeros bp 1 prim seq-int.set
          s 36 bp prim + 1 prim seq-int.set bp 2 adj } ]
      [ 12 prim seq-int.empty zeros s ]
      if
      locals { pd s2 } { order n 0 pd s2 res pairs } } };

: rl
  (forall ρ; ρ rat:Seq Int n:Int s:Seq Int res:Seq Int r:Int rr:Int -- ρ out:Seq Int)
  locals { rat n s res r rr } {
    r rr prim >=
    [ s ]
    [ rat n rat n s res playround res r 1 prim + rr rl ]
    if };

: bsum
  (forall ρ; ρ s:Seq Int p:Int q:Int n:Int acc:Int -- ρ r:Int)
  locals { s p q n acc } {
    q n prim >=
    [ acc ]
    [ s p q 1 prim + n
      acc s 64 p 12 prim * prim + q prim + prim seq-int.at s q prim seq-int.at prim * prim +
      bsum ]
    if };

: bh
  (forall ρ; ρ s:Seq Int n:Int p:Int out:Seq Int -- ρ r:Seq Int)
  locals { s n p out } {
    p n prim >=
    [ out ]
    [ s n p 1 prim + out s p 0 n 0 bsum prim seq-int.push bh ]
    if };

: main
  (forall ρ; ρ ratings:Seq Int rounds:Int results:Seq Int
   -- ρ scores:Seq Int buchholz:Seq Int ranking:Seq Int whites:Seq Int rematches:Int)
  locals { ratings rounds results } {
    ratings prim seq-int.len
    locals { n } {
      ratings n 208 prim seq-int.empty zeros results 0 rounds rl
      locals { s } {
        s n 0 prim seq-int.empty bh
        locals { bhs } {
          s 0 n prim seq-int.empty slice
          bhs
          ratings n s bhs 0 prim seq-int.empty mkkeys prim seq-int.empty sortdesc
          s 12 12 n prim + prim seq-int.empty slice
          s 48 prim seq-int.at } } } };
```

### task: warehouse
```firth
: zeros
  (forall ρ; ρ n:Int out:Seq Int -- ρ r:Seq Int)
  locals { n out } {
    n 0 prim <=
    [ out ]
    [ n 1 prim - out 0 prim seq-int.push zeros ]
    if };

: slice
  (forall ρ; ρ chars:Seq Int k:Int end:Int out:Seq Int -- ρ r:Seq Int)
  locals { chars k end out } {
    k end prim >=
    [ out ]
    [ chars k 1 prim + end out chars k prim seq-int.at prim seq-int.push slice ]
    if };

: wget
  (forall ρ; ρ w:Seq Int i:Int -- ρ v:Int)
  prim seq-int.at;

: wset
  (forall ρ; ρ w:Seq Int i:Int v:Int -- ρ r:Seq Int)
  prim seq-int.set;

: wadd
  (forall ρ; ρ w:Seq Int i:Int k:Int -- ρ r:Seq Int)
  locals { w i k } { w i w i prim seq-int.at k prim + prim seq-int.set };

: lqi
  (forall ρ; ρ p:Int i:Int -- ρ x:Int)
  locals { p i } { 500 p 150 prim * prim + i prim + };

: lei
  (forall ρ; ρ p:Int i:Int -- ρ x:Int)
  locals { p i } { 1250 p 150 prim * prim + i prim + };

: qbi
  (forall ρ; ρ p:Int i:Int -- ρ x:Int)
  locals { p i } { 2000 p 82 prim * prim + i prim + };

: dbi
  (forall ρ; ρ p:Int i:Int -- ρ x:Int)
  locals { p i } { 2410 p 82 prim * prim + i prim + };

: copyin
  (forall ρ; ρ w:Seq Int src:Seq Int dst:Int j:Int -- ρ r:Seq Int)
  locals { w src dst j } {
    j src prim seq-int.len prim >=
    [ w ]
    [ w dst j prim + src j prim seq-int.at prim seq-int.set src dst j 1 prim + copyin ]
    if };

: take
  (forall ρ; ρ w:Seq Int p:Int q:Int acc:Int -- ρ r:Seq Int t:Int)
  locals { w p q acc } {
    q 0 prim <= w p wget w 5 p prim + wget prim >= prim or
    [ w acc ]
    [ w p wget
      locals { h } {
        w p h lqi wget
        locals { l } {
          l q prim < [ l ] [ q ] if
          locals { m } {
            w p h lqi 0 m prim - wadd
            l m prim = [ p 1 wadd ] [ ] if
            10 p prim + 0 m prim - wadd
            31 m wadd
            30 m w 40 p prim + wget prim * wadd
            p q m prim - acc m prim + take } } } ]
    if };

: shift
  (forall ρ; ρ w:Seq Int p:Int i:Int qty:Int ex:Int -- ρ r:Seq Int)
  locals { w p i qty ex } {
    i w p wget prim >
    w p i 1 prim - lei wget ex prim > prim and
    [ w p i lqi w p i 1 prim - lqi wget wset
      p i lei w p i 1 prim - lei wget wset
      p i 1 prim - qty ex shift ]
    [ w p i lqi qty wset p i lei ex wset ]
    if };

: fillbo
  (forall ρ; ρ w:Seq Int p:Int -- ρ r:Seq Int)
  locals { w p } {
    w 20 p prim + wget w 25 p prim + wget prim <
    w 10 p prim + wget 0 prim > prim and
    [ w p w 20 p prim + wget qbi wget
      locals { b } {
        w p b 0 take
        locals { w2 t } {
          w2 35 0 t prim - wadd
          t b prim =
          [ 20 p prim + 1 wadd ]
          [ p w2 20 p prim + wget qbi 0 t prim - wadd ]
          if
          p fillbo } } ]
    [ w ]
    if };

: arrive
  (forall ρ; ρ w:Seq Int p:Int qty:Int ex:Int -- ρ r:Seq Int)
  locals { w p qty ex } {
    w p w 5 p prim + wget qty ex shift
    5 p prim + 1 wadd
    10 p prim + qty wadd
    p fillbo };

: addbo
  (forall ρ; ρ w:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { w p q d } {
    w p w 25 p prim + wget qbi q wset
    p w 25 p prim + wget dbi d wset
    35 q wadd
    25 p prim + 1 wadd };

: order
  (forall ρ; ρ w:Seq Int p:Int q:Int d:Int -- ρ r:Seq Int)
  locals { w p q d } {
    w 20 p prim + wget w 25 p prim + wget prim <
    [ w p q d addbo ]
    [ w p q 0 take
      locals { w2 t } {
        t q prim <
        [ w2 p q t prim - d addbo ]
        [ w2 ]
        if } ]
    if };

: events
  (forall ρ; ρ w:Seq Int d:Int -- ρ r:Seq Int)
  locals { w d } {
    w 37 wget
    locals { ei } {
      ei w 38 wget prim <
      w 100 ei prim + wget d prim = prim and
      [ w 260 ei prim + wget
        locals { p } {
          w 340 ei prim + wget
          locals { q } {
            w 180 ei prim + wget 1 prim =
            [ w p q w 420 ei prim + wget arrive ]
            [ w p q d order ]
            if
            37 1 wadd d events } } ]
      [ w ]
      if } };

: discard1
  (forall ρ; ρ w:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { w p d } {
    w p wget w 5 p prim + wget prim <
    w p w p wget lei wget d prim < prim and
    [ w p w p wget lqi wget
      locals { q } {
        w 32 q wadd
        10 p prim + 0 q prim - wadd
        p 1 wadd
        p d discard1 } ]
    [ w ]
    if };

: supply1
  (forall ρ; ρ w:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { w p d } {
    w 15 p prim + wget d prim =
    [ w p w 50 p prim + wget d w 60 p prim + wget prim + arrive
      15 p prim + -1 wset ]
    [ w ]
    if };

: cancelp
  (forall ρ; ρ w:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { w p d } {
    w 20 p prim + wget w 25 p prim + wget prim <
    w p w 20 p prim + wget dbi wget d 7 prim - prim <= prim and
    [ w p w 20 p prim + wget qbi wget
      locals { a } {
        w 33 a wadd
        35 0 a prim - wadd
        20 p prim + 1 wadd
        p d cancelp } ]
    [ w ]
    if };

: reorder1
  (forall ρ; ρ w:Seq Int p:Int d:Int -- ρ r:Seq Int)
  locals { w p d } {
    w 15 p prim + wget 0 prim <
    w 10 p prim + wget w 45 p prim + wget prim <= prim and
    [ w 15 p prim + d w 55 p prim + wget prim + wset 34 1 wadd ]
    [ w ]
    if };

: forp
  (forall ρ; ρ w:Seq Int d:Int p:Int np:Int ph:Int -- ρ r:Seq Int)
  locals { w d p np ph } {
    p np prim >=
    [ w ]
    [ w
      ph 0 prim =
      [ p d discard1 ]
      [ ph 1 prim =
        [ p d supply1 ]
        [ ph 2 prim =
          [ p d cancelp ]
          [ p d reorder1 ]
          if ]
        if ]
      if
      d p 1 prim + np ph forp ]
    if };

: dayloop
  (forall ρ; ρ w:Seq Int d:Int days:Int -- ρ r:Seq Int)
  locals { w d days } {
    d days prim >=
    [ w ]
    [ w 36 wget
      locals { np } {
        w d 0 np 0 forp
        d 0 np 1 forp
        d events
        d 0 np 2 forp
        d 0 np 3 forp
        d 1 prim + days dayloop } ]
    if };

: main
  (forall ρ; ρ days:Int price:Seq Int rp:Seq Int rq:Seq Int lead:Seq Int shelf:Seq Int
   ev-day:Seq Int ev-kind:Seq Int ev-prod:Seq Int ev-qty:Seq Int ev-expiry:Seq Int
   -- ρ stock:Seq Int earned:Int shipped:Int discarded:Int cancelled:Int supplies:Int owed:Int)
  locals { days price rp rq lead shelf ev-day ev-kind ev-prod ev-qty ev-expiry } {
    2820 prim seq-int.empty zeros
    price 40 0 copyin
    rp 45 0 copyin
    rq 50 0 copyin
    lead 55 0 copyin
    shelf 60 0 copyin
    ev-day 100 0 copyin
    ev-kind 180 0 copyin
    ev-prod 260 0 copyin
    ev-qty 340 0 copyin
    ev-expiry 420 0 copyin
    36 price prim seq-int.len wset
    38 ev-day prim seq-int.len wset
    15 -1 wset 16 -1 wset 17 -1 wset 18 -1 wset 19 -1 wset
    0 days dayloop
    locals { w } {
      w 10 10 w 36 wget prim + prim seq-int.empty slice
      w 30 wget w 31 wget w 32 wget w 33 wget w 34 wget w 35 wget } };
```

### task: cache-sim
```firth
: zeros
  (forall ρ; ρ n:Int out:Seq Int -- ρ r:Seq Int)
  locals { n out } {
    n 0 prim <=
    [ out ]
    [ n 1 prim - out 0 prim seq-int.push zeros ]
    if };

: wget
  (forall ρ; ρ w:Seq Int i:Int -- ρ v:Int)
  prim seq-int.at;

: wset
  (forall ρ; ρ w:Seq Int i:Int v:Int -- ρ r:Seq Int)
  prim seq-int.set;

: wadd
  (forall ρ; ρ w:Seq Int i:Int k:Int -- ρ r:Seq Int)
  locals { w i k } { w i w i prim seq-int.at k prim + prim seq-int.set };

: bb
  (forall ρ; ρ lvl:Int -- ρ r:Int)
  1 prim = [ 0 ] [ 70 ] if;

: db
  (forall ρ; ρ lvl:Int -- ρ r:Int)
  1 prim = [ 32 ] [ 134 ] if;

: cb
  (forall ρ; ρ lvl:Int -- ρ r:Int)
  1 prim = [ 64 ] [ 198 ] if;

: ways
  (forall ρ; ρ w:Seq Int lvl:Int -- ρ r:Int)
  locals { w lvl } { lvl 1 prim = [ w 217 wget ] [ w 219 wget ] if };

: nsets
  (forall ρ; ρ w:Seq Int lvl:Int -- ρ r:Int)
  locals { w lvl } { lvl 1 prim = [ w 216 wget ] [ w 218 wget ] if };

: bslot
  (forall ρ; ρ lvl:Int set:Int k:Int -- ρ r:Int)
  locals { lvl set k } { lvl bb set 8 prim * prim + k prim + };

: dslot
  (forall ρ; ρ lvl:Int set:Int k:Int -- ρ r:Int)
  locals { lvl set k } { lvl db set 8 prim * prim + k prim + };

: cslot
  (forall ρ; ρ lvl:Int set:Int -- ρ r:Int)
  locals { lvl set } { lvl cb set prim + };

: find
  (forall ρ; ρ w:Seq Int lvl:Int set:Int a:Int k:Int -- ρ r:Int)
  locals { w lvl set a k } {
    k w lvl set cslot wget prim >=
    [ -1 ]
    [ w lvl set k bslot wget a prim =
      [ k ]
      [ w lvl set a k 1 prim + find ]
      if ]
    if };

: shl
  (forall ρ; ρ w:Seq Int lvl:Int set:Int i:Int -- ρ r:Seq Int)
  locals { w lvl set i } {
    i 1 prim + w lvl set cslot wget prim >=
    [ w lvl set cslot -1 wadd ]
    [ w lvl set i bslot w lvl set i 1 prim + bslot wget wset
      lvl set i dslot w lvl set i 1 prim + dslot wget wset
      lvl set i 1 prim + shl ]
    if };

: appnd
  (forall ρ; ρ w:Seq Int lvl:Int set:Int b:Int d:Int -- ρ r:Seq Int)
  locals { w lvl set b d } {
    w lvl set cslot wget
    locals { c } {
      w lvl set c bslot b wset
      lvl set c dslot d wset
      lvl set cslot 1 wadd } };

: hitu
  (forall ρ; ρ w:Seq Int lvl:Int set:Int k:Int mark:Int -- ρ r:Seq Int)
  locals { w lvl set k mark } {
    w lvl set k bslot wget
    locals { b } {
      w lvl set k dslot wget mark prim + 0 prim > [ 1 ] [ 0 ] if
      locals { d } {
        w lvl set k shl lvl set b d appnd } } };

: putc
  (forall ρ; ρ w:Seq Int lvl:Int a:Int d:Int -- ρ r:Seq Int evb:Int evd:Int)
  locals { w lvl a d } {
    a w lvl nsets prim mod
    locals { set } {
      w lvl set cslot wget w lvl ways prim >=
      [ w lvl set 0 bslot wget
        locals { eb } {
          w lvl set 0 dslot wget
          locals { ed } {
            w lvl set 0 shl lvl set a d appnd eb ed } } ]
      [ w lvl set a d appnd -1 0 ]
      if } };

: wback
  (forall ρ; ρ w:Seq Int b:Int -- ρ r:Seq Int)
  locals { w b } {
    b w 2 nsets prim mod
    locals { s2 } {
      w 2 s2 b 0 find
      locals { k } {
        k 0 prim >=
        [ w 2 s2 k 1 hitu ]
        [ w 2 b 1 putc
          locals { w2 eb ed } {
            ed 1 prim =
            [ w2 215 1 wadd ]
            [ w2 ]
            if } ]
        if } } };

: l2part
  (forall ρ; ρ w:Seq Int a:Int -- ρ r:Seq Int)
  locals { w a } {
    a w 2 nsets prim mod
    locals { s2 } {
      w 2 s2 a 0 find
      locals { k } {
        k 0 prim >=
        [ w 212 1 wadd 2 s2 k 0 hitu ]
        [ w 213 1 wadd 214 1 wadd 2 a 0 putc
          locals { w2 eb ed } {
            ed 1 prim =
            [ w2 215 1 wadd ]
            [ w2 ]
            if } ]
        if } } };

: access
  (forall ρ; ρ w:Seq Int a:Int wr:Int -- ρ r:Seq Int)
  locals { w a wr } {
    a w 1 nsets prim mod
    locals { s1 } {
      w 1 s1 a 0 find
      locals { k } {
        k 0 prim >=
        [ w 210 1 wadd 1 s1 k wr hitu ]
        [ w 211 1 wadd a l2part 1 a wr putc
          locals { w2 eb ed } {
            ed 1 prim =
            [ w2 eb wback ]
            [ w2 ]
            if } ]
        if } } };

: sim
  (forall ρ; ρ w:Seq Int addrs:Seq Int writes:Seq Bool i:Int -- ρ r:Seq Int)
  locals { w addrs writes i } {
    i addrs prim seq-int.len prim >=
    [ w ]
    [ w addrs i prim seq-int.at writes i prim seq-bool.at [ 1 ] [ 0 ] if access
      addrs writes i 1 prim + sim ]
    if };

: dcount
  (forall ρ; ρ w:Seq Int lvl:Int set:Int k:Int acc:Int -- ρ r:Int)
  locals { w lvl set k acc } {
    set w lvl nsets prim >=
    [ acc ]
    [ k w lvl set cslot wget prim >=
      [ w lvl set 1 prim + 0 acc dcount ]
      [ w lvl set k 1 prim + acc w lvl set k dslot wget prim + dcount ]
      if ]
    if };

: blist
  (forall ρ; ρ w:Seq Int set:Int k:Int out:Seq Int -- ρ r:Seq Int)
  locals { w set k out } {
    set w 1 nsets prim >=
    [ out ]
    [ k w 1 set cslot wget prim >=
      [ w set 1 prim + 0 out blist ]
      [ w set k 1 prim + out w 1 set k bslot wget prim seq-int.push blist ]
      if ]
    if };

: main
  (forall ρ; ρ s1:Int w1:Int s2:Int w2:Int addrs:Seq Int writes:Seq Bool
   -- ρ l1-hits:Int l1-misses:Int l2-hits:Int l2-misses:Int mem-reads:Int mem-writes:Int dirty:Int l1-blocks:Seq Int)
  locals { s1 w1 s2 w2 addrs writes } {
    220 prim seq-int.empty zeros
    216 s1 wset 217 w1 wset 218 s2 wset 219 w2 wset
    addrs writes 0 sim
    locals { f } {
      f 210 wget f 211 wget f 212 wget f 213 wget f 214 wget f 215 wget
      f 1 0 0 0 dcount f 2 0 0 0 dcount prim +
      f 0 0 prim seq-int.empty blist } };
```

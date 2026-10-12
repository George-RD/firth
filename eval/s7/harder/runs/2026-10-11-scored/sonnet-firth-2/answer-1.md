### task: sokoban
```firth
: sg (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many) prim seq-int.at;
: sp (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: inc (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m i d } { m i m i sg d prim + sp };
: bump (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } { m i 1 inc };
: zeros (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { n 0 prim <= [ s ] [ s 0 prim seq-int.push n 1 prim - zeros ] if };

: delta (forall ρ; ρ w:Int^many d:Int^many -- ρ r:Int^many)
  locals { w d } { d 2 prim mod 1 prim = [ 2 d prim - ] [ d 1 prim - w prim * ] if };

: findbox (forall ρ; ρ m:Seq Int^many t:Int^many k:Int^many -- ρ r:Int^many)
  locals { m t k } {
    k m 8 sg prim >=
    [ -1 ]
    [ m 9 k prim + sg t prim = [ k ] [ m t k 1 prim + findbox ] if ]
    if };

: record (forall ρ; ρ m:Seq Int^many e:Int^many -- ρ r:Seq Int^many)
  locals { m e } { m 15 m 2 sg prim + e sp 2 bump };

: deadq (forall ρ; ρ cells:Seq Int^many w:Int^many u:Int^many -- ρ r:Bool^many)
  locals { cells w u } {
    cells u sg 2 prim =
    [ false ]
    [ cells u w prim - sg 1 prim = cells u w prim + sg 1 prim = prim or
      cells u 1 prim - sg 1 prim = cells u 1 prim + sg 1 prim = prim or
      prim and ]
    if };

: allgoal (forall ρ; ρ cells:Seq Int^many m:Seq Int^many k:Int^many -- ρ r:Bool^many)
  locals { cells m k } {
    k m 8 sg prim >=
    [ true ]
    [ cells m 9 k prim + sg sg 2 prim =
      [ cells m k 1 prim + allgoal ]
      [ false ]
      if ]
    if };

: solved (forall ρ; ρ cells:Seq Int^many m:Seq Int^many -- ρ r:Bool^many)
  locals { cells m } { cells m 0 allgoal };

: collect (forall ρ; ρ m:Seq Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m k acc } {
    k m 8 sg prim >=
    [ acc ]
    [ m k 1 prim + acc m 9 k prim + sg prim seq-int.push collect ]
    if };

: loadboxes (forall ρ; ρ m:Seq Int^many boxes:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m boxes k } {
    k boxes prim seq-int.len prim >=
    [ m ]
    [ m 9 k prim + boxes k prim seq-int.at sp boxes k 1 prim + loadboxes ]
    if };

: domove (forall ρ; ρ cells:Seq Int^many m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { cells m d } {
    m 0 sg m 7 sg d delta
    locals { p dl } {
      p dl prim +
      locals { t } {
        cells t sg 1 prim =
        [ m 4 bump ]
        [ m t 0 findbox
          locals { k } {
            k 0 prim <
            [ m 0 t sp d 8 prim * record ]
            [ t dl prim +
              locals { u } {
                cells u sg 1 prim = m u 0 findbox 0 prim >= prim or
                [ m 4 bump ]
                [ m 9 k prim + u sp 0 t sp
                  d 8 prim * k prim + 1 prim + record
                  3 bump
                  locals { m3 } {
                    cells m3 7 sg u deadq
                    [ m3 6 bump ] [ m3 ] if } ]
                if } ]
            if } ]
        if } } };

: undo (forall ρ; ρ cells:Seq Int^many m:Seq Int^many -- ρ r:Seq Int^many)
  locals { cells m } {
    m 2 sg 0 prim =
    [ m ]
    [ m 14 m 2 sg prim + sg
      locals { e } {
        m 7 sg e 8 prim div delta
        locals { dl } {
          m 0 m 0 sg dl prim - sp
          locals { m1 } {
            e 8 prim mod 0 prim >
            [ m1 8 e 8 prim mod prim + m1 8 e 8 prim mod prim + sg dl prim - sp ]
            [ m1 ]
            if
            locals { m2 } { m2 2 m2 2 sg 1 prim - sp 5 bump } } } } ]
    if };

: play (forall ρ; ρ cells:Seq Int^many moves:Seq Int^many m:Seq Int^many -- ρ r:Seq Int^many)
  locals { cells moves m } {
    m 1 sg moves prim seq-int.len prim >=
    cells m solved
    prim or
    [ m ]
    [ moves m 1 sg prim seq-int.at
      locals { mv } {
        cells moves
        mv 4 prim =
        [ cells m 1 bump undo ]
        [ cells m 1 bump mv domove ]
        if
        play } ]
    if };

: main
  (forall ρ; ρ w:Int^many h:Int^many cells:Seq Int^many player:Int^many boxes:Seq Int^many moves:Seq Int^many -- ρ player:Int^many boxes:Seq Int^many read:Int^many history:Int^many pushes:Int^many blocked:Int^many undos:Int^many dead:Int^many solved:Bool^many)
  locals { w h cells player boxes moves } {
    prim seq-int.empty 215 zeros
    0 player sp
    7 w sp
    8 boxes prim seq-int.len sp
    boxes 0 loadboxes
    locals { m } {
      cells moves m play
      locals { f } {
        f 0 sg
        f 0 prim seq-int.empty collect
        f 1 sg f 2 sg f 3 sg f 4 sg f 5 sg f 6 sg
        cells f solved } } };
```

### task: checkers
```firth
: sg (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many) prim seq-int.at;
: sp (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: zeros (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { n 0 prim <= [ s ] [ s 0 prim seq-int.push n 1 prim - zeros ] if };

: nbcalc (forall ρ; ρ i:Int^many d:Int^many -- ρ r:Int^many)
  locals { i d } {
    i 4 prim div
    locals { r } {
      i 4 prim mod 2 prim * 1 r 2 prim mod prim - prim +
      locals { c } {
        r d 2 prim < [ -1 ] [ 1 ] if prim +
        c d 2 prim mod 0 prim = [ -1 ] [ 1 ] if prim +
        locals { nr nc } {
          nr 0 prim < nr 7 prim > prim or
          nc 0 prim < nc 7 prim > prim or
          prim or
          [ -1 ]
          [ nr 4 prim * nc 2 prim div prim + ]
          if } } } };

: buildnbr (forall ρ; ρ acc:Seq Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { acc k } {
    k 128 prim >=
    [ acc ]
    [ acc k 4 prim div k 4 prim mod nbcalc prim seq-int.push k 1 prim + buildnbr ]
    if };

: canmove (forall ρ; ρ piece:Int^many d:Int^many -- ρ r:Bool^many)
  locals { piece d } {
    piece 1 prim = [ d 2 prim < ]
    [ piece 3 prim = [ d 2 prim >= ] [ true ] if ] if };

: crowns (forall ρ; ρ piece:Int^many l:Int^many -- ρ r:Bool^many)
  locals { piece l } {
    piece 1 prim = [ l 4 prim < ]
    [ piece 3 prim = [ l 28 prim >= ] [ false ] if ] if };

: isenemy (forall ρ; ρ v:Int^many piece:Int^many -- ρ r:Bool^many)
  locals { v piece } {
    piece 2 prim <= [ v 3 prim >= ] [ v 1 prim >= v 2 prim <= prim and ] if };

: owns (forall ρ; ρ v:Int^many side:Int^many -- ρ r:Bool^many)
  locals { v side } {
    side 0 prim = [ v 1 prim >= v 2 prim <= prim and ] [ v 3 prim >= ] if };

: cand (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many d:Int^many -- ρ r:Int^many)
  locals { nbr b piece s d } {
    piece d canmove
    [ nbr s 4 prim * d prim + sg
      locals { over } {
        over 0 prim <
        [ -1 ]
        [ b over sg piece isenemy
          [ nbr over 4 prim * d prim + sg
            locals { land } {
              land 0 prim <
              [ -1 ]
              [ b land sg 0 prim = [ land ] [ -1 ] if ]
              if } ]
          [ -1 ]
          if ]
        if } ]
    [ -1 ]
    if };

: nextl (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many prev:Int^many d:Int^many bd:Int^many bl:Int^many -- ρ r:Int^many)
  locals { nbr b piece s prev d bd bl } {
    d 4 prim >=
    [ bd ]
    [ nbr b piece s d cand
      locals { l } {
        l prev prim >
        bd 0 prim < l bl prim < prim or
        prim and
        [ nbr b piece s prev d 1 prim + d l nextl ]
        [ nbr b piece s prev d 1 prim + bd bl nextl ]
        if } ]
    if };

: nextdir (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many prev:Int^many -- ρ r:Int^many)
  locals { nbr b piece s prev } { nbr b piece s prev 0 -1 0 nextl };

: dfs (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many p:Seq Int^many bs:Seq Int^many -- ρ r:Seq Int^many)
  locals { nbr b piece s p bs } {
    nbr b piece s -1 nextdir
    locals { d } {
      d 0 prim <
      [ p 0 sg bs 0 sg prim > [ p ] [ bs ] if ]
      [ nbr b piece s p bs d kids ]
      if } };

: kids (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many p:Seq Int^many bs:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { nbr b piece s p bs d } {
    nbr b piece s d cand
    locals { l } {
      nbr s 4 prim * d prim + sg
      locals { over } {
        p 0 sg 1 prim +
        locals { dp } {
          p 0 dp sp dp 1 prim + d sp
          locals { p2 } {
            piece l crowns
            [ dp bs 0 sg prim > [ p2 ] [ bs ] if ]
            [ nbr b over 0 sp piece l p2 bs dfs ]
            if
            locals { bs2 } {
              nbr b piece s l nextdir
              locals { d2 } {
                d2 0 prim <
                [ bs2 ]
                [ nbr b piece s p bs2 d2 kids ]
                if } } } } } } };

: findcap (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many side:Int^many s:Int^many bs:Seq Int^many -- ρ r:Seq Int^many)
  locals { nbr b side s bs } {
    s 32 prim >=
    [ bs ]
    [ b s sg side owns
      [ nbr b s 0 sp b s sg s prim seq-int.empty 14 zeros 1 s sp bs dfs
        locals { bs2 } { nbr b side s 1 prim + bs2 findcap } ]
      [ nbr b side s 1 prim + bs findcap ]
      if ]
    if };

: walk (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many bs:Seq Int^many i:Int^many s:Int^many -- ρ rb:Seq Int^many rs:Int^many)
  locals { nbr b bs i s } {
    i bs 0 sg prim >=
    [ b s ]
    [ bs 2 i prim + sg
      locals { d } {
        nbr s 4 prim * d prim + sg
        locals { over } {
          nbr b over 0 sp bs i 1 prim + nbr over 4 prim * d prim + sg walk } } ]
    if };

: target (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many d:Int^many -- ρ r:Int^many)
  locals { nbr b piece s d } {
    piece d canmove
    [ nbr s 4 prim * d prim + sg
      locals { l } {
        l 0 prim < [ -1 ] [ b l sg 0 prim = [ l ] [ -1 ] if ] if } ]
    [ -1 ]
    if };

: minstep (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many piece:Int^many s:Int^many d:Int^many bl:Int^many -- ρ r:Int^many)
  locals { nbr b piece s d bl } {
    d 4 prim >=
    [ bl ]
    [ nbr b piece s d target
      locals { l } {
        l 0 prim >=
        bl 0 prim < l bl prim < prim or
        prim and
        [ nbr b piece s d 1 prim + l minstep ]
        [ nbr b piece s d 1 prim + bl minstep ]
        if } ]
    if };

: findstep (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many side:Int^many s:Int^many -- ρ r:Int^many)
  locals { nbr b side s } {
    s 32 prim >=
    [ -1 ]
    [ b s sg side owns
      [ nbr b b s sg s 0 -1 minstep
        locals { l } {
          l 0 prim >=
          [ s 32 prim * l prim + ]
          [ nbr b side s 1 prim + findstep ]
          if } ]
      [ nbr b side s 1 prim + findstep ]
      if ]
    if };

: game (forall ρ; ρ nbr:Seq Int^many b:Seq Int^many side:Int^many played:Int^many wt:Int^many bt:Int^many cr:Int^many plies:Int^many -- ρ rb:Seq Int^many rplayed:Int^many rwt:Int^many rbt:Int^many rcr:Int^many res:Int^many)
  locals { nbr b side played wt bt cr plies } {
    nbr b side 0 prim seq-int.empty 14 zeros findcap
    locals { bs } {
      bs 0 sg 0 prim >
      [ played plies prim >=
        [ b played wt bt cr 0 ]
        [ bs 1 sg
          locals { st } {
            b st sg
            locals { piece } {
              nbr b st 0 sp bs 0 st walk
              locals { b1 sf } {
                piece sf crowns
                locals { cw } {
                  b1 sf cw [ piece 1 prim + ] [ piece ] if sp
                  locals { b2 } {
                    nbr b2 1 side prim - played 1 prim +
                    side 0 prim = [ wt bs 0 sg prim + ] [ wt ] if
                    side 0 prim = [ bt ] [ bt bs 0 sg prim + ] if
                    cr cw [ 1 ] [ 0 ] if prim +
                    plies game } } } } } ]
        if ]
      [ nbr b side 0 findstep
        locals { code } {
          code 0 prim <
          [ b played wt bt cr side 0 prim = [ 2 ] [ 1 ] if ]
          [ played plies prim >=
            [ b played wt bt cr 0 ]
            [ code 32 prim div
              locals { st } {
                code 32 prim mod
                locals { l } {
                  b st sg
                  locals { piece } {
                    piece l crowns
                    locals { cw } {
                      b st 0 sp l cw [ piece 1 prim + ] [ piece ] if sp
                      locals { b2 } {
                        nbr b2 1 side prim - played 1 prim + wt bt cr cw [ 1 ] [ 0 ] if prim + plies game } } } } } ]
            if ]
          if } ]
      if } };

: main
  (forall ρ; ρ board:Seq Int^many turn:Int^many plies:Int^many -- ρ rb:Seq Int^many played:Int^many wt:Int^many bt:Int^many crowned:Int^many result:Int^many)
  locals { board turn plies } {
    prim seq-int.empty 0 buildnbr
    board turn 0 0 0 0 plies game };
```

### task: regex
```firth
: sg (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many) prim seq-int.at;
: sp (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: zeros (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { n 0 prim <= [ s ] [ s 0 prim seq-int.push n 1 prim - zeros ] if };

: empty13 (forall ρ; ρ -- ρ r:Seq Int^many) prim seq-int.empty 13 zeros;

: uniloop (forall ρ; ρ a:Seq Int^many b:Seq Int^many i:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { a b i acc } {
    i 13 prim >=
    [ acc ]
    [ a b i 1 prim + acc i a i sg b i sg prim + 0 prim > [ 1 ] [ 0 ] if sp uniloop ]
    if };
: uni (forall ρ; ρ a:Seq Int^many b:Seq Int^many -- ρ r:Seq Int^many)
  locals { a b } { a b 0 empty13 uniloop };

: seteql (forall ρ; ρ a:Seq Int^many b:Seq Int^many i:Int^many -- ρ r:Bool^many)
  locals { a b i } {
    i 13 prim >=
    [ true ]
    [ a i sg b i sg prim = [ a b i 1 prim + seteql ] [ false ] if ]
    if };
: seteq (forall ρ; ρ a:Seq Int^many b:Seq Int^many -- ρ r:Bool^many)
  locals { a b } { a b 0 seteql };

: lastset (forall ρ; ρ r:Seq Int^many i:Int^many -- ρ x:Int^many)
  locals { r i } {
    i 0 prim < [ -1 ] [ r i sg 1 prim = [ i ] [ r i 1 prim - lastset ] if ] if };

: closeof (forall ρ; ρ pat:Seq Int^many i:Int^many d:Int^many -- ρ j:Int^many)
  locals { pat i d } {
    pat i sg
    locals { t } {
      t 32 prim =
      [ d 0 prim = [ i ] [ pat i 1 prim + d 1 prim - closeof ] if ]
      [ t 31 prim = [ pat i 1 prim + d 1 prim + closeof ] [ pat i 1 prim + d closeof ] if ]
      if } };

: atomend (forall ρ; ρ pat:Seq Int^many a:Int^many -- ρ j:Int^many)
  locals { pat a } {
    pat a sg 31 prim =
    [ pat a 1 prim + 0 closeof 1 prim + ]
    [ a 1 prim + ]
    if };

: opsend (forall ρ; ρ pat:Seq Int^many i:Int^many -- ρ j:Int^many)
  locals { pat i } {
    i pat prim seq-int.len prim >=
    [ i ]
    [ pat i sg
      locals { t } {
        t 27 prim >= t 29 prim <= prim and
        [ pat i 1 prim + opsend ]
        [ i ]
        if } ]
    if };

: seqend (forall ρ; ρ pat:Seq Int^many i:Int^many -- ρ j:Int^many)
  locals { pat i } {
    i pat prim seq-int.len prim >=
    [ i ]
    [ pat i sg
      locals { t } {
        t 30 prim = t 32 prim = prim or
        [ i ]
        [ pat pat i atomend opsend seqend ]
        if } ]
    if };

: effop (forall ρ; ρ pat:Seq Int^many i:Int^many e:Int^many fq:Int^many fs:Int^many fp:Int^many -- ρ r:Int^many)
  locals { pat i e fq fs fp } {
    i e prim >=
    [ fs 1 prim = fq fp prim + 2 prim = prim or
      [ 2 ]
      [ fq 1 prim = [ 1 ] [ fp 1 prim = [ 3 ] [ 0 ] if ] if ]
      if ]
    [ pat i sg
      locals { t } {
        pat i 1 prim + e
        t 29 prim = [ 1 ] [ fq ] if
        t 27 prim = [ 1 ] [ fs ] if
        t 28 prim = [ 1 ] [ fp ] if
        effop } ]
    if };

: stepset (forall ρ; ρ s:Seq Int^many c:Int^many st:Seq Int^many p:Int^many t:Seq Int^many -- ρ r:Seq Int^many)
  locals { s c st p t } {
    p s prim seq-int.len prim >=
    [ t ]
    [ st p sg 1 prim =
      c 26 prim = s p sg c prim = prim or
      prim and
      [ s c st p 1 prim + t p 1 prim + 1 sp stepset ]
      [ s c st p 1 prim + t stepset ]
      if ]
    if };

: atomev (forall ρ; ρ pat:Seq Int^many s:Seq Int^many a0:Int^many st:Seq Int^many -- ρ r:Seq Int^many)
  locals { pat s a0 st } {
    pat a0 sg
    locals { t } {
      t 31 prim =
      [ pat s a0 1 prim + st altev ]
      [ s t st 0 empty13 stepset ]
      if } };

: star (forall ρ; ρ pat:Seq Int^many s:Seq Int^many a0:Int^many r:Seq Int^many -- ρ x:Seq Int^many)
  locals { pat s a0 r } {
    r pat s a0 r atomev uni
    locals { r2 } {
      r2 r seteq [ r ] [ pat s a0 r2 star ] if } };

: chain (forall ρ; ρ pat:Seq Int^many s:Seq Int^many a0:Int^many op:Int^many st:Seq Int^many -- ρ r:Seq Int^many)
  locals { pat s a0 op st } {
    op 0 prim =
    [ pat s a0 st atomev ]
    [ op 1 prim =
      [ st pat s a0 st atomev uni ]
      [ op 2 prim =
        [ pat s a0 st star ]
        [ pat s a0 pat s a0 st atomev star ]
        if ]
      if ]
    if };

: seqev (forall ρ; ρ pat:Seq Int^many s:Seq Int^many pp:Int^many st:Seq Int^many -- ρ r:Seq Int^many)
  locals { pat s pp st } {
    pp pat prim seq-int.len prim >=
    [ st ]
    [ pat pp sg
      locals { t } {
        t 30 prim = t 32 prim = prim or
        [ st ]
        [ pat pp atomend
          locals { a1 } {
            pat a1 opsend
            locals { e } {
              pat s pp pat a1 e 0 0 0 effop st chain
              locals { s2 } { pat s e s2 seqev } } } ]
        if } ]
    if };

: altev (forall ρ; ρ pat:Seq Int^many s:Seq Int^many pp:Int^many st:Seq Int^many -- ρ r:Seq Int^many)
  locals { pat s pp st } {
    pat s pp st seqev
    locals { t } {
      pat pp seqend
      locals { q } {
        q pat prim seq-int.len prim >=
        [ t ]
        [ pat q sg 30 prim =
          [ t pat s q 1 prim + st altev uni ]
          [ t ]
          if ]
        if } } };

: valalt (forall ρ; ρ pat:Seq Int^many i:Int^many -- ρ j:Int^many)
  locals { pat i } {
    pat i valseq
    locals { j } {
      j 0 prim <
      [ -1 ]
      [ j pat prim seq-int.len prim >=
        [ j ]
        [ pat j sg 30 prim = [ pat j 1 prim + valalt ] [ j ] if ]
        if ]
      if } };

: valseq (forall ρ; ρ pat:Seq Int^many i:Int^many -- ρ j:Int^many)
  locals { pat i } {
    i pat prim seq-int.len prim >=
    [ i ]
    [ pat i sg
      locals { t } {
        t 30 prim = t 32 prim = prim or
        [ i ]
        [ pat i valitem
          locals { e } { e 0 prim < [ -1 ] [ pat e valseq ] if } ]
        if } ]
    if };

: valitem (forall ρ; ρ pat:Seq Int^many i:Int^many -- ρ j:Int^many)
  locals { pat i } {
    pat i sg
    locals { t } {
      t 26 prim <=
      [ pat i 1 prim + opsend ]
      [ t 31 prim =
        [ pat i 1 prim + valalt
          locals { j } {
            j 0 prim <
            [ -1 ]
            [ j pat prim seq-int.len prim >=
              [ -1 ]
              [ pat j sg 32 prim = [ pat j 1 prim + opsend ] [ -1 ] if ]
              if ]
            if } ]
        [ -1 ]
        if ]
      if } };

: slice (forall ρ; ρ chars:Seq Int^many off:Int^many n:Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { chars off n k acc } {
    k n prim >=
    [ acc ]
    [ chars off n k 1 prim + acc chars off k prim + sg prim seq-int.push slice ]
    if };

: evalstr (forall ρ; ρ pat:Seq Int^many chars:Seq Int^many off:Int^many n:Int^many -- ρ f:Bool^many l:Int^many)
  locals { pat chars off n } {
    chars off n 0 prim seq-int.empty slice
    locals { s } {
      pat s 0 empty13 0 1 sp altev
      locals { r } {
        r n sg 1 prim =
        r n lastset } } };

: strloop (forall ρ; ρ pat:Seq Int^many lens:Seq Int^many chars:Seq Int^many j:Int^many off:Int^many full:Seq Bool^many long:Seq Int^many cnt:Int^many -- ρ rf:Seq Bool^many rl:Seq Int^many rc:Int^many)
  locals { pat lens chars j off full long cnt } {
    j lens prim seq-int.len prim >=
    [ full long cnt ]
    [ lens j sg
      locals { n } {
        pat chars off n evalstr
        locals { f l } {
          pat lens chars j 1 prim + off n prim +
          full f prim seq-bool.push
          long l prim seq-int.push
          cnt f [ 1 ] [ 0 ] if prim +
          strloop } } ]
    if };

: fillinv (forall ρ; ρ lens:Seq Int^many k:Int^many full:Seq Bool^many long:Seq Int^many -- ρ rf:Seq Bool^many rl:Seq Int^many)
  locals { lens k full long } {
    k lens prim seq-int.len prim >=
    [ full long ]
    [ lens k 1 prim + full false prim seq-bool.push long -1 prim seq-int.push fillinv ]
    if };

: main
  (forall ρ; ρ pat:Seq Int^many lens:Seq Int^many chars:Seq Int^many -- ρ full:Seq Bool^many longest:Seq Int^many count:Int^many valid:Bool^many)
  locals { pat lens chars } {
    pat 0 valalt pat prim seq-int.len prim =
    [ pat lens chars 0 0 prim seq-bool.empty prim seq-int.empty 0 strloop true ]
    [ lens 0 prim seq-bool.empty prim seq-int.empty fillinv 0 false ]
    if };
```

### task: swiss
```firth
: sg (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many) prim seq-int.at;
: sp (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: inc (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m i d } { m i m i sg d prim + sp };
: zeros (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { n 0 prim <= [ s ] [ s 0 prim seq-int.push n 1 prim - zeros ] if };

: sub (forall ρ; ρ m:Seq Int^many off:Int^many n:Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m off n k acc } {
    k n prim >=
    [ acc ]
    [ m off n k 1 prim + acc m off k prim + sg prim seq-int.push sub ]
    if };

: better (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many a:Int^many b:Int^many -- ρ r:Bool^many)
  locals { k1 k2 k3 a b } {
    k1 a sg k1 b sg prim =
    [ k2 a sg k2 b sg prim =
      [ k3 a sg k3 b sg prim =
        [ a b prim < ]
        [ k3 a sg k3 b sg prim > ]
        if ]
      [ k2 a sg k2 b sg prim > ]
      if ]
    [ k1 a sg k1 b sg prim > ]
    if };

: best (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many used:Seq Int^many i:Int^many b:Int^many -- ρ r:Int^many)
  locals { k1 k2 k3 used i b } {
    i k1 prim seq-int.len prim >=
    [ b ]
    [ used i sg 1 prim =
      [ k1 k2 k3 used i 1 prim + b best ]
      [ b 0 prim <
        [ k1 k2 k3 used i 1 prim + i best ]
        [ k1 k2 k3 i b better
          [ k1 k2 k3 used i 1 prim + i best ]
          [ k1 k2 k3 used i 1 prim + b best ]
          if ]
        if ]
      if ]
    if };

: rankloop (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many used:Seq Int^many out:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 used out } {
    out prim seq-int.len k1 prim seq-int.len prim >=
    [ out ]
    [ k1 k2 k3 used 0 -1 best
      locals { b } { k1 k2 k3 used b 1 sp out b prim seq-int.push rankloop } ]
    if };

: rankby (forall ρ; ρ k1:Seq Int^many k2:Seq Int^many k3:Seq Int^many -- ρ r:Seq Int^many)
  locals { k1 k2 k3 } {
    k1 k2 k3 prim seq-int.empty k1 prim seq-int.len zeros prim seq-int.empty rankloop };

: findbye (forall ρ; ρ m:Seq Int^many ord:Seq Int^many i:Int^many -- ρ p:Int^many)
  locals { m ord i } {
    ord i sg
    locals { p } {
      m 36 p prim + sg 0 prim = [ p ] [ m ord i 1 prim - findbye ] if } };

: clrpa (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m i } {
    i m 283 sg prim >=
    [ m ]
    [ m 290 i prim + 0 sp i 1 prim + clrpa ]
    if };

: findp (forall ρ; ρ m:Seq Int^many ord:Seq Int^many x:Int^many j:Int^many must:Int^many -- ρ y:Int^many)
  locals { m ord x j must } {
    j ord prim seq-int.len prim >=
    [ -1 ]
    [ ord j sg
      locals { y } {
        m 290 y prim + sg 0 prim =
        must 0 prim = m 48 x 12 prim * prim + y prim + sg 0 prim = prim or
        prim and
        [ y ]
        [ m ord x j 1 prim + must findp ]
        if } ]
    if };

: play (forall ρ; ρ m:Seq Int^many x:Int^many y:Int^many res:Seq Int^many -- ρ r:Seq Int^many)
  locals { m x y res } {
    m 12 x prim + sg m 12 y prim + sg
    locals { wx wy } {
      wx wy prim <
      [ x y ]
      [ wy wx prim <
        [ y x ]
        [ m 24 y prim + sg 2 prim = m 24 x prim + sg 2 prim = prim not prim and
          [ y x ] [ x y ] if ]
        if ]
      if
      locals { w b } {
        res m 281 sg sg
        locals { r } {
          m 281 1 inc
          290 y prim + 1 sp
          12 w prim + 1 inc
          24 w prim + 1 sp
          24 b prim + 2 sp
          48 w 12 prim * prim + b prim + 1 sp
          48 b 12 prim * prim + w prim + 1 sp
          192 m 280 sg 2 prim * prim + w sp
          193 m 280 sg 2 prim * prim + b sp
          280 1 inc
          r 0 prim =
          [ w 2 inc ]
          [ r 1 prim = [ w 1 inc b 1 inc ] [ b 2 inc ] if ]
          if } } } };

: pairing (forall ρ; ρ m:Seq Int^many ord:Seq Int^many res:Seq Int^many i:Int^many -- ρ r:Seq Int^many)
  locals { m ord res i } {
    i ord prim seq-int.len prim >=
    [ m ]
    [ ord i sg
      locals { x } {
        m 290 x prim + sg 1 prim =
        [ m ord res i 1 prim + pairing ]
        [ m 290 x prim + 1 sp
          locals { m1 } {
            m1 ord x i 1 prim + 1 findp
            locals { y0 } {
              y0 0 prim <
              [ m1 282 1 inc m1 ord x i 1 prim + 0 findp ]
              [ m1 y0 ]
              if
              locals { m2 y } {
                m2 x y res play
                ord res i 1 prim + pairing } } } ]
        if } ]
    if };

: round (forall ρ; ρ m:Seq Int^many ratings:Seq Int^many res:Seq Int^many -- ρ r:Seq Int^many)
  locals { m ratings res } {
    m 283 sg
    locals { n } {
      m 0 n 0 prim seq-int.empty sub ratings ratings rankby
      locals { ord } {
        m 0 clrpa
        locals { m1 } {
          n 2 prim mod 1 prim =
          [ m1 ord n 1 prim - findbye
            locals { p } { m1 p 2 inc 36 p prim + 1 sp 290 p prim + 1 sp } ]
          [ m1 ]
          if
          locals { m2 } { m2 ord res 0 pairing } } } } };

: playrounds (forall ρ; ρ m:Seq Int^many ratings:Seq Int^many res:Seq Int^many r:Int^many total:Int^many -- ρ x:Seq Int^many)
  locals { m ratings res r total } {
    r total prim >=
    [ m ]
    [ m ratings res round ratings res r 1 prim + total playrounds ]
    if };

: buchloop (forall ρ; ρ m:Seq Int^many g:Int^many buch:Seq Int^many -- ρ x:Seq Int^many)
  locals { m g buch } {
    g m 280 sg prim >=
    [ buch ]
    [ m 192 g 2 prim * prim + sg m 193 g 2 prim * prim + sg
      locals { w b } {
        m g 1 prim +
        buch w m b sg inc b m w sg inc
        buchloop } ]
    if };

: main
  (forall ρ; ρ ratings:Seq Int^many rounds:Int^many results:Seq Int^many -- ρ scores:Seq Int^many buchholz:Seq Int^many ranking:Seq Int^many whites:Seq Int^many rematches:Int^many)
  locals { ratings rounds results } {
    prim seq-int.empty 300 zeros
    283 ratings prim seq-int.len sp
    ratings results 0 rounds playrounds
    locals { f } {
      ratings prim seq-int.len
      locals { n } {
        f 0 n 0 prim seq-int.empty sub
        locals { sc } {
          f 0 prim seq-int.empty n zeros buchloop
          locals { bu } {
            sc bu
            sc bu ratings rankby
            f 12 n 0 prim seq-int.empty sub
            f 282 sg } } } } };
```

### task: warehouse
```firth
: sg (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many) prim seq-int.at;
: sp (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: inc (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m i d } { m i m i sg d prim + sp };
: zeros (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { n 0 prim <= [ s ] [ s 0 prim seq-int.push n 1 prim - zeros ] if };
: min (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ a ] [ b ] if };

: pg (forall ρ; ρ m:Seq Int^many b:Int^many p:Int^many -- ρ r:Int^many)
  locals { m b p } { m b p prim + sg };
: pinc (forall ρ; ρ m:Seq Int^many b:Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m b p d } { m b p prim + d inc };
: pset (forall ρ; ρ m:Seq Int^many b:Int^many p:Int^many x:Int^many -- ρ r:Seq Int^many)
  locals { m b p x } { m b p prim + x sp };

: sub (forall ρ; ρ m:Seq Int^many off:Int^many n:Int^many k:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m off n k acc } {
    k n prim >=
    [ acc ]
    [ m off n k 1 prim + acc m off k prim + sg prim seq-int.push sub ]
    if };

: copy (forall ρ; ρ m:Seq Int^many src:Seq Int^many base:Int^many k:Int^many -- ρ r:Seq Int^many)
  locals { m src base k } {
    k src prim seq-int.len prim >=
    [ m ]
    [ m base k prim + src k prim seq-int.at sp src base k 1 prim + copy ]
    if };

: takel (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many taken:Int^many -- ρ r:Seq Int^many t:Int^many)
  locals { m p q taken } {
    q 0 prim <=
    m 10 p pg m 15 p pg prim >=
    prim or
    [ m taken ]
    [ 100 p 150 prim * prim + m 10 p pg prim +
      locals { ix } {
        m ix sg
        locals { lq } {
          lq q min
          locals { t } {
            m ix lq t prim - sp
            lq t prim - 0 prim =
            [ 10 p 1 pinc ]
            [ ]
            if
            p q t prim - taken t prim + takel } } } ]
    if };

: take (forall ρ; ρ m:Seq Int^many p:Int^many q:Int^many -- ρ r:Seq Int^many t:Int^many)
  locals { m p q } {
    m p q 0 takel
    locals { m1 t } {
      m1 20 p 0 t prim - pinc
      1 t inc
      0 t m1 40 p pg prim * inc
      t } };

: shiftl (forall ρ; ρ m:Seq Int^many p:Int^many exp:Int^many pos:Int^many -- ρ r:Seq Int^many q:Int^many)
  locals { m p exp pos } {
    pos m 10 p pg prim >
    [ m 850 p 150 prim * prim + pos prim + 1 prim - sg exp prim > ]
    [ false ]
    if
    [ 100 p 150 prim * prim + pos prim +
      locals { qi } {
        850 p 150 prim * prim + pos prim +
        locals { ei } {
          m qi m qi 1 prim - sg sp
          ei m ei 1 prim - sg sp
          p exp pos 1 prim - shiftl } } ]
    [ m pos ]
    if };

: addlot (forall ρ; ρ m:Seq Int^many p:Int^many qty:Int^many exp:Int^many -- ρ r:Seq Int^many)
  locals { m p qty exp } {
    m p exp m 15 p pg shiftl
    locals { m1 pos } {
      m1 100 p 150 prim * prim + pos prim + qty sp
      850 p 150 prim * prim + pos prim + exp sp
      15 p 1 pinc
      20 p qty pinc
      p fillbo } };

: fillbo (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    m 30 p pg m 35 p pg prim <
    m 20 p pg 0 prim >
    prim and
    [ 1600 p 80 prim * prim + m 30 p pg prim +
      locals { bi } {
        m bi sg
        locals { o } {
          m p o take
          locals { m1 t } {
            m1 bi o t prim - sp
            o t prim - 0 prim =
            [ 30 p 1 pinc ]
            [ ]
            if
            p fillbo } } } ]
    [ m ]
    if };

: addbo (forall ρ; ρ m:Seq Int^many p:Int^many o:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p o d } {
    1600 p 80 prim * prim + m 35 p pg prim +
    locals { bi } {
      m bi o sp
      bi 400 prim + d sp
      35 p 1 pinc } };

: order (forall ρ; ρ m:Seq Int^many p:Int^many qty:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p qty d } {
    m 30 p pg m 35 p pg prim <
    [ m p qty d addbo ]
    [ m p qty take
      locals { m1 t } {
        qty t prim - 0 prim >
        [ m1 p qty t prim - d addbo ]
        [ m1 ]
        if } ]
    if };

: events (forall ρ; ρ m:Seq Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m d } {
    m 5 sg
    locals { i } {
      i m 7 sg prim >=
      [ m ]
      [ m 2400 i prim + sg d prim =
        [ m 2480 i prim + sg 1 prim =
          [ m m 2560 i prim + sg m 2640 i prim + sg m 2720 i prim + sg addlot ]
          [ m m 2560 i prim + sg m 2640 i prim + sg d order ]
          if
          5 1 inc
          d events ]
        [ m ]
        if ]
      if } };

: expire1 (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    m 10 p pg m 15 p pg prim <
    [ m 850 p 150 prim * prim + m 10 p pg prim + sg d prim < ]
    [ false ]
    if
    [ 100 p 150 prim * prim + m 10 p pg prim +
      locals { qi } {
        m qi sg
        locals { q } {
          m 2 q inc
          20 p 0 q prim - pinc
          10 p 1 pinc
          p d expire1 } } ]
    [ m ]
    if };

: arrive (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    m 25 p pg d prim =
    [ m p m 50 p pg d m 60 p pg prim + addlot
      25 p -1 pset ]
    [ m ]
    if };

: cancel (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    m 30 p pg m 35 p pg prim <
    [ m 2000 p 80 prim * prim + m 30 p pg prim + sg d 7 prim - prim <= ]
    [ false ]
    if
    [ 1600 p 80 prim * prim + m 30 p pg prim +
      locals { bi } {
        m 3 m bi sg inc
        30 p 1 pinc
        p d cancel } ]
    [ m ]
    if };

: reorder (forall ρ; ρ m:Seq Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m p d } {
    m 25 p pg 0 prim <
    m 20 p pg m 45 p pg prim <=
    prim and
    [ m 25 p d m 55 p pg prim + pset 4 1 inc ]
    [ m ]
    if };

: eachp (forall ρ; ρ m:Seq Int^many ph:Int^many p:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m ph p d } {
    p m 6 sg prim >=
    [ m ]
    [ m p d
      ph 0 prim = [ expire1 ]
      [ ph 1 prim = [ arrive ]
        [ ph 2 prim = [ cancel ] [ reorder ] if ]
        if ]
      if
      ph p 1 prim + d eachp ]
    if };

: days (forall ρ; ρ m:Seq Int^many d:Int^many total:Int^many -- ρ r:Seq Int^many)
  locals { m d total } {
    d total prim >=
    [ m ]
    [ m 0 0 d eachp
      1 0 d eachp
      d events
      2 0 d eachp
      3 0 d eachp
      d 1 prim + total days ]
    if };

: initsup (forall ρ; ρ m:Seq Int^many p:Int^many -- ρ r:Seq Int^many)
  locals { m p } {
    p m 6 sg prim >=
    [ m ]
    [ m 25 p -1 pset p 1 prim + initsup ]
    if };

: owedp (forall ρ; ρ m:Seq Int^many p:Int^many i:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m p i acc } {
    i m 35 p pg prim >=
    [ acc ]
    [ m p i 1 prim + acc m 1600 p 80 prim * prim + i prim + sg prim + owedp ]
    if };

: owedall (forall ρ; ρ m:Seq Int^many p:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m p acc } {
    p m 6 sg prim >=
    [ acc ]
    [ m p 1 prim + acc m p m 30 p pg 0 owedp prim + owedall ]
    if };

: main
  (forall ρ; ρ days:Int^many price:Seq Int^many rp:Seq Int^many rq:Seq Int^many lead:Seq Int^many shelf:Seq Int^many evd:Seq Int^many evk:Seq Int^many evp:Seq Int^many evq:Seq Int^many eve:Seq Int^many -- ρ stock:Seq Int^many earned:Int^many shipped:Int^many discarded:Int^many cancelled:Int^many supplies:Int^many owed:Int^many)
  locals { dd price rp rq lead shelf evd evk evp evq eve } {
    prim seq-int.empty 2800 zeros
    6 price prim seq-int.len sp
    7 evd prim seq-int.len sp
    price 40 0 copy
    rp 45 0 copy
    rq 50 0 copy
    lead 55 0 copy
    shelf 60 0 copy
    evd 2400 0 copy
    evk 2480 0 copy
    evp 2560 0 copy
    evq 2640 0 copy
    eve 2720 0 copy
    0 initsup
    0 dd days
    locals { f } {
      f 20 f 6 sg 0 prim seq-int.empty sub
      f 0 sg f 1 sg f 2 sg f 3 sg f 4 sg
      f 0 0 owedall } };
```

### task: cache-sim
```firth
: sg (forall ρ; ρ m:Seq Int^many i:Int^many -- ρ r:Int^many) prim seq-int.at;
: sp (forall ρ; ρ m:Seq Int^many i:Int^many x:Int^many -- ρ r:Seq Int^many) prim seq-int.set;
: inc (forall ρ; ρ m:Seq Int^many i:Int^many d:Int^many -- ρ r:Seq Int^many)
  locals { m i d } { m i m i sg d prim + sp };
: zeros (forall ρ; ρ s:Seq Int^many n:Int^many -- ρ r:Seq Int^many)
  locals { s n } { n 0 prim <= [ s ] [ s 0 prim seq-int.push n 1 prim - zeros ] if };

: bix (forall ρ; ρ lv:Int^many set:Int^many j:Int^many -- ρ r:Int^many)
  locals { lv set j } { lv 128 prim * set 8 prim * prim + j prim + };

: find (forall ρ; ρ m:Seq Int^many lv:Int^many set:Int^many blk:Int^many j:Int^many -- ρ r:Int^many)
  locals { m lv set blk j } {
    j m 256 lv 8 prim * prim + set prim + sg prim >=
    [ -1 ]
    [ m lv set j bix sg blk prim =
      [ j ]
      [ m lv set blk j 1 prim + find ]
      if ]
    if };

: shl (forall ρ; ρ m:Seq Int^many lv:Int^many set:Int^many k:Int^many cnt:Int^many -- ρ r:Seq Int^many)
  locals { m lv set k cnt } {
    k 1 prim + cnt prim >=
    [ m ]
    [ lv set k bix
      locals { i } {
        m i m i 1 prim + sg sp
        i 64 prim + m i 65 prim + sg sp
        lv set k 1 prim + cnt shl } ]
    if };

: touch (forall ρ; ρ m:Seq Int^many lv:Int^many set:Int^many pos:Int^many nd:Int^many -- ρ r:Seq Int^many)
  locals { m lv set pos nd } {
    lv set pos bix
    locals { i } {
      m i sg
      locals { b } {
        m i 64 prim + sg nd prim + 0 prim > [ 1 ] [ 0 ] if
        locals { d } {
          m lv set pos m 256 lv 8 prim * prim + set prim + sg shl
          locals { m1 } {
            lv set m 256 lv 8 prim * prim + set prim + sg 1 prim - bix
            locals { j } { m1 j b sp j 64 prim + d sp } } } } } };

: insert (forall ρ; ρ m:Seq Int^many lv:Int^many set:Int^many b:Int^many d:Int^many -- ρ r:Seq Int^many eb:Int^many ed:Int^many)
  locals { m lv set b d } {
    m 256 lv 8 prim * prim + set prim + sg
    locals { cnt } {
      cnt m 292 lv prim + sg prim >=
      [ lv set 0 bix
        locals { i0 } {
          m i0 sg m i0 64 prim + sg
          locals { eb ed } {
            m lv set 0 cnt shl
            lv set cnt 1 prim - bix
            locals { m1 j } { m1 j b sp j 64 prim + d sp eb ed } } } ]
      [ lv set cnt bix
        locals { j } {
          m j b sp j 64 prim + d sp
          256 lv 8 prim * prim + set prim + cnt 1 prim + sp
          -1 0 } ]
      if } };

: l2write (forall ρ; ρ m:Seq Int^many b:Int^many -- ρ r:Seq Int^many)
  locals { m b } {
    b m 291 sg prim mod
    locals { s2 } {
      m 1 s2 b 0 find
      locals { p } {
        p 0 prim >=
        [ m 1 s2 p 1 touch ]
        [ m 1 s2 b 1 insert
          locals { m2 eb ed } { ed 1 prim = [ m2 285 1 inc ] [ m2 ] if } ]
        if } } };

: access (forall ρ; ρ m:Seq Int^many a:Int^many wr:Bool^many -- ρ r:Seq Int^many)
  locals { m a wr } {
    a m 290 sg prim mod
    locals { s1 } {
      m 0 s1 a 0 find
      locals { pos } {
        pos 0 prim >=
        [ m 0 s1 pos wr [ 1 ] [ 0 ] if touch 280 1 inc ]
        [ m 281 1 inc
          a m 291 sg prim mod
          locals { m1 s2 } {
            m1 1 s2 a 0 find
            locals { p2 } {
              p2 0 prim >=
              [ m1 1 s2 p2 0 touch 282 1 inc ]
              [ m1 283 1 inc 284 1 inc 1 s2 a 0 insert
                locals { m2 eb ed } {
                  ed 1 prim =
                  [ m2 285 1 inc ]
                  [ m2 ]
                  if } ]
              if
              locals { m3 } {
                m3 0 s1 a wr [ 1 ] [ 0 ] if insert
                locals { m4 eb1 ed1 } {
                  ed1 1 prim =
                  [ m4 eb1 l2write ]
                  [ m4 ]
                  if } } } } ]
        if } } };

: run (forall ρ; ρ m:Seq Int^many addrs:Seq Int^many writes:Seq Bool^many i:Int^many -- ρ r:Seq Int^many)
  locals { m addrs writes i } {
    i addrs prim seq-int.len prim >=
    [ m ]
    [ m addrs i prim seq-int.at writes i prim seq-bool.at access addrs writes i 1 prim + run ]
    if };

: dc (forall ρ; ρ m:Seq Int^many lv:Int^many set:Int^many j:Int^many acc:Int^many -- ρ r:Int^many)
  locals { m lv set j acc } {
    set m 290 lv prim + sg prim >=
    [ acc ]
    [ j m 256 lv 8 prim * prim + set prim + sg prim >=
      [ m lv set 1 prim + 0 acc dc ]
      [ m lv set j 1 prim + acc m lv set j bix 64 prim + sg prim + dc ]
      if ]
    if };

: l1b (forall ρ; ρ m:Seq Int^many set:Int^many j:Int^many acc:Seq Int^many -- ρ r:Seq Int^many)
  locals { m set j acc } {
    set m 290 sg prim >=
    [ acc ]
    [ j m 256 set prim + sg prim >=
      [ m set 1 prim + 0 acc l1b ]
      [ m set j 1 prim + acc m 0 set j bix sg prim seq-int.push l1b ]
      if ]
    if };

: main
  (forall ρ; ρ s1:Int^many w1:Int^many s2:Int^many w2:Int^many addrs:Seq Int^many writes:Seq Bool^many -- ρ l1h:Int^many l1m:Int^many l2h:Int^many l2m:Int^many mr:Int^many mw:Int^many dirty:Int^many blocks:Seq Int^many)
  locals { s1 w1 s2 w2 addrs writes } {
    prim seq-int.empty 300 zeros
    290 s1 sp
    291 s2 sp
    292 w1 sp
    293 w2 sp
    addrs writes 0 run
    locals { f } {
      f 280 sg f 281 sg f 282 sg f 283 sg f 284 sg f 285 sg
      f 0 0 0 0 dc f 1 0 0 0 dc prim +
      f 0 0 prim seq-int.empty l1b } };
```

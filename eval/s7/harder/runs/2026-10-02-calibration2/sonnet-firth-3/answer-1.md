### task: poker
```firth
: bswap
  (forall ρ; ρ xs:Seq Int j:Int -- ρ r:Seq Int)
  locals { xs j } {
    xs j prim seq-int.at
    xs j 1 prim + prim seq-int.at
    locals { a b } {
      xs j b prim seq-int.set
      j 1 prim + a prim seq-int.set
    }
  };

: bpass
  (forall ρ; ρ xs:Seq Int j:Int -- ρ r:Seq Int)
  locals { xs j } {
    j 4 prim <
    [ xs j prim seq-int.at  xs j 1 prim + prim seq-int.at  prim <
      [ xs j bswap ]
      [ xs ]
      if
      j 1 prim +
      bpass ]
    [ xs ]
    if
  };

: bsort
  (forall ρ; ρ xs:Seq Int n:Int -- ρ r:Seq Int)
  locals { xs n } {
    n 0 prim >
    [ xs 0 bpass  n 1 prim -  bsort ]
    [ xs ]
    if
  };

: tally
  (forall ρ; ρ rs:Seq Int cs:Seq Int i:Int -- ρ r:Seq Int)
  locals { rs cs i } {
    i 5 prim <
    [ rs
      cs  rs i prim seq-int.at  cs rs i prim seq-int.at prim seq-int.at  1 prim +  prim seq-int.set
      i 1 prim +
      tally ]
    [ cs ]
    if
  };

: mkkeys
  (forall ρ; ρ rs:Seq Int cs:Seq Int ks:Seq Int i:Int -- ρ r:Seq Int)
  locals { rs cs ks i } {
    i 5 prim <
    [ rs cs
      ks  cs rs i prim seq-int.at prim seq-int.at 16 prim *  rs i prim seq-int.at prim +  prim seq-int.push
      i 1 prim +
      mkkeys ]
    [ ks ]
    if
  };

: digits
  (forall ρ; ρ ks:Seq Int acc:Int i:Int -- ρ r:Int)
  locals { ks acc i } {
    i 5 prim <
    [ ks  acc 15 prim *  ks i prim seq-int.at 16 prim mod  prim +  i 1 prim +  digits ]
    [ acc ]
    if
  };

: allsuit
  (forall ρ; ρ ss:Seq Int v:Int i:Int -- ρ r:Bool)
  locals { ss v i } {
    i 5 prim <
    [ ss i prim seq-int.at v prim =
      [ ss v i 1 prim + allsuit ]
      [ false ]
      if ]
    [ true ]
    if
  };

: flat-score
  (forall ρ; ρ ks:Seq Int ss:Seq Int base:Int -- ρ r:Int)
  locals { ks ss base } {
    ks 0 prim seq-int.at 16 prim mod
    ks 1 prim seq-int.at 16 prim mod
    ks 4 prim seq-int.at 16 prim mod
    locals { r0 r1 r4 } {
      ss ss 0 prim seq-int.at 1 allsuit
      locals { fl } {
        r0 r4 prim - 4 prim =  r0 14 prim =  r1 5 prim =  prim and  prim or
        [ fl [ 6075000 ] [ 3037500 ] if
          r0 14 prim =  r1 5 prim =  prim and  [ 5 ] [ r0 ] if
          prim + ]
        [ fl [ 3796875 base prim + ] [ base ] if ]
        if
      }
    }
  };

: hscore
  (forall ρ; ρ rs:Seq Int ss:Seq Int -- ρ r:Int)
  locals { rs ss } {
    rs { 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 } 0 tally
    locals { cs } {
      rs cs prim seq-int.empty 0 mkkeys  5 bsort
      locals { ks } {
        ks 0 0 digits
        locals { base } {
          ks 0 prim seq-int.at 16 prim div
          locals { c0 } {
            c0 4 prim =
            [ base 5315625 prim + ]
            [ c0 3 prim =
              [ ks 3 prim seq-int.at 16 prim div 2 prim =
                [ base 4556250 prim + ]
                [ base 2278125 prim + ]
                if ]
              [ c0 2 prim =
                [ ks 2 prim seq-int.at 16 prim div 2 prim =
                  [ base 1518750 prim + ]
                  [ base 759375 prim + ]
                  if ]
                [ ks ss base flat-score ]
                if ]
              if ]
            if
          }
        }
      }
    }
  };

: main
  (forall ρ; ρ r1:Seq Int s1:Seq Int r2:Seq Int s2:Seq Int -- ρ w:Int c1:Int c2:Int)
  locals { r1 s1 r2 s2 } {
    r1 s1 hscore
    r2 s2 hscore
    locals { a b } {
      a b prim >
      [ 1 ]
      [ a b prim <  [ 2 ] [ 0 ] if ]
      if
      a 759375 prim div
      b 759375 prim div
    }
  };
```

### task: league-table
```firth
: zeros
  (forall ρ; ρ n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim -  acc 0 prim seq-int.push  zeros ]
    [ acc ]
    if
  };

: addat
  (forall ρ; ρ xs:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { xs i d } { xs i xs i prim seq-int.at d prim + prim seq-int.set };

: bswap
  (forall ρ; ρ xs:Seq Int j:Int -- ρ r:Seq Int)
  locals { xs j } {
    xs j prim seq-int.at
    xs j 1 prim + prim seq-int.at
    locals { a b } {
      xs j b prim seq-int.set
      j 1 prim + a prim seq-int.set
    }
  };

: bpass2
  (forall ρ; ρ xs:Seq Int j:Int lim:Int -- ρ r:Seq Int)
  locals { xs j lim } {
    j lim prim <
    [ xs j prim seq-int.at  xs j 1 prim + prim seq-int.at  prim <
      [ xs j bswap ]
      [ xs ]
      if
      j 1 prim + lim
      bpass2 ]
    [ xs ]
    if
  };

: bsort2
  (forall ρ; ρ xs:Seq Int lim:Int cnt:Int -- ρ r:Seq Int)
  locals { xs lim cnt } {
    cnt 0 prim >
    [ xs 0 lim bpass2  lim cnt 1 prim -  bsort2 ]
    [ xs ]
    if
  };

: addpts
  (forall ρ; ρ pts:Seq Int h:Int a:Int hg:Int ag:Int -- ρ r:Seq Int)
  locals { pts h a hg ag } {
    hg ag prim >
    [ pts h 3 addat ]
    [ hg ag prim <
      [ pts a 3 addat ]
      [ pts h 1 addat  a 1 addat ]
      if ]
    if
  };

: pass-pts
  (forall ρ; ρ hs:Seq Int aw:Seq Int hgs:Seq Int ags:Seq Int pts:Seq Int k:Int -- ρ r:Seq Int)
  locals { hs aw hgs ags pts k } {
    k hs prim seq-int.len prim <
    [ hs aw hgs ags
      pts hs k prim seq-int.at aw k prim seq-int.at hgs k prim seq-int.at ags k prim seq-int.at addpts
      k 1 prim +
      pass-pts ]
    [ pts ]
    if
  };

: pass-s
  (forall ρ; ρ hs:Seq Int aw:Seq Int hgs:Seq Int ags:Seq Int sv:Seq Int k:Int -- ρ r:Seq Int)
  locals { hs aw hgs ags sv k } {
    k hs prim seq-int.len prim <
    [ hs aw hgs ags
      sv hs k prim seq-int.at  hgs k prim seq-int.at 1001 prim *  ags k prim seq-int.at 1000 prim * prim -  addat
      aw k prim seq-int.at  ags k prim seq-int.at 1001 prim *  hgs k prim seq-int.at 1000 prim * prim -  addat
      k 1 prim +
      pass-s ]
    [ sv ]
    if
  };

: mkp
  (forall ρ; ρ pts:Seq Int sv:Seq Int p:Seq Int i:Int -- ρ r:Seq Int)
  locals { pts sv p i } {
    i pts prim seq-int.len prim <
    [ pts sv
      p  pts i prim seq-int.at 4000000 prim *  sv i prim seq-int.at prim +  prim seq-int.push
      i 1 prim +
      mkp ]
    [ p ]
    if
  };

: pass-h
  (forall ρ; ρ hs:Seq Int aw:Seq Int hgs:Seq Int ags:Seq Int p:Seq Int hh:Seq Int k:Int -- ρ r:Seq Int)
  locals { hs aw hgs ags p hh k } {
    k hs prim seq-int.len prim <
    [ hs aw hgs ags p
      hs k prim seq-int.at
      locals { h } {
        aw k prim seq-int.at
        locals { a } {
          p h prim seq-int.at  p a prim seq-int.at  prim =
          [ hh h a hgs k prim seq-int.at ags k prim seq-int.at addpts ]
          [ hh ]
          if
        }
      }
      k 1 prim +
      pass-h ]
    [ hh ]
    if
  };

: mkf
  (forall ρ; ρ p:Seq Int hh:Seq Int f:Seq Int i:Int -- ρ r:Seq Int)
  locals { p hh f i } {
    i p prim seq-int.len prim <
    [ p hh
      f  p i prim seq-int.at 256 prim *  hh i prim seq-int.at prim +  16 prim *  9 i prim - prim +  prim seq-int.push
      i 1 prim +
      mkf ]
    [ f ]
    if
  };

: decode
  (forall ρ; ρ fs:Seq Int out:Seq Int i:Int -- ρ r:Seq Int)
  locals { fs out i } {
    i fs prim seq-int.len prim <
    [ fs
      out  9 fs i prim seq-int.at 16 prim mod prim -  prim seq-int.push
      i 1 prim +
      decode ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ n:Int hs:Seq Int aw:Seq Int hgs:Seq Int ags:Seq Int -- ρ order:Seq Int pts:Seq Int)
  locals { n hs aw hgs ags } {
    hs aw hgs ags  n prim seq-int.empty zeros  0 pass-pts
    locals { pts } {
      hs aw hgs ags  n prim seq-int.empty zeros  0 pass-s
      locals { sv } {
        pts sv prim seq-int.empty 0 mkp
        locals { p } {
          hs aw hgs ags p  n prim seq-int.empty zeros  0 pass-h
          locals { hh } {
            p hh prim seq-int.empty 0 mkf
            n 1 prim -  n 1 prim -  bsort2
            prim seq-int.empty 0 decode
            pts
          }
        }
      }
    }
  };
```

### task: bank-ledger
```firth
: zeros
  (forall ρ; ρ n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim -  acc 0 prim seq-int.push  zeros ]
    [ acc ]
    if
  };

: addat
  (forall ρ; ρ xs:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { xs i d } { xs i xs i prim seq-int.at d prim + prim seq-int.set };

: adj
  (forall ρ; ρ b:Int -- ρ r:Int)
  locals { b } {
    b 0 prim <
    [ b  0 b prim - 9 prim + 10 prim div  prim - ]
    [ b 100 prim >=
      [ b  b 100 prim div  prim + ]
      [ b ]
      if ]
    if
  };

: mend
  (forall ρ; ρ bal:Seq Int i:Int -- ρ r:Seq Int)
  locals { bal i } {
    i bal prim seq-int.len prim <
    [ bal i  bal i prim seq-int.at adj  prim seq-int.set
      i 1 prim +
      mend ]
    [ bal ]
    if
  };

: wd
  (forall ρ; ρ old:Int amt:Int -- ρ r:Int)
  locals { old amt } {
    old amt prim -
    locals { nw } {
      old 0 prim >=  nw 0 prim <  prim and
      [ nw 5 prim - ]
      [ nw ]
      if
    }
  };

: apply
  (forall ρ; ρ bal:Seq Int kind:Int a:Int b:Int amt:Int -- ρ r:Seq Int)
  locals { bal kind a b amt } {
    kind 1 prim =
    [ bal a amt addat ]
    [ bal a  bal a prim seq-int.at amt wd  prim seq-int.set
      locals { bal2 } {
        kind 3 prim =
        [ bal2 b amt addat ]
        [ bal2 ]
        if
      } ]
    if
  };

: dop
  (forall ρ; ρ bal:Seq Int rej:Seq Int lim:Int kind:Int a:Int b:Int amt:Int -- ρ bal2:Seq Int rej2:Seq Int)
  locals { bal rej lim kind a b amt } {
    kind 4 prim =
    [ bal 0 mend  rej ]
    [ rej a prim seq-int.at 3 prim >=
      kind 3 prim =  rej b prim seq-int.at 3 prim >=  a b prim =  prim or  prim and
      prim or
      kind 2 prim >=  bal a prim seq-int.at amt prim -  0 lim prim -  prim <  prim and
      prim or
      [ bal  rej a 1 addat ]
      [ bal kind a b amt apply  rej ]
      if ]
    if
  };

: run
  (forall ρ; ρ bal:Seq Int rej:Seq Int lim:Int ks:Seq Int ac:Seq Int ot:Seq Int am:Seq Int i:Int -- ρ bal2:Seq Int rej2:Seq Int)
  locals { bal rej lim ks ac ot am i } {
    i ks prim seq-int.len prim <
    [ bal rej lim
      ks i prim seq-int.at  ac i prim seq-int.at  ot i prim seq-int.at  am i prim seq-int.at
      dop
      lim ks ac ot am i 1 prim +
      run ]
    [ bal rej ]
    if
  };

: sumseq
  (forall ρ; ρ xs:Seq Int i:Int acc:Int -- ρ r:Int)
  locals { xs i acc } {
    i xs prim seq-int.len prim <
    [ xs i 1 prim +  acc xs i prim seq-int.at prim +  sumseq ]
    [ acc ]
    if
  };

: frz
  (forall ρ; ρ rej:Seq Int out:Seq Bool i:Int -- ρ r:Seq Bool)
  locals { rej out i } {
    i rej prim seq-int.len prim <
    [ rej  out rej i prim seq-int.at 3 prim >= prim seq-bool.push  i 1 prim +  frz ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ bal:Seq Int lim:Int ks:Seq Int ac:Seq Int ot:Seq Int am:Seq Int -- ρ final:Seq Int rej:Int fr:Seq Bool)
  locals { bal lim ks ac ot am } {
    bal  bal prim seq-int.len prim seq-int.empty zeros  lim ks ac ot am 0 run
    locals { fin rj } {
      fin
      rj 0 0 sumseq
      rj prim seq-bool.empty 0 frz
    }
  };
```

### task: order-book
```firth
: zeros
  (forall ρ; ρ n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim -  acc 0 prim seq-int.push  zeros ]
    [ acc ]
    if
  };

: addat
  (forall ρ; ρ xs:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { xs i d } { xs i xs i prim seq-int.at d prim + prim seq-int.set };

: scanlo
  (forall ρ; ρ s:Seq Int lim:Int n:Int j:Int bj:Int bp:Int -- ρ r:Int)
  locals { s lim n j bj bp } {
    j n prim <
    [ s j 80 prim + prim seq-int.at
      locals { e } {
        e 1024 prim >
        [ e 1024 prim mod
          locals { p } {
            lim 0 prim =  p lim prim <=  prim or
            bj 0 prim <  p bp prim <  prim or  prim and
            [ s lim n j 1 prim +  j p  scanlo ]
            [ s lim n j 1 prim +  bj bp  scanlo ]
            if
          } ]
        [ s lim n j 1 prim +  bj bp  scanlo ]
        if
      } ]
    [ bj ]
    if
  };

: scanhi
  (forall ρ; ρ s:Seq Int lim:Int n:Int j:Int bj:Int bp:Int -- ρ r:Int)
  locals { s lim n j bj bp } {
    j n prim <
    [ s j 80 prim + prim seq-int.at
      locals { e } {
        e 0 prim >  e 1024 prim <  prim and
        [ lim 0 prim =  e lim prim >=  prim or
          bj 0 prim <  e bp prim >  prim or  prim and
          [ s lim n j 1 prim +  j e  scanhi ]
          [ s lim n j 1 prim +  bj bp  scanhi ]
          if ]
        [ s lim n j 1 prim +  bj bp  scanhi ]
        if
      } ]
    [ bj ]
    if
  };

: trade
  (forall ρ; ρ s:Seq Int i:Int q:Int j:Int -- ρ s2:Seq Int q2:Int)
  locals { s i q j } {
    s j prim seq-int.at
    locals { r } {
      r q prim <  [ r ] [ q ] if
      locals { u } {
        s j r u prim - prim seq-int.set
        40 i prim + u addat
        40 j prim + u addat
        120  u  s 80 j prim + prim seq-int.at 1024 prim mod  prim *  addat
        121 1 addat
        locals { s5 } {
          r u prim =
          [ s5 80 j prim + 0 prim seq-int.set ]
          [ s5 ]
          if
        }
        q u prim -
      }
    }
  };

: match
  (forall ρ; ρ i:Int sd:Int lim:Int s:Seq Int q:Int -- ρ s2:Seq Int q2:Int)
  locals { i sd lim s q } {
    q 0 prim >
    [ sd 0 prim =
      [ s lim i 0 -1 0 scanlo ]
      [ s lim i 0 -1 0 scanhi ]
      if
      locals { j } {
        j 0 prim >=
        [ s i q j trade
          locals { s2 q2 } { i sd lim s2 q2 match } ]
        [ s q ]
        if
      } ]
    [ s q ]
    if
  };

: place
  (forall ρ; ρ s:Seq Int i:Int sd:Int lim:Int q:Int -- ρ s2:Seq Int)
  locals { s i sd lim q } {
    q 0 prim >  lim 0 prim >  prim and
    [ s i q prim seq-int.set
      80 i prim + lim sd 1024 prim * prim + prim seq-int.set ]
    [ s ]
    if
  };

: cancel
  (forall ρ; ρ s:Seq Int i:Int j:Int -- ρ s2:Seq Int)
  locals { s i j } {
    s j prim seq-int.at 0 prim >
    [ s j 0 prim seq-int.set  80 j prim + 0 prim seq-int.set ]
    [ s ]
    if
  };

: loop
  (forall ρ; ρ ks:Seq Int sides:Seq Int pr:Seq Int qt:Seq Int s:Seq Int i:Int -- ρ s2:Seq Int)
  locals { ks sides pr qt s i } {
    i ks prim seq-int.len prim <
    [ ks sides pr qt
      ks i prim seq-int.at 0 prim =
      [ i  sides i prim seq-int.at  pr i prim seq-int.at  s  qt i prim seq-int.at  match
        locals { s2 q2 } { s2 i sides i prim seq-int.at pr i prim seq-int.at q2 place } ]
      [ s i qt i prim seq-int.at cancel ]
      if
      i 1 prim +
      loop ]
    [ s ]
    if
  };

: extract
  (forall ρ; ρ s:Seq Int m:Int out:Seq Int i:Int -- ρ r:Seq Int)
  locals { s m out i } {
    i m prim <
    [ s m  out s 40 i prim + prim seq-int.at prim seq-int.push  i 1 prim +  extract ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ ks:Seq Int sides:Seq Int pr:Seq Int qt:Seq Int -- ρ filled:Seq Int value:Int trades:Int)
  locals { ks sides pr qt } {
    ks sides pr qt  122 prim seq-int.empty zeros  0 loop
    locals { s } {
      s ks prim seq-int.len prim seq-int.empty 0 extract
      s 120 prim seq-int.at
      s 121 prim seq-int.at
    }
  };
```

### task: spreadsheet
```firth
: zeros
  (forall ρ; ρ n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim -  acc 0 prim seq-int.push  zeros ]
    [ acc ]
    if
  };

: mx
  (forall ρ; ρ x:Int y:Int -- ρ r:Int)
  locals { x y } { x y prim > [ x ] [ y ] if };

: tdiv
  (forall ρ; ρ a:Int b:Int -- ρ r:Int)
  locals { a b } {
    a 0 prim <  [ 0 a prim - ] [ a ] if
    b 0 prim <  [ 0 b prim - ] [ b ] if
    prim div
    locals { q } {
      a 0 prim <  b 0 prim >  prim and
      a 0 prim >  b 0 prim <  prim and
      prim or
      [ 0 q prim - ]
      [ q ]
      if
    }
  };

: mkpre
  (forall ρ; ρ w:Seq Int k:Int n:Int -- ρ r:Seq Int)
  locals { w k n } {
    k n prim <
    [ w  97 k prim +  w 96 k prim + prim seq-int.at  w k prim seq-int.at 0 prim =  [ 1 ] [ 0 ] if  prim +  prim seq-int.set
      k 1 prim + n
      mkpre ]
    [ w ]
    if
  };

: sfok
  (forall ρ; ρ w:Seq Int x:Int n:Int -- ρ r:Bool)
  locals { w x n } {
    x 0 prim <  x n prim >=  prim or
    [ true ]
    [ w x prim seq-int.at 1 prim = ]
    if
  };

: depok
  (forall ρ; ρ w:Seq Int kd:Int a:Int b:Int n:Int -- ρ r:Bool)
  locals { w kd a b n } {
    kd 0 prim =
    [ true ]
    [ kd 4 prim <
      [ w a n sfok  w b n sfok  prim and ]
      [ a b prim >
        [ true ]
        [ a 0 prim >  [ a ] [ 0 ] if
          b n 1 prim - prim <  [ b ] [ n 1 prim - ] if
          locals { lo hi } {
            lo hi prim >
            [ true ]
            [ w 97 hi prim + prim seq-int.at  w 96 lo prim + prim seq-int.at  prim -  0 prim = ]
            if
          } ]
        if ]
      if ]
    if
  };

: rmax
  (forall ρ; ρ w:Seq Int c:Int b:Int m:Int e:Int -- ρ m2:Int e2:Int)
  locals { w c b m e } {
    c b prim <=
    [ w c 1 prim + b
      m  w 32 c prim + prim seq-int.at  mx
      e  w 64 c prim + prim seq-int.at  prim +
      rmax ]
    [ m e ]
    if
  };

: rcnt
  (forall ρ; ρ w:Seq Int c:Int b:Int k:Int -- ρ r:Int)
  locals { w c b k } {
    c b prim <=
    [ w c 1 prim + b
      k
      w 64 c prim + prim seq-int.at 0 prim =  w 32 c prim + prim seq-int.at 0 prim >  prim and
      [ 1 ] [ 0 ] if  prim +
      rcnt ]
    [ k ]
    if
  };

: evalc
  (forall ρ; ρ w:Seq Int kd:Int a:Int b:Int n:Int -- ρ v:Int e:Int)
  locals { w kd a b n } {
    kd 0 prim =
    [ a 0 ]
    [ kd 4 prim <
      [ a 0 prim <  a n prim >=  prim or  b 0 prim <  prim or  b n prim >=  prim or
        [ 0 1 ]
        [ w 32 a prim + prim seq-int.at
          w 32 b prim + prim seq-int.at
          locals { va vb } {
            w 64 a prim + prim seq-int.at  w 64 b prim + prim seq-int.at  prim +  0 prim >
            [ 0 1 ]
            [ kd 1 prim =
              [ va vb prim + 0 ]
              [ kd 2 prim =
                [ va vb prim - 0 ]
                [ vb 0 prim =
                  [ 0 1 ]
                  [ va vb tdiv 0 ]
                  if ]
                if ]
              if ]
            if
          } ]
        if ]
      [ a b prim >  a 0 prim <  prim or  b n prim >=  prim or
        [ 0 1 ]
        [ kd 4 prim =
          [ w a 1 prim + b  w 32 a prim + prim seq-int.at  w 64 a prim + prim seq-int.at  rmax
            locals { m e } { e 0 prim >  [ 0 1 ] [ m 0 ] if } ]
          [ w a b 0 rcnt 0 ]
          if ]
        if ]
      if ]
    if
  };

: cellpass
  (forall ρ; ρ ks:Seq Int xs:Seq Int ys:Seq Int n:Int w:Seq Int i:Int -- ρ r:Seq Int)
  locals { ks xs ys n w i } {
    i n prim <
    [ ks xs ys n
      w i prim seq-int.at 0 prim =
      [ w ks i prim seq-int.at xs i prim seq-int.at ys i prim seq-int.at n depok
        [ w ks i prim seq-int.at xs i prim seq-int.at ys i prim seq-int.at n evalc
          locals { v e } {
            w 32 i prim + v prim seq-int.set
            64 i prim + e prim seq-int.set
            i 1 prim seq-int.set
          } ]
        [ w ]
        if ]
      [ w ]
      if
      i 1 prim +
      cellpass ]
    [ w ]
    if
  };

: passes
  (forall ρ; ρ ks:Seq Int xs:Seq Int ys:Seq Int n:Int w:Seq Int c:Int -- ρ r:Seq Int)
  locals { ks xs ys n w c } {
    c 0 prim >
    [ ks xs ys n  w 0 n mkpre  0 cellpass
      locals { w2 } { ks xs ys n w2 c 1 prim - passes } ]
    [ w ]
    if
  };

: outv
  (forall ρ; ρ w:Seq Int n:Int out:Seq Int i:Int -- ρ r:Seq Int)
  locals { w n out i } {
    i n prim <
    [ w n  out w 32 i prim + prim seq-int.at prim seq-int.push  i 1 prim +  outv ]
    [ out ]
    if
  };

: oute
  (forall ρ; ρ w:Seq Int n:Int out:Seq Bool i:Int -- ρ r:Seq Bool)
  locals { w n out i } {
    i n prim <
    [ w n
      out
      w i prim seq-int.at 0 prim =  w 64 i prim + prim seq-int.at 0 prim >  prim or
      prim seq-bool.push
      i 1 prim +
      oute ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ ks:Seq Int xs:Seq Int ys:Seq Int -- ρ vals:Seq Int errs:Seq Bool)
  locals { ks xs ys } {
    ks prim seq-int.len
    locals { n } {
      ks xs ys n  128 prim seq-int.empty zeros  n 1 prim +  passes
      locals { w } {
        w n prim seq-int.empty 0 outv
        w n prim seq-bool.empty 0 oute
      }
    }
  };
```

### task: elevator
```firth
: zeros
  (forall ρ; ρ n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim -  acc 0 prim seq-int.push  zeros ]
    [ acc ]
    if
  };

: addat
  (forall ρ; ρ xs:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { xs i d } { xs i xs i prim seq-int.at d prim + prim seq-int.set };

: bswap
  (forall ρ; ρ xs:Seq Int j:Int -- ρ r:Seq Int)
  locals { xs j } {
    xs j prim seq-int.at
    xs j 1 prim + prim seq-int.at
    locals { a b } {
      xs j b prim seq-int.set
      j 1 prim + a prim seq-int.set
    }
  };

: bpassa
  (forall ρ; ρ xs:Seq Int j:Int lim:Int -- ρ r:Seq Int)
  locals { xs j lim } {
    j lim prim <
    [ xs j prim seq-int.at  xs j 1 prim + prim seq-int.at  prim >
      [ xs j bswap ]
      [ xs ]
      if
      j 1 prim + lim
      bpassa ]
    [ xs ]
    if
  };

: bsorta
  (forall ρ; ρ xs:Seq Int lim:Int cnt:Int -- ρ r:Seq Int)
  locals { xs lim cnt } {
    cnt 0 prim >
    [ xs 0 lim bpassa  lim cnt 1 prim -  bsorta ]
    [ xs ]
    if
  };

: mkord
  (forall ρ; ρ tm:Seq Int out:Seq Int k:Int -- ρ r:Seq Int)
  locals { tm out k } {
    k tm prim seq-int.len prim <
    [ tm  out tm k prim seq-int.at 64 prim * k prim + prim seq-int.push  k 1 prim +  mkord ]
    [ out ]
    if
  };

: arrive
  (forall ρ; ρ s:Seq Int fl:Seq Int ord:Seq Int m:Int -- ρ r:Seq Int)
  locals { s fl ord m } {
    s 3 prim seq-int.at m prim <
    [ ord s 3 prim seq-int.at prim seq-int.at
      locals { key } {
        key 64 prim div  s 0 prim seq-int.at  prim <=
        [ fl key 64 prim mod prim seq-int.at
          locals { g } {
            s 8 g prim + 1 addat  3 1 addat
            g s 1 prim seq-int.at prim >
            [ 4 1 addat ]
            [ g s 1 prim seq-int.at prim <  [ 5 1 addat ] [ ] if ]
            if
            fl ord m arrive
          } ]
        [ s ]
        if
      } ]
    [ s ]
    if
  };

: serve
  (forall ρ; ρ tm:Seq Int fl:Seq Int m:Int s:Seq Int k:Int -- ρ r:Seq Int)
  locals { tm fl m s k } {
    k m prim <
    [ tm fl m
      fl k prim seq-int.at s 1 prim seq-int.at prim =
      tm k prim seq-int.at s 0 prim seq-int.at prim <=  prim and
      s 32 k prim + prim seq-int.at 0 prim =  prim and
      [ s 32 k prim + s 0 prim seq-int.at 1 prim + prim seq-int.set ]
      [ s ]
      if
      k 1 prim +
      serve ]
    [ s ]
    if
  };

: run
  (forall ρ; ρ tm:Seq Int fl:Seq Int ord:Seq Int m:Int s:Seq Int -- ρ r:Seq Int)
  locals { tm fl ord m s } {
    s 1 prim seq-int.at
    locals { f } {
      s 0 prim seq-int.at
      locals { t } {
        s 8 f prim + prim seq-int.at 0 prim >
        [ tm fl m s 0 serve
          locals { s1 } {
            tm fl ord m
            s1 8 f prim + 0 prim seq-int.set
            0 t 2 prim + prim seq-int.set
            cont
          } ]
        [ s 4 prim seq-int.at  s 5 prim seq-int.at  prim +  0 prim =
          [ s 3 prim seq-int.at m prim >=
            [ s ]
            [ tm fl ord m
              s 0 ord s 3 prim seq-int.at prim seq-int.at 64 prim div prim seq-int.set
              cont ]
            if ]
          [ s 2 prim seq-int.at 1 prim =
            [ s 4 prim seq-int.at 0 prim >  [ 1 ] [ -1 ] if ]
            [ s 5 prim seq-int.at 0 prim >  [ -1 ] [ 1 ] if ]
            if
            locals { nd } {
              tm fl ord m
              s 2 nd prim seq-int.set
              0 t 1 prim + prim seq-int.set
              6 1 addat
              nd 1 prim =
              [ 4 0 s 8 f prim + 1 prim + prim seq-int.at prim - addat
                1 f 1 prim + prim seq-int.set ]
              [ 5 0 s 8 f prim + 1 prim - prim seq-int.at prim - addat
                1 f 1 prim - prim seq-int.set ]
              if
              cont
            } ]
          if ]
        if
      }
    }
  };

: cont
  (forall ρ; ρ tm:Seq Int fl:Seq Int ord:Seq Int m:Int s:Seq Int -- ρ r:Seq Int)
  locals { tm fl ord m s } {
    tm fl ord m
    s fl ord m arrive
    run
  };

: outsv
  (forall ρ; ρ s:Seq Int m:Int out:Seq Int k:Int -- ρ r:Seq Int)
  locals { s m out k } {
    k m prim <
    [ s m  out s 32 k prim + prim seq-int.at 1 prim - prim seq-int.push  k 1 prim +  outsv ]
    [ out ]
    if
  };

: main
  (forall ρ; ρ tm:Seq Int fl:Seq Int -- ρ served:Seq Int end:Int moved:Int)
  locals { tm fl } {
    tm prim seq-int.len
    locals { m } {
      tm tm prim seq-int.empty 0 mkord  m 1 prim -  m 1 prim -  bsorta
      locals { ord } {
        tm fl ord m
        64 prim seq-int.empty zeros  2 1 prim seq-int.set  fl ord m arrive
        run
        locals { s } {
          s m prim seq-int.empty 0 outsv
          s 0 prim seq-int.at
          s 6 prim seq-int.at
        }
      }
    }
  };
```

### task: date-diff
```firth
: dfc
  (forall ρ; ρ y:Int m:Int d:Int -- ρ r:Int)
  locals { y m d } {
    m 2 prim <=  [ y 1 prim - ] [ y ] if
    locals { yy } {
      yy 400 prim div
      locals { era } {
        yy era 400 prim * prim -
        locals { yoe } {
          m 9 prim + 12 prim mod
          locals { mp } {
            era 146097 prim *
            yoe 365 prim *  yoe 4 prim div prim +  yoe 100 prim div prim -
            153 mp prim * 2 prim + 5 prim div prim +  d prim +  1 prim -
            prim +
            719468 prim -
          }
        }
      }
    }
  };

: main
  (forall ρ; ρ y1:Int m1:Int d1:Int y2:Int m2:Int d2:Int -- ρ days:Int wd:Int doy:Int)
  locals { y1 m1 d1 y2 m2 d2 } {
    y2 m2 d2 dfc
    locals { n2 } {
      n2  y1 m1 d1 dfc  prim -
      n2 3 prim + 7 prim mod
      n2  y2 1 1 dfc  prim -  1 prim +
    }
  };
```

### task: heap-alloc
```firth
: zeros
  (forall ρ; ρ n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { n acc } {
    n 0 prim >
    [ n 1 prim -  acc 0 prim seq-int.push  zeros ]
    [ acc ]
    if
  };

: addat
  (forall ρ; ρ xs:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { xs i d } { xs i xs i prim seq-int.at d prim + prim seq-int.set };

: findbest
  (forall ρ; ρ s:Seq Int v:Int k:Int cnt:Int bslot:Int bkey:Int -- ρ r:Int)
  locals { s v k cnt bslot bkey } {
    k cnt prim <
    [ s 64 k prim + prim seq-int.at
      locals { l } {
        l v prim >=
        l 2048 prim *  s k prim seq-int.at prim +  bkey prim <  prim and
        [ s v k 1 prim + cnt  k  l 2048 prim * s k prim seq-int.at prim +  findbest ]
        [ s v k 1 prim + cnt  bslot bkey  findbest ]
        if
      } ]
    [ bslot ]
    if
  };

: findl
  (forall ρ; ρ s:Seq Int s0:Int k:Int cnt:Int -- ρ r:Int)
  locals { s s0 k cnt } {
    k cnt prim <
    [ s 64 k prim + prim seq-int.at 0 prim >
      s k prim seq-int.at  s 64 k prim + prim seq-int.at prim +  s0 prim =  prim and
      [ k ]
      [ s s0 k 1 prim + cnt findl ]
      if ]
    [ -1 ]
    if
  };

: findr
  (forall ρ; ρ s:Seq Int e:Int k:Int cnt:Int -- ρ r:Int)
  locals { s e k cnt } {
    k cnt prim <
    [ s 64 k prim + prim seq-int.at 0 prim >
      s k prim seq-int.at e prim =  prim and
      [ k ]
      [ s e k 1 prim + cnt findr ]
      if ]
    [ -1 ]
    if
  };

: kill
  (forall ρ; ρ s:Seq Int k:Int -- ρ r:Seq Int)
  locals { s k } {
    k 0 prim >=
    [ s 64 k prim + 0 prim seq-int.set ]
    [ s ]
    if
  };

: lenof
  (forall ρ; ρ s:Seq Int k:Int -- ρ r:Int)
  locals { s k } {
    k 0 prim >=
    [ s 64 k prim + prim seq-int.at ]
    [ 0 ]
    if
  };

: valid
  (forall ρ; ρ s:Seq Int i:Int j:Int -- ρ r:Bool)
  locals { s i j } {
    j 0 prim >=
    [ j i prim <
      [ s 168 j prim + prim seq-int.at 0 prim > ]
      [ false ]
      if ]
    [ false ]
    if
  };

: doalloc
  (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ s2:Seq Int r:Int)
  locals { s i v } {
    s v 0 s 208 prim seq-int.at -1 1000000000 findbest
    locals { b } {
      b 0 prim <
      [ s -1 ]
      [ s b  s b prim seq-int.at v prim +  prim seq-int.set
        64 b prim + 0 v prim - addat
        128 i prim + s b prim seq-int.at prim seq-int.set
        168 i prim + v prim seq-int.set
        s b prim seq-int.at ]
      if
    }
  };

: dofree
  (forall ρ; ρ s:Seq Int i:Int j:Int -- ρ s2:Seq Int r:Int)
  locals { s i j } {
    s i j valid
    [ s 128 j prim + prim seq-int.at
      s 168 j prim + prim seq-int.at
      locals { s0 n } {
        s s0 0 s 208 prim seq-int.at findl
        s s0 n prim + 0 s 208 prim seq-int.at findr
        locals { lf rt } {
          lf 0 prim >=  [ s lf prim seq-int.at ] [ s0 ] if
          n  s lf lenof prim +  s rt lenof prim +
          locals { ns nl } {
            s 168 j prim + 0 prim seq-int.set  lf kill  rt kill
            s 208 prim seq-int.at
            locals { c } {
              c ns prim seq-int.set
              64 c prim + nl prim seq-int.set
              208 1 addat
              0
            }
          }
        }
      } ]
    [ s -1 ]
    if
  };

: hloop
  (forall ρ; ρ ks:Seq Int vs:Seq Int s:Seq Int out:Seq Int i:Int -- ρ s2:Seq Int out2:Seq Int)
  locals { ks vs s out i } {
    i ks prim seq-int.len prim <
    [ ks vs
      ks i prim seq-int.at 0 prim =
      [ s i vs i prim seq-int.at doalloc ]
      [ s i vs i prim seq-int.at dofree ]
      if
      locals { s2 r } {
        s2 out r prim seq-int.push i 1 prim +
        hloop
      } ]
    [ s out ]
    if
  };

: stats
  (forall ρ; ρ s:Seq Int k:Int cnt:Int nb:Int mxl:Int -- ρ a:Int b:Int)
  locals { s k cnt nb mxl } {
    k cnt prim <
    [ s 64 k prim + prim seq-int.at
      locals { l } {
        s k 1 prim + cnt
        nb  l 0 prim >  [ 1 ] [ 0 ] if  prim +
        mxl l prim >  [ mxl ] [ l ] if
        stats
      } ]
    [ nb mxl ]
    if
  };

: main
  (forall ρ; ρ size:Int ks:Seq Int vs:Seq Int -- ρ results:Seq Int blocks:Int largest:Int)
  locals { size ks vs } {
    ks vs
    216 prim seq-int.empty zeros  64 size prim seq-int.set  208 1 prim seq-int.set
    prim seq-int.empty 0 hloop
    locals { s out } {
      out
      s 0 s 208 prim seq-int.at 0 0 stats
    }
  };
```

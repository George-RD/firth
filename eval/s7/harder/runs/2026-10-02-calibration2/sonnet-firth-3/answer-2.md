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
      tm prim seq-int.empty 0 mkord  m 1 prim -  m 1 prim -  bsorta
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

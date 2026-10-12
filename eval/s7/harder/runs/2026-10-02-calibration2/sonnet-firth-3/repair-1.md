Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## elevator
Simulate one lift. Request k asks for the lift at floor floors[k], from time times[k] (the two sequences have the same length). At time 0 the lift is at floor 0, heading up. A request is waiting when its time is at most the current time and it has not been served. Repeat: if a waiting request is for the current floor, serve every waiting request for that floor at the current time (that is each one's serve time), and the stop takes 2 time units. Otherwise, if no request is waiting: stop if every request has been served, else move the clock forward to the earliest time of a request not yet served (the lift does not move). Otherwise, if no waiting request is beyond the current floor in the heading direction, reverse the heading; then move one floor in the heading direction, which takes 1 time unit. Return each request's serve time, the time when the simulation stops, and how many floors the lift moved in all. There are at most 30 requests, floors are 0 to 20, and times are 0 to 1,000, in any order.
Inputs on the stack, bottom to top: times: Seq Int, floors: Seq Int.
Outputs left on the stack, bottom to top: served: Seq Int, end: Int, moved: Int.
Example: stack [{ 0 0 3 }, { 3 1 2 }] becomes [{ 7 1 4 }, 9, 3].

Your answer:
```
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
On the example, the run failed:
code: firth.type.declared-effect-mismatch
word: main
at: line 160, column 3
message: `main` declares that it leaves ρ Seq Int Int Int but its body leaves ρ Seq Int Seq Int Int Int.
expected: ρ Seq Int Int Int
actual: ρ Seq Int Seq Int Int Int
hint: The body leaves 1 extra value on top (Int). Consume or `drop` it before the end of the word, or declare it in the signature's output. Here ρ stands for the caller's values that this word must leave untouched.

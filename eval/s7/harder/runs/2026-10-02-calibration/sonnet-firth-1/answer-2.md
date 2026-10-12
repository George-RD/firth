### task: rpn
```firth
: rpn-abs
  (forall ρ; ρ x:Int^many -- ρ r:Int^many)
  locals { x } { x 0 prim < [ 0 x prim - ] [ x ] if };

: rpn-tdiv
  (forall ρ; ρ a:Int^many b:Int^many -- ρ q:Int^many)
  locals { a b } {
    a rpn-abs b rpn-abs prim div
    a 0 prim < b 0 prim < prim or
    a 0 prim < b 0 prim < prim and prim not
    prim and
    [ 0 swap prim - ] [ ] if
  };

: rpn-op3
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 3 prim = [ a b prim * ] [ a b rpn-tdiv ] if
  };

: rpn-op2
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 2 prim = [ a b prim - ] [ a b k rpn-op3 ] if
  };

: rpn-op
  (forall ρ; ρ a:Int^many b:Int^many k:Int^many -- ρ r:Int^many)
  locals { a b k } {
    k 1 prim = [ a b prim + ] [ a b k rpn-op2 ] if
  };

: rpn-push
  (forall ρ; ρ buf:Seq Int^many sp:Int^many v:Int^many -- ρ buf2:Seq Int^many sp2:Int^many)
  locals { buf sp v } {
    sp buf prim seq-int.len prim <
    [ buf sp v prim seq-int.set sp 1 prim + ]
    [ buf v prim seq-int.push sp 1 prim + ]
    if
  };

: rpn-dup
  (forall ρ; ρ buf:Seq Int^many sp:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp } {
    sp 1 prim <
    [ buf sp 1 ]
    [ buf sp buf sp 1 prim - prim seq-int.at rpn-push 0 ]
    if
  };

: rpn-bin2
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k } {
    k 4 prim =
    buf sp 1 prim - prim seq-int.at 0 prim =
    prim and
    [ buf sp 2 ]
    [ buf sp 2 prim -
      buf sp 2 prim - prim seq-int.at
      buf sp 1 prim - prim seq-int.at
      k rpn-op
      rpn-push 0 ]
    if
  };

: rpn-bin
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k } {
    sp 2 prim <
    [ buf sp 1 ]
    [ buf sp k rpn-bin2 ]
    if
  };

: rpn-tok2
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k } {
    k 5 prim =
    [ buf sp rpn-dup ]
    [ buf sp k rpn-bin ]
    if
  };

: rpn-tok
  (forall ρ; ρ buf:Seq Int^many sp:Int^many k:Int^many v:Int^many
    -- ρ buf2:Seq Int^many sp2:Int^many st:Int^many)
  locals { buf sp k v } {
    k 0 prim =
    [ buf sp v rpn-push 0 ]
    [ buf sp k rpn-tok2 ]
    if
  };

: rpn-step
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many
    -- ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many flag:Bool^many)
  locals { kinds vals i buf sp st } {
    st 0 prim =
    i kinds prim seq-int.len prim <
    prim and
    [ kinds vals i 1 prim +
      buf sp kinds i prim seq-int.at vals i prim seq-int.at rpn-tok
      true ]
    [ kinds vals i buf sp st false ]
    if
  };

: rpn-loop
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many
    -- ρ kinds:Seq Int^many vals:Seq Int^many i:Int^many buf:Seq Int^many sp:Int^many st:Int^many)
  rpn-step [ rpn-loop ] [ ] if ;

: rpn-fin2
  (forall ρ; ρ buf:Seq Int^many sp:Int^many -- ρ result:Int^many status:Int^many)
  locals { buf sp } {
    sp 1 prim =
    [ buf 0 prim seq-int.at 0 ]
    [ 0 3 ]
    if
  };

: rpn-fin
  (forall ρ; ρ buf:Seq Int^many sp:Int^many st:Int^many -- ρ result:Int^many status:Int^many)
  locals { buf sp st } {
    st 0 prim =
    [ buf sp rpn-fin2 ]
    [ 0 st ]
    if
  };

: main
  (forall ρ; ρ kinds:Seq Int^many vals:Seq Int^many -- ρ result:Int^many status:Int^many)
  0 prim seq-int.empty 0 0 rpn-loop
  locals { ks vs i buf sp st } { buf sp st rpn-fin } ;
```

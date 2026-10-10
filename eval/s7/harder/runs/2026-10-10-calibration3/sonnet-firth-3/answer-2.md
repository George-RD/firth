### task: mini-cpu
```firth
: b2i (forall ρ; ρ f:Bool -- ρ i:Int) [ 1 ] [ 0 ] if;
: sget (forall ρ; ρ s:Seq Int i:Int -- ρ v:Int) prim seq-int.at;
: sput (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set;
: ap (forall ρ; ρ s:Seq Int q:Seq Int i:Int -- ρ r:Seq Int)
  locals { s q i } { s q i sget prim seq-int.push };

: pad (forall ρ; ρ s:Seq Int total:Int -- ρ r:Seq Int)
  locals { s total } {
    s prim seq-int.len total prim <
    [ s 0 prim seq-int.push total pad ]
    [ s ] if };

: app (forall ρ; ρ a:Seq Int b:Seq Int i:Int -- ρ r:Seq Int)
  locals { a b i } {
    i b prim seq-int.len prim <
    [ a b i sget prim seq-int.push b i 1 prim + app ]
    [ a ] if };

: sl (forall ρ; ρ s:Seq Int from:Int to:Int acc:Seq Int -- ρ r:Seq Int)
  locals { s from to acc } {
    from to prim <
    [ s from 1 prim + to acc s from ap sl ]
    [ acc ] if };

: inter (forall ρ; ρ o:Seq Int a:Seq Int b:Seq Int c:Seq Int i:Int n:Int acc:Seq Int -- ρ r:Seq Int)
  locals { o a b c i n acc } {
    i n prim <
    [ o a b c i 1 prim + n acc o i ap a i ap b i ap c i ap inter ]
    [ acc ] if };

: inc (forall ρ; ρ s:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { s i d } { s i s i sget d prim + sput };
: adv (forall ρ; ρ s:Seq Int -- ρ r:Seq Int) 12 1 inc 11 1 inc;
: fault (forall ρ; ρ s:Seq Int k:Int -- ρ r:Seq Int)
  locals { s k } { s 13 k sput };
: jmp (forall ρ; ρ s:Seq Int t:Int -- ρ r:Seq Int)
  locals { s t } { s 11 t sput 12 1 inc };
: cj (forall ρ; ρ s:Seq Int t:Int f:Bool -- ρ r:Seq Int)
  locals { s t f } { f [ s t jmp ] [ s adv ] if };

: wrap (forall ρ; ρ x:Int -- ρ w:Int)
  2147483648 prim + 4294967296 prim mod 2147483648 prim -;
: neg (forall ρ; ρ x:Int -- ρ r:Int) 0 swap prim -;
: abs (forall ρ; ρ x:Int -- ρ r:Int) dup 0 prim < [ neg ] [ ] if;
: tdiv (forall ρ; ρ a:Int b:Int -- ρ q:Int)
  locals { a b } {
    a abs b abs prim div
    a 0 prim < b2i b 0 prim < b2i prim =
    [ ] [ neg ] if };
: pw (forall ρ; ρ acc:Int c:Int -- ρ r:Int)
  locals { acc c } {
    c 0 prim >
    [ acc 2 prim * c 1 prim - pw ]
    [ acc ] if };
: pow2 (forall ρ; ρ c:Int -- ρ r:Int) 1 swap pw;

: flags (forall ρ; ρ s:Seq Int w:Int t:Int -- ρ r:Seq Int)
  locals { s w t } {
    s 8 w 0 prim = b2i sput
    9 w 0 prim < b2i sput
    10 w t prim = prim not b2i sput };
: alu (forall ρ; ρ s:Seq Int a:Int t:Int -- ρ r:Seq Int)
  locals { s a t } {
    t wrap locals { w } { s a w sput w t flags } };
: cmp (forall ρ; ρ s:Seq Int t:Int -- ρ r:Seq Int)
  locals { s t } { s t wrap t flags };

: dsp2 (forall ρ; ρ env:Seq Int s:Seq Int op:Int a:Int b:Int c:Int -- ρ r:Seq Int)
  locals { env s op a b c } {
    op 18 prim =
    [ s b s 9 sget s 10 sget prim = cj ]
    [ op 19 prim =
      [ s 14 sget 16 prim >=
        [ s 4 fault ]
        [ s 84 s 14 sget prim + s a sget sput 14 1 inc adv ] if ]
      [ op 20 prim =
        [ s 14 sget 0 prim =
          [ s 5 fault ]
          [ s a s 83 s 14 sget prim + sget sput 14 -1 inc adv ] if ]
        [ op 21 prim =
          [ s 15 sget 8 prim >=
            [ s 4 fault ]
            [ s 100 s 15 sget prim + s 11 sget 1 prim + sput 15 1 inc b jmp ] if ]
          [ op 22 prim =
            [ s 15 sget 0 prim =
              [ s 5 fault ]
              [ s 11 s 99 s 15 sget prim + sget sput 15 -1 inc 12 1 inc ] if ]
            [ op 23 prim =
              [ s 16 sget env 296 sget prim >=
                [ s 7 fault ]
                [ s a env 256 s 16 sget prim + sget sput 16 1 inc adv ] if ]
              [ op 24 prim =
                [ s 108 s 17 sget prim + s a sget sput 17 1 inc adv ]
                [ s ] if ] if ] if ] if ] if ] if ] if };

: dsp1 (forall ρ; ρ env:Seq Int s:Seq Int op:Int a:Int b:Int c:Int -- ρ r:Seq Int)
  locals { env s op a b c } {
    op 9 prim =
    [ s a s b sget c pow2 prim * alu adv ]
    [ op 10 prim =
      [ s a s b sget c pow2 prim div alu adv ]
      [ op 11 prim =
        [ s s b sget s c sget prim - cmp adv ]
        [ op 12 prim =
          [ s b sget c prim + locals { ad } {
              ad 0 prim < ad 63 prim > prim or
              [ s 6 fault ]
              [ s a s 20 ad prim + sget sput adv ] if } ]
          [ op 13 prim =
            [ s b sget c prim + locals { ad } {
                ad 0 prim < ad 63 prim > prim or
                [ s 6 fault ]
                [ s 20 ad prim + s a sget sput adv ] if } ]
            [ op 14 prim =
              [ s b jmp ]
              [ op 15 prim =
                [ s b s 8 sget 1 prim = cj ]
                [ op 16 prim =
                  [ s b s 8 sget 0 prim = cj ]
                  [ op 17 prim =
                    [ s b s 9 sget s 10 sget prim = prim not cj ]
                    [ env s op a b c dsp2 ] if ] if ] if ] if ] if ] if ] if ] if ] if };

: dsp0 (forall ρ; ρ env:Seq Int s:Seq Int op:Int a:Int b:Int c:Int -- ρ r:Seq Int)
  locals { env s op a b c } {
    op 0 prim =
    [ s 13 0 sput 12 1 inc ]
    [ op 1 prim =
      [ s a b sput adv ]
      [ op 2 prim =
        [ s a s b sget sput adv ]
        [ op 3 prim =
          [ s a s b sget s c sget prim + alu adv ]
          [ op 4 prim =
            [ s a s b sget s c sget prim - alu adv ]
            [ op 5 prim =
              [ s a s b sget s c sget prim * alu adv ]
              [ op 6 prim =
                [ s c sget 0 prim =
                  [ s 3 fault ]
                  [ s a s b sget s c sget tdiv alu adv ] if ]
                [ op 7 prim =
                  [ s c sget 0 prim =
                    [ s 3 fault ]
                    [ s a s b sget s b sget s c sget tdiv s c sget prim * prim - alu adv ] if ]
                  [ op 8 prim =
                    [ s a 0 s b sget prim - alu adv ]
                    [ env s op a b c dsp1 ] if ] if ] if ] if ] if ] if ] if ] if ] if };

: exec (forall ρ; ρ env:Seq Int s:Seq Int -- ρ r:Seq Int)
  locals { env s } {
    s 11 sget 4 prim * locals { base } {
      env s env base sget env base 1 prim + sget
      env base 2 prim + sget env base 3 prim + sget dsp0 } };

: step (forall ρ; ρ env:Seq Int s:Seq Int -- ρ r:Seq Int)
  locals { env s } {
    s 12 sget 300 prim >=
    [ s 13 1 sput ]
    [ s 11 sget 0 prim < s 11 sget env 297 sget prim >= prim or
      [ s 13 2 sput ]
      [ env s exec ] if ] if };

: run (forall ρ; ρ env:Seq Int s:Seq Int -- ρ r:Seq Int)
  locals { env s } {
    s 13 sget -1 prim =
    [ env env s step run ]
    [ s ] if };

: main
  (forall ρ; ρ ops:Seq Int fa:Seq Int fb:Seq Int fc:Seq Int regs:Seq Int mem:Seq Int inp:Seq Int
   -- ρ out:Seq Int status:Int executed:Int pc:Int rs:Seq Int fm:Seq Int fl:Seq Bool)
  locals { ops fa fb fc rg mem inp } {
    ops fa fb fc 0 ops prim seq-int.len prim seq-int.empty inter
    256 pad inp 0 app 296 pad
    inp prim seq-int.len prim seq-int.push
    ops prim seq-int.len prim seq-int.push
    rg { 0 0 0 } 0 app { 0 0 -1 0 0 0 0 } 0 app { 0 0 } 0 app mem 0 app 408 pad
    run
    locals { fin } {
      fin 108 fin 17 sget 108 prim + prim seq-int.empty sl
      fin 13 sget fin 12 sget fin 11 sget
      fin 0 8 prim seq-int.empty sl
      fin 20 84 prim seq-int.empty sl
      prim seq-bool.empty
      fin 8 sget 1 prim = prim seq-bool.push
      fin 9 sget 1 prim = prim seq-bool.push
      fin 10 sget 1 prim = prim seq-bool.push } };
```

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
                    [ env s op a b c dsp1 ] if ] if ] if ] if ] if ] if ] if ] if };

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
NOTE: written without being able to run the checker; the `Seq Int` spelling in stack effects is a guess, and state is packed into one sequence because Firth has no records or mutable variables.

### task: stacker
```firth
: b2i (forall ρ; ρ f:Bool -- ρ i:Int) [ 1 ] [ 0 ] if;
: sget (forall ρ; ρ s:Seq Int i:Int -- ρ v:Int) prim seq-int.at;
: sput (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set;
: inc (forall ρ; ρ s:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { s i d } { s i s i sget d prim + sput };

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

: tbl (forall ρ; ρ -- ρ t:Seq Int)
  { 0 2 1 2 2 2 3 2   2 0 2 1 2 2 2 3   0 1 1 1 2 1 3 1   1 0 1 1 1 2 1 3
    1 1 2 1 1 2 2 2   1 1 2 1 1 2 2 2   1 1 2 1 1 2 2 2   1 1 2 1 1 2 2 2
    0 2 1 2 2 2 1 3   1 1 1 2 1 3 2 2   0 2 1 2 2 2 1 1   1 1 1 2 1 3 0 2
    0 2 1 2 1 3 2 3   1 3 1 2 2 2 2 1   0 1 1 1 1 2 2 2   0 3 0 2 1 2 1 1
    0 3 1 3 1 2 2 2   2 3 2 2 1 2 1 1   0 2 1 2 1 1 2 1   1 3 1 2 0 2 0 1
    0 2 1 2 2 2 2 3   1 3 1 2 1 1 2 1   0 1 0 2 1 2 2 2   0 3 1 3 1 2 1 1
    0 3 0 2 1 2 2 2   1 1 1 2 1 3 2 3   0 2 1 2 2 2 2 1   0 1 1 1 1 2 1 3 };

: sqok (forall ρ; ρ env:Seq Int st:Seq Int i:Int x:Int y:Int -- ρ ok:Bool)
  locals { env st i x y } {
    x env i sget prim + locals { px } {
    y env i 1 prim + sget prim + locals { py } {
      px 0 prim >= px st 15 sget prim < prim and
      py 0 prim >= prim and py st 16 sget prim < prim and
      [ st 20 py st 15 sget prim * px prim + prim + sget 0 prim = ]
      [ 1 0 prim = ] if } } };

: fl (forall ρ; ρ env:Seq Int st:Seq Int base:Int x:Int y:Int s:Int cnt:Int -- ρ n:Int)
  locals { env st base x y s cnt } {
    s 4 prim <
    [ env st base x y s 1 prim + cnt
      env st base s 2 prim * prim + x y sqok b2i prim + fl ]
    [ cnt ] if };

: fits (forall ρ; ρ env:Seq Int st:Seq Int kind:Int rot:Int x:Int y:Int -- ρ ok:Bool)
  locals { env st kind rot x y } {
    env st kind 4 prim * rot prim + 8 prim * x y 0 0 fl 4 prim = };

: curfits (forall ρ; ρ env:Seq Int st:Seq Int rot:Int x:Int y:Int -- ρ ok:Bool)
  locals { env st rot x y } { env st st 1 sget rot x y fits };

: tm (forall ρ; ρ env:Seq Int st:Seq Int dx:Int dy:Int -- ρ r:Seq Int)
  locals { env st dx dy } {
    env st st 2 sget st 3 sget dx prim + st 4 sget dy prim + curfits
    [ st 3 st 3 sget dx prim + sput 4 st 4 sget dy prim + sput ]
    [ st ] if };

: spawn (forall ρ; ρ env:Seq Int st:Seq Int kind:Int -- ρ r:Seq Int)
  locals { env st kind } {
    st 0 1 sput 1 kind sput 2 0 sput 6 1 sput
    3 st 15 sget 4 prim - 2 prim div sput
    4 st 16 sget 4 prim - sput
    locals { s2 } {
      env s2 s2 2 sget s2 3 sget s2 4 sget curfits
      [ s2 ] [ s2 14 2 sput ] if } };

: next (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    st 12 sget env 224 sget prim >=
    [ st 14 0 sput ]
    [ env st 12 1 inc env 230 st 12 sget prim + sget spawn ] if };

: hold (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    st 6 sget 0 prim =
    [ st ]
    [ st 5 sget -1 prim =
      [ env st 5 st 1 sget sput next 6 0 sput ]
      [ env st 5 st 1 sget sput st 5 sget spawn 6 0 sput ] if ] if };

: rt (forall ρ; ρ env:Seq Int st:Seq Int nr:Int k:Int -- ρ r:Seq Int)
  locals { env st nr k } {
    k 6 prim >=
    [ st ]
    [ { 0 -1 1 0 -2 2 } k sget locals { ox } {
      { 0 0 0 1 0 0 } k sget locals { oy } {
        env st nr st 3 sget ox prim + st 4 sget oy prim + curfits
        [ st 2 nr sput 3 st 3 sget ox prim + sput 4 st 4 sget oy prim + sput ]
        [ env st nr k 1 prim + rt ] if } } ] if };

: dd (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    env st st 2 sget st 3 sget st 4 sget 1 prim - curfits
    [ env st 4 -1 inc dd ]
    [ st ] if };

: lk (forall ρ; ρ env:Seq Int st:Seq Int s:Int -- ρ r:Seq Int)
  locals { env st s } {
    s 4 prim <
    [ st 1 sget 4 prim * st 2 sget prim + 8 prim * s 2 prim * prim + locals { idx } {
        env
        st 20 st 4 sget env idx 1 prim + sget prim + st 15 sget prim * prim +
           st 3 sget env idx sget prim + prim + 1 sput
        s 1 prim + lk } ]
    [ st ] if };

: rsum (forall ρ; ρ st:Seq Int r:Int x:Int acc:Int -- ρ n:Int)
  locals { st r x acc } {
    x st 15 sget prim <
    [ st r x 1 prim + acc st 20 r st 15 sget prim * prim + x prim + sget prim + rsum ]
    [ acc ] if };

: copyrow (forall ρ; ρ st:Seq Int dst:Int src:Int x:Int -- ρ r:Seq Int)
  locals { st dst src x } {
    x st 15 sget prim <
    [ st 20 dst st 15 sget prim * prim + x prim +
         st 20 src st 15 sget prim * prim + x prim + sget sput
      dst src x 1 prim + copyrow ]
    [ st ] if };

: zrow (forall ρ; ρ st:Seq Int dst:Int x:Int -- ρ r:Seq Int)
  locals { st dst x } {
    x st 15 sget prim <
    [ st 20 dst st 15 sget prim * prim + x prim + 0 sput dst x 1 prim + zrow ]
    [ st ] if };

: shiftl (forall ρ; ρ st:Seq Int t:Int -- ρ r:Seq Int)
  locals { st t } {
    t st 16 sget 1 prim - prim <
    [ st t t 1 prim + 0 copyrow t 1 prim + shiftl ]
    [ st t 0 zrow ] if };

: clr (forall ρ; ρ st:Seq Int r:Int -- ρ s:Seq Int)
  locals { st r } {
    r st 16 sget prim >=
    [ st ]
    [ st r 0 0 rsum st 15 sget prim =
      [ st r shiftl 18 1 inc r clr ]
      [ st r 1 prim + clr ] if ] if };

: score (forall ρ; ρ st:Seq Int -- ρ r:Seq Int)
  locals { st } {
    st 18 sget locals { k } {
      k 0 prim >
      [ st 7 st 7 sget
          k 4 prim =
          [ st 10 sget 4 prim = [ 1200 ] [ 800 ] if ]
          [ k 200 prim * 100 prim - ] if
          st 11 sget 50 prim * prim +
          st 8 sget 10 prim div 1 prim + prim *
          prim + sput
        8 st 8 sget k prim + sput
        10 k sput
        11 st 11 sget 1 prim + sput ]
      [ st 11 0 sput ] if } };

: lock (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    env st 0 lk 0 0 sput 9 st 9 sget 1 prim + sput 18 0 sput 0 clr score };

: cmd (forall ρ; ρ env:Seq Int st:Seq Int c:Int -- ρ r:Seq Int)
  locals { env st c } {
    c 0 prim = [ env env st dd lock ]
    [ c 1 prim = [ env st -1 0 tm ]
      [ c 2 prim = [ env st 1 0 tm ]
        [ c 5 prim = [ env st 0 -1 tm ]
          [ c 3 prim = [ env st st 2 sget 1 prim + 4 prim mod 0 rt ]
            [ c 4 prim = [ env st st 2 sget 3 prim + 4 prim mod 0 rt ]
              [ c 6 prim = [ env st hold ]
                [ st ] if ] if ] if ] if ] if ] if ] if };

: run (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    st 14 sget -1 prim =
    [ st 0 sget 0 prim =
      [ env env st next run ]
      [ st 13 sget env 225 sget prim >=
        [ st 14 1 sput ]
        [ env env st 13 1 inc env 260 st 13 sget prim + sget cmd run ] if ] if ]
    [ st ] if };

: colh (forall ρ; ρ st:Seq Int x:Int r:Int -- ρ h:Int)
  locals { st x r } {
    r 0 prim <
    [ 0 ]
    [ st 20 r st 15 sget prim * prim + x prim + sget 0 prim =
      [ st x r 1 prim - colh ]
      [ r 1 prim + ] if ] if };

: hs (forall ρ; ρ st:Seq Int x:Int acc:Seq Int -- ρ r:Seq Int)
  locals { st x acc } {
    x st 15 sget prim <
    [ st x 1 prim + acc st x st 16 sget 1 prim - colh prim seq-int.push hs ]
    [ acc ] if };

: main
  (forall ρ; ρ w:Int h:Int q:Seq Int mv:Seq Int
   -- ρ heights:Seq Int score:Int rows:Int locks:Int status:Int held:Int)
  locals { w h q mv } {
    tbl q prim seq-int.len prim seq-int.push mv prim seq-int.len prim seq-int.push
    230 pad q 0 app 260 pad mv 0 app
    { 0 0 0 0 0 -1 0 0 0 0 0 0 0 0 -1 } w prim seq-int.push h prim seq-int.push
    0 prim seq-int.push 0 prim seq-int.push 0 prim seq-int.push
    w h prim * 20 prim + pad
    run
    locals { f } {
      f 0 prim seq-int.empty hs
      f 7 sget f 8 sget f 9 sget f 14 sget f 5 sget } };
```
NOTE: written without being able to run the checker; the `Seq Int` spelling in stack effects is a guess, and state is packed into one sequence because Firth has no records or mutable variables.

### task: bank-days
```firth
: b2i (forall ρ; ρ f:Bool -- ρ i:Int) [ 1 ] [ 0 ] if;
: sget (forall ρ; ρ s:Seq Int i:Int -- ρ v:Int) prim seq-int.at;
: sput (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set;
: ap (forall ρ; ρ s:Seq Int q:Seq Int i:Int -- ρ r:Seq Int)
  locals { s q i } { s q i sget prim seq-int.push };
: inc (forall ρ; ρ s:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { s i d } { s i s i sget d prim + sput };

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

: mdays (forall ρ; ρ y:Int m:Int -- ρ d:Int)
  locals { y m } {
    m 2 prim =
    [ y 4 prim mod 0 prim = y 100 prim mod 0 prim = prim not prim and
      y 400 prim mod 0 prim = prim or
      [ 29 ] [ 28 ] if ]
    [ m 4 prim = m 6 prim = prim or m 9 prim = prim or m 11 prim = prim or
      [ 30 ] [ 31 ] if ] if };

: pay (forall ρ; ρ st:Seq Int f:Int t:Int amt:Int k:Int -- ρ r:Seq Int ok:Bool)
  locals { st f t amt k } {
    k 3 prim = f t prim = prim and
    st f sget amt prim - st 42 f prim + sget prim + 0 prim < prim or
    [ st 1 0 prim = ]
    [ st f st f sget amt prim - sput
      locals { s1 } {
        k 3 prim =
        [ s1 t s1 t sget amt prim + sput ]
        [ s1 ] if
        1 1 prim = } ] if };

: txone (forall ρ; ρ env:Seq Int st:Seq Int k:Int -- ρ r:Seq Int)
  locals { env st k } {
    env k sget st 37 sget prim =
    [ env 60 k prim + sget locals { kind } {
      env 120 k prim + sget locals { a } {
      env 180 k prim + sget locals { b } {
      env 240 k prim + sget locals { m } {
        kind 1 prim =
        [ st a st a sget m prim + sput ]
        [ st a b m kind pay [ ] [ 30 1 inc ] if ] if } } } } ]
    [ st ] if };

: txl (forall ρ; ρ env:Seq Int st:Seq Int k:Int -- ρ r:Seq Int)
  locals { env st k } {
    k env 300 sget prim <
    [ env env st k txone k 1 prim + txl ]
    [ st ] if };

: sone (forall ρ; ρ env:Seq Int st:Seq Int j:Int -- ρ r:Seq Int)
  locals { env st j } {
    st 24 j prim + sget 0 prim =
    [ env 302 j prim + sget locals { dom } {
      st 34 sget st 35 sget mdays locals { md } {
        st 36 sget dom md prim < [ dom ] [ md ] if prim =
        [ st env 308 j prim + sget env 314 j prim + sget env 320 j prim + sget 3 pay
          [ 18 j prim + 0 sput ]
          [ 30 1 inc 18 j prim + st 18 j prim + sget 1 prim + sput
            st 18 j prim + sget 1 prim + 2 prim >= [ 24 j prim + 1 sput ] [ ] if ] if ]
        [ st ] if } } ]
    [ st ] if };

: sol (forall ρ; ρ env:Seq Int st:Seq Int j:Int -- ρ r:Seq Int)
  locals { env st j } {
    j env 301 sget prim <
    [ env env st j sone j 1 prim + sol ]
    [ st ] if };

: int1 (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } {
    st i sget locals { bal } {
      bal 0 prim >
      [ st 6 i prim + st 6 i prim + sget bal st 40 sget prim * prim + sput ]
      [ bal 0 prim <
        [ st 6 i prim + st 6 i prim + sget bal st 41 sget prim * prim + sput
          12 i prim + 1 sput ]
        [ st ] if ] if } };

: intl (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } {
    i st 39 sget prim <
    [ st i int1 i 1 prim + intl ]
    [ st ] if };

: postacc (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } {
    st 6 i prim + sget locals { s } {
      s 0 prim >=
      [ s 1000000 prim div locals { p } {
          st i st i sget p prim + sput 6 i prim + 0 sput 31 st 31 sget p prim + sput } ]
      [ 0 s prim - 1000000 prim div locals { p } {
          st i st i sget p prim - sput 6 i prim + 0 sput 32 st 32 sget p prim + sput } ] if } };

: fee (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } {
    st 12 i prim + sget 1 prim =
    [ st i st i sget 1000 prim - sput 12 i prim + 0 sput 33 st 33 sget 1000 prim + sput ]
    [ st ] if };

: post (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } {
    i st 39 sget prim <
    [ st i postacc i fee i 1 prim + post ]
    [ st ] if };

: advd (forall ρ; ρ st:Seq Int -- ρ r:Seq Int)
  locals { st } {
    st 36 sget 1 prim + locals { d } {
      d st 34 sget st 35 sget mdays prim >
      [ st 36 1 sput 35 st 35 sget 1 prim + sput
        locals { s5 } {
          s5 35 sget 12 prim >
          [ s5 35 1 sput 34 s5 34 sget 1 prim + sput ]
          [ s5 ] if } ]
      [ st 36 d sput ] if } };

: day (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    env env st 0 txl 0 sol 0 intl
    locals { s3 } {
      s3 36 sget s3 34 sget s3 35 sget mdays prim =
      [ s3 0 post ] [ s3 ] if
      advd 37 1 inc } };

: run (forall ρ; ρ env:Seq Int st:Seq Int -- ρ r:Seq Int)
  locals { env st } {
    st 37 sget st 38 sget prim <
    [ env env st day run ]
    [ st ] if };

: cb (forall ρ; ρ st:Seq Int j:Int m:Int acc:Seq Bool -- ρ r:Seq Bool)
  locals { st j m acc } {
    j m prim <
    [ st j 1 prim + m acc st 24 j prim + sget 1 prim = prim seq-bool.push cb ]
    [ acc ] if };

: main
  (forall ρ; ρ yr:Int mo:Int dy:Int ds:Int bal:Seq Int lim:Seq Int cr:Int db:Int
     td:Seq Int tk:Seq Int ta:Seq Int tr:Seq Int tm:Seq Int
     sdm:Seq Int sfr:Seq Int sto:Seq Int sam:Seq Int
   -- ρ final:Seq Int rejected:Int cancelled:Seq Bool added:Int taken:Int fees:Int)
  locals { yr mo dy ds bal lim cr db td tk ta tr tm sdm sfr sto sam } {
    prim seq-int.empty td 0 app 60 pad tk 0 app 120 pad ta 0 app 180 pad
    tr 0 app 240 pad tm 0 app 300 pad
    td prim seq-int.len prim seq-int.push sdm prim seq-int.len prim seq-int.push
    sdm 0 app 308 pad sfr 0 app 314 pad sto 0 app 320 pad sam 0 app 326 pad
    prim seq-int.empty bal 0 app 34 pad
    yr prim seq-int.push mo prim seq-int.push dy prim seq-int.push 0 prim seq-int.push
    ds prim seq-int.push bal prim seq-int.len prim seq-int.push
    cr prim seq-int.push db prim seq-int.push
    lim 0 app 48 pad
    run
    locals { f } {
      f 0 f 39 sget prim seq-int.empty sl
      f 30 sget
      f 0 sdm prim seq-int.len prim seq-bool.empty cb
      f 31 sget f 32 sget f 33 sget } };
```
NOTE: written without being able to run the checker; the `Seq Int` spelling in stack effects is a guess, and state is packed into one sequence because Firth has no records or mutable variables.

### task: formula-sheet
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

: eb (forall ρ; ρ cv:Seq Int i:Int n:Int acc:Seq Bool -- ρ r:Seq Bool)
  locals { cv i n acc } {
    i n prim <
    [ cv i 1 prim + n acc cv 20 i prim + sget 1 prim = prim seq-bool.push eb ]
    [ acc ] if };

: neg (forall ρ; ρ x:Int -- ρ r:Int) 0 swap prim -;
: abs (forall ρ; ρ x:Int -- ρ r:Int) dup 0 prim < [ neg ] [ ] if;
: tdiv (forall ρ; ρ a:Int b:Int -- ρ q:Int)
  locals { a b } {
    a abs b abs prim div
    a 0 prim < b2i b 0 prim < b2i prim =
    [ ] [ neg ] if };

: capchk (forall ρ; ρ r:Int e:Int -- ρ r2:Int e2:Int)
  locals { r e } {
    e 0 prim =
    [ r abs 1000000000 prim > [ 0 1 ] [ r 0 ] if ]
    [ 0 1 ] if };

: bin2 (forall ρ; ρ x:Int a:Int b:Int ae:Int be:Int -- ρ r:Int e:Int)
  locals { x a b ae be } {
    ae be prim + 0 prim >
    [ 0 1 ]
    [ x 1 prim = [ a b prim + 0 capchk ]
      [ x 2 prim = [ a b prim - 0 capchk ]
        [ x 3 prim = [ a b prim * 0 capchk ]
          [ x 4 prim = [ b 0 prim = [ 0 1 ] [ a b tdiv 0 capchk ] if ]
            [ x 5 prim = [ a b prim < b2i 0 capchk ]
              [ a b prim = b2i 0 capchk ] if ] if ] if ] if ] if ] if };

: push (forall ρ; ρ s:Seq Int sp:Int v:Int e:Int -- ρ s2:Seq Int sp2:Int)
  locals { s sp v e } {
    s sp 2 prim * v sput sp 2 prim * 1 prim + e sput sp 1 prim + };

: store (forall ρ; ρ s:Seq Int i:Int r:Int e:Int -- ρ s2:Seq Int)
  locals { s i r e } { s i r sput i 1 prim + e sput };

: evop (forall ρ; ρ stk:Seq Int sp:Int x:Int -- ρ s2:Seq Int sp2:Int)
  locals { stk sp x } {
    x 7 prim = [ 3 ] [ x 8 prim = [ 1 ] [ 2 ] if ] if
    locals { ar } {
      sp ar prim <
      [ stk -100 ]
      [ sp ar prim - 2 prim * locals { i0 } {
          stk i0
          ar 1 prim =
          [ 0 stk i0 sget prim - stk i0 1 prim + sget capchk ]
          [ ar 2 prim =
            [ x stk i0 sget stk i0 2 prim + sget stk i0 1 prim + sget stk i0 3 prim + sget bin2 ]
            [ stk i0 1 prim + sget 0 prim =
              [ stk i0 sget 0 prim =
                [ stk i0 4 prim + sget stk i0 5 prim + sget ]
                [ stk i0 2 prim + sget stk i0 3 prim + sget ] if ]
              [ 0 1 ] if ] if ] if
          store sp ar prim - 1 prim + } ] if } };

: fnl (forall ρ; ρ cv:Seq Int x:Int i:Int z:Int acc:Int ec:Int -- ρ acc2:Int ec2:Int)
  locals { cv x i z acc ec } {
    i z prim >
    [ acc ec ]
    [ cv i sget locals { v } {
        cv x i 1 prim + z
        x 1 prim = [ acc v prim + ]
        [ x 2 prim = [ acc v prim < [ acc ] [ v ] if ]
          [ acc v prim > [ acc ] [ v ] if ] if ] if
        ec cv 20 i prim + sget prim + fnl } ] if };

: evfn (forall ρ; ρ env:Seq Int cv:Seq Int stk:Seq Int sp:Int x:Int y:Int z:Int -- ρ s2:Seq Int sp2:Int)
  locals { env cv stk sp x y z } {
    y 0 prim < y env 660 sget prim >= prim or z 0 prim < prim or
    z env 660 sget prim >= prim or y z prim > prim or
    [ stk sp 0 1 push ]
    [ cv x y z x 1 prim = [ 0 ] [ cv y sget ] if 0 fnl
      locals { acc ec } {
        stk sp
        x 4 prim = [ z y prim - 1 prim + ec prim - 0 ]
        [ ec 0 prim > [ 0 1 ] [ acc 0 capchk ] if ] if
        push } ] if };

: ev (forall ρ; ρ env:Seq Int cv:Seq Int c:Int stk:Seq Int sp:Int t:Int -- ρ v:Int e:Int)
  locals { env cv c stk sp t } {
    sp 0 prim < t env c sget prim >= prim or
    [ sp 1 prim = [ stk 0 sget stk 1 sget ] [ 0 1 ] if ]
    [ c 8 prim * t prim + locals { q } {
      env 20 q prim + sget locals { k } {
      env 180 q prim + sget locals { x } {
      env 340 q prim + sget locals { y } {
      env 500 q prim + sget locals { z } {
        env cv c
        k 0 prim = [ stk sp x 0 push ]
        [ k 1 prim =
          [ x 0 prim >= x env 660 sget prim < prim and
            [ stk sp cv x sget cv 20 x prim + sget push ]
            [ stk sp 0 1 push ] if ]
          [ k 2 prim = [ stk sp x evop ]
            [ env cv stk sp x y z evfn ] if ] if ] if
        t 1 prim + ev } } } } } ] if };

: evcell (forall ρ; ρ env:Seq Int cv:Seq Int c:Int -- ρ r:Seq Int)
  locals { env cv c } {
    env cv c prim seq-int.empty 16 pad 0 0 ev
    locals { v e } { cv c v sput 20 c prim + e sput 40 c prim + 1 sput } };

: dep (forall ρ; ρ env:Seq Int cv:Seq Int c:Int t:Int -- ρ ok:Bool)
  locals { env cv c t } {
    t env c sget prim >=
    [ 1 1 prim = ]
    [ c 8 prim * t prim + locals { q } {
      env 20 q prim + sget locals { k } {
      env 180 q prim + sget locals { x } {
      env 340 q prim + sget locals { y } {
      env 500 q prim + sget locals { z } {
        k 1 prim = x 0 prim >= prim and x env 660 sget prim < prim and
        [ cv 40 x prim + sget 1 prim = ]
        [ k 3 prim = y 0 prim >= prim and y z prim <= prim and z env 660 sget prim < prim and
          [ cv 61 z prim + sget cv 60 y prim + sget prim - 0 prim = ]
          [ 1 1 prim = ] if ] if
        [ env cv c t 1 prim + dep ]
        [ 1 0 prim = ] if } } } } } ] if };

: pfx (forall ρ; ρ env:Seq Int cv:Seq Int i:Int -- ρ r:Seq Int)
  locals { env cv i } {
    i env 660 sget prim <
    [ env cv 61 i prim + cv 60 i prim + sget 1 cv 40 i prim + sget prim - prim + sput
      i 1 prim + pfx ]
    [ cv ] if };

: cells (forall ρ; ρ env:Seq Int cv:Seq Int c:Int prog:Int -- ρ r:Seq Int p:Int)
  locals { env cv c prog } {
    c env 660 sget prim <
    [ cv 40 c prim + sget 0 prim =
      [ env cv c 0 dep
        [ env env cv c evcell c 1 prim + 1 cells ]
        [ env cv c 1 prim + prog cells ] if ]
      [ env cv c 1 prim + prog cells ] if ]
    [ cv prog ] if };

: rounds (forall ρ; ρ env:Seq Int cv:Seq Int -- ρ r:Seq Int)
  locals { env cv } {
    env env cv 0 pfx 0 0 cells
    locals { cv2 prog } {
      prog 1 prim = [ env cv2 rounds ] [ cv2 ] if } };

: evalall (forall ρ; ρ env:Seq Int -- ρ cv:Seq Int)
  locals { env } { env prim seq-int.empty 81 pad rounds };

: snap (forall ρ; ρ cv:Seq Int n:Int i:Int -- ρ r:Seq Int)
  locals { cv n i } {
    i n prim <
    [ cv 40 i prim + sget 0 prim = [ cv 20 i prim + 1 sput ] [ cv ] if n i 1 prim + snap ]
    [ cv ] if };

: chg (forall ρ; ρ a:Seq Int b:Seq Int n:Int i:Int acc:Int -- ρ r:Int)
  locals { a b n i acc } {
    i n prim <
    [ a b n i 1 prim + acc
      a i sget b i sget prim = a 20 i prim + sget b 20 i prim + sget prim = prim and
      [ 0 ] [ 1 ] if prim + chg ]
    [ acc ] if };

: setc (forall ρ; ρ env:Seq Int c:Int len:Int off:Int src:Seq Int j:Int -- ρ r:Seq Int)
  locals { env c len off src j } {
    j len prim <
    [ c 8 prim * j prim + locals { q } {
        env
        20 q prim + src off j prim + sget sput
        180 q prim + src 200 off prim + j prim + sget sput
        340 q prim + src 400 off prim + j prim + sget sput
        500 q prim + src 600 off prim + j prim + sget sput
        c len off src j 1 prim + setc } ]
    [ env ] if };

: setcell (forall ρ; ρ env:Seq Int c:Int len:Int off:Int src:Seq Int -- ρ r:Seq Int)
  locals { env c len off src } { env c len off src 0 setc c len sput };

: loadall (forall ρ; ρ env:Seq Int c:Int n:Int off:Int lens:Seq Int src:Seq Int -- ρ r:Seq Int)
  locals { env c n off lens src } {
    c n prim <
    [ env c lens c sget off src setcell
      c 1 prim + n off lens c sget prim + lens src loadall ]
    [ env ] if };

: edl (forall ρ; ρ env:Seq Int prev:Seq Int e:Int ne:Int off:Int ecs:Seq Int els:Seq Int src:Seq Int out:Seq Int
       -- ρ cv:Seq Int o:Seq Int)
  locals { env prev e ne off ecs els src out } {
    e ne prim <
    [ env ecs e sget els e sget off src setcell
      locals { env2 } {
        env2 evalall env2 660 sget 0 snap
        locals { cv } {
          env2 cv e 1 prim + ne off els e sget prim + ecs els src
          out prev cv env2 660 sget 0 0 chg prim seq-int.push edl } } ]
    [ prev out ] if };

: main
  (forall ρ; ρ lens:Seq Int kinds:Seq Int xs:Seq Int ys:Seq Int zs:Seq Int
     ecs:Seq Int els:Seq Int ek:Seq Int ex:Seq Int ey:Seq Int ez:Seq Int
   -- ρ values:Seq Int errors:Seq Bool changed:Seq Int)
  locals { lens kinds xs ys zs ecs els ek ex ey ez } {
    prim seq-int.empty kinds 0 app 200 pad xs 0 app 400 pad ys 0 app 600 pad zs 0 app 800 pad
    locals { s1 } {
    prim seq-int.empty ek 0 app 200 pad ex 0 app 400 pad ey 0 app 600 pad ez 0 app 800 pad
    locals { s2 } {
    prim seq-int.empty 661 pad 660 lens prim seq-int.len sput
    0 lens prim seq-int.len 0 lens s1 loadall
    locals { env } {
      env evalall env 660 sget 0 snap
      locals { cv0 } {
        env cv0 0 ecs prim seq-int.len 0 ecs els s2 prim seq-int.empty edl
        locals { cvf out } {
          cvf 0 env 660 sget prim seq-int.empty sl
          cvf 0 env 660 sget prim seq-bool.empty eb
          out } } } } } };
```
NOTE: written without being able to run the checker; the `Seq Int` spelling in stack effects is a guess, and state is packed into one sequence because Firth has no records or mutable variables. Step cost may be close to the 1,000,000 budget on worst-case sheets.

### task: blackjack
```firth
: b2i (forall ρ; ρ f:Bool -- ρ i:Int) [ 1 ] [ 0 ] if;
: sget (forall ρ; ρ s:Seq Int i:Int -- ρ v:Int) prim seq-int.at;
: sput (forall ρ; ρ s:Seq Int i:Int v:Int -- ρ r:Seq Int) prim seq-int.set;
: ap (forall ρ; ρ s:Seq Int q:Seq Int i:Int -- ρ r:Seq Int)
  locals { s q i } { s q i sget prim seq-int.push };
: inc (forall ρ; ρ s:Seq Int i:Int d:Int -- ρ r:Seq Int)
  locals { s i d } { s i s i sget d prim + sput };

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

: cvv (forall ρ; ρ r:Int -- ρ v:Int) dup 10 prim > [ drop 10 ] [ ] if;

: addc (forall ρ; ρ st:Seq Int b:Int card:Int -- ρ r:Seq Int)
  locals { st b card } {
    card cvv locals { v } {
      st b st b sget v prim + sput
      b 1 prim + st b 1 prim + sget card 1 prim = b2i prim + 0 prim > b2i sput
      b 2 prim + st b 2 prim + sget 1 prim + sput } };

: soft (forall ρ; ρ st:Seq Int b:Int -- ρ f:Bool)
  locals { st b } { st b 1 prim + sget 1 prim = st b sget 10 prim + 21 prim <= prim and };
: tot (forall ρ; ρ st:Seq Int b:Int -- ρ t:Int)
  locals { st b } { st b sget st b soft [ 10 prim + ] [ ] if };

: draw (forall ρ; ρ st:Seq Int -- ρ r:Seq Int card:Int)
  locals { st } {
    st 0 sget st 6 sget prim >=
    [ st 1 1 sput 0 ]
    [ st 0 1 inc st 200 st 0 sget prim + sget ] if };

: want (forall ρ; ρ st:Seq Int b:Int up:Int -- ρ f:Bool)
  locals { st b up } {
    st b tot locals { t } {
      t 21 prim > [ 1 0 prim = ]
      [ st b soft
        [ t 17 prim <= ]
        [ t 11 prim <= t 16 prim <= up 1 prim = up 7 prim >= prim or prim and prim or ] if ] if } };

: pdraw (forall ρ; ρ st:Seq Int b:Int up:Int -- ρ r:Seq Int)
  locals { st b up } {
    st 1 sget 0 prim = [ st b up want ] [ 1 0 prim = ] if
    [ st draw locals { s2 c } { s2 b c addc b up pdraw } ]
    [ st ] if };

: dbl (forall ρ; ρ st:Seq Int b:Int i:Int up:Int -- ρ f:Bool)
  locals { st b i up } {
    st b 2 prim + sget 2 prim =
    st b tot 10 prim >= prim and
    st b tot 11 prim <= prim and
    st b soft prim not prim and
    up 2 prim >= prim and up 9 prim <= prim and
    st 10 i prim + sget
      st 60 i 10 prim * prim + 3 prim + sget
      st 68 i 10 prim * prim + sget prim +
      st 15 i prim + sget prim + prim >= prim and };

: phand (forall ρ; ρ st:Seq Int b:Int i:Int up:Int -- ρ r:Seq Int)
  locals { st b i up } {
    st b i up dbl
    [ st b 3 prim + st b 3 prim + sget 2 prim * sput
      draw locals { s2 c } { s2 b c addc } ]
    [ st b up pdraw ] if };

: sethand (forall ρ; ρ st:Seq Int b:Int r:Int bet:Int -- ρ r2:Seq Int)
  locals { st b r bet } {
    st b r cvv sput b 1 prim + r 1 prim = b2i sput b 2 prim + 1 sput
    b 3 prim + bet sput b 4 prim + 1 sput };

: pturn (forall ρ; ρ st:Seq Int i:Int -- ρ r:Seq Int)
  locals { st i } {
    st 20 i prim + sget 1 prim = st 30 i prim + sget 0 prim = prim and
    [ 60 i 10 prim * prim + locals { b } {
      st 45 sget locals { up } {
      st 35 i prim + sget locals { r1 } {
      st 40 i prim + sget locals { r2 } {
      st 15 i prim + sget locals { bet } {
        r1 r2 prim = r1 1 prim = r1 8 prim = prim or prim and
        st 10 i prim + sget bet 2 prim * prim >= prim and
        [ st b r1 bet sethand b 5 prim + r2 bet sethand
          draw locals { s2 c1 } {
            s2 b c1 addc draw locals { s3 c2 } {
              s3 b 5 prim + c2 addc
              r1 1 prim =
              [ ]
              [ b i up phand b 5 prim + i up phand ] if } } ]
        [ st b 3 prim + bet sput b 4 prim + 1 sput b i up phand ] if } } } } } ]
    [ st ] if };

: dd (forall ρ; ρ st:Seq Int -- ρ r:Seq Int)
  locals { st } {
    st 1 sget 0 prim = st 110 tot 17 prim < prim and
    [ st draw locals { s2 c } { s2 110 c addc dd } ]
    [ st ] if };

: anyl (forall ρ; ρ st:Seq Int s:Int acc:Int -- ρ n:Int)
  locals { st s acc } {
    s 10 prim <
    [ st s 1 prim + acc
      st 60 s 5 prim * prim + 4 prim + sget 1 prim =
      st 60 s 5 prim * prim + tot 21 prim <= prim and b2i prim + anyl ]
    [ acc ] if };

: stl (forall ρ; ρ st:Seq Int s:Int -- ρ r:Seq Int)
  locals { st s } {
    s 10 prim <
    [ 60 s 5 prim * prim + locals { b } {
        st b 4 prim + sget 1 prim =
        [ st b tot locals { t } {
          st 110 tot locals { dl } {
          st b 3 prim + sget locals { stake } {
          25 s 2 prim div prim + locals { d } {
            st d st d sget
              t 21 prim > [ 0 stake prim - ]
              [ dl 21 prim > dl t prim < prim or [ stake ]
                [ dl t prim > [ 0 stake prim - ] [ 0 ] if ] if ] if
              prim + sput } } } } ]
        [ st ] if
        s 1 prim + stl } ]
    [ st ] if };

: dl (forall ρ; ρ st:Seq Int i:Int k:Int -- ρ r:Seq Int)
  locals { st i k } {
    i st 5 sget prim <
    [ st 20 i prim + sget 1 prim =
      [ st draw locals { s2 c } {
          s2 30 k 5 prim * prim + i prim + c sput
          60 i 10 prim * prim + c addc
          i 1 prim + k dl } ]
      [ st i 1 prim + k dl ] if ]
    [ st ] if };

: zf (forall ρ; ρ st:Seq Int i:Int e:Int -- ρ r:Seq Int)
  locals { st i e } {
    i e prim <
    [ st i 0 sput i 1 prim + e zf ]
    [ st ] if };

: cnt (forall ρ; ρ st:Seq Int i:Int acc:Int -- ρ n:Int)
  locals { st i acc } {
    i st 5 sget prim <
    [ st i 1 prim + acc st 20 i prim + sget prim + cnt ]
    [ acc ] if };

: act (forall ρ; ρ st:Seq Int i:Int mode:Int -- ρ r:Seq Int)
  locals { st i mode } {
    mode 5 prim =
    [ st 20 i prim + st 10 i prim + sget st 15 i prim + sget prim >= b2i sput ]
    [ st 20 i prim + sget 1 prim =
      [ mode 0 prim =
        [ 60 i 10 prim * prim + locals { b } {
            st 30 i prim + st b 2 prim + sget 2 prim = st b tot 21 prim = prim and b2i sput } ]
        [ mode 1 prim =
          [ st 30 i prim + sget 0 prim =
            [ st 25 i prim + 0 st 15 i prim + sget prim - sput ]
            [ st ] if ]
          [ mode 2 prim =
            [ st 30 i prim + sget 1 prim =
              [ st 25 i prim + st 15 i prim + sget 3 prim * 2 prim div sput ]
              [ st ] if ]
            [ mode 3 prim =
              [ st i pturn ]
              [ mode 4 prim =
                [ st 10 i prim + st 10 i prim + sget st 25 i prim + sget prim + sput
                  3 st 3 sget st 30 i prim + sget prim + sput ]
                [ st ] if ] if ] if ] if ] if ]
      [ st ] if ] if };

: pl (forall ρ; ρ st:Seq Int i:Int mode:Int -- ρ r:Seq Int)
  locals { st i mode } {
    i st 5 sget prim <
    [ st i mode act i 1 prim + mode pl ]
    [ st ] if };

: round (forall ρ; ρ st:Seq Int -- ρ r:Seq Int)
  locals { st } {
    st 20 115 zf 0 5 pl
    locals { s1 } {
      s1 0 0 cnt 0 prim =
      [ s1 8 1 sput ]
      [ s1 0 1 dl
        draw locals { s2 c } { s2 45 c sput 110 c addc }
        0 2 dl
        draw locals { s3 c } { s3 110 c addc }
        0 0 pl
        locals { s4 } {
          s4 110 tot 21 prim =
          [ s4 0 1 pl ]
          [ s4 0 2 pl 0 3 pl
            locals { s5 } {
              s5 0 0 anyl 0 prim >
              [ s5 dd ] [ s5 ] if
              0 stl } ] if } ] if } };

: rl (forall ρ; ρ st:Seq Int r:Int -- ρ r2:Seq Int)
  locals { st r } {
    r st 7 sget prim <
    [ st round locals { s1 } {
        s1 8 sget 1 prim = s1 1 sget 1 prim = prim or
        [ s1 ]
        [ s1 0 4 pl 4 1 inc
          locals { s2 } { s2 110 tot 21 prim > [ s2 2 1 inc ] [ s2 ] if }
          r 1 prim + rl ] if } ]
    [ st ] if };

: main
  (forall ρ; ρ shoe:Seq Int bank:Seq Int bets:Seq Int rounds:Int
   -- ρ final:Seq Int played:Int busts:Int naturals:Int)
  locals { shoe bank bets rounds } {
    prim seq-int.empty 10 pad bank 0 app 15 pad bets 0 app 200 pad shoe 0 app
    5 bank prim seq-int.len sput 6 shoe prim seq-int.len sput 7 rounds sput
    0 rl
    locals { f } {
      f 10 f 5 sget 10 prim + prim seq-int.empty sl
      f 4 sget f 2 sget f 3 sget } };
```
NOTE: written without being able to run the checker; the `Seq Int` spelling in stack effects is a guess, and state is packed into one sequence because Firth has no records or mutable variables. The round state is mutated in place and only committed to the bankrolls when no card ran out, so a short shoe discards the round.

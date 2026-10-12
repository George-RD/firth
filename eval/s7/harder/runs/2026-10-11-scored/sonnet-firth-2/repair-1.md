Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## regex
Match strings against a regular expression given as tokens. Token 0 to 25 is that letter; 26 is '.', matching any one letter; 27 '*', 28 '+' and 29 '?' are postfix operators; 30 is '|'; 31 '(' and 32 ')'. The pattern's grammar: an alternation is one or more sequences separated by '|'; a sequence is zero or more items, one after another; an item is an atom followed by zero or more postfix operators; an atom is a letter, '.', or '(' alternation ')'. The whole pattern is one alternation. A postfix operator applies to its item's atom together with any operators already after it, so ab* repeats only the b and (a*)? is a*?: '*' matches zero or more repeats, '+' one or more, '?' zero or one. A sequence matches its items one after another (an empty sequence matches the empty string), and an alternation matches if any of its sequences does. A pattern that does not fit the grammar, such as one with an operator where an atom should start, a '(' never closed or a ')' with no '(' open, is invalid. The strings are given together: string j has lens[j] letters, and chars holds every string's letters, string 0 first. For each string, return whether the whole string matches the pattern, and the length of the longest start of it (from no letters up to all of them) that matches, or -1 if none does. Also return how many strings match whole and whether the pattern is valid; for an invalid pattern every string gives false and -1, the count is 0 and validity is false. pattern has at most 20 tokens, each 0 to 32; lens has 1 to 8 values, each 0 to 12, adding up to the length of chars; every value of chars is 0 to 25.
Inputs on the stack, bottom to top: pattern: Seq Int, lens: Seq Int, chars: Seq Int.
Outputs left on the stack, bottom to top: full: Seq Bool, longest: Seq Int, count: Int, valid: Bool.
Example: stack [{ 0 27 1 30 31 2 3 32 28 }, { 3 2 4 0 3 1 3 }, { 0 0 1 2 3 2 3 2 3 2 3 2 1 0 1 1 }] becomes [{ true true true false false true false }, { 3 2 4 -1 2 1 2 }, 4, true].

Your answer:
```
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
On the example, the run failed:
code: firth.type.branch-mismatch
word: seqend
at: line 67, column 9
message: In the false branch of the `if` in `seqend` whose true branch is `[ i ]`, `seqend` needs 2 values (pat:Seq Int, i:Int), but the branch has pushed only 1 value before it (the result of `opsend`). The remaining 1 value would come from below the `if`, where there is none: everything the word was given is bound to locals or already used.
hint: Make the branch push, just before `seqend`, exactly the values it takes, in this order: pat:Seq Int, i:Int. The branch already pushes the result of `opsend`, in the place of the last one (i:Int). Push the first one (pat:Seq Int) before it by writing the local of that name, `pat`: write `pat pat pat i atomend opsend seqend` in place of `pat pat i atomend opsend seqend` on line 66. With that edit `seqend` checks. If `seqend` should not be in this branch, remove it. Adding a `drop` or pushing values to even out the branches would only move the mistake.

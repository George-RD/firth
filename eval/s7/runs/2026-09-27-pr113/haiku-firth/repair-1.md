Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## triple
Return three times n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4] becomes [12].

Your answer:
```
: main
  ( -- r:Int^many )
  3 prim *;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.stack-underflow', 'severity': 'error', 'message_key': 'diagnostic.stack_underflow', 'message_params': {'name': '*'}, 'location': {'path': 'tmpbt1vm4qh.firth', 'range': {'start': {'line': 3, 'column': 5}, 'end': {'line': 3, 'column': 11}}}, 'cause': {'kind': 'type-checking', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## sum3
Return a + b + c.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [1, 2, 3] becomes [6].

Your answer:
```
: main
  ( -- r:Int^many )
  prim + prim +;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.stack-underflow', 'severity': 'error', 'message_key': 'diagnostic.stack_underflow', 'message_params': {'name': '+'}, 'location': {'path': 'tmpvict9f_y.firth', 'range': {'start': {'line': 3, 'column': 3}, 'end': {'line': 3, 'column': 9}}}, 'cause': {'kind': 'type-checking', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## times10
Return ten times n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3] becomes [30].

Your answer:
```
: main
  ( -- r:Int^many )
  10 prim *;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.stack-underflow', 'severity': 'error', 'message_key': 'diagnostic.stack_underflow', 'message_params': {'name': '*'}, 'location': {'path': 'tmph1gfp1qv.firth', 'range': {'start': {'line': 3, 'column': 6}, 'end': {'line': 3, 'column': 12}}}, 'cause': {'kind': 'type-checking', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## affine
Return 4*x + 7.
Inputs on the stack, bottom to top: x: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [1] becomes [11].

Your answer:
```
: main
  ( -- r:Int^many )
  4 prim * 7 prim +;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.stack-underflow', 'severity': 'error', 'message_key': 'diagnostic.stack_underflow', 'message_params': {'name': '*'}, 'location': {'path': 'tmped2v_0tq.firth', 'range': {'start': {'line': 3, 'column': 5}, 'end': {'line': 3, 'column': 11}}}, 'cause': {'kind': 'type-checking', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## majority
Return true when at least two of p, q, r are true.
Inputs on the stack, bottom to top: p: Bool, q: Bool, r: Bool.
Outputs left on the stack, bottom to top: m: Bool.
Example: stack [true, false, true] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  locals { p q r } {
    p [
      q [ true ] [ r ] if
    ] [
      q [ r ] [ false ] if
    ] if
  };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'q'}, 'location': {'path': 'tmp_5hcv1mj.firth', 'range': {'start': {'line': 5, 'column': 7}, 'end': {'line': 5, 'column': 8}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## count-true
Return how many of p, q, r are true, as an Int.
Inputs on the stack, bottom to top: p: Bool, q: Bool, r: Bool.
Outputs left on the stack, bottom to top: n: Int.
Example: stack [true, false, true] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ n:Int^many)
  locals { p q r } {
    p [ 1 ] [ 0 ] if
    q [ 1 ] [ 0 ] if prim +
    r [ 1 ] [ 0 ] if prim +
  };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.quotation-input-mismatch', 'severity': 'error', 'message_key': 'diagnostic.quotation_input_mismatch', 'message_params': {}, 'location': {'path': 'tmph6lvfk4z.firth', 'range': {'start': {'line': 5, 'column': 5}, 'end': {'line': 5, 'column': 6}}}, 'cause': {'kind': 'type-checking', 'data': {'state': {'encoding': 'opaque', 'value': {'lean_repr': 'Firth.Elaborator.StackEffect.AStack.snoc\\n  (Firth.Elaborator.StackEffect.AStack.snoc\\n    (Firth.Elaborator.StackEffect.AStack.snoc\\n      (Firth.Elaborator.StackEffect.AStack.snoc\\n        (Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.rigid \"\u03c1\"))\\n        (Firth.Elaborator.StackEffect.AType.base \"Bool\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n      (Firth.Elaborator.StackEffect.AType.base \"Bool\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n    (Firth.Elaborator.StackEffect.AType.base \"Int\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n  (Firth.Elaborator.StackEffect.AType.quotation\\n    (Firth.Elaborator.StackEffect.AStack.snoc\\n      (Firth.Elaborator.StackEffect.AStack.snoc\\n        (Firth.Elaborator.StackEffect.AStack.snoc\\n          (Firth.Elaborator.StackEffect.AStack.snoc\\n            (Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.mvar 19))\\n            (Firth.Elaborator.StackEffect.AType.mvar 10 (Firth.Elaborator.StackEffect.AUsage.mvar 11)))\\n          (Firth.Elaborator.StackEffect.AType.mvar 9 (Firth.Elaborator.StackEffect.AUsage.mvar 10)))\\n        (Firth.Elaborator.StackEffect.AType.mvar 12 (Firth.Elaborator.StackEffect.AUsage.mvar 13)))\\n      (Firth.Elaborator.StackEffect.AType.mvar 16 (Firth.Elaborator.StackEffect.AUsage.mvar 18)))\\n    (Firth.Elaborator.StackEffect.AStack.snoc\\n      (Firth.Elab

## max
Return the larger of a and b.
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3, 8] becomes [8].

Your answer:
```
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ b ] [ a ] if };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'b'}, 'location': {'path': 'tmpq2q1kfuv.firth', 'range': {'start': {'line': 3, 'column': 33}, 'end': {'line': 3, 'column': 34}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## min3
Return the smallest of a, b and c.
Inputs on the stack, bottom to top: a: Int, b: Int, c: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4, 2, 9] becomes [2].

Your answer:
```
: main
  (forall ρ; ρ a:Int^many b:Int^many c:Int^many -- ρ r:Int^many)
  locals { a b c } {
    a b prim < [ a c prim < [ a ] [ c ] if ] [ b c prim < [ b ] [ c ] if ] if
  };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'a'}, 'location': {'path': 'tmp64mdjjlg.firth', 'range': {'start': {'line': 4, 'column': 18}, 'end': {'line': 4, 'column': 19}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## abs-diff
Return |a - b|.
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3, 10] becomes [7].

Your answer:
```
: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  locals { a b } { a b prim < [ b a prim - ] [ a b prim - ] if };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'b'}, 'location': {'path': 'tmpninyyai1.firth', 'range': {'start': {'line': 3, 'column': 33}, 'end': {'line': 3, 'column': 34}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## clamp
Return x limited to the range lo..hi (lo <= hi is guaranteed).
Inputs on the stack, bottom to top: x: Int, lo: Int, hi: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [15, 0, 10] becomes [10].

Your answer:
```
: main
  (forall ρ; ρ x:Int^many lo:Int^many hi:Int^many -- ρ r:Int^many)
  locals { x lo hi } { x lo prim < [ lo ] [ x hi prim < [ x ] [ hi ] if ] if };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'lo'}, 'location': {'path': 'tmpx6dcccdw.firth', 'range': {'start': {'line': 3, 'column': 38}, 'end': {'line': 3, 'column': 40}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## is-even
Return true when n is even.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [6] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ n:Int^many -- ρ r:Bool^many)
  0;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.declared-effect-mismatch', 'severity': 'error', 'message_key': 'diagnostic.declared_effect_mismatch', 'message_params': {}, 'location': {'path': 'tmpyxu2jqof.firth', 'range': {'start': {'line': 2, 'column': 3}, 'end': {'line': 2, 'column': 44}}}, 'cause': {'kind': 'type-checking', 'data': {'state': {'encoding': 'opaque', 'value': {'lean_repr': 'Firth.Elaborator.StackEffect.AStack.snoc\\n  (Firth.Elaborator.StackEffect.AStack.snoc\\n    (Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.rigid \"\u03c1\"))\\n    (Firth.Elaborator.StackEffect.AType.base \"Int\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n  (Firth.Elaborator.StackEffect.AType.base \"Int\" (Firth.Elaborator.StackEffect.AUsage.many))'}}}}, 'expected_stack': {'encoding': 'opaque', 'value': {'lean_repr': 'Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.rigid \"\u03c1\")'}}, 'actual_stack': {'encoding': 'opaque', 'value': {'lean_repr': 'Firth.Elaborator.StackEffect.AStack.snoc\\n  (Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.rigid \"\u03c1\"))\\n  (Firth.Elaborator.StackEffect.AType.base \"Int\" (Firth.Elaborator.StackEffect.AUsage.many))'}}, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## sum-to
Return 0 + 1 + ... + n.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4] becomes [10].

Your answer:
```
: sum-to-helper
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  n 0 prim = [ acc ] [ n 1 prim - dup n prim + acc prim + sum-to-helper ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 sum-to-helper;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.name.unresolved', 'severity': 'error', 'message_key': 'diagnostic.unresolved', 'message_params': {}, 'location': {'path': 'tmpaha4f0d_.firth', 'range': {'start': {'line': 3, 'column': 3}, 'end': {'line': 3, 'column': 4}}}, 'cause': {'kind': 'validation', 'data': {'actual': 'n'}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## factorial
Return n! (0! = 1).
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [4] becomes [24].

Your answer:
```
: fact-helper
  (forall ρ; ρ n:Int^many acc:Int^many -- ρ r:Int^many)
  n 0 prim = [ acc ] [ n 1 prim - dup acc n prim * fact-helper ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  1 fact-helper;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.name.unresolved', 'severity': 'error', 'message_key': 'diagnostic.unresolved', 'message_params': {}, 'location': {'path': 'tmpq0d4a35j.firth', 'range': {'start': {'line': 3, 'column': 3}, 'end': {'line': 3, 'column': 4}}}, 'cause': {'kind': 'validation', 'data': {'actual': 'n'}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## fib
Return the n-th Fibonacci number, with fib(0) = 0 and fib(1) = 1.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [6] becomes [8].

Your answer:
```
: fib-helper
  (forall ρ; ρ n:Int^many a:Int^many b:Int^many -- ρ r:Int^many)
  n 0 prim = [ a ] [ n 1 prim - b a b prim + fib-helper ] if;

: main
  (forall ρ; ρ n:Int^many -- ρ r:Int^many)
  0 1 fib-helper;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.name.unresolved', 'severity': 'error', 'message_key': 'diagnostic.unresolved', 'message_params': {}, 'location': {'path': 'tmpckv93hiv.firth', 'range': {'start': {'line': 3, 'column': 3}, 'end': {'line': 3, 'column': 4}}}, 'cause': {'kind': 'validation', 'data': {'actual': 'n'}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## gcd
Return the greatest common divisor of a and b (both at least 1).
Inputs on the stack, bottom to top: a: Int, b: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [12, 18] becomes [6].

Your answer:
```
: gcd-helper
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  b 0 prim = [ a ] [ b a b prim - prim - gcd-helper ] if;

: main
  (forall ρ; ρ a:Int^many b:Int^many -- ρ r:Int^many)
  gcd-helper;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.name.unresolved', 'severity': 'error', 'message_key': 'diagnostic.unresolved', 'message_params': {}, 'location': {'path': 'tmper42mlo4.firth', 'range': {'start': {'line': 3, 'column': 3}, 'end': {'line': 3, 'column': 4}}}, 'cause': {'kind': 'validation', 'data': {'actual': 'b'}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## power
Return base raised to exp (0^0 = 1).
Inputs on the stack, bottom to top: base: Int, exp: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [3, 4] becomes [81].

Your answer:
```
: power-helper
  (forall ρ; ρ base:Int^many exp:Int^many acc:Int^many -- ρ r:Int^many)
  exp 0 prim = [ acc ] [ exp 1 prim - acc base prim * power-helper ] if;

: main
  (forall ρ; ρ base:Int^many exp:Int^many -- ρ r:Int^many)
  1 power-helper;

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.name.unresolved', 'severity': 'error', 'message_key': 'diagnostic.unresolved', 'message_params': {}, 'location': {'path': 'tmptao1o61g.firth', 'range': {'start': {'line': 3, 'column': 3}, 'end': {'line': 3, 'column': 6}}}, 'cause': {'kind': 'validation', 'data': {'actual': 'exp'}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## collatz-steps
Return how many Collatz steps it takes n (n >= 1) to reach 1: halve even numbers, map odd n to 3n + 1.
Inputs on the stack, bottom to top: n: Int.
Outputs left on the stack, bottom to top: r: Int.
Example: stack [6] becomes [8].

Your answer:
```

```
On the example, no answer was given

Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## and
Return p AND q.
Inputs on the stack, bottom to top: p: Bool, q: Bool.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [true, false] becomes [false].

Your answer:
```
: main
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  locals { p q } { [ q ] [ drop false ] if };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'q'}, 'location': {'path': 'tmp7gfop_hh.firth', 'range': {'start': {'line': 3, 'column': 22}, 'end': {'line': 3, 'column': 23}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

## xor
Return p XOR q (true when exactly one is true).
Inputs on the stack, bottom to top: p: Bool, q: Bool.
Outputs left on the stack, bottom to top: r: Bool.
Example: stack [true, false] becomes [true].

Your answer:
```
: main
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  locals { p q } {
    q [ p [ false ] [ true ] if ] [ ] if
  };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'p'}, 'location': {'path': 'tmp4bk2cq6e.firth', 'range': {'start': {'line': 4, 'column': 9}, 'end': {'line': 4, 'column': 10}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

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
    q [ drop true ] [
      drop r [ drop true ] [ q [ drop true ] [ drop false ] if ] if
    ] if
  };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.elaboration.unsupported-capture', 'severity': 'error', 'message_key': 'diagnostic.unsupported_capture', 'message_params': {'name': 'r'}, 'location': {'path': 'tmpboesxdqn.firth', 'range': {'start': {'line': 5, 'column': 12}, 'end': {'line': 5, 'column': 13}}}, 'cause': {'kind': 'elaboration', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

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
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.type.quotation-input-mismatch', 'severity': 'error', 'message_key': 'diagnostic.quotation_input_mismatch', 'message_params': {}, 'location': {'path': 'tmp0b1ypace.firth', 'range': {'start': {'line': 5, 'column': 5}, 'end': {'line': 5, 'column': 6}}}, 'cause': {'kind': 'type-checking', 'data': {'state': {'encoding': 'opaque', 'value': {'lean_repr': 'Firth.Elaborator.StackEffect.AStack.snoc\\n  (Firth.Elaborator.StackEffect.AStack.snoc\\n    (Firth.Elaborator.StackEffect.AStack.snoc\\n      (Firth.Elaborator.StackEffect.AStack.snoc\\n        (Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.rigid \"\u03c1\"))\\n        (Firth.Elaborator.StackEffect.AType.base \"Bool\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n      (Firth.Elaborator.StackEffect.AType.base \"Bool\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n    (Firth.Elaborator.StackEffect.AType.base \"Int\" (Firth.Elaborator.StackEffect.AUsage.many)))\\n  (Firth.Elaborator.StackEffect.AType.quotation\\n    (Firth.Elaborator.StackEffect.AStack.snoc\\n      (Firth.Elaborator.StackEffect.AStack.snoc\\n        (Firth.Elaborator.StackEffect.AStack.snoc\\n          (Firth.Elaborator.StackEffect.AStack.snoc\\n            (Firth.Elaborator.StackEffect.AStack.row (Firth.Elaborator.StackEffect.Row.mvar 19))\\n            (Firth.Elaborator.StackEffect.AType.mvar 10 (Firth.Elaborator.StackEffect.AUsage.mvar 11)))\\n          (Firth.Elaborator.StackEffect.AType.mvar 9 (Firth.Elaborator.StackEffect.AUsage.mvar 10)))\\n        (Firth.Elaborator.StackEffect.AType.mvar 12 (Firth.Elaborator.StackEffect.AUsage.mvar 13)))\\n      (Firth.Elaborator.StackEffect.AType.mvar 16 (Firth.Elaborator.StackEffect.AUsage.mvar 18)))\\n    (Firth.Elaborator.StackEffect.AStack.snoc\\n      (Firth.Elab

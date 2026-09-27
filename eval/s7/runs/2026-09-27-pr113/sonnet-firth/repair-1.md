Some of your firth answers did not work on the visible example. Fix them. Answer only the tasks listed, in the same format as before.

## majority
Return true when at least two of p, q, r are true.
Inputs on the stack, bottom to top: p: Bool, q: Bool, r: Bool.
Outputs left on the stack, bottom to top: m: Bool.
Example: stack [true, false, true] becomes [true].

Your answer:
```
: and
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ ] [ drop false ] if;

: or
  (forall ρ; ρ p:Bool^many q:Bool^many -- ρ r:Bool^many)
  swap [ drop true ] [ ] if;

: main
  (forall ρ; ρ p:Bool^many q:Bool^many r:Bool^many -- ρ m:Bool^many)
  locals { p q r } { p q and q r and or p r and or };

```
On the example, the run failed:
{"error": "application elaborate: status 'failure', expected 'success': [{'schema_version': '1.0', 'payload_kind': 'diagnostic', 'payload_id': 'application.elaborate', 'request_id': 'application', 'body': {'code': 'firth.name.unbound-local', 'severity': 'error', 'message_key': 'diagnostic.unbound_local', 'message_params': {'name': 'q'}, 'location': {'path': 'tmpqpl_xdju.firth', 'range': {'start': {'line': 11, 'column': 30}, 'end': {'line': 11, 'column': 31}}}, 'cause': {'kind': 'name-resolution', 'data': {}}, 'expected_stack': None, 'actual_stack': None, 'obligations': [], 'proposed_fixes': []}}]", "status": "error"}

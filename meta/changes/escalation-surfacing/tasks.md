# Tasks: escalation-surfacing

- [x] Author dec.escalation-surfacing.
- [x] Amend the mandate (inert vs live risk) and the runbook (park
      semantics).
- [x] supervisor.sh: park loop, nonce handshake, issue surfacing,
      quota recheck on ack; compose control mount; README contract.
- [x] Flow tests green: park on every stay-down, ack resume,
      pre-staged ack refused, dedupe, quota gate across acks, cap
      re-opened, refreshed driver consumed.
- [x] Deploy and resume the parked incident end to end.

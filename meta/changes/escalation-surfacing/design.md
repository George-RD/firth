# Design: escalation-surfacing

Park is an interruptible wait loop, not an exit. The ack is a content
handshake: the marker holds a nonce minted at park time after the
driver's process group is killed, so nothing in-container can write it
(/control is read-only inside), nothing staged pre-park can contain
it, and no timestamp-resolution games apply. The GitHub issue is pure
notification: the loop and operator share one identity, so issue
closure proves nothing about who decided. Ack resumes through
refresh_for_relaunch; an rc 3 resume re-runs the quota verdict and an
ack re-opens the bounded quota window rather than overriding the gate.

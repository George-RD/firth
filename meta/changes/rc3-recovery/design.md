# Design: rc3-recovery

Order of gates on rc 3: machine-checked quota verdict first. `wait`
keeps the bounded quota path (never the delegate), `unknown` stays
down, `ok` proves the stop was not quota and routes it to recovery.sh
with rc 3. The signature already embeds the rc, so bounds count per
class per tips. `refresh_for_relaunch` (fetch, ff-only merge, driver
re-extraction, log prune) is the single relaunch gate used by quota,
rc 2, and rc 3 paths; failure stays down with the grant ledgered.

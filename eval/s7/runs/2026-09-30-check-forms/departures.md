# Run 13 departures from the pre-registration

1. **No new starts once the early look's reading was fixed (05:35Z).** The
   pre-registration says authoring continues while the early look waits for
   its window to be final. At 05:35:10Z B10's round 1 audit flagged a call,
   the sixth audit void among B1 to B10 (B1, B2, B4, B7, B8, B10). A sample
   found void at any point is void, so the look could only read 6 or more
   and stop. From then on no sample started in either arm. Under the
   pre-registration, A11 and B11 would have started at 05:40Z, when B9's
   validity became final and freed an arm B slot. The decision used void
   status only; no score and no arm total was read for it. It changed
   nothing in the look's window: B8, B9 and B10 got both feedback rounds,
   their third answers were scored, and the look was taken as written at
   05:48:49Z, once all ten had `final.md` (`driver/early-look.txt`,
   `driver/state.md`). It read 7 audit voids, because B9's round 3 audit
   also flagged a call.
2. **`void.md` amended after `final.md`.** Three void records gained causes
   after their `final.md` was written, all from the scans already run on
   the complete log and all before the early look:
   - B7: `final.md` at 05:25:28Z; the context cause (a `task_status` line
     at 05:21:43Z, found by that same scan) was added to `void.md` at
     05:26Z.
   - B9: its only audit flag came in round 3. `final.sh` wrote `final.md`
     at 05:40:01Z, and `void.md` was written a few seconds later from the
     same audit output.
   - B8: the round 3 flags (a `cat` of the prompt through `head`, and a
     heredoc script in `/tmp`) were added to the reason text of its
     existing `void.md` after `final.md` at 05:41:45Z.

   None of these changed a sample's void kind or whether it was an audit
   void, and `analyse.py --early-look` reads only those.

# 02: The phone's console

**What to build:** ten taps in a row on the ruleset description on the "New
match" tab ("First to 2 sets. A set is 6 games…" / "Scoring to 21 points…")
open Pulse's `ConsoleView` in a sheet with a Done button. The phone app links
`PulseUI`.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Ten taps, each within about half a second of the last, open the console;
      a longer pause starts the count over
- [ ] Nothing shows along the way: no haptic, no hint, no change to the text
- [ ] The description looks and reads exactly as it does today, VoiceOver
      included — the taps add no button trait
- [ ] The console opens in a sheet with Done; a swipe down closes it too
- [ ] The console shows the phone's own messages, including those written by
      `PadelDelivery`
- [ ] Driven on a simulator: ten taps open it, nine do not, a slow ten do not

## Notes

The description is the one plain text the phone shows in every state of the
history, a broken store included, and away from a running match.

The gesture is the same on the watch (03); if it fits in `PadelDesign` as one
modifier both apps use, it goes there.

## Comments

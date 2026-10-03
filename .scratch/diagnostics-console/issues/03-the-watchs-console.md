# 03: The watch's console

**What to build:** ten taps in a row on the ruleset description on the watch's
settings page — the text under the "Scoring" card — open Pulse's
`ConsoleView` in a sheet. The watch app links `PulseUI`.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Ten taps, each within about half a second of the last, open the console;
      a longer pause starts the count over
- [ ] Nothing shows along the way: no haptic, no hint, no change to the text
- [ ] The description looks and reads exactly as it does today
- [ ] The console opens in a sheet the watch can close
- [ ] The console shows the watch's own messages, including those written by
      `PadelDelivery`
- [ ] The console's "Share Store" offers the store as a `.pulse` file
- [ ] Driven on a simulator: ten taps open it, nine do not

## Notes

The watch keeps its own store; its logs do not travel to the phone. Taps on the
score screen award rallies, which is why the way in sits on the start pages.

If 02 put the gesture in `PadelDesign`, this ticket uses it.

## Comments

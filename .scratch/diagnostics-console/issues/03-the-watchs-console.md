# 03: The watch's console

**What to build:** ten taps in a row on the ruleset description on the watch's
settings page — the text under the "Scoring" card — open Pulse's
`ConsoleView` in a sheet. The watch app links `PulseUI`.

**Blocked by:** 01

**Status:** done

- [x] Ten taps, each within about half a second of the last, open the console;
      a longer pause starts the count over
- [x] Nothing shows along the way: no haptic, no hint, no change to the text
- [x] The description looks and reads exactly as it does today
- [x] The console opens in a sheet the watch can close
- [x] The console shows the watch's own messages, including those written by
      `PadelDelivery`
- [x] The console's "Share Store" offers the store as a `.pulse` file
- [x] Driven on a simulator: ten taps open it, nine do not

## Notes

The watch keeps its own store; its logs do not travel to the phone. Taps on the
score screen award rallies, which is why the way in sits on the start pages.

If 02 put the gesture in `PadelDesign`, this ticket uses it.

## Comments

Shipped: `onQuickTaps(_:within:perform:)` in `PadelDesign/Gestures/`, which 02
can use as is. The watch links `PulseUI` through a project package reference.
The console opens in `.logs` mode, because Pulse defaults to its network tab.
It closes with watchOS's own ✕, not a Done button.

Driven on a Series 11 simulator, in Russian and in English at AX5: ten quick
taps open the console, nine do not, ten slow do not. The console showed
"Notice • Delivery" and "Error • Workout", and Share Store exported
`logs-….pulse`. The console lists the current launch only, until another
session is picked under its Sessions button.

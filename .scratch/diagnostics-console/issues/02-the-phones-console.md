# 02: The phone's console

**What to build:** ten taps in a row on the ruleset description on the "New
match" tab ("First to 2 sets. A set is 6 games…" / "Scoring to 21 points…")
open Pulse's `ConsoleView` in a sheet with a Done button. The phone app links
`PulseUI`.

**Blocked by:** 01

**Status:** done

- [x] Ten taps, each within about half a second of the last, open the console;
      a longer pause starts the count over
- [x] Nothing shows along the way: no haptic, no hint, no change to the text
- [x] The description looks and reads exactly as it does today, VoiceOver
      included — the taps add no button trait
- [x] The console opens in a sheet with Done; a swipe down closes it too
- [x] The console shows the phone's own messages, including those written by
      `PadelDelivery`
- [x] Driven on a simulator: ten taps open it, nine do not, a slow ten do not

## Notes

The description is the one plain text the phone shows in every state of the
history, a broken store included, and away from a running match.

The gesture is the same on the watch (03); if it fits in `PadelDesign` as one
modifier both apps use, it goes there.

## Comments

Shipped: the description takes 03's `onQuickTaps(10)` and opens
`DiagnosticsConsole`, Pulse's `ConsoleView` in `.logs` mode with Pulse's close
button hidden and a Done of our own ("Готово" in Russian). The phone links
`PulseUI` through 03's package reference.

Driven on an iPhone 17 Pro simulator, in Russian and in English at AX XXXL,
with the gaps the app saw printed by a debug line since removed: ten taps
0.25–0.30 s apart open it, nine do not, ten 0.62–0.70 s apart do not. The
sentence stays a StaticText with no traits and no actions — read off the
accessibility tree, not heard through VoiceOver. Done and a swipe down close
it. With the store's tables dropped, it listed "Error • Delivery" and
"Error • New Match". A clean launch logs nothing yet; 04 adds that.

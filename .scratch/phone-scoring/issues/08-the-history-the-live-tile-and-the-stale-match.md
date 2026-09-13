# 08: The history — the live tile, the stale match, landscape

**What to build:** what the history does now that a match can be running while
it is on screen, and what it does with one that was left running yesterday.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] A match in progress shows as a tile at the top of the history: its score,
      its ruleset, and that it is running. Tapping it opens the scoreboard
- [ ] Opening the app while a match is running goes straight to the scoreboard;
      closing the scoreboard comes back here, where the tile is waiting
- [ ] The "New match" button stands at the foot of the history when no match is
      running, and gives way to the tile when one is
- [ ] A match in progress that was last played more than a few hours ago is not
      resumed silently: the app asks whether to carry on or to close it as
      unfinished, and does neither until it is answered
- [ ] Answering "close it" abandons the match and leaves it in the history,
      marked as it is today
- [ ] The list works in landscape: the column is capped at a readable width and
      centred rather than stretched across the screen
- [ ] The tile is drawn from the host's current match, not from a second read of
      the store
- [ ] Previews for: a running match, a stale one, an empty history in landscape
- [ ] The strings are in `Shared/Localizable.xcstrings`, English as the source

## Notes

**Why the question and not the watch's silence.** `RootView` on the watch goes
straight back into a match in progress, and is right to: a watch is opened
between games. A phone is opened in the metro, and dropping someone into a
landscape board of yesterday's abandoned set is the failure this criterion
exists to prevent.

**What counts as stale is a threshold, and thresholds are guesses.** Start at a
few hours, put the number in one named constant, and say in the closing note
what it is. `SavedMatch.lastRallyAt` is what to measure from — the match lasted
until its last point, not until the phone was opened again.

**The tile is not a fourth history state.** `HistoryView`'s `History` enum keeps
apart "unknown", "known" and "unreadable" for a good reason; a running match is
not another one of those. It is a row above the list, and the list underneath it
is whatever it was.

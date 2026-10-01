# 02: The app stops turning the phone

**What to build:** the scoreboard opens and closes without asking for an
orientation, and replaces the tabs instead of covering them.

**Blocked by:** 01

**Status:** ready-for-human

- [x] Nothing in the app requests or narrows an orientation:
      `AppDelegate.orientations`, `supportedInterfaceOrientationsFor` and the
      board's `turn(to:)` are gone, and the `AppDelegate` with them if nothing
      else needs it
- [x] The declared orientations stay as they are: portrait and both landscapes
- [x] `RootView` shows either the tabs or the board, never one over the other,
      and the change between them is a short cross-fade. The full-screen cover
      is gone
- [x] Leaving the board lands on the history, at the top, with its large title
      standing the way a fresh launch draws it
- [x] The idle timer is still held while the board is up and released when it
      leaves
- [ ] On a real iPhone: opening a match held upright shows the stacked board
      with no jump; turning the phone rotates it with the system's animation;
      leaving it never shows the history sideways
- [x] `docs/design/PhoneScore.dc.html` is deleted, with its entry in
      `canvas.json`, its section in `docs/design/README.md`, and the line in
      `CLAUDE.md` that says one board is left waiting on `phone-scoring`

## Notes

**This is what `phone-scoring/06` was about.** The history came home with its
large title collapsed because it was laid out in landscape behind the cover.
With no turn and no cover there is nothing laid out in a window the player is
not looking at. 06 was closed `wontfix` pointing here; check its first criterion
here, on the device.

**The history's scroll position does not survive a match**, and that is
accepted: the tabs are rebuilt when the board leaves. The player left from New
match, not from the history.

## Comments

**Built; 6/7.** The `AppDelegate` and `turn(to:)` are gone. `RootView` swaps
the tabs and the board with a 0.25 s cross-fade. The fade was filmed both ways
on an iPhone 17 Pro simulator. Back and End both land on the history at the top
with its title standing, in English and Russian and at the largest type size.
That includes a history that was scrolled before the match.

**Open: the real-iPhone criterion**, and `phone-scoring/06`'s first criterion
with it. There is no device here, and the simulator cannot be turned by a
script. The owner checks these on a phone, ticks the box and sets `done`.

The idle-timer criterion is ticked from the code, not from a test or a recording:
`onAppear` and `onDisappear` still hold the timer and let it go.

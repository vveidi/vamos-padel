# Any window: every phone screen lays itself out from the window it is given

Status: done

## Problem Statement

The scoreboard holds the phone in landscape by force. It narrows the app's
orientations through an `AppDelegate`, asks for landscape with
`requestGeometryUpdate` on the way in and lets go on the way out. On a real
iPhone that shows in three ways:

- **The turn in is a jump.** The board slides up as a cover in portrait, stands
  there laid out side by side for half a second, then snaps to landscape with
  no rotation animation.
- **The turn out shows the history sideways.** The cover slides down in
  landscape and the history stands behind it, laid out in landscape with its
  tab bar down the side, for about 0.6 s before the phone turns back.
- **The history comes home with its large title collapsed**, because it was
  laid out in landscape behind the cover and kept the scroll offset it took
  there (`phone-scoring/06`).

And it cannot hold. iPhone Duo puts the app in windows the app does not
choose: an outer display, an inner one that is nearly square, and a 50/50 Split
View half. Apple's guidance for it is to design for a freely resizable window
and not for an orientation, and a geometry request means nothing in a Split View
half. A board that can only draw itself in landscape breaks there.

## What is in, and what is not

In:

- The **scoreboard** in any window: the halves side by side in a wide window,
  stacked in a tall one.
- The app **no longer turns the phone**. No orientation is requested and none
  is narrowed.
- The scoreboard **replaces the tabs** rather than covering them.
- **New match, the history and the match card** in a wide window: one column of
  readable width, centred.

Not in:

- **iPhone Duo's own APIs.** The toolchain is Xcode 26.6 and the iOS 26.5 SDK,
  which has no Duo simulator and none of its APIs. This feature makes the app
  right in a window of any shape and nothing more. Checking it on a Duo is
  ticket 04, which waits for the means to do it.
- **A two-pane history** — the list beside the card on a wide display. That is
  a new feature, not a screen fitting its window.
- **Upside-down portrait.** It stays undeclared, as it is on most iPhone apps.

## The design, in words

**The net crosses the long axis of the board's own window.** A window wider than
it is tall puts the halves left and right; any other puts them one above the
other. That keeps each half as wide as the window allows — the halves are never
narrow. It is the rule `docs/design/README.md` already states for
`PhoneScore.dc.html` and the landscape board alike.

**The board reads its own size, not a size class and not the device's
orientation.** A size class cannot say which side of a window is longer: Duo's
inner display is regular by regular in either pose, and an iPhone in landscape
is compact by compact. Only the window's size answers it.

**Stacked, ours is below the net and theirs above it** — the watch's frame
(ADR-0013) and the board's own. Mirroring the board swaps top and bottom the way
it swaps left and right.

**The player turns the phone, the app does not.** A phone held upright shows the
halves stacked; turned, it shows them side by side, with the system's own
rotation animation and the match, the mirroring and the score kept. A player
with rotation lock on gets the stacked board.

**The root swaps between the tabs and the board.** `RootView` shows one or the
other, with a short cross-fade, the way the watch's root answers its one
question. Nothing sits behind the board, so nothing is laid out in a window the
player is not looking at. Leaving the board lands on the history, built fresh,
at the top, with its large title standing.

**A wide window gets a column, not a wider screen.** New match, the history and
the match card cap their content at one readable width, held in one named
constant in `PadelDesign/Tokens/`, and centre it.

## Consequences, stated plainly

- **ADR-0015 reverses a recorded decision.** `phone-scoring`'s spec declined "a
  second scoreboard layout in portrait" and wrote that the board forces the
  rotation. Both stop being true here, and the glossary's **Scoreboard** stops
  calling it the phone's landscape screen.
- **The board is no longer landscape for a player with rotation lock on.** That
  was the reason the geometry request was written; it goes with it.
- **`PhoneScore.dc.html` is built at last.** It is deleted when the stacked
  board ships, and `docs/design/` is left with no board waiting.
- **The history's scroll position does not survive a match.** The tabs are
  rebuilt when the board leaves; the history opens at the top.

## The tickets

```
01  the scoreboard fits its window
02  the app stops turning the phone            blocked by 01
03  a readable column in a wide window
04  checked on an iPhone Duo                   needs-info
```

01 comes before 02 because removing the turn first would show a portrait board
with its halves side by side and narrow. 03 is independent of both.

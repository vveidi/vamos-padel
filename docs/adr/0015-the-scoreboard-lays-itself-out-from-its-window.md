# The scoreboard lays itself out from its window

The scoreboard draws the court across the long axis of the window it is given. A window wider than it is tall puts the halves left and right of a vertical net; any other window — a phone held upright, a square one, a narrow Split View half — stacks them above and below a horizontal net, ours below. The board reads that from its own size, where it already reads its safe area. Not from a size class, which cannot say which side of a window is longer (an iPhone in landscape is compact by compact, iPhone Duo's inner display regular by regular in either pose), and not from the device's orientation, which says nothing about a window that is not the whole screen.

The app does not turn the phone. The player does, and the board follows with the system's own rotation, keeping the score, the mirroring and anything it was asking. A player with rotation lock on gets the stacked board.

## It reverses phone-scoring

`phone-scoring`'s spec (now in `.scratch/archive/phone-scoring/`) recorded the opposite twice, and both stop being true:

- **"A second scoreboard layout in portrait"** was declined. The stacked arrangement is that layout, and it is the one `PhoneScore.dc.html` always drew.
- **"Both orientations everywhere except the scoreboard"** held the board in landscape with `requestGeometryUpdate` and an `AppDelegate` narrowing the app's orientations. That was written so the board stayed landscape under rotation lock. It cost a turn that jumps in, a history shown sideways on the way out, and a board that means nothing in a window the app does not choose — which is what iPhone Duo gives it: an outer display, a near-square inner one, and Split View halves.

## Consequences

- **One frame for the ball's corners.** Stacked, the corners are the watch's (ADR-0013) unturned: our right at screen trailing, theirs at screen leading. Side by side is the same frame turned a quarter turn clockwise, and mirroring is a half turn of either. Nothing else converts a `ServingHalf` for the phone.
- **Mirroring swaps top and bottom when stacked**, and the corners turn with it: mirrored, our serve from the right sits at the bottom leading corner of our half, by the net.
- **VoiceOver reads ours, then theirs**, whichever half the arrangement draws first.
- **The turn goes in `any-window` 02**, not here: until then the app still asks for landscape, and the stacked board is seen only where that request is refused.

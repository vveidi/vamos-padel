# 01: The scoreboard fits its window

**What to build:** the scoreboard's second arrangement — the net horizontal and
the halves stacked — chosen by the board from its own size.

**Blocked by:** None

**Status:** done

- [x] A window wider than it is tall draws the board as it is today: the net
      vertical, the halves left and right. Any other window draws the net
      horizontal and the halves one above the other, each the full width
- [x] The choice is made from the board's own size, read where the board
      already reads its safe area — not from a size class and not from the
      device's orientation
- [x] Stacked, ours is below the net and theirs above it. Mirroring the board
      swaps top and bottom, the ball's corners with it
- [x] Stacked, the ball's corners are the watch's: `ScoreView`'s
      `serveAlignment(for:from:)` frame, unturned — our right at screen
      trailing, theirs at screen leading (ADR-0013)
- [x] The strip, the scrim and the controls sit where `PhoneScore.dc.html`
      draws them in the stacked arrangement: the strip along the top, the
      controls along the bottom
- [x] The points stay the largest thing in each half in both arrangements, and
      no control steals a tap from a half or is swallowed by one
- [x] Turning the phone while the board is up rearranges it with the system's
      rotation, and keeps the score, the mirroring and the confirmation state
- [x] VoiceOver reads the halves in the same order in both arrangements: ours,
      then theirs
- [x] Previews of the stacked board at an iPhone portrait size and at a narrow
      tall window about the size of a Split View half — both rulesets, a golden
      point, mirrored and not, both languages, `.accessibility5`
- [x] ADR-0015 records that the board lays itself out from its window and that
      the app does not turn the phone, and says it reverses the decision in
      `phone-scoring`'s spec ("A second scoreboard layout in portrait", and
      "Both orientations everywhere except the scoreboard")
- [x] `CONTEXT.md`'s **Scoreboard** no longer says "landscape": the court across
      the long axis of its window, a half per side of the net

## Notes

**The app still turns the phone after this ticket.** `turn(to:)` and the
`AppDelegate` stay until 02, so in the app the stacked board is seen only when
the turn is refused — rotation lock, or a window the system will not turn. The
previews and a simulator with rotation lock are where it is checked.

**`PhoneScore.dc.html` is the reference and stays until 02.** It is portrait,
and what `docs/design/README.md` says the app will not do — the labels "Them"
and "Us", the two colours — still holds: position and the net say whose half it
is. Read the board's layout, not its type sizes (`docs/design/README.md`).

**The four corner previews are named for the surprise**, as 04's were: in the
stacked board our serve from the right sits at the top trailing corner of our
half, and the opponents' at the bottom leading corner of theirs.

## Comments

**Shipped.** The board picks its arrangement from its window's size, safe area
added back: wider than tall is side by side, anything else stacked. The ball's
corners are one frame — the watch's, unturned when stacked, a quarter turn
clockwise side by side, a half turn when mirrored. Side by side is unchanged.
ADR-0015 records the reversal; `CONTEXT.md` and `docs/design/README.md` follow.

**Departures from the board.** At the owner's request the three controls are
icons, not words: an undo arrow, two arrows across the net for Mirror, and the
watch's `xmark` for End; VoiceOver still names each. Stacked they share the
width equally; side by side they keep to the board's 118 apiece. The floodlight
moves to our bottom trailing corner when stacked, as on the board and the watch.

**Checked on reasoning, not by ear.** VoiceOver order is set with a sort
priority inside a `.contain` container; no VoiceOver pass was run. The stacked
board, and a rotation keeping the score, the mirroring and the End alert, were
driven on a simulator through a temporary, uncommitted patch that held off
`turn(to:)`. The 340×720 Split View previews compile but were not rendered.

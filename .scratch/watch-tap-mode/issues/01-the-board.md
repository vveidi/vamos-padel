# 01: The board

**What to build:** three watch artboards for what this feature draws — the
tap-mode page, the same component as a card on the start settings page, and the
score screen with the vertical page indicator on it.

**Blocked by:** None

**Status:** ready-for-agent

**This is a `/design` session, not a `/next-ticket`.** There is no code in it,
nothing to build and nothing to drive on a simulator. The boards are published as
a canvas, the owner looks at them, and ticket 03 starts from what they say.

- [ ] `docs/design/WatchTapMode.dc.html` exists with three artboards, drawn 2x
      (396×484 px = 198×242 pt) as every watch board in this repo has been
- [ ] **Tap mode, mid-match**: the page title, the `ChoiceRow` naming its value
      with its chevron, and the three legend lines under it. Drawn in both
      values, so the legend is seen changing
- [ ] **The start settings page**: the same component as a card, in place
      between the rules card and the Health switch, so the whole scroll is
      drawn and its length is known
- [ ] **The score screen with the vertical indicator**: the indicator on the
      trailing edge, and the sets digit and both serve balls indented to clear
      it. This artboard exists to produce one number — how far in the trailing
      furniture moves
- [ ] The legend lines are drawn as the final strings, in both languages:
      `1 tap → your point`, `2 taps → their point`, `long press → undo` for
      multi-tap; `tap bottom → your point`, `tap top → their point`,
      `long press → undo` for tap zones
- [ ] The board is added to `docs/design/canvas.json` alongside the two phone
      boards
- [ ] `docs/design/README.md` is updated: "Two artboards and the canvas" becomes
      three boards, and the new one is listed in the table with the tickets that
      read it

## Notes

**Layout transfers, type does not.** `docs/design/README.md`, "Reading the
boards" — the board decides which ramp entry a thing gets and what the paddings
are, never the point size and never the typeface.

**Why the score screen is drawn again even though it ships.** The rule is that a
board exists only for a screen that has not been built. What has not been built
is the trailing edge with a page indicator on it: `.verticalPage` puts one where
the sets digit sits at `.trailing` and where the serve ball's inner corners are
(`.topTrailing` in our zone, `.bottomTrailing` in theirs). That collision is a
layout question, and the honest way to answer it is to look at it.

**All three boards are deleted as their tickets close** — 03 and 04 for the first
and third, 05 for the second — and `docs/design/README.md` goes back to two. The
numbers survive in the screens' private `Board` enums, halved, the way every
watch board's numbers already have.

# 04: The vertical match stack and the tap-mode page

**What to build:** somewhere to change the mode while a match runs. The match's
pages turn vertical, as the start screen's already are, and a third page joins
them: End above, the score in the middle, tap mode below.

**Blocked by:** 01, 03

**Status:** ready-for-agent

- [ ] `ScorePages` is `.tabViewStyle(.verticalPage)` with three pages in the
      order End, score, tap mode, and the score is still what opens
- [ ] A `NavigationStack` goes around the pages, the arrangement `StartPages`
      proved out. **The bar is not hidden** — the score page has no title and
      reserves none, the tap-mode page is titled "Tap mode" and gets one, which
      is where its pushed list finds its Back button
- [ ] The tap-mode page is a `ChoiceRow` naming the current value and pushing a
      list of the two, in `Padel Watch App/Sources/Settings/` with the type
- [ ] Three legend lines under the row, changing with the value:
      `1 tap → your point` / `2 taps → their point` / `long press → undo` for
      multi-tap, and `tap bottom → your point` / `tap top → their point` /
      `long press → undo` for tap zones
- [ ] The row plus its legend is one component, reusable as-is by 05 — it is
      put in a second place there and must not be written twice
- [ ] The sets digit and both serve balls are indented off the trailing edge to
      clear the vertical page indicator, by the number board 01 gives
- [ ] `serveAlignment(for:from:)`'s doc comment no longer justifies the inner
      corners by "the page dots of `ScorePages` sit over our bottom" — the dots
      are on the trailing edge now, and the comment says what is true
- [ ] Previews of the tap-mode page in both languages, both values, and at
      `.accessibility5`, as `StartPages` and `RulesetSettings` have
- [ ] The Russian strings for the page title, both value names and all four
      legend lines are in the catalog
- [ ] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean,
      and the page is driven on a simulator: score → tap mode → the pushed list
      → back, and the match still scores afterwards
- [ ] `docs/design/WatchTapMode.dc.html` loses the two artboards this ticket
      built — the mid-match page and the score screen — per
      `docs/design/README.md`

## Notes

**Why three pages and not two.** End is destructive and belongs as far as
possible from the surface being tapped forty times a match; tap mode goes on the
other side of the score. Folding both onto one settings page, the way
`StartPages` does, would put the End button one flick from the score.

**Why a pushed list and not two pills in place.** `RulesetSettings`' doc comment
argues that on a 198pt screen a row-plus-list and an in-place control are the
same act, and the app has one vocabulary for a choice. This follows it.

**The bar is the thing to get wrong here.** `StartPages`' doc comment records
what happened the last time it was hidden by hand: every push logged
"Transitioning bar did not exist during transition" from SaltUICore, and the
pushed screen had no way back. Do not hide it.

# 04: The vertical match stack and the tap-mode page

**What to build:** somewhere to change the mode while a match runs. The match's
pages turn vertical, as the start screen's already are, and a third page joins
them: End above, the score in the middle, tap mode below.

**Blocked by:** 01, 03

**Status:** done

- [x] `ScorePages` is `.tabViewStyle(.verticalPage)` with three pages in the
      order End, score, tap mode, and the score is still what opens
- [x] A `NavigationStack` goes around the pages, the arrangement `StartPages`
      proved out. **The bar is not hidden** — the score page has no title and
      reserves none, the tap-mode page is titled "Tap mode" and gets one, which
      is where its pushed list finds its Back button
- [x] The tap-mode page is a `ChoiceRow` naming the current value and pushing a
      list of the two, in `Padel Watch App/Sources/Settings/` with the type
- [x] Three legend lines under the row, changing with the value, each a pair
      with no arrow — the gesture leading, what it does trailing:
      `1 tap` · `your point` / `2 taps` · `their point` / `long press` · `undo`
      for multi-tap, and `tap bottom` · `your point` / `tap top` ·
      `their point` / `long press` · `undo` for tap zones
- [x] The row plus its legend is one component, reusable as-is by 05 — it is
      put in a second place there and must not be written twice
- [x] The sets digit and both serve balls are indented off the trailing edge to
      clear the vertical page indicator, by the number board 01 gives
- [x] `serveAlignment(for:from:)`'s doc comment no longer justifies the inner
      corners by "the page dots of `ScorePages` sit over our bottom" — the dots
      are on the trailing edge now, and the comment says what is true
- [x] Previews of the tap-mode page in both languages, both values, and at
      `.accessibility5`, as `StartPages` and `RulesetSettings` have
- [x] The Russian strings for the page title, both value names and all four
      legend lines are in the catalog
- [x] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean,
      and the page is driven on a simulator: score → tap mode → the pushed list
      → back, and the match still scores afterwards
- [x] `docs/design/WatchTapMode.dc.html` loses the two artboards this ticket
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

## Comments

**Closed.** The match is three vertical pages — End, score, tap mode — in a
`NavigationStack` with the bar left alone. `TapModeSettings` (the card plus the
legend) is the component 05 drops in; `TapModePage` wraps it for the match.
The tap mode is now a binding from `RootView`'s `@AppStorage`, so a change
lands on the running match at once.

Driven on a 46mm simulator in both languages: score → tap mode → list → Back,
both values, then scoring in both modes. At 16pt the sets digit and the
trailing ball clear the real indicator by about 9pt. Largest type was checked
with a temporary root-level `.dynamicTypeSize` — the watch runtime refuses
`simctl ui content_size`. Russian tap zones wraps "касание вверху" there.

The page-dots sentence was never in `serveAlignment`'s doc comment; it was in
ADR-0013, which now says what is true.

Open for the owner: the page title is "Tap mode" as written here, so it sits
right above the row's own "Tap mode" label; the board had "Settings".

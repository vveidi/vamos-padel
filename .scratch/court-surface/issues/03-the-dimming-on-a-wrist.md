# 03: The dimming, on a wrist

**What to build:** `CourtDimming.surface` settled on a real watch, which is the
one criterion ticket 01 could not meet.

**Blocked by:** None

**Status:** ready-for-human

- [ ] The court is looked at in Always-On on a real Apple Watch, mid-match, at
      arm's length — the state a match actually spends most of its ninety
      minutes in
- [ ] `CourtDimming.surface` is confirmed at 0.72 or moved, and the number that
      ships is the one that was seen rather than the one that was computed
- [ ] Its doc comment says what was settled on the wrist, replacing the rendered
      measurements standing in for it now
- [ ] `AlwaysOnTests`' `fell > 0.6` floor still holds, or moves with the number
      and says why
- [ ] `swift test --package-path Packages/PadelDesign` is clean

## Notes

**Why this is `ready-for-human` and not `ready-for-agent`.** There is no way for
an agent to reach the answer. The watchOS simulator offers no Always-On state —
not through the Simulator's Device or Features menus, not through `simctl ui`,
which has only `appearance`, `increase_contrast` and `content_size`, and the
last of those is refused outright by the watchOS runtime. Burn-in and legibility
at arm's length are both eye questions on real hardware.

**Where the number stands today.** 0.72, up from the 0.55 that was held shallow
so the two old half tints would not merge into one black rectangle when the
lights went down. With one surface there is nothing to stay apart from, so the
fall answers only to burn-in and to whether the score is still readable.

It was settled from rendered measurements, which is what ticket 01's spec said
would not do — *"the dimming number in particular cannot be settled from a
canvas: it is an Always-On question and answers only on a watch."* What was
measured: the dimmed surface at 0.119 luminance against `night`'s 0.079, still
blue at rgb(7, 34, 51) rather than gray, and `courtInk` standing off it at
5.8 : 1. All three are necessary and none of them is sufficient.

**What to look for on the wrist.** Whether the court still reads as a court
rather than as the app's ground with a net drawn across it, and whether the
score is still findable without raising the wrist. If it is too dark, the number
comes down; if the ink is haloing or the surface is still bright enough to worry
about burn-in over ninety minutes, it goes up.

**This ticket exists because the rule says so.** It replaces the `TODO:` that
sat above the constant. `CLAUDE.md`: work that is not done is a ticket, never a
comment — a comment the board cannot see is work that never appears as work.

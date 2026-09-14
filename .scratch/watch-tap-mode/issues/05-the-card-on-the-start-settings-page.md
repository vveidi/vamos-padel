# 05: The card on the start settings page

**What to build:** the same choice before the match. The component 04 built,
put on `StartPages`' settings page as a card of its own between the rules and
the Health switch.

**Blocked by:** 03, 04

**Status:** ready-for-agent

- [ ] A `SettingsCard` holding the row-plus-legend component from 04, placed
      between the ruleset sentence and the Health card
- [ ] It is the same component, not a second copy of the row and the three lines
- [ ] It reads and writes the same `@AppStorage("tap-mode")`, so a mode chosen
      here is the mode the match starts with and a mode chosen mid-match is what
      this card shows next time
- [ ] The page's gaps come from `StartPages`' private `Board` enum, and any new
      number in it is read off board 01 and quotes it in its doc comment the way
      the others do
- [ ] Previews of the whole settings page in both languages and at
      `.accessibility5`, scrolled to the foot — the page grows by a card and the
      Health switch at the bottom has to stay reachable
- [ ] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean,
      and the page is driven on a simulator: scroll to the card, open the list,
      come back, start a match, and the mode chosen is the mode in force
- [ ] `docs/design/WatchTapMode.dc.html` is deleted — its last artboard is built
      — and removed from `docs/design/canvas.json`;
      `docs/design/README.md` goes back to two boards
- [ ] CLAUDE.md's "Where things live in the two apps" gains
      `Settings/  the tap mode, before a match and during one`, noted as the one
      watch folder named for a screen rather than for what the player is doing
- [ ] `CONTEXT.md`'s **Tap mode** entry is accurate against what shipped

## Notes

**Why between the rules and Health, not after it.** Tap mode is about the match
being set up, so it belongs with the rules; the Health switch is the page's odd
one out and reads best last.

**`StartSettings` stays in `Start/`.** Only the component comes from
`Settings/`. Moving the start page's own settings section out would split
`StartPages` across two folders to no purpose.

**This is the ticket that closes the feature.** The board is gone, the docs
agree with the code, and both ways of reaching the setting exist — after 03 and
04 alone there is a default with no way back to tap zones, which is not a state
to leave the feature in.

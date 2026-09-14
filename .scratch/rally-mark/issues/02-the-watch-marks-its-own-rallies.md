# 02: The watch marks its own rallies

**What to build:** the mark on the watch's score screen, fired by the journal
growing and not by the finger.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Each `ScoreZone` in `ScoreView.swift` carries the mark from ticket 01, and
      the zone that is marked is the one whose side won the rally
- [ ] `ScoreView` is given what it needs to know a rally landed — which side won
      it and that it is a *new* one — and `MatchView` computes that from
      `saved.match`'s journal. **Not from `record(rallyWonBy:)`**: ADR-0009 says
      the watch draws nothing it has not been given, and ADR-0011 keeps the mark
      on the honest side of that line while the haptic stays on the other
- [ ] The tier is the games or the sets having moved with the rally — both are
      already handed to `ScoreView`. A match to N points has no games, so it has
      one tier, and that is correct rather than a gap
- [ ] **An undo marks nothing.** The journal shrinking is not a rally landing,
      and the mark must not fire on it
- [ ] **The screen appearing marks nothing.** A match continued after an
      interruption, or the score page swiped back to, opens at its score and does
      not replay the last rally
- [ ] A `TODO:` where the origin filter will go, naming
      `.scratch/phone-scoring/issues/09-the-watch-becomes-a-remote.md` — today
      every rally on this screen is one the watch awarded, and after 09 it is
      not. One line, in the spelling Xcode's jump bar lists
- [ ] The haptics of `watch-tap-mode` 02 are untouched wherever they have landed
      by then: they answer the finger, the mark answers the journal, and the two
      are deliberately not wired together
- [ ] Previews of a zone marked at peak, both tiers, both sides — using ticket
      01's inner view, since an animation's resting state is nothing to look at
- [ ] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean,
      and the screen is driven on a simulator: rallies to both sides, a game
      taken, an undo, and the score still scores afterwards

## Notes

**Why the trigger is the journal and not the tap.** ADR-0009: "The watch never
draws a point it has not been given. No optimistic update: a scoreboard that
shows 40 and takes it back is worse than one that is late." Today the watch holds
the match, so the journal grows in the same update as the tap and the distinction
costs nothing. It stops being free at `phone-scoring` 09, and the code written
here is the code that is still correct then — which is the only reason to write
it this way now.

**Why the haptic and the mark are not one call.** `watch-tap-mode` 02 fires the
haptic from `MatchView`'s funnel, deliberately optimistic, and accepts that an
intent later refused will have buzzed. The mark does not take that trade. Wiring
them together would force one of the two decisions onto the other.

**The match-winning rally will not be seen.** It marks a screen that
`MatchView` replaces with `OutcomeView` in the same update. Do not chase it: the
feature marks no match ending, for the same reason `watch-tap-mode` 02 plays no
extra haptic for one.

**Do not hide the navigation bar** for any of this, and do not change the page
stack. `watch-tap-mode` 04 is doing that work and `StartPages`' doc comment
records what happened the last time a bar was hidden by hand. This ticket adds an
overlay to two zones and nothing else.

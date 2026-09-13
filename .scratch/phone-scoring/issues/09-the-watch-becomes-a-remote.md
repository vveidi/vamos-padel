# 09: The watch becomes a remote

**What to build:** the watch keeps its score screen and loses its match. What it
draws is the last journal the phone sent; what its taps do is ask.

**Blocked by:** 03, 04

**Status:** ready-for-agent

- [ ] `RootView` no longer asks a store what is in progress. It asks the remote,
      and the remote asks the phone
- [ ] The score screen draws the state computed from the journal that arrived,
      with `PadelScoring` on the watch as before
- [ ] A tap sends `rally(wonBy:base:)`; the long press sends `undo(base:)`; the
      control page's "End" sends `end(base:)`. Nothing is drawn until the
      journal comes back
- [ ] The start screen sends `start(ruleset:firstServer:)` and waits for the
      match to arrive before showing the score
- [ ] The start screen is refused while the phone is unreachable, and says so —
      a match cannot begin without the phone (ADR-0009)
- [ ] The ruleset it offers comes from the phone with the link, not from a store
      on the watch
- [ ] Losing the link mid-match: the screen says the phone is unreachable and
      stops taking taps. The score stays on screen, visibly stale rather than
      silently wrong
- [ ] Getting it back resumes with whatever the phone holds, with no merge and
      no replay of what was tapped in the meantime
- [ ] The outcome screen is reached the same way it is now — from the match
      being over, which is now a fact that arrives rather than one computed here
- [ ] `MatchView` no longer writes to a store or calls a delivery
- [ ] Previews cover: a live match, an unreachable phone, and a match that ended
- [ ] The new strings are in `Shared/Localizable.xcstrings`, English as the
      source, and spoken by VoiceOver where they are drawn

## Notes

**The screen itself barely changes**, and that is the point: `ScoreView` already
takes a `Points`, a `SideCounts?`, a serving side and two closures. What changes
is where those come from and what the closures do.

**On the refusal being visible.** The watch refusing a tap has to look different
from the watch accepting one, or the player taps twice and wonders. Whatever it
is — the score dimming, the half not flashing — say in the closing note what was
chosen and what it looked like on a wrist.

**On the start screen's ruleset.** `lastRuleset()` was always asked of the store
rather than kept beside it (ADR-0001's argument, one level up). It still is —
just of the phone's store, over the link.

# 05: The watch becomes a remote

**What to build:** in a paired match the watch keeps its score screen and loses
its match. What it draws is the last journal the phone sent; what its taps do is
ask. A solo match on the watch is untouched.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] `RootView` asks two questions: the watch's own store for a solo match in
      progress, as today, and the remote for a paired one. The remote asks the
      phone
- [ ] The score screen of a paired match draws the state computed from the
      journal that arrived, with `PadelScoring` on the watch as before
- [ ] A tap sends `rally(wonBy:base:)`; the long press sends `undo(base:)`; the
      control page's "End" sends `end(base:)`. Nothing is drawn until the
      journal comes back
- [ ] A paired start sends `start(ruleset:firstServer:)` and waits for the
      match to arrive before showing the score. The ruleset and the first server
      are the start screen's own, from the watch's store as today (ticket 08
      decides when a start is paired)
- [ ] A refused intent looks different from an accepted one, read off the echo
      (ticket 01), so the player does not tap twice and wonder
- [ ] Losing the link mid-match: the screen says the phone is unreachable and
      stops taking taps. The score stays on screen, visibly stale rather than
      silently wrong. Nothing is buffered to send later
- [ ] Getting it back resumes with whatever the phone holds, with no merge and
      no replay of what was tapped in the meantime
- [ ] The outcome screen is reached the same way it is now — from the match
      being over, which in a paired match is a fact that arrives rather than one
      computed here
- [ ] In a paired match `MatchView` writes to no store and calls no delivery;
      in a solo match it does both, as today
- [ ] The rally mark keeps to ADR-0011's "a device marks the rallies it
      awarded": a rally lights the half only when it arrives with an accepted
      echo of this watch's own `rally` intent. A rally awarded on the phone
      moves the score and lights nothing
- [ ] Previews cover: a live paired match, an unreachable phone, a refused tap,
      and a paired match that ended
- [ ] The new strings are in `Shared/Localizable.xcstrings`, English as the
      source, and spoken by VoiceOver where they are drawn

## Notes

**The screen itself barely changes**, and that is the point: `ScoreView` already
takes a `Points`, a `SideCounts?`, a serving side and two closures. What changes
is where those come from and what the closures do.

**On the refusal being visible.** Whatever it is — the score dimming, the half
not flashing, a haptic of its own — say in the closing note what was chosen and
what it looked like on a wrist.

**On the start screen's ruleset.** It stays the watch's: `lastRuleset()` is
asked of the watch's own store, which survives because the watch still scores
solo matches. The start screen draws without waiting on the link, and the
ruleset is what was chosen on the wrist, whichever device then holds the match.

**On the link being lost.** The match freezes on the wrist and goes on on the
phone (ticket 04): the phone is the scorer, and the watch is only ever looking
at it. The hint the screen gives is to bring the phone back in range, not to
keep playing.

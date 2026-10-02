# 05: The watch becomes a remote

**What to build:** in a paired match the watch keeps its score screen and loses
its match. What it draws is the last journal the phone sent; what its taps do is
ask. A solo match on the watch is untouched.

**Blocked by:** 02, 03

**Status:** done

- [x] `RootView` asks two questions: the watch's own store for a solo match in
      progress, as today, and the remote for a paired one. The remote asks the
      phone
- [x] The score screen of a paired match draws the state computed from the
      journal that arrived, with `PadelScoring` on the watch as before
- [x] A tap sends `rally(wonBy:base:)`; the long press sends `undo(base:)`; the
      control page's "End" sends `end(base:)`. Nothing is drawn until the
      journal comes back
- [x] A paired start sends `start(ruleset:firstServer:)` and waits for the
      match to arrive before showing the score. The ruleset and the first server
      are the start screen's own, from the watch's store as today (ticket 08
      decides when a start is paired)
- [x] A refused intent looks different from an accepted one, read off the echo
      (ticket 01), so the player does not tap twice and wonder
- [x] Losing the link mid-match: the screen says the phone is unreachable and
      stops taking taps. The score stays on screen, visibly stale rather than
      silently wrong. Nothing is buffered to send later
- [x] Getting it back resumes with whatever the phone holds, with no merge and
      no replay of what was tapped in the meantime
- [x] The outcome screen is reached the same way it is now — from the match
      being over, which in a paired match is a fact that arrives rather than one
      computed here
- [x] In a paired match `MatchView` writes to no store and calls no delivery;
      in a solo match it does both, as today
- [x] The rally mark keeps to ADR-0011's "a device marks the rallies it
      awarded": a rally lights the half only when it arrives with an accepted
      echo of this watch's own `rally` intent. A rally awarded on the phone
      moves the score and lights nothing
- [x] Previews cover: a live paired match, an unreachable phone, a refused tap,
      and a paired match that ended
- [x] The new strings are in `Shared/Localizable.xcstrings`, English as the
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

## Comments

**Done.** `MatchView` takes a `Scoring` — alone, with the store and the
delivery, or paired, with the remote — and the same screen draws either. A
paired match writes nothing on the watch: two were played on a simulator pair
and the watch's database stayed empty, while a solo match after them was
written as before.

- **The wire says whether a match is paired.** Without it the watch took up
  any match the phone held, including one scored there alone, and the phone
  accepted its taps. `MatchUpdate.match` now carries `isPaired`; a `start`
  intent is always paired, `MatchScorer.start` is told, and the phone's new
  match screen passes `false` until ticket 08 draws its switch. An intent into
  a match the phone scores alone is refused.
- **The paired start is reached through `@AppStorage("starts-paired")`**, off,
  with no row yet. Ticket 08 draws the row; until then it was set with
  `defaults write` to drive the start.
- **The refusal.** The numbers shake once, the `.failure` haptic plays, and no
  half lights. Seen on a simulator recording; the haptic was not felt on a
  wrist. The tap's own haptic still fires with the finger (ADR-0011), so a
  refused rally feels like the direction and then the failure.
- **The outcome screen of a paired match has no undo.** The phone refuses any
  intent on a match that is over, so the button could only ever fail.
- **Unreachable and the rejoin were checked through a fake link.** The
  simulator pair never reported the phone unreachable, even with the phone
  simulator shut down. The overlay, the dead taps, and the ended and waiting
  screens were driven through a throwaway root swapped onto the previews' fake
  phone. On the real pair, the phone did resend its state when the watch came
  back. Ticket 07 is where the rest is seen.
- **The mark** was not caught on screen: it is gone before a screenshot lands.
  A phone rally was caught lighting nothing.
- **The workout of a paired match is ticket 04's `PairedWorkout`.** A start on
  the wrist calls its `begin()` once the intent is sent; `MatchView` runs no
  workout of its own in a paired match. The app holds one `MatchRemote`, shared
  with `PairedWorkout`, because the transport keeps one update handler.
- **Left for the phone:** a match started from the wrist is held by the phone's
  scorer but not put on its screen. Ticket 09.

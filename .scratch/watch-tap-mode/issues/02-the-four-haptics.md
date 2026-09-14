# 02: The four haptics

**What to build:** the wrist saying back what just happened. Four distinct
haptics — our point, their point, undo, and the confirmed End — in both tap
modes, so that a rally needs no glance to be confirmed.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] `MatchView.record(rallyWonBy:)` plays `.directionDown` for `.us` and
      `.directionUp` for `.them`
- [ ] `MatchView.undo()` plays `.retry`
- [ ] The End button inside the confirmation dialog on `ScorePages`' control
      page plays `.stop`; the cancel button plays nothing
- [ ] A match ending by itself plays nothing extra — the rally that ended it has
      already buzzed
- [ ] `WKInterfaceDevice.current().play(_:)` and not `.sensoryFeedback`, for the
      reason `StartView.start(_:)` already gives: the feedback watches a value,
      and the value changes in the same update that tears the view down
- [ ] `StartView.start(_:)`'s doc comment no longer says "a match starting is
      worth one, a rally scored is not" — that sentence is what this ticket
      reverses
- [ ] The undo on `OutcomeView` buzzes too, which comes free from firing in
      `MatchView` rather than in the gesture
- [ ] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean

## The choices

| what happened | haptic           |
| ------------- | ---------------- |
| our point     | `.directionDown` |
| their point   | `.directionUp`   |
| undo          | `.retry`         |
| End confirmed | `.stop`          |

## Notes

**Why `MatchView` and not the gesture.** The buzz answers the finger, and
`record`/`undo` are the same millisecond as the gesture today — and stay the same
millisecond after `phone-scoring` 09, where the intent is sent rather than
awaited. Firing from the funnel costs nothing and picks up the two paths a
gesture recognizer would miss: the VoiceOver action on each zone, and the undo on
the outcome screen after a match-ending mis-tap.

The consequence is that an intent the phone later refuses will have buzzed first.
That is 09's to answer with feedback for a refusal; making every accepted tap
feel slow to be honest about the rare refused one is the wrong trade.

**Why up is theirs and down is ours.** It follows the screen and not the
sentiment: the opponents are on top, we are at the bottom, and in tap zones the
finger literally goes down for your own point. `.directionUp`/`.directionDown`
is also the only pair in `WKHapticType` designed to be told apart from each
other.

**This cannot be judged in a simulator**, which has no haptics at all. The pair
is provisional until it is felt on a wrist: two people on a court, not looking,
saying which side just scored. If the two are indistinguishable, fall back to
`.click` for us and `.notification` for them — and record that in the closing
note, because the next person will wonder why the table above is not what
shipped.

**Forty buzzes a match, in both modes, is deliberate** and not an oversight to be
softened with a switch. watchOS has a system-wide haptics setting and the app adds
none of its own.

# 02: The four haptics

**What to build:** the wrist saying back what just happened. Four distinct
haptics — our point, their point, undo, and the confirmed End — in both tap
modes, so that a rally needs no glance to be confirmed.

**Blocked by:** None

**Status:** done

- [x] `MatchView.record(rallyWonBy:)` plays `.directionDown` for `.us` and
      `.directionUp` for `.them`
- [x] `MatchView.undo()` plays `.retry`
- [x] The End button inside the confirmation dialog on `ScorePages`' control
      page plays `.stop`; the cancel button plays nothing
- [x] A match ending by itself plays nothing extra — the rally that ended it has
      already buzzed
- [x] `WKInterfaceDevice.current().play(_:)` and not `.sensoryFeedback`, for the
      reason `StartView.start(_:)` already gives: the feedback watches a value,
      and the value changes in the same update that tears the view down
- [x] `StartView.start(_:)`'s doc comment no longer says "a match starting is
      worth one, a rally scored is not" — that sentence is what this ticket
      reverses
- [x] The undo on `OutcomeView` buzzes too, which comes free from firing in
      `MatchView` rather than in the gesture
- [x] `set -o pipefail; xcodebuild … -scheme "Padel Watch App" build` is clean

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
millisecond after `paired-scoring` 05, where the intent is sent rather than
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

## Comments

**Done.** Two files, three call sites: `MatchView.record(rallyWonBy:)` and
`MatchView.undo()` in `Padel Watch App/Sources/Match/MatchView.swift`, and the
dialog's End button in `ScorePages.swift`. No other file changed.

**The haptics are not verified, and cannot be here.** The watch simulator has
no haptics — nothing rings, and nothing logs either, so what was driven on a
40mm simulator is that every path still reaches its funnel and the screen does
what it did before: a point to each side, a long press undoing one, End through
the confirmation dialog to the outcome screen, and a match won 5–0 (scoring to
5 points) undone from `OutcomeView` back to 4–0 on the score screen. The
`.directionUp`/`.directionDown` pair stays provisional until it is felt on a
wrist, exactly as the ticket says. If the two turn out to be indistinguishable
on court, the fallback is `.click` for us and `.notification` for them, and the
change is one line.

**One departure: `undo()` buzzes only when a rally actually came off.** The
criterion reads "`MatchView.undo()` plays `.retry`" flat, and the first pass
wrote it flat. Code-review's spec axis caught that `SavedMatch.undo(at:)` is a
guarded no-op on an empty journal (`guard match.undo() else { return }`), so a
long press at 0–0 buzzed as though a rally had been taken back — a false
confirmation, in the one case the player cannot check without looking, on a
feature whose whole claim is that the buzz means a glance is unnecessary. It
now compares the journal's count either side of the call and plays only when it
shrank. Driven: four undos from 4–0 down to 0–0, then a fifth long press that
changes nothing.

`record(rallyWonBy:)` is left firing before the mutation and unconditionally.
`Match.record` refuses only a match that is already over, and a finished match
shows `OutcomeView` rather than the tap zones, so there is no reachable path
where it buzzes for nothing. The asymmetry between the two methods is that, and
is worth knowing about if `paired-scoring` 05 ever makes `record` refusable
from the screen.

**The `StartView` criterion was already true before this ticket started.** "A
match starting is worth one, a rally scored is not" left
`Padel Watch App/Sources/Start/StartView.swift` in commit `43d4aa7`, comment-diet
ticket 02; a repo-wide grep now finds the sentence only in this ticket and the
spec. Nothing was edited there, so do not look for it in the diff. What survives
on `start(_:)` is the `WKInterfaceDevice`-over-`.sensoryFeedback` reason, which
is still true and is what the fifth criterion points at.

**What code-review raised.**

- *Standards, hard violation, fixed.* The first pass put a two-line comment
  over the direction ternary — "down is ours and up is theirs because that is
  where the two halves are on the screen". It restated the code's own ternary
  and then repeated this ticket's "Why up is theirs and down is ours" note
  verbatim, which `CLAUDE.md` puts in the ticket and not in the source. Deleted.
- *Spec, confirmed defect, fixed.* The unconditional undo buzz, above.
- *Standards, judgment call, left alone.* `WKInterfaceDevice.current().play(_:)`
  now appears at four sites in three files, and the `.click`/`.notification`
  fallback would be an edit at three of them. The review named it and said a
  helper today would read as speculative generality. Left as four call sites;
  say the word if the fallback ever lands and it should become one.
- *Standards, judgment call, left alone by the spec's own instruction.* `.stop`
  fires inside `MatchControls`' dialog button rather than from
  `MatchView.abandon()`, which is that path's funnel — and it is what forces
  `import WatchKit` into `ScorePages.swift`. The spec asks for it there in so
  many words ("plus the confirmation button on the control page"), so it was
  built as written.

**Not run:** the phone's tests. Nothing outside `Padel Watch App/` changed, and
the watch scheme has no test action of its own — `PadelTests` is hosted by the
phone app and reads its strings, and this ticket adds no string. The build is
clean on `Padel Watch App` against a watchOS 26.5 simulator. For the same
reason there was no Russian pass or largest-Dynamic-Type pass worth the name:
the change adds no words and moves no pixel. The simulator happened to be in
Russian throughout anyway.

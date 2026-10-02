# 03: The board marks them all

**What to build:** the mark on the phone's scoreboard, on every rally whatever
its origin — which is the case this whole feature was opened for.

**Blocked by:** 01

**Status:** done

- [x] Each half of the scoreboard carries the mark from ticket 01, and the half
      that is marked is the one whose side won the rally
- [x] **Every rally is marked, whatever awarded it.** A rally tapped into the
      wrist marks the board. There is no origin filter here, and the one
      `paired-scoring` 05 adds to the watch has no counterpart in this file — ADR-0011 says why the two devices
      differ — *moved to `paired-scoring` 08: under ADR-0009 the phone records
      every rally it draws, so there is no wrist origin yet to mark*
- [x] The trigger is the journal the board is already drawing from, not the tap
      on a half: a rally the phone awards and a rally that arrives over the live
      link go through one path and look identical — *the journal half is met; the
      live-link half moved to `paired-scoring` 08*
- [x] The tier is the games or the sets having moved, as on the watch
- [x] An undo marks nothing; the board appearing marks nothing; mirroring the
      board marks nothing
- [x] **The strength is re-checked by eye at phone size and in landscape**, and
      the number in `CourtColors.swift` is corrected if the wrist's is wrong
      there. A half on a phone is roughly 426×393pt against the watch's whole
      198pt screen, and the mark is read from a bench rather than from arm's
      length
- [x] Previews of both halves marked at peak, both tiers, mirrored and not
- [x] `set -o pipefail; xcodebuild … -scheme Padel build` is clean, and the board
      is driven on a simulator with a watch awarding the rallies — the mark on a
      rally the phone did not award is the one thing here that cannot be checked
      from the phone alone — *the build is clean and the board was driven with the
      phone awarding the rallies; the watch-awarded run moved to
      `paired-scoring` 08*

## Notes

**Why the phone marks what the watch does not.** The asymmetry is the room and
not the code. On the wrist the mark confirms something you just did and already
know about — the haptic said so. Nobody is holding the phone: it is a scoreboard
read by four people, none of whom awarded anything, and a rally that moves it
silently is the problem in the spec's first paragraph. Making the two devices
behave alike would be a consistency nobody standing on a court would benefit
from.

**Half of this ticket is waiting on a feature that has not been specced yet.**
It was written when the phone was about to hold every match and the watch was
about to become its remote. That was cut: a match now has one scorer and it is
the device it was started on (ADR-0009), so a phone scoreboard marks the rallies
it records and there is no second origin to mark, no live link to arrive over,
and no unreachable watch to draw around. Everything about two origins — the
criterion about a rally tapped into the wrist, the one about the journal rather
than the tap being the trigger, and the simulator run with a watch awarding the
rallies — belongs to `paired-scoring`. Read this ticket again when
`phone-scoring` 04 lands; what survives the re-read is a mark on a half, and it
is most of the work.

**The number may well differ from the watch's.** That is not a failure of ticket
01 — strength is a property of the surface it is drawn on, and a phone in
landscape at bench distance is a different reading of the same surface. If it
does differ, say so in the closing note, because the next person will read
`CourtColors.swift` and wonder which of the two numbers was measured and which
was guessed.

## Comments

**Shipped.** `ScoreboardView` watches `saved.match.journal` and, when it grows,
hands each half a `RallyMark`, as `MatchView` does on the watch. Driven on an
iPhone 17 Pro simulator and measured frame by frame: each side lights only its
own half, stacked and side by side, mirrored and not; a game holds its peak
~0.4s; an undo, a mirror and the board appearing light nothing.

**The strength stays at 1.0.** Re-checked by eye on simulator stills at phone
size, portrait and landscape, and at the largest type: the half reads as lit
and still blue, and the score on it reads. So the watch's number holds on the
phone. Not checked on a real phone from a bench.

**Three criteria moved, not met.** Everything about a rally the watch awarded
went to `paired-scoring` 08. Under ADR-0009 the phone has no second origin yet.

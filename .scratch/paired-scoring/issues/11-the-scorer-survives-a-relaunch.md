# 11: The phone's scorer survives a relaunch

**What to build:** `MatchScorer` lives in memory and starts empty. A phone app
jettisoned or crashed mid-match, then relaunched, broadcasts that there is no
match: the watch closes the unfinished match it was the remote of, and the
history keeps it "in progress" with no way to go on with it.

The store learns how each match was scored, and the phone's scorer takes its
own unfinished match back from it on launch, before the link comes up.

**Blocked by:** 05

**Status:** done

- [x] **The store says how a match was scored.** One column on `match`, written
      for every match and with no default: scored alone on the watch, scored
      alone on the phone, or paired. `SavedMatch` carries it, the wire carries
      it, and a match delivered from the watch arrives saying the watch scored
      it. The schema is edited in v1 (ADR-0014)
- [x] **The phone takes back its own match, and only its own.** On launch the
      scorer reads the last match the phone scored — alone or paired — and holds
      it again if it is unfinished, paired or not as the store says. A match the
      watch scored is never taken up, whatever its state
- [x] **The same rule as the watch's `restore()`.** The last of the phone's own
      matches comes back however long ago it was left, and an older unfinished
      one never does. A player who did not want it back ends it
- [x] **The watch never hears that there is no match.** The match is held
      before `transport.activate()`, so the first update the watch gets after a
      relaunch is the match as it stood, and a paired match goes on from the
      wrist where it was
- [x] Tests cover the column round-tripping through the store and the wire, a
      scorer built over a store holding an unfinished paired match, one holding
      an unfinished solo match, one whose last match the watch delivered, and
      one whose last phone match is over
- [x] Driven on a simulator pair: a paired match a few rallies in, the phone
      app terminated and relaunched, the board back at the same score and the
      watch still on it; then the same with a solo phone match

## Notes

Found while triaging ticket 09. Ticket 07 already checks this on a real pair —
"the journal must come back from the store, not from memory", and a force-quit
app reopened to find the match where it was — and would fail both today.

ADR-0009 already promises that a phone match "survives being backgrounded or
terminated by being read back from the store"; this ticket makes it true again.
Neither it nor ADR-0017 needs a word changed.

Whether HealthKit hands the mirrored workout back to a relaunched app is not
something a simulator can show. 07 checks it on a real pair.

## Comments

**Triage.** The phone never receives an unfinished match today — the watch
delivers only matches that are over — so `matchInProgress()` could already
tell the phone's own match apart. The owner chose to write the scorer into the
store anyway, rather than lean on how the delivery happens to behave, and to
store pairing beside it: one column with three values, since a paired match is
always the phone's.

**Closed.** `SavedMatch.scoring` — `aloneOnWatch`, `aloneOnPhone`, `paired` —
is a `NOT NULL` column with a check and no default, and a required key on the
wire. The scorer reads `matchInProgress(scored: [.aloneOnPhone, .paired])` in
its initializer, which `PadelApp` already runs before `transport.activate()`.
Driven on a simulator pair: a solo match at 30:15 and a paired one at 30:0 each
came back after the phone app was terminated, and the watch stayed on the
paired one and scored the next rally into it. The paired match was started from
the watch: the phone's own paired start stops at the Health sheet, which the
automation cannot reach. On review, `MatchUpdate` and the wire lost their own
`isPaired`: both ends read `SavedMatch.isPaired`, and the schema's check is
built from `MatchScoring.allCases`. A database from before this change has no
`scoring` column: delete the app (ADR-0014).

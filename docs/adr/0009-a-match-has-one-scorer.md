# A match has one scorer, and it is the device it was started on

The device a match is started on holds its rally journal from the first rally to the last. Start on the watch and the watch scores it, keeps it in its own store, and delivers it to the phone when it is over — what the app has always done. Start on the phone and the phone scores it, writing the journal into the same store the history is read from, so the match is in the history from its first point. The two devices say nothing to each other while a match runs.

The alternative was to give the match a single home on the phone and reduce the watch to a remote that holds nothing and asks for every rally. It is the better end state and it is not abandoned — it is deferred, and reframed: pairing the two devices becomes a third way to score rather than the only one, and it is specced in `.scratch/paired-scoring/`. What sent it back was its price of entry. It needs a live link in both directions, an intent protocol, a mirrored workout session to keep the phone alive in the background, `startWatchApp`, and a run-through on real hardware before any of it can be trusted — all of that before the phone can draw a single digit. The scoreboard needs none of it.

What the phone gains by scoring alone is what the feature was always for: the four players read the score from the bench. What it gives up is named below.

## Consequences

- **The scorer is not a setting.** It is where you started. A player who picks up the phone gets a phone-scored match and one who lifts a wrist gets a watch-scored one; nothing is stored about which, and there is nothing to configure. A setting would only be able to say what picking up a device has already said.
- **Both devices may be scoring at once.** Neither can see the other's match while it runs, so nothing prevents it — and nothing tries to, because any warning would be a guess. Two matches reach the history, which is what there were.
- **A phone-scored match has no workout.** `HKWorkoutSession` is watchOS's, and the phone has neither the sensors nor a session to run them in. No heart rate, no calories, no ring. Choosing the phone is choosing the board over the record in Health, and that asymmetry is the honest argument for pairing later.
- **The phone needs nothing to stay alive.** The journal is written to the store after every rally, and the idle timer is held while the board is up. Every rally arrives through the phone's own screen, so nothing is missed while the app is away, and a match survives being backgrounded or terminated by being read back from the store. This is why there is no ADR-0010: the mirrored session it argued for belongs to the deferred design and is kept with it.
- **ADR-0002 stands unqualified again.** The watch is the source of truth for a match it scores until the hand-off, and still has to see one through with no phone nearby. The delivery, the receipt and the queue all stay, and ADR-0004 with them.
- **ADR-0001 is untouched.** The journal is the single stored truth on whichever device holds it, and the score is computed from it rather than stored beside it.

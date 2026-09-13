# The match lives on the phone, and the watch is its remote

The rally journal is written on the phone, into the same store the history is read from. The watch holds no match, stores nothing, and asks: a tap on the wrist is an intent — "a rally to us, on top of a journal of 27" — which the phone records or refuses. What comes back is the journal, and the watch computes the score from it with the same engine.

This reverses the arrangement ADR-0002 describes, where the watch is the source of truth until a finished match is handed over and signed for. The reason is that the phone is no longer a reader: it shows a running match on a scoreboard and awards rallies from it. A phone that draws and controls a match it does not hold needs either a second journal — which cannot be merged, because a journal is an ordered list of who won and two pairs tapping after the same rally are indistinguishable from two rallies — or a round trip to the watch for its own taps.

The cost is that the journal now lives on the device iOS is free to suspend and terminate, which is what ADR-0010 is about.

## Consequences

- **A match needs both devices to begin.** Starting on the phone raises the watch app into a workout; starting on the watch requires the phone to answer. A player who leaves the phone in a locker room cannot score a match at all. This is a deliberate reversal of ADR-0002's second consequence and of `CONTEXT.md`'s opening sentence, and it is the largest thing given up here.
- **Delivery disappears.** A match born on the phone has nowhere to be delivered to: `MatchDelivery`, `MatchReception`, the receipt, and the queue are removed, and ADR-0004 is superseded along with them. The watch loses its database and the GRDB dependency with it.
- **An intent carries the journal length it was formed against**, and the host refuses one whose base does not match. That integer is what makes a message delivered twice score once, and a tap made against a stale screen fail loudly rather than quietly.
- **The watch never draws a point it has not been given.** No optimistic update: a scoreboard that shows 40 and takes it back is worse than one that is late.
- **A match interrupted by an unreachable phone is frozen, not lost.** The watch refuses taps and says why; the match stands on the phone at the score it reached. What is lost is the rallies played while nobody was recording.
- **ADR-0001 is untouched.** The journal is still the single stored truth and the score is still computed — on the wire as well, where what travels is the journal and never the score.

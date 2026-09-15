# The delivery queue lives in the store, not beside it

A match waiting to be sent to the phone is not copied into a separate list: the queue is the store it already lies in. The `match` table carries a delivery mark, and the "queue" is a query for the matches without one. The alternative — a table or file of its own holding the identifiers of what was sent — creates a second copy of the same knowledge, and two copies diverge sooner or later: a match left in the queue after it was deleted from the store, or the other way round.

As a consequence the queue gets for free what ADR-0002 demands of it: it survives the app being unloaded and the watch being restarted, because it survives them along with the matches.

## Consequences

- **A second non-computable column.** ADR-0001 says that nothing computable is stored beside the rally journal, and names the abandoned mark as the only exception. The delivery mark is a second one, and of a different kind: it is not a property of the match but a receipt of the queue, and so takes no part in the score, never travels to the phone and is shown nowhere. The rule of ADR-0001 stands unchanged: of the match state, still nothing is stored but the abandoned mark.
- **The mark is cleared by any write of the match.** What gets delivered is a version, not a match: a point undone in a finished match changes the journal, and what left stops matching what is on the watch. So `save` clears the mark, and a receipt from the phone sets it only if the match has not changed since.
- **A protocol of its own.** The store answers "what did we play", the queue answers "which of it has left"; those are different reasons to change, so `MatchDeliveryQueue` is declared separately from `MatchStore`, even though they share one implementation.
- **Nothing is deleted.** A delivered match stays on the watch: there is no reason to delete it while the history takes kilobytes and there is no backup (ADR-0002).

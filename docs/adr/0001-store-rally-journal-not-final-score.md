# A match is stored as a rally journal, not as a final score

A match is saved as an ordered sequence of rallies ("the point was won by side A/B"); the score is computed from the journal and is nowhere stored beside it. The alternative — writing down a result such as "6:4" — is cheaper today but irreversibly loses everything else: the course of the match cannot be recovered from a score line, whereas anything at all can be recomputed from the journal.

The decision is made for the sake of v2: once players and statistics appear, the whole history accumulated by then stays usable — break points, streaks, behaviour on the golden point can all be computed from the journal after the fact. Had the result been stored, the entire history up to that moment would have been dead weight.

## Consequences

- The score screen does not "increment a counter"; it appends an entry to the journal and recomputes the state.
- Undoing the last point is the removal of the last entry, not arithmetic run backwards.
- A match left halfway needs no special handling: it is a journal without a final state, so restoring it automatically after the app was unloaded comes for free.
- The single exception within the match state is the abandoned mark: the decision to walk off the court cannot be derived from the journal. The journal of a match stopped at 5:2 is no different from the journal of a match about to resume, and without the mark that difference is lost for good. It is stored beside the journal; the score still is not — the mark changes the outcome but computes nothing. One more thing is stored beside a match, the delivered-to-the-phone mark (ADR-0004), but that is not about the match — it is about the queue: it appears in no score, no outcome and no history.

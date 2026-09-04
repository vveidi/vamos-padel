# 12: The match card

**What to build:** Opening a match from the list, the owner sees not only how it ended but how it came about: the course of the score is reconstructed from the **rally journal** by the same engine that counted the match on the watch.

This is what the journal is stored for instead of the final score (ADR-0001), and what the engine lives in a shared package for: the same logic yields the same result on both devices.

**Blocked by:** 11, 03

**Status:** ready-for-agent

- [ ] The card shows the course of the score through the match, not only the result
- [ ] The course is reconstructed by the engine from the journal rather than stored separately
- [ ] For classic scoring the progression through games and sets is visible
- [ ] For the match to N points it is visible how the points were accumulated
- [ ] The card of an abandoned match shows clearly that it was not played out
- [ ] A match restored on the phone shows the same score as it had on the watch

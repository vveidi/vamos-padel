# 06: The delivery is removed

**What to build:** nothing. This ticket deletes the post office now that there
is nothing to post.

**Blocked by:** 05

**Status:** needs-triage

- [ ] `MatchDelivery`, `MatchReception` and their tests are gone
- [ ] `MatchDeliveryQueue`, `matchesAwaitingDelivery` and `markDelivered` are
      gone from the storage interface and from `DatabaseMatchStore`
- [ ] The `delivered` column is gone from the schema — edited in place, not
      migrated: there is no released version to migrate from, and the schema is
      still v1
- [ ] The watch links no store and no GRDB; `DatabaseMatchStore.inApplicationSupport()`
      is called on the phone alone
- [ ] Nothing in either app imports a symbol that no longer exists, and both
      targets build
- [ ] `swift test` is green in every package, and `PadelTests` still passes
- [ ] `CLAUDE.md`'s package map no longer promises an `Ends/` that delivers
- [ ] `CONTEXT.md` loses its **Match delivery** entry and gains **Live link**
      and **Intent** — the two this feature's spec has been holding — and no
      other entry still refers to a receipt. **Scorer** goes with the delivery:
      a paired match has no one device holding it

## Notes

**Why this is its own ticket.** Ticket 05 leaves the delivery unused; leaving it
*in* would be worse than either state — a live link and a dormant queue in the
same app, and one day the queue would wake up and deliver a match a second time.
Separating the deletion keeps 09 reviewable as a screen change.

**The database on the phone keeps everything else.** The history, the journals,
the abandoned marks: only the delivery mark goes. `MigrationTests` shrinks with
the schema rather than gaining a case.

**ADR-0002 and ADR-0004 are superseded here, and the notes have to be written.**
They carried them once, for the design this feature restores, and the notes came
off when that design was deferred — ADR-0002 stands unqualified again and
ADR-0004 stands outright. Removing the delivery is what supersedes them, so the
notes belong in this ticket. ADR-0009 is rewritten with them: it records the
scorer being the device a match was started on, and the pair makes that false.

# 10: The delivery is removed

**What to build:** nothing. This ticket deletes the post office now that there
is nothing to post.

**Blocked by:** 09

**Status:** ready-for-agent

- [ ] `MatchDelivery`, `MatchReception` and their tests are gone
- [ ] `MatchDeliveryQueue`, `matchesAwaitingDelivery` and `markDelivered` are
      gone from the seam and from `SQLiteMatchStore`
- [ ] The `delivered` column is gone from the schema — edited in place, not
      migrated: there is no released version to migrate from, and the schema is
      still v1
- [ ] The watch links no store and no GRDB; `SQLiteMatchStore.inApplicationSupport()`
      is called on the phone alone
- [ ] Nothing in either app imports a symbol that no longer exists, and both
      targets build
- [ ] `swift test` is green in every package, and `PadelTests` still passes
- [ ] `CLAUDE.md`'s package map no longer promises an `Ends/` that delivers
- [ ] `CONTEXT.md` has no **Match delivery** entry (already replaced by **Live
      link**), and no other entry still refers to a receipt

## Notes

**Why this is its own ticket.** Ticket 09 leaves the delivery unused; leaving it
*in* would be worse than either state — a live link and a dormant queue in the
same app, and one day the queue would wake up and deliver a match a second time.
Separating the deletion keeps 09 reviewable as a screen change.

**The database on the phone keeps everything else.** The history, the journals,
the abandoned marks: only the delivery mark goes. `MigrationTests` shrinks with
the schema rather than gaining a case.

**ADR-0002 and ADR-0004 already carry their supersession notes** — written when
ADR-0009 was. Check them off rather than writing them again.

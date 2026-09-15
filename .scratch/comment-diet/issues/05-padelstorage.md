# 05: PadelStorage

**What to build:** `Packages/PadelStorage` held to `CLAUDE.md`'s rewritten
"Writing comments" — 10 files across both targets, 1,526 lines, 356 doc-comment
lines and 105 inline.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `Packages/PadelStorage` — `Sources/Interface/`,
      `Sources/Database/` and `Tests/` — is read and its comments held to the
      rule
- [ ] The **27 doc-comment blocks of 6 or more lines, 249 lines between them**,
      are gone or cut to four
- [ ] No `public` symbol is exempt
- [ ] Deleted, not reworded
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [ ] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [ ] The diff contains **no line of code** — and in this area that includes the
      SQL inside `db.execute(sql:)`, whose string literals must not be touched
- [ ] `swift test --package-path Packages/PadelStorage` is clean
- [ ] The closing note states the area's doc and inline line counts **before and
      after**

## Notes

**This is the area with the most genuinely load-bearing comments, so go slower
than the line count suggests.** Storage comments encode rules that are true of
the data rather than of the code, and the data outlives the code.

**`MatchDatabase.swift`'s migration rule is the one to be careful with.** It
says there is one schema version so far and no new one appears before the first
release — the app has no users, so `v1` is edited in place rather than appended
to — and that the rule inverts the day the app reaches somebody else, because
the watch's database is the only copy of a match until it transfers. That is a
real, currently-binding instruction and deleting it would be a genuine loss. It
is also about three hundred words. **Move it to `docs/adr/` and leave four lines
pointing at it.**

**`eraseDatabaseOnSchemaChange = false` keeps its comment.** It is spelled out
even though it is the default, precisely so that switching it on is a decision
rather than a shrug. That is what a comment is for.

**`DatabaseMatchStore.save` has two keeps and a lot of narration.** The journal
is rewritten in full rather than appended to, because a match arriving from the
watch can be any version — that is a precondition. The delivery mark clearing on
write is a failure mode. The paragraphs around both explaining ADR-0004's queue
decision are ADR-0004's.

**The two `lastMatch` / `matches` ordering comments are one comment.** Both
explain that the two queries order by different columns on purpose and would be
wrong to unify. Keep it once, on whichever is read first.

# 05: PadelStorage

**What to build:** `Packages/PadelStorage` held to `CLAUDE.md`'s rewritten
"Writing comments" — 10 files across both targets, 1,526 lines, 356 doc-comment
lines and 105 inline.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `Packages/PadelStorage` — `Sources/Interface/`,
      `Sources/Database/` and `Tests/` — is read and its comments held to the
      rule
- [x] The **27 doc-comment blocks of 6 or more lines, 249 lines between them**,
      are gone or cut to four
- [x] No `public` symbol is exempt
- [x] Deleted, not reworded
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [x] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [x] The diff contains **no line of code** — and in this area that includes the
      SQL inside `db.execute(sql:)`, whose string literals must not be touched
- [x] `swift test --package-path Packages/PadelStorage` is clean
- [x] The closing note states the area's doc and inline line counts **before and
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

## Comments

**Done.** 9 `.swift` files under `Sources/` and `Tests/`, read in full and cut.

| | before | after |
| ---------------- | ----: | ----: |
| total lines | 1,526 | 1,172 |
| doc comments | 356 | 65 |
| inline comments | 105 | 42 |
| comment share | 30% | 9% |

The counts are the whole area including `Package.swift`, which is the
denominator the ticket's header uses. Excluding it — the nine files this pass
actually touched — 1,475 lines become 1,122, 356 doc-comment lines become 66 and
95 inline become 32. **No comment block of five lines or more is left**, doc or
inline, checked mechanically; the longest survivor is exactly four. `// MARK:`
is untouched at 3. No `TODO:` or `FIXME:` existed to convert.

**The diff contains no line of code**, checked the way tickets 01 and 03 were:
every file stripped of comments and blank lines before and after the pass, and
the two compared. The comparison is empty, so no SQL string literal moved by so
much as a space. `swift test --package-path Packages/PadelStorage` is clean —
46 cases, no warnings — and both app schemes build clean, which is what the
spec names as this feature's proof.

**`Package.swift` was left alone.** The first criterion enumerates
`Sources/Interface/`, `Sources/Database/` and `Tests/`, and the manifest is in
none of them; tickets 01–04 left theirs alone on the same reading, and
`PadelScoring`'s and `PadelDesign`'s manifests still carry their platform
comments. Its longest block is four lines, so it is inside the ceiling anyway.

- **Rescue 1 — ADR-0014, new.** `MatchDatabase`'s seventeen-line block held the
  migration rule the notes flagged: one version so far, a column added by
  editing `v1`, and the whole thing inverting the day the app reaches somebody
  else, because the watch's database is the only copy of a match until it
  transfers. It is now `0014-the-schema-is-edited-in-v1-until-the-first-release`,
  and three lines on `MatchDatabase` point at it. `MigrationTests`' eleven-line
  version of the same rule is gone too — the `#expect` message it already
  carried says it at the point of failure, which is where it is needed.

- **Rescue 2 — ADR-0001 gains a consequence.** `SavedMatch`'s type doc and its
  `undo` block both argued that a rally carries no time and that time therefore
  lives outside the engine. ADR-0001 describes the journal but never said it.
  It is now a bullet there, and `undo(at:)` keeps two lines for the part a
  reader would otherwise take for a bug: the match ends at the undo, not at the
  rally now last.

- **Rescue 3 — ADR-0003 gains a consequence.** Three separate comments in the
  schema — on the ruleset columns, on the `rally` table and on the `CHECK` —
  were one rule: nothing is folded into a column only our code can read,
  because portability means a reader that does not have our format. ADR-0003
  argues portability but never drew the rule out of it. It is now a bullet
  there, and it binds every column added later, which none of the three
  comments did.

- **Kept, as the notes asked:** `eraseDatabaseOnSchemaChange = false` keeps its
  comment, cut from five lines to three; `save`'s two — the journal rewritten
  in full because a match from the watch can be any version, and the delivery
  mark cleared on write — keep four and three lines, with ADR-0004's queue
  argument gone from around them; and the two ordering comments are now one, on
  `lastMatch`, which is read first.

- **Kept elsewhere: the threading rules, the constraints and the failure
  modes.** `DatabaseMatchStore` writing synchronously on its caller's thread;
  the observation scheduling on the cooperative pool rather than the main
  queue; the two containers one path rule yields; GRDB's in-memory `name` being
  needed only for a second connection; `Application Support` not existing on a
  fresh install; `matchesAwaitingDelivery` filtering in Swift because being
  over is the engine's answer and not a column's; `markDelivered`'s receipt
  being for a version and not an identifier; `MatchStoreError` naming what the
  schema cannot guard. In the tests, `aMoment` being a round second because
  GRDB stores milliseconds, `MigrationTests`' fixture being bare SQL on
  purpose, and the observation test waiting for the first value before the
  second write.

- **Two judgment calls left for the owner.** The `code-review` standards pass
  called the surviving `lastMatch` clause "and the two must not be unified" a
  design argument that belongs in an ADR — the ticket asks for that comment by
  name, so it stayed; if it should be an ADR instead, say so. It also flagged
  the deleted `MatchStore` policy — that the store does not decide what to do
  about a write that did not happen, and on the watch the match goes on and a
  line lands in the log — as a failure mode now recorded nowhere. I read
  `throws` as saying the first half and the watch's call site as owning the
  second, so it went; it is one ADR bullet away if you disagree.

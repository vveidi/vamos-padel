# 04: The phone app

**What to build:** `Padel` held to `CLAUDE.md`'s rewritten "Writing comments" —
6 files, 1,467 lines, 462 doc-comment lines and 46 inline.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `Padel/Sources/` is read and its comments held
      to the rule
- [ ] The **30 doc-comment blocks of 6 or more lines, 276 lines between them**,
      are gone or cut to four. Six files carry them, so the density per file is
      the highest in the repo
- [ ] Deleted, not reworded
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [ ] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [ ] The diff contains **no line of code**
- [ ] The `Padel` scheme builds, `PadelTests` passes, and the history is driven
      once on a simulator to prove nothing moved
- [ ] The closing note states the area's doc and inline line counts **before and
      after**

## Notes

**`HistoryView` and `MatchCard` are most of the weight.** Both argue their
layout at length — why the history is not a `List`, why the card shows the score
after each step rather than who took it, why the separator is the only part of
the footnote written in code. The third is a localization constraint and stays.
The first two are design arguments with no ADR behind them: if they are worth
keeping, they are worth an ADR, and if they are not, they go. Decide per
comment rather than rescuing both by reflex.

**`MatchWording.swift` and `MatchFixtures.swift` sit at the sources root because
they belong to both screens.** `CLAUDE.md` already says that, so a doc comment
repeating it goes.

**`MatchFixtures` has one comment worth keeping** — that every fixture goes
through the engine rather than being assembled from a ready score, because the
score is computed from the journal and a made-up course would check nothing.
That is a precondition on anyone adding a fixture. Four lines.

**`PadelApp.swift`'s init is the ownership case.** Reception subscribes before
the session comes up, because a parcel arriving into an app without a handler
does not arrive twice. That is a failure mode and an ordering rule — the
clearest keep in the area.

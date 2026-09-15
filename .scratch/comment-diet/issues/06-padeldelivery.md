# 06: PadelDelivery

**What to build:** `Packages/PadelDelivery` held to `CLAUDE.md`'s rewritten
"Writing comments" — 11 files, 1,177 lines, 245 doc-comment lines and 34 inline.
The lightest area, and the last of the six.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `Packages/PadelDelivery` — `Sources/Transport/`,
      `Sources/Ends/`, `Logging.swift` and `Tests/` — is read and its comments
      held to the rule
- [ ] The **17 doc-comment blocks of 6 or more lines, 151 lines between them**,
      are gone or cut to four
- [ ] No `public` symbol is exempt
- [ ] Deleted, not reworded
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [ ] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [ ] The diff contains **no line of code**
- [ ] `swift test --package-path Packages/PadelDelivery` is clean
- [ ] The closing note states the area's doc and inline line counts **before and
      after**, and — since this is the last ticket in the feature — the repo-wide
      totals against the 13,779 lines / 4,479 comments this feature started from

## Notes

**`WatchConnectivity` is the reason this area's keeps are real.** Its delegate
callbacks arrive on a queue that is not the main one, transfers survive app
launches, and a parcel handed to an app with no handler registered does not
arrive twice. Every one of those is a threading rule or a failure mode — the
rule's own keep list — and they are invisible in the signatures. Cut them to
four lines; do not delete them.

**The `Ends/` types are two halves of one conversation, and both say so at
length.** The watch's end and the phone's end each open by explaining the other.
One sentence naming the counterpart is enough; the protocol between them is
`Transport/`'s to describe, and it should describe it once.

**`Logging.swift` sits at the target root because it belongs to no subsystem.**
`CLAUDE.md` says that, so the comment repeating it goes.

**This ticket closes the feature, so its closing note is the feature's.** State
the repo-wide before and after, and say whether the under-10% target was
reached. If it was not, say by how much and which area carries the remainder
rather than leaving the number to be re-measured later.

# 02: The watch app

**What to build:** `Padel Watch App` held to `CLAUDE.md`'s rewritten "Writing
comments" — 11 files, 2,220 lines, 688 doc-comment lines and 210 inline. The
densest area by ratio: 40% of it is prose.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] Every `.swift` file under `Padel Watch App/Sources/` is read and its
      comments held to the rule: the default is no comment, and what survives
      names a precondition, a unit, a threading or ownership rule, a failure
      mode, where a measured number came from, or what a workaround is working
      around
- [ ] The **46 doc-comment blocks of 6 or more lines, 486 lines between them**,
      are gone or cut to four
- [ ] The **210 inline comments** get the same pass, and this area is where they
      are worth reading carefully — the watch's are disproportionately real
      (a watchOS API constraint, a gesture that competes with the `TabView`'s
      swipe) rather than narration
- [ ] Deleted, not reworded
- [ ] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [ ] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [ ] The diff contains **no line of code**
- [ ] The `Padel Watch App` scheme builds, and the score screen is driven once
      on a simulator to prove nothing moved
- [ ] The closing note states the area's doc and inline line counts **before and
      after**

## Notes

**The screen files carry screen-level essays.** `ScoreView`, `OutcomeView` and
`StartView` each open with several paragraphs arguing the layout — why the
opponents are on top, why a label would cost the digit room, why the capsule is
a `Button` and not a gesture. The last of those is a real constraint and stays,
cut short. The first two are design rationale and belong in `docs/adr/0006`.

**The `Board` enums are the biggest single win.** Each screen ends with a
`private enum Board` whose every constant carries two or three sentences about
where the number came from. "Where a measured number came from" is on the rule's
keep list — but it means *"the boards' 16px halved"*, one line, not a paragraph
about the artboard it was read off and why the artboard was 2x. `docs/design/README.md`
already carries that argument once, which is where it should stay.

**Watch out for what is genuinely watchOS-specific.** `StartPages.swift` explains
why the navigation bar is not hidden, and there is a memory and a real
SaltUICore fault behind that. `StartView` explains why `WKInterfaceDevice` is
used instead of `.sensoryFeedback`. Both are workarounds; both stay, at four
lines.

**Nothing here is a package, so there is no `swift test`.** The proof is the
scheme building and the screen still drawing — one drive, one screenshot.

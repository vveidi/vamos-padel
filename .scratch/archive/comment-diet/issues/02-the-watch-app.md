# 02: The watch app

**What to build:** `Padel Watch App` held to `CLAUDE.md`'s rewritten "Writing
comments" — 11 files, 2,220 lines, 688 doc-comment lines and 210 inline. The
densest area by ratio: 40% of it is prose.

**Blocked by:** None

**Status:** done

- [x] Every `.swift` file under `Padel Watch App/Sources/` is read and its
      comments held to the rule: the default is no comment, and what survives
      names a precondition, a unit, a threading or ownership rule, a failure
      mode, where a measured number came from, or what a workaround is working
      around
- [x] The **46 doc-comment blocks of 6 or more lines, 486 lines between them**,
      are gone or cut to four
- [x] The **210 inline comments** get the same pass, and this area is where they
      are worth reading carefully — the watch's are disproportionately real
      (a watchOS API constraint, a gesture that competes with the `TabView`'s
      swipe) rather than narration
- [x] Deleted, not reworded
- [x] Any `TODO:` or `FIXME:` found becomes a ticket and is deleted from the
      code — `CLAUDE.md` forbids both. `// MARK:` survives untouched
- [x] Anything load-bearing that a deletion would lose moves to `docs/adr/` or
      to the ticket that owns it. The closing note lists every rescue
- [x] The diff contains **no line of code**
- [x] The `Padel Watch App` scheme builds, and the score screen is driven once
      on a simulator to prove nothing moved
- [x] The closing note states the area's doc and inline line counts **before and
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

## Comments

**Done.** All 11 `.swift` files under `Sources/`, read in full and cut.

| | before | after |
| --------------- | ----: | ----: |
| total lines | 2,218 | 1,508 |
| doc comments | 688 | 126 |
| inline comments | 208 | 62 |
| comment share | 40% | 12.5% |

`// MARK:` is untouched: 5 lines before and after, and they are excluded from
the inline counts above. No `TODO:` or `FIXME:` existed to convert. Every
surviving block is four lines or fewer, checked with an `awk` pass over the
tree rather than by eye.

**The diff contains no line of code**, checked mechanically: every file was
stripped of comments and blank lines before and after the pass and the two
compared, and the comparison is empty. The scheme builds clean on a watchOS
26.5 simulator.

**Driven on Apple Watch SE 3 (40mm), in Russian** — the start screen, the score
screen (a rally scored, the ball crossing to the other serving half), the
control page with its confirmation, and the abandoned outcome. The rules list
was pushed as well, to confirm the Back button the `StartPages` comment guards
is still there.

- **One rescue: ADR-0013, "The score screen is drawn from our end."**
  `serveAlignment(for:from:)`'s thirty-line argument — why one `ServingHalf`
  case gives two opposite alignments, what flattening it breaks, that no test
  in this target catches it, and why both balls sit in the zones' inner corners
  (the watch clock over the opponents' top trailing, `ScorePages`' page dots
  over ours). The function now cites the ADR in three lines.

- **Nothing else was rescued.** The screen-level layout essays the ticket
  expected to land in ADR-0006 turned out to be written down already:
  ADR-0012's "One surface, and position says whose it is" carries "the
  opponents on top, never a label" for both `ScoreView` and `StartView`, and
  ADR-0006 carries the ball's yellow. They were deleted rather than moved.

- **Kept, against the general cut:** the watchOS constraints the ticket named —
  `StartPages`' four lines on why the navigation bar is *not* hidden,
  `StartView`'s `WKInterfaceDevice`-not-`.sensoryFeedback`, the `Button`-not-a-
  gesture that would otherwise steal the page swipe — plus the localization
  rules a refactor would break (whole sentences per outcome, because the two
  languages order side and verb differently; whole clauses for a counted noun,
  because Russian has four forms of it), `HealthKitWorkout`'s queue of one and
  its cleared-before-the-await rule, `MatchView`'s workout restarting after an
  undo and leaving two records in Health, and every number read off a board.

- **Names left looking thin, for a later ticket.** `RootView.isRestored` no
  longer says what it is restored *from*; `MatchView.persist` lost the sentence
  saying it runs after every rally rather than at the end of the match;
  `OutcomeView`'s `Board.headlineGap`, `buttonsGap` and `buttonGap` are now
  bare numbers whose names are the only thing placing them. Renaming is out of
  this feature's scope by its spec.

- **One deleted comment was already stale.** `ScoreZone`'s accessibility block
  said "the zone stopped being a button, so everything a button gave VoiceOver
  is put back by hand" — narration of a change git already holds, and the
  hand-written traits sit directly under it.

- **`code-review` was not run.** The owner called for the commit before it
  started.

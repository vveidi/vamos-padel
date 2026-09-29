# 03: The phone's new match screen

**What to build:** `PhoneNewMatch.dc.html`, at last — first server, ruleset,
the numbers that shape it, and one button that starts the match.

**Blocked by:** None

**Status:** done

- [x] One screen, not a stack of pages: "Who serves first?" over a court with
      two halves and the ball on the chosen one, then the rules, then "Start
      match"
- [x] The ruleset is chosen with `SegmentedChoice`, the numbers with
      `StepperRow`, the golden point with the switch — the three controls that
      have been sitting in `PadelDesign` unused and unavailable on watchOS —
      the redesign built them for a screen that did not exist yet
- [x] The summary sentence under the controls reads the ruleset back in words,
      in both languages
- [x] The previous match's ruleset is filled in from `lastRuleset()` — asked of
      the store, never kept beside it
- [x] "Start match" writes the new match to the store and ~~opens the
      scoreboard, which takes it from there~~ hands it to its caller, which has
      no scoreboard to open until ticket 04 — see the closing note
- [x] Reached from the history: the "New match" button the redesign drew and
      left out, because it led to this screen and this screen did not exist
- [x] It is not offered while a match is running — the live tile stands there
      instead (ticket 05)
- [x] Works in both orientations, and at the largest Dynamic Type setting
- [x] Previews in both languages and at `.accessibility5`
- [x] The strings are in `Shared/Localizable.xcstrings`, English as the source

## Notes

**Sides stay anonymous.** "Us" and "the opponents", as the glossary has it. The
reference app names four players; that is a feature of its own and the spec puts
it explicitly out of scope.

**The watch's wording is not this screen's.** `MatchWording.swift` already
carries the rule and the reason: the watch is choosing a ruleset and keeps the
numbers out of its name, while the phone is describing a match and the numbers
are what make it readable. Two targets, two sentences.

## Comments

`NewMatchView.swift` is the screen, pushed from the history and drawn off the
board: the question, the court with a half per side, the rules, the sentence,
and a pinned "Start match". It was driven on an iPhone 17 in both languages, at
`.accessibility5`, and in landscape.

- **The board is deleted.** `docs/design/PhoneNewMatch.dc.html` is gone, with
  its entry in `canvas.json` and the counts in `docs/design/README.md` and
  `CLAUDE.md` — the README's own rule, "a board is deleted when its screen is
  built". One board is left, `PhoneScore.dc.html`, waiting on ticket 04.

- **"Start match" saves and hands the match to its caller; nothing opens it.**
  The criterion asks for the scoreboard, which is ticket 04. `NewMatchView`
  takes `onStart: (SavedMatch) -> Void` and the history pops back with the
  payload unused, which is where 04 pushes the board. The consequence is a
  seam worth knowing about until then: a match started on the phone is in the
  store, has no screen, and cannot be ended. `lastRallyAt` keeps it from being
  a trap — see the next note.

- **"Not offered while a match is running" means the last match played, not
  any unfinished one.** A `contains` over the history would have hidden the
  button for good over a match abandoned in fact but not in the store a month
  ago. The rule here is `matchInProgress()`'s own — the match with the latest
  `lastRallyAt`, if it is still in progress — derived from the history the
  screen is already observing rather than read a second time. Driven both
  ways: a match started now hides the button, the same match backdated to
  August gives it back.

- **`StepperRow` had never been used, and wrapped.** "Очков до победы" beside
  a two-digit value squeezed the number until "16" drew as a 1 above a 6, in a
  row that never stacked. `.fixedSize()` on the value fixes it, with a test in
  `PadelDesignTests` that fails without it. The control ships on the phone
  only, so nothing else moved.

- **The halves are labelled "Us" and "Opponents", the board's own labels.**
  VoiceOver says "We serve" / "Opponents serve" instead, because the two halves
  are heard one after the other and a name alone does not answer the question
  the screen is asking. Both spoken keys are the watch's, unchanged.

- **The ruleset's numbers are a verbatim copy of the watch's.** `Numbers`,
  `sentence(for:)`, `deuce(_:)` and the three bounds are the same ~110 lines as
  `RulesetSettings.swift`. There is no home for them: `PadelScoring` passes no
  judgment on a ruleset by design, and the sentence needs the catalog, which
  ADR-0005 keeps out of the packages. That file's doc comment claimed to be
  "the only place the rules are bounded" and no longer is, so it now says it is
  the watch's. Both reviews called the duplication out; it is left for the
  owner, and it wants an ADR or a ticket rather than another quiet copy.

- **Left as written, for the owner.** The board's second segment reads "To N
  points" and the code reuses the watch's "By points" key rather than adding a
  third phrasing for the same choice. The bottom bar — a pill over a
  `nightScrim` — is written twice, once here and once in the history. And the
  `onStart` payload is unused until 04, which a reviewer read as speculative;
  the criterion asks for the match to be handed on, so it is.

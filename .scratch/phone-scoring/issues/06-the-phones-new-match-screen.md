# 06: The phone's new match screen

**What to build:** `PhoneNewMatch.dc.html`, at last — first server, ruleset,
the numbers that shape it, and one button that starts the match.

**Blocked by:** 03

**Status:** ready-for-agent

- [ ] One screen, not a stack of pages: "Who serves first?" over a court with
      two halves and the ball on the chosen one, then the rules, then "Start
      match"
- [ ] The ruleset is chosen with `SegmentedChoice`, the numbers with
      `StepperRow`, the golden point with the switch — the three controls that
      have been sitting in `PadelDesign` unused and unavailable on watchOS since
      `redesign/03`
- [ ] The summary sentence under the controls reads the ruleset back in words,
      in both languages
- [ ] The previous match's ruleset is filled in from `lastRuleset()` — asked of
      the store, never kept beside it
- [ ] "Start match" starts it through the host (ticket 03) and opens the
      scoreboard
- [ ] Reached from the history: the "New match" button the redesign left out
      because it led nowhere (`redesign/spec.md`, "What is in, and what is not")
- [ ] It is not offered while a match is running — the live tile stands there
      instead (ticket 08)
- [ ] Works in both orientations, and at the largest Dynamic Type setting
- [ ] Previews in both languages and at `.accessibility5`
- [ ] The strings are in `Shared/Localizable.xcstrings`, English as the source

## Notes

**Sides stay anonymous.** "Us" and "the opponents", as the glossary has it. The
reference app names four players; that is a feature of its own and the spec puts
it explicitly out of scope.

**The watch's wording is not this screen's.** `MatchWording.swift` already
carries the rule and the reason: the watch is choosing a ruleset and keeps the
numbers out of its name, while the phone is describing a match and the numbers
are what make it readable. Two targets, two sentences.

# 11: The match list on the iPhone

**What to build:** The history appears on the phone. Opening the app, the owner sees a list of the matches played: the date, the score, the duration and which **ruleset** the match was played by — otherwise a score of "16:14" looks like a strange tennis result.

**Abandoned matches** stand out at a glance, without having to read closely.

An iPhone-only app; the iPad is out of the target.

**Blocked by:** 10, 09

**Status:** ready-for-agent

- [ ] The list shows the matches, freshest first
- [ ] For every match the date, the final score and the duration are visible
- [ ] It is visible which ruleset the match was played by
- [ ] Abandoned matches are visually distinct
- [ ] The history survives a relaunch of the app
- [ ] An empty history looks sensible rather than like an error

## Comments

**From the review of ticket 09.** A match can be stopped early before its first rally — there
is no start screen yet, and the app opens straight onto the score. Such a match is saved
honestly: abandoned, with an empty journal and zero duration. It has no business in the
list — "0:0, 0 min" is not history but the trace of a mis-tap — so whether to show it or
filter it out has to be decided here. Filtering should go by the journal: a match begins with
its first rally, as the glossary defines it.

**From ticket 10.** Some of this screen is already in place and does not need doing again:

- `MatchStore.matches()` hands back every match, freshest first.
- The phone's `HistoryView` already closes four of the six criteria: freshest first, the
  abandoned mark, a sensible empty history, and its surviving a relaunch. What stays uncovered
  is the duration and the ruleset.
- The presentation there is a draft, and is worth replacing wholesale rather than adding to.
- A match arrives into an app woken by the system, and the screen does not learn about it: the
  history is currently re-read on returning to the active state and on a pull to refresh. A
  real list needs to observe the database — GRDB's `ValueObservation` — and that is this
  ticket's work.
- A match without a single rally will not need filtering: ticket 10 does not send such matches
  to the phone.

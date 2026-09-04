# 11: The match list on the iPhone

**What to build:** The history appears on the phone. Opening the app, the owner sees a list of the matches played: the date, the score, the duration and which **ruleset** the match was played by — otherwise a score of "16:14" looks like a strange tennis result.

**Abandoned matches** stand out at a glance, without having to read closely.

An iPhone-only app; the iPad is out of the target.

**Blocked by:** 10, 09

**Status:** done

- [x] The list shows the matches, freshest first
- [x] For every match the date, the final score and the duration are visible
- [x] It is visible which ruleset the match was played by
- [x] Abandoned matches are visually distinct
- [x] The history survives a relaunch of the app
- [x] An empty history looks sensible rather than like an error

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

**Done.** The history is watched rather than read, and the row says what a match was.

- **Freshest first**: `MatchStore.matches()` already ordered by the time of the last rally,
  and the observation asks the same query — the two share one `matches(in:)` so they cannot
  start answering about different histories. Checked in the simulator on four matches seeded
  into the app's own database: 4 сент., 3 сент., 2 сент., 1 сент., top to bottom.
- **The date, the final score and the duration**: the score is `MatchState.finalScore` — the
  one the ruleset chooses, games for a single set and sets for a longer match — and our side
  always stands first, including in a match we lost, so that a column of results can be
  scanned down. The duration is `SavedMatch.duration`, the first rally to the last. On screen:
  "6 : 4 · Классический счёт · 1 сет · 1 сент. 2026 г., 20:11 · 41 мин".
- **The ruleset**: named with the number filled in — "Счёт до 16 очков" under a "16 : 14",
  which is what the ticket asked the line for. The watch keeps the N out of the same name on
  purpose, so the two are different sentences rather than one copied twice; the phone pays for
  its number with two grammatical cases ("до 21 очка", "до 16 очков").
- **Abandoned matches**: the score is dimmed and a "не доигран" capsule stands at the end of
  the row. Grey rather than red, the colour the watch marks it with on the outcome screen:
  being stopped early is not an error to warn about, it is a result that is not one. Checked
  in both appearances.
- **A relaunch**: the four matches were written into the database with the app terminated, and
  the list came back with them on launch — the screen reads SQLite and nothing else.
- **An empty history**: `ContentUnavailableView` with "Матчей пока нет / Сыгранный на часах
  матч появится здесь сам" — kept from the draft, it was already right.

## What was decided along the way

**The observation is a method on the store, not GRDB in the screen.**
`matchesObserved()` hands back an `AsyncThrowingStream` of the same list `matches()` reads;
inside `SQLiteMatchStore` it is a `ValueObservation`, and the screen still knows nothing about
the database (ADR-0002, ADR-0003). It throws for the same reason the other methods do — the
store is not the place to decide what to do about a read that did not happen — and the screen
does with the failure exactly what the watch does: keeps what it has and writes a line in the
log.

**"Not known yet" is not "empty".** The list is `nil` until the first value arrives. Telling an
owner with a hundred matches that they have none, even for one frame, is a lie the screen can
avoid — the same reason `RootView` on the watch waits before choosing a screen.

**A match without a rally is not filtered** — the question ticket 09 left here. The phone never
receives one: `matchesAwaitingDelivery` drops it on the watch (ticket 10). Filtering it again
here would guard against a case delivery already forbids, and would quietly swallow the
evidence if one ever did arrive.

**The row names only the parameter that shapes the score** — the sets, the N. The golden point
and the interval between service changes decide how the match was played, not how the number
in front of the reader is to be read; they belong on the match card (ticket 12), which shows
one match instead of a column of them.

**Dates and durations are formatted in Russian, not in the reader's locale.** The app writes
Russian and has no second language to switch to, so on an English phone the row read
"1 hr, 35 min" between "Классический счёт · 2 сета" and the rest — caught in the simulator,
which is set to English. The calendar and the time zone stay the reader's own: what is fixed
here is the language, not where in the world the owner is.

## What is not verified

A match arriving from the watch into an open history — that needs the watch, and the pair was
not run together. What is checked is the mechanism underneath it: a test writes a match into
the store and the observation hands out the new history, and `PadelApp` gives the reception
and the screen one and the same store, so the write the phone performs is a write the screen
is watching.

## After the review

Three of the review's findings were fixed; the rest were left as they are and why is
written below.

**The screen no longer waits forever for a history that will not come.** A failure on the
observation's very first read left the list unknown and the spinner turning, with the stream
already over. The screen now knows three states instead of a list and a `nil` — unknown,
known, unreadable — and says the third one out loud: "История не читается", with a button
that starts the observation over. A failure after a list has arrived still changes nothing on
screen: the matches in front of the owner are closer to the truth than anything that could
replace them. Checked in the simulator by writing an unreadable side into a rally of the
freshest match: the error screen instead of the spinner, and the history back after the row
was repaired. The button itself was not pressed — driving the simulator's UI from outside is
not something this setup can do — so it is verified by construction, not by a tap.

**The history is ordered by the start of the match, not by its last rally.** The row shows
the start, and the two disagreed: a match begun at seven and played out at eleven stood above
a match played at nine while showing an earlier time than it — a list arguing with its own
dates. `matchInProgress` and `lastRuleset` keep ordering by the last rally: "which match is
the previous one" is a different question, and there the match played out most recently is
the right answer. A test now holds the two apart.

**The double in the delivery tests keeps the protocol's promise.** `FailingMatchStore` ended
its stream without handing out the first value, which the protocol promises; nothing wires it
to a screen today, and a screen it was wired to tomorrow would wait forever.

Left alone: the Russian strings duplicated between the watch's start screen and the phone's
row (`sets(_:)`, the score's VoiceOver label). There is no shared home for them — the app
targets are separate and `PadelScoring` is no place for Russian — and inventing one for two
short strings costs more than it saves. A third copy should force the seam.


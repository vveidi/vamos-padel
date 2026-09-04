# 06: The start screen

**What to build:** The screen a match starts from. The player picks a **ruleset**, its parameters, and which **side** serves first, and then lands on the score screen.

The main requirement is speed: the settings are remembered from the previous match, so in the ordinary case the start is a single tap on "Start", and the player sees the parameters screen only if they went there themselves. A group plays by the same rules for months; a setting asked every time is a tax paid for something that happens twice a year.

**Blocked by:** 04

**Status:** done

- [x] The ruleset is chosen: classic scoring or the match to N points
- [x] For classic scoring, the number of sets and the golden point are configurable
- [x] For the match to N points, N and X are configurable
- [x] The first serving side is named
- [x] The default values: N = 16, X = 4, one set
- [x] The previous match's settings are filled in automatically and survive a relaunch of the app
- [x] A match with the remembered settings can be started with one tap

## Comments

From the review of ticket 03: before this screen the app plays with a single hard-wired
ruleset, and since ticket 03 that is classic scoring. **The match to N points is currently
unreachable from the app** — it lives only in the engine's tests — because there is nothing
to choose between, and the score screen cannot show both rulesets at once. This ticket closes
that regression: with the choice in place, both rulesets become reachable again.

The same review noted that **the sets are not shown on the score screen**: the spec names
exactly three quantities (points, games, serve), and with a single set that is enough. As soon
as choosing two becomes possible here, the games line will be left without saying which set it
belongs to — worth settling together with the choice.


**What was built.**

Three screens instead of two, and a root that picks between them. At launch `RootView` asks
the store two questions — "is a match already running?" and "which rules did we play by last
time?" — and decides from the first whether to show the score or the start. A match that
survived an unload goes straight to the score: a player whose app was unloaded between games
did not order a start screen. Until the store answers, a `ProgressView` is on screen rather
than the start: flashing the start screen under the hand of a player who came back to a
running match is a sure way to start a new one instead.

**The first serve is the "Start" button.** The start screen has two rows — "Подают соперники"
and "Подаём мы" — and each of them starts the match. A separate "Start" button next to the
serve choice would be a second tap that says nothing new: the serve has to be asked for every
time anyway (the glossary: the rules are remembered until the next match, who serves first is
decided anew). This way the ticket's "one tap" holds literally, not on average. The opponents
on top, us at the bottom, the same colors as on the score screen — the half the player will
be tapping for their own points all match is recognizable before the first rally.

The third row shows the rules ("Классический счёт / 1 сет · золотое очко") and leads to the
rules screen, `RulesetView`: the ruleset, the sets and the golden point, or N and X. The
bounds on the values are set there (sets 1–3, N 5–40, X 1–6) — exactly what the engine
deliberately left to the start screen: it passes no judgment on what it was handed but clamps
from below, so as not to crash the app on court.

**The rules are remembered by the store, not by a separate setting.**
`MatchStore.lastRuleset()` hands back the previous match's ruleset — the same match
`matchInProgress()` touches, and by one query (`SQLiteMatchStore.lastMatch`): were they to
drift apart, they would start answering about different matches. No second copy of the same
value appeared beside the database — for the same reason the score is not stored beside the
journal (ADR-0001). A consequence worth knowing: what is remembered is what the player
finished playing with, not what they span up on the rules screen and thought better of without
starting a match.

**The score screen shows the sets** — where there is more than one. `Ruleset.isMultiSet`
answers that question once for everyone: the same answer picks the score the match will be
remembered by (`MatchState.finalScore`). The sets digit stands at the right edge of the zone,
opposite the serve dot, rather than as a third number on the score line: next to the games, a
second small digit would read as part of the game score, and "4 1" would have to be puzzled
out. Position is the only thing that tells them apart, and it is also what keeps them from
pushing the points off the center of the zone.

**How each criterion was checked.**

- *Choosing the ruleset, the sets, the golden point, N and X* — `RulesetView`, captured in the
  simulator (Series 11 46mm) on the match to N points: "Счёт — до N очков", "Очков (N) — 16",
  "Подача через (X) — 4".
- *The first serving side* — the two rows of the start screen, captured in the same place.
- *The defaults N = 16, X = 4, one set* — `Ruleset.defaultPointsTo` and `defaultClassic`, and
  the tests "A match to N points defaults to 16, with the serve changing every 4 rallies" and
  "Classic scoring defaults to one set with the golden point". The rules screen takes the
  defaults apart from those very values rather than writing the numbers out again.
- *The previous match's settings are filled in and survive a relaunch* — four store tests
  ("The previous match's rules are remembered" across three rulesets, "…from a finished match
  too", "…not the one before", "…survive a relaunch of the app") plus a check in the
  simulator: a database with a match to 21 points and the serve changing every 2 was written
  by a separate process and put into the app's container — the start screen came up with
  "Счёт до N очков / N = 21 · X = 2".
- *Starting with one tap* — a tap on "Подаём мы" is the start: `onStart` assembles a `Match`
  from the remembered ruleset and the named serve.
- *Returning to a running match past the start* — a database with an unfinished match to two
  sets was put into the container (the first set ours, 2:4 in the second, 30:15 in the game);
  the app came up straight on the score, with the sets at 1:0 by the right edge.

`swift test` in both packages: 76 and 27 tests, all green. Both targets build.

**Decisions the ticket did not ask for.**

- **"Новый матч" on the outcome screen.** Ticket 02 assigned that return to the start screen
  ("the button was written and removed: the way back to a new match is ticket 06"), and
  without it the start screen would be reachable only by relaunching. A button, not a gesture:
  on the outcome screen the player is no longer on serve and is in no hurry, and mis-tapping
  into a new match in the middle of dissecting the last rally is not something anybody wants.
  The long press on that screen stayed with undo (ticket 05).
- **The sets on the score screen** — what ticket 03 left to be settled here. The spec names
  "exactly three quantities", and a fourth appears only in a match longer than one set:
  without it the games lie, they reset with every set, and "4 : 1" does not say who is ahead
  in the match. In a match to one set — which is the default — the screen stays exactly as the
  spec described it.
- **The first serve is not remembered between matches**, unlike the rules. That is how the
  glossary defines it: who serves first is decided anew every time. It is also what makes
  choosing the serve free — it is merged with the start.
- **The rules screen remembers the numbers of both rulesets while it is open.** Glancing at
  the neighbouring case and coming back must not cost the sets already dialled in. What leaves
  the screen, though, is a single ruleset — the selected one.
- **A match without a single rally does not survive a relaunch**: it reaches the store with
  its first point. The app will come back to the start screen — exactly where such a match is
  started.
- **`padel.xcodeproj` was rewritten by Xcode during the build**: `PadelStorage` was added to
  the Frameworks of both targets (it used to be linked only through the package dependency),
  and the Cyrillic in the `Info.plist` keys was unescaped. The change is incidental, but
  correct, and so was kept.

**What is left to check by hand** (the spec puts the screens among what tests do not cover;
there turned out to be no window in the simulator that could be pressed, so every screen was
captured but not tapped through):

- Going from the start screen to the rules screen and back: the rules should reach the start
  at once, without a "Done".
- The Digital Crown on the choice of N: forty values is a couple of turns, and it is worth
  making sure the wheel does not skip past the one you want.
- Whether the "Новый матч" button intercepts the long press for undo on the outcome screen —
  it lies inside the same area.
- Whether the sets digit at the right edge reads as sets rather than as one more game — on
  court, in a match to two sets.

**The crash on the "Новый матч" button — found and fixed.**

The root handed the match screen a `Binding($match)` — a binding to an optional `SavedMatch`,
so that the match would have a single owner. SwiftUI implements such a binding through
`BindingOperations.ForceUnwrapping`, and force-unwraps the optional on **every** read. The
"Новый матч" button cleared the match, the still-alive match screen read its binding in the
same update cycle — `EXC_BREAKPOINT` in `ForceUnwrapping.get(base:)`. The stack was taken from
the report in `~/Library/Logs/DiagnosticReports` after reproducing it in the simulator.

The fix: the match travels into the match screen as a value rather than a binding — the screen
owns it itself again (`@State`), as it did before the ticket, and it is enough for the root to
know that a match exists. Plus `.id(match.id)`: a different match means a different screen,
from a clean slate. The reason is written down in `RootView.match`'s doc comment, so that the
binding is not brought back.

Checked on the same transition: a database with an unfinished match to two sets was put into
the container, and `onFinish()` was called from the match screen on a timer instead of a tap —
the app went to the start screen, and no crash report appeared. Before the fix the same
transition produced one.

A lesson for checking by hand, from the same place: screens captured one at a time do not
catch crashes on the transitions between them. All four transitions (start → score, score →
outcome, outcome → start, start → rules → start) are worth walking through with a finger, one
after another.

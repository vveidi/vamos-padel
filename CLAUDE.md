# Padel

## Agent skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature-slug>/` in this repo. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label string equal to its name, and this repo's
own `done` on top of them. `done` is terminal: set it once every acceptance
criterion is checked off and the closing note is written, and nobody picks the
ticket up again. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

### Design boards

The artboards live in `docs/design/`, not in the tracker: a feature's folder is
emptied when it closes, and a board outlives the ticket that reads it.

**Only screens that have not been built have a board.** A board is deleted once
its screen ships — after that the screen is the design, and a second drawing of
it is a second source of truth that goes stale without anyone noticing. Two are
left, both waiting on `phone-scoring`.

`docs/design/README.md` carries the one rule the doc comments in `PadelDesign`
and both apps cite by name — layout transfers off a board, type sizes and
typefaces do not.

### Working a backlog

`/next-ticket [feature]` takes one ticket, builds it, drives it on a simulator,
runs `code-review` over it and commits it — then stops, because the review
between two tickets is the owner's. See `.claude/skills/next-ticket/SKILL.md`.

`/status [feature]` reads the board — `.scratch/status.sh` — and says what is
takeable, what is blocked and on what. See `.claude/skills/status/SKILL.md`.

## Building and testing

Pipe `xcodebuild` and `swift test` through `xcbeautify --quiet`. It cuts the log
down to warnings and errors, keeping the file, line, and message on every one of
them; `swift test` adds a line per suite on top of that. A hand-picked
`| tail -N` cuts off the error you ran the build to find.

Open the pipe with `set -o pipefail`, which makes the shell report the build's
exit code instead of `xcbeautify`'s. Without it a failing build reports success:

    set -o pipefail; xcodebuild -project Padel.xcodeproj -scheme "Padel Watch App" \
      -destination 'platform=watchOS Simulator,id=<uuid>' build 2>&1 | xcbeautify --quiet

`xcodebuild -list -project Padel.xcodeproj` names the schemes; a failed
`-destination` prints every simulator UUID the scheme accepts.

Most of the tests are the packages' and run under `swift test`. One target's
tests are the project's: `PadelTests`, hosted by the phone app, which reads the
strings out of the built `Padel.app`. It runs under the `Padel` scheme's test
action on an iOS simulator, and `xcbeautify --quiet` prints a passing suite as
one line — `xcrun xcresulttool get test-results summary --path <.xcresult>`
counts the cases behind it.

`-list` reads nothing but the project file in name only: it resolves the package
graph on the way, which writes `SourcePackages` and reaches GitHub for GRDB. It
sits on the allowlist because it changes no source, not because it is inert.

## Where things live in the packages

Each package's sources are grouped by subsystem, and its tests mirror the
grouping folder for folder. A file's folder is the fastest thing to read about
it:

    PadelScoring/   Vocabulary/  the small value types — Side, Points, ServingHalf
                    Journal/     the rally journal, which is the source of truth
                    Rules/       Ruleset and the two replays that walk the journal
                    Match/       Match, its state, its outcome, its course

    PadelStorage/   Seam/        the protocols and SavedMatch (ADR-0002)
                    SQLite/      the GRDB implementation behind that seam

    PadelDelivery/  Transport/   the wire and what travels over it
                    Ends/        the watch's side and the phone's side

    PadelDesign/    Tokens/      what a screen names: palette, ramp, radii
                    Court/       the court, net, ball and the two lights
                    Controls/    the five controls and their metrics

What is *not* in a folder is deliberate: a package's shared test harness and
its isolation test sit at the test target's root, and `Logging.swift` sits at
`PadelDelivery`'s, because they belong to no one subsystem.

Adding a folder needs no manifest edit — SwiftPM compiles everything under the
target's directory.

## Where things live in the two apps

Both app targets split the same way — `Sources/` and `Resources/` — and the
sources are grouped by what the player is doing at the time:

    Padel Watch App/Sources/   App/       the entry point and the root's one question
                               Start/     the court before the match, its settings and its rules
                               Match/     the match while it runs, and how it ends
                               Workout/   the workout the match runs inside

    Padel/Sources/             App/       the entry point, the store and reception
                               Screens/   the history, its rows and the match card

`MatchWording.swift` and `MatchFixtures.swift` sit at `Padel/Sources/`'s root
because they belong to both screens rather than to either.

`Resources/` holds the asset catalog, and on the watch the `Info.plist` and the
catalog that localizes it. The entitlements stay at the target's root: they are
signed with, not shipped.

Both targets are `PBXFileSystemSynchronizedRootGroup`s, so moving a file or
adding a folder needs no project edit. `Info.plist` is the one exception — its
path is written twice in `INFOPLIST_FILE` and once in the target's membership
exceptions, and all three have to agree.

## Reading code

Reach for the `LSP` tool before `cat`. `documentSymbol` outlines a file in about
fifteen lines where `cat` spends 1,200 tokens on it, and `goToDefinition` and
`hover` answer "what is this" without opening anything.

Semantic operations resolve only inside `Packages/*`, which build through SwiftPM
and carry an index. The Xcode targets — `Padel/` and `Padel Watch App/` — have no
compile database, so sourcekit-lsp reports `No such module` there and `hover` and
`goToDefinition` come back empty; `documentSymbol` is syntactic and still works.
`findReferences` names the right files and the wrong lines: it answers from the
index, which lags the file on disk, so its positions drift the moment you edit.
Read it as a list of files if you like, but `grep -rn` owns call sites.

Read a file in full when you are about to change it. Dumping a directory to
answer one question costs 8,000 tokens for `Packages/PadelScoring` alone, and
every one of them is resent on each later model call.

## Editing files

Change a file with the Edit tool and create one with Write. Auto mode approves
both inside the working directory without a prompt, so a heredoc buys no
permission and costs a full copy of the file in output tokens — which is then
resent on every later model call. A PreToolUse hook denies heredoc rewrites of
source files; heredocs into `/tmp` stay fine for throwaway scripts. The hook is
installed at user scope — `~/.claude/hooks/no-heredoc-writes.py`, wired up in
`~/.claude/settings.json` — so it guards every project and lives in none of
them. Nothing in this repo enforces it, and a fresh clone gets no such guard.

## Writing comments

Write them the way Apple writes its documentation: the summary first, the rest
only if the summary leaves something unsafe to assume.

- **One sentence, then a blank line.** A doc comment opens with a single
  sentence saying what the symbol is or does. Types and properties take a noun
  phrase — "The side serving the current game." Methods take a third-person
  verb — "Returns the score after the rally."
- **A discussion paragraph only for what a caller would otherwise get wrong:**
  a precondition, a failure mode, a unit, a threading rule, an ownership rule.
  Two or three sentences. If it needs more, it is an ADR.
- **Rationale lives elsewhere.** Why a design was chosen belongs in
  `docs/adr/` or in the commit message. A comment says what the code does now,
  not how we arrived at it — the reader needs to know the workout keeps the
  screen awake, not the two gestures we tried before the button.
- **Use the callouts rather than prose** where one fits: `- Parameter`,
  `- Returns`, `- Throws`, `- Note`, `- Important`, `- Warning`, and
  double-backtick links to other symbols.
- **Never restate the code.** `// increment the score` over `score += 1` is
  noise.

`///` and `//` are held to different bars. A doc comment on a type, a member or
a function is expected, and is written even when the name looks self-evident:
it is what Quick Help shows, and a symbol without one shows nothing. An inline
comment inside a body is not expected and has to earn its line — where a number
came from, what a workaround is working around, an API constraint the call site
cannot show on its own. One line above the code it is about. A body needing
several of them wants splitting, not annotating.

Anything deferred is a `TODO:` on its own line, where the work will have to be
done, with the ticket it belongs to:

    // TODO: Turn the corner rule a quarter turn for the landscape board
    // (.scratch/phone-scoring/issues/07-the-scoreboard.md)

Xcode lists `TODO:` and `FIXME:` in the jump bar, which is the whole reason for
the exact spelling — `// todo` and `// Todo(later)` are invisible there.
`FIXME:` marks something already wrong; `TODO:` marks something not yet done.
Neither is a place to argue a case: one line saying what, plus the path.

The comments already in the repo are the older, narrative style, and they are
not being retrofitted. Apply this to what you write and to what you are already
changing; leave the rest alone until a ticket says otherwise.

## Bulk edits

For a mechanical change across many files — renaming a call, reshaping an API,
rewording a comment convention — write one `ast-grep` rule instead of editing
each file. It parses Swift through tree-sitter, so it matches structure and
leaves lookalike text inside strings alone:

    ast-grep --lang swift -p '<pattern>' -r '<rewrite>' Packages "Padel Watch App"

It prints a diff and writes nothing until you add `-U`.

## Session scope

One ticket per session, one session per ticket. Every model call resends the
whole conversation, so a session carrying three tickets pays for the first
ticket's context while working on the third — length costs as much as work.

Run `/compact` once the context passes ~150k tokens, and open a fresh session
when the next ticket is unrelated to the one just finished.

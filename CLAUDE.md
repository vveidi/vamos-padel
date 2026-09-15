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

`/backlog [feature]` reads the board — `.scratch/status.sh` — and says what is
takeable, what is blocked and on what. See `.claude/skills/backlog/SKILL.md`.

## Building and testing

`/build [target]` and `/test [target]` run the commands below for a package,
an app scheme, or `all`, picking one from what's changed if `target` is
omitted. See `.claude/skills/build/SKILL.md` and
`.claude/skills/test/SKILL.md`.

Pipe `xcodebuild` and `swift test` through `xcsift`. Unlike `xcbeautify`, it's
built for an agent to read rather than a human to skim: a clean build or test
run collapses to one JSON object — `warnings`, `errors`, `passed_tests`,
`failed_tests` — and `-q` drops even that to nothing on a pass. A failure keeps
the file, line, and message for every error by default; `-w` adds the same for
warnings, which are otherwise just a count.

Open the pipe with `set -o pipefail`, which makes the shell report the build's
exit code instead of `xcsift`'s. Without it a failing build reports success:

    set -o pipefail; xcodebuild -project Padel.xcodeproj -scheme "Padel Watch App" \
      -destination 'platform=watchOS Simulator,id=<uuid>' build 2>&1 | xcsift -q

`xcodebuild -list -project Padel.xcodeproj` names the schemes; a failed
`-destination` prints every simulator UUID the scheme accepts.

Most of the tests are the packages' and run under `swift test`. One target's
tests are the project's: `PadelTests`, hosted by the phone app, which reads the
strings out of the built `Padel.app`. It runs under the `Padel` scheme's test
action on an iOS simulator, and `xcsift`'s summary counts the cases behind it
directly — `passed_tests` and `failed_tests`, no separate `xcresulttool` pass
needed.

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

    PadelStorage/   Interface/   the protocols and SavedMatch (ADR-0002)
                    Database/    the GRDB implementation behind that interface

    PadelDelivery/  Transport/   the wire and what travels over it
                    Ends/        the watch's side and the phone's side

    PadelDesign/    Tokens/      what a screen names: palette, ramp, radii
                    Court/       the court, net, ball and the two lights
                    Controls/    the five controls and their metrics

What is *not* in a folder is deliberate: a package's shared test harness and
its isolation test sit at the test target's root, and `Logging.swift` sits at
`PadelDelivery`'s, because they belong to no one subsystem.

`PadelStorage` is the one package whose two folders are two targets, and
therefore two products. `PadelStorage` is `Interface/` alone and links no
database; `PadelStorageDatabase` is `Database/` and depends on it and on GRDB.
The tests stay one target, named `PadelStorageTests` and mirroring both folders.

The split exists so that the watch can name a `SavedMatch` on the wire without
linking GRDB. It does not do that yet: both apps link both products today,
because the watch still opens a store of its own. It drops to the interface
alone when the store leaves it.

Adding a folder needs no manifest edit — SwiftPM compiles everything under the
target's directory. `PadelStorage` is the exception, and for the same reason:
each of its targets names its half with a `path:`, so a third folder there
belongs to neither until the manifest says which.

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

**The default is no comment.** The code says what it does; a name that needs a
sentence to be understood wants renaming, and an extracted function with an
honest name beats the comment that would have explained the block. This holds
for `public` symbols too — there is no Quick Help exemption. A symbol whose
signature already answers the question shows nothing in Quick Help because
there is nothing left to show.

A comment is written only when something true about the code **cannot be said
in the code**:

- a **precondition** or an invariant the type cannot express;
- a **unit**, a coordinate space, a frame of reference;
- a **threading** or **ownership** rule;
- a **failure mode** — what happens on the unhappy path, when the signature
  does not say;
- **where a number came from**, when it was measured or read off a board;
- **what a workaround is working around**, or an API constraint the call site
  cannot show on its own.

Nothing else. In particular:

- **Never restate the code.** `// increment the score` over `score += 1` is
  noise, and so is `/// The court's surface.` over `static let court`.
- **Never narrate history.** Not what the design used to be, not what it
  replaced, not what was tried first. Git holds that.
- **Rationale lives elsewhere.** Why a design was chosen belongs in
  `docs/adr/`, in the ticket, or in the commit message. A ticket that asks for
  an argument to be written into a doc comment is asking for the wrong thing;
  say so and put it in an ADR.

**Four lines is the ceiling**, comment markers included. Anything that wants
more is an ADR or a commit message, without exception. Use the callouts rather
than prose where one fits — `- Parameter`, `- Returns`, `- Throws`, `- Note`,
`- Important`, `- Warning` — and double-backtick links to other symbols.

`///` and `//` are held to the same bar, and it is this one. An inline comment
goes one line above the code it is about; a body wanting several wants
splitting instead.

**No `TODO:`, and no `FIXME:`.** Work that is not done is a ticket under
`.scratch/`, never a comment. Wanting to write one is the signal that a ticket
is missing: stop and write the ticket instead, then say in the handoff that you
opened it.

A `TODO:` is worse than no record at all. The board cannot see it —
`.scratch/status.sh` reads ticket files, so a comment is work that never appears
as work, has no acceptance criteria, blocks nothing and is blocked by nothing,
and survives every review because a reviewer reads it as a note rather than as
a debt. It ages in place until the reason for it is gone and nobody dares delete
it. A ticket is the one mechanism this repo has for something that should happen
later, and it costs about as much to write as the comment did.

The same goes for a `FIXME:` on something already wrong, which is a bug, which
is a ticket. If it is wrong and small, fix it now; if it is wrong and not small,
it needs a ticket more than a comment, not less.

`// MARK:` is not affected and stays — it is navigation, not deferred work, and
Xcode's jump bar reads it.

Most of the comments already in the repo predate this rule and break it: the
older style put an essay on every symbol. `comment-diet` is retrofitting them
one area at a time. Until that feature closes, apply this rule to what you
write and to what you are already changing, and leave the rest to its ticket —
but never take a file you are editing as the example to follow.

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

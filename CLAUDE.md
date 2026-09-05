# padel

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

## Building and testing

Pipe `xcodebuild` and `swift test` through `xcbeautify --quiet`. It cuts the log
down to warnings and errors, keeping the file, line, and message on every one of
them; `swift test` adds a line per suite on top of that. A hand-picked
`| tail -N` cuts off the error you ran the build to find.

Open the pipe with `set -o pipefail`, which makes the shell report the build's
exit code instead of `xcbeautify`'s. Without it a failing build reports success:

    set -o pipefail; xcodebuild -project padel.xcodeproj -scheme "padel Watch App" \
      -destination 'platform=watchOS Simulator,id=<uuid>' build 2>&1 | xcbeautify --quiet

`xcodebuild -list -project padel.xcodeproj` names the schemes; a failed
`-destination` prints every simulator UUID the scheme accepts.

`-list` reads nothing but the project file in name only: it resolves the package
graph on the way, which writes `SourcePackages` and reaches GitHub for GRDB. It
sits on the allowlist because it changes no source, not because it is inert.

## Reading code

Reach for the `LSP` tool before `cat`. `documentSymbol` outlines a file in about
fifteen lines where `cat` spends 1,200 tokens on it, and `goToDefinition` and
`hover` answer "what is this" without opening anything.

Semantic operations resolve only inside `Packages/*`, which build through SwiftPM
and carry an index. The Xcode targets — `padel/` and `padel Watch App/` — have no
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

## Bulk edits

For a mechanical change across many files — renaming a call, reshaping an API,
rewording a comment convention — write one `ast-grep` rule instead of editing
each file. It parses Swift through tree-sitter, so it matches structure and
leaves lookalike text inside strings alone:

    ast-grep --lang swift -p '<pattern>' -r '<rewrite>' Packages "padel Watch App"

It prints a diff and writes nothing until you add `-U`.

## Session scope

One ticket per session, one session per ticket. Every model call resends the
whole conversation, so a session carrying three tickets pays for the first
ticket's context while working on the third — length costs as much as work.

Run `/compact` once the context passes ~150k tokens, and open a fresh session
when the next ticket is unrelated to the one just finished.

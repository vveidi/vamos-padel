# padel

## Agent skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature-slug>/` in this repo. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Building and testing

Pipe `xcodebuild` and `swift test` through `xcbeautify --quiet`. It prints only
warnings and errors, and keeps the file, line, and message on every one of them.
A hand-picked `| tail -N` cuts off the error you ran the build to find.

Open the pipe with `set -o pipefail`, which makes the shell report the build's
exit code instead of `xcbeautify`'s. Without it a failing build reports success:

    set -o pipefail; xcodebuild -project padel.xcodeproj -scheme "padel Watch App" \
      -destination 'platform=watchOS Simulator,id=<uuid>' build 2>&1 | xcbeautify --quiet

`xcodebuild -list -project padel.xcodeproj` names the schemes; a failed
`-destination` prints every simulator UUID the scheme accepts.

## Reading code

Reach for the `LSP` tool before `cat`. `documentSymbol` outlines a file in about
fifteen lines where `cat` spends 1,200 tokens on it, and `goToDefinition` and
`hover` answer "what is this" without opening anything.

Semantic operations resolve only inside `Packages/*`, which build through SwiftPM
and carry an index. The Xcode targets — `padel/` and `padel Watch App/` — have no
compile database, so sourcekit-lsp reports `No such module` there and `hover` and
`goToDefinition` come back empty; `documentSymbol` is syntactic and still works.
`findReferences` is unreliable everywhere in this repo, so `grep -rn` owns call
sites.

Read a file in full when you are about to change it. Dumping a directory to
answer one question costs 8,000 tokens for `Packages/PadelScoring` alone, and
every one of them is resent on each later model call.

## Editing files

Change a file with the Edit tool and create one with Write. Auto mode approves
both inside the working directory without a prompt, so a heredoc buys no
permission and costs a full copy of the file in output tokens — which is then
resent on every later model call. A PreToolUse hook denies heredoc rewrites of
files in this repo; heredocs into `/tmp` stay fine for throwaway scripts.

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

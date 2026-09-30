---
name: next-ticket
description: Take one ticket, build it in a worktree of its own, and hand it back as a pull request. Use when the user invokes /next-ticket, or asks to pick up a ticket, continue the backlog, or work the tickets one at a time.
disable-model-invocation: true
---

# Next ticket

One ticket per session, built in a git worktree of its own and handed back as a
pull request. Several tabs run this at the same time, and the rule under every
step below is the same one: **touch nothing outside your own worktree and your
own simulators.** The repository's own directory belongs to no session — a
`git checkout` there changes the files another tab is building.

`$ARGUMENTS` names the ticket: `<feature>/<NN>`, as in `/next-ticket
phone-scoring/04`. It is required — see **The argument**.

## The three rounds

A session is one ticket, one branch and one pull request. Every round is one of
three kinds, decided by what the user's message carries, and never two:

- **Take** — no PR exists yet. Build the ticket, push the branch, open the PR,
  stop.
- **Fix** — a PR exists and the user has findings, on GitHub or in the tab. Fix
  them, push, answer the threads, stop.
- **Drop** — the user says to drop it, or its PR is closed unmerged. Clean up
  and stop.

**You never merge.** The user merges on GitHub, squashed, and that is what puts
the ticket on `main`.

## The sweep

A take round starts here, in the repository's own directory, before any
worktree exists. It is the only housekeeping anyone does, so it runs every
time:

    git fetch --prune origin
    git worktree list --porcelain

For each worktree under `.claude/worktrees/`, its branch is the ticket it was
for. Ask GitHub what became of it:

    gh pr list --head "<branch>" --state all --json state --jq '.[0].state'

- `MERGED` or `CLOSED` — remove the worktree, delete the branch, and delete the
  simulators named `padel-<feature>-<NN>-*`.
- `OPEN` — leave it alone and report it: the branch, and how long since its last
  commit. A pile of unlanded branches is the thing this report exists to make
  visible.

Then delete any `padel-*` simulator whose worktree is gone, whatever its state.

A worktree you remove may belong to a tab that is still open. That is fine and
expected — its ticket is merged, so its session is over — but say which ones you
removed, because that tab will fail confusingly if the user types into it.

## A take round

1. **Resolve the argument.** `<feature>/<NN>` names a ticket file at
   `.scratch/<feature>/issues/<NN>-*.md`. No argument, or a feature with no
   number, is a stop-and-ask: run `.scratch/status.sh <feature>` and show the
   takeable rows. Do not pick one yourself — with four tabs running, the board
   is the user's to allocate.

2. **Run the sweep**, above.

3. **Check nobody else has it.** After the fetch, the branch list is shared
   state across every worktree of this repo, and a pull request is shared
   across machines:

       git branch -a --list "*<feature>/<NN>-*"
       gh pr list --state all --json headRefName \
         --jq '.[] | select(.headRefName | startswith("<feature>/<NN>-"))'

   Anything comes back, stop and say what it found. A ticket with a branch has
   an owner, merged or not.

4. **Read the ticket's status before taking it.** Leave anything marked
   `needs-triage` or `for a human` alone — those are the user's, and a ticket at
   9/11 criteria is not an invitation. A ticket whose blockers are not `done` on
   `origin/main` is not takeable either: your worktree branches from
   `origin/main`, so a blocker sitting unmerged in a sibling tab is a blocker
   you do not have.

5. **Enter a worktree** named for the ticket — `<feature>/<NN>-<slug>`, the
   ticket file's own slug, as in `phone-scoring/04-the-scoreboard`. It branches
   from `origin/main`. Everything from here on happens inside it.

6. **Make your own simulators**, one per scheme the ticket needs, following
   `docs/agents/targets.md`. Name them `padel-<feature>-<NN>-<platform>` and use
   their UUIDs for every `-destination`, `simctl` and UI call for the rest of
   the session. The devices already on the machine are shared with every other
   tab; installing over one of those clobbers another tab's app mid-run.

7. **Read the ticket in full**, along with whatever it names — the board it is
   drawn from, the ADR it cites, the screen it changes. `CLAUDE.md` and the
   feature's spec govern. What a ticket says must not change is not up for
   renegotiation; if you think it is wrong, say so in the PR body and build it
   as written.

8. **Build it, test it, and drive it.** Run the `build` and `test` skills, then
   take the change through every state the ticket lists on your own simulator,
   in both languages where the words differ, and again at the largest Dynamic
   Type setting. Screenshot what you are going to claim. A ticket is not done
   because it compiles.

9. **Run the `code-review` skill over the work before committing it**, so what
   it finds folds into the one commit the ticket gets. Then split what comes
   back:
   - A **confirmed defect** — wrong behaviour, a broken state, a criterion that
     is not actually met — fix it, and drive it again if the fix touched the
     screen.
   - A **judgment call** — a naming argument, a structure it would have done
     differently, a suggestion the ticket does not ask for — leave it and put it
     in the PR body for the user to arbitrate. Do not quietly act on it and do
     not quietly drop it.

10. **Hand it back — run the `submit-ticket` skill.** It owns the rest: closing
    the ticket file, the one commit in Conventional Commits format, the pull
    request, the "what to look at first" comment, and the reply in this tab.
    Then stop.

    Its rule is worth knowing before you get there, because it decides what you
    write down along the way: the owner reads the PR on a phone, and he needs
    what changed and what he has to decide. Reasoning he cannot act on is noise.

## A fix round

Findings arrive on the PR, in the tab, or both. Start by fetching what is on
GitHub, whatever the user typed:

    gh pr view --comments
    gh api repos/{owner}/{repo}/pulls/<n>/comments

Fold those together with anything in the user's message, fix them, and drive
anything that touched a screen again. The `submit-ticket` skill's **A fix
round** covers the rest — the commit's format, the push, and replying to each
thread without resolving it.

Then stop. Do not take another ticket: this session has one.

## A drop round

The user says to drop it, or the sweep found the PR closed unmerged. Close the
PR if it is still open, exit the worktree removing it and its branch, and delete
the session's simulators. Leave the ticket file on `main` untouched — it is
still `ready-for-agent`, and a later tab may take it.

## The argument

`<feature>/<NN>` and nothing else. Today's tolerance for guessing — the feature
worked last round, or the only feature with takeable work — is gone: it was safe
with one session and it is not with four.

A bare `/next-ticket`, or a feature with no number, means showing that feature's
takeable rows and stopping. An unknown feature or number is a stop-and-report
error naming what `.scratch/` actually holds.

## Asking, and not asking

Ask **one** question with concrete options when guessing wrong would mean
redoing the work, and wait for the answer. Ask nothing that the ticket, the
board, or `CLAUDE.md` already answers — make those calls yourself and say in the
PR body which way you went.

Report failures as failures. A test you skipped, a state you could not get on
screen, a criterion you ticked on reasoning rather than on evidence: say so.

When the conversation passes ~150k tokens, say so and recommend a fresh session.
A session is a ticket, so a fresh session is a fresh worktree, which is exactly
what the next ticket wants anyway.

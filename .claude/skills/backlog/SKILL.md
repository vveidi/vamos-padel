---
name: backlog
description: Read the ticket board — every feature's tickets, their blockers, their criteria and which are free to pick up. Use when the user invokes /backlog, or asks what is left, what is next, what is blocked, how a feature is going, or what state the backlog is in.
---

# Backlog

`.scratch/status.sh` is the board. Run it rather than reading ticket files: it
reads the `**Status:**` line, the `**Blocked by:**` line and the criteria
checkboxes out of every `.scratch/<feature>/issues/NN-*.md`, and a hand count
of the same files costs thousands of tokens to get wrong.

    .scratch/status.sh                   every feature in work
    .scratch/status.sh phone-scoring     one feature
    .scratch/status.sh phone-scoring release
    .scratch/status.sh archive/redesign  one finished feature

`$ARGUMENTS` is the feature slug, or slugs, or nothing. An unknown slug exits
non-zero and names the directory it looked for — offer the slugs under
`.scratch/` rather than guessing which one was meant.

Finished features live in `.scratch/archive/` and the bare board leaves them
out. A closing `Finished, move to archive/:` line names one that was closed but
never moved — say so, because the move belongs in the PR that closed it.

## Reading a row

| Column   | What it is                                                  |
| -------- | ----------------------------------------------------------- |
| #        | the ticket number, unique within its feature                 |
| Ticket   | its title, cut at 44 characters                              |
| Blocked  | every ticket it lists as a blocker, done or not              |
| Criteria | acceptance criteria checked off, out of the total            |
| Status   | the triage label, read against the blockers                  |

The status column is the `Status:` line crossed with the blockers, so it says
something the ticket file alone does not:

- **✅ done** — terminal. Nobody picks it up again.
- **🚫 wontfix** — closed unbuilt.
- **⛔ waiting on NN** — has an open blocker, whatever its own label says.
- **🟢 up for grabs** — `ready-for-agent`, unblocked. An agent's to take.
- **🟢 for a human** — `ready-for-human`, unblocked. The user's to take, and
  not yours, however close its criteria are to full.
- **🟡 needs-triage** / **🟡 needs-info** — the label, unblocked, and not ready
  for anyone to build.

`Up for grabs` on the footer line counts both green states together. A ticket
sitting at 9/11 criteria is not half-free: the label decides, not the count.

## The board is only as fresh as `main`

A ticket is closed on its own branch and reaches `main` only when its pull
request merges, so a ticket a session is three hours into still reads
`ready-for-agent` in its file. Two things follow.

**Read the board from `origin/main`, not from here.** Inside a worktree the
`.scratch/` you have is your branch's, frozen at whatever `origin/main` held
when the session started. `status.sh` finds the features next to itself, so the
board has to be run where a current `main` is checked out — the repository's own
directory, which `git worktree list` prints first:

    root=$(git worktree list --porcelain | sed -n '1s/^worktree //p')
    git -C "$root" pull --ff-only
    "$root/.scratch/status.sh" <feature>

That directory holds no session's work, so fast-forwarding it disturbs nobody.

**Mark the rows that are in flight.** An open pull request is a ticket someone
has, and its branch carries the ticket in its name:

    gh pr list --state open --json number,headRefName,updatedAt

A row whose `<feature>/<NN>` matches an open PR is not up for grabs however
green the board prints it — say so on the row, with the PR number. This is the
one place the board lies, and it lies exactly when the user is deciding what the
next tab gets.

## What to say back

Show the board's own output — the columns are the answer, and rewriting them
as prose loses the blockers. Then add the reading it does not give:

- which feature has takeable work, and which ticket is lowest-numbered there
- what a `⛔` is actually waiting on, when the chain is more than one deep
- anything stalled on the user — a `for a human` row, or a `needs-triage` one
  that has been sitting through several rounds

Keep it to a few lines under the table. If the user asked about one feature,
answer about that one and do not tour the rest.

To then work a ticket, that is `/next-ticket` — this skill reports and stops.

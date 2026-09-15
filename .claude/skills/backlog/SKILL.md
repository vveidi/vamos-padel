---
name: backlog
description: Read the ticket board — every feature's tickets, their blockers, their criteria and which are free to pick up. Use when the user invokes /backlog, or asks what is left, what is next, what is blocked, how a feature is going, or what state the backlog is in.
---

# Backlog

`.scratch/status.sh` is the board. Run it rather than reading ticket files: it
reads the `**Status:**` line, the `**Blocked by:**` line and the criteria
checkboxes out of every `.scratch/<feature>/issues/NN-*.md`, and a hand count
of the same files costs thousands of tokens to get wrong.

    .scratch/status.sh                 every feature
    .scratch/status.sh redesign        one feature
    .scratch/status.sh redesign release

`$ARGUMENTS` is the feature slug, or slugs, or nothing. An unknown slug exits
non-zero and names the directory it looked for — offer the slugs under
`.scratch/` rather than guessing which one was meant.

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

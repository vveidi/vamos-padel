---
name: submit-ticket
description: Close a finished ticket and hand it back as one commit and one pull request the owner can read on a phone. Use when the user invokes /submit-ticket, or asks to open the PR, send the work for review, or hand the ticket back.
---

# Submit a ticket

The work is built, tested and driven. This turns it into one commit and one
pull request.

**The owner merges on GitHub, squashed.** The PR title and body become the
commit message on `main`, so write them as one thing. **Never merge yourself.**

## The rule under all of it

The owner reads this on a phone. He needs two things: what changed, and what he
has to decide. Everything else is noise — the diff is one tap away.

Short sentences. Plain words. English, like every artifact in this repo.

## 1. Close the ticket

In the ticket file, on your branch:

- tick every acceptance criterion;
- write the closing note under `## Comments`;
- set `**Status:** done`.

If that was the feature's last open ticket, archive the feature in the same
commit: `git mv .scratch/<feature> .scratch/archive/<feature>` and set the spec's
`Status:` to `done`. `.scratch/status.sh` names a finished feature left outside.

A criterion you could not meet is **not** ticked. Say so in the note, and open
a ticket for what is left — `CLAUDE.md` forbids a `TODO:`. A ticket closed at
19/20 with a terminal label is the failure `docs/agents/triage-labels.md` names.

The closing note says what shipped, what stayed open, and what the owner has to
decide. It is not a retelling of the work.

## 2. The commit

One commit:

    <feature>/<NN>: <description>

    <body>

    <footers>

### Subject

The ticket, then the description:

    court-surface/02: draw the app icon as a ball on the court
    watch-tap-mode/03: store the tap mode and read it back
    phone-scoring/04: draw the scoreboard in landscape

`<feature>/<NN>` is the ticket, spelled the way everything else spells it —
the branch, the board, and `/next-ticket`'s own argument. One spelling, so
`git log` and `.scratch/` can be read against each other.

The description is imperative, lower case, no full stop, and about 60
characters or fewer including the ticket. It says what the commit does, not
what the ticket was called.

**No `feat:` or `fix:`.** This is deliberately not Conventional Commits: the
ticket already says where the change lands and what it is for, and a type in
front of it is a second, coarser answer to a question `.scratch/` answers
better. Nothing here consumes a changelog generator.

### A commit with no ticket

Board fixes, doc edits, anything asked for in conversation — these commit
straight to `main` with no branch, and there is no ticket to name. Write the
description alone:

    settle which scope owns docs/design
    reopen the one surface as ready-for-human

### Body

**Five lines is the ceiling.** Why, not what — the diff says what. Wrap at 72.
Leave it out when the description already says everything.

Anything that wants more than five lines is an ADR, not a commit body.

### Footer

Always:

    Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>

## 3. The pull request

Title: the commit description, with its type and scope. Exactly the commit
subject.

Body: three headings and nothing else.

    ## What changed

    One to three bullets.

    ## What you need to decide

    One line each:
    - every judgment call `code-review` raised that you did not act on;
    - every place you departed from the ticket as written;
    - every criterion left open, and where it went.

    Nothing to decide: write "Nothing — merge it."

    ## Checked

    Builds, tests, screens driven. One line.

Then the attribution line the harness asks for.

**"What you need to decide" is the point of the PR.** If you find yourself
explaining the reasoning behind something the owner does not have to rule on,
cut it.

## 4. What to look at first

One PR comment. Two or three lines: where to start reading, and what you are
least sure about.

It is a comment and not part of the body because it reads oddly as a commit
message six months on.

## 5. Stop

    git push -u origin <branch>
    gh pr create --base main --title "<the commit subject>" --body-file <file>

Reply in the tab with the PR URL and one line. Then stop.

## A fix round

Review findings arrive on the PR or in the tab. Fix them, drive anything that
touched a screen again, and commit to the same branch. The subject names the
same ticket as the first commit, because it is the same ticket.

Then reply to each thread you addressed, one line each. **Do not resolve
them** — resolving is the reviewer's verb.

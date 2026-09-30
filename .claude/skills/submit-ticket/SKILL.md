---
name: submit-ticket
description: Close a finished ticket and hand it back as one commit and one pull request, in Conventional Commits format. Use when the user invokes /submit-ticket, or asks to open the PR, send the work for review, or hand the ticket back.
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

A criterion you could not meet is **not** ticked. Say so in the note, and open
a ticket for what is left — `CLAUDE.md` forbids a `TODO:`. A ticket closed at
19/20 with a terminal label is the failure `docs/agents/triage-labels.md` names.

The closing note says what shipped, what stayed open, and what the owner has to
decide. It is not a retelling of the work.

## 2. The commit

One commit, [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/):

    <type>(<scope>): <description>

    <body>

    <footers>

### Type

`feat` and `fix` are the spec's own. Also allowed here: `docs`, `refactor`,
`test`, `build`, `ci`, `chore`, `perf`, `style`.

A breaking change takes `!` after the scope — `feat(storage)!:` — or a
`BREAKING CHANGE:` footer. That footer is uppercase, and it is the one
case-sensitive thing in the spec.

### Scope

The part of the repo the ticket is about:

    scoring  storage  delivery  design    the packages
    watch    phone                        the app targets
    docs                                  CONTEXT.md, docs/adr, docs/agents, docs/design
    board                                 .scratch/
    project                               Padel.xcodeproj and the build settings

Touching several, name the one the ticket is about. Genuinely spanning
everything, leave the scope out — the spec makes it optional.

### Description

Imperative, lower case, no full stop, about 60 characters or fewer. What the
commit does, not what the ticket was called.

    feat(design): draw the app icon as a ball on the court
    fix(watch): keep the score legible in Always-On
    docs(board): open the two ADR tickets court-surface owes

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
touched a screen again, and commit to the same branch. The commit is
Conventional like any other — usually `fix(<scope>):`, or the type that matches
what you actually changed.

Then reply to each thread you addressed, one line each. **Do not resolve
them** — resolving is the reviewer's verb.

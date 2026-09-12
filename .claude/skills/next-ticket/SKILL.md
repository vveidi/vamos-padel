---
name: next-ticket
description: Take the next ticket of a feature's backlog, work it end to end, self-review it, and hand it back for a human review. Use when the user invokes /next-ticket, or asks to pick up the next ticket, continue the backlog, or work the tickets one at a time.
disable-model-invocation: true
---

# Next ticket

One ticket per round. The user reviews between rounds; you never take two in a
row.

`$ARGUMENTS` is the feature slug — the directory name under `.scratch/`, as in
`/next-ticket redesign`. It is optional; **Which feature** below says what to do
without it.

## Each round

1. **If the user's message carried review findings, fix those and stop.** That
   is the whole round: fix, commit, hand back. Do not also take a new ticket —
   a round is either fixing or taking, never both.
2. **Otherwise take a ticket.** Run `.scratch/status.sh` and take the
   lowest-numbered ticket of the feature that is up for grabs. Leave anything
   marked `needs-triage` or `for a human` alone — those are the user's, and a
   ticket at 9/11 criteria is not an invitation. If nothing is left that you
   can take, say so and stop rather than reaching into another feature.
3. **Read it in full**, along with whatever it names — the board it is drawn
   from, the ADR it cites, the screen it changes. `CLAUDE.md` and the feature's
   spec govern. What a ticket says must not change is not up for
   renegotiation; if you think it is wrong, say so in the handoff and build it
   as written.
4. **Build it, test it, and drive it.** Run the build and the tests, then take
   the change through every state the ticket lists on a real simulator, in
   both languages where the words differ, and again at the largest Dynamic
   Type setting. Screenshot what you are going to claim. A ticket is not done
   because it compiles.
5. **Run the `code-review` skill over the work before committing it**, so that
   what it finds folds into the one commit the ticket gets. Then split what
   comes back:
   - A **confirmed defect** — wrong behaviour, a broken state, a criterion
     that is not actually met — fix it, and drive it again if the fix touched
     the screen.
   - A **judgment call** — a naming argument, a structure it would have done
     differently, a suggestion the ticket does not ask for — leave it and put
     it in the handoff for the user to arbitrate. Do not quietly act on it and
     do not quietly drop it.
6. **Close the ticket.** Tick the acceptance criteria, write the closing note
   under `## Comments`, and commit in the repo's style: an imperative subject,
   then prose saying what changed and what argued for it.
7. **Stop and hand back in under ten lines**: what the screen is now, anything
   that went differently from what the ticket asked, what the review raised
   and what you did with each finding, and what to look at first. The user
   reads these on a phone — detail belongs in the ticket and the commit
   message, not in the reply.

**Do not start the next ticket.** Running `code-review` is not the same as
being reviewed: the last word between two tickets is the user's.

## Which feature

With an argument, that feature. Without one, in order:

1. The feature this session's previous round worked, if there was one.
2. Otherwise, if exactly one feature has a takeable ticket, that feature.
3. Otherwise ask which, with the candidates as options. Do not guess — picking
   up the wrong backlog wastes a whole round.

## Asking, and not asking

Ask **one** question with concrete options when guessing wrong would mean
redoing the work, and wait for the answer. Ask nothing that the ticket, the
board, or `CLAUDE.md` already answers — make those calls yourself and say in
the handoff which way you went.

Report failures as failures. A test you skipped, a state you could not get on
screen, a criterion you ticked on reasoning rather than on evidence: say so.

When the conversation passes ~150k tokens, say so in the handoff and recommend
a fresh session instead of taking another ticket. Every model call resends the
whole conversation, which is what `CLAUDE.md`'s "Session scope" is about; this
skill bends that rule on purpose and it does not bend far.

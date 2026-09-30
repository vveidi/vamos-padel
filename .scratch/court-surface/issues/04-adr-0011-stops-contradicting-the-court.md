# 04: ADR-0011 stops contradicting the court

**What to build:** the two places where ADR-0011 still describes the two-colour
court corrected, and the one remaining doc that still asserts it in the present
tense.

**Blocked by:** None

**Status:** ready-for-agent

- [ ] ADR-0011's consequence **"Strength belongs to the surface, not to the
      mark"** no longer calls the mark's strength "a per-side constant settled by
      eye". There is one surface, so there is one number — `.scratch/rally-mark/spec.md`
      already says so and the ADR still does not
- [ ] The same paragraph no longer says `courtSurface`, `courtLine`, `courtInk`
      and `courtWeave` "are all per-side answers in that one file already".
      `courtLine` is deleted and the other three lost their `Side` (ADR-0012).
      The argument it was making — that a theme threaded through those functions
      threads the mark's number with them — survives the correction and should
      not be dropped with it
- [ ] ADR-0011's consequence **"The mark and the identity of a half are now made
      of the same material"** no longer says which half is ours "is said today by
      turf green against glass blue". It is said by position and the net
      (ADR-0012)
- [ ] That consequence's *conclusion* is re-decided rather than reworded. It
      argued that themes would degrade a hue difference into a value difference,
      and that the mark brightens the surface carrying that identity. With one
      surface the premise is gone — say whether the consequence is now settled,
      or what is left of it
- [ ] **How the correction is made is decided and stated**: edited in place, or
      left standing with a superseding note pointing at ADR-0012. ADR-0012
      already records the court with no painted lines, so 0011 needs to stop
      contradicting it, not to re-argue it
- [ ] `docs/design/canvas.json`'s board description no longer asserts "Deep glass
      blue for their half, turf green for ours" as present tense. It is the seed
      text the canvas renders, so it is read as a description of what the app is
- [ ] `grep -rn "turf green\|glass blue" docs/ Packages "Padel Watch App" Padel`
      turns up nothing stating the two-colour rule as current. Two files keep it
      legitimately and must not be "fixed": `docs/design/RallyMark.html`, where
      the rejected candidates are the point and an annotation already says the
      court no longer ships, and `.scratch/rally-mark/spec.md`, which already
      states it in the past tense

## Notes

**This was found and flagged rather than fixed, deliberately.** `court-surface`
01 recorded it in its closing note: `docs/agents/domain.md` says that output
contradicting an ADR is surfaced explicitly rather than silently overridden, so
the ticket that broke 0011 correctly refused to rewrite it. That leaves the
correction owed, which is this.

**Why it cannot wait for the feature to close.** `.scratch/` is emptied when a
feature closes, and the note recording the conflict is in
`.scratch/court-surface/issues/01-the-one-surface.md`. The ADR would keep the
wrong sentence and lose the only record that anyone noticed.

**What is already correct, so that the fix does not go looking for work.**
`court-surface` 01 corrected `.scratch/rally-mark/spec.md` and
`issues/01-the-mark.md`, and wrote the annotation into `docs/design/RallyMark.html`
saying the night court it fires against is no longer what ships and that
candidate B — the painted lines flaring — is unbuildable rather than merely
rejected. What it left, because an ADR is not a ticket's to rewrite, is ADR-0011
itself.

**The risk in this ticket is over-correction.** ADR-0011 is a record of a
decision made at a time, and most of it is still true: the mark is the surface
brightened, the tint beat four other candidates, an undo is not marked, Always-On
never arises. Only the sentences resting on there being two surfaces are wrong.
An ADR rewritten past its actual error stops being a record.

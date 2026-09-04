# 05: The project's first test target

**What to build:** A test target on the phone, and tests that pin the plural forms in both languages.

Until now the Xcode project has had no test target at all — the tests live in the SPM packages, and the wording layer is covered by nothing. That was tolerable while the forms were computed by a function anyone could read. Once they move into the catalog they are data, and data rots without a sound: nobody notices "до 22 очка" until it is on a screen in front of a player.

Because the catalog is shared between the two targets, this one target reaches the watch's keys as well.

**Blocked by:** 02, 03

**Status:** ready-for-agent

- [ ] The project has a test target for `padel`, and it runs in the ordinary test action
- [ ] Every plural-bearing key resolves correctly for every number the rules screen offers — sets 1 to 3, X 1 to 6, and N across its whole range — in both Russian and English
- [ ] The genitive after "до" is pinned by a test: "до 21 очка" and "до 22 очков" are different forms, and the test says which is which
- [ ] At least one key belonging to the watch is resolved from this target, so that the shared catalog is proven shared rather than assumed to be
- [ ] The suite is green

## Notes

**On a test for untranslated keys.** Tempting, and harder than it looks: a key with no translation falls back to its own English text, so "untranslated" and "identical in both languages" are indistinguishable at runtime — and some keys, `"AD"` and `"40"` among them, are legitimately identical. If it can be written without a list of exceptions that has to be maintained, write it. If it cannot, leave it: Xcode's catalog editor reports the same thing, and a test with an exception list rots faster than the data it guards.

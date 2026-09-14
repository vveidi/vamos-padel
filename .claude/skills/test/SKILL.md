---
name: test
description: Test this repo — a Swift package with `swift test`, an app scheme with `xcodebuild test`. Use when the user invokes /test, or asks to run the tests, check the suite passes, or verify nothing broke.
---

# Test

Read `docs/agents/targets.md` and resolve `$ARGUMENTS` through it: a package, an
app scheme, `all`, or — with no argument — whatever the diff points at. It also
holds how to find a scheme's simulator and how to tell a scheme that has tests
from one that only builds.

## A package

    cd <package directory> && set -o pipefail; swift test 2>&1 | xcsift -q

A package with no test target has nothing to run, which is not a failure.

## An app scheme

    set -o pipefail; xcodebuild -project <name>.xcodeproj -scheme "<scheme>" \
      -destination "id=<uuid>" test 2>&1 | xcsift -q

A scheme with no test action is a signal to run the `build` skill on it
instead, and to say that is what happened.

## More than one target

Packages first, then app schemes. Keep going through failing tests — unlike a
build, one target's failures don't need another target held back. A target that
fails to *build* partway through does: treat everything downstream of it the
way the `build` skill treats it, as a symptom of that one break rather than a
separate failure to report.

## Reporting

`xcsift -q` prints nothing on an all-pass run. Otherwise its summary carries
`passed_tests` / `failed_tests`, and every failure's file, line and message —
show that as-is. Say which targets ran, which passed, which didn't, which had
nothing to run, and — when the selection came from the diff rather than an
argument — which changed files drove it.

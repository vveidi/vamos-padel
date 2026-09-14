---
name: build
description: Build this repo — a Swift package with `swift build`, an app scheme with `xcodebuild`. Use when the user invokes /build, or asks to build the project, a package or an app, or wants to confirm a change compiles.
---

# Build

Read `docs/agents/targets.md` and resolve `$ARGUMENTS` through it: a package, an
app scheme, `all`, or — with no argument — whatever the diff points at. It also
holds how to find a scheme's simulator.

## A package

    cd <package directory> && set -o pipefail; swift build 2>&1 | xcsift -q

## An app scheme

    set -o pipefail; xcodebuild -project <name>.xcodeproj -scheme "<scheme>" \
      -destination "id=<uuid>" build 2>&1 | xcsift -q

## More than one target

Packages first, then app schemes — a package sits before whatever depends on
it, so a break surfaces at its source. Stop at the first failure rather than
running the rest: once one package fails to build, its dependents and the apps
failing too is that same failure, not new information.

## Reporting

`xcsift -q` prints nothing on a clean build; check the exit code — `set -o
pipefail` makes it the build's rather than `xcsift`'s — and report success from
that. On a failure, or a clean build with warnings, `xcsift` prints a JSON
summary and, for every error, its file, line and message; show that output
as-is rather than re-describing it. Say which targets built and which didn't,
and — when the selection came from the diff rather than an argument — which
changed files drove it.

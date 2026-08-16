# ADR-014: Use adr-tools 3.0.0 as the Compatibility Corpus Baseline

Date: 2026-08-15

## Status

Proposed

## Context

`adrctl` is intended to be a behavior-compatible successor to `adr-tools` where
practical, while deliberately improving architecture, safety, configuration,
testing, and distribution.

Compatibility cannot be measured against a moving repository or against memory.
The upstream project has a stable 3.0.0 release whose product source and behavior
tests are unchanged by the later documentation-only commits on `master`.

The rewrite also contains intentional deviations, such as refusing ambiguous ADR
references and improving preflight behavior.  The test strategy must distinguish
those changes from accidental regressions.

## Decision

The canonical predecessor comparator for the initial `adrctl` compatibility
milestone SHALL be:

```text
Repository: npryce/adr-tools
Release:    3.0.0
Tag commit: b47d3837d452ca6d2509d2524c7a08c701e84367
```

The compatibility corpus SHALL be independently authored for `adrctl` from
observable predecessor behavior, documentation, and tests.  It SHALL NOT copy or
mechanically translate GPL-covered implementation code into `adrctl` production
source.

The initial inherited command surface to characterize SHALL include:

```text
init
new
link
list
help
generate
generate toc
generate graph
upgrade-repository
```

The top-level dispatch behavior and invocation through the `adr` compatibility
symlink SHALL also be included.

The corpus SHALL cover at least:

- project discovery from root and nested directories;
- `.adr-dir` behavior;
- default `doc/adr` behavior;
- initial repository creation through `init`;
- default and project-specific templates;
- template delimiter auto-detection and explicit overrides;
- numbering, padding, titles, slugs, dates, and statuses;
- editor selection and editor suppression during initialization;
- `new -s` supersede relationships;
- `new -l` relationships;
- reciprocal `link` mutations;
- ADR reference resolution;
- listing order and output;
- help and pager selection;
- TOC generation;
- Graphviz DOT generation and its link-prefix/extension options;
- stdout, stderr, and success/non-success behavior;
- generated executable behavior through both `adrctl` and `adr` names; and
- intentional safety deviations documented by accepted architecture.

Each observed behavior SHALL be classified as one of:

```text
Compatible
Intentional deviation
New adrctl behavior
```

An intentional deviation SHALL have an architectural or specification rationale
and a regression test.  User-visible deviations from established successful
workflows SHOULD include migration guidance.

The first implementation milestone SHALL prioritize the compatible predecessor
surface before optional enhancements.  New features SHALL NOT be used to mask a
missing compatibility case.

Tests SHALL exercise observable behavior: process arguments, streams, exit
status, generated files, file contents, filesystem effects, and the literal
generated artifact.  Tests SHALL NOT assert private Bash helper names or source
layout unless the build contract itself is under test.

The comparator revision SHALL be explicit in test fixtures or test metadata so a
later upstream change cannot silently redefine expected behavior.

Downstream packaged variants MAY be added as additional compatibility evidence
only through an explicit documented decision.  They SHALL NOT silently replace
the 3.0.0 baseline.

## Considered Alternatives

### Compare against upstream master

The current upstream master happens to differ only in documentation, but a moving
branch can change later and makes reproducibility weaker than a tagged release.

### Reuse upstream tests verbatim

That can entangle the rewrite with implementation assumptions, licensing, and
historical test structure.  Independently authored behavior tests provide a
cleaner specification boundary.

### Implement new features first and test compatibility later

This makes it difficult to distinguish regressions from deliberate extensions.
The predecessor surface should be established before optional capabilities
reshape it.

### Require byte-for-byte equivalence everywhere

Some predecessor behavior is incidental, unsafe, or under-specified.  The corpus
exists to make those distinctions explicit rather than freeze every accident.

## Consequences

Compatibility claims become reproducible and reviewable.

Intentional deviations are visible rather than buried in implementation details.

The generated artifact and `adr` symlink are first-class test subjects, not
assumptions inferred from source tests.

## Related Decisions

- Related to: ADR-002
- Related to: ADR-004
- Related to: ADR-007
- Related to: ADR-011
- Adapted from Bootstrap ADR-006, ADR-039, ADR-040, and ADR-046.
- Related baseline: `doc/upstream-adr-tools-compatibility.md`.
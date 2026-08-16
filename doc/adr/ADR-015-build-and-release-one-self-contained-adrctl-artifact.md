# ADR-015: Build and Release One Self-Contained adrctl Artifact

Date: 2026-08-15

## Status

Proposed

## Context

Bootstrap and `mktext` establish a useful source/distribution model: maintain
readable modular Bash source, generate the exact consumer artifact, test that
artifact directly, and treat release metadata as build input rather than runtime
state.

`adrctl` additionally embeds the pinned `mktext` release under ADR-003 and must
remain safe when invoked as either `adrctl` or through an `adr` symlink.

The release process therefore needs a deterministic assembly boundary and must
verify the same bytes that users receive.

## Decision

The canonical maintained implementation SHALL be modular Bash source under
`src/` and/or `lib/` with an explicit build order recorded by Make.

The canonical generated consumer artifact SHALL be:

```text
dist/adrctl
```

The artifact SHALL:

- begin with `#!/usr/bin/env bash`;
- be executable with mode `0755`;
- contain the complete required runtime implementation in one file;
- embed the verified `mktext` v0.0.6 artifact according to ADR-003;
- require no sibling product files for core operation;
- contain exactly one effective product entrypoint owned by `adrctl`;
- remain safe when invoked through an `adr` symlink; and
- require no runtime network access for normal operation.

Build source order SHALL be explicit rather than discovered implicitly by
filesystem globbing.  This keeps assembly deterministic and makes dependency
order reviewable.

The generated artifact SHALL embed immutable build metadata supplied by the build
or release workflow:

```text
VERSION
BUILD_DATE
BUILD_COMMIT
```

`VERSION` SHALL be the SemVer selected by the release process.

`BUILD_DATE` SHALL represent the source revision timestamp rather than wall-clock
build time so rebuilding the same source with the same inputs does not produce a
different timestamp solely because the build ran later.

`BUILD_COMMIT` SHALL identify the source revision, preferably with a stable
abbreviated Git commit when available.

Version reporting SHALL use embedded metadata and SHALL NOT query Git, the clock,
or the network at runtime.

The Makefile SHALL be the canonical local and CI orchestration surface.  It SHALL
provide, at minimum, coherent targets for:

```text
all/build
check
format
test
test-report
docs
docs-clean
docs-stage
checksums
clean
distclean
```

Additional compatibility or minimum-Bash test targets MAY be added as distinct
or composed targets.

`all`/`build` SHALL produce the consumer artifact.  Validation SHALL remain
explicit rather than making artifact production secretly perform every lint,
test, and documentation operation.

Tests SHALL exercise maintained source where useful, but release acceptance SHALL
include literal execution of `dist/adrctl`, including its `adr` symlink path.

The release workflow SHALL:

1. determine and validate the SemVer release version;
2. run the required source checks and behavior tests;
3. acquire and verify pinned build dependencies;
4. build `dist/adrctl` using the selected release metadata;
5. validate the exact generated artifact;
6. generate a SHA-256 checksum for the exact artifact;
7. generate GitHub provenance attestation when the release platform supports it;
8. create the tag/release according to the project's release policy; and
9. publish the exact validated artifact, checksum, and attestation references.

The workflow SHALL pass the release version into Make.  Make SHALL NOT independently
recalculate a potentially different release version.

Release artifacts SHALL use `adrctl` as their canonical identity.  The project
SHALL NOT publish a separately implemented `adr` artifact merely to satisfy
ADR-002.

Generated distribution output SHALL be treated as build output rather than the
canonical maintained source.  It MAY remain untracked in Git; release automation
must therefore build and test it reproducibly from the maintained inputs.

## Considered Alternatives

### Maintain one monolithic source file

This would reduce build mechanics but make a growing compatibility-oriented Bash
program harder to navigate, document, and test in coherent units.

### Discover source modules automatically

Automatic inclusion can make artifact contents depend on directory accidents and
introduces plugin-like behavior rejected by ADR-006.  Explicit source order is
more inspectable.

### Publish both adrctl and adr executable files

A second artifact increases verification and release surfaces.  The supported
`adr` compatibility path is a symlink to the same artifact.

### Compute build metadata at runtime

Runtime Git/clock queries make output environment-dependent and fail in installed
contexts without repository metadata.

### Validate only source files

The assembly step, embedded dependency, metadata injection, permissions, and
entrypoint behavior can all fail even when individual source modules are valid.
The consumer artifact must be tested directly.

## Consequences

Contributors can work in readable modules while users receive one portable Bash
executable.

Release provenance refers to the exact bytes users download.

The `mktext` integration and `adr` symlink behavior become observable release
properties rather than source-level assumptions.

## Related Decisions

- Related to: ADR-002
- Related to: ADR-003
- Related to: ADR-006
- Related to: ADR-008
- Related to: ADR-013
- Adapted from Bootstrap ADR-009, ADR-010, ADR-011, ADR-012, ADR-029, ADR-031,
  ADR-039, and ADR-040.
- Adapted from `mktext` ADR-008 and ADR-009.
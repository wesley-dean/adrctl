# ADR-003: Pin, Verify, and Embed mktext as a Build Dependency

Date: 2026-08-15

## Status

Proposed

## Intent and Documentation Posture

This ADR defines how `adrctl` consumes `mktext` while preserving the project's
single-file distribution model, deterministic build expectations, and clear
process-entrypoint ownership.

`mktext` is a separate project with its own public API and release lifecycle.
`adrctl` should consume that API rather than copy or fork its implementation, but
users of the final `adrctl` executable should not need to install `mktext`
separately or permit runtime network access.

## Context

`adrctl` uses `mktext` as the single rendering implementation selected by
ADR-001.  The `mktext` project publishes one sourceable and executable Bash
artifact named `mktext.bash`.

The Bootstrap reference build creates its distribution artifact by concatenating
maintained Bash modules in an explicit order.  `adrctl` intends to retain that
single-file model.

An executable-and-sourceable dependency introduces a composition concern.  A
traditional Bash direct-execution guard such as:

```bash
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  ...
fi
```

becomes true when the guarded source is physically concatenated into another
executed Bash file.  Without an additional ownership check, embedded `mktext`
could therefore consume `adrctl` arguments and exit before the `adrctl`
entrypoint runs.

`mktext` issue #7 addressed this use case.  Beginning with release `v0.0.6`, the
`mktext` direct-execution guard also requires the invocation basename to be an
explicitly supported `mktext` executable name.  The embedded code is therefore
inert when the generated executable is invoked as `adrctl` or through the `adr`
compatibility symlink defined by ADR-002.

The published `v0.0.6` release artifact is:

```text
Artifact: mktext.bash
SHA-256: 03d8b99188251ffeca394cd5737e8876813190d14d671109f2fbe236f4b13c01
```

## Decision Drivers

- Use the documented `mktext` API rather than maintaining a second renderer.
- Preserve one generated `adrctl` executable as the consumer-facing runtime
  artifact.
- Require no separately installed `mktext` runtime dependency.
- Require no runtime network access for rendering.
- Make the exact third-party build input reviewable and reproducible.
- Detect dependency tampering, accidental replacement, or upstream asset drift
  before incorporation into the product artifact.
- Preserve one effective product entrypoint owned by `adrctl`.
- Avoid build-time textual surgery that depends on private `mktext` source
  layout.
- Test the exact assembled executable users receive.

## Decision

`adrctl` SHALL consume `mktext` as a pinned build dependency.

The initial pinned dependency SHALL be:

```text
mktext release: v0.0.6
release asset:  mktext.bash
SHA-256:        03d8b99188251ffeca394cd5737e8876813190d14d671109f2fbe236f4b13c01
```

The build SHALL acquire or use that exact artifact and SHALL verify its SHA-256
digest before incorporating it into the generated `adrctl` executable.

A missing dependency MAY cause the build to acquire the pinned artifact from its
documented upstream release location.  Dependency acquisition is a build-time
operation.  The generated `adrctl` executable SHALL NOT download, locate, or
source `mktext` at runtime.

A digest mismatch SHALL fail the build before the dependency is incorporated.
The build SHALL NOT silently accept a different artifact merely because it is
published under the expected filename or release tag.

The verified `mktext.bash` artifact SHALL be incorporated unchanged into the
generated `adrctl` executable.  The `adrctl` build SHALL NOT use `sed`, `awk`,
line-number slicing, regular-expression deletion, or another textual rewrite to
remove or modify the `mktext` direct-execution guard.

The generated executable SHALL contain one effective product entrypoint owned by
`adrctl`.  The embedded `mktext` direct-execution guard is expected to remain
inert because `adrctl` is invoked with the basename `adrctl` or, under ADR-002,
`adr`.  Invocation of the final product SHALL NOT cause the embedded dependency
to dispatch process arguments independently.

The maintained `adrctl` source list and build order SHALL be explicit and
deterministic.  The generated artifact SHALL place embedded dependency code
before the final `adrctl` process-dispatch entrypoint so all required rendering
functions are defined before they are called.

The exact generated artifact SHALL be tested for at least:

- direct invocation as `adrctl`;
- invocation through an `adr` symbolic link;
- successful use of `mktext` rendering through `adrctl`;
- absence of premature `mktext` process dispatch;
- expected help, version, and subcommand dispatch after embedding; and
- syntax validity under the minimum supported Bash version.

A future `mktext` upgrade SHALL be deliberate.  The dependency version and
expected digest SHALL be updated together, the upstream behavioral contract
SHALL be reviewed for relevant changes, and the complete `adrctl` compatibility
and generated-artifact test suites SHALL run against the candidate upgrade.

The dependency SHALL NOT track a moving branch such as `mktext/main` in
production builds.

## Considered Alternatives

### Require mktext as a separately installed runtime dependency

`adrctl` could invoke or source a system-installed `mktext`.  This was rejected
because it would make runtime behavior depend on installation state and version
selection outside the `adrctl` artifact, weaken reproducibility, and complicate
support for the single-file distribution goal.

### Vendor an independently maintained fork of mktext

Copying the renderer into `adrctl` and maintaining it there would avoid build-time
acquisition.  This was rejected because it would split ownership of the rendering
implementation, create update drift, and weaken the deliberate caller/renderer
boundary.

### Strip the mktext executable guard during the adrctl build

The assembler could remove the final guard with text processing before
concatenation.  This was rejected because it would couple `adrctl` to private
source layout and silently transform a verified upstream artifact.  Harmless
upstream formatting or documentation changes could then break the build logic.

### Publish or consume a second library-only mktext artifact

`mktext` could maintain separate executable and embedding artifacts.  This would
work, but the basename-aware execution guard introduced for `v0.0.6` makes the
additional artifact unnecessary.  One upstream artifact can remain both
sourceable/executable on its own and inert when embedded under another product
name.

### Consume mktext from its moving main branch

This would simplify acquisition but would make `adrctl` builds depend on mutable
upstream state and could change behavior without an `adrctl` source change.  A
versioned artifact plus digest provides a stronger review and reproducibility
boundary.

## Consequences

`adrctl` gains deterministic access to the `mktext` capabilities required by
ADR-001 without adding a runtime dependency.

The generated executable remains one portable Bash artifact and can continue to
support the `adr` symlink compatibility contract in ADR-002.

Local or CI builds may require network access when the pinned dependency is not
already available.  Once acquired, its digest provides an explicit integrity
check before use.

Upgrading `mktext` becomes a visible dependency-maintenance event rather than an
implicit consequence of upstream branch movement.

The build and tests must treat the embedded third-party artifact as part of the
actual consumer executable and verify its composition behavior, not merely test
`mktext` and `adrctl` separately.

## Open Questions and Follow-Ups

The Make/build implementation must choose the local cache or vendor path used for
the verified `mktext.bash` artifact and define the corresponding clean/distclean
behavior.  That path is an implementation detail provided it does not become a
runtime dependency or a second source of truth.

Release documentation should identify the pinned `mktext` version used to build a
given `adrctl` release when doing so materially aids provenance and debugging.

## Related Decisions

- Related to: ADR-001
- Related to: ADR-002
- Related to: Bootstrap ADR-009, ADR-010, ADR-029, and ADR-042.
- Related to: mktext ADR-001, ADR-008, and ADR-009.
- Upstream integration evidence: `doc/mktext-delimiter-integration.md`.

# ADR-024: Standardize SHA-256 Checksum Companion Filenames

Date: 2026-08-27

## Status

Accepted

## Intent and Documentation Posture

This ADR standardizes the filename suffix used for SHA-256 checksum companions
published with adrctl release artifacts and defines the compatibility rule for
consumers that retrieve checksum companions across historical releases.

The change is deliberately narrow.  It changes release-sidecar names from `.256`
to `.sha256`; it does not change the SHA-256 algorithm, checksum-file contents,
the three-flavor release model, artifact provenance, dependency synchronization,
or adrctl runtime behavior.

This decision supersedes only the checksum-filename portions of ADR-022.  ADR-022
remains authoritative for the development, standard, and minified executable
flavors, the six-artifact release model, Bash-Minifier integration, and the
network-free `make build` boundary.

ADR-019 originally selected `adrctl.bash.sha256` for the standard artifact before
ADR-022 replaced that suffix with `.256`.  This decision restores the
self-describing `.sha256` convention and extends it consistently to all three
current executable flavors rather than rewriting either historical ADR.

## Context

ADR-022 currently requires one adjacent SHA-256 checksum companion for each
released executable using these filenames:

```text
adrctl.dev.bash.256
adrctl.bash.256
adrctl.min.bash.256
```

The `.256` suffix is technically usable because `sha256sum` and `shasum` do not
require a particular checksum filename extension.  It is not, however,
self-describing: a reader must already know that `256` denotes SHA-256 rather than
a project-specific format or an unrelated file convention.

The `.sha256` suffix identifies the checksum algorithm directly.  Related Bash
projects are standardizing new release companions on the same suffix, so adrctl
can remove an unnecessary naming difference while retaining the existing
one-artifact/one-checksum relationship.

The repository also contains a documented consumer of its own checksum sidecars.
The README Bash-startup helper retrieves the latest `adrctl.bash` release and its
published checksum before replacing a local installation.  That helper must work
with both historical releases that expose `.256` and new releases that expose
`.sha256` without allowing compatibility fallback to conceal a real transport or
verification failure.

A separate trust boundary applies to adrctl's build dependencies.  ADR-021 makes
committed SHA-256 digests authoritative for the Make-owned bashdeps bootstrap and
manifest-managed dependencies.  Live upstream checksum sidecars must not replace
those committed trust data merely because release-sidecar naming is changing.

## Decision Drivers

- Make the checksum algorithm evident from the sidecar filename.
- Use one checksum naming convention across related Bash projects.
- Preserve the existing one-executable/one-checksum release relationship.
- Preserve conventional `sha256sum`/`shasum -a 256` checksum-file contents.
- Preserve the six-file release model established by ADR-022.
- Avoid publishing duplicate checksum companions indefinitely.
- Preserve the ability to verify historical releases that published `.256`.
- Fail closed rather than masking transport, server, or verification failures as
  legacy compatibility.
- Preserve committed digests as the trust authority for external build
  dependencies.
- Keep adrctl runtime behavior unchanged.

## Decision

### Publish `.sha256` companions for new releases

`make build` SHALL produce exactly these checksum companions:

```text
dist/adrctl.dev.bash.sha256
dist/adrctl.bash.sha256
dist/adrctl.min.bash.sha256
```

Together with the existing executable flavors, a successful build continues to
produce six release artifacts:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
dist/adrctl.dev.bash.sha256
dist/adrctl.bash.sha256
dist/adrctl.min.bash.sha256
```

Each `.sha256` file SHALL continue to contain the SHA-256 digest and matching
executable basename in conventional checksum-tool syntax.  For example:

```text
0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef  adrctl.bash
```

The standard artifact SHALL therefore be directly verifiable from the
distribution directory with:

```text
sha256sum -c adrctl.bash.sha256
```

or the supported `shasum` equivalent.

New releases SHALL publish only the `.sha256` checksum companion for each
executable.  They SHALL NOT publish duplicate `.256` companions merely for a
transition period.

A successful build SHALL remove stale `.256` companions for the current three
executable filenames from `dist/` so a working tree that previously built the old
contract does not appear to contain nine current release artifacts.

### Preserve historical releases through read-side compatibility

Existing GitHub releases and their `.256` checksum companions are historical
published artifacts and SHALL NOT be rewritten solely to adopt the new suffix.

A consumer that explicitly retrieves an adrctl checksum companion across both
naming eras SHOULD request `<artifact>.sha256` first.

It MAY retry `<artifact>.256` only when the preferred `.sha256` resource is
confirmed absent.  For HTTP retrieval, a confirmed HTTP 404 is the expected
missing-resource signal.

Legacy fallback SHALL NOT occur for other failures, including:

- DNS, connection, timeout, or other transport failures;
- TLS or certificate failures;
- authentication or authorization failures;
- HTTP server errors such as 5xx responses;
- malformed checksum content; or
- a checksum mismatch.

Those conditions are failures and SHALL remain failures.

The README Bash-startup installation example SHALL follow this rule when fetching
release checksums: prefer `.sha256`, use `.256` only after a confirmed 404 for the
preferred sidecar, and fail closed for other retrieval or verification errors.

### Preserve committed-digest dependency trust

This release-sidecar compatibility rule SHALL NOT add live checksum discovery to
adrctl's build dependency workflow.

The Makefile continues to authorize the released `vendor/bashdeps.bash` bootstrap
with the SHA-256 digest committed in repository source.  `dependencies.txt`
continues to authorize `mktext`, Bash Doxygen, Bash-Minifier, and other ordinary
managed artifacts through committed `digest=sha256:...` values.

Neither Make nor bashdeps SHALL dynamically replace those committed expected
digests with a value retrieved from a `.sha256` or `.256` sidecar as a consequence
of this decision.

A maintainer or external helper may consult a published checksum companion while
reviewing an update, but committing the selected digest remains the explicit
repository authorization step.

### Preserve release provenance and validation

Release automation SHALL verify all three `.sha256` files before publication.

The release workflow SHALL publish and attest the same six logical outputs
established by ADR-022, using `.sha256` for the three checksum filenames.

Generated-artifact tests SHALL verify that each checksum matches its adjacent
executable and that current builds do not leave legacy `.256` companions behind.

## Considered Alternatives

### Keep `.256`

This would preserve the ADR-022 naming decision and require no migration.  It was
rejected because the suffix does not identify the checksum algorithm clearly and
creates avoidable inconsistency with related release tooling.

### Publish both `.sha256` and `.256`

Publishing both would preserve compatibility for consumers that hard-code `.256`
without any read-side logic.  It was rejected because the two files would carry
the same information, expand the six-file release surface, and make the deprecated
name appear equally current.

Absence-only read-side fallback preserves historical compatibility without
requiring duplicate write-side artifacts.

### Fall back to `.256` after any `.sha256` retrieval failure

This would be easy to implement with a generic `curl` failure branch.  It was
rejected because a timeout, TLS failure, authorization error, or server failure is
not evidence that the preferred asset is absent.  Treating those failures as a
reason to fetch a different resource could conceal a real problem and violates the
project's fail-closed posture.

### Replace per-artifact companions with `SHA256SUMS`

An aggregate checksum file is common and compact, but ADR-022 deliberately defines
one checksum companion per executable artifact.  This decision changes only the
filename suffix and does not revisit that release relationship.

### Dynamically trust published sidecars for build dependencies

The Make bootstrap or dependency workflow could fetch a live checksum companion
and use it instead of a committed expected digest.  This was rejected because it
would move authorization from reviewed repository source to mutable remote state
and contradict ADR-021's trust boundary.

## Consequences

New adrctl releases expose self-describing `.sha256` checksum filenames while
retaining the same SHA-256 algorithm, checksum contents, executable flavors,
artifact count, and provenance model.

Developers rebuilding in a working tree that contains old `.256` outputs do not
retain those obsolete companions after a successful build.

Documentation and release automation must use `.sha256` for current release
artifacts.

Consumers that fetch adrctl release sidecars can continue verifying historical
`.256` releases through a narrow, absence-only fallback.

The build dependency model does not change.  Existing committed version, URL, and
digest pins remain authoritative and need no update solely because of the release
checksum filename migration.

## Superseded Decisions

This ADR supersedes ADR-022 only where ADR-022:

- names `.256` as the checksum suffix;
- requires `.256` files in build validation and release publication;
- states that `.256` supersedes `.sha256`; and
- rejects retaining `.sha256` for the release checksum suffix.

All other ADR-022 decisions remain in force.

ADR-019's original `adrctl.bash.sha256` checksum filename is consistent with this
decision, but ADR-024 is the current authority because the release model now
contains three executable flavors rather than the single artifact described by
ADR-019.

ADR-021 remains fully in force for dependency acquisition, committed-digest trust,
and the network-free `make build` boundary.

## Related Decisions

- Related to: ADR-019
- Related to: ADR-021
- Supersedes checksum-filename portions of: ADR-022

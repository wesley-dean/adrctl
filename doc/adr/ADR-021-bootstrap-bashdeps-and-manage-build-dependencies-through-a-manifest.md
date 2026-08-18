# ADR-021: Bootstrap bashdeps and Manage Build Dependencies Through a Manifest

Date: 2026-08-17

## Status

Proposed

## Context

`adrctl` currently has two separate Makefile acquisition paths for external build
inputs.

The build pins, downloads, and verifies `mktext` directly before embedding it into
the generated `adrctl.bash` artifact.  Reference-documentation generation
separately downloads the Bash Doxygen filter from the upstream `main` branch.

The direct `mktext` path was strengthened after a stale vendor artifact exposed an
important failure mode: the expected dependency version could change while bytes
from an older version remained at a locally accepted path.  ADR-003 therefore
requires exact byte verification before `mktext` is incorporated into the
consumer artifact.

The separate `bashdeps` project now provides the reusable artifact-acquisition
mechanism that grew from that lesson.  It reads a committed `dependencies.txt`,
validates exact artifact declarations, reuses correct local bytes, downloads
missing or mismatched artifacts, verifies committed SHA-256 digests, and publishes
verified bytes under declared repository-relative destinations.

Using bashdeps introduces one unavoidable bootstrap boundary: bashdeps cannot read
a manifest to obtain the first copy of itself.  The consuming Makefile therefore
still needs one small direct download-and-verification path.

The desired adrctl developer workflow is:

```text
make all
  -> bootstrap and verify vendor/bashdeps.bash
  -> vendor/bashdeps.bash sync dependencies.txt
       -> vendor/mktext.bash
       -> vendor/doxygen-bash.awk
  -> make build
       -> dist/adrctl.bash
```

This keeps the bootstrap mechanism explicit while moving ordinary project
dependency declarations out of Make.

## Decision Drivers

- Keep one explicit, auditable bootstrap trust boundary.
- Centralize ordinary external artifact acquisition and SHA-256 verification in
  bashdeps rather than duplicating the mechanism in adrctl's Makefile.
- Preserve ADR-003's requirement that the exact reviewed mktext bytes are embedded
  unchanged into the generated executable.
- Replace the mutable Bash Doxygen `main` URL with a release-pinned declaration.
- Make fresh-checkout development convenient through `make all`.
- Keep ordinary `make build` fast, deterministic with respect to local inputs,
  network-free, and dependency-management-free.
- Provide an explicit offline integrity check for already-materialized
  dependencies.
- Keep `vendor/` generated, ignored, and reconstructable.
- Preserve the runtime property that the final `adrctl.bash` artifact has no
  dependency on bashdeps, mktext files beside it, or network access.

## Decision

### Bootstrap bashdeps directly from Make

The Makefile SHALL directly manage exactly one external acquisition dependency:

```text
vendor/bashdeps.bash
```

The bootstrap artifact SHALL NOT appear in `dependencies.txt`.

The Makefile SHALL pin the exact bashdeps release URL and expected SHA-256 digest.
At the time of this decision, the selected bootstrap is:

```text
bashdeps release: v0.0.6
release asset:    bashdeps.bash
SHA-256:          bb6c807fa12c010950bda06172ac0611d278c57aca1f8352f41502d0d76b4e6c
```

The bootstrap target SHALL use `curl` to acquire the release artifact when the
local file is missing or does not match the committed digest.

The bootstrap target SHALL:

1. verify an existing `vendor/bashdeps.bash` before reuse;
2. avoid network access when the existing bytes already match;
3. otherwise download to a temporary path;
4. verify the temporary candidate against the committed SHA-256 digest;
5. make the verified executable mode `0755`; and
6. replace the bootstrap destination only after verification succeeds.

A failed download or digest mismatch SHALL leave any previously installed
bootstrap artifact untouched until a verified replacement is available.

The committed Makefile digest is the adrctl repository's trust datum.  The build
SHALL NOT dynamically trust a remotely retrieved checksum file as a replacement
for that committed value.

### Declare ordinary dependencies in dependencies.txt

The repository SHALL contain a root-level:

```text
dependencies.txt
```

The manifest SHALL declare ordinary external artifacts consumed by adrctl's build
and documentation workflows.

The initial records SHALL materialize:

```text
vendor/mktext.bash
vendor/doxygen-bash.awk
```

At the time of this decision, the reviewed declarations are:

```text
mktext        v0.0.9  vendor/mktext.bash
bash-doxygen  v0.0.6  vendor/doxygen-bash.awk
```

The exact URLs and digests in `dependencies.txt` are authoritative.

The mktext record SHALL use the immutable v0.0.9 release asset and SHA-256:

```text
b25cc84f733ccb8368f6cba98578ea7e266638cb61e794fc0028f16266cd336a
```

The bash-doxygen v0.0.6 release does not attach the AWK filter as a release asset.
The manifest SHALL therefore use the immutable raw file at tag `v0.0.6`, with
SHA-256:

```text
dc09bccac7cdb69940b2b34f0c2a92d862c5979d578364ec66782ac92338a3ea
```

Dependency upgrades SHALL update identity, URL, and digest together as one
reviewed change.

The manifest SHALL remain compatible with the released bashdeps bootstrap selected
by the Makefile.  It SHALL NOT depend on manifest syntax that exists only on an
unreleased bashdeps branch.

### make deps

The repository SHALL provide:

```text
make deps
```

`deps` SHALL:

1. bootstrap or repair `vendor/bashdeps.bash` when necessary;
2. verify the pinned bootstrap immediately before use; and
3. invoke:

```text
vendor/bashdeps.bash sync dependencies.txt
```

`make deps` MAY use the network and MAY mutate manifest-declared destinations.
When all declared local bytes already match their committed digests, bashdeps
SHOULD reuse them without downloading replacements.

### make deps-check

The repository SHALL provide:

```text
make deps-check
```

`deps-check` SHALL be network-free and SHALL NOT bootstrap, repair, or download
anything.

It SHALL require an already-present executable `vendor/bashdeps.bash`, verify that
bootstrap against the committed Makefile digest, and then invoke:

```text
vendor/bashdeps.bash verify dependencies.txt
```

A missing or invalid bootstrap SHALL make `deps-check` fail rather than trigger
repair.

### Keep build independent from dependency synchronization

`make build` SHALL NOT invoke `make deps`, `bashdeps sync`, `bashdeps verify`, or a
dependency download.

The build SHALL consume the current local:

```text
vendor/mktext.bash
```

and SHALL fail with a useful diagnostic when that required build input is absent.

This intentionally supersedes the portion of ADR-003 that allowed a missing
mktext artifact to be acquired as an implicit consequence of `make build`.

ADR-003's byte-identity and embedding requirements remain in force: dependency
synchronization establishes the trusted local bytes, and the build embeds the
materialized `mktext.bash` unchanged.

A caller that wants an explicit offline verification immediately before building
may run:

```text
make deps-check build
```

### make all prepares dependencies and builds

`make all` SHALL be the convenient fresh-checkout path.

It SHALL explicitly sequence:

```text
make deps
make build
```

The sequence SHALL be represented in a way that remains ordered under parallel
Make execution.  `all: deps build` alone is insufficient because independent
prerequisites may execute concurrently.

Repeated use of plain `make build` after dependency preparation SHALL not re-hash
the complete dependency manifest merely because another build was requested.

### Documentation uses manifest-managed bash-doxygen

The Makefile SHALL remove the direct Bash Doxygen URL/download target.

`make docs` SHALL ensure manifest dependencies are synchronized before Doxygen is
invoked, because the filter is now materialized by bashdeps at:

```text
vendor/doxygen-bash.awk
```

Bashdeps deliberately materializes ordinary dependencies as data and does not
infer executable intent.  The consuming docs target therefore owns any executable
mode required by the Doxygen filter and SHALL apply that mode immediately before
use.

Generated `doc/reference/` output remains governed by ADR-020 and stays ignored by
Git.

### CI and release workflows make acquisition explicit

CI and release workflows SHALL prepare dependencies explicitly before targets that
consume them.

The normal pattern SHALL be conceptually:

```text
make deps
make deps-check
make check
make build
make test
```

or a composed equivalent when a job intentionally exercises `make all`.

Release workflows SHALL synchronize and verify dependencies before building the
release artifact.  Release acceptance continues to concern the exact generated
`dist/adrctl.bash` bytes.

### Runtime remains self-contained

`bashdeps.bash`, `dependencies.txt`, `vendor/mktext.bash`, and
`vendor/doxygen-bash.awk` are build/development inputs only.

The released `dist/adrctl.bash` SHALL continue to embed mktext unchanged and SHALL
require none of those files at runtime.

## Considered Alternatives

### Continue downloading mktext directly from Make

This preserves the existing implementation but repeats the exact artifact
acquisition and verification responsibility that bashdeps now centralizes.
It also keeps dependency identity split between Make variables and other project
documentation.  This option is rejected.

### Continue downloading bash-doxygen directly from Make

The existing Doxygen rule is small, but it uses a mutable `main` URL and creates a
second acquisition mechanism outside the dependency manifest.  This option is
rejected.

### Put bashdeps itself in dependencies.txt

This creates a bootstrap cycle: bashdeps would be required to read the manifest
entry that obtains bashdeps.  The first copy must therefore remain independently
managed by Make.

### Make build depend on deps

This makes `make build` convenient on a fresh checkout but couples ordinary
artifact generation to dependency hashing, potential network access, and
filesystem mutation.  The project instead gives that behavior the explicit
`make all` entry point.

### Make deps-check repair missing state

Repair would make the target convenient, but it would destroy the useful guarantee
that dependency verification can be run without network access or mutation.
`make deps` is the repair path.

### Embed bashdeps into the adrctl release artifact

Bashdeps is needed only to prepare build inputs.  Embedding it would enlarge the
runtime artifact and blur a clean build/runtime boundary.  This option is
rejected.

## Consequences

A fresh checkout can run:

```text
make all
```

and obtain the bootstrap tool, synchronize approved project dependencies, and
build the single adrctl artifact.

The Makefile retains one small direct download-and-verification implementation for
bashdeps itself.  Ordinary dependency declarations move into `dependencies.txt`.

`make build` becomes network-free and does no dependency synchronization or
verification.  A build attempted before dependency preparation fails rather than
silently reaching the network.

`make deps-check` provides an explicit offline integrity check.

The mktext upgrade from the previously materialized v0.0.7 build input to v0.0.9
becomes a reviewed manifest change rather than a Makefile implementation detail.

The Doxygen filter becomes release-pinned and digest-verified instead of following
upstream `main`.

The released adrctl executable remains self-contained and has no new runtime
dependency.

## Superseded Decisions

This ADR supersedes ADR-003 only insofar as ADR-003 permits `make build` to acquire
a missing mktext dependency and treats the mktext version/URL/digest as direct
Makefile-owned acquisition data.

ADR-003 remains authoritative for:

- using mktext as adrctl's rendering implementation;
- requiring exact reviewed bytes;
- embedding the verified mktext artifact unchanged;
- keeping mktext inert as an embedded dependency; and
- requiring no runtime mktext installation or network access.

This ADR supersedes the existing Makefile implementation of direct Bash Doxygen
filter acquisition.  ADR-017's documentation-first source policy and ADR-020's
generated-documentation persistence policy remain unchanged.

ADR-015's release requirement to acquire and verify pinned build dependencies
remains in force; this ADR defines bashdeps synchronization as the mechanism that
satisfies that requirement.

## Related Decisions

- Supersedes portions of: ADR-003
- Refines build orchestration from: ADR-015
- Related to: ADR-017
- Related to: ADR-019
- Related to: ADR-020

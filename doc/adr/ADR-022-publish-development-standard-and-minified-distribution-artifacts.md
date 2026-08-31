# ADR-022: Publish Development, Standard, and Minified Distribution Artifacts

Date: 2026-08-18

## Status

Accepted

## Intent and Documentation Posture

This ADR defines adrctl's three generated executable flavors, the build-time
Bash-Minifier dependency, the checksum publication contract, and the dependency
boundary required to produce all supported release artifacts.

## Context

ADR-019 established `dist/adrctl.bash` as the canonical generated distribution
artifact and GitHub Release executable.  ADR-021 later separated external
dependency synchronization from ordinary artifact assembly so `make build`
remains network-free and consumes only already-prepared local inputs.

The established `adrctl.bash` build removes full-line comments before release.
Consumers now benefit from three deliberately different representations of the
same implementation:

- a development artifact that preserves comments from the assembled package;
- the established readable comment-stripped artifact; and
- a compact artifact produced by Bash-Minifier from the stripped artifact.

The assembled adrctl package includes maintained adrctl modules, the adrctl
entrypoint, and embedded library/dependency code such as `mktext.bash`.  The
comment-stripping boundary applies to those assembled library inputs as well as to
adrctl-owned modules.  Generated artifact-identification comments emitted by Make
remain present in the readable standard artifact as build provenance.

Love Borgstrom's Bash-Minifier project provides a state-aware Bash minifier under
the MIT License.  adrctl can consume a commit-pinned copy of the upstream
`Minify.sh` artifact as a build dependency without embedding Bash-Minifier itself
in the runtime product.

The selected output set is:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
dist/adrctl.dev.bash.256
dist/adrctl.bash.256
dist/adrctl.min.bash.256
```

The three executable artifacts represent one adrctl product and must preserve the
same public behavior.

## Decision Drivers

- Preserve an inspectable artifact containing the complete assembled package before
  comment stripping.
- Preserve `adrctl.bash` as the standard, readable consumer filename.
- Remove full-line comments from all assembled library/source inputs in the
  standard flavor.
- Offer a smaller minified form without maintaining a second implementation.
- Treat minification as an explicit, reproducible transformation of the standard
  artifact.
- Keep `make build` network-free under ADR-021.
- Pin and verify Bash-Minifier through the existing bashdeps manifest rather than
  adding another direct Makefile download path.
- Validate every released executable flavor with the same behavioral and
  minimum-Bash tests.
- Publish one SHA-256 checksum file for every executable release asset.
- Preserve executable mode consistently across all three flavors.

## Decision

### Publish three executable flavors

`make build` SHALL produce these executable Bash artifacts:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
```

`dist/adrctl.bash` remains the default and recommended general-purpose release
artifact.  The `.dev.bash` and `.min.bash` suffixes describe representations and
SHALL NOT create separate product identities.

All three executable artifacts SHALL:

- begin with a valid Bash shebang;
- be executable with mode `0755`;
- contain the same adrctl version, build date, and build commit metadata;
- expose the same command surface, configuration behavior, filesystem behavior,
  standard streams, and exit-status contract;
- remain self-contained at runtime; and
- satisfy the Bash 4.3 minimum-runtime contract.

Direct execution of any of the three distribution filenames SHALL normalize
human-facing presentation to the canonical product identity `adrctl`.  The
existing `adr` compatibility symlink behavior remains unchanged.

### Define the development flavor

`dist/adrctl.dev.bash` SHALL represent the complete assembled package before
comment stripping or minification.

It SHALL contain:

- the generated adrctl shebang and build metadata;
- maintained adrctl library modules with their source comments and
  Doxygen-compatible documentation;
- the manifest-managed embedded `mktext.bash` bytes as materialized; and
- the adrctl entrypoint with its maintained source comments.

The development artifact SHALL NOT attempt to reconstruct comments that an
external dependency's own release process removed before adrctl received those
bytes.  It preserves the actual dependency artifact supplied to adrctl.

Generated artifact-identification comments emitted by Make remain present.

### Define the standard flavor

`dist/adrctl.bash` SHALL remain the readable standard distribution artifact.

The standard artifact SHALL be assembled from the same ordered implementation and
library inputs as the development artifact while removing full-line comments from
those inputs.  This includes comments present in:

- adrctl library modules;
- the adrctl entrypoint; and
- embedded library/dependency artifacts such as `vendor/mktext.bash`.

The stripping operation SHALL preserve executable Bash behavior and SHALL NOT
remove non-comment lines merely because they contain `#` characters as data or
syntax.

Generated artifact-identification comments emitted directly by Make MAY remain in
`adrctl.bash` as build provenance.  The stripping contract concerns comments from
the assembled implementation/library inputs.

Because embedded library comments are removed, `adrctl.bash` no longer promises
byte-for-byte identity with the complete `vendor/mktext.bash` artifact.  The
executable implementation remains derived from the verified dependency bytes with
full-line comment records removed.

### Define the minified flavor

`dist/adrctl.min.bash` SHALL be produced by applying the pinned Bash-Minifier build
tool to the completed `dist/adrctl.bash` artifact.

The transformation chain is therefore:

```text
maintained source + embedded library/dependency inputs
  -> adrctl.dev.bash
  -> remove full-line comments from assembled inputs
  -> adrctl.bash
  -> Bash-Minifier
  -> adrctl.min.bash
```

The implementation MAY assemble the development and standard flavors separately
from the same ordered inputs rather than textually deriving one file from the
other when that keeps generated headers and metadata clearer.  The observable
representation contract remains the same.

Bash-Minifier SHALL be invoked noninteractively.  The build SHALL fail if
minification fails, if the minified result is missing, or if Bash syntax
validation of the minified result fails.

Whole-file minification transforms adrctl code and embedded library code together.
The minified artifact therefore does not preserve byte identity with either the
standard artifact or the original embedded dependency artifacts.  Its release
acceptance depends on the verified standard input, the pinned Bash-Minifier bytes,
and direct syntax/behavior validation of the exact minified output.

### Preserve semantics when accommodating minifier limitations

Bash-Minifier is a build transformation tool rather than the authoritative Bash
parser for adrctl source design.  If a valid Bash construct is not preserved
correctly by the pinned minifier, adrctl MAY express the same behavior using an
alternative Bash form that the minifier handles correctly.

Such a change SHALL:

- preserve the documented adrctl behavior;
- remain valid and readable maintained Bash source;
- avoid patching or mutating the pinned Bash-Minifier dependency locally; and
- be covered by the same source/generated-artifact validation used for other
  behavior-sensitive changes.

This allowance exists only to preserve release-equivalent semantics across the
three required representations.  It does not justify unrelated source rewrites.

### Manage Bash-Minifier through dependencies.txt

Bash-Minifier SHALL be an ordinary manifest-managed build dependency under
ADR-021.  The Makefile SHALL NOT download it directly.

The manifest SHALL materialize the selected upstream `Minify.sh` bytes as:

```text
vendor/bash-minifier.bash
```

The initial selected upstream identity is:

```text
Repository: Zuzzuc/Bash-minifier
Commit:     9c824e20815a5bca2153ec25ecc02a4edea1430e
Source:     Minify.sh
SHA-256:    93cb422360db4cc410d19b068eb074da020a4a743f0eebc9c442d1e5acd90e9b
```

The dependency URL SHALL identify that immutable commit rather than the moving
`master` branch.

The destination filename is an adrctl-local descriptive name and does not assert
that upstream publishes an artifact named `bash-minifier.bash`.

The build MAY invoke the manifest-managed file explicitly with Bash instead of
changing its executable mode.

### Keep make build network-free

ADR-021 remains authoritative for dependency acquisition.

`make build` SHALL NOT download, synchronize, verify, or repair Bash-Minifier or
other external dependencies.  It SHALL require the prepared local build inputs it
needs, including:

```text
vendor/mktext.bash
vendor/bash-minifier.bash
```

and fail with a useful diagnostic when required prepared state is absent.

A fresh checkout that needs release artifacts SHALL use:

```text
make all
```

or explicitly:

```text
make deps build
```

`make deps` remains the network-permitted synchronization surface, and
`make deps-check` remains the network-free integrity-verification surface.

### Publish one checksum per executable artifact

`make build` SHALL also produce:

```text
dist/adrctl.dev.bash.256
dist/adrctl.bash.256
dist/adrctl.min.bash.256
```

Each `.256` file SHALL contain the SHA-256 checksum of its corresponding artifact
in conventional `sha256sum`/`shasum -a 256` check-file form, naming only the
artifact basename so verification works from within `dist/`.

The build SHALL fail when neither supported SHA-256 command is available.

The `.256` suffix supersedes the prior `.sha256` release-checksum filename.

`make checksums` MAY remain as a compatibility/convenience target, but all six
selected build outputs SHALL already exist after successful `make build`.

### Validate every executable flavor

The generated-artifact behavior suite SHALL execute against all three executable
artifacts.

Validation SHALL establish that:

- all three artifacts are executable;
- all three pass Bash syntax validation;
- all three expose the same public adrctl behavior;
- all three report the same version/provenance metadata;
- direct execution of each flavor presents canonical `adrctl` identity;
- each flavor satisfies the Bash 4.3 compatibility harness;
- the development flavor retains representative comments from maintained source
  and assembled library inputs;
- the standard flavor removes representative full-line comments from maintained
  source and assembled library inputs;
- the minified flavor is the deterministic Bash-Minifier transform of the standard
  flavor and remains behaviorally valid; and
- every `.256` file verifies the exact adjacent executable bytes.

Tests that exercise dependency synchronization, cleanup, or other build machinery
need not duplicate the same infrastructure case for each executable flavor.  The
consumer behavior suite SHALL cover every released executable representation.

### Publish all six files in GitHub Releases

Release automation SHALL publish and attest all six build outputs:

```text
adrctl.dev.bash
adrctl.bash
adrctl.min.bash
adrctl.dev.bash.256
adrctl.bash.256
adrctl.min.bash.256
```

Release acceptance SHALL validate the exact bytes that will be uploaded.

The release workflow SHALL verify all three checksum files before publication.

### Preserve product identity

The canonical product identity remains:

```text
adrctl
```

The historical compatibility invocation remains:

```text
adr
```

Documentation SHOULD describe `adrctl.bash` as the default/recommended release
artifact, `adrctl.dev.bash` as the inspection/debugging flavor, and
`adrctl.min.bash` as the compact flavor.

## Superseded Portions of Earlier Decisions

This ADR supersedes ADR-003 where ADR-003 requires the embedded mktext release
artifact to remain textually unchanged in every final generated executable.
`adrctl.dev.bash` remains the exact-byte embedding surface for the prepared
`vendor/mktext.bash` dependency.  `adrctl.bash` intentionally removes full-line
comments from the embedded library representation, and `adrctl.min.bash`
transforms the complete standard artifact further.  ADR-003 requirements
concerning dependency pinning, digest verification, renderer responsibility, and
runtime self-containment remain in force.

This ADR supersedes ADR-019 where ADR-019 requires GitHub Releases to publish only
one canonical executable and names `adrctl.bash.sha256` as the sole checksum
artifact.  ADR-019 remains authoritative for canonical product identity,
`adrctl.bash` as the conventional filename, alias/symlink behavior, and the
absence of a separately maintained `adr` executable.

This ADR supersedes ADR-015 only where its single-distribution-artifact language
would prohibit multiple generated representations of the same implementation.
The maintained-source and self-contained-runtime decisions remain unchanged.

ADR-021 remains authoritative for dependency synchronization and the network-free
`make build` boundary.  Bash-Minifier is added to the set of ordinary
manifest-managed build/development dependencies.

## Considered Alternatives

### Publish only the minified artifact

This would discard the readable and development-oriented representations that
support debugging, inspection, and downstream review.  It is rejected.

### Replace adrctl.bash with the minified bytes

This would silently change the established default artifact from readable Bash to
the least-readable representation.  `adrctl.bash` remains the conventional
stripped form while minification is an explicit opt-in filename.

### Strip comments only from adrctl-owned modules

The package includes embedded library code.  Leaving library comments in the
standard artifact would make the stripping contract depend on source ownership
rather than the representation consumers receive.  Full-line comments from
assembled library inputs are therefore stripped as well.

### Preserve exact embedded mktext bytes in adrctl.bash

This would conflict with the whole-package comment-stripping rule when the
verified library artifact contains comments.  Exact dependency bytes remain
available in `adrctl.dev.bash`; the standard and minified representations are
intentional transformations.

### Minify maintained source directly

This could diverge from the exact standard artifact consumers use.  Minifying
`adrctl.bash` establishes an explicit pipeline and keeps the minified form
downstream of the comment-stripping boundary.

### Patch Bash-Minifier locally

A project-local patch would create an untracked derivative of the pinned upstream
build dependency and weaken the manifest's byte-identity contract.  When a valid
adrctl Bash expression can be written equivalently in a form the pinned minifier
supports, the maintained adrctl source may use that equivalent expression instead.
An upstream minifier update remains a separate reviewed dependency change.

### Download Bash-Minifier directly from Make

ADR-021 intentionally centralizes ordinary external artifacts in
`dependencies.txt`.  A second direct Makefile download path would duplicate
acquisition and digest-verification policy and is rejected.

### Track Bash-Minifier from the moving master branch

A moving URL would allow upstream bytes to change without a corresponding adrctl
review.  The dependency is therefore commit-pinned and digest-pinned.

### Test only adrctl.bash and assume the variants are equivalent

The development and minified files are independently transformed build outputs.
A syntax or semantic defect can be introduced by assembly or minification even
when the standard artifact passes.  All released executable flavors therefore
require direct consumer validation.

### Keep the .sha256 checksum suffix

The selected release contract uses `.256` adjacent to each executable artifact.
Keeping `.sha256` would create additional release files beyond the six selected
outputs and is rejected for this distribution model.

## Consequences

A prepared checkout can run:

```text
make build
```

and receive three executable distribution flavors plus their three adjacent
SHA-256 check files.

A fresh checkout uses `make all` or `make deps build` because Bash-Minifier and
mktext remain external prepared build inputs.

The build remains network-free but now performs a minification pass, syntax
validation for all three generated executables, and three checksum calculations.

The development flavor preserves the prepared embedded library bytes.  The
standard flavor intentionally strips full-line comments from the whole assembled
implementation/library set, and the minified flavor transforms that standard
representation further.

The test matrix is larger because public behavior and minimum-Bash compatibility
must be exercised against three distributed representations.

Release workflows publish six files instead of two and attest each published
artifact.

Consumers gain explicit choices among inspectability, readability, and compact
size without gaining multiple implementations or divergent product behavior.

## Related Decisions

- Supersedes in part: ADR-003
- Supersedes in part: ADR-015
- Supersedes in part: ADR-019
- Related to: ADR-021

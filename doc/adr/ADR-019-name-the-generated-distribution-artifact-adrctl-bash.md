# ADR-019: Name the Generated Distribution Artifact adrctl.bash

Date: 2026-08-15

## Status

Accepted

## Context

ADR-002 established `adrctl` as the canonical product and command identity, with
`adr` supported as a symbolic-link compatibility invocation.  ADR-015 established
the generated single-file distribution model and initially named the generated
consumer artifact `dist/adrctl`.

During implementation review, the maintainer corrected the intended generated
artifact filename.  The completely assembled Bash program belongs under `dist/`
with an explicit `.bash` suffix:

```text
dist/adrctl.bash
```

The maintainer also requires ordinary shell aliases such as:

```bash
alias adr=~/.local/bin/adrctl.bash
```

to invoke the same tool successfully.

This correction changes the distribution filename and release asset name.  It
does not rename the product, create a new runtime mode, or weaken the existing
`adr` compatibility path.

Because ADR-002 and ADR-015 are already Accepted historical decisions, this ADR
records the correction explicitly rather than rewriting those records as though
the earlier filename had never been selected.

## Decision

The canonical generated consumer artifact SHALL be:

```text
dist/adrctl.bash
```

The canonical SHA-256 checksum artifact SHALL therefore be:

```text
dist/adrctl.bash.sha256
```

GitHub Releases SHALL publish `adrctl.bash` and its corresponding checksum and
provenance material.  The build and release workflows SHALL NOT publish
`dist/adrctl` as the canonical generated artifact.

The canonical product and installed command identity remains:

```text
adrctl
```

The historical compatibility invocation remains:

```text
adr
```

The `.bash` suffix identifies the generated distribution file.  It SHALL NOT
create a third product identity or compatibility mode.

Direct execution of `dist/adrctl.bash` SHALL be supported.  Human-facing help and
diagnostic presentation for direct `adrctl.bash` execution SHALL normalize the
invocation name to `adrctl`, so the distribution filename does not leak into the
canonical command grammar.

When the artifact is installed or linked as `adrctl`, help and diagnostics SHALL
use `adrctl`.  When it is reached through a filesystem symbolic link named `adr`,
help and diagnostics SHOULD continue to use `adr` as defined by ADR-002.

A shell alias that expands `adr` directly to the `adrctl.bash` path SHALL be a
supported way to invoke the command.  Such alias invocation SHALL have the same
command semantics, configuration, filesystem effects, output results, and exit
statuses as direct `adrctl.bash` execution.

Bash alias expansion does not preserve the alias token as the executed script's
`$0`.  Therefore a plain alias such as `alias adr=~/.local/bin/adrctl.bash` cannot
be detected reliably by the artifact.  Help and diagnostic presentation through
that alias SHALL use canonical `adrctl` presentation rather than claiming that the
process was invoked through a detectable `adr` basename.

Version and provenance output SHALL continue to identify the product as
`adrctl`, regardless of whether the bytes are reached as `adrctl.bash`, an
installed `adrctl`, an `adr` symlink, or a shell alias that expands to the
artifact path.

The generated-artifact test matrix SHALL exercise at least:

- direct execution of `dist/adrctl.bash`;
- execution of the same bytes through an `adrctl` symbolic link;
- execution of the same bytes through an `adr` symbolic link;
- command execution through a shell alias named `adr` that expands to the
  `adrctl.bash` path;
- canonical help and diagnostic presentation for `adrctl.bash` and `adrctl`;
- compatibility presentation through a filesystem `adr` symlink;
- canonical `adrctl` presentation through a plain shell alias; and
- release/checksum paths using `adrctl.bash`.

The embedded `mktext` v0.0.6 execution guard remains compatible with this change.
The basename `adrctl.bash` does not match either supported standalone `mktext`
name, so the embedded renderer remains inert until called by `adrctl`.

## Superseded Portions of Earlier Decisions

This ADR supersedes ADR-002 only where ADR-002 states that the generated and
released executable file itself SHALL be named `adrctl`.  ADR-002 remains in
force for product identity, canonical command identity, detectable `adr` symlink
behavior, presentation rules, and the one-implementation compatibility model.

This ADR supersedes ADR-015 only where ADR-015 names `dist/adrctl` as the
canonical generated artifact or release path.  All other source, build,
validation, metadata, checksum, attestation, and single-artifact decisions in
ADR-015 remain in force.

## Considered Alternatives

### Keep dist/adrctl

This was the previously accepted path.  It was rejected by the maintainer's
explicit correction that the completely built Bash tool should reside at
`dist/adrctl.bash`.

### Publish both adrctl and adrctl.bash

Publishing duplicate executable assets would enlarge the release, checksum,
attestation, documentation, and test surfaces without adding capability.  One
canonical distribution artifact remains sufficient.

### Rename the product and command to adrctl.bash

The `.bash` suffix describes the generated file rather than the product.  Making
it part of the public command identity would unnecessarily change existing CLI
and compatibility decisions.

### Require a symlink and reject shell aliases

A shell alias to the released Bash artifact is a normal low-friction installation
choice and requires no special runtime mechanism.  Rejecting it would create an
unnecessary difference between equivalent ways of reaching the same bytes.

### Pretend a shell alias is detectable as adr

Bash expands aliases before command execution and does not pass the original
alias token to the script as `$0`.  Fabricating `adr` presentation would require
extra wrapper state or environment configuration and would make a simple alias
more complex than necessary.

## Consequences

Build output, tests, checksum generation, release automation, documentation, and
consumer-artifact validation must consistently use `dist/adrctl.bash`.

The generated checksum filename becomes `adrctl.bash.sha256` automatically when
it is derived from the distribution artifact name.

Users and packagers can install the released file under the canonical command
name `adrctl`, may provide the historical `adr` symlink, or may use a shell alias
that points directly to `adrctl.bash`.

The runtime needs a narrow invocation-name normalization rule so direct execution
of the `.bash` artifact and plain alias invocation present canonical `adrctl` help
and diagnostics.

Historical ADR-002 and ADR-015 remain intact as records of the earlier decision;
this ADR is the authoritative later correction for the generated artifact name
and supported alias behavior.

## Related Decisions

- Supersedes in part: ADR-002
- Related to: ADR-003
- Supersedes in part: ADR-015
- Related to: ADR-017
- Related to: ADR-018

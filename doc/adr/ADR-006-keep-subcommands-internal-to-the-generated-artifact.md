# ADR-006: Keep Subcommands Internal to the Generated Artifact

Date: 2026-08-15

## Status

Proposed

## Intent and Documentation Posture

This ADR defines the extension boundary for `adrctl` subcommands.

The predecessor implements subcommands as separate `adr-*` executables in its
installation directory.  `adrctl` instead targets one generated executable.
This ADR decides whether that predecessor structure is a compatibility
requirement or an internal implementation detail.

## Context

`npryce/adr-tools` dispatches `adr COMMAND` by constructing an executable path for
`adr-COMMAND` inside its configured binary directory.  That structure allows the
upstream package to be assembled from multiple command files, but it does not by
itself establish a general external plugin protocol for `adrctl`.

`adrctl` is deliberately adopting a modular maintained source tree that builds
one self-contained consumer artifact.  Supporting external command discovery
would reintroduce runtime filesystem coupling, search-path policy, versioning
questions, trust questions, and a second extension lifecycle before the project
has a concrete need for them.

The maintainer has explicitly decided that any additional subcommands supported
at this stage will be implemented inside the repository and included in the
generated artifact.  External plugins are outside the initial product scope.

## Decision Drivers

- Preserve one self-contained generated executable.
- Keep command availability deterministic and inspectable.
- Avoid a plugin trust/version/discovery model without a demonstrated use case.
- Preserve supported predecessor command semantics without inheriting its file
  layout unnecessarily.
- Keep release, checksum, provenance, documentation, and testing surfaces tied to
  one artifact.
- Allow internal modularity during development without exposing that structure as
  a public runtime extension API.

## Decision

All supported `adrctl` subcommands SHALL be implemented by code maintained in the
`adrctl` repository and incorporated into the generated `adrctl` executable at
build time.

The build SHALL enumerate maintained source modules explicitly so command
availability and assembly order are deterministic.

The runtime SHALL NOT discover or execute arbitrary external `adr-*`,
`adrctl-*`, or similarly named executables as plugins.

The runtime SHALL NOT search `$PATH`, the directory containing the generated
artifact, the project directory, or another plugin directory for a command
implementation merely because an unknown subcommand was requested.

An unknown subcommand SHALL fail through the documented `adrctl` usage/diagnostic
contract.

Invocation through the `adr` compatibility symlink defined by ADR-002 SHALL use
the same internal command set.  The alias SHALL NOT enable predecessor-style
external command discovery.

Internal source files MAY be organized by subcommand or responsibility.  Such
files are implementation modules, not separately supported executables or public
plugin interfaces.

A future external plugin mechanism would require a new ADR defining at least:

- discovery locations and precedence;
- naming and command collision rules;
- API/version compatibility;
- argument, environment, stdin/stdout/stderr, and exit-status contracts;
- trust and security boundaries;
- packaging and provenance expectations; and
- behavior through both `adrctl` and `adr` invocation names.

## Compatibility Classification

For supported built-in predecessor commands, the goal remains behavioral
compatibility as defined by the normative specification and compatibility corpus.

The predecessor's use of separate `adr-*` files is classified as an
implementation mechanism rather than a required public architecture.

If a user has locally modified an `adr-tools` installation by placing additional
`adr-*` executables into its binary directory, those locally added commands are
not part of the initial `adrctl` compatibility contract.

## Considered Alternatives

### Preserve adr-* executable discovery

This would more closely reproduce predecessor dispatch internals, but it would
make the generated executable dependent on neighboring runtime files and create
an external extension contract that the project does not currently need.

### Search PATH for external plugins

This would provide a conventional plugin mechanism, but it would be a new feature
rather than compatibility with the predecessor's configured binary-directory
dispatch.  It also introduces command shadowing and trust concerns.

### Automatically discover source modules at build time

This would keep plugins internal while reducing Makefile enumeration.  It was
rejected because explicit source lists produce deterministic build order and make
new executable behavior visible in review.

## Consequences

The generated `adrctl` artifact remains self-contained and relocatable.

Adding a subcommand requires a repository change, documentation, tests, and a new
build/release rather than dropping an executable into a runtime directory.

The compatibility corpus can focus on observable command behavior instead of
replicating predecessor filesystem layout.

The project retains the option to design plugins later if a real use case
justifies the additional contract.

## Open Questions and Follow-Ups

The normative specification must enumerate the initial supported subcommands and
unknown-command diagnostics.

The build ADR/specification must identify the explicit maintained source-module
order used to assemble the generated artifact.

## Related Decisions

- Related to: ADR-002
- Related to: ADR-003
- Adapted from Bootstrap ADR-009, ADR-010, ADR-024, ADR-033, and ADR-034.
- Compatibility lineage: `npryce/adr-tools` ADR 0003 and its `adr-*` dispatch
  implementation.

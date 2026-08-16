# ADR-008: Require Bash 4.3+ and Classify Runtime Dependencies

Date: 2026-08-15

## Status

Accepted

## Context

`adrctl` is a Bash program that intentionally follows the Bootstrap and `mktext`
model of maintained modular source assembled into one consumer executable.  Its
embedded `mktext` dependency requires Bash 4.3 or newer because its public API
uses associative arrays and namerefs.

The predecessor `adr-tools` relies on a collection of ordinary Unix commands and
optionally participates in documentation tool chains such as Graphviz.  A rewrite
should not accidentally make every command used anywhere in the project a core
runtime requirement.

Dependencies need to be classified according to when and why they are required.
That keeps the runtime inspectable, avoids network-dependent behavior, and allows
optional features to fail locally rather than preventing unrelated commands from
working.

## Decision

`adrctl` SHALL require Bash 4.3 or newer.

The generated executable SHALL validate the Bash version before using features
that are unavailable on older versions and SHALL fail with a concise diagnostic
when the requirement is not met.

Dependencies SHALL be classified into these categories:

1. Bash builtins and language features used by the core runtime;
2. core external runtime commands required by generally available product
   behavior;
3. feature-specific optional runtime commands;
4. build-only dependencies; and
5. development/documentation dependencies.

The implementation SHOULD prefer Bash builtins where they are clear, portable
within the supported Bash floor, and no less maintainable than an external
command.  Ordinary Unix commands MAY be used when they provide a clearer or more
portable implementation.

Git MAY be used for project-root fallback and product-development metadata where
the relevant operation explicitly permits it.  ADR mutation commands SHALL NOT
implicitly stage, commit, or otherwise change Git repository state.

Graphviz SHALL be an optional feature-specific dependency.  Commands that only
emit textual graph source SHALL NOT require Graphviz.  A future command that asks
`adrctl` to invoke Graphviz MAY require it for that operation and SHALL diagnose
its absence without disabling unrelated commands.

`mktext` is a build dependency whose verified source is embedded in the generated
artifact under ADR-003.  It SHALL NOT be a separate runtime dependency of the
released `adrctl` executable.

Runtime template rendering SHALL NOT require network access.

Build and release tooling MAY depend on commands such as `curl`, checksum tools,
Doxygen, ShellCheck, shfmt, Bats, GitHub Actions utilities, or similar tooling,
but those commands SHALL NOT become runtime requirements merely because the
repository uses them during development or release.

The normative specification SHALL identify any core external runtime commands
once implementation proves they are necessary.  The project SHOULD avoid adding
a core runtime dependency when a Bash implementation is comparably readable and
reliable.

## Considered Alternatives

### Require only POSIX sh

This would broaden shell availability, but it conflicts with the selected
`mktext` dependency and would require replacing useful associative-array and
nameref-based interfaces.  The additional implementation complexity is not
justified by the compatibility target.

### Require every development tool at runtime

This would make environment setup unnecessarily heavy and would couple ordinary
ADR operations to documentation, linting, release, and optional visualization
tool chains.

### Make Git mandatory for every command

Many ADR operations are fundamentally filesystem operations and remain useful
outside a Git repository.  Git therefore remains a bounded integration rather
than the owner of project state.

## Consequences

The runtime floor matches the embedded renderer and can be tested explicitly in a
Bash 4.3 environment.

Optional functionality can report missing feature-specific dependencies without
making the whole program unusable.

The generated artifact remains self-contained with respect to `mktext` and does
not need to fetch code at runtime.

## Related Decisions

- Related to: ADR-003
- Related to: ADR-005
- Adapted from Bootstrap ADR-001, ADR-021, ADR-033, ADR-034, and ADR-042.
- Adapted from `mktext` ADR-002.
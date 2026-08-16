# ADR-005: Discover Project Context with Recognized Markers

Date: 2026-08-15

## Status

Proposed

## Intent and Documentation Posture

This ADR defines how `adrctl` determines the project root, recognizes project
configuration, preserves legacy `.adr-dir` behavior, and resolves configured
paths.

The goal is to preserve the useful predecessor behavior of running ADR commands
from nested directories without allowing an unrelated `.env` file to redefine
`adrctl` project context accidentally.

## Context

`adr-tools` searches upward from the current directory for `.adr-dir` or an
existing `doc/adr` directory.  The `adrctl` design also introduces `.env`-style
project configuration using namespaced `ADRCTL_` keys.

A generic `.env` cannot safely serve as an unconditional project marker because
many repositories contain `.env` files for unrelated applications.  Stopping at
the nearest arbitrary `.env` could select the wrong project root and redirect ADR
reads or writes into an unintended location.

At the same time, requiring users to abandon `.adr-dir` or always invoke
`adrctl` from the repository root would create unnecessary migration work.

Initialization is a special case because it creates project context rather than
consuming an already-established one.  Preserving predecessor behavior means
`init` should use the directory the user intentionally initializes rather than
silently climbing to a Git ancestor merely because no ADR marker exists yet.

## Decision Drivers

- Preserve nested-directory invocation from `adr-tools`.
- Preserve legacy `.adr-dir` projects without mandatory migration.
- Support explicit `ADRCTL_` project configuration.
- Avoid treating unrelated application `.env` files as `adrctl` markers.
- Keep root selection deterministic, inspectable, and overrideable.
- Resolve project-relative paths consistently from one root.
- Avoid sourcing configuration as shell code.
- Preserve intuitive and predecessor-compatible initialization behavior.

## Decision

For commands that operate on an existing project, `adrctl` SHALL determine
`PROJECT_ROOT` according to this precedence:

1. an explicit command-line project-root option;
2. `ADRCTL_PROJECT_ROOT` from the process environment;
3. the nearest recognized project marker found while walking upward from the
   current working directory;
4. the Git work-tree root, when the current directory is inside a Git work tree;
5. the current working directory.

A recognized project marker is any of the following:

- a `.adr-dir` file;
- an existing `doc/adr` directory;
- a `.env` file containing at least one syntactically recognizable supported
  project-scoped `ADRCTL_` directive.

`ADRCTL_PROJECT_ROOT` is not project-scoped configuration and SHALL NOT, by
itself, cause a `.env` file to become an `adrctl` project marker.  It is a
command/process input as defined by ADR-009.

An arbitrary `.env` that contains no supported project-scoped `ADRCTL_` directive
SHALL NOT establish `adrctl` project context.

When multiple recognized markers exist at different ancestor levels, the nearest
ancestor containing any recognized marker SHALL win.  Marker type SHALL NOT
cause a more distant ancestor to override a nearer recognized project.

After `PROJECT_ROOT` is selected, `adrctl` SHALL read project configuration from
`.env` at that root when present.  Configuration SHALL be parsed as data rather
than sourced or evaluated as shell code.

Configuration precedence for individual settings SHALL be:

```text
built-in default
    -> compatible legacy metadata where applicable
    -> project configuration
    -> process environment
    -> command-line option
```

Higher-precedence values replace lower-precedence values for the same setting.

Recognized `ADRCTL_` configuration keys SHALL be explicitly enumerated by the
normative specification.  An unknown `ADRCTL_` key in the selected project
configuration SHALL be treated as an error rather than silently ignored, so a
typographical error does not create plausible but unintended behavior.

The legacy `.adr-dir` file SHALL remain a supported mechanism for selecting the
ADR directory.  Its path value SHALL be interpreted relative to `PROJECT_ROOT`
unless it is an absolute Unix path.

Configured project paths generally SHALL follow the same rule:

- a path beginning with `/` is absolute;
- any other configured path is resolved relative to `PROJECT_ROOT`.

The normative specification SHALL define command-specific exceptions when a
command intentionally establishes a new project or uses a different path base.

For `init`, when neither a command-line project root nor
`ADRCTL_PROJECT_ROOT` is supplied, `PROJECT_ROOT` SHALL be the current working
directory.  `init` SHALL NOT use Git-root fallback before it has established the
new ADR project.  This preserves the predecessor expectation that `adr init`
initializes the directory in which it is invoked.

`adrctl` SHALL NOT require Git merely to operate.  Git-root discovery is a
fallback when no recognized `adrctl` marker exists; it does not make Git the
owner of project configuration or ADR state.

## Considered Alternatives

### Treat every ancestor `.env` as a project marker

This was rejected because `.env` is a common application configuration filename
with no inherent relationship to ADR tooling.  An unrelated nearer `.env` could
silently redirect project discovery.

### Let ADRCTL_PROJECT_ROOT inside .env redirect discovery

This was rejected because the root must already be known before `adrctl` can
choose which `.env` to read.  Root overrides therefore remain command/process
inputs and do not create recursive discovery semantics.

### Use only a new dedicated adrctl configuration filename

A dedicated filename would be unambiguous, but it would add another project file
and diverge from the selected `.env` configuration model.  Namespaced content is
sufficient to make `.env` recognizable without claiming unrelated files.

### Resolve Git root before legacy markers

This would be predictable in Git repositories, but it could change established
`.adr-dir`/`doc/adr` behavior in nested or multi-project repositories.  Explicit
ADR markers are stronger evidence of intended ADR context than repository
membership alone.

### Let init use Git-root fallback

This would make initialization inside a nested Git directory unexpectedly modify
the repository root.  Initialization creates ADR context and therefore defaults
to the caller's current directory unless explicitly redirected.

### Require invocation from project root

This would simplify discovery but regress a useful predecessor workflow and make
interactive use unnecessarily cumbersome.

### Source the .env file

This was rejected because configuration is data.  Shell evaluation would expand
the trusted computing base, permit arbitrary execution, and reproduce an unsafe
class of predecessor implementation behavior without compatibility benefit.

## Consequences

Existing `.adr-dir` and ordinary `doc/adr` projects remain discoverable from
nested directories.

New projects can use namespaced `.env` configuration without unrelated `.env`
files hijacking discovery.

The implementation needs one explicit upward-discovery routine and a strict
configuration parser.

Initialization retains current-directory semantics unless deliberately
redirected.

Git remains useful as a fallback but is not a mandatory runtime dependency for
basic ADR operations.

Tests must cover nested directories, competing ancestor markers, unrelated
`.env` files, qualifying `.env` files, explicit root overrides, `.adr-dir`, Git
fallback, cwd fallback, and initialization inside nested Git directories.

## Open Questions and Follow-Ups

The normative specification must enumerate the supported `ADRCTL_` keys and use
`--project-root PATH` as the explicit project-root option unless a later ADR
changes that spelling.

Migration guidance may later recommend `.env` configuration while preserving
`.adr-dir` compatibility; no automated migration command is required by this
ADR.

## Related Decisions

- Related to: ADR-000
- Related to: ADR-001
- Related to: ADR-002
- Related to: ADR-009
- Adapted from Bootstrap ADR-005, ADR-023, ADR-028, and ADR-040.
- Compatibility lineage: `npryce/adr-tools` upward `.adr-dir`/`doc/adr` discovery.
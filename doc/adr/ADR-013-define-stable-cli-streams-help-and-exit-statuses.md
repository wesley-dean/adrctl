# ADR-013: Define Stable CLI Streams, Help, and Exit Statuses

Date: 2026-08-15

## Status

Accepted

## Context

`adrctl` is both an interactive command and a tool that users may call from shell
scripts.  The predecessor intentionally prints the newly created ADR filename to
standard output so `adr new` can participate in automation.  Generated reports
such as table-of-contents and graph output are also pipeline-oriented.

Diagnostics, help text, version metadata, and status codes therefore need stable
boundaries.  Routine progress text on standard output would corrupt command
substitution and generated-document pipelines.

ADR-002 additionally requires help and diagnostics to respect the invocation name
`adr` or `adrctl` without changing the canonical product identity.

## Decision

### Standard output

Standard output SHALL be reserved for the command's requested result or explicit
informational output.

Examples include:

- the created ADR pathname from a successful `new` command;
- the ADR path list from `list`;
- table-of-contents output;
- Graphviz DOT output;
- requested help text when not being displayed through a pager; and
- requested version information.

Routine diagnostics, warnings, migration notices, configuration errors, and
failure explanations SHALL NOT be mixed into script-facing result output.

### Standard error

Diagnostics and warnings SHALL be written to standard error.

A failure diagnostic SHOULD identify the command or subject that failed and
SHOULD avoid dumping implementation details unless an explicit diagnostic mode is
selected.

Human-facing diagnostic prefixes SHOULD use the invoked basename (`adr` or
`adrctl`) under ADR-002.

### Exit statuses

The initial public exit-status vocabulary SHALL be intentionally small:

```text
0  successful completion
1  operational or domain failure
2  invalid command usage or invalid adrctl configuration
```

Examples of status 1 include unresolved or ambiguous ADR references, required
files that cannot be read or written, an expected external operation that fails,
or a requested project operation that cannot be completed safely.

Examples of status 2 include unknown options, missing required arguments,
malformed option values, conflicting options, unknown `ADRCTL_` project keys, or
an invalid delimiter pair.

Internal `mktext` statuses SHALL be translated into the `adrctl` public status
contract.  `adrctl` SHALL NOT expose `mktext`'s private numeric vocabulary merely
because the library is embedded.

A process terminated by a signal MAY retain Bash's normal signal-derived process
status.  `adrctl` SHALL NOT install broad signal handlers solely to force every
termination into 0, 1, or 2.

A future ADR MAY add a public status when a concrete machine-readable distinction
is valuable.  New statuses SHALL not be invented for internal layering alone.

### Help

The canonical help surface SHALL be available through an explicit `help`
subcommand.  Top-level `-h` and `--help` SHOULD be supported as convenient
aliases.

Help for an inherited command SHALL document the compatible command grammar and
intentional deviations.

When invoked as `adr`, usage examples and command prefixes SHOULD use `adr`.
When invoked as `adrctl`, they SHOULD use `adrctl`.

Pager behavior is governed by ADR-012.

### Version identity

The canonical product identity in version output SHALL be `adrctl` even when the
same artifact is invoked through an `adr` symlink.

Version output SHALL report immutable build metadata embedded by the generated
artifact and SHALL NOT query Git, the network, or the clock at runtime.

The exact stable version-output format SHALL be specified before implementation
and tested against the generated artifact.

### Unknown commands

An unknown subcommand SHALL fail with status 2, write a concise diagnostic to
standard error, and make appropriate usage/help discoverable without attempting
to execute an external plugin under ADR-006.

## Considered Alternatives

### Print status/progress messages to stdout

This is convenient for interactive use but corrupts command substitution and
report pipelines.  Diagnostics belong on stderr.

### Preserve every predecessor error status exactly

`adr-tools` frequently relies on `set -e` and status 1 without defining a stable
error taxonomy.  Treating those incidental numeric results as a compatibility
contract would freeze implementation accidents.  Successful output and the
success/non-success distinction are stronger compatibility surfaces.

### Expose detailed internal error codes

A large status vocabulary makes scripts depend on implementation layers and is
difficult to preserve.  Start with distinctions users can act upon.

## Consequences

Script-facing output remains clean and composable.

Help can look natural through either supported invocation name without obscuring
the installed product identity.

The public status contract is small enough to preserve while still separating
usage/configuration errors from operational failures.

## Related Decisions

- Related to: ADR-002
- Related to: ADR-006
- Related to: ADR-012
- Adapted from Bootstrap ADR-020, ADR-024, ADR-025, ADR-026, ADR-028, and ADR-030.
- Compatibility evidence: `adr-tools` `adr-new`, `adr-list`, `adr-help`, and
  `adr-generate`.
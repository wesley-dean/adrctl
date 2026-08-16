# ADR-012: Bound Editor, Pager, Git, and Graphviz Integrations

Date: 2026-08-15

## Status

Proposed

## Context

`adrctl` inherits several integrations with programs outside its own process.  The
predecessor opens newly created ADRs in an editor, pages help text, can participate
in Git repositories, and emits Graphviz DOT source for relationship graphs.

These integrations should remain useful without allowing external tools to blur
`adrctl`'s responsibility boundaries.  In particular, command selection and
argument preparation belong to `adrctl`; the external program owns its own
interactive behavior and output after a valid invocation is made.

## Decision

### Editor selection

For compatibility, `adrctl` SHALL select an editor for ordinary `new` operations
using this precedence:

```text
VISUAL
EDITOR
no-op fallback
```

The predecessor's no-op fallback is effectively `true`; `adrctl` MAY implement
that behavior without spawning an external `true` process.

A command or option that explicitly disables editing SHALL take precedence over
the environment.  `init` SHALL be able to create its bootstrap ADR without
opening an interactive editor, preserving predecessor behavior.

`adrctl` SHALL invoke the selected editor only after the target ADR and all
related mutations have passed preflight and the initial file has been written.
The editor's exit status SHALL be handled according to the public command status
contract; editor failure SHALL NOT cause `adrctl` to pretend the already-created
file was never written.

### Pager selection

For compatibility, help display SHALL select a pager using:

```text
ADR_PAGER
PAGER
more
```

The implementation SHALL NOT evaluate pager text as arbitrary shell source.
Where support for pager arguments is required for compatibility, tokenization and
invocation semantics SHALL be specified explicitly rather than implemented with
`eval`.

Non-interactive or explicitly unpaged help MAY bypass the pager and write help
text directly to standard output.

### Git boundary

Git MAY be queried as a fallback source for `PROJECT_ROOT` under ADR-005 and MAY
be used by build/release tooling for source metadata.

Core ADR commands SHALL NOT implicitly run `git add`, `git commit`, `git mv`,
`git checkout`, or otherwise mutate repository state.  ADR filesystem changes
remain visible to Git in the ordinary way and are committed by the user or their
own automation.

A command SHALL remain usable outside a Git work tree whenever its behavior does
not intrinsically require Git.

### Graph generation and Graphviz

The inherited `generate graph` behavior SHALL emit Graphviz DOT text to standard
output.  It SHALL NOT require the Graphviz `dot` executable merely to generate
that text.

The initial product SHALL NOT invoke Graphviz automatically.  Users may pipe DOT
output to Graphviz or another compatible tool themselves.

A future explicit rendering command MAY integrate Graphviz as an optional
feature-specific dependency, but that would require a separate documented
contract for formats, diagnostics, and failures.

### General external-process rule

Before invoking any external program, `adrctl` SHALL finish all validation it can
perform locally, construct arguments without shell evaluation, and keep
script-facing standard output free of unrelated diagnostics.

External processes SHALL NOT be used as hidden configuration or plugin execution
mechanisms.

## Considered Alternatives

### Execute editor and pager values with `eval`

This can support elaborate shell snippets but turns environment configuration
into shell source and makes quoting difficult to reason about.  Explicit process
invocation is safer.

### Have `adrctl` automatically commit ADR changes

That would make Git an owner of mutation semantics and surprise users whose
branching, staging, signing, or review workflows differ.

### Require Graphviz for `generate graph`

The predecessor emits DOT source and leaves visualization to downstream tools.
Keeping that boundary avoids a needless core dependency.

### Remove editor and pager compatibility

These are established user-facing workflows and inexpensive to preserve when
implemented with a safer invocation boundary.

## Consequences

Existing editor and pager preferences continue to work with documented
precedence.

Git remains useful context rather than a hidden mutation engine.

Graph generation remains composable in pipelines and does not enlarge the core
runtime dependency set.

## Related Decisions

- Related to: ADR-005
- Related to: ADR-007
- Related to: ADR-008
- Adapted from Bootstrap ADR-004, ADR-013, ADR-021, ADR-025, ADR-033, and ADR-042.
- Compatibility evidence: `adr-tools` `adr-new`, `adr-help`, and
  `_adr_generate_graph`.
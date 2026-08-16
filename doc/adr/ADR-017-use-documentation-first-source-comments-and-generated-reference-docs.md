# ADR-017: Use Documentation-First Source Comments and Generated Reference Docs

Date: 2026-08-15

## Status

Accepted

## Context

Bootstrap and `mktext` both treat source documentation as part of the engineering
contract rather than as optional cleanup.  Their Bash source uses Doxygen-compatible
comments, and generated reference documentation is made available as a browsable
project artifact.

`adrctl` will have more modules and more compatibility-sensitive behavior than
`mktext`.  Contributors need to understand ownership, inputs, outputs, statuses,
side effects, and invariants without reverse-engineering dense Bash.

## Decision

Hand-maintained Bash source SHALL use Doxygen-compatible documentation comments
for modules, public/internal functions, important constants, and non-obvious
state boundaries.

Function documentation SHALL describe, where applicable:

- purpose and responsibility;
- parameters and expected forms;
- stdout/stderr behavior;
- return statuses;
- filesystem or process side effects;
- caller/callee ownership boundaries;
- important preconditions or invariants; and
- examples when they materially improve understanding.

Comments SHALL explain intent, constraints, and non-obvious reasoning rather than
merely restating shell syntax.

Documentation SHALL be written before or alongside implementation when a new
function or module is introduced.  If implementation changes the documented
contract, the documentation SHALL change in the same coherent change.

The repository SHALL provide a Doxygen configuration and Bash filter compatible
with the source-comment convention.

Generated reference documentation SHALL live under:

```text
doc/reference/
```

The reference output SHALL be reproducible from maintained source and SHALL be
regenerated when public/internal documented source structure changes.

The generated reference documentation SHOULD be committed so repository readers
and GitHub Pages can browse it without requiring a local documentation toolchain.
A sentinel README SHALL make clear that generated reference files are not to be
edited manually.

`make docs` SHALL regenerate reference documentation from a clean reference
output directory.  `make docs-clean` and `make docs-stage` SHALL provide the
corresponding cleanup and staging operations described by ADR-015.

GitHub Pages SHOULD publish `doc/reference` from the default branch after
regenerating or validating the reference documentation according to the selected
workflow.

Generated reference documentation does not replace hand-maintained product
documentation.  ADRs explain why; the normative specification defines current
behavior; README explains product use; AGENTS guides contributors; source
comments document implementation boundaries.

## Considered Alternatives

### Rely on readable function names alone

Names help navigation but cannot capture failure semantics, side effects,
compatibility rationale, or subtle ownership boundaries.

### Generate docs but do not commit them

That reduces repository churn but makes browser-only inspection harder and
weakens the documentation-as-product precedent selected by Bootstrap and
`mktext`.

### Put implementation details in ADRs

ADRs should explain durable architectural decisions.  Per-function contracts and
implementation boundaries belong close to the source.

## Consequences

Source modules carry enough context for future contributors to reason about them
without reconstructing this development conversation.

Reference documentation becomes part of release-quality validation.

Documentation drift is treated as an engineering defect rather than cosmetic
debt.

## Related Decisions

- Related to: ADR-015
- Adapted from Bootstrap ADR-041, ADR-044, and ADR-045.
- Adapted from `mktext` ADR-011 and ADR-012.
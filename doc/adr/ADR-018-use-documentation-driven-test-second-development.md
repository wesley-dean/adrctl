# ADR-018: Use Documentation-Driven, Test-Second Development

Date: 2026-08-15

## Status

Proposed

## Context

`adrctl` is a compatibility-oriented rewrite with substantial architectural
intent that cannot be reconstructed reliably from tests alone.  Bootstrap and
`mktext` both converged on a documentation-driven workflow: establish the
behavioral or architectural contract, implement the smallest coherent change,
then add or update observable-behavior tests and validate the resulting artifact.

Tests remain essential, but a test suite is not the best primary record for why a
compatibility deviation, safety rule, dependency boundary, or release contract
exists.

## Decision

Normal `adrctl` development SHALL use this sequence for architectural or
behavioral changes:

1. identify the user-visible or architectural intent;
2. update or add the relevant ADR, specification section, or other normative
   documentation;
3. implement the smallest coherent change that satisfies that documented intent;
4. add or update tests of observable behavior;
5. build and validate the literal generated artifact where the change can affect
   consumers; and
6. review the complete diff for architectural drift, documentation drift, and
   unintended compatibility changes.

This is a default workflow, not a prohibition on exploratory tests.  A maintainer
MAY write a test first when it is the clearest way to reproduce a bug, characterize
unknown behavior, or explore an interface.  Before the change is considered
complete, the normative documentation SHALL describe the intended resulting
behavior independently of the test implementation.

Architecture Decision Records SHALL explain durable choices, alternatives, and
consequences.  New ADRs created during initial development SHALL remain `Proposed`
until the maintainer intentionally accepts them.

The normative behavioral specification SHALL describe the current public
contract and SHALL be updated whenever a command, configuration value, stream,
status, file format, or compatibility behavior changes.

Tests SHALL emphasize observable behavior and shall avoid coupling to private
helper names or module layout unless the module/build boundary is itself the
subject of the test.

Bug fixes SHALL include a regression test when the defect is observable and
reasonably reproducible.

Implementation discoveries that contradict an ADR or specification SHALL be
surfaced as an architectural conflict.  The project SHALL update the decision or
change the implementation; it SHALL NOT silently let code become the new truth.

## Considered Alternatives

### Test-first development as a universal rule

Test-first can be useful, but making it mandatory would encourage tests to become
the de facto design record and fits poorly when the primary task is deciding a
compatibility or architecture contract.

### Documentation after implementation

This makes it easy for implementation accidents to be rationalized after the
fact and increases the chance that important constraints remain undocumented.

### Treat code as the only source of truth

That forces each contributor to rediscover rationale, alternatives, and intended
boundaries from implementation details.

## Consequences

Architecture and behavior remain explainable independently of the current source
layout.

Tests verify contracts rather than inventing them implicitly.

The project can use tests pragmatically during investigation without abandoning
documentation-first intent.

## Related Decisions

- Related to: ADR-014
- Related to: ADR-017
- Adapted from Bootstrap ADR-036, ADR-039, ADR-041, ADR-044, and ADR-046.
- Adapted from `mktext` ADR-009 and ADR-010.
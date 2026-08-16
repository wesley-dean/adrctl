# ADR-007: Preflight Multi-File Mutations Before Writing

Date: 2026-08-15

## Status

Proposed

## Intent and Documentation Posture

This ADR defines the safety boundary for commands that create or modify more than
one ADR file.

The decision preserves successful predecessor behavior while deliberately
improving avoidable failure modes.  It does not claim filesystem-wide
transactionality that ordinary portable Bash cannot guarantee.

## Context

Some `adr-tools` operations, including link and supersede workflows, can update
multiple ADR documents during one command.  The predecessor performs sequential
mutations, so a later failure can leave earlier files changed.

That partial-write behavior is observable, but it is an implementation failure
mode rather than a useful compatibility property.  Preserving it would conflict
with the project's broader goals of conservative failure, explicit preflight,
deterministic behavior, and inspectable mutation boundaries.

The maintainer has explicitly chosen to preserve successful results while
strengthening failure safety.

## Decision Drivers

- Avoid predictable partial changes when an error can be detected before writes.
- Preserve successful predecessor outputs and workflows wherever practical.
- Keep failure behavior conservative and understandable.
- Avoid promising cross-file atomic transactions that the implementation cannot
  actually guarantee.
- Prepare complete intended content before mutating user files.
- Use ordinary portable filesystem mechanisms where practical.

## Decision

Before the first persistent mutation of a multi-file operation, `adrctl` SHALL
preflight every condition that can reasonably be validated without performing
that mutation.

Preflight SHALL include, as applicable:

- command arguments and option combinations;
- project-root and ADR-directory resolution;
- referenced ADR existence and unambiguous lookup;
- template selection and readability;
- rendering-context preparation and template rendering;
- destination path calculation;
- filename/number collisions known at preflight time;
- source file readability;
- destination directory existence and writability;
- parse or mutation prerequisites for every affected ADR;
- availability of required feature-specific external tools before mutation; and
- the complete intended content for each affected file.

`adrctl` SHOULD construct the complete replacement content for all affected files
before the first persistent write whenever practical.

For an existing file replacement, `adrctl` SHOULD write prepared content to a
temporary file in the same directory and replace the destination using an atomic
rename when the target filesystem and operation permit it.

For creation of a new ADR, the implementation SHALL avoid silently overwriting an
existing path.  The normative specification and concurrency decision will define
the exact creation primitive and collision behavior.

A command SHALL NOT intentionally mutate an earlier file and then perform a
validation step for a later file that could reasonably have been performed during
preflight.

If a failure occurs after mutation has begun due to a condition that could not be
predicted or prevented during preflight, `adrctl` SHALL report the failure
accurately.  It SHALL NOT claim that the entire multi-file operation was atomic
unless a future implementation genuinely provides that guarantee.

The initial design SHALL NOT implement a general rollback transaction system.
Rollback across several files can itself fail and would add a substantially more
complex persistence protocol.  Strong preflight plus atomic per-file replacement
is the selected initial safety model.

Successful output compatibility SHALL take precedence over preservation of
accidental predecessor partial-write states.  A legacy failure that left one or
more files partially updated MAY become a clean preflight failure in `adrctl`.
Such a difference is an intentional safety improvement rather than a
compatibility defect.

## Considered Alternatives

### Preserve predecessor write ordering and partial failures

This would reproduce more incidental behavior, but it would knowingly retain
avoidable inconsistent states.  The project does not treat unsuccessful
intermediate filesystem states as a compatibility goal.

### Implement a full cross-file transaction and rollback journal

This could provide stronger recovery semantics, but it would add persistent
transaction state, rollback failure modes, cleanup policy, and substantially more
complexity than the current ADR workflows justify.

### Write files directly after validating each one individually

This is simpler than whole-operation preflight, but a later predictable error can
still leave earlier files changed.  Validation should cover the complete intended
operation before mutation begins.

### Require Git and use Git for rollback

Git could help users inspect or revert changes, but making Git responsible for
transaction safety would make a version-control tool a mandatory persistence
mechanism and would fail outside Git repositories.  Git is not the mutation
owner.

## Consequences

Some failing `adrctl` commands will be safer than the corresponding predecessor
command and may leave fewer partial changes.

Implementation will benefit from a conceptual separation between interpretation
and mutation: resolve references, derive content, validate the change set, then
write.

Tests must exercise failure injection and observable filesystem state, including
errors discovered before mutation and failures that occur after mutation begins.

Per-file atomic replacement reduces torn writes but does not make a collection of
separate file replacements one atomic transaction.

Commands that invoke an editor after creating an ADR need a separately specified
boundary: a later interactive editor failure cannot generally mean that the
already-created ADR never existed.

## Open Questions and Follow-Ups

The normative specification must define the mutation set for each command and the
point at which a command is considered to have entered persistent mutation.

The concurrent ADR-number allocation decision must specify how creation races are
handled without weakening the no-overwrite rule.

Editor, pager, and viewer invocation behavior will be documented separately.

## Related Decisions

- Related to: ADR-000
- Related to: ADR-005
- Adapted from Bootstrap ADR-013, ADR-014, ADR-015, ADR-039, and ADR-040.
- Related working baseline: `doc/upstream-adr-tools-compatibility.md`

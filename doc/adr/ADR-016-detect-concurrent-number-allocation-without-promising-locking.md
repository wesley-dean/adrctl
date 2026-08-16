# ADR-016: Detect Concurrent Number Allocation without Promising Locking

Date: 2026-08-15

## Status

Proposed

## Context

The predecessor chooses the next ADR number by scanning existing filenames,
adding one to the maximum number, and then writing the new file.  Two concurrent
`new` commands can therefore choose the same number.

A complete locking protocol would add new state, stale-lock recovery rules,
waiting behavior, timeouts, and portability questions.  The initial product does
not otherwise need a cross-process coordination system.

At the same time, `adrctl` should never silently overwrite an ADR merely because
a race occurred between number selection and file creation.

## Decision

The initial `adrctl` concurrency model SHALL treat simultaneous writers to the
same ADR directory as unsupported for guaranteed automatic sequencing.

`adrctl` SHALL nevertheless defend against destructive number-allocation races.

A `new` operation SHALL:

1. inspect the ADR directory and determine the next candidate logical number;
2. render and validate the intended destination basename;
3. confirm during preflight that the destination does not already exist; and
4. use creation/replacement mechanics that SHALL NOT overwrite a file that
   appeared after preflight.

If another process claims the same destination before `adrctl` completes its
creation, the command SHALL fail safely with status 1 and a diagnostic indicating
that the destination already exists or that concurrent allocation was detected.
The user may rerun the command, causing a fresh scan and a new candidate number.

The implementation MAY perform a small bounded automatic rescan/retry when the
only failure is a cleanly detected destination collision, provided that:

- no user-visible partial mutation has occurred;
- retry count is bounded and deterministic;
- the command never overwrites the competing file; and
- behavior is covered by a concurrency regression test.

The initial architecture SHALL NOT introduce a persistent lock file or lock
directory as part of the public project format.

A future ADR MAY add coordinated concurrent allocation if a real multi-writer use
case justifies lock ownership, stale-lock recovery, waiting, and timeout
semantics.

Multi-file relationship updates remain governed by ADR-007.  This ADR does not
claim cross-process transactionality for those operations.

## Considered Alternatives

### Ignore the race

This preserves predecessor behavior but risks one process overwriting or corrupting
another process's ADR.  Safe collision detection is inexpensive and appropriate.

### Add a project-wide lock immediately

A lock can serialize number allocation, but it creates additional persistent or
semi-persistent state and requires recovery semantics that the current product
has no demonstrated need for.

### Use timestamps or random identifiers instead of sequential numbers

That would avoid allocation contention but would abandon a central compatibility
convention and change filenames, references, and user expectations.

### Guarantee automatic retries until success

Unbounded waiting or retry loops can hang automation and obscure contention.
A bounded retry is acceptable as an implementation optimization; guaranteed
multi-writer sequencing is not part of the initial contract.

## Consequences

The common single-writer workflow stays simple and compatible.

Concurrent runs fail safely rather than overwriting each other.

The project format does not gain lock metadata before a concrete need exists.

## Related Decisions

- Related to: ADR-007
- Related to: ADR-010
- Related to: ADR-013
- Adapted from Bootstrap ADR-013, ADR-015, ADR-028, and ADR-040.
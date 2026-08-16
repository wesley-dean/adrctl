# ADR-004: Continue Using CC0 for adrctl

Date: 2026-08-15

## Status

Accepted

## Intent and Documentation Posture

This ADR records the license selected for `adrctl` and the provenance boundary
that applies while reproducing compatible behavior from `npryce/adr-tools`.

## Context

The repository template used to create `adrctl` supplied the Creative Commons
CC0 1.0 Universal dedication.  The predecessor project, `npryce/adr-tools`, is
licensed under GPLv3-or-later for its program implementation and separately
describes licensing for content created by the tool.

`adrctl` is being implemented independently against documented observable
behavior, architecture decisions, a normative specification, and an
independently authored compatibility corpus.  Upstream implementation source is
useful as evidence of behavior, but it is not an implementation source for the
new program.

The maintainer has explicitly selected CC0 for `adrctl`; the existing repository
license is therefore intentional rather than temporary template scaffolding.

## Decision Drivers

- Preserve the maintainer's explicit intent to dedicate `adrctl` under CC0.
- Keep licensing simple and permissive for downstream users and contributors.
- Maintain a reviewable provenance boundary from GPL-covered predecessor source.
- Separate behavioral compatibility work from source-code adaptation.
- Keep licensing and compatibility decisions explicit in project history.

## Decision

`adrctl` SHALL continue to use the repository's existing CC0 1.0 Universal
license.

The `LICENSE` file SHALL remain the canonical license text unless a future ADR
explicitly changes the project license.

The compatibility and implementation process SHALL maintain the following
provenance boundary:

- upstream `adr-tools` source MAY be inspected to establish observable behavior;
- upstream documentation and tests MAY be used as evidence for independently
  authored specifications, fixtures, and tests;
- GPL-covered predecessor implementation code SHALL NOT be copied, translated,
  mechanically transformed, or adapted into `adrctl` production source;
- `adrctl` production source SHALL be independently authored against the
  project's ADRs, normative specification, and compatibility corpus;
- where behavior is learned from predecessor source, project documentation SHALL
  describe the observable contract rather than reproduce implementation
  expression.

This ADR records a project engineering and licensing decision.  It does not
purport to provide legal advice or resolve questions that would require legal
analysis of a specific contribution or external dependency.

Third-party dependencies retain their own licenses.  Their inclusion in a build
or repository SHALL NOT silently change the declared license of independently
authored `adrctl` source; dependency-license obligations must be handled according
to the dependency's actual terms.

## Considered Alternatives

### Treat CC0 as temporary template scaffolding

This was rejected because the maintainer has explicitly selected CC0 for the
project.

### Adopt GPLv3-or-later to match adr-tools

This would align the successor's license with the predecessor implementation,
but it is not required by the selected independent-implementation strategy and
does not match the maintainer's licensing preference.

### Select another permissive software license

MIT, BSD, Apache-2.0, and similar licenses could provide familiar software
licensing terms.  They were not selected because the maintainer explicitly chose
to retain CC0.

## Consequences

The existing repository license remains valid project intent and does not need a
license migration before implementation begins.

Contributors and automation must continue to respect the provenance boundary
with the GPL-covered predecessor implementation.

Dependency acquisition work, including the pinned `mktext` build dependency,
must retain enough metadata to identify upstream provenance and license terms.

A future decision to incorporate GPL-covered predecessor implementation code
would require revisiting this ADR before that code is introduced.

## Open Questions and Follow-Ups

No licensing decision currently blocks implementation.

Future dependencies or contributions that introduce materially different
licensing obligations should trigger an explicit review rather than being folded
into the build unnoticed.

## Related Decisions

- Related to: ADR-000
- Related to: ADR-003
- Related working baseline: `doc/upstream-adr-tools-compatibility.md`

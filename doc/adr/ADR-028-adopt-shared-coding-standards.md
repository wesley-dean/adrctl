# ADR-028: Adopt Shared Coding Standards

Date: 2026-09-15

## Status

Accepted

## Context

`adrctl` already has repository-specific governance in its README, agent
guidance, specifications where applicable, and Architecture Decision Records.
Related repositories also share reusable coding, documentation, architecture,
release, and development-workflow standards through
`wesley-dean/coding_standards`.

Maintaining independent repository-local copies of reusable standards creates a
drift risk and makes it harder for contributors and automated agents to determine
which rule is current.  Fetching standards dynamically during ordinary development
or CI would create the opposite problem: the effective governance could change
without a reviewed repository change and could become unavailable offline.

The repository also had repository-local documentation-standard files that overlap
with standards now delivered by the managed snapshot:

- `doc/documentation-standard.md`

Those duplicate live standards are removed as part of adoption.  Current guidance
and documentation-generation references are redirected to `doc/standards/` so a
reader does not have to decide which copy is authoritative.

The repository therefore needs a versioned, inspectable adoption model that keeps
shared standards locally available while preserving the authority of accepted
repository-specific decisions.

## Conditions and Assumptions

This decision is made with the following conditions and assumptions:

- `wesley-dean/coding_standards` publishes immutable versioned release artifacts;
- `coding_standards@v1.0.9` is the release selected for this adoption;
- the published `coding_standards.tar.gz` archive has been verified against its
  published checksum and expected SHA-256 digest before materialization;
- the complete release snapshot is the unit of adoption rather than a hand-picked
  subset;
- accepted repository-specific ADRs, explicit security policy, compatibility
  requirements, and documented public contracts remain higher-precedence local
  governance when they intentionally refine a shared standard; and
- language-specific standards are applicable only when their subject matter is
  relevant to maintained content in this repository.

## Decision Drivers

The decision prioritizes:

- one reviewable source of reusable engineering standards across related projects;
- deterministic governance from an ordinary checkout, including offline review;
- explicit provenance for the exact adopted release;
- preservation of repository-specific architectural authority;
- elimination of duplicate live documentation-standard paths;
- visible, reviewable standards upgrades rather than silent synchronization; and
- clear guidance for both human contributors and automated coding agents.

## Decision

The repository SHALL commit the complete released `coding_standards@v1.0.9`
snapshot beneath `doc/standards/`.

The project-root `.codingstandardrc` SHALL record:

- source: `https://github.com/wesley-dean/coding_standards.git`;
- version: `coding_standards@v1.0.9`;
- archive SHA-256:
  `86e91725f30dc5d91a3c7f7158e17d6a8538519b3be10709440e179027c37a03`; and
- managed destination: `doc/standards`.

The release tag resolves to upstream commit
`22e42d2583cc98d4a7db8c48e1ab0c459f76946e`.

Applicable imported standards are repository governance.  Presence in the complete
snapshot does not itself make a standard applicable, and content beneath
`doc/standards/examples/` remains illustrative unless a governing standard
explicitly promotes it.

Imported files SHALL NOT be edited locally.  Shared changes belong upstream in
`wesley-dean/coding_standards`; repository-specific exceptions or refinements
belong in this repository's normal governance.

Every committed ADR in this repository SHALL use `Accepted` as its status.  An ADR
prepared in a pull request intended for merge is written as `Accepted`; merging the
pull request is generally understood to be the maintainer's acceptance of that
ADR.  Supersession, replacement, deprecation, and similar historical relationships
SHALL be expressed in the ADR narrative rather than by changing the status away
from `Accepted`.

The repository SHALL maintain `doc/decisions.md` as the concise orientation layer
over its ADR corpus.  Every ADR SHALL have a corresponding summary of generally
three to five sentences with a direct reference to the ADR.  Adding or materially
changing an ADR requires reviewing and updating that summary in the same pull
request, including summaries of earlier ADRs whose interpretation is changed by a
superseding or refining decision.

These ADR lifecycle rules supersede earlier active process wording that required
new ADRs to remain `Proposed` until a separate maintainer action.  Historical text
that accurately describes an earlier repository state may remain as history, but
it no longer governs current ADR status or acceptance workflow.

A future standards upgrade SHALL replace the complete managed snapshot, update
`.codingstandardrc`, and be reviewed as an ordinary repository change.  The
repository SHALL NOT add a permanent standards downloader, background updater,
Make synchronization target, dependency-manifest entry, or automatic standards
upgrade workflow as part of this adoption.

## Alternatives Considered

### Keep independent repository-local standards

Rejected because independently maintained copies predictably drift and leave
contributors to infer which repository contains the canonical wording.  This
approach also multiplies maintenance work when a shared rule changes.

### Import only standards that appear applicable today

Rejected because a partial snapshot weakens provenance, makes upgrades harder to
audit, and can silently omit a new cross-cutting standard introduced by the
selected release.  Applicability is determined by subject matter and local
governance, not by deleting files from the released snapshot.

### Fetch the latest standards dynamically

Rejected because a moving network dependency would allow effective governance to
change without a repository diff, would reduce reproducibility, and would make
normal development dependent on upstream availability.

### Install permanent synchronization tooling

Rejected because the expected update frequency does not justify another maintained
repository mechanism.  A standards upgrade should remain an intentional reviewable
maintenance event.

### Keep a separate Proposed-to-Accepted ADR transition

Rejected because the pull request already provides the review and acceptance
boundary.  Requiring a second status-only change after merge adds ceremony,
creates a period where merged governance claims not to be accepted, and mixes
acceptance history with later supersession state.

## Tradeoffs and Consequences

The repository gains a deterministic, locally inspectable standards library and a
clear provenance record.  Humans and automated agents can read the same governing
material without network access, and shared-standard changes appear as ordinary
reviewable diffs.

The repository accepts additional tracked documentation volume, including standards
for languages that may not currently apply.  That is intentional: complete snapshot
provenance is preferred over minimizing file count.  Contributors must still use
judgment about applicability and must follow higher-precedence accepted local ADRs
where an intentional refinement exists.

Future shared-standard changes require a deliberate snapshot replacement and
`.codingstandardrc` update rather than an in-place local edit.

ADR review becomes simpler because `Accepted` has one meaning: the decision entered
the repository's governed history.  Later changes in applicability are recorded as
decision relationships rather than overloaded status values.

## Expected Outcomes

After adoption:

- the exact shared standards release is discoverable from `.codingstandardrc`;
- the complete standards library is available beneath `doc/standards/`;
- current repository guidance directs contributors and agents to that managed tree;
- duplicate repository-local documentation standards no longer compete with the
  shared documentation standards;
- all committed ADRs have `Accepted` status;
- `doc/decisions.md` remains synchronized with the ADR corpus; and
- standards changes remain explicit pull-request review surfaces.

## Compatibility and Migration

This decision changes repository governance and maintained documentation only.  It
does not intentionally change runtime behavior, public interfaces, supported input
or output formats, portability commitments, generated product artifacts, or
release semantics.

Where a duplicate repository-local documentation-standard path existed, references
to that live path are migrated to the corresponding file beneath `doc/standards/`.
Historical ADR text remains historical evidence and is not rewritten merely to
make old decisions use the new path.

Existing ADRs whose status was `Proposed`, `Superseded`, or another historical
status notation are normalized to `Accepted`; relevant supersession or replacement
relationships remain in their narrative or decision summaries.

## Relationships to Prior Decisions

Existing accepted ADRs remain authoritative for `adrctl` architecture, public
behavior, compatibility, security boundaries, build and release contracts, and
other repository-specific decisions.  This ADR establishes a reusable
shared-standards governance layer beneath those decisions; it does not supersede
them merely because an imported standard discusses the same general subject.

This ADR specifically supersedes the ADR lifecycle sentence in ADR-018 that
required new ADRs to remain `Proposed` until separate maintainer acceptance.  It
also supersedes equivalent active process wording elsewhere in repository guidance.

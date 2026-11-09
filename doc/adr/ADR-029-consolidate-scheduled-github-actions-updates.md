# ADR-029: Consolidate Scheduled GitHub Actions Dependency Updates

Date: 2026-11-08

## Status

Accepted

## Intent and Documentation Posture

This decision adopts a lower-noise Dependabot maintenance policy for
`adrctl` based on the separately merged and observed `template-bash`
pilot.  Routine GitHub Actions version updates can be proposed together,
including major, minor, and patch releases.  The objective is fewer repeated
PR reviews while preserving independent security response, risk-based review,
and existing merge safeguards.

This ADR governs PR generation and review expectations.  It does not establish
that a dependency release is compatible or secure.

## Context and Constraints

The existing Dependabot configuration uses one GitHub Actions ecosystem at the
repository root, on a weekly schedule with a seven-day cooldown.  Its
`minor-and-patch` group explicitly excludes major releases.  Dependabot can
therefore produce a grouped minor/patch PR plus individual major-release PRs
for related workflow dependencies.  Across a portfolio, that creates duplicate
review effort and long-standing backlogs.

The `template-bash` pilot demonstrated that `groups` with a wildcard
`patterns` entry and no `update-types` restriction can produce a grouped
GitHub Actions PR.  Its observed PR bundled six non-major updates and passed
the available PR checks.  That pilot did not demonstrate a mixed-major group
or guarantee how many PRs future schedules will create.

This repository already has an auto-merge workflow using
`dependabot/fetch-metadata`.  Its condition excludes
`version-update:semver-major`.  The action documents that the output is
the highest semantic-version update in a grouped PR.  Therefore a mixed
major/minor group is expected to stay outside the current non-major
auto-merge path.

The repository's CODEOWNERS file and branch rules are separate controls:
syntax is being corrected in a separate PR, and required code-owner approval
must be independently enforced by an effective ruleset or branch protection.
This change does not grant or remove any workflow authority.

ADR-015 governs release-artifact validation; ADR-021 governs pinned build dependencies; ADR-028 governs shared coding standards and accepted ADR status.

## Decision Drivers

- Minimize repetitive routine PRs and review actions.
- Preserve explicit visibility of all dependencies updated in a group.
- Separate vulnerability response from scheduled version maintenance.
- Keep the established seven-day release cooldown.
- Preserve non-major auto-merge gating and existing repository protections.
- Require targeted evidence for major changes and write-capable actions.
- Avoid hiding new updates behind a prematurely low open-PR limit.
- Keep the change local to GitHub Actions, with no product runtime or release
  contract modification.

## Decision

### Group All Eligible Routine GitHub Actions Version Updates

The `github-actions` ecosystem SHALL retain its existing weekly schedule,
root directory, seven-day cooldown, and commit-message conventions.

One group named `actions-version-updates` SHALL match `"*"` with
`applies-to: version-updates`.  The group SHALL omit `update-types`,
making major, minor, and patch releases eligible for the same scheduled
version-update PR.

This policy SHALL NOT add a restrictive `open-pull-requests-limit`
during initial backlog cleanup.  Any later limit requires evidence that
older outstanding PRs will not suppress useful new updates.

### Keep Security Updates Independent

The new group applies only to routine version updates.  Security updates
SHALL remain outside this group and independent of its weekly cadence and
cooldown.  Dependabot security updates rely on repository-level dependency
graph, alerting, and security-update settings, which this YAML does not enable
or verify.  Maintainers must verify those settings before asserting prompt
security-update coverage.

### Preserve Merge and Review Safeguards

The existing non-major-only Dependabot auto-merge workflow SHALL remain
unchanged.  Any grouped PR whose highest SemVer change is major is expected
to be excluded from automatic merge requests by its existing condition.

A successful auto-merge workflow run is not proof that a PR was merged or
that required CODEOWNER approval is enforced.  Human or advisory review
SHALL assess the highest-risk dependency within the group, including
release workflow actions that can access credentials, write to the repository,
publish packages or containers, create tags, or modify build output.

Passing static checks does not establish compatibility for an unexercised
release, packaging, registry, or signing path.  If relevant CI evidence is
missing, request targeted validation instead of automatically approving.

### Repository-Specific Exceptions

An individual dependency MAY be excluded from the general group or given a
separate group when the exact trust boundary, behavior changes, or incomplete
test evidence justify isolation.  Exceptions should be narrow, documented,
and revisited after remediation.  Major version alone is a review signal,
not a categorical reason to generate a separate PR.

Cross-ecosystem grouping and monthly schedules are not adopted here.  They
require separately justified decisions for repositories with different
operational needs.

## Promises and Non-Promises

The configuration permits a wildcard group containing major, minor, and patch
routine GitHub Actions version updates, and preserves the prior weekly
schedule and cooldown.

It does not promise exactly one PR per week, instant replacement of existing
Dependabot PRs, successful dependency resolution for every combination,
compatibility of major updates, or absence of supply-chain compromise.
It does not change the authorization of security updates, repository
rulesets, branch protections, CODEOWNERS, or CI workflow permissions.

## Adversary and Failure Model

Relevant assets include repository source, workflow definitions, GitHub tokens,
build and test outputs, release credentials, tags, and published artifacts.
An upstream dependency can be malicious, compromised, abandoned, or incompatible.
Several simultaneous updates can obscure the root cause of a failure.  A
write-capable action can exercise more authority than a read-only linter.
A nominally passing test suite may never execute the changed release action.
A disabled security-update feature can create a separate maintenance gap.

Mitigations are existing full-SHA pinning, delayed routine version updates,
dependency-specific review within groups, the highest-major auto-merge guard,
and targeted CI evidence.  They reduce selected risks and do not prove upstream
trustworthiness.  Effective branch protection and CODEOWNER enforcement must
be checked outside this YAML.  Revisit the threat model if any future change
alters token permissions, release authority, security-update behavior, or merge
protections.

## Alternatives Considered

### Retain the Minor/Patch Group and Individual Majors

This keeps major upgrades isolated, but preserves a substantial source of
review noise.  Rejected as the default; explicit high-risk exclusions remain.

### Use Monthly Batches Immediately

May reduce PR volume further, but delays ordinary version maintenance in an
actively maintained repository.  Deferred pending portfolio usage evidence.

### Combine Security and Version Updates

Would blur advisory urgency with routine maintenance and risk delaying security
fixes.  Rejected in favor of separate trigger behavior.

### Auto-Merge Major Upgrades

Would reduce manual review, but weakens scrutiny of possible breaking changes
and higher-authority actions.  Rejected; the existing major guard remains.

### Lower the Open-PR Limit Immediately

Could prevent fresh proposals while old PRs occupy the allowance.  Deferred
until backlog reconciliation.

### Group Across Ecosystems

Could reduce additional PRs in complex repositories, but conflates runtime,
container, build, and CI changes.  Rejected as unnecessary for this
single-ecosystem adoption.

## Consequences, Compatibility, and Rollout

Routine GitHub Actions updates become eligible for one grouped review
decision.  A grouped failure may require a narrow exception or isolated test.
Reviewers must inspect all dependency changes rather than approving a batch
solely because one job is green.

This change does not modify Bash runtime behavior, product interfaces,
generated artifact formats, dependency manifests, release contracts, or
workflow permissions.  Existing Dependabot PRs are left open unless
independently verified as superseded by an actual subsequent group.
The first post-merge Dependabot run is needed to observe group generation;
a sustained reduction in review volume requires measurement over further
cycles.

## Relationships to Prior Decisions

This decision adds a repository-local CI dependency maintenance policy and
does not supersede the accepted architectural or specification contracts.

- ADR-015: Build and Release One Self-Contained adrctl Artifact
- ADR-021: Bootstrap bashdeps and Manage Build Dependencies Through a Manifest
- ADR-028: Adopt Shared Coding Standards

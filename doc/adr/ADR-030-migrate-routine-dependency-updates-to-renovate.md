# ADR-030: Migrate Routine Dependency Updates to Centrally Managed Renovate

Date: 2026-11-26

## Status

Accepted

## Decision

The repository SHALL enroll in the already-operational, centrally managed
Jenkins Renovate service through a root `renovate.json` containing its
schema declaration.  GitHub Actions scheduled Dependabot version-update PRs
SHALL be disabled with `open-pull-requests-limit: 0` on the existing
ecosystem entry.  Existing registry, grouping, cooldown, schedule, and
commit-message configuration SHALL otherwise be preserved in place.

Dependabot vulnerability alerts, dependency graph, and security updates
SHALL remain independent of scheduled version updates.  The existing
`dependabot[bot]`-scoped, non-major auto-merge workflow SHALL be retained for
security-related Dependabot PRs.  Renovate SHALL NOT be exempted from
branch protections, required checks, or CODEOWNERS approval.

**This ADR supersedes ADR-029's selection of Dependabot as the active
scheduled routine-update provider, its active weekly grouping policy,
and its explicit rejection of a low open-pull-requests limit.**  ADR-029's
threat-modeling, review, and security-update separation commitments remain
applicable to dependency updates regardless of provider.  Its historical
decision record remains intact.

## Context and Constraints

The earlier grouped Dependabot approach reduced repetitive maintenance PRs
but still duplicates dependency scheduling and PR lifecycle management across
repositories.  A Jenkins-run Renovate service now supplies centralized
policy, scheduling, signed changes, and native platform auto-merge under
existing human review controls.  Repository enrollment is deliberately
explicit; an autodiscovery pattern alone is insufficient.

The existing SHA-pinned GitHub Actions and pinned, SHA-256-verified build
dependencies under ADR-021 and ADR-022 are trust boundaries.  Comment-only
version annotation corrections SHALL leave executable immutable references
and dependency manifest hashes untouched.  Imported shared coding standards
are maintained upstream and SHALL NOT be edited locally for this migration.

## Assumptions and Operational Dependencies

- Jenkins Renovate already discovers `wesley-dean/*`; this decision does
  not modify that service or introduce repository-specific CI.
- The Renovate machine account requires accepted collaborator write access
  and must not bypass code-owner review or required checks.
- GitHub Dependabot alerts and security updates are separately enabled.
  Their existence or operation is not established by this YAML file.
- Native auto-merge must respect the repository's effective protection rules.

These assumptions require independent verification after merge.

## Alternatives Considered

### Continue routine Dependabot updates

Rejected because it duplicates central Renovate administration and PR
generation.

### Delete Dependabot configuration completely

Rejected in favor of preserving ecosystem metadata, security update
separation, and reversible history.

### Add per-repository Renovate Actions and secrets

Rejected due to maintenance and privilege overhead across repositories.

### Extend Dependabot's auto-merge workflow to Renovate

Rejected; it is intentionally identity-scoped, and security Dependabot PRs
still require their existing independent handling.

### Replace SHA pins with floating release tags

Rejected because this weakens a deliberate supply-chain trust control.
A comment naming a tag SHALL be verified against the actual pinned commit
before normalization.

## Consequences and Rollout

Configuration changes do not modify Bash interfaces, build artifacts,
runtime dependencies, or release behavior.  A migration PR includes this
decision, an updated decision summary, a README maintenance explanation,
the root Renovate enrollment, and the disabled routine Dependabot limit.

Routine Dependabot PRs SHALL remain open until the migration is merged and
effective.  After merge they may be closed with an explicit explanatory
comment linking the migration, unless a PR contains security remediation or
substantive human edits that Renovate would not reproduce.

The migration is not operationally complete until the machine account has
write permission and the runner creates or processes updates successfully.
Repository protections and security settings must be independently checked.

## Threats, Tradeoffs, and Mitigations

Renovate acquires branch/PR write authority.  A compromised machine account,
upstream action, or registry artifact could affect CI or publishing.  Grouped
dependency changes may conceal regressions.  Preserve immutable commit
references, signed commits, least privilege, required code-owner approval,
CI gates, and targeted review of privileged release actions.  Do not guess
unverifiable tags; report exceptions.  Security advisories remain handled
independently by Dependabot.

## Relationships

- ADR-015 and ADR-022: Verified generated distribution and release pipeline.
- ADR-021: Verified, manifest-controlled build dependencies.
- ADR-028: Shared coding standards and repository decision authority.
- ADR-029: Earlier grouped Dependabot policy, partially superseded here.

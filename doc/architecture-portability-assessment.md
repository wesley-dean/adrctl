# adrctl Architecture Portability Assessment

## Status and purpose

This document evaluates product-architecture decisions from
`wesley-dean/bootstrap` and `wesley-dean/mktext` for applicability to `adrctl`.
It is separate from `doc/bootstrap-framework-inventory.md`, which evaluates the
reusable project framework.

The assessment also identifies decisions that are unique to `adrctl` and records
material conflicts discovered while checking the compatibility assumptions
against the canonical upstream `npryce/adr-tools` implementation.

This is a working assessment, not an accepted architecture.  New `adrctl` ADRs
remain `Proposed` until explicit maintainer acceptance.

## Classification model

The product-architecture classifications are:

- **Relevant as-is** - the decision can be adopted without changing its
  architectural substance.
- **Relevant with modification** - the underlying concern applies, but the
  decision must be adapted to `adrctl` requirements or compatibility.
- **Not relevant** - the decision addresses product behavior that `adrctl` does
  not own or require.
- **Unique to adrctl** - the project requires an architectural decision that is
  not adequately established by the Bootstrap or `mktext` ADR corpus.

A decision may be relevant without deserving a one-for-one copied ADR.  Several
related source ADRs may be consolidated into one coherent `adrctl` decision when
their rationale and consequences are inseparable in this product.

## Primary conclusions

The source review supports the following high-level direction:

1. `adrctl` should retain Bootstrap's compatibility, inspectability,
   deterministic-behavior, small-core, documentation, release, and testing
   principles.
2. `adrctl` should not inherit Bootstrap's package-manager domain model,
   immutable Action Record pipeline, backend interface, or package-specific
   execution controls merely because they exist in the reference project.
3. `adrctl` is substantially larger than `mktext`; modular maintained Bash
   source feeding one generated executable is currently the strongest source
   organization candidate.
4. `mktext` should remain a narrow rendering dependency.  `adrctl` owns ADR
   semantics, value acquisition, transformation, project discovery, filesystem
   operations, and policy.
5. Existing `adr-tools` behavior is an additional compatibility authority.  A
   design that is elegant relative to Bootstrap but breaks established ADR-tool
   behavior without reason is not a successful port.
6. Two handoff assumptions require explicit resolution before the ADR corpus can
   be finalized: literal `adr` command compatibility and legacy template
   compatibility with `mktext`.

## Bootstrap ADR assessment

### ADR-000 - Capability Scope, Epistemic Honesty, and Separation of Concerns

**Classification: Relevant as-is.**

This ADR is already present as accepted `adrctl` ADR-000.  It should remain the
foundational record and should not be duplicated or renumbered.

### ADR-001 - Use Bash as the Bootstrap Entry Point

**Classification: Relevant with modification.**

The low-friction, inspectable Bash rationale applies, but `adrctl` targets Bash
4.3+ rather than Bootstrap's Bash 5+ and is a normal command-line product rather
than a remote first-run bootstrap entry point.  The decision should be combined
with the dependency/runtime decision informed by `mktext` ADR-002.

### ADR-002 - Describe Desired State Rather Than Installation Procedures

**Classification: Not relevant.**

This is a package-provisioning product decision.  `adrctl` exposes explicit
operations on ADR artifacts rather than a desired-state package manifest.

### ADR-003 - Treat Native Package Managers as the Source of Truth

**Classification: Not relevant.**

`adrctl` does not manage operating-system packages.  Delegation boundaries for
Git, `mktext`, editors, pagers, Graphviz, and filesystem operations are distinct
`adrctl` concerns and should be documented directly.

### ADR-004 - Separate the Bootstrap Engine from User Intent

**Classification: Relevant with modification.**

The separation between mechanism and user-owned policy applies strongly.
`adrctl` should manage ADR mechanics without deciding the content of a user's
architectural decisions.  Templates and project configuration express user
intent; `adrctl` interprets only the documented mechanics needed to operate on
those artifacts.

### ADR-005 - Design Around Progressive Adoption

**Classification: Relevant with modification.**

Progressive adoption maps directly to the compatibility strategy: legacy
`.adr-dir`, existing templates, established filename behavior, and existing
commands remain usable while newer configuration and rendering capabilities are
introduced deliberately.

### ADR-006 - Preserve a Stable Bootstrap Interface While Allowing Internal Evolution

**Classification: Relevant with modification.**

The principle is central to the rewrite.  `adrctl` should permit major internal
restructuring while treating CLI behavior, configuration, templates, filenames,
filesystem effects, diagnostics, and exit statuses as compatibility surfaces.

### ADR-007 - Prefer Inspectable and Reviewable Bootstrap Execution

**Classification: Not relevant as a standalone product decision.**

The ADR primarily concerns downloading and executing a privileged remote
bootstrap script.  `adrctl` should still be inspectable, but that broader concern
is better represented by ADR-027 and the single-artifact/release decisions.

### ADR-008 - Define a Human-Centered Package Manifest Format

**Classification: Not relevant.**

The package manifest language is domain-specific.  `adrctl` configuration,
template syntax, and ADR document interpretation need their own compatibility
contracts rather than a renamed package-manifest ADR.

### ADR-009 - Distribute the Engine as a Single Executable Script

**Classification: Relevant with modification.**

`adrctl` has an explicit one-executable product goal.  The generated artifact
should be the consumer surface while maintained source remains organized for
contributors.

### ADR-010 - Build the Distribution Artifact from Modular Source Files

**Classification: Relevant with modification.**

Current `adrctl` responsibilities are broad enough to justify modular maintained
source unless implementation evidence later proves otherwise.  Module
boundaries, assembly ordering, and registration are `adrctl` design questions.
The current Bootstrap Makefile enumerates its source files explicitly; it should
not be cited as evidence for an automatic plugin-discovery requirement.

### ADR-011 - Publish Release Artifacts Through GitHub Releases

**Classification: Relevant with modification.**

GitHub Releases should publish the generated `adrctl` executable and verification
material rather than presenting a maintained source file as the canonical
runtime artifact.

### ADR-012 - Use Make as the Local and CI Orchestration Interface

**Classification: Relevant with modification.**

The product should adopt the stable Make lifecycle described in the framework
inventory.  Exact targets and inputs change with the `adrctl` source and
compatibility-test architecture.

### ADR-013 - Fail Conservatively and Avoid Surprising System Changes

**Classification: Relevant with modification.**

For `adrctl`, the protected state is the user's ADR repository and related files.
Validation failures should occur before avoidable mutations, and partial updates
should not be accepted merely because legacy scripts happened to make them
possible.

### ADR-014 - Separate Manifest Parsing from Package Installation

**Classification: Relevant with modification.**

The domain-specific parser/installer split does not carry over, but the safety
boundary does.  `adrctl` should parse and validate command intent, configuration,
references, templates, and target paths before beginning the corresponding
filesystem mutation when practical.

### ADR-015 - Perform a Planning Phase Before Making System Changes

**Classification: Relevant with modification.**

Commands that can modify multiple ADR files, especially linking and superseding
operations, need a complete preflight view before mutation.  This does not imply
that `adrctl` needs Bootstrap's planner/resolver object model.  A smaller
validated change-set abstraction may be sufficient.

### ADR-016 - Provide Dry-Run and Explain Modes for Planned Changes

**Classification: Not relevant to the initial architecture.**

No current `adrctl` requirement calls for these modes.  Adding them would expand
the public CLI and test matrix.  They can be proposed later if a concrete ADR
workflow benefits from them; Bootstrap's existence alone is not justification.

### ADR-017 - Delegate Package Operations to Native Package Managers

**Classification: Not relevant.**

The package-manager decision does not apply.  `adrctl` does require clear
responsibility boundaries with `mktext`, Git, external editors/viewers, and
Graphviz, which are unique project decisions.

### ADR-018 - Define a Stable Manifest Grammar

**Classification: Not relevant as a direct port.**

`adrctl` has no package-manifest grammar.  Stable configuration, template, ADR
reference, and filename semantics must be defined directly in the `adrctl`
specification and ADRs.

### ADR-019 - Define Stable Version Constraint Semantics

**Classification: Not relevant.**

This is package-version behavior.

### ADR-020 - Provide Human-Centered Diagnostics

**Classification: Relevant with modification.**

Diagnostics should identify what failed, where applicable, why the operation
stopped, and what the user can do next.  For `adrctl`, useful provenance may
include project root, ADR path, referenced ADR, template/config path, and command
phase rather than package-manifest line numbers.

### ADR-021 - Layer the Engine Around Well-Defined Responsibilities

**Classification: Relevant with modification.**

Layering applies, but `adrctl` responsibilities differ.  Likely boundaries
include CLI dispatch, configuration/root discovery, ADR lookup and parsing,
render-context construction, rendering, change preparation, mutation, and
reporting.  The final boundaries should be justified by the product rather than
copied from Bootstrap's package pipeline.

### ADR-022 - Define a Stable Package Backend Interface

**Classification: Not relevant.**

`adrctl` has no package backends.

### ADR-023 - Prefer Explicit Configuration Over Implicit Discovery

**Classification: Relevant with modification and deliberate divergence.**

The configuration-precedence and parsed-data principles apply.  Bootstrap's
explicit rejection of parent-directory discovery does not: canonical
`adr-tools` already walks upward for `.adr-dir` or `doc/adr`, and the `adrctl`
handoff requires an explicit project-root model with upward configuration
search, Git fallback, and cwd fallback.

This divergence must be documented rather than described as though Bootstrap
made the same discovery choice.

### ADR-024 - Provide a Stable and Explicit Command-Line Interface

**Classification: Relevant with modification.**

`adrctl` needs a stable CLI, but compatibility requires preserving the established
`adr-tools` subcommand model rather than adopting Bootstrap's no-subcommand CLI.
New flags and commands should remain orthogonal and deliberate.

### ADR-025 - Provide Human-Centered Logging with Progressive Levels of Detail

**Classification: Relevant with modification.**

Stable standard-stream and diagnostic roles matter.  Routine progress/verbosity
features should not be imported automatically into a tool whose operations are
normally short.  The eventual decision should preserve script-friendly stdout
contracts and keep diagnostics on stderr.

### ADR-026 - Define a Stable Exit Code Philosophy

**Classification: Relevant with modification.**

Exit statuses are a machine-facing public interface.  `adrctl` needs a small,
stable vocabulary aligned with existing behavior where compatibility matters and
with distinct failure categories only where callers can act on the distinction.

### ADR-027 - Establish Trust Through Inspectability

**Classification: Relevant with modification.**

One readable generated Bash artifact, traceable release metadata, explainable
filesystem behavior, and documentation of external dependencies support the
same trust objective without Bootstrap's privileged package-management context.

### ADR-028 - Favor the Principle of Least Surprise

**Classification: Relevant with modification.**

This principle is especially important for a compatibility-oriented rewrite.
Existing valid workflows should continue to behave as users expect unless an
intentional, documented correction provides enough value to justify deviation.

### ADR-029 - Ensure Reproducible and Verifiable Releases

**Classification: Relevant with modification.**

Use source-revision metadata, checksums, provenance attestation, and validation of
the exact executable being released.  `mktext` reinforces the need to avoid
stale generated metadata when Make inputs change.

### ADR-030 - Preserve Stable Public Interfaces

**Classification: Relevant with modification.**

The relevant public surface is broader than Bootstrap's: existing `adr-tools`
subcommands, templates, filenames, project discovery, editor/pager integration,
generated output, exit behavior, and filesystem changes are potential inherited
contracts in addition to new `adrctl` interfaces.

### ADR-031 - Adopt Semantic Versioning and Deliberate Compatibility

**Classification: Relevant with modification.**

Semantic Versioning should communicate compatibility impact.  The pre-1.0 policy
and the extent of compatibility promised to `adr-tools` require explicit
`adrctl` wording.

### ADR-033 - Prefer Composition Over Special Cases

**Classification: Relevant with modification.**

Shared lookup, rendering, mutation, and reporting mechanisms should compose
across commands rather than accumulate command-specific exceptions.  Legacy
compatibility adapters are acceptable when they are explicit compatibility
boundaries rather than hidden special cases.

### ADR-034 - Keep the Core Engine Small

**Classification: Relevant with modification.**

The responsibility boundary should prevent `adrctl` from becoming a general
Markdown processor, template engine, Git porcelain replacement, editor, graph
renderer, or project-management system.

### ADR-035 - Prefer Data Over Code

**Classification: Relevant with modification.**

Configuration and templates must be parsed as data, never sourced or evaluated
as shell code.  This is particularly important because legacy `adr-tools` uses
`eval` around generated configuration; preserving observable compatibility does
not require preserving that unsafe implementation mechanism.

### ADR-036 - Make Architectural Decisions Explicit

**Classification: Relevant with modification.**

Significant `adrctl` decisions should be durable ADRs, old accepted decisions
should remain historical records, and later changes should supersede rather than
rewrite architectural history.

### ADR-037 - Establish a Deliberate Deprecation Policy

**Classification: Relevant with modification.**

This is central to `.adr-dir`, legacy templates, and other migration surfaces.
Modernization should be encouraged with clear guidance while existing supported
behavior remains functional through the documented compatibility window.

### ADR-038 - Introduce Experimental Features Deliberately

**Classification: Relevant with modification.**

The governance principle is useful even if the initial rewrite exposes no
experimental features.  Experimental behavior should be explicit and should not
quietly become part of the stable compatibility surface.

### ADR-039 - Test Observable Behavior Rather Than Implementation

**Classification: Relevant with modification.**

This is foundational to the compatibility corpus.  Tests should exercise public
commands, outputs, status codes, files, templates, and direct execution of the
generated artifact rather than private Bash helper structure.

### ADR-040 - Prefer Deterministic Behavior

**Classification: Relevant with modification.**

Given the same project state, command, configuration, and relevant external
inputs, `adrctl` should make the same decisions.  Deliberate sources of changing
state such as the current date must be explicit and testable.

### ADR-041 - Treat Documentation as Part of the Product

**Classification: Relevant with modification.**

README, AGENTS, ADRs, normative specification, source documentation, generated
reference documentation, migration guidance, and compatibility notes are all
release-relevant product artifacts.

### ADR-042 - Minimize the Trusted Computing Base

**Classification: Relevant with modification.**

Prefer Bash builtins when they are clear and safe, use ordinary Unix tools where
they are the appropriate mechanism, keep `mktext` pinned and inspectable, and
make feature-specific dependencies such as Graphviz optional rather than core
runtime dependencies.

### ADR-043 - Favor Stable Concepts Over Clever Implementations

**Classification: Relevant with modification.**

Project root, ADR reference, template context, change set, and compatibility mode
should be explainable concepts.  Compact Bash tricks should not obscure those
concepts.

### ADR-044 - Optimize for the Next Contributor

**Classification: Relevant with modification.**

The repository should be understandable without reconstructing the current
conversation.  ADRs, `AGENTS.md`, the behavioral specification, source comments,
and conventional project lifecycle all support that goal.

### ADR-045 - Documentation-First Source Code Commenting Standard

**Classification: Relevant as-is.**

The ADR is deliberately project-agnostic and was ported unchanged in substance
to `mktext` as ADR-011.  `adrctl` should adopt the same standard with a provenance
note and a fresh project ADR number.

### ADR-046 - Adopt Documentation-Driven, Test-Second Development

**Classification: Relevant as-is.**

The accepted `mktext` version confirms the intended operating model:
documentation/architecture first, smallest correct implementation second,
observable-behavior tests immediately afterward, then full validation and diff
review.  Tests may be written first when useful, but tests are not the primary
record of intent.

This supplement-backed model supersedes any earlier handoff wording that could be
read as mandating tests before every implementation change.

### ADR-047 - Represent Planned Operations as Immutable Action Records

**Classification: Not relevant to the initial architecture.**

`adrctl` may benefit from a validated change set for multi-file operations, but
there is no demonstrated need for Bootstrap's Action Record -> Resolved Action
pipeline.  Importing it now would be architecture by analogy rather than by
requirement.

### ADR-048 - Execution SHALL Consume Only Resolved Actions

**Classification: Not relevant.**

This decision depends on Bootstrap's planner/resolver/executor model, which is not
currently justified for `adrctl`.

### ADR-049 - Preflight All Manifests Before Execution

**Classification: Not relevant as a direct port.**

`adrctl` has no multi-manifest package run.  Its useful safety principle is
already captured by the adapted ADR-013/014/015 concerns: validate the complete
scope of a multi-file ADR change before mutating files.

### ADR-050 - Bound Package Installation and Report Progress

**Classification: Not relevant.**

The decision addresses potentially blocking package-manager installation and
package-level progress.  No comparable core `adrctl` operation has been
identified.  External editor, pager, or Graphviz process behavior can be
specified if concrete blocking/failure requirements justify it.

## mktext ADR assessment

`mktext` serves two roles in this analysis: it is a completed small-project
adaptation of the Bootstrap framework, and it is an intended `adrctl` dependency.
The classifications below answer whether its architectural substance should be
represented in `adrctl`, not whether `adrctl` should duplicate `mktext` internals.

### mktext ADR-000 - Capability Scope, Epistemic Honesty, and Separation of Concerns

**Classification: Relevant as-is.**

This is the same project-agnostic ADR already accepted as `adrctl` ADR-000.

### mktext ADR-001 - Define mktext Scope and the Caller Boundary

**Classification: Relevant as-is as a dependency boundary.**

`adrctl` must honor this boundary.  `mktext` renders names to literal values;
`adrctl` owns dates, numbers, slugification, Git/filesystem queries, ADR semantics,
project discovery, and all other acquisition or transformation.

### mktext ADR-002 - Require Bash 4.3+ and Minimize Runtime Dependencies

**Classification: Relevant with modification.**

The same Bash 4.3 floor is already required by the `adrctl` handoff and avoids a
runtime-version mismatch with the embedded/sourceable dependency.  Unlike
`mktext`, `adrctl` has legitimate domain reasons to invoke some external tools,
including Git and optional feature-specific utilities.

### mktext ADR-003 - Expose One Stable Function and Associative-Array Contexts

**Classification: Not a port candidate; relevant integration contract.**

`adrctl` should consume the documented `mktext` API rather than reproduce it as
its own public API.  Associative-array contexts are useful internally for passing
prepared values to rendering.

### mktext ADR-004 - Define Key and Macro Grammar

**Classification: Not a port candidate; material integration constraint.**

The `{KEY}` grammar constrains new `mktext`-rendered templates and filenames.
It also exposes a direct compatibility conflict with legacy `adr-tools` templates,
which use unbraced tokens such as `TITLE`, `STATUS`, `NUMBER`, and `DATE`.

### mktext ADR-005 - Render Lexically, Literally, and Non-Recursively

**Classification: Not a port candidate; relevant dependency semantics.**

These security and determinism guarantees are desirable for new rendering
surfaces.  They are not automatically identical to legacy `adr-tools` `sed`
substitution semantics, so `adrctl` must define the compatibility boundary.

### mktext ADR-006 - Stream STDIN to STDOUT and Preserve Line Termination

**Classification: Not a port candidate; relevant integration contract.**

`adrctl` can feed template content through the sourceable renderer without asking
`mktext` to own filenames or project paths.

### mktext ADR-007 - Define Diagnostics and Return-Status Semantics

**Classification: Not a port candidate; relevant integration contract.**

`adrctl` must handle `mktext` failures correctly, but it need not expose
`mktext`'s numeric status vocabulary as its own CLI status contract.

### mktext ADR-008 - Release One Versioned Sourceable Artifact

**Classification: Relevant with modification.**

This ADR is the key dependency-acquisition precedent.  `adrctl` should consume a
specific versioned `mktext` artifact rather than a moving branch.  How that
artifact is fetched, verified, and incorporated into the generated `adrctl`
executable requires an `adrctl` decision.

### mktext ADR-009 - Use Make and Test Observable Behavior

**Classification: Relevant with modification.**

The Make and exact-artifact testing model is directly useful.  `adrctl` needs a
larger compatibility and filesystem-behavior test surface, but the same
orchestration principles apply.

### mktext ADR-010 - Adopt Documentation-Driven, Test-Second Development

**Classification: Relevant as-is.**

This is the same development model selected by Bootstrap ADR-046 and the project
supplement.

### mktext ADR-011 - Documentation-First Source Code Commenting Standard

**Classification: Relevant as-is.**

This is the accepted `mktext` port of Bootstrap ADR-045 and should be carried into
`adrctl` with provenance.

### mktext ADR-012 - Treat Documentation and Architectural Context as Product Artifacts

**Classification: Relevant with modification.**

The division of roles among README, AGENTS, ADRs, normative specification, and
source comments is directly useful.  `adrctl` additionally has migration and
compatibility documentation that `mktext` does not require.

## Canonical adr-tools compatibility evidence

The compatibility goal was checked against `npryce/adr-tools`, not inferred from
memory.

Important observations include:

- the public executable is `adr`, whose first argument selects a subcommand;
- subcommands are separate executable `adr-*` scripts discovered by filename;
- `adr new` generates four-digit filenames by default;
- the default ADR number exposed to the template is unpadded while the filename
  number is zero-padded;
- `adr new` derives a lowercase alphanumeric/hyphen slug from the title;
- `ADR_DATE` may override the default ISO-style current date;
- `VISUAL` then `EDITOR` controls opening the created ADR;
- a successful `adr new` prints the created ADR filename to stdout;
- `.adr-dir` and `doc/adr` are discovered by walking upward from the current
  directory;
- project-specific templates use bare `TITLE`, `STATUS`, `NUMBER`, and `DATE`
  tokens;
- legacy template substitution is performed with sequential `sed` substitutions,
  not the braced `mktext` grammar;
- link/supersede operations can mutate the new ADR and existing ADRs in one
  command;
- legacy configuration scripts use shell evaluation internally, an
  implementation mechanism that should not be preserved when safe data parsing
  can preserve the external behavior.

These observations are compatibility inputs, not endorsements of every legacy
implementation detail.

## Decisions unique to adrctl

The following topics require `adrctl`-specific decisions.  Related topics may be
combined into fewer ADRs after the unresolved questions are settled.

### Product identity and compatibility boundary

Define precisely what "drop-in-compatible superset" means now that the native
executable is named `adrctl` while the canonical predecessor executable is
`adr`.

The decision must distinguish command semantics from executable-path identity and
must state whether an `adr` shim, symlink, alias, or other compatibility surface
is part of the product.

### Subcommand architecture and extension boundary

Preserve the established command concepts while deciding whether the predecessor's
dynamic discovery of arbitrary executable `adr-*` scripts is a compatibility
contract or merely an implementation detail.

Current evidence does not justify a general plugin system in the new single-file
product.  Adding one should require an explicit use case.

### Bash 4.3 runtime and dependency policy

Adopt the documented Bash 4.3 minimum and define which external commands are core,
optional, build-only, or delegated domain dependencies.

### Project root and project discovery

Define `PROJECT_ROOT`, explicit overrides, upward discovery, Git-root fallback,
and cwd fallback while preserving the useful predecessor behavior of running
commands from nested project directories.

### Configuration file identity and precedence

Define the project configuration filename/marker, `ADRCTL_` namespacing, parsed
`.env`-style grammar, unknown-key behavior, and precedence:

```text
built-in defaults
    -> configuration file
    -> environment
    -> CLI
```

A generic `.env` creates a discovery ambiguity because many repositories contain
an unrelated `.env`.  Root discovery must not stop at an unrelated file merely
because it has that generic filename.

### Legacy .adr-dir compatibility and migration

Define when `.adr-dir` is consulted, how it interacts with the new configuration
file, what migration guidance is printed, and whether an automated migration
command is part of the initial product.

### Project-relative path semantics

Define how configured ADR/template paths resolve against `PROJECT_ROOT` while
preserving ordinary Unix absolute-path semantics for leading `/`.

### Legacy and modern template rendering

Resolve the conflict between legacy unbraced `adr-tools` template tokens and the
braced `mktext` grammar.

A compatibility solution must preserve existing valid templates without
weakening `mktext`'s deliberately narrow semantics or pretending the two
renderers already implement the same language.

### mktext acquisition, verification, and embedding

Define the pinned `mktext` version/artifact, build-time verification, update
process, and how the dependency is incorporated into the generated `adrctl`
executable without creating an undeclared runtime network dependency.

### Rendering-context ownership

Define the values `adrctl` prepares for body and filename templates, including
number forms, title, slug, status, date, project root, and later additions.
`mktext` substitutes values; `adrctl` owns their meaning and derivation.

### Filename, numbering, slug, date, and default-status compatibility

Specify the predecessor behavior precisely before extending it.  New filename
patterns should be opt-in when changing the default would break established
repositories or automation.

### ADR lookup and Markdown mutation semantics

Define how numeric/partial references resolve and how `adrctl` recognizes titles,
statuses, and links in Markdown without accidentally becoming a general Markdown
parser.

This decision is required for `link`, supersede behavior, table-of-contents
generation, graph generation, and compatibility with existing ADR documents.

### Filesystem preflight and multi-file mutation safety

Define the validation boundary for commands that create or modify more than one
file.  The recommended direction is to validate all referenced ADRs, target
paths, templates, and intended changes before the first mutation, then use atomic
file replacement where practical.

Preserving successful legacy behavior does not require preserving avoidable
partial writes on failure.

### Git responsibility boundary

Define when Git is used for project-root discovery or metadata and whether any ADR
mutation operation should invoke Git automatically.  Git should not become an
implicit owner of filesystem state unless compatibility evidence requires it.

### Editor, pager, and viewer boundary

Define compatibility for `VISUAL`, `EDITOR`, `ADR_PAGER`, `PAGER`, and any future
viewer behavior.  External programs own their own interactive behavior; `adrctl`
owns selection, invocation, diagnostics, and exit propagation where specified.

### Graphviz boundary

Preserve graph generation while treating Graphviz, if required for a particular
output form, as a feature-specific optional dependency rather than a core runtime
requirement.

### Public standard streams and exit statuses

Specify command-by-command stdout, stderr, and exit behavior.  Script-facing
outputs such as the filename printed by `adr new` must not be polluted by routine
diagnostics.

### Compatibility corpus and milestone policy

Define the canonical predecessor revision/release used as the baseline, fixture
strategy, behavior categories, and the rule that the first implementation
milestone reproduces existing supported behavior before optional enhancements
change the surface.

### Generated artifact identity and version output

Define the generated executable path/name, interpreter line, executable mode,
version/build metadata, checksum, provenance, and literal direct-execution tests.

### Concurrent ADR-number allocation

The predecessor computes the next number by scanning existing filenames and then
creates the new file.  Concurrent writers can therefore select the same number.
`adrctl` should decide whether concurrency remains outside the supported model or
whether number allocation needs a locking/atomic-creation policy.  This should
not be "fixed" incidentally because locking can add portability and dependency
costs.

## Material architecture questions to resolve before drafting the ADR set

### 1. What does command compatibility mean after renaming the executable?

The handoff says valid existing `adr-tools` commands should remain valid whenever
practical, while the selected product identity says the single executable is
`adrctl`.

Those statements conflict if "command" includes the literal executable name.
The architecture should explicitly choose between:

- semantic compatibility after replacing `adr` with `adrctl`;
- an additional `adr` compatibility entry point; or
- another precisely defined migration surface.

### 2. How should legacy templates coexist with mktext templates?

Direct delegation cannot preserve legacy templates because the grammars differ.
The strongest current recommendation is two explicit rendering contracts:

- a legacy body-template compatibility renderer that preserves established
  unbraced-token behavior; and
- `mktext` for new, explicitly selected braced template and filename rendering.

This keeps old repositories working and keeps the `mktext` language honest.
A different compatibility adapter is possible, but it must be demonstrated
against the predecessor corpus rather than assumed equivalent.

### 3. What file should identify adrctl project configuration during upward discovery?

Using a generic `.env` as an ancestor marker can select an unrelated application
configuration file.  Viable approaches include:

- a dedicated `adrctl` configuration filename;
- treating `.env` as an `adrctl` marker only when it contains recognized
  `ADRCTL_` directives;
- using `.adr-dir`/Git to establish root first and reading `.env` only at that
  resolved root; or
- another explicit marker with compatibility rules.

The original handoff's plain "nearest ancestor containing `.env`" rule should not
be implemented literally without resolving this collision risk.

### 4. Does adrctl intentionally support third-party subcommand/plugin discovery?

The predecessor discovers executable `adr-*` scripts.  The original handoff also
mentions automatic module/plugin discovery, but the current Bootstrap build
explicitly enumerates its maintained source files and `mktext` explicitly rejects
plugin discovery.

The current recommendation is an explicit internal subcommand set in one
generated executable, with no plugin system in the initial release.  If external
`adr-*` extension is considered part of the compatibility contract, that changes
the architecture materially and should be decided now.

### 5. May adrctl strengthen failure atomicity relative to adr-tools?

Legacy multi-file commands perform sequential writes.  The current recommendation
is to preserve successful outputs while improving the failure boundary through
preflight and atomic replacement where practical.

If byte-for-byte/step-for-step legacy failure behavior is considered part of the
compatibility contract, that recommendation would have to change.  The handoff's
stated safety and maintainability goals suggest that successful-workflow
compatibility, rather than preservation of accidental partial failures, is the
better contract.

## Recommended next step

Resolve the five material questions above.  Once resolved, the next coherent
artifact should be a proposed `adrctl` ADR map that:

1. consolidates the relevant Bootstrap principles;
2. records the `mktext` dependency boundary;
3. captures the unique `adrctl` decisions;
4. preserves lightweight source-ADR provenance;
5. assigns fresh project ADR numbers beginning after existing `ADR-000`; and
6. leaves every new ADR in `Proposed` state pending explicit maintainer
   acceptance.

The normative behavioral specification should follow the Proposed ADR set and
serve as the single current contract against which the compatibility corpus and
implementation are tested.
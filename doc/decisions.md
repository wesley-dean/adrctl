# Architecture Decision Summary

This document provides a concise map of the architectural decisions that govern
`adrctl`.  It is an orientation aid rather than a substitute for the full ADRs;
when this summary and an ADR differ, the ADR is authoritative.

## ADR-000 - Capability Scope, Epistemic Honesty, and Separation of Concerns

The project treats accuracy, explicit capability boundaries, evidence, and
separation of concerns as foundational engineering requirements.  Assistance and
automation must not substitute agreement, appearance of helpfulness, or hidden
scope expansion for correctness.  See
[ADR-000](adr/ADR-000-capability-scope-and-epistemic-honesty.md).

## ADR-001 - Select Template Delimiters Automatically with Explicit Overrides

`adrctl` uses `mktext` as its single body-template renderer while preserving both
legacy bare-token and modern braced-token templates.  Explicit delimiter settings
win over conservative automatic detection, and filename rendering remains a
separate braced-token surface.  See
[ADR-001](adr/ADR-001-select-template-delimiters-automatically-with-explicit-overrides.md).

## ADR-002 - Support adr as a Symlink-Compatible Invocation Name

The canonical product identity is `adrctl`, while an `adr` filesystem symlink is a
supported compatibility invocation.  Both names use the same implementation and
behavior; the invocation basename may affect human-facing presentation without
creating a separate runtime mode.  See
[ADR-002](adr/ADR-002-support-adr-as-a-symlink-compatible-invocation-name.md).

## ADR-003 - Pin, Verify, and Embed mktext as a Build Dependency

`mktext` is consumed as a pinned, SHA-256-verified build dependency rather than a
separately installed runtime requirement.  Its released artifact is incorporated
into the generated `adrctl` executable while preserving a single effective
product entrypoint and no runtime network dependency.  See
[ADR-003](adr/ADR-003-pin-verify-and-embed-mktext-as-a-build-dependency.md).

## ADR-004 - Continue Using CC0 for adrctl

The repository deliberately retains the CC0 1.0 Universal dedication for
independently authored `adrctl` source.  Compatibility work may inspect the
GPL-covered predecessor as behavioral evidence, but production implementation is
not copied, translated, or mechanically adapted from that source.  See
[ADR-004](adr/ADR-004-continue-using-cc0-for-adrctl.md).

## ADR-005 - Discover Project Context with Recognized Markers

Existing-project commands discover context through explicit root overrides,
recognized nearest ancestor markers, Git-root fallback, and finally the current
working directory.  `.adr-dir` remains supported, qualifying `.env` files claim
context through the `ADRCTL_` namespace, and `init` intentionally defaults to the
current directory.  See
[ADR-005](adr/ADR-005-discover-project-context-with-recognized-markers.md).

## ADR-006 - Keep Subcommands Internal to the Generated Artifact

Supported subcommands are implemented inside the repository and assembled into
the generated executable.  Runtime discovery of arbitrary external `adr-*` or
`adrctl-*` plugins is excluded so command availability, trust, release, and test
surfaces remain deterministic.  See
[ADR-006](adr/ADR-006-keep-subcommands-internal-to-the-generated-artifact.md).

## ADR-007 - Preflight Multi-File Mutations Before Writing

Operations that can affect multiple ADR files validate the complete intended
change as far as practical before the first persistent mutation.  Existing files
use atomic per-file replacement where practical, while the project deliberately
does not promise a general cross-file transaction or rollback system.  See
[ADR-007](adr/ADR-007-preflight-multi-file-mutations-before-writing.md).

## ADR-008 - Require Bash 4.3+ and Classify Runtime Dependencies

Bash 4.3 or newer is the minimum runtime, matching the language features required
by the embedded renderer contract.  External commands are classified as core,
feature-specific, build-only, or development/documentation dependencies so tools
used during development do not silently become runtime requirements.  See
[ADR-008](adr/ADR-008-require-bash-4-3-and-classify-runtime-dependencies.md).

## ADR-009 - Parse Project Configuration as Data with Explicit Precedence

Project `.env` configuration is parsed as inert data rather than sourced or
evaluated shell code.  Namespaced `ADRCTL_` settings have explicit precedence,
unknown namespaced keys fail visibly, and project-relative paths resolve from the
selected project root.  See
[ADR-009](adr/ADR-009-parse-project-configuration-as-data-with-explicit-precedence.md).

## ADR-010 - Own ADR Values and Preserve Compatible Default Filenames

`adrctl` owns ADR-specific render values such as numbers, titles, slugs, dates,
statuses, and paths, while `mktext` performs textual substitution only.  The
default filename remains compatible with the established four-digit numbered
form, and custom filename patterns are explicit project choices.  See
[ADR-010](adr/ADR-010-own-adr-values-and-preserve-compatible-default-filenames.md).

## ADR-011 - Resolve ADR References Unambiguously and Mutate Bounded Markdown

ADR reference resolution gathers candidates and fails on ambiguity rather than
preserving an incidental first-match behavior from the predecessor.  Markdown
mutation is deliberately bounded to the headings, status sections, and
relationship links that `adrctl` owns instead of growing a general Markdown
parser.  See
[ADR-011](adr/ADR-011-resolve-adr-references-unambiguously-and-mutate-bounded-markdown.md).

## ADR-012 - Bound Editor, Pager, Git, and Graphviz Integrations

External integrations have narrow responsibilities: editors and pagers are
invoked through explicit precedence, Git may provide context but does not own ADR
mutation, and graph generation emits text without invoking Graphviz.  External
processes must not become hidden configuration, plugin, or state-management
mechanisms.  See
[ADR-012](adr/ADR-012-bound-editor-pager-git-and-graphviz-integrations.md).

## ADR-013 - Define Stable CLI Streams, Help, and Exit Statuses

Standard output is reserved for requested results and explicit informational
output, while diagnostics and warnings go to standard error.  The CLI uses a
small stable status vocabulary and keeps help, unknown-command behavior, and
version identity predictable for both interactive and scripted use.  See
[ADR-013](adr/ADR-013-define-stable-cli-streams-help-and-exit-statuses.md).

## ADR-014 - Use adr-tools 3.0.0 as the Compatibility Corpus Baseline

The initial compatibility comparator is the tagged `npryce/adr-tools` 3.0.0
release rather than a moving upstream branch.  Observable predecessor behavior is
classified as compatible, an intentional deviation, or new adrctl behavior so
safety improvements are explicit rather than confused with regressions.  See
[ADR-014](adr/ADR-014-use-adr-tools-3-0-0-as-the-compatibility-corpus-baseline.md).

## ADR-015 - Build and Release One Self-Contained adrctl Artifact

Maintained modular source is assembled in an explicit order into a self-contained
consumer executable with immutable build metadata.  Validation and release work
exercise the exact generated artifact, with no runtime Git, clock, or network
lookup required to determine version identity.  See
[ADR-015](adr/ADR-015-build-and-release-one-self-contained-adrctl-artifact.md).

## ADR-016 - Detect Concurrent Number Allocation without Promising Locking

The project does not promise coordinated multi-writer numbering through a
persistent locking protocol.  Creation still defends against destructive races by
refusing to overwrite a destination that appears after preflight, with bounded
retry permitted only when it remains safe and deterministic.  See
[ADR-016](adr/ADR-016-detect-concurrent-number-allocation-without-promising-locking.md).

## ADR-017 - Use Documentation-First Source Comments and Generated Reference Docs

Maintained Bash source uses Doxygen-compatible comments as part of the engineering
contract, and Doxygen produces browsable reference documentation from those
comments.  Documentation generation is treated as a first-class project workflow
rather than optional cleanup after implementation.  See
[ADR-017](adr/ADR-017-use-documentation-first-source-comments-and-generated-reference-docs.md).

## ADR-018 - Use Documentation-Driven, Test-Second Development

Architectural and behavioral changes normally establish documented intent before
implementation and observable-behavior tests.  Tests may still be written first
for reproduction or exploration, but they do not replace ADRs, specifications, or
other normative documentation as the record of intended behavior.  See
[ADR-018](adr/ADR-018-use-documentation-driven-test-second-development.md).

## ADR-019 - Name the Generated Distribution Artifact adrctl.bash

The canonical standard distribution filename is `dist/adrctl.bash`, correcting
the earlier filename selected by ADR-015 without changing the `adrctl` product
identity.  Direct artifact execution, installed `adrctl`, the `adr` filesystem
symlink, and ordinary shell aliases all remain paths to the same product.  See
[ADR-019](adr/ADR-019-name-the-generated-distribution-artifact-adrctl-bash.md).

## ADR-020 - Keep Generated Reference Documentation Out of Git

Generated Doxygen output under `doc/reference/` is derivative build state and is
ignored rather than committed.  `make docs` regenerates the site, Pages publishes
that generated tree, and repository history retains maintained documentation
sources instead of rendered reference output.  See
[ADR-020](adr/ADR-020-keep-generated-reference-documentation-out-of-git.md).

## ADR-021 - Bootstrap bashdeps and Manage Build Dependencies Through a Manifest

Make directly bootstraps and verifies one released `bashdeps.bash` artifact, while
ordinary external build and documentation dependencies live in
`dependencies.txt`.  `make deps` may acquire or repair dependency state,
`make deps-check` verifies prepared state without repair, and plain `make build`
remains dependency-management-free.  See
[ADR-021](adr/ADR-021-bootstrap-bashdeps-and-manage-build-dependencies-through-a-manifest.md).

## ADR-022 - Publish Development, Standard, and Minified Distribution Artifacts

The build publishes development, standard, and minified executable
representations of the same adrctl implementation.  Comment stripping and
Bash-Minifier are explicit build transformations, every flavor receives direct
validation, and Bash-Minifier remains a manifest-managed build tool rather than a
runtime component.  See
[ADR-022](adr/ADR-022-publish-development-standard-and-minified-distribution-artifacts.md).

## ADR-023 - Separate ADR Candidate Selection from Logical Number Extraction

ADR filename creation, candidate selection, and logical-number extraction are
distinct concepts with separate configuration.  One shared discovery pipeline
feeds listing, reference resolution, numbering, TOC generation, graph generation,
and creation rediscoverability checks so those behaviors cannot silently disagree.
See
[ADR-023](adr/ADR-023-separate-adr-candidate-selection-from-logical-number-extraction.md).

## ADR-024 - Standardize SHA-256 Checksum Companion Filenames

New release checksum companions use the explicit `.sha256` suffix while
historical `.256` companions remain valid for the releases that published them.
Consumers may use legacy fallback only after confirming the preferred sidecar is
absent; transport or verification failures remain failures, and committed digests
continue to authorize build dependencies.  See
[ADR-024](adr/ADR-024-standardize-sha256-checksum-companion-filenames.md).

## ADR-025 - Separate Graph Semantics from Serialization

`generate graph` constructs one semantic ADR relationship model and serializes it
as DOT by default or Mermaid when requested.  Both formats share discovery,
relationship, ordering, and link semantics, while rendering remains a downstream
concern with no Graphviz, Mermaid CLI, Node.js, or browser requirement for source
generation.  See
[ADR-025](adr/ADR-025-separate-graph-semantics-from-serialization.md).

## ADR-026 - Maintain a Hand-Authored Section 1 Man Page

This currently Proposed decision places a hand-authored `adrctl(1)` manual page at
`doc/adrctl.1` rather than generating it from another documentation source.  The
behavioral specification remains normative, while the man page is a conventional
consumer reference and does not introduce installation or packaging behavior on
its own.  See
[ADR-026](adr/ADR-026-maintain-a-hand-authored-section-1-man-page.md).

## ADR-027 - Publish an Ephemeral ADR Landing Page with Released adrctl

The Doxygen site uses an ephemeral `doc/adr/README.md` assembled from maintained
intro/outro framing plus a linked TOC produced by a pinned previously released
`adrctl.bash`.  The generated Markdown remains ignored, `make adr-index` consumes
prepared dependency state atomically, and `make docs` sequences dependency
preparation before generation without adding the released tool to the current
product source closure.  See
[ADR-027](adr/ADR-027-publish-an-ephemeral-adr-landing-page-with-released-adrctl.md).

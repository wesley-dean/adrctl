# AGENTS.md

This file provides guidance for AI coding agents working in this repository.

Use this file together with `README.md`, the Architecture Decision Records under
`doc/adr/`, and `doc/adrctl-spec.md`.

The README is the human-facing project overview.  The ADRs are the canonical
record of architectural intent.  The specification is the normative public
behavioral contract.  This file is the agent-facing operational map.

## Project Overview

`adrctl` is a deliberate Bash rebuild and successor to
`npryce/adr-tools`.

The project aims to preserve established `adr-tools` commands and successful
workflows where practical while improving configuration safety, filesystem
preflight, build/release discipline, documentation, test coverage, and
maintainability.

The canonical product and installed command identity is `adrctl`.  The build
produces three executable representations of the same product:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
```

`adrctl.bash` is the standard/default distribution flavor.  The same product
behavior must also work from the development and minified flavors, when installed
as `adrctl`, or when reached through an `adr` symbolic link.

The project is licensed under CC0 1.0 Universal.

## Read the ADRs and Specification First

Before making a significant change, review the relevant ADRs under `doc/adr/` and
the affected sections of `doc/adrctl-spec.md`.

Do not infer architecture from implementation when an ADR or specification
already defines the contract.

If implementation exposes a contradiction in the documented architecture, stop
treating the implementation as authoritative.  Surface the conflict and update
the ADR/specification or change the implementation deliberately.  Do not allow
silent architectural drift.

New ADRs created during initial development remain `Proposed` until the maintainer
explicitly accepts them.

Checksum companion naming and historical-read compatibility are governed by
ADR-024.

## Foundational Architecture

Preserve these boundaries unless a later ADR intentionally changes them:

- Bash 4.3+ is the minimum runtime.
- Maintained source is modular and assembled into three generated representations
  of one executable implementation.
- `dist/adrctl.bash` remains the standard/default generated artifact under
  ADR-019 and ADR-022.
- `dist/adrctl.dev.bash` retains comments from the assembled adrctl source and
  embedded library inputs for inspection and debugging.
- `dist/adrctl.bash` strips full-line comments from assembled implementation and
  library inputs while retaining generated build-identification comments.
- `dist/adrctl.min.bash` is produced by applying the pinned Bash-Minifier build
  dependency to the completed standard artifact.
- Each executable artifact has an adjacent `.sha256` SHA-256 checksum file.
- The canonical installed command identity remains `adrctl`.
- Every generated executable has one effective product entrypoint owned by
  `adrctl`.
- Invocation through an `adr` symlink is a supported compatibility path.
- Supported subcommands are built into the repository and generated artifacts.
- External `adr-*` or `adrctl-*` plugin discovery is not supported initially.
- Project configuration is data and is never sourced or evaluated.
- ADR filename creation, ADR candidate selection, and logical-number extraction
  are separate concerns under ADR-023.
- `ADRCTL_ADR_GLOB` selects candidate basenames; it does not itself establish that
  a file is a managed ADR.
- `ADRCTL_ADR_NUMBER_REGEX` recognizes managed ADR basenames and capture group 1
  contains the complete logical decimal ADR number.
- `new` and `init` must preflight rendered filenames against the effective glob
  and number regex so adrctl never knowingly creates an ADR that subsequent
  discovery would ignore or assign a different logical number.
- `mktext` performs textual substitution only; `adrctl` owns ADR-specific value
  acquisition and transformation.
- The Makefile directly bootstraps only the pinned `bashdeps.bash` build tool.
- Ordinary external build/development artifacts, including `mktext.bash`, the
  Bash Doxygen filter, and Bash-Minifier, are declared in `dependencies.txt` and
  synchronized by bashdeps under ADR-021 and ADR-022.
- `make build` consumes already-prepared dependency state and does not acquire or
  verify external dependencies.
- `make all` is the fresh-checkout convenience path that synchronizes dependencies
  before building.
- Bash-Minifier is a build-time transformation tool and is not embedded into
  adrctl runtime artifacts.
- The embedded renderer adds no runtime network dependency.
- Multi-file mutations preflight the complete intended change before writing.
- Existing files use atomic per-file replacement where practical.
- Cross-file transactionality is not promised.
- Git may supply project context but does not own ADR mutation state.
- `generate graph` emits Graphviz DOT and does not invoke Graphviz automatically.
- Ambiguous ADR references fail rather than selecting the first incidental match.
- Generated Doxygen output under `doc/reference/` is ignored build output and is
  published through GitHub Pages rather than committed to the repository.

## Compatibility and Provenance

The canonical compatibility baseline is:

```text
Repository: npryce/adr-tools
Release:    3.0.0
Commit:     b47d3837d452ca6d2509d2524c7a08c701e84367
```

Upstream source, documentation, and tests may be inspected to establish observable
behavior and compatibility cases.

Do not copy, translate, mechanically transform, or adapt GPL-covered upstream
implementation code into `adrctl` production source.

Independently author `adrctl` source against the ADRs, specification, and observed
behavioral corpus.

When upstream implementation inspection is required to understand behavior,
document the observable contract rather than reproducing implementation
expression.

Default/template explanatory prose should be independently authored.  Preserve
required structure and observable semantics without copying predecessor prose
merely for textual similarity.

Classify predecessor behavior as:

```text
Compatible
Intentional deviation
New adrctl behavior
```

Intentional deviations require rationale, specification coverage, and regression
tests.  User-visible deviations from successful predecessor workflows should have
migration guidance.

## Clarify Only Material Ambiguity

Use repository evidence before asking the maintainer to reconstruct facts that can
be discovered from source, documentation, tests, ADRs, Git history, or the
compatibility baseline.

Ask a question when two reasonable answers would produce meaningfully different
public behavior, compatibility, security, persistence, release behavior,
licensing, or architectural boundaries.

For low-risk, reversible implementation choices that fit the established
architecture, choose the conventional answer and continue.

Do not invent rationale when the repository does not establish it.

## Technology Stack

Runtime:

- Bash 4.3+
- Bash builtins and language features
- bounded ordinary Unix utilities when clearly justified
- Git only where the specification permits it

Build and development:

- Make
- Bats
- ShellCheck
- shfmt
- Doxygen-compatible Bash documentation
- GitHub Actions
- SHA-256 release checksums
- GitHub artifact provenance attestation

Build dependency management:

- the Makefile pins and independently verifies the released `bashdeps.bash`
  bootstrap artifact;
- `dependencies.txt` pins the `mktext.bash` artifact embedded into adrctl;
- `dependencies.txt` pins `doxygen-bash.awk` for reference documentation;
- `dependencies.txt` pins the commit-specific Bash-Minifier `Minify.sh` bytes as
  `vendor/bash-minifier.bash` for the minified distribution transformation; and
- exact current versions, immutable URLs, commits, and SHA-256 digests SHALL be
  read from the Makefile and `dependencies.txt` rather than duplicated in this
  guidance.

## Source and Build Boundaries

Treat maintained source under `src/` and `lib/` as the implementation source of
truth once those directories exist.

Do not edit generated files under `dist/` as though they were maintained source.

The Makefile must enumerate maintained build inputs explicitly.  Do not replace
explicit source order with implicit plugin/module discovery.

External build inputs are prepared separately:

```text
make deps
```

may bootstrap bashdeps and synchronize the committed manifest, while:

```text
make deps-check
```

verifies already-present dependency state without network access or repair.

`make build` SHALL NOT bootstrap, synchronize, or verify external dependencies.
It builds only from current local inputs.  `make all` explicitly sequences
`make deps` followed by `make build` for callers that want a prepared fresh-checkout
path.

A successful `make build` produces:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
dist/adrctl.dev.bash.sha256
dist/adrctl.bash.sha256
dist/adrctl.min.bash.sha256
```

New releases publish only `.sha256` checksum companions.  Historical `.256`
release assets remain valid for the releases that contain them.  Code that
explicitly retrieves release checksum sidecars may fall back from `.sha256` to
`.256` only when the preferred resource is confirmed absent; transport, TLS,
authorization, server, malformed-content, and checksum-verification failures
remain failures.  This compatibility rule does not change dependency trust:
committed SHA-256 digests remain authoritative for the bashdeps bootstrap and
manifest-managed artifacts.

The build injects immutable version/build metadata into the development and
standard assemblies.  The development flavor embeds the manifest-managed
`mktext.bash` artifact as supplied.  The standard flavor removes full-line
comments from all assembled implementation/library inputs, including the embedded
mktext representation.  The minified flavor is produced from that completed
standard artifact by the manifest-managed Bash-Minifier.

Generated build-identification comments remain in the development and standard
artifacts.  They are build provenance rather than comments inherited from an
assembled source/library input.

The development flavor does not reconstruct comments already removed by an
upstream dependency's own release packaging.

Do not rewrite, patch, or semantically modify the prepared `mktext` implementation
inside adrctl assembly.  ADR-022 permits only the representation transformations
that define the flavors: full-line comment removal for the standard artifact and
whole-file minification downstream of the standard artifact.

Bash-Minifier is applied after the standard artifact is assembled.  Do not build a
second minified implementation directly from maintained source or allow
minification to replace the project's explicit comment-stripping boundary.

If the pinned Bash-Minifier fails to preserve a valid Bash construct, a
semantics-preserving adrctl source expression that the minifier supports may be
used when it remains readable, documented, and validated across all three
artifacts.  Do not locally patch the pinned minifier bytes to hide an integration
problem.

Release versions come from the release workflow and are passed into Make.  Make
does not independently invent a release version.

Build dates use source-revision timestamps rather than wall-clock assembly time.

## Coding Guidelines

Prefer small, readable Bash functions with one clear responsibility.

Avoid `eval`.

Do not source `.env`, `.adr-dir`, templates, ADR documents, replacement values, or
`dependencies.txt` as shell code.

Quote expansions deliberately.

Treat template text, configuration values, titles, relationship text, ADR
contents, dependency-manifest fields, candidate globs, and number regexes as data.

Prefer Bash builtins when they implement the behavior clearly and safely on Bash
4.3.  Use ordinary Unix commands where they make the implementation more obvious
or compatible rather than recreating them poorly in shell.

Keep parsing bounded to the syntax the specification owns.  Do not grow a general
Markdown parser, shell parser, or template engine opportunistically.

Separate interpretation from mutation.  Resolve configuration, references,
templates, target paths, and complete intended outputs before the first write.

Use same-directory temporary files and atomic rename for existing-file replacement
where practical.

Never overwrite a newly appeared destination merely because number allocation
raced with another process.

## Configuration Rules

Project-root discovery and configuration are separate phases.

`ADRCTL_PROJECT_ROOT` is a CLI/process-environment concept.  It is not valid
inside project `.env` configuration.

A shared `.env` may contain unrelated keys.  Ignore non-`ADRCTL_` keys.  Reject
unknown `ADRCTL_` project keys.

Configuration must be parsed as data with the exact grammar defined by the
specification.  Do not add shell expansion, command substitution, or escape
processing as convenience features.

`ADRCTL_ADR_GLOB` and `ADRCTL_ADR_NUMBER_REGEX` are project-scoped discovery
settings.  Their precedence is process environment, project `.env`, then built-in
default; no command-line forms exist initially.

Apply `ADRCTL_ADR_GLOB` only to immediate basenames within the effective ADR
directory.  Do not use it to introduce recursive discovery or path traversal.

Apply `ADRCTL_ADR_NUMBER_REGEX` with Bash ERE matching.  Capture group 1 is the
complete logical decimal number.  Do not guess another capture group, infer the
first digit run after a configured match, or derive the number from document body
content.

Never apply either configured discovery value through `eval`, `source`, command
construction, or another execution mechanism.

Relative project paths resolve against `PROJECT_ROOT`, not the caller's incidental
nested cwd.

Preserve `.adr-dir` compatibility until a later accepted decision changes it.

## ADR Discovery and Numbering Rules

Treat ADR discovery as one shared pipeline:

```text
ADR directory
  -> ADRCTL_ADR_GLOB candidate selection
  -> ADRCTL_ADR_NUMBER_REGEX validation + capture group 1
  -> logical ADR records
```

All collection-driven behavior must consume that same logical record set,
including listing, numeric and partial reference resolution, next-number
allocation, TOC generation, graph generation, and repository upgrades.

Preserve numeric ordering by captured logical number with basename ordering as the
stable tie-breaker for duplicate logical numbers.

A candidate that matches the glob but not the number regex is unrelated and is
ignored.  A configured regex that is invalid, or that matches a candidate without
a decimal capture group 1, is a configuration-contract failure and must not be
silently interpreted another way.

Filename creation is a separate surface.  After rendering a new basename and
before publication, verify that the basename matches the effective candidate glob,
matches the effective number regex, and captures the exact number adrctl assigned.
Do not allow `new` or `init` to create an ADR that the next discovery operation
would lose or renumber.

Do not derive persistent discovery solely from a transient `--filename-pattern`
option.  The default discovery settings are intentionally broad enough to
recognize common prefixed forms such as `ADR-0001-title.md`.

## Rendering Rules

`adrctl` owns context values such as:

```text
NUMBER
NUMBER4
TITLE
TITLE_SLUG
STATUS
DATE
PROJECT_ROOT
ADR_DIR
```

Do not move slugification, date generation, number padding, filesystem discovery,
or ADR semantics into `mktext`.

Use the pinned public `mktext` render API provided by the manifest-managed artifact.

Delimiter selection belongs to `adrctl`:

1. explicit command-line pair;
2. process-environment pair;
3. project-configuration pair;
4. automatic detection of a recognized braced context token;
5. otherwise empty delimiters for legacy bare-token mode.

Do not implement mixed implicit rendering or a second compatibility renderer.

## Scope Discipline

Produce the smallest coherent change that satisfies the documented behavior.

Do not perform unrelated refactoring, formatting, renaming, dependency upgrades,
feature additions, or documentation rewrites in a focused patch.

A coherent engineering change may include the documentation, source, tests, and
build updates necessary to keep one behavior complete.  That is not scope creep.

If additional improvement opportunities are discovered, record or report them
separately unless they block correctness or safety of the current work.

Documentation-only requests must preserve executable behavior exactly.

## Documentation Standards

Follow ADR-017, ADR-018, ADR-020, ADR-021, ADR-022, ADR-023, and ADR-024.

Hand-maintained Bash uses Doxygen-compatible documentation comments.

Document function purpose, parameters, statuses, streams, side effects, and
important invariants where applicable.

Comments should explain intent and constraints rather than paraphrasing syntax.

Documentation roles are distinct:

- README: human-facing use and orientation;
- AGENTS: contributor operating guidance;
- ADRs: why durable architectural choices were made;
- `doc/adrctl-spec.md`: current public behavior;
- source comments: implementation contracts;
- `doc/reference`: generated source-reference documentation, ignored by Git and
  published through GitHub Pages.

Do not use tests or source comments as substitutes for updating the normative
specification when public behavior changes.

## Development Workflow

The project follows documentation-driven, test-second development.

For a behavioral or architectural change:

1. establish or update documented intent;
2. implement the smallest coherent change;
3. add or update observable-behavior tests;
4. synchronize required external inputs explicitly when build/test work needs
   them;
5. build and test every literal generated executable flavor when consumer behavior
   can be affected;
6. test through the `adr` symlink when invocation identity can be affected; and
7. review the complete diff for architecture, compatibility, and documentation
   drift.

Tests may be written first to reproduce a bug or characterize unknown behavior.
Before completion, the intended resulting behavior must exist independently in
the documentation.

## Testing

Use Bats for the primary behavior suite unless a small shell harness is more
appropriate for a specific minimum-Bash or build-boundary test.

Prefer observable behavior:

- command arguments;
- stdout and stderr;
- exit status;
- generated paths;
- file contents;
- filesystem mutations;
- editor/pager invocation boundaries;
- generated reports;
- configuration precedence;
- ADR candidate selection and logical-number extraction;
- creation rediscoverability preflight;
- dependency synchronization and verification; and
- literal execution of each generated distribution flavor.

Do not couple tests to private helper names merely because they are convenient to
call.

The compatibility suite must cover the canonical `adr-tools` 3.0.0 surface and
all documented intentional deviations.

Every behavior-affecting fix should add or update a regression test that would
have caught the defect.

All three generated executable artifacts must be tested directly.  Valid source
modules or one passing representation do not prove that concatenation order,
comment stripping, minification, embedded dependency behavior, metadata
injection, permissions, or the `adr` symlink path are correct in the others.

Minimum-runtime testing must include Bash 4.3 for all three executable flavors.

Build-boundary validation should also confirm that plain `make build` does not
bootstrap or synchronize dependencies and that `make all` works from a fresh
checkout.

## Validation

When relevant, use the repository's Make targets rather than reproducing their
logic ad hoc.

Validation should include the applicable subset of:

- dependency synchronization with `make deps`;
- offline dependency verification with `make deps-check`;
- Bash syntax validation for every distribution flavor;
- static analysis;
- formatting checks;
- behavior tests against every distribution flavor;
- compatibility tests;
- minimum-Bash tests against every distribution flavor;
- literal generated-artifact tests;
- `adr` symlink tests;
- generated documentation;
- verification of all `.sha256` files; and
- complete diff review.

Report only validation actually performed.  Do not invent successful tool output.

## Release Discipline

Release artifacts are:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
dist/adrctl.dev.bash.sha256
dist/adrctl.bash.sha256
dist/adrctl.min.bash.sha256
```

Release acceptance concerns the exact bytes of all six files that will be
published.

The release workflow validates source and behavior, synchronizes and verifies the
committed dependency manifest, builds all three executable flavors with the chosen
SemVer, validates each executable, verifies each SHA-256 checksum file, produces
provenance attestation when supported, and publishes those exact bytes.

`adrctl.bash` remains the standard/default distribution.  Do not create a
separately maintained `adr` executable.  Compatibility uses a symlink to the
installed adrctl executable selected by the user.

## Common Failure Modes

Avoid:

- copying `adr-tools` implementation code into the rewrite;
- treating GPL-covered implementation expression as a shortcut to compatibility;
- editing generated files under `dist/` directly;
- reintroducing separate direct Makefile acquisition for manifest-managed
  dependencies;
- downloading Bash-Minifier directly from Make instead of declaring it in
  `dependencies.txt`;
- tracking Bash-Minifier from a moving branch rather than an immutable commit and
  digest;
- making `make build` silently access the network or repair dependency state;
- allowing `make deps-check` to bootstrap or mutate dependency state;
- embedding Bash-Minifier into the runtime artifact;
- generating the minified flavor independently from maintained source rather than
  transforming the standard flavor;
- preserving embedded-library comments in the standard flavor when the
  whole-package stripping contract requires their removal;
- applying transformations to embedded mktext beyond the ADR-022 representation
  rules;
- locally patching the pinned Bash-Minifier bytes to work around unsupported Bash
  syntax;
- publishing a transformed executable without running the consumer behavior suite
  against that exact representation;
- embedding an unverified or moving `mktext` dependency;
- allowing embedded `mktext` to claim the `adrctl` process entrypoint;
- treating every `.env` as a project marker;
- allowing `.env` to redirect its own project root;
- evaluating configuration, templates, ADR globs, or ADR number regexes as shell
  code;
- silently ignoring unknown `ADRCTL_` project keys;
- hard-coding another ADR filename prefix instead of using the ADR-023 discovery
  contract;
- deriving persistent discovery solely from a transient filename-creation pattern;
- implementing different ADR-recognition logic for list, references, numbering,
  reports, or upgrades;
- creating an ADR filename that the effective discovery configuration cannot
  rediscover as the same logical number;
- choosing the first ambiguous ADR reference;
- mutating one file before discovering that another required target is invalid;
- claiming cross-file transactionality that the filesystem does not provide;
- overwriting a file after a concurrent number-allocation collision;
- writing diagnostics into script-facing stdout;
- exposing private `mktext` statuses as the `adrctl` CLI contract;
- automatically staging or committing Git changes;
- requiring Graphviz merely to emit DOT;
- adding external plugin discovery without a new architectural decision;
- testing only source modules or only one generated artifact and assuming every
  released representation works;
- inventing design rationale; and
- silently expanding scope.

## Final Principle

`adrctl` should make established ADR workflows easier to trust.

Preserve useful compatibility, improve unsafe failure boundaries deliberately,
keep the generated product inspectable, and leave every change understandable to
the next contributor without requiring access to the conversation that produced
it.

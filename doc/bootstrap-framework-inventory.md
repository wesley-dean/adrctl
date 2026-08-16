# Bootstrap Framework Inventory for adrctl

## Status and purpose

This document records the initial inventory of the reusable engineering framework
that `adrctl` should inherit from `wesley-dean/bootstrap` and the smaller-scale
adaptation demonstrated by `wesley-dean/mktext`.

This is a working architecture assessment.  It does not accept product
architecture or replace Architecture Decision Records.  Product-specific
architecture is assessed separately so that rejecting a Bootstrap implementation
mechanism does not accidentally discard the engineering process around it.

The governing approach is "preserve, then prune": Bootstrap framework machinery
is presumed useful until there is a concrete reason to modify or omit it.

Classifications in this document are:

- **Inherit as-is** - preserve the existing framework concept and, where
  practical, its current repository implementation.
- **Inherit with modification** - preserve the process or architectural role,
  while adapting names, paths, runtime requirements, product behavior, or other
  project-specific details for `adrctl`.
- **Omit with reason** - do not carry the mechanism into `adrctl`; the reason is
  stated explicitly.

## Sources reviewed

This inventory is based on the current repositories and project handoff, with the
supplement taking precedence where the two handoff documents differ.

Bootstrap sources reviewed include:

- `README.md` and `AGENTS.md`;
- `doc/` and the complete `doc/adr/` corpus;
- `Makefile`;
- `Doxyfile`;
- `.github/workflows/`;
- `doc/cli.md`;
- `doc/testing.md`;
- `doc/release-verification.md`;
- the maintained-source and generated-artifact structure.

`mktext` sources reviewed include:

- `AGENTS.md`;
- all accepted ADRs from `ADR-000` through `ADR-012`;
- `doc/bootstrap-adr-port-assessment.md`;
- `doc/mktext-spec.md`;
- `Makefile`;
- `Doxyfile`;
- `src/mktext.bash`;
- the Bash 4.3 compatibility harness;
- test, versioning, and GitHub Pages workflows;
- the committed `doc/reference/` output.

The `adrctl` baseline was also inspected.  The initial development branch is
currently close to the template repository: it contains the general repository
and security machinery plus `ADR-000`, but it does not yet contain the product
Makefile, Doxygen configuration, `AGENTS.md`, source tree, test workflow,
GitHub Pages workflow, generated reference documentation, or normative product
specification.

## Repository and contributor structure

### README.md

**Classification: Inherit with modification.**

Preserve Bootstrap's role for the README as the human-facing overview, but write
it for `adrctl`, its compatibility relationship to `adr-tools`, installation,
normal command usage, configuration, templates, and release artifact.

The current template README is scaffolding rather than the eventual product
README.

### AGENTS.md

**Classification: Inherit with modification.**

`adrctl` should receive an agent-facing operational map derived from Bootstrap
and informed by `mktext`.

It should direct AI-assisted contributors to the ADR corpus and normative
specification before behavioral work, state the compatibility contract, define
the maintained-source and generated-artifact boundaries, describe the
`mktext` dependency boundary, reinforce documentation-driven/test-second
engineering, and require the smallest coherent change.

The final file should describe `adrctl` rather than copy either reference
project mechanically.

### Community and repository-policy files

**Classification: Inherit as-is unless a product-specific need appears.**

The template already supplies repository-level files such as `CODEOWNERS`,
`CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, `SECURITY.md`, `SUPPORT.md`, issue and
pull-request templates, spelling configuration, editor configuration, and
security-scanner configuration.

These are reusable project framework rather than `adrctl` product architecture.
They should remain unless later review identifies an actual conflict.

### doc/

**Classification: Inherit with modification.**

Use `doc/` as the durable documentation root.  Product documentation should
include at least:

- architectural assessments and framework inventories;
- `doc/adr/`;
- a normative `adrctl` behavioral specification;
- generated source-reference documentation under `doc/reference/`;
- user-facing reference or design documents that become necessary as the CLI and
  configuration model are specified.

### doc/adr/

**Classification: Inherit as-is as a repository convention.**

The existing `.adr-dir` already points to `doc/adr`, and `ADR-000` is an accepted
foundational record.  Preserve that location and the historical-record model.
New project ADRs begin after the existing `ADR-000` and remain `Proposed` until
explicit maintainer acceptance.

The existing ADR template and preflight checklist may be retained and adapted
only when an actual project need requires it.

### Normative behavioral specification

**Classification: Inherit with modification.**

`mktext` demonstrates the value of separating architectural rationale from a
single current behavioral contract.  `adrctl` should have a normative
specification, expected to be `doc/adrctl-spec.md`, covering command forms,
configuration, standard streams, exit statuses, filesystem effects, templates,
compatibility behavior, failure behavior, and other consumer-visible contracts.

The exact specification contents are product architecture and will be drafted
after the consequential architecture questions are resolved.

### Generated reference documentation

**Classification: Inherit as-is as a process, with product-specific inputs.**

Preserve the complete documentation pipeline:

```text
Doxygen-compatible Bash comments
        |
        v
make docs
        |
        v
doc/reference/*
        |
        +---- committed reference output
        |
        v
.github/workflows/static.yml
        |
        v
GitHub Pages
```

Generated reference documentation is a build product.  Maintainers edit source
comments and regenerate the reference output rather than editing generated HTML
manually.

## Maintained source and distribution lifecycle

### Separate maintained source from consumer artifact

**Classification: Inherit with modification.**

Preserve Bootstrap's and `mktext`'s `src/` to `dist/` lifecycle.  Human-maintained
source belongs under the source tree; consumers receive a generated artifact
under `dist/`.

The current architectural evidence favors modular maintained source for
`adrctl`, because the product owns CLI parsing, configuration, project discovery,
ADR operations, compatibility behavior, diagnostics, rendering integration, and
other responsibilities.  The exact module boundaries remain a product-architecture
decision and should not be fixed by this framework inventory.

### One generated user-facing executable

**Classification: Inherit with modification.**

The handoff already establishes one user-facing executable named `adrctl`.
The build should generate that executable from maintained source, inject immutable
build metadata, set the interpreter directive and executable mode, and treat the
result as the product artifact that tests and releases exercise.

The exact distribution path and filename are product-interface details to be
recorded in the ADR corpus.  The expected direction is a generated executable
under `dist/`, rather than a maintained root-level script.

### Generated artifacts are not canonical source

**Classification: Inherit as-is.**

Generated `dist/` output should not become a second hand-maintained source of
truth.  Build logic, tests, and release automation should regenerate it from the
maintained source tree.

### Build metadata

**Classification: Inherit with modification.**

Preserve the model demonstrated by `mktext`:

- release version is supplied by the semantic-version workflow;
- development builds use an explicit development version;
- source commit identity is embedded at build time;
- build/source date uses the source revision's commit timestamp rather than
  wall-clock build time when Git metadata is available;
- runtime version reporting does not query Git, the clock, or the network;
- build targets regenerate when metadata inputs change rather than relying only
  on filesystem modification times.

Exact `adrctl --version` output belongs in the behavioral specification.

### Reproducibility expectations

**Classification: Inherit as-is as a principle.**

Repeated builds of the same revision and supplied version should avoid
incidental differences whenever practical.  The project need not promise
byte-for-byte reproducibility until that requirement is demonstrated and
specified.

## Make lifecycle

Bootstrap's Makefile is process architecture.  `adrctl` should preserve stable
target meanings while scaling implementation details to the product.

### make / make all / make build

**Classification: Inherit with modification.**

Follow the shared Bootstrap and `mktext` convention that the default Make path
builds the consumer artifact.  Validation should remain explicit rather than
being hidden behind the default build target.

The expected semantic relationship is:

```text
make
make all
make build
    -> generate the adrctl consumer artifact
```

The exact prerequisites and source assembly mechanism depend on the final source
architecture.

### make check

**Classification: Inherit with modification.**

Provide a stable static-validation target for maintained source and other
applicable hand-maintained inputs.  Shell syntax validation and ShellCheck are
expected baseline checks.  Generated distribution output should be validated as
a product artifact without being treated as a second hand-maintained source.

### make format

**Classification: Inherit as-is in purpose.**

Use `shfmt` through one stable Make target for hand-maintained shell source.
Formatting rules should be centralized rather than duplicated in contributor
instructions and CI.

### make test

**Classification: Inherit with modification.**

Use Bats as the primary observable-behavior suite.  Tests should exercise both
appropriate maintained-source surfaces and the exact generated executable users
receive.  `adrctl` also requires a compatibility corpus against existing
`adr-tools` behavior; that is product-specific test architecture rather than a
reason to replace the Make testing interface.

### make test-report

**Classification: Inherit with modification.**

Preserve Bootstrap's CI-reporting capability so CI can publish structured Bats
results.  The target should execute the same behavioral suite as ordinary
project testing while emitting the report format expected by the CI reporter.

### make docs and make docs-clean

**Classification: Inherit as-is in purpose.**

Preserve the Doxygen generation lifecycle and the clean rebuild of
`doc/reference/`.  The Bash Doxygen preprocessing/filter mechanism should be
retained for Bash source.

### make docs-stage

**Classification: Inherit as-is in purpose.**

Because generated reference documentation is committed, provide the same
convenience target for staging the generated documentation tree after
regeneration.

### make checksums

**Classification: Inherit with modification.**

Generate a checksum for the exact `adrctl` release executable after building it.
The filename changes with the `adrctl` release artifact, while the release
verification process remains the same.

### make clean

**Classification: Inherit with modification.**

Remove ordinary generated products such as the distribution executable,
reference-documentation output, downloaded documentation filter, and test-report
artifacts without deleting hand-maintained project state.

### make distclean

**Classification: Inherit with modification.**

Retain a deeper cleanup operation whose documented goal is to return the working
tree close to a fresh-checkout generated state.  Exact generated paths will be
known after the build and test layout is established.

### Bootstrap package-manager end-to-end targets

**Classification: Omit with reason.**

Bootstrap's APT/APK/DNF container end-to-end targets validate package-manager
behavior that `adrctl` does not own.  Carrying those exact targets into
`adrctl` would add framework-shaped ceremony without product value.

`adrctl` may later need its own end-to-end or compatibility fixtures, but those
should test ADR-tool behavior rather than preserve Bootstrap's package-manager
matrix by name.

## Continuous integration

### Normal project validation workflow

**Classification: Inherit with modification.**

Add an `adrctl` test workflow that delegates to Make rather than duplicating the
underlying commands.  It should run static checks and behavioral tests and,
where useful, publish Bats/JUnit results through a first-class GitHub check.

### Minimum-runtime compatibility job

**Classification: Inherit with modification from mktext.**

The handoff sets Bash 4.3+ as the `adrctl` runtime floor.  CI should therefore
exercise the generated executable under Bash 4.3 in a dedicated compatibility
job, using a harness that does not depend on a newer Bash interpreter.

The purpose is to prove the documented minimum runtime literally rather than
assuming code that works on the CI host also works on Bash 4.3.

### MegaLinter

**Classification: Inherit as-is initially.**

The template already contains the MegaLinter workflow and configuration.  Keep
it unless product files reveal a concrete configuration change that is needed.

### CodeQL

**Classification: Inherit as-is initially.**

The template already carries the CodeQL workflow used by `mktext`.  Preserve it
as repository security machinery unless source-language support or scanner
behavior creates a demonstrated reason to adapt it.

### OpenSSF Scorecard

**Classification: Inherit as-is initially.**

The existing template workflow is reusable supply-chain/security framework and
should remain.

### Dependency automation and Dependabot auto-merge

**Classification: Inherit as-is initially.**

Preserve the existing dependency automation and pinned-action maintenance model.
Product-specific dependencies, including the selected `mktext` acquisition
mechanism, may require later configuration updates.

### Issue and repository-maintenance workflows

**Classification: Inherit as-is initially.**

Issue-branch creation and stale-issue handling are repository process rather than
product architecture.  Preserve them unless the maintainer later chooses a
different project-management policy.

### Bootstrap package-manager E2E workflow

**Classification: Omit with reason.**

Do not import Bootstrap's APT/APK/DNF matrix.  Any `adrctl` integration workflow
must arise from `adrctl` behavior and its actual external dependencies.

## Documentation publication

### Doxyfile

**Classification: Inherit with modification.**

Create an `adrctl` Doxygen configuration using Bootstrap and `mktext` as the
reference implementations.  Inputs and project metadata must match the eventual
`adrctl` maintained-source layout.

### Bash Doxygen filter

**Classification: Inherit as-is in process.**

Use the established Bash Doxygen preprocessing filter and acquire it through the
Make documentation target rather than committing an independently maintained
copy without a reason.

### Committed doc/reference output

**Classification: Inherit as-is.**

Commit generated reference documentation so the repository and Pages workflow
carry the same reference output.  Generated files remain products of
`make docs`, not hand-edited documentation.

### Static GitHub Pages workflow

**Classification: Inherit as-is with repository-local paths.**

Add the established Pages workflow that publishes `doc/reference`.  The current
`adrctl` template does not contain that workflow.

## Release behavior

### Semantic Versioning

**Classification: Inherit as-is as a policy, with workflow modification.**

Retain the repository's existing semantic-version calculation model.  The
current template versioning workflow must be expanded from tag/release creation
into a product release pipeline that validates and publishes the generated
`adrctl` artifact.

### Validate before versioning and release

**Classification: Inherit with modification.**

Follow the stronger behavior demonstrated by `mktext`: validate the repository
before producing a release artifact, build with the selected release version,
and validate the exact release artifact before publication.

The final workflow ordering should avoid publishing a tag or artifact whose
consumer surface has not been exercised successfully.

### SHA-256 checksum

**Classification: Inherit as-is in policy, with artifact-name modification.**

Bootstrap's release verification is stronger than the current `mktext` release
pipeline.  Under preserve-then-prune, `adrctl` should generate and publish a
SHA-256 checksum for its executable unless a concrete reason to omit it emerges.

### GitHub provenance attestation

**Classification: Inherit as-is in policy, with artifact-name modification.**

Preserve Bootstrap's GitHub artifact-attestation mechanism for the executable
and checksum.  This adds supply-chain evidence without changing `adrctl` runtime
behavior.

### Release artifact selection

**Classification: Inherit with modification.**

GitHub Releases should publish the generated `adrctl` executable and its release
verification material.  Maintained source files should remain available through
normal Git source archives rather than being presented as the canonical runtime
artifact.

## Source documentation standard

### Doxygen-compatible narrative comments

**Classification: Inherit as-is.**

Bootstrap ADR-045 and `mktext` ADR-011 establish a project-agnostic Bash source
commenting standard.  The same standard should govern `adrctl` source, including
`##` Doxygen lines, file and function documentation, configuration-variable
documentation, realistic examples, explicit safety/failure semantics, and
visible `@TODO` markers when rationale cannot be established from evidence.

A corresponding `adrctl` ADR should preserve provenance rather than silently
copying the rule.

## Development sequence

### Documentation-driven, test-second engineering

**Classification: Inherit as-is as the operating model.**

The working sequence demonstrated by Bootstrap and accepted by `mktext` is:

```text
architecture / specification
        |
        v
smallest correct implementation
        |
        v
observable-behavior tests
        |
        v
format / static analysis / docs / tests / diff review
```

Tests may be written earlier when they clarify behavior.  Human-readable
architectural intent remains the primary design artifact.

For `adrctl`, the initial architecture phase is intentionally larger: framework
inventory, product-architecture assessment, responsibility boundary, Proposed
ADRs, and the normative specification precede production implementation.

## Explicitly deferred framework details

The following questions are deliberately not answered by this framework
inventory because they materially affect `adrctl` product architecture:

- exact maintained-source module boundaries and assembly/discovery rules;
- exact generated executable path and filename;
- the compatibility meaning of the historical `adr` executable versus the new
  `adrctl` executable;
- CLI/subcommand grammar and compatibility guarantees;
- project-root and configuration discovery semantics;
- `.env` filename and marker semantics;
- `.adr-dir` compatibility and migration behavior;
- the `mktext` acquisition, pinning, embedding, and update boundary;
- ADR filename and numbering behavior;
- template and filename rendering context;
- filesystem mutation/preflight/atomicity behavior;
- Git ownership boundaries;
- editor/viewer and Graphviz boundaries;
- exit-status categories and standard-stream contracts;
- exact compatibility-corpus methodology.

Those items belong in the product-architecture assessment and subsequent ADR
discussion.

## Initial framework conclusion

`adrctl` should inherit most of Bootstrap's engineering operating model.  The
main deliberate omissions identified so far are Bootstrap's package-manager
end-to-end machinery and other product-domain mechanisms that do not exercise an
ADR-management tool.

`mktext` demonstrates that Bootstrap's rigor can survive substantial product
simplification without discarding the source/distribution boundary, Make
lifecycle, exact-artifact testing, minimum-runtime verification, documentation
pipeline, CI discipline, and release metadata model.

The next step is a separate product-architecture portability assessment of the
Bootstrap ADR corpus and the `mktext` decisions that either provide useful
precedent or directly constrain `adrctl` as a consumer.
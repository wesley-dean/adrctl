# ADR-027: Publish an Ephemeral ADR Landing Page with Released adrctl

Date: 2026-09-09

## Status

Accepted

## Intent and Documentation Posture

This Architecture Decision Record extends adrctl's generated Doxygen reference
site with a project-level ADR landing page while preserving the repository's
existing source, build, dependency, and publication boundaries.

The repository SHALL maintain project-specific framing for the landing page,
SHALL use a previously released `adrctl.bash` artifact to generate the linked ADR
table of contents, and SHALL compose those inputs into an ignored
`doc/adr/README.md` before Doxygen runs.  Doxygen SHALL use that generated Markdown
file as the published site's main page.

The generated landing page is derivative documentation state rather than
maintained source.  The maintained ADR corpus, framing files, normative behavioral
specification, and decision summary remain authoritative according to their
respective roles.

The released adrctl artifact used for documentation generation is tooling for the
repository that develops adrctl.  It is not embedded into the current product,
does not replace the current maintained source, and does not create a runtime
self-dependency.

Routine documentation generation SHALL use the linked textual ADR index only.  It
SHALL NOT automatically compose or render the relationship graph supported by
`adrctl generate graph`.

## Context

ADR-017 established documentation-first source comments and Doxygen-generated
reference documentation.  ADR-020 later made `doc/reference/` explicitly ephemeral
and ignored, reinforcing the distinction between maintained documentation source
and reproducible reference output.

ADR-021 established the current dependency model.  Make bootstraps one pinned,
previously released `vendor/bashdeps.bash`; bashdeps then synchronizes ordinary
external development, build, and documentation artifacts declared in
`dependencies.txt`.  `make docs` is intentionally allowed to prepare those
manifest-managed documentation dependencies before running Doxygen.

The resulting Pages site exposes implementation-level reference documentation but
has no useful project-level body at its index.  adrctl already has a substantial
ADR corpus and a normative behavioral specification, so the published site should
orient readers to that architecture rather than opening directly into generated
source reference pages.

ADR-013 makes `generate toc` a public, pipeline-oriented report whose requested
result is emitted on standard output.  ADR-023 requires TOC generation to use the
same configured ADR discovery and logical-numbering pipeline as the rest of the
product.  A documentation build can therefore consume the public report without
reimplementing filename recognition, title extraction, ordering, or link
serialization.

The unusual question is which adrctl implementation should generate adrctl's own
documentation index.

Building the current unreleased product and then executing it solely to construct
its own documentation would couple `make docs` to the product assembly path,
embedded mktext dependency, Bash-Minifier preparation, generated executable
flavors, and build validation.  That coupling is unnecessary for a report whose
required behavior already exists in a released public interface.

Invoking maintained library modules directly would avoid building a distribution
artifact but would make the documentation pipeline depend on private source order,
private helper names, and implementation structure.  That would give the
repository itself a privileged integration path different from the one consumers
use.

A pinned previously released `adrctl.bash` provides a cleaner boundary.  It is an
ordinary manifest-managed documentation tool whose exact bytes are reviewable and
checksum-authorized.  The documentation build exercises the same public
`generate toc` interface available to downstream repositories, while the current
checkout remains the documentation subject.

The approach intentionally introduces a one-release lag for documentation-tooling
semantics: changes to current `generate toc` behavior do not affect repository
publication until the pinned documentation-tool version is deliberately advanced.
That tradeoff is preferable to creating a circular or privileged build path, and
it makes a documentation-tool upgrade an explicit reviewed dependency change.

## Decision Drivers

- Give the published Doxygen site a useful project and architecture landing page.
- Keep stable explanatory prose in maintained source.
- Generate ADR titles and links mechanically from authoritative ADR files.
- Reuse adrctl's public TOC behavior rather than implementing another parser.
- Exercise a released public interface instead of private implementation details.
- Avoid coupling documentation publication to assembly of the current unreleased
  adrctl product.
- Preserve the bashdeps bootstrap and manifest-managed dependency model from
  ADR-021.
- Preserve `make docs` as a network-capable convenience target that prepares its
  documented dependencies.
- Keep `make adr-index` itself focused, deterministic, and network-free once
  dependency state is prepared.
- Keep generated Markdown and generated HTML out of maintained source control.
- Preserve atomic replacement for generated intermediate content.
- Keep routine ADR navigation textual and renderer-independent.
- Avoid introducing a runtime self-dependency or altering release artifacts.

## Decision

### Maintain framing and generate the composite page

The repository SHALL maintain:

```text
doc/adr/README.intro.md
doc/adr/README.outro.md
```

These files own stable repository-specific prose that appears before and after the
mechanically generated ADR list.

Documentation generation SHALL compose those files with `adrctl generate toc`
output into:

```text
doc/adr/README.md
```

The generated `README.md` SHALL be ignored by Git and SHALL NOT be committed as
ordinary repository state.

The responsibility boundary is:

```text
ADRs + README.intro.md + README.outro.md
    = maintained documentation source

released adrctl generate toc
    = ADR discovery, ordering, title extraction, and link serialization

Make
    = dependency sequencing, composition destination, and atomic replacement

doc/adr/README.md
    = ephemeral Doxygen input

doc/reference/
    = ephemeral Doxygen output
```

### Use a pinned released adrctl artifact as documentation tooling

`dependencies.txt` SHALL declare a previously released standard adrctl artifact at:

```text
vendor/adrctl.bash
```

The initial documentation-tool pin SHALL be:

```text
Release:  v0.0.13
Artifact: adrctl.bash
SHA-256:  5b5c34aeeff59cbadda1f9810c64983555013693139eae4746e979a556149e6e
```

The manifest SHALL use the immutable release-asset URL and committed SHA-256
digest established by the repository dependency model.

This artifact is development/documentation tooling under the classification in
ADR-008.  It SHALL NOT be concatenated, embedded, sourced, or otherwise included
in any current `dist/adrctl*.bash` product artifact.

The released documentation tool and the current product source have separate
roles:

```text
vendor/adrctl.bash
    -> generates documentation navigation

lib/*.bash + src/adrctl.bash + product build dependencies
    -> generate current adrctl distribution artifacts
```

The build SHALL NOT use `vendor/adrctl.bash` as an implementation source for the
current product.  Product tests and release validation SHALL continue to exercise
the current generated distribution artifacts built from maintained source.

### Avoid a bootstrap cycle

The self-referential project name does not create a dependency bootstrap cycle.
Make continues to bootstrap only the previously released bashdeps executable as
governed by ADR-021.  That bashdeps executable reads `dependencies.txt` and
materializes the released adrctl documentation artifact alongside the other
ordinary dependencies.

The dependency path is therefore:

```text
Make
  -> pinned released bashdeps bootstrap
      -> dependencies.txt
          -> released adrctl documentation tool
```

The current adrctl build is not needed to obtain or execute the released
documentation tool.

### Provide `make adr-index`

The Makefile SHALL expose:

```text
make adr-index
```

The target SHALL consume already-prepared `vendor/adrctl.bash` state and SHALL NOT
invoke `make deps`, perform release discovery, or intentionally access the
network.

`make adr-index` SHALL:

1. verify that the released adrctl documentation artifact is readable;
2. require the maintained introduction and conclusion fragments;
3. invoke the released tool through Bash rather than depending on executable mode;
4. request `generate toc` through the public CLI;
5. write the complete candidate to a temporary file beside the destination; and
6. replace `doc/adr/README.md` only after successful complete generation.

A failed report therefore does not intentionally publish a partial landing page.

### Integrate generation with `make docs`

`make docs` SHALL preserve the network-capable dependency-preparation behavior
already accepted by ADR-021.  It SHALL prepare manifest-managed dependencies and
complete existing reference-output cleanup before invoking `make adr-index` and
Doxygen.

The sequencing between dependency preparation and ADR-index generation SHALL be
explicit.  The implementation SHALL NOT rely on parallel Make prerequisite order
to ensure that `vendor/adrctl.bash` exists before the generator executes.

The effective high-level path is:

```text
make docs
  -> prepare manifest-managed dependencies
  -> generate ephemeral ADR landing page
  -> run Doxygen
```

`make adr-index` remains usable separately after `make deps` when a contributor
wants to inspect the generated Markdown without running Doxygen.

### Keep cleanup responsibilities separated

`make docs-clean` SHALL remain focused on `doc/reference/` Doxygen output.  It
SHALL NOT become a prerequisite that deletes the ADR landing page while another
parallel prerequisite may generate it.

`make distclean` SHALL remove the generated ADR landing page as part of complete
generated-state cleanup.

A successful `make docs` MAY leave ignored `doc/adr/README.md` available for local
inspection after Doxygen finishes.

### Publish selected maintained project documentation

Doxygen SHALL consume the generated ADR landing page, the ADR corpus, maintained
Bash source, and selected maintained project documentation appropriate to the
public reference site.

The generated page SHALL be configured as:

```text
USE_MDFILE_AS_MAINPAGE = doc/adr/README.md
```

The maintained framing fragments SHOULD be excluded from independent Doxygen page
discovery because the generated main page already contains their content.
Generated `doc/reference/` output and vendored tooling remain excluded.

Historical working assessments and repository-process documents need not be
published merely because they live under `doc/`; Doxygen input remains an
intentional publication surface rather than an automatic mirror of every
repository Markdown file.

### Keep routine graph publication out of scope

`adrctl generate graph` remains a supported product capability under ADR-012 and
ADR-025.  This documentation pipeline SHALL NOT invoke it automatically.

The generated landing page SHALL NOT include a Mermaid relationship block, DOT
source, Graphviz rendering, or graph-specific link configuration as part of
ordinary publication.

This decision does not prohibit users or other repositories from explicitly
composing graph output when they find it useful.  It defines only adrctl's own
routine documentation publication path.

### Dependency version updates are deliberate

The released adrctl documentation-tool pin SHALL change only through an explicit
reviewed dependency update.

A current-source change to `generate toc` does not automatically alter adrctl's
own documentation build.  If publication requires behavior introduced by a newer
adrctl release, the repository SHALL first publish or identify a release that
contains the required public behavior, then update the documentation-tool pin and
digest deliberately.

This lag is an accepted reproducibility boundary, not a promise that documentation
always dogfoods the unreleased current implementation.

## Promises

1. The published reference site has a project-specific ADR landing page as its
   main page.
2. ADR enumeration is generated from the repository's managed ADR corpus through
   adrctl's public `generate toc` command.
3. Stable framing remains maintained in `README.intro.md` and `README.outro.md`.
4. `doc/adr/README.md` is generated, ignored, and not maintained in Git.
5. ADR-index generation replaces its destination only after complete successful
   generation.
6. `make docs` may continue to prepare manifest-managed dependencies according to
   ADR-021.
7. `make adr-index` itself consumes prepared state and performs no intentional
   network access.
8. The released adrctl documentation tool remains outside current product source
   closure and release artifacts.
9. Current adrctl product validation remains based on artifacts built from current
   maintained source rather than on the released documentation tool.
10. Routine documentation publication does not generate an ADR relationship graph.

## Non-Promises

1. The generated ADR landing page is not maintained architectural source.
2. Browsing `doc/adr/` on GitHub is not promised to show the generated composite
   README in a pristine checkout.
3. The released documentation-tool version is not promised to equal the version
   currently being developed.
4. `make adr-index` does not bootstrap or synchronize its own dependencies.
5. The documentation tool is not a runtime dependency of adrctl.
6. The documentation tool is not embedded into development, standard, or minified
   adrctl distribution artifacts.
7. This decision does not change `generate toc` public behavior.
8. This decision does not deprecate or remove `generate graph`.
9. Doxygen publication is not required to mirror every Markdown file under
   `doc/`.
10. This decision does not alter ADR-026's current Proposed status.

## Adversary and Failure Model

The released adrctl artifact executes during documentation generation and is part
of the documentation trusted computing base.  Its committed SHA-256 digest
authorizes exact expected bytes but does not prove behavioral safety.  Dependency
review remains necessary when the pin changes.

A compromised or defective documentation tool could emit incorrect links or
navigation.  The authoritative ADR files and maintained framing remain available
for review, and the generated output is derivative rather than promoted to source
truth.

A failed report generator could otherwise leave truncated Markdown at the Doxygen
main-page path.  Same-directory candidate generation followed by rename-style
replacement only on success bounds the ordinary partial-write failure mode.

A stale local generated README may exist after ADR changes.  `make docs`
regenerates it before Doxygen consumption, so publication does not trust stale
intermediate state left by an earlier build.

Executing the current unreleased product during documentation generation would
give build artifacts and their dependencies authority that is unnecessary for TOC
serialization.  Using the pinned released CLI narrows that path and keeps current
product assembly independently testable.

Conversely, using a released tool means a newly introduced current-source TOC
feature is unavailable to the documentation build until the pin is updated.  The
build SHALL fail visibly when it requires unsupported behavior rather than
silently falling back to private current-source implementation.

The repository's existing bashdeps bootstrap remains the root of dependency
materialization.  Adding a released adrctl artifact to `dependencies.txt` does not
authorize that artifact to modify the current source tree beyond the explicit
output redirection owned by Make.

## Operational Constraints

- `vendor/adrctl.bash` MUST be declared in `dependencies.txt` with a released,
  immutable asset URL and committed SHA-256 digest.
- the initial documentation-tool pin MUST use adrctl v0.0.13 with the digest
  recorded in this ADR unless a later reviewed change updates it.
- `vendor/adrctl.bash` MUST remain documentation/development tooling only.
- current adrctl distribution artifacts MUST NOT include the released
  documentation-tool bytes as an implementation input.
- `make adr-index` MUST consume prepared dependency state and MUST NOT synchronize
  dependencies.
- `make docs` MUST sequence dependency preparation before ADR index generation.
- `doc/adr/README.intro.md` and `doc/adr/README.outro.md` MUST remain maintained
  source.
- `doc/adr/README.md` MUST be ignored generated state.
- Doxygen MUST use the generated ADR landing page as its main page.
- `make docs-clean` MUST continue to clean Doxygen output without racing ADR-index
  generation.
- `make distclean` MUST remove the generated ADR landing page.
- routine documentation generation MUST NOT invoke `adrctl generate graph` or add
  relationship-graph rendering.

## Considered Alternatives

### Build and execute the current adrctl artifact

This would dogfood the exact current source and eliminate the one-release lag.
It was rejected for routine documentation because it would couple `make docs` to
product assembly, mktext embedding, Bash-Minifier preparation, generated artifact
creation, and product build semantics merely to obtain an already released report
capability.

### Execute maintained adrctl modules directly

The documentation build could source or concatenate selected current modules and
call internal helpers.  This was rejected because it would depend on private
implementation structure and create a privileged integration path that bypasses
the public CLI contract used by downstream consumers.

### Implement ADR enumeration in Make or shell utilities

A short local pipeline could discover filenames and extract headings.  It was
rejected because it would establish a second definition of candidate discovery,
logical numbering, title extraction, ordering, and link serialization in the
repository that already owns those semantics as product behavior.

### Commit the generated `doc/adr/README.md`

This would make the complete index visible automatically when browsing the ADR
directory on GitHub.  It was rejected because the page is mechanically
reproducible and exists primarily as an intermediate for another generated
publication surface.  Committing it would create an avoidable synchronization and
drift obligation.

### Generate the page only in the Pages workflow

This would satisfy hosted publication while leaving local `make docs` different
from CI.  The repository already treats Make as the canonical shared
orchestration interface, so local and CI documentation generation should use the
same path.

### Make `make adr-index` run dependency synchronization

That would make the focused target convenient on a pristine checkout but would
blur the existing preparation/consumption boundary.  The higher-level `make docs`
target already owns convenience synchronization under ADR-021.

### Use `doc/decisions.md` as the Doxygen main page

The decision summary is maintained and useful, but it serves a different role: it
summarizes architectural decisions rather than providing mechanically complete ADR
navigation and project-specific publication framing.  The generated landing page
keeps those responsibilities separate.

### Include the relationship graph in the landing page

ADR-025 makes graph output composable, but the textual TOC provides the routine
navigation needed by the reference site without adding renderer-specific content.
Graph publication remains an explicit downstream choice.

## Consequences

The Pages site gains an architecture-oriented entry point while generated Markdown
and generated HTML remain outside maintained source control.

The repository gains a self-referential-looking but bounded documentation
dependency: a previously released adrctl artifact generates navigation for the
current source tree.  Its role is explicit, checksum-pinned, and independent of
the current product build.

`make docs` downloads or repairs one additional manifest-managed artifact when
necessary.  `make deps-check` verifies it alongside the repository's other
ordinary dependencies.

The documentation pipeline no longer needs to know private ADR parsing or
serialization details and becomes a real consumer of the public `generate toc`
interface.

A current change to TOC behavior may require a later dependency-pin update before
adrctl's own documentation can use that change.  This is the accepted cost of
keeping publication reproducible and decoupled from current product assembly.

No runtime behavior, public command contract, current release artifact contents,
minimum Bash version, compatibility baseline, or graph capability changes.

## Related Decisions

- Related to: ADR-003: Pin, Verify, and Embed mktext as a Build Dependency
- Related to: ADR-008: Require Bash 4.3+ and Classify Runtime Dependencies
- Related to: ADR-013: Define Stable CLI Streams, Help, and Exit Statuses
- Related to: ADR-017: Use Documentation-First Source Comments and Generated Reference Docs
- Related to: ADR-020: Keep Generated Reference Documentation Out of Git
- Extends: ADR-021: Bootstrap bashdeps and Manage Build Dependencies Through a Manifest
- Related to: ADR-023: Separate ADR Candidate Selection from Logical Number Extraction
- Related to: ADR-025: Separate Graph Semantics from Serialization

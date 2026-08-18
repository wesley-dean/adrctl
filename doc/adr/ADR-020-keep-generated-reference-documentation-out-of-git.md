# ADR-020: Keep Generated Reference Documentation Out of Git

Date: 2026-08-17

## Status

Accepted

## Context

ADR-017 established Doxygen-compatible source documentation and generated
reference documentation under `doc/reference/`.  It also stated that generated
reference documentation SHOULD be committed, retained a sentinel README in that
directory, and required a `docs-stage` Make target.  ADR-015 likewise included
`docs-stage` in the minimum Make target surface.

Experience with the completed documentation workflow shows that committing the
generated output is unnecessary.  GitHub Pages can generate the Doxygen output
from maintained source in CI, upload `doc/reference` as a Pages artifact, and
deploy those exact generated files without storing them on the repository's
default branch.

The sibling `bashdeps` project uses this model successfully: `make docs`
regenerates `doc/reference`, the directory is ignored by Git, and the Pages
workflow publishes the generated directory directly.

Keeping generated HTML in Git would duplicate information already represented by
maintained Bash source and Doxygen configuration, increase repository churn, and
create opportunities for generated output to drift from the source that produced
it.

## Decision

Generated Doxygen reference documentation SHALL remain build output rather than
maintained repository content.

The generated reference output SHALL continue to live at:

```text
doc/reference/
```

The root `.gitignore` SHALL ignore:

```text
/doc/reference/
/vendor/
```

The repository SHALL NOT retain a sentinel file or generated documentation under
`doc/reference/` merely to keep that directory present in Git.

`make docs` SHALL create `doc/reference/` as needed and regenerate Doxygen output
from maintained source.

`make docs-clean` SHALL remove the complete generated `doc/reference/` directory.

The `docs-stage` target SHALL be removed.  Generated reference documentation
SHALL NOT have a project-supported staging path for committing it to the
repository.

GitHub Pages SHALL continue to generate the documentation in CI and upload the
resulting `doc/reference/` directory directly as the Pages artifact.  The Pages
workflow SHALL NOT commit, push, or otherwise persist generated documentation to
the repository.

CI SHOULD verify that documentation generation produces the expected Pages input
and that the generated directory is ignored by Git.

The README SHOULD expose the Pages deployment workflow through a Documentation
status badge alongside the project's other CI and security badges.

Source comments, `Doxyfile`, documentation tooling configuration, ADRs, README,
AGENTS, and other hand-maintained documentation remain repository content.  This
decision changes only the persistence model for generated Doxygen output.

## Considered Alternatives

### Continue committing generated reference documentation

This preserves browser access to generated files directly from the source tree,
but GitHub Pages already provides the intended browsable documentation.  The
additional committed copy creates churn and a second opportunity for generated
output to become stale.

### Keep only a sentinel README under doc/reference

A sentinel can explain how the directory is generated, but the directory itself
is disposable build output.  Keeping one tracked file complicates `docs-clean`,
requires special-case preservation logic, and weakens the otherwise clear
ownership boundary.

### Publish Pages from committed generated files

This avoids generating documentation during deployment, but it makes source
changes and generated output two separately committed states that must remain in
sync.  Generating Pages from the checked-out source produces a clearer and more
reproducible relationship.

## Consequences

Repository clones remain smaller and cleaner because Doxygen HTML is not tracked.

Documentation changes no longer require staging or reviewing generated HTML.

GitHub Pages remains the browsable distribution surface for reference
documentation.

A contributor who wants local reference documentation must run `make docs` and
will receive generated output under the ignored `doc/reference/` directory.

`make docs-clean` becomes simpler because it can remove the entire generated
directory.

The documentation CI job and Pages deployment remain important validation
surfaces because generated output is no longer visible in ordinary repository
diffs.

## Superseded Decisions

This ADR supersedes only the following portions of ADR-017:

- the recommendation to commit generated reference documentation;
- the sentinel README requirement; and
- the `docs-stage` requirement.

It also supersedes ADR-015 only insofar as ADR-015 requires `docs-stage` in the
minimum Make target surface.

All other decisions in ADR-015 and ADR-017 remain in force, including modular
source documentation, Doxygen-compatible comments, reproducible reference-doc
generation, and GitHub Pages publication.

## Related Decisions

- Supersedes portions of: ADR-015
- Supersedes portions of: ADR-017
- Related to: ADR-018
- Informed by the current `bashdeps` documentation-generation and Pages workflow.

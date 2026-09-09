# ADR-026: Maintain a Hand-Authored Section 1 Man Page

Date: 2026-09-06

## Status

Proposed

## Intent and Documentation Posture

This ADR defines the repository location, ownership boundary, and maintenance
policy for an `adrctl(1)` manual page.

The manual page is a user-facing command reference for Unix-like environments.
It complements the README and built-in help without becoming another normative
behavioral specification.  `doc/adrctl-spec.md` remains authoritative for the
public command contract, while the man page presents that contract in the
conventional interface expected by `man(1)` users and package maintainers.

## Context

The repository already separates documentation by role:

- `README.md` provides human-facing orientation and common usage;
- `doc/adrctl-spec.md` defines the normative public behavioral contract;
- ADRs record durable architectural rationale;
- `AGENTS.md` provides contributor and coding-agent guidance;
- source comments document implementation boundaries; and
- `doc/reference/` contains generated Doxygen reference documentation that is
  intentionally excluded from Git under ADR-020.

None of those surfaces provides a conventional section 1 manual page for an
installed command.  Users on Unix-like systems commonly expect `man adrctl` to
provide command syntax, options, environment variables, files, exit statuses,
and representative examples without requiring a browser or repository checkout.

A man page could be generated from built-in help, the README, the behavioral
specification, or another intermediate format.  The current project does not have
a documentation generator that owns consumer-facing CLI reference material, and
the built-in help intentionally remains concise.  Introducing a generation
pipeline solely for one manual page would add build dependencies and another
transformation boundary without eliminating the need to review the rendered
content for accuracy.

The man page also needs a clear relationship to the `adr` compatibility name.
ADR-002 and ADR-019 establish `adrctl` as the canonical product and command
identity while allowing the same executable to be reached through an `adr`
filesystem symlink.  Documentation should preserve that distinction rather than
create a second product identity.

## Decision Drivers

- Provide conventional offline command documentation for Unix-like users.
- Keep `doc/adrctl-spec.md` as the single normative public behavioral contract.
- Keep generated Doxygen output and hand-maintained product documentation
  separate under ADR-020.
- Avoid adding a documentation-generation dependency or build transformation
  without a demonstrated need.
- Keep the canonical product identity `adrctl` while documenting the supported
  `adr` compatibility invocation.
- Make the manual-page source visible and reviewable in ordinary repository
  diffs.
- Keep this change documentation-only and avoid introducing installation or
  packaging behavior implicitly.

## Decision

The repository SHALL maintain a section 1 manual page at:

```text
doc/adrctl.1
```

The file SHALL be hand-authored using conventional `man(7)`/roff macros so it can
be consumed directly by common manual-page tooling without a project-specific
conversion step.

The manual page SHALL use `adrctl` as the canonical command name and product
identity.  It SHALL document that the same executable may be invoked through the
supported `adr` filesystem symlink, but it SHALL NOT describe `adr` as a separate
runtime mode or independently maintained product.

The man page SHALL be consumer-oriented.  It SHOULD cover, as appropriate:

- command synopsis and built-in commands;
- global and command-specific options;
- project discovery and configuration;
- ADR reference behavior;
- templates and filename behavior;
- relevant environment variables and project files;
- standard-output and diagnostic boundaries;
- public exit statuses;
- representative examples;
- compatibility notes; and
- pointers to the repository and normative specification.

`doc/adrctl-spec.md` SHALL remain authoritative when describing public behavior.
The man page SHALL NOT create an independent normative contract.  If the man page
and the accepted ADR/specification corpus disagree, the conflict SHALL be
resolved by correcting the man page or deliberately changing the governing
architecture/specification rather than treating the manual page as an alternate
source of truth.

A public behavior change that makes existing man-page content inaccurate SHALL
update `doc/adrctl.1` in the same coherent change.  This is documentation drift
prevention, not a requirement to duplicate implementation-level detail in the
manual page.

The manual page SHALL remain committed hand-maintained repository content.  It
SHALL NOT be placed under `doc/reference/`, because that directory is generated
Doxygen build output governed by ADR-020.

This decision does not add an installation target, package-manager integration,
release asset, compressed man-page artifact, or automatic `adr.1` alias.  A
future packaging or installation change MAY install `doc/adrctl.1` into the
platform's section 1 manual hierarchy and MAY provide an `adr(1)` alias or
cross-reference where appropriate, but those behaviors require their own
explicit implementation scope.

## Considered Alternatives

### Generate the man page from built-in help

Built-in help is intentionally concise and does not contain the configuration,
environment, file, exit-status, and explanatory material expected from a complete
manual page.  Expanding help until it becomes a man-page source would weaken the
separation between interactive usage help and reference documentation.

### Generate the man page from the behavioral specification

The specification is normative and substantially more detailed than a useful
section 1 manual page.  A reliable conversion would require a maintained mapping
from specification structure to roff structure and would still need editorial
review.  The additional machinery is not justified for the current single-page
need.

### Convert a Markdown man-page source during the build

Markdown would be convenient to edit, but conversion would add a generator and
would make the directly installable manual page a generated artifact.  The
project already has a clear distinction between maintained product documentation
and generated reference output; direct roff keeps the new surface small and
inspectable.

### Place the manual page in a new top-level `man/` directory

A dedicated hierarchy is conventional in larger packaging-oriented projects, but
`adrctl` already establishes `doc/` as the durable documentation root and has only
one manual page.  Creating another documentation root provides little value at
this stage.

### Maintain separate `adrctl.1` and `adr.1` pages

Two maintained pages would duplicate content and could imply two product modes.
The canonical product remains `adrctl`; the `adr` name is a compatibility
invocation of the same executable.

### Add installation automation in the same change

An install target or packaging contract would introduce filesystem destinations,
privilege expectations, prefix handling, and platform policy beyond the request
for a manual page.  Keeping this decision documentation-only preserves executable
behavior and leaves packaging as a deliberate follow-up.

## Consequences

Unix-oriented users and packagers gain a conventional, directly consumable
`adrctl(1)` source file.

The repository gains one additional hand-maintained documentation surface that
must remain synchronized with public behavior.  Reviewers should therefore treat
man-page drift as a documentation defect when a CLI change affects documented
content.

No runtime behavior, build artifact, dependency, release artifact, or installation
path changes as a consequence of this ADR alone.

Keeping the page in roff avoids a generation dependency but requires contributors
editing it to understand a small set of conventional man-page macros and escaping
rules.

The project can add packaging or installation support later without changing the
manual-page source-of-truth decision.

## Open Questions and Follow-Ups

A later packaging or installation effort may decide whether the project should:

- install the page automatically;
- compress installed manual pages;
- provide an `adr(1)` symlink or `.so` cross-reference; or
- validate rendered man-page output in CI.

Those choices are intentionally outside this documentation-only change.

## Related Decisions

- Related to: ADR-002
- Related to: ADR-013
- Related to: ADR-017
- Related to: ADR-018
- Related to: ADR-019
- Related to: ADR-020

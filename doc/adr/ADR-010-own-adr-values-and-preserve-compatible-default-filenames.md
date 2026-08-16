# ADR-010: Own ADR Values and Preserve Compatible Default Filenames

Date: 2026-08-15

## Status

Accepted

## Context

`mktext` owns textual substitution, while `adrctl` must own every ADR-specific
value supplied to that renderer.  This includes values used in document bodies
and in configurable filenames.

The predecessor establishes observable defaults that users may depend on:
numbered Markdown files, four-digit zero padding in filenames, an unpadded ADR
number inside the template, lowercase hyphenated title slugs, ISO-style dates,
and an initial status of `Accepted` for ordinary `adr new` operations.

Modern filename templates can provide useful flexibility, but compatibility
requires those capabilities to be opt-in rather than silently changing existing
file naming.

## Decision

`adrctl` SHALL prepare the rendering context used for ADR body and filename
rendering.  `mktext` SHALL NOT derive ADR-specific values.

The initial context SHALL include at least these canonical keys where applicable:

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

`NUMBER` SHALL be the logical ADR number without forced zero padding.

`NUMBER4` SHALL be the same logical number formatted with a minimum width of four
decimal digits using leading zeroes.  Numbers larger than four digits SHALL NOT
be truncated.

`TITLE` SHALL be the title formed from the command's title arguments according to
the public command contract.

`TITLE_SLUG` SHALL preserve the predecessor's default intent: convert the title to
a lowercase, hyphen-separated filename component containing alphanumeric runs,
collapse non-alphanumeric separators, and remove leading or trailing separators.
The compatibility corpus SHALL define the exact behavior for punctuation,
whitespace, and non-ASCII input before implementation is considered complete.

`DATE` SHALL default to the current local date in `YYYY-MM-DD` form.  The legacy
`ADR_DATE` environment variable SHALL remain a supported compatibility override
for commands that create ADRs unless a higher-precedence modern command option or
configuration value explicitly controls the date.

The default initial status for an ordinary new ADR SHALL remain `Accepted` for
`adr-tools` compatibility.  A future workflow that creates Proposed ADRs MAY
provide an explicit option or template, but it SHALL NOT silently change the
compatibility default.

The default filename pattern SHALL remain behaviorally equivalent to:

```text
{NUMBER4}-{TITLE_SLUG}.md
```

A configurable filename pattern MAY replace that default through the precedence
model in ADR-009.  Changing the pattern is an explicit project choice.

Filename rendering SHALL use the same prepared `adrctl` context and `mktext`
substitution boundary used for body templates.  `adrctl` SHALL validate the
rendered filename before filesystem mutation.  A rendered filename SHALL NOT be
allowed to escape the configured ADR directory through absolute paths, `..`
traversal, or path separators unless a later ADR explicitly introduces nested
filename patterns.

The body template SHALL continue to receive the legacy values needed by existing
`adr-tools` templates, including `NUMBER`, `TITLE`, `DATE`, and `STATUS`.
ADR-001 controls whether those keys are rendered with braces, bare tokens, or an
explicit custom delimiter pair.

## Considered Alternatives

### Let mktext derive number, slug, date, or paths

That would violate the dependency boundary and turn a small text renderer into an
ADR-aware application component.

### Change the default status to Proposed

Proposed is useful for the development process of this repository, but changing
`adr new`'s default would be a user-visible predecessor incompatibility.  Users
can opt into a different workflow explicitly.

### Use a new filename format by default

That would break scripts, links, documentation conventions, and user expectations
for little benefit.  Filename flexibility should be available without making
migration mandatory.

### Permit arbitrary rendered paths

A filename template is intended to select a name inside the ADR directory.  Letting
it escape that boundary would make a presentation feature control unrelated
filesystem locations and complicate preflight safety.

## Consequences

The renderer stays generic while `adrctl` has one auditable place where ADR
semantics are prepared.

Existing repositories keep their familiar filename and template values by
default.

New filename patterns can be added without changing compatibility behavior.

## Related Decisions

- Related to: ADR-001
- Related to: ADR-003
- Related to: ADR-007
- Related to: ADR-009
- Adapted from `mktext` ADR-001, ADR-004, and ADR-005.
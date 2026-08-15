# mktext Delimiter Integration for adrctl

## Status

Working architecture note.  This note records an agreed integration direction
while the corresponding `mktext` documentation and pull request are still being
completed.  The final `adrctl` architecture should capture this decision in the
Proposed ADR corpus and normative behavioral specification.

## Context

Canonical `adr-tools` body templates use unbraced replacement tokens such as:

```text
TITLE
STATUS
NUMBER
DATE
```

The initial `mktext` release recognizes delimited macros such as:

```text
{TITLE}
{STATUS}
{NUMBER}
{DATE}
```

That difference originally implied that `adrctl` might need a separate legacy
body-template renderer in order to preserve existing project templates.

The `mktext` project has since been updated to accept render-time
`--start-delimiter` and `--end-delimiter` options.  The maintainer has indicated
that the remaining work is documentation and merging the corresponding pull
request.

## Agreed direction

`adrctl` should use `mktext` as the single template-rendering dependency for both
legacy-compatible and modern template syntax.

The normal `mktext` delimiter behavior remains appropriate for modern templates.
Legacy `adr-tools` body templates can be rendered by supplying empty starting and
ending delimiters once the updated `mktext` behavior is merged and published.

Conceptually:

```text
modern template rendering:
    start delimiter = "{"
    end delimiter   = "}"

legacy adr-tools template rendering:
    start delimiter = ""
    end delimiter   = ""
```

This removes the need for an `adrctl`-owned compatibility renderer and preserves
the intended responsibility boundary:

```text
value acquisition and transformation -> adrctl
template substitution                -> mktext
```

`adrctl` remains responsible for deriving ADR-specific values such as the ADR
number, zero-padded number, title, slug, status, date, and project root.  `mktext`
remains responsible only for textual substitution according to its documented
render contract.

## Compatibility consequence

Existing valid `adr-tools` project templates should not need to be rewritten
merely because `adrctl` uses `mktext` internally.

The compatibility corpus should contain representative legacy templates and
exercise the exact `mktext` delimiter configuration that `adrctl` uses.  Modern
braced templates should be tested separately so both rendering contracts remain
explicit.

The implementation should preserve successful predecessor behavior rather than
assuming every incidental `sed` edge case is a compatibility requirement.  Any
observable difference discovered by the compatibility corpus should be classified
as compatible, an intentional deviation, or a defect before release.

## Dependency versioning

The `adrctl` build must not pin a particular `mktext` release or commit until the
configurable-delimiter change is documented and merged in the `mktext`
repository.

After merge, the `adrctl` dependency decision should identify a specific
versioned `mktext` artifact or immutable source revision and define its
verification and update process.  Runtime network access should not be required
for template rendering.

## Architectural effect

The earlier open question "How should legacy templates coexist with mktext
templates?" is no longer a blocking product-architecture question in principle.
The selected direction is one renderer with render-time delimiter configuration.

The remaining work is to verify the merged `mktext` contract, pin the dependency,
and express the integration behavior precisely in the `adrctl` ADRs,
specification, and tests.

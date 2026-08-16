# mktext Delimiter Integration for adrctl

## Status

Working architecture note.  The `mktext` capabilities required by `adrctl` were
first completed in `mktext` release `v0.0.6`.  The current pinned dependency is
`v0.0.7`, which preserves that rendering and embedding contract while stripping
full-line source comments from the `mktext.bash` distribution artifact in the
`mktext` build itself.

The current pinned dependency is:

```text
Release:      v0.0.7
Artifact:     mktext.bash
SHA-256:      213cee4663512954f486c8a6ff00ddd36a9b4c48ceb3e9b71d9ec70a36c1e0dd
```

Release `v0.0.7` retains the configurable render delimiters and
concatenation-safe direct-execution guard required for embedding `mktext` in the
generated `adrctl.bash` distribution artifact.  Its packaging change is owned by
`mktext`; `adrctl` continues to verify and embed the published dependency bytes
unchanged.

## Context

Canonical `adr-tools` body templates use unbraced replacement tokens such as:

```text
TITLE
STATUS
NUMBER
DATE
```

The original `mktext` grammar uses delimited macros such as:

```text
{TITLE}
{STATUS}
{NUMBER}
{DATE}
```

That difference originally implied that `adrctl` might need a separate legacy
body-template renderer in order to preserve existing project templates.

`mktext` now accepts render-time `--start-delimiter` and `--end-delimiter`
options.  Its normal defaults remain `{` and `}`.  Supplying empty strings for
both options selects bare-key mode.

`mktext` also constrains its direct-execution entrypoint to supported `mktext`
invocation basenames.  When the same source is concatenated into `adrctl.bash`,
installed or linked as `adrctl`, or reached through an `adr` symlink, the embedded
`mktext` entrypoint remains inert and execution can continue to the `adrctl`
entrypoint.

## Verified mktext contract

The current `mktext` specification defines the public render form as:

```text
mktext render CONTEXT [--start-delimiter STRING] [--end-delimiter STRING]
```

The verified behavior relevant to `adrctl` is:

- delimiter options apply only to the current render invocation;
- default delimiters are `{` and `}`;
- two non-empty delimiters are matched as literal strings;
- two empty delimiters select bare-key mode;
- a one-sided empty delimiter pair is invalid usage;
- delimiters containing newlines are invalid;
- bare-key mode scans complete lexical key tokens rather than arbitrary
  substrings;
- bare-key lookup is case-sensitive;
- normal public contexts populated through `mktext set` therefore naturally
  recognize uppercase legacy markers such as `TITLE`, `STATUS`, `NUMBER`, and
  `DATE` while leaving ordinary lower- and mixed-case prose unchanged;
- inserted values remain literal and nonrecursive;
- delimiter selection does not mutate the caller-owned context;
- readonly contexts remain valid for rendering;
- direct execution is owned only by supported `mktext` basenames; and
- concatenated embedding under another executable basename leaves `mktext` inert
  at top level.

These semantics are sufficient for `adrctl` to use one renderer while preserving
ordinary `adr-tools` template syntax and the single-file build model.

## Agreed adrctl direction

`adrctl` SHALL use `mktext` as the single template-rendering dependency for both
legacy-compatible and modern template syntax.

`adrctl` ADR-001 defines delimiter selection policy.  In summary:

1. explicit delimiter configuration wins over automatic detection;
2. when no explicit pair is configured, `adrctl` inspects the unrendered
   template for a recognized braced token whose key exists in the prepared render
   context;
3. a recognized braced token selects `{` and `}`;
4. otherwise `adrctl` selects empty delimiters and therefore `mktext` bare-key
   mode; and
5. exactly one delimiter pair is selected for one render operation.

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
delimiter selection                   -> adrctl
template substitution                 -> mktext
```

`adrctl` remains responsible for deriving ADR-specific values such as the ADR
number, zero-padded number, title, slug, status, date, and project root.  `mktext`
remains responsible only for textual substitution according to its documented
render contract.

## Build and embedding consequence

The `adrctl` build may incorporate the pinned `mktext.bash` release artifact into
the generated `adrctl.bash` distribution artifact by ordered concatenation
without rewriting or removing the `mktext` direct-execution guard.

The final executable SHALL still have one effective product entrypoint owned by
`adrctl`.  The embedded `mktext` guard remains inert when the artifact is executed
as `adrctl.bash`, installed or linked as `adrctl`, or reached through the
supported `adr` symlink, because none of those basenames is `mktext` or
`mktext.bash`.

A shell alias that expands to the `adrctl.bash` path does not alter the executed
script basename, so the same guard behavior applies without a special embedding
mode.

The build should verify the downloaded dependency against the pinned SHA-256
before incorporating it.  A checksum mismatch SHALL fail the build before the
dependency is used.

`adrctl` SHALL NOT strip, rewrite, or otherwise post-process `mktext.bash` during
assembly.  Distribution cleanup inside `mktext.bash`, including comment stripping,
is the responsibility of the `mktext` build and release process.

Runtime network access SHALL NOT be required for template rendering.  Dependency
acquisition is a build-time concern.

## Compatibility consequence

Existing valid `adr-tools` project templates should not need to be rewritten
merely because `adrctl` uses `mktext` internally.

The compatibility corpus should contain representative legacy templates and
exercise the exact empty-delimiter configuration that `adrctl` selects.  Modern
braced templates should be tested separately, together with ambiguous templates,
explicit custom delimiters, and unrelated brace expressions.

Generated-artifact tests should also verify that the embedded `mktext` entrypoint
does not claim `adrctl` arguments when the final artifact is executed directly as
`adrctl.bash`, under the installed `adrctl` name, or through an `adr` symlink.

The implementation should preserve successful predecessor behavior rather than
assuming every incidental `sed` edge case is a compatibility requirement.  Any
observable difference discovered by the compatibility corpus should be classified
as compatible, an intentional deviation, or a defect before release.

## Dependency versioning

`mktext` `v0.0.6` is the first published release that satisfies the complete
currently known `adrctl` rendering and embedding requirements.

`mktext` `v0.0.7` changes only the dependency's distribution packaging: its build
strips full-line source comments before publishing `mktext.bash`.  The public
renderer/runtime source did not change between the two releases.  `adrctl`
therefore pins `v0.0.7` and its SHA-256 digest while preserving the same dependency
contract established by ADR-001 and ADR-003.

A later upgrade should remain an intentional dependency change that updates the
pinned version and digest together and reruns the `adrctl` compatibility and
generated-artifact test suite.

## Architectural effect

The earlier questions "How should legacy templates coexist with mktext
templates?" and "Can the executable mktext artifact be safely embedded by
concatenation?" are resolved.

The architecture uses one renderer, `mktext`, with `adrctl` choosing the
effective delimiter pair according to ADR-001.  The current `v0.0.7` dependency
can be verified and concatenated into `dist/adrctl.bash` unchanged while leaving
process startup under `adrctl` ownership.
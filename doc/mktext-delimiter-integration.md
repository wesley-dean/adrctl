# mktext Delimiter Integration for adrctl

## Status

Working architecture note.  The configurable-delimiter capability has now been
merged into `wesley-dean/mktext` `main` and documented in the normative `mktext`
behavioral specification.  This note records the verified dependency contract
that informs `adrctl` ADR-001 and the later dependency/versioning decision.

Verified upstream merge commit:

```text
a5486bface8b72920c6670fa62fae7c28a773708
```

The merge commit records pull request #6, `feat: support configurable render
delimiters`.

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

The merged `mktext` contract now accepts render-time `--start-delimiter` and
`--end-delimiter` options.  Its normal defaults remain `{` and `}`.  Supplying
empty strings for both options selects bare-key mode.

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
- readonly contexts remain valid for rendering.

These semantics are sufficient for `adrctl` to use one renderer while preserving
ordinary `adr-tools` template syntax.

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
   mode;
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

## Compatibility consequence

Existing valid `adr-tools` project templates should not need to be rewritten
merely because `adrctl` uses `mktext` internally.

The compatibility corpus should contain representative legacy templates and
exercise the exact empty-delimiter configuration that `adrctl` selects.  Modern
braced templates should be tested separately, together with ambiguous templates,
explicit custom delimiters, and unrelated brace expressions.

The implementation should preserve successful predecessor behavior rather than
assuming every incidental `sed` edge case is a compatibility requirement.  Any
observable difference discovered by the compatibility corpus should be classified
as compatible, an intentional deviation, or a defect before release.

## Dependency versioning

The configurable-delimiter capability is no longer a blocker to selecting an
`mktext` dependency revision.

The `adrctl` dependency decision should prefer a versioned `mktext` release
artifact that contains merge commit
`a5486bface8b72920c6670fa62fae7c28a773708` or later and should define its
verification and update process.  If implementation begins before such a release
is available, that immutable merge commit is sufficient as a development
reference, but a moving `main` branch SHALL NOT become the production build
input.

Runtime network access should not be required for template rendering.  The final
`adrctl` build/release architecture will define how the pinned `mktext` artifact
is verified and incorporated into the generated executable.

## Architectural effect

The earlier question "How should legacy templates coexist with mktext
templates?" is resolved.

The architecture uses one renderer, `mktext`, with `adrctl` choosing the
effective delimiter pair according to ADR-001.  Remaining work is limited to
pinning an immutable release artifact or revision, incorporating it into the
build, and verifying the complete behavior through the `adrctl` compatibility
corpus and generated-artifact tests.

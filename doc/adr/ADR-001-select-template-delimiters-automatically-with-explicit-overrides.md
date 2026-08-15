# ADR-001: Select Template Delimiters Automatically with Explicit Overrides

Date: 2026-08-15

## Status

Proposed

## Intent and Documentation Posture

This ADR defines how `adrctl` selects the token delimiters used when it delegates
template rendering to `mktext`.

The decision exists primarily to preserve compatibility with existing
`adr-tools` templates while allowing `adrctl` and its users to adopt the clearer
braced token syntax supported by `mktext`.  The selection behavior must remain
predictable enough that a repository can determine which template language will
be used without depending on hidden migration state or a second rendering
implementation.

This ADR deliberately separates delimiter selection, which is `adrctl` policy,
from textual substitution, which remains the responsibility of `mktext`.

## Context

Canonical `adr-tools` templates use bare replacement tokens such as:

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

`mktext` has since added render-time `--start-delimiter` and
`--end-delimiter` options.  Supplying an empty string for both delimiters allows
`mktext` to render the bare-token form used by legacy `adr-tools` templates.
This removes the architectural need for `adrctl` to maintain a second legacy
renderer.

Requiring every existing repository to configure empty delimiters would weaken
the compatibility goal.  Requiring every new repository to configure braces
would add unnecessary ceremony.  `adrctl` can distinguish the common cases by
inspecting the template immediately before rendering.

Automatic detection must nevertheless remain conservative.  Markdown,
documentation, code examples, and other template text can legitimately contain
brace expressions that are unrelated to `adrctl`.  A syntactically plausible
brace expression alone is therefore insufficient evidence that the template is
using the braced `mktext` convention.

Users also need an escape hatch for intentionally unusual or ambiguous
conventions.  Delimiter selection therefore needs an explicit configuration
surface whose result takes precedence over automatic detection.

## Decision Drivers

- Preserve existing valid `adr-tools` body templates without requiring rewrites.
- Use `mktext` as the single text-substitution implementation in `adrctl`.
- Make modern braced templates work without mandatory configuration.
- Avoid treating unrelated Markdown or code braces as template-mode markers.
- Keep automatic behavior deterministic and explainable.
- Give users explicit control when a template is ambiguous or uses another
  delimiter convention.
- Preserve `mktext`'s responsibility boundary rather than adding ADR-specific
  parsing semantics to the renderer.
- Avoid multi-pass rendering, hidden migrations, or template mutation merely to
  determine syntax.

## Decision

`adrctl` SHALL use `mktext` as its template-rendering implementation.

Delimiter selection SHALL occur before each render operation.  The effective
selection SHALL follow this precedence, from highest to lowest:

1. explicit command-line delimiter options;
2. explicit process-environment delimiter configuration;
3. explicit project delimiter configuration;
4. automatic template detection.

The public command-line options SHALL be:

```text
--start-delimiter VALUE
--end-delimiter VALUE
```

The environment and project-configuration names SHALL be:

```text
ADRCTL_TEMPLATE_START_DELIMITER
ADRCTL_TEMPLATE_END_DELIMITER
```

An explicit delimiter pair SHALL always win over automatic detection.

At a given explicit configuration layer, the starting and ending delimiter
SHALL be provided together or neither SHALL be provided.  Supplying only one
member of the pair SHALL be a configuration or usage error.  `adrctl` SHALL NOT
silently complete a partial pair from a lower-precedence configuration layer or
from automatic detection.

Empty strings are valid explicit delimiter values.  Therefore the following
configuration intentionally selects legacy bare-token rendering:

```text
start delimiter = ""
end delimiter   = ""
```

When no explicit delimiter pair is effective, `adrctl` SHALL inspect the
unrendered template for a recognized braced render token.

A syntactically eligible braced token has the form:

```text
{ OPTIONAL-BLANKS KEY OPTIONAL-BLANKS }
```

where `OPTIONAL-BLANKS` means zero or more ASCII spaces or horizontal tabs and
`KEY` follows the `mktext` key grammar:

```text
[A-Za-z][A-Za-z0-9_-]*
```

A regular-expression representation of the lexical shape is approximately:

```text
\{[[:blank:]]*[A-Za-z][A-Za-z0-9_-]*[[:blank:]]*\}
```

Syntax alone SHALL NOT select braced mode.  The candidate key, after applying
the same key normalization used by the rendering contract, SHALL also exist in
the render context prepared by `adrctl` for that operation.

Examples of tokens that may establish braced mode when their keys exist in the
render context include:

```text
{TITLE}
{ NUMBER }
{NUMBER4}
{STATUS}
{DATE}
{PROJECT_ROOT}
```

An unrelated expression such as `{foo}` SHALL NOT establish braced mode merely
because it has a valid lexical shape when `FOO` is absent from the prepared
render context.

If at least one recognized braced render token is present, `adrctl` SHALL invoke
`mktext` with:

```text
--start-delimiter "{"
--end-delimiter "}"
```

If no recognized braced render token is present, `adrctl` SHALL invoke `mktext`
with:

```text
--start-delimiter ""
--end-delimiter ""
```

This fallback preserves the token style used by existing `adr-tools` templates.

Automatic detection SHALL select exactly one delimiter pair for one render.
`adrctl` SHALL NOT automatically render the same template multiple times using
different delimiter conventions and SHALL NOT combine bare and braced token
recognition in one implicit rendering pass.

Consequently, a template containing both a recognized braced token and intended
legacy bare tokens is considered ambiguous.  Automatic detection will select the
braced delimiter pair.  Users who intend the bare-token interpretation SHALL
select empty delimiters explicitly.  Users who intend another delimiter
convention SHALL provide that pair explicitly.

Delimiter detection SHALL inspect the template before substitution.  Replacement
values SHALL NOT influence delimiter selection, and inserted values SHALL NOT
cause another detection or rendering pass.

This ADR defines delimiter-selection policy.  It does not change ownership of
render-context values.  `adrctl` remains responsible for acquiring and
transforming ADR-specific values such as number forms, title, slug, status,
date, and project root.  `mktext` remains responsible for textual substitution
according to its own documented rendering contract.

## Considered Alternatives

### Require legacy templates to configure empty delimiters

This would keep selection entirely explicit, but every existing `adr-tools`
repository would need new configuration before `adrctl` could render an
otherwise valid template.  That would turn an internal renderer change into a
migration requirement and weaken the project's compatibility objective.

### Require existing templates to be rewritten with braces

Migrating `TITLE` to `{TITLE}` and similar tokens would provide one visible
syntax, but it would unnecessarily modify existing repositories and could make
adoption of `adrctl` disruptive.  Existing valid templates are a compatibility
surface and should remain usable.

### Maintain a separate legacy renderer in adrctl

A second renderer could duplicate the predecessor's substitution behavior while
`mktext` handled modern templates.  This was rejected because it would split
text-substitution responsibility across two implementations, duplicate tests and
failure modes, and undermine the deliberately narrow `mktext` dependency
boundary.

### Detect any brace expression that matches the token grammar

This would be straightforward but too eager.  Templates may contain Markdown,
code, examples, or prose containing valid-looking brace expressions that are not
intended for `adrctl`.  Requiring the detected key to exist in the prepared
render context reduces false mode selection while keeping the rule explainable.

### Render once with braces and then again with empty delimiters

A two-pass strategy could replace both forms in one template.  It was rejected
because it creates recursive and order-dependent behavior: values inserted by
the first pass could become tokens in the second pass, and literal text could be
modified merely because it resembles a key.  One render operation should have
one explicit token grammar.

### Search simultaneously for braced and bare tokens

A combined grammar would make many mixed templates appear convenient, but bare
identifiers share lexical space with ordinary prose.  Combining the grammars
would make substitution harder to reason about and would create ambiguity over
which syntax owns overlapping text.  Selecting one delimiter pair keeps the
rendering contract inspectable.

### Let mktext auto-detect delimiters

Delimiter auto-detection depends on the semantic render context and the
compatibility policy of the calling product.  `mktext` deliberately does not know
what an ADR is or which keys are meaningful to `adrctl`.  Detection therefore
belongs to `adrctl`; `mktext` should receive an explicit delimiter pair and
perform substitution.

## Consequences

Existing `adr-tools` templates using bare tokens can remain unchanged and should
render through `mktext` without a separate compatibility renderer.

New templates can use the clearer braced syntax without mandatory configuration
when they contain at least one recognized `adrctl` render token.

Repositories with other conventions can select delimiter strings explicitly.
The same mechanism can support conventions such as `{{NAME}}` without adding a
new renderer or changing `mktext` semantics.

Automatic detection is intentionally conservative.  A syntactically valid
braced expression whose key is not present in the render context will not switch
the template to braced mode.

Mixed legacy and braced syntax is not implicitly supported in a single render.
Ambiguous templates must use explicit delimiter configuration when the automatic
choice does not express the author's intent.

The delimiter pair becomes part of effective `adrctl` configuration and must be
included in configuration-precedence tests, diagnostics, documentation, and
compatibility fixtures.

The compatibility corpus must include representative upstream `adr-tools`
templates, modern braced templates, unrelated brace text, ambiguous mixed
syntax, explicit empty delimiters, and explicit non-default delimiter pairs.

The exact `mktext` artifact used by `adrctl` must provide the documented
render-time delimiter options before the dependency can be pinned for the
initial release.

## Open Questions and Follow-Ups

The general configuration ADR and behavioral specification must define the exact
syntax used to represent empty delimiter values in project configuration and in
shell examples so that an intentional empty string is distinguishable from a
missing setting.

The implementation and compatibility corpus must verify the final merged
`mktext` behavior for empty delimiters before this integration is considered
complete.

If future evidence shows that automatic detection causes material ambiguity in
real repositories, a later ADR may refine or remove auto-detection while
preserving explicit delimiter configuration as the deterministic escape hatch.

## Related Decisions

- Related to: ADR-000
- Related to: `doc/mktext-delimiter-integration.md`
- Related to: `doc/architecture-portability-assessment.md`
- Related to: `doc/upstream-adr-tools-compatibility.md`
- Informed by: `mktext` ADR-001, ADR-004, ADR-005, and issue #5

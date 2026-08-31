# ADR-025: Separate Graph Semantics from Serialization

Date: 2026-08-30

## Status

Accepted

## Intent and Documentation Posture

This ADR defines the architectural boundary between ADR relationship discovery
and graph serialization.

The existing `generate graph` report remains the semantic product.  Graphviz DOT
remains its compatibility/default representation, while callers may explicitly
select Mermaid as another textual representation of the same graph.

The important decision is not merely to add Mermaid syntax.  It is to ensure that
node discovery, logical ADR numbering, sequence relationships, and status-section
relationships are modeled once and then serialized independently so graph
semantics cannot drift between formats.

## Context

`adrctl` inherited `generate graph` from `adr-tools`.  The existing implementation
combines several responsibilities in one command path:

- collecting managed ADRs;
- reading ADR titles;
- determining sequence edges between consecutive logical ADR numbers;
- parsing Status-section relationship links;
- filtering reciprocal relationship labels ending in ` by`;
- constructing node URLs; and
- writing Graphviz DOT syntax.

That was sufficient while DOT was the only representation.  Issue #15 introduces
a second representation, Mermaid, motivated by documentation systems such as
GitHub Markdown that can render Mermaid directly.

Implementing Mermaid by duplicating the existing discovery logic would create two
independent definitions of an ADR graph.  A future change to candidate selection,
logical-number extraction, relationship parsing, ordering, or reciprocal-edge
filtering could then affect one representation but not the other.

ADR-023 already requires graph generation to consume the common managed-ADR
discovery pipeline.  The current graph relationship parser nevertheless contains
an older graph-specific assumption that a relationship target basename begins
with decimal digits.  That assumption is inconsistent with the current discovery
contract, which recognizes configured basenames such as `ADR-0001-title.md` or a
custom convention whose logical number is captured elsewhere in the basename.

ADR-008 and ADR-012 also establish an important external-process boundary:
generating textual graph source does not require Graphviz.  Mermaid should follow
the same rule and remain a serialization format rather than a runtime renderer
dependency.

## Decision Drivers

- Preserve `generate graph` as the semantic report.
- Preserve existing DOT output as the default representation.
- Keep existing callers compatible unless they explicitly select another format.
- Prevent graph semantics from drifting between DOT and Mermaid implementations.
- Reuse the common managed-ADR discovery and logical-number contract.
- Keep relationship interpretation consistent with configured ADR basenames.
- Preserve deterministic node and edge ordering.
- Keep graph source useful in shell pipelines and documentation builds.
- Avoid Graphviz, Mermaid CLI, Node.js, or another renderer as a generation-time
  runtime dependency.
- Reuse existing link-prefix and link-extension semantics for navigable nodes.
- Keep repository-specific Markdown headings, fences, prose, and output placement
  outside `adrctl`.

## Decision

### Keep one semantic graph report

The public report remains:

```text
adrctl generate graph
```

Graph serialization is selected with:

```text
--format FORMAT
```

The initially supported values are:

```text
dot
mermaid
```

When `--format` is omitted, the effective format SHALL be `dot`.

Therefore:

```text
adrctl generate graph
adrctl generate graph --format dot
```

SHALL select the same DOT serializer and SHALL preserve the established DOT
representation.

`mermaid` SHALL be an alternate serialization of the graph report rather than a
new report such as `generate mermaid`.

A future representation SHOULD be evaluated as another graph serializer unless
it introduces genuinely different graph semantics.

### Build one graph model

Graph generation SHALL separate relationship discovery/modeling from textual
serialization.

Conceptually:

```text
managed ADRs
    -> graph model
         -> DOT serializer
         -> Mermaid serializer
```

The graph model SHALL contain enough information for both serializers to express:

- ordered ADR nodes;
- each node's logical ADR number;
- each node's title;
- each node's managed ADR basename;
- sequence edges between consecutive logical ADR numbers; and
- recognized Status-section relationship edges with their relationship labels.

Serializers SHALL consume that model.  They SHALL NOT independently rediscover
ADRs or reinterpret Status-section relationships.

Link prefix and link extension are representation inputs used when serializing
navigable node targets.  They do not change graph semantics.

### Use the shared ADR discovery contract for relationship targets

A relationship line remains conceptually:

```text
RELATIONSHIP [TARGET TITLE](TARGET-BASENAME)
```

When graph construction interprets `TARGET-BASENAME`, it SHALL apply the same
effective `ADRCTL_ADR_GLOB` and `ADRCTL_ADR_NUMBER_REGEX` contract used by ADR
collection and reference resolution.

The graph implementation SHALL NOT assume that the target basename begins with
its decimal logical number.

This means relationships to managed basenames such as:

```text
ADR-0002-two.md
decision-2026-0042-use-postgresql.md
```

are interpreted according to the active discovery configuration rather than a
separate graph-specific filename grammar.

A relationship target rejected by the effective discovery contract is not a
managed graph relationship target and is ignored by graph construction, matching
the bounded-parser approach used elsewhere by adrctl.

The existing reciprocal-presentation rule remains: relationship labels ending in
` by` are omitted from graph relationship edges so reciprocal links do not create
duplicate semantic presentation.

### Preserve sequence-edge semantics

The graph model SHALL retain predecessor-compatible sequence edges between ADRs
whose logical numbers are consecutive.

Sequence semantics depend on captured logical ADR numbers rather than filename
lexical form.

DOT SHALL continue to represent sequence edges as dotted edges with the existing
weight behavior.

Mermaid SHALL represent the same sequence edges as dotted directed links.

### Preserve DOT as the compatibility serializer

DOT remains the default representation.

The DOT serializer SHALL preserve the established node identifiers, title labels,
URLs, sequence-edge presentation, relationship direction, relationship labels,
and deterministic output order.

`--format dot` SHALL not establish a second DOT implementation.  Omitted format
and explicit `dot` use the same serializer.

### Add raw Mermaid serialization

The Mermaid serializer SHALL emit raw Mermaid flowchart source to standard
output.  It SHALL NOT emit Markdown code fences, document headings, explanatory
prose, or repository-specific wrapper content.

The initial diagram SHALL use a top-down flowchart and stable node identifiers
derived from logical ADR numbers.

Node labels SHALL contain ADR titles.  Sequence edges SHALL be dotted directed
links.  Relationship edges SHALL be directed links carrying the same relationship
label represented by DOT.

Mermaid node and edge text SHALL be escaped deterministically so characters that
would otherwise change Mermaid syntax remain data.

### Reuse graph node link semantics

The existing graph options remain:

```text
-p LINK_PREFIX
-e LINK_EXTENSION
```

Both DOT and Mermaid serializers SHALL derive node targets from the same rule:

```text
LINK_PREFIX + ADR basename with .md replaced by LINK_EXTENSION
```

The default extension remains:

```text
.html
```

Mermaid SHALL emit ordinary node link directives for these targets.

Whether a downstream Mermaid renderer activates those links is outside adrctl's
control.  Mermaid documents that interactive links can be disabled by renderer
security policy.  adrctl's contract is to emit deterministic valid link
directives, not to override downstream rendering policy.

### Keep graph generation dependency-free with respect to renderers

Generating DOT SHALL NOT require Graphviz.

Generating Mermaid SHALL NOT require Mermaid CLI, Node.js, a browser, or another
Mermaid renderer.

Both are textual serialization operations implemented by adrctl itself.

Rendering textual graph source into SVG, PNG, HTML, or another visual artifact
remains a downstream concern unless a future ADR explicitly introduces a renderer
integration.

### Preserve composition boundaries

`adrctl` SHALL continue to write focused report output to standard output.

A repository documentation build may compose output such as:

```sh
adrctl generate toc
adrctl generate graph --format mermaid
```

but the caller, Makefile, or documentation layer owns Markdown headings, Mermaid
code fences, explanatory prose, destination filenames, and atomic replacement of
a maintained documentation page.

`adrctl` SHALL NOT grow repository-specific README assembly behavior merely
because Mermaid is commonly embedded in Markdown.

## CLI and Failure Semantics

The supported graph grammar becomes:

```text
adrctl generate graph [-p LINK_PREFIX] [-e LINK_EXTENSION] [--format dot|mermaid]
```

`--format` MAY appear with the existing graph options in any supported option
order.

A missing `--format` value, unsupported format value, or repeated `--format`
option is invalid usage and SHALL return status 2 with a diagnostic on standard
error.

Graph source remains the only standard-output result on success.

## Considered Alternatives

### Add `generate mermaid` as another report

This would be easy to dispatch but would put a semantic report name and a
serialization format at the same command level.  It also encourages an
independent implementation path whose graph semantics could drift from
`generate graph`.

### Add Mermaid by translating generated DOT

The Mermaid serializer could consume DOT text instead of a semantic graph model.
This was rejected because DOT syntax would become an internal intermediate API,
forcing Mermaid behavior to depend on presentation details of another serializer.
It would also require parsing DOT or constraining future DOT evolution for no
semantic benefit.

### Duplicate graph discovery in a Mermaid implementation

This minimizes refactoring but creates two graph definitions.  It was rejected
because candidate selection, configured logical numbering, relationship parsing,
reciprocal filtering, and ordering would then need to remain synchronized by
convention rather than architecture.

### Invoke Mermaid CLI automatically

This could produce rendered files directly, but it adds Node/Mermaid runtime
requirements, output-format policy, filesystem behavior, and renderer-security
questions.  The issue is textual graph serialization, not visual rendering.

### Emit fenced Markdown from `--format mermaid`

This would make direct Markdown embedding convenient but would make the serializer
own document layout.  Raw Mermaid is more composable and can be fenced, redirected,
or processed by the caller as needed.

### Preserve the numeric-prefix-only relationship parser

That behavior predates ADR-023 and makes graph relationships inconsistent with
managed ADR discovery.  It was rejected because a shared graph model should honor
the already-established logical-number contract rather than retain a hidden
format-specific filename grammar.

## Consequences

Graph semantics have one implementation boundary even as representations grow.

Existing `generate graph` callers continue to receive DOT by default.

Mermaid becomes available for documentation systems without adding a renderer
runtime dependency.

Configured and prefixed ADR naming conventions participate consistently in graph
relationships as well as graph nodes.

The graph implementation becomes easier to extend because serialization concerns
can evolve without duplicating discovery logic.

Tests must exercise the same graph fixture through DOT and Mermaid and verify that
node, sequence-edge, and relationship-edge semantics remain aligned.

## Related Decisions

- Related to: ADR-008
- Related to: ADR-011
- Related to: ADR-012
- Related to: ADR-013
- Related to: ADR-014
- Related to: ADR-017
- Related to: ADR-018
- Related to: ADR-023
- Implements: issue #15

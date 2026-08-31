# Graph Serialization

`adrctl generate graph` produces the ADR relationship graph as textual graph
source.  The graph itself is the report; DOT and Mermaid are alternate
serializations of the same discovered nodes and relationships.

## Select a format

DOT remains the compatibility/default representation:

```bash
adrctl generate graph
adrctl generate graph --format dot
```

Both forms select the same DOT serializer.

To emit raw Mermaid flowchart source:

```bash
adrctl generate graph --format mermaid
```

The Mermaid output is deliberately not wrapped in a Markdown code fence.  That
keeps the command useful with ordinary shell redirection and lets the caller own
its surrounding document structure.

For example:

```bash
adrctl generate graph --format mermaid >adr-relationships.mmd
```

A repository documentation build can instead add its own heading and fence:

```bash
{
  printf '%s\n' '## ADR relationships' '```mermaid'
  adrctl generate graph --format mermaid
  printf '%s\n' '```'
} >generated-adr-graph.md
```

`adrctl` does not own the surrounding Markdown page, output pathname, or atomic
replacement policy for such a generated document.

## Graph semantics

Both serializers consume the same graph model.

Managed ADRs are collected through the effective `ADRCTL_ADR_GLOB` and
`ADRCTL_ADR_NUMBER_REGEX` discovery contract.  The model contains:

- one node for each managed ADR;
- dotted sequence edges between consecutive logical ADR numbers; and
- relationship edges derived from recognized links in ADR `## Status` sections.

Relationship targets are interpreted using the same managed-basename discovery
contract.  They do not need to begin directly with a decimal number.  Configured
names such as `ADR-0002-example.md` or a convention whose logical number appears
later in the basename therefore use the same graph semantics as ordinary
`0002-example.md` files.

Reciprocal relationship labels ending in ` by` are omitted from graph
relationship edges so a reciprocal pair does not produce duplicate semantic
presentation.

## Links

The existing graph link options apply to both serializers:

```text
-p LINK_PREFIX
-e LINK_EXTENSION
```

The default extension is `.html`.

For a managed ADR named:

```text
0007-use-postgresql.md
```

this command:

```bash
adrctl generate graph --format mermaid -p '/adrs/' -e '.md'
```

emits a Mermaid node link targeting:

```text
/adrs/0007-use-postgresql.md
```

DOT uses the same derived target for its node URL.

Mermaid renderers may disable interactive node links according to their own
security policy.  `adrctl` guarantees deterministic link directives in the text
it emits; it cannot require a downstream renderer to activate them.

## Rendering dependencies

`adrctl` only emits graph source.

DOT generation does not require Graphviz.  Mermaid generation does not require
Mermaid CLI, Node.js, a browser, or another Mermaid renderer.  Converting either
textual representation into SVG, PNG, HTML, or another visual artifact is a
downstream operation.

## Composition

The report remains suitable for UNIX-style composition.  For example, a
repository-specific documentation task may combine the table of contents and
Mermaid graph while retaining ownership of headings and Markdown fences:

```bash
adrctl generate toc
adrctl generate graph --format mermaid
```

That separation is intentional: `adrctl` supplies focused report fragments, and
the repository's Makefile or documentation layer decides how those fragments are
assembled into maintained documentation.

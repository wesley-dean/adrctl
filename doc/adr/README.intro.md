# adrctl Architecture and Reference Documentation

adrctl is a Bash-based Architecture Decision Record tool designed as a compatible,
safer successor to `adr-tools` while keeping project discovery, configuration,
mutation, reporting, and release behavior explicit and reviewable.

The repository separates documentation by responsibility:

- [`doc/adrctl-spec.md`](../adrctl-spec.md) defines the normative public behavior
  expected from adrctl.
- [`doc/decisions.md`](../decisions.md) provides concise summaries of architectural
  decisions and their current status.
- ADRs preserve the context, rationale, alternatives, constraints, and consequences
  behind durable decisions.
- [`doc/graph-serialization.md`](../graph-serialization.md) documents the textual
  DOT and Mermaid relationship-report formats.
- [`doc/mktext-delimiter-integration.md`](../mktext-delimiter-integration.md)
  records the renderer integration and compatibility boundary.
- [`doc/upstream-adr-tools-compatibility.md`](../upstream-adr-tools-compatibility.md)
  records the predecessor compatibility and provenance baseline.
- Generated Doxygen pages document implementation-level contracts from maintained
  source comments.

The ADRs remain authoritative for architectural rationale.  The behavioral
specification remains authoritative for the current public contract.

## Architecture Decision Records

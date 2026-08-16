# ADR-011: Resolve ADR References Unambiguously and Mutate Bounded Markdown

Date: 2026-08-15

## Status

Proposed

## Context

Several inherited commands accept an ADR reference rather than a complete path.
The predecessor resolves a reference by listing ADR files, filtering with `grep`,
and taking the first match.  It also recognizes titles and status sections with
small line-oriented shell and `awk` operations rather than with a complete
Markdown parser.

The small-parser approach is appropriate for ADR documents whose relevant
structure is deliberately conventional.  Selecting the first ambiguous filename,
however, can silently link or edit the wrong ADR.  That failure mode conflicts
with ADR-007's conservative preflight policy.

The rewrite therefore needs a precise boundary: understand the small amount of
Markdown structure required by ADR operations, preserve ordinary document text,
and refuse ambiguous references rather than guessing.

## Decision

An ADR document managed by compatibility-oriented commands SHALL be identified by
a Markdown filename within the configured ADR directory whose basename begins
with one or more decimal digits followed by `-` and ends with `.md`.

A user-supplied ADR reference MAY be:

- an exact ADR number;
- an exact ADR filename or basename; or
- a partial filename fragment supported for predecessor compatibility.

Reference resolution SHALL gather all candidate ADR files before choosing a
result.

An exact filename match SHALL win over partial matching.

A decimal-number reference SHALL match the numeric prefix as a complete logical
number rather than as an arbitrary substring.  Leading zeroes in the reference
SHALL NOT change the logical number.

A partial reference that matches exactly one candidate MAY resolve to that
candidate.

A reference that matches no candidates SHALL fail before mutation.

A reference that matches more than one candidate SHALL fail as ambiguous and
SHALL identify enough candidate information for the user to choose a unique
reference.  `adrctl` SHALL NOT preserve the predecessor's incidental "first grep
match wins" behavior.

This is an intentional safety deviation from `adr-tools` 3.0.0 and SHALL be
covered by migration/compatibility documentation and regression tests.

For compatibility-oriented Markdown operations, `adrctl` SHALL recognize these
structural conventions:

- the ADR title is the first level-one Markdown heading, conventionally the first
  line and beginning with `# `;
- the status section heading is the exact level-two heading `## Status`;
- the status section continues until the next Markdown heading of level two or
  higher that terminates that section under the documented parser rules;
- relationship lines inserted by `adrctl` use ordinary Markdown links whose
  target is the target ADR basename, preserving relative links within one ADR
  directory.

`adrctl` SHALL NOT attempt to become a general CommonMark parser.  It SHALL use a
small, documented, line-oriented structural parser for the headings and link
positions it owns.

Commands that add reciprocal ADR relationships SHALL preflight both documents,
confirm the required structural locations exist, and prepare both complete
outputs before either document is replaced.

Supersede behavior SHALL preserve the predecessor's successful intent:

- the new ADR gains a relationship to the superseded ADR;
- the superseded ADR gains a reciprocal relationship to the new ADR; and
- the predecessor status text being superseded is removed or updated according
  to the normative command contract.

The exact historical spelling `Supercedes`/`Superceded` appears in predecessor
behavior and documentation.  The compatibility corpus SHALL determine where that
spelling is observable and therefore retained.  New user-facing prose SHOULD use
standard spelling where doing so does not alter compatibility output.

All parser and mutation rules SHALL preserve unrelated lines byte-for-byte where
practical.  A command SHALL NOT reformat an entire Markdown document merely to
insert or remove the bounded structure it owns.

## Considered Alternatives

### Preserve first-match reference resolution

This is closest to the predecessor implementation but can silently mutate the
wrong ADR when a partial reference is ambiguous.  Conservative failure is safer
and easier to explain.

### Require only complete filenames

That would remove ambiguity but would break useful predecessor workflows that
refer to ADRs by number or partial filename.

### Adopt a complete Markdown parser

A complete parser would add substantial dependency and complexity for a tiny
structural surface.  ADR operations need headings, status sections, and links,
not arbitrary Markdown transformation.

### Rewrite documents into a canonical format on every mutation

That would create noisy diffs and could destroy author formatting.  Mutations
should be narrow and preserve content outside the owned region.

## Consequences

Existing numeric and unique partial references remain convenient.

Ambiguous references become a deliberate compatibility deviation that fails
safely rather than selecting an arbitrary document.

The Markdown implementation remains small and auditable while its accepted
structure becomes part of the normative specification.

## Related Decisions

- Related to: ADR-007
- Related to: ADR-010
- Adapted from Bootstrap ADR-013, ADR-014, ADR-015, ADR-028, and ADR-040.
- Compatibility evidence: `adr-tools` `_adr_file`, `_adr_title`, `_adr_status`,
  `_adr_add_link`, and `_adr_remove_status`.
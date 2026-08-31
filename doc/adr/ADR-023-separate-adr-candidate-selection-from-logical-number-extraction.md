# ADR-023: Separate ADR Candidate Selection from Logical Number Extraction

Date: 2026-08-19

## Status

Accepted

## Intent and Documentation Posture

This ADR defines how adrctl selects candidate files, recognizes managed ADRs,
extracts logical ADR numbers, and validates newly rendered ADR filenames against
the effective discovery contract.

It extends ADR-009's project-configuration namespace, refines ADR-010's
configurable filename-pattern decision with a rediscoverability invariant, and
supersedes the current specification assumption that every managed ADR basename
must begin directly with its decimal number.

Historical ADRs remain unchanged.  This ADR records the later decision that makes
configurable filename creation and subsequent ADR discovery consistent.

## Context

ADR-010 deliberately permits projects to replace the compatibility filename
pattern:

```text
{NUMBER4}-{TITLE_SLUG}.md
```

with another basename pattern, including patterns such as:

```text
ADR-{NUMBER4}-{TITLE_SLUG}.md
```

The current implementation can render and create such a file.  Discovery,
however, still recognizes only basenames whose decimal number begins at byte
zero.  The effective result is a broken lifecycle: adrctl can create an ADR that
`list`, numeric reference resolution, next-number allocation, `generate toc`, and
`generate graph` subsequently ignore.

Hard-coding another accepted prefix would address one example without fixing the
underlying contract.  Filename patterns are intentionally configurable, and
existing repositories may contain more than one historical naming convention.
Discovery therefore needs a configurable boundary of its own.

At the same time, filename creation, candidate selection, and logical-number
extraction solve different problems:

- filename creation answers how a newly created ADR should be named;
- candidate selection answers which immediate files in the configured ADR
  directory should be considered for management; and
- logical-number extraction answers whether a candidate is a managed ADR and what
  decimal number adrctl should assign to it logically.

Treating those concerns separately allows adrctl to recognize a broad range of
common repositories without making every Markdown file an ADR and without
requiring one transient creation pattern to persist forever.

## Decision Drivers

- An ADR filename accepted for creation should remain manageable by subsequent
  commands.
- Projects should be able to narrow discovery when the ADR directory contains
  unrelated Markdown files.
- Common prefixed ADR forms such as `ADR-0001-title.md` should work without extra
  configuration.
- Projects with less common conventions should be able to define how the logical
  number is captured.
- Numeric ordering, reference resolution, and next-number allocation should share
  one logical-number contract.
- Project configuration must remain inert data and must never become executable
  shell code.
- A one-time `--filename-pattern` override must not become hidden persistent
  discovery state.
- Existing compatibility behavior for `0001-title.md` should remain valid by
  default.

## Decision

### Separate creation, candidate selection, and number extraction

adrctl SHALL treat these as three distinct configuration concepts:

```text
ADRCTL_FILENAME_PATTERN
ADRCTL_ADR_GLOB
ADRCTL_ADR_NUMBER_REGEX
```

`ADRCTL_FILENAME_PATTERN` controls rendering of newly created ADR basenames.

`ADRCTL_ADR_GLOB` controls which immediate basenames in the configured ADR
directory are candidates for ADR recognition.

`ADRCTL_ADR_NUMBER_REGEX` determines whether a candidate basename is a managed ADR
and captures its logical decimal number.

The default values SHALL be:

```text
ADRCTL_FILENAME_PATTERN={NUMBER4}-{TITLE_SLUG}.md
ADRCTL_ADR_GLOB=*.md
ADRCTL_ADR_NUMBER_REGEX=^[^0-9]*([0-9]+)-.+\.md$
```

The defaults preserve the existing compatibility filename while recognizing
common prefixed forms such as:

```text
0001-example.md
ADR-0001-example.md
decision-0001-example.md
```

### Define ADRCTL_ADR_GLOB as candidate-selection data

`ADRCTL_ADR_GLOB` SHALL use Bash shell-pattern semantics suitable for matching one
basename.

The value SHALL:

- default to `*.md`;
- apply only to immediate files beneath the effective ADR directory;
- select candidates rather than proving ADR validity;
- be available through process environment and project `.env`;
- be treated as data rather than shell syntax to execute; and
- never be applied through `eval`, `source`, command construction, or an
  equivalent execution mechanism.

A project MAY narrow candidate selection, for example:

```text
ADRCTL_ADR_GLOB=ADR-*.md
```

Matching the glob means only that the basename is eligible for number-regex
validation.  A matching file whose basename does not satisfy the effective number
regex is not a managed ADR.

An empty glob SHALL be invalid configuration.  A configured value containing `/`
SHALL be invalid because candidate selection is intentionally basename-scoped and
must not introduce nested path traversal or directory-recursion semantics.

### Define ADRCTL_ADR_NUMBER_REGEX as the logical-number contract

`ADRCTL_ADR_NUMBER_REGEX` SHALL use Bash extended regular-expression semantics
compatible with the project's Bash 4.3 minimum.

Capture group 1 SHALL contain the complete logical decimal ADR number.

For example:

```text
ADRCTL_ADR_NUMBER_REGEX=^ADR_([0-9]+)_.+\.md$
```

recognizes:

```text
ADR_0042_use-postgresql.md
```

as logical ADR 42.

A project using a dated convention such as:

```text
decision-2026-0042-use-postgresql.md
```

may configure:

```text
ADRCTL_ADR_NUMBER_REGEX=^decision-[0-9]{4}-([0-9]+)-.+\.md$
```

so the logical number remains 42 rather than 2026.

The regex SHALL be treated strictly as inert data.  It SHALL NOT be passed through
`eval`, `source`, command construction, or another shell-execution boundary.

An empty number regex SHALL be invalid configuration.

A syntactically invalid Bash ERE SHALL fail configuration validation with the
public invalid-usage/configuration status before an ADR mutation begins.

When a candidate basename matches the configured regex, capture group 1 SHALL be
present and SHALL contain one or more decimal digits only.  A candidate match that
does not provide a decimal group 1 SHALL be treated as a configuration-contract
failure rather than assigning an inferred or partial number.

The captured decimal string SHALL be normalized as a logical decimal number for
ordering and reference comparison.  Leading zeroes SHALL remain presentation
only and SHALL NOT change the logical value.

### Use one discovery pipeline

All commands that operate on managed ADR collections SHALL use one conceptual
pipeline:

```text
ADR directory
  -> ADRCTL_ADR_GLOB candidate selection
  -> ADRCTL_ADR_NUMBER_REGEX validation + capture group 1
  -> logical ADR records
       -> numeric ordering
       -> reference resolution
       -> next-number allocation
       -> list
       -> generate toc
       -> generate graph
```

Commands SHALL NOT introduce independent filename-recognition rules for these
operations.

A candidate selected by the glob but rejected by the number regex SHALL be
ignored as an unrelated file.

### Preserve ordering and reference semantics

Managed ADRs SHALL remain ordered by logical numeric value, with basename ordering
as the stable tie-breaker when two basenames resolve to the same logical number.

Numeric references SHALL compare against the complete captured logical number and
SHALL ignore presentation zero padding.

Exact basename matches SHALL retain their existing precedence over partial
matching.

Unique partial-basename references SHALL continue to operate only over the common
managed ADR candidate set.

A new ADR number SHALL remain one greater than the greatest recognized logical
number.  When no managed ADR is recognized, the first candidate number remains 1.

### Require creation to satisfy the effective discovery contract

adrctl SHALL NOT create an ADR filename that its effective discovery
configuration cannot subsequently recognize as the same logical ADR number.

After rendering a basename for `new` or `init`, but before visible filesystem
mutation, adrctl SHALL verify that:

1. the rendered basename matches the effective `ADRCTL_ADR_GLOB`;
2. the basename matches the effective `ADRCTL_ADR_NUMBER_REGEX`;
3. capture group 1 contains decimal digits; and
4. the captured logical value equals the number assigned to the ADR being
   created.

A failure of any of these checks SHALL fail before publishing the new ADR.

This invariant applies equally to the default filename pattern, a project
configuration pattern, a process-environment pattern, and a transient
`--filename-pattern` override.

The invariant is intentionally stronger than merely checking that the rendered
basename is safe.  A syntactically safe filename that would disappear from the
next `list` operation is not acceptable product behavior.

### Keep discovery configuration independent from transient creation overrides

adrctl SHALL NOT derive later discovery behavior solely from the most recently
used `ADRCTL_FILENAME_PATTERN` or `--filename-pattern` value.

A one-time command such as:

```text
adrctl new --filename-pattern 'ADR-{NUMBER4}-{TITLE_SLUG}.md' 'Example'
```

does not create persistent configuration.  Subsequent commands therefore rely on
the effective glob and number-regex settings, whose defaults intentionally
recognize the resulting common prefixed form.

This also permits a repository to contain ADRs created under multiple compatible
historical filename patterns while retaining one stable number-extraction
contract.

### Extend project configuration without adding new CLI options initially

ADR-009's precedence model remains authoritative.

`ADRCTL_ADR_GLOB` and `ADRCTL_ADR_NUMBER_REGEX` SHALL initially be available as:

1. process-environment values;
2. project `.env` values; and
3. built-in defaults.

No command-line options are introduced initially for these two settings.

`ADRCTL_FILENAME_PATTERN` retains its existing command-line, process-environment,
project-file, and default precedence.

Unknown `ADRCTL_` project keys continue to fail configuration validation.  Adding
these two names to the recognized namespace therefore makes their support
explicit rather than relying on permissive unknown-key handling.

## Security and Safety

The two new settings SHALL remain inert configuration data.

Applying the candidate glob or number regex SHALL NOT:

- evaluate command substitutions;
- perform shell variable expansion from the configured value;
- invoke `eval`;
- source project configuration;
- construct and execute shell commands from configured text; or
- permit candidate selection to escape the configured ADR directory.

Creation compatibility checks are part of preflight under ADR-007.  A mismatch
between the creation pattern and discovery configuration SHALL be detected before
the ADR is published.

## Considered Alternatives

### Hard-code an optional ADR- prefix

This would fix the immediate example but would merely replace one hard-coded
filename assumption with two.  It would not support other repository conventions
or mixed historical naming.

### Derive discovery directly from ADRCTL_FILENAME_PATTERN

This looks attractive because creation already uses the filename pattern.
However, `--filename-pattern` is allowed as a transient command option and is not
persisted for later commands.  Repositories may also contain historical ADRs from
more than one naming convention.  Discovery therefore needs a stable independent
contract.

### Use only a configurable glob

A glob is useful for candidate selection but does not identify which decimal run
is the logical ADR number.  It cannot safely preserve numeric ordering,
next-number allocation, or numeric reference semantics for arbitrary naming
conventions.

### Use only a configurable number regex

A regex alone could recognize ADRs, but a separate candidate glob gives projects a
clear ownership boundary when an ADR directory also contains unrelated Markdown
files.  The two-stage model keeps broad compatibility defaults while allowing
cheap narrowing before structural recognition.

### Parse the logical number from ADR document contents

ADR bodies commonly contain numbered headings, but content parsing would make
filename discovery depend on reading and interpreting every candidate document.
It would also create ambiguity when filename and body numbers disagree.  adrctl's
logical filename identity should remain explicit and independently configurable.

### Infer the first decimal run anywhere in every Markdown basename

That would recognize many common names, but it would also silently misclassify
files such as dated notes.  The bounded default regex recognizes common prefixed
forms while requiring a familiar ADR-like `NUMBER-text.md` structure.  Projects
with other conventions can configure the extraction rule explicitly.

## Consequences

adrctl can support common prefixed ADR naming without special-case prefixes.

Repositories that mix unrelated Markdown files into the ADR directory can narrow
candidate ownership with `ADRCTL_ADR_GLOB`.

Repositories with custom numbering conventions can define exactly which capture
group is the logical ADR number while preserving the common ordering and
reference machinery.

The creation path gains a stronger preflight guarantee: adrctl will not knowingly
publish an ADR that its own effective discovery configuration immediately loses.

Configuration becomes slightly richer, but each setting has one purpose and an
explicit safety boundary.

The implementation will need shared helpers for effective discovery settings,
pattern/regex validation, candidate matching, and number extraction so commands do
not drift into separate interpretations.

## Implementation and Test Expectations

Implementation should add regression coverage for at least:

- existing default `0001-title.md` recognition;
- default recognition of `ADR-0001-title.md`;
- lifecycle behavior after creation with
  `ADR-{NUMBER4}-{TITLE_SLUG}.md`;
- next-number allocation across prefixed ADRs;
- numeric references to prefixed ADRs;
- reciprocal links between prefixed ADRs;
- TOC and graph generation from prefixed ADR collections;
- narrowed `ADRCTL_ADR_GLOB=ADR-*.md` candidate selection;
- process-environment and project-file precedence for both new settings;
- unrelated Markdown candidates ignored by the number regex;
- duplicate logical numbers with basename tie-breaking;
- invalid ERE rejection;
- missing or nondecimal capture group 1 handling;
- inert handling of malicious-looking glob/regex values;
- preflight rejection when a rendered filename does not match the effective glob;
- preflight rejection when a rendered filename captures the wrong logical number;
  and
- equivalent behavior across `adrctl.dev.bash`, `adrctl.bash`, and
  `adrctl.min.bash` through the existing generated-artifact test matrix.

## Related Decisions

- Extends: ADR-009
- Refines: ADR-010
- Related to: ADR-005
- Related to: ADR-007
- Related to: ADR-011

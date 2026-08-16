# adrctl Behavioral Specification

## Purpose

This document is the normative behavioral specification for `adrctl`.

Architecture Decision Records under `doc/adr/` explain why the project selected
these behaviors.  This specification describes the current public contract that
implementation and tests are expected to satisfy.

Normative terms such as SHALL, SHALL NOT, SHOULD, and MAY are used deliberately.

The accepted ADR corpus is the architectural authority for this specification.
If source behavior conflicts with an ADR or this specification, the conflict SHALL
be resolved explicitly rather than allowing implementation to become undocumented
architecture.

## Product Identity and Compatibility Baseline

The canonical project, product, and installed command identity is:

```text
adrctl
```

The canonical generated distribution artifact is:

```text
adrctl.bash
```

under `dist/` in the source tree.

The generated executable SHALL also support invocation through a symbolic link
named:

```text
adr
```

The `adr` name is a compatibility invocation alias, not a separate product mode.
Inherited commands SHALL use the same implementation, configuration, and
filesystem behavior through either name.

A shell alias that expands `adr` directly to the generated `adrctl.bash` path is
also a supported invocation mechanism.  Because Bash removes the alias during
command expansion and does not pass the alias token as `$0`, a plain shell alias
cannot be distinguished from direct `adrctl.bash` execution by the script.

Help and diagnostic presentation SHALL therefore follow these rules:

- direct `adrctl.bash` execution presents canonical `adrctl`;
- an installed or linked basename `adrctl` presents `adrctl`;
- a detectable filesystem symlink basename `adr` presents `adr`; and
- a plain shell alias named `adr` that expands to the `adrctl.bash` path presents
  canonical `adrctl` because the alias name is unavailable to the script.

Version and provenance output SHALL always identify the installed product as
`adrctl`.

The canonical predecessor comparator for the initial compatibility milestone is:

```text
Repository: npryce/adr-tools
Release:    3.0.0
Commit:     b47d3837d452ca6d2509d2524c7a08c701e84367
```

Compatibility behavior is classified as:

```text
Compatible
Intentional deviation
New adrctl behavior
```

Intentional deviations SHALL be documented and regression-tested.

## Runtime and Generated Artifact

`adrctl` requires Bash 4.3 or newer.

The canonical generated consumer artifact is:

```text
dist/adrctl.bash
```

It SHALL:

- begin with `#!/usr/bin/env bash`;
- be executable with mode `0755`;
- contain the complete required runtime implementation in one file;
- embed the verified `mktext` v0.0.6 release artifact unchanged;
- contain exactly one effective `adrctl` product entrypoint;
- remain executable directly, through an installed `adrctl` name, through an
  `adr` filesystem symlink, and through a shell alias that expands to its path;
  and
- require no runtime network access for normal operation.

The generated artifact SHALL embed:

```text
VERSION
BUILD_DATE
BUILD_COMMIT
```

`BUILD_DATE` SHALL represent the source revision timestamp rather than wall-clock
assembly time.  Version reporting SHALL NOT query Git, the clock, or the network
at runtime.

The embedded `mktext` dependency is an implementation detail.  Its private
numeric return-status vocabulary is not part of the `adrctl` CLI contract.

## Public Command Surface

The command grammar is conceptually:

```text
adrctl [GLOBAL-OPTION...] COMMAND [COMMAND-OPTION...] [ARGUMENT...]
```

The same grammar SHALL work when the executable is reached through the supported
`adr` compatibility symlink or a shell alias that expands `adr` to the artifact
path.

The initial built-in commands are:

```text
help
init
new
link
list
generate
upgrade-repository
```

The initial built-in reports are:

```text
toc
graph
```

No external `adr-*` or `adrctl-*` command/plugin discovery is supported.

### Global forms

The following informational forms SHALL be available without requiring project
state:

```text
adrctl help
adrctl -h
adrctl --help
adrctl --version
```

Commands that use project state SHALL support:

```text
--project-root PATH
```

as an explicit global project-root override.

Unknown commands or options SHALL fail with status 2 and SHALL NOT trigger
external executable discovery.

## Project Discovery

For commands operating on an existing project, `PROJECT_ROOT` SHALL be selected
in this order:

1. `--project-root PATH`;
2. process-environment `ADRCTL_PROJECT_ROOT`;
3. nearest recognized ancestor marker while walking upward from cwd;
4. Git work-tree root, when Git can determine one; and
5. cwd.

Recognized ancestor markers are:

- a `.adr-dir` file;
- an existing `doc/adr` directory; or
- a `.env` file containing at least one syntactically valid assignment whose key
  begins with `ADRCTL_`.

A `.env` containing no `ADRCTL_` assignment SHALL NOT establish `adrctl` project
context.

The discovery test deliberately does not decide whether a namespaced key is
supported.  A misspelled or source-inappropriate `ADRCTL_` assignment establishes
the nearest context and then fails configuration validation.  It SHALL NOT be
silently skipped in favor of a more distant ancestor.

When multiple ancestor markers exist, the nearest marked ancestor SHALL win
regardless of marker type.

### init discovery exception

`init` creates project context.  Unless `--project-root` or process-environment
`ADRCTL_PROJECT_ROOT` is supplied, `init` SHALL use cwd as `PROJECT_ROOT` and
SHALL NOT climb to a Git root before initialization.

## Project Configuration

After `PROJECT_ROOT` is selected, `adrctl` SHALL read `${PROJECT_ROOT}/.env` when
it exists.

The file SHALL be parsed as inert data.  It SHALL NOT be sourced, evaluated, or
shell-expanded.

### .env grammar

The parser SHALL accept:

- blank lines;
- full-line comments whose first nonblank character is `#`;
- optional `export` before an assignment;
- `KEY=VALUE` assignments;
- surrounding whitespace around keys and values; and
- one matching outer layer of single or double quotes around a value.

The parser SHALL NOT perform:

- parameter expansion;
- command substitution;
- backtick evaluation;
- shell escape interpretation;
- nested quote parsing; or
- shell execution.

Keys SHALL match:

```text
[A-Za-z_][A-Za-z0-9_]*
```

Non-`ADRCTL_` keys are ignored by `adrctl`.

An unknown `ADRCTL_` project key SHALL fail with status 2.

`ADRCTL_PROJECT_ROOT` is valid only as process-environment/CLI input.  If it is
present in project `.env`, configuration validation SHALL fail with status 2.

### Initial project keys

Project `.env` supports:

```text
ADRCTL_ADR_DIR
ADRCTL_TEMPLATE
ADRCTL_FILENAME_PATTERN
ADRCTL_TEMPLATE_START_DELIMITER
ADRCTL_TEMPLATE_END_DELIMITER
```

The process environment additionally supports:

```text
ADRCTL_PROJECT_ROOT
```

Legacy process-environment compatibility inputs include:

```text
ADR_TEMPLATE
ADR_DATE
VISUAL
EDITOR
ADR_PAGER
PAGER
```

For project-scoped settings, effective precedence is:

```text
command-line option
process environment
project .env
compatible legacy project metadata
built-in default
```

Higher-precedence values replace lower-precedence values for the same setting.

## Path and ADR Directory Semantics

A configured path beginning with `/` is absolute.  Other configured project paths
resolve against `PROJECT_ROOT` unless a command explicitly defines another base.

The ADR directory is selected in this order:

1. an explicit command-specific ADR-directory option, if a future command defines
   one;
2. process-environment `ADRCTL_ADR_DIR`;
3. project `.env` `ADRCTL_ADR_DIR`;
4. `.adr-dir` content at `PROJECT_ROOT`; and
5. `doc/adr` relative to `PROJECT_ROOT`.

`.adr-dir` is parsed as data.  It is never sourced.

An explicit absolute ADR directory MAY live outside `PROJECT_ROOT`.  Once
resolved, that directory remains the boundary for ADR filenames and references.

## Rendering Responsibility

`adrctl` owns ADR-specific value acquisition and transformation.  `mktext` owns
literal textual substitution.

The render context SHALL include, as applicable:

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

`NUMBER` is the logical decimal ADR number without forced padding.

`NUMBER4` is the same logical number with a minimum width of four digits and
leading zeroes.  Values larger than four digits are not truncated.

`TITLE` is formed by joining title arguments with single spaces.

`TITLE_SLUG` is a lowercase, hyphen-separated filename slug.  Runs of
non-alphanumeric title characters become one separator; leading/trailing
separators are removed.

`DATE` defaults to the local calendar date in `YYYY-MM-DD` form.
Process-environment `ADR_DATE` remains a compatibility override for created ADRs.

The ordinary compatibility-oriented `new` status defaults to:

```text
Accepted
```

## Body Template Selection

The ADR body template is selected in this order:

1. explicit `--template PATH`;
2. process-environment `ADRCTL_TEMPLATE`;
3. legacy process-environment `ADR_TEMPLATE`;
4. project `.env` `ADRCTL_TEMPLATE`;
5. `${ADR_DIR}/templates/template.md`, when readable; and
6. the built-in default template.

Configured relative template paths resolve against `PROJECT_ROOT`.

The built-in default body template SHALL preserve the established structural
contract:

- level-one numbered/title heading;
- `Date:` line;
- `## Status`;
- `## Context`;
- `## Decision`; and
- `## Consequences`.

Placeholder/explanatory prose is independently authored for `adrctl`; exact
predecessor prose is not a compatibility requirement.

## Body Template Delimiters

Delimiter configuration in this section applies to ADR body templates only.
Filename patterns are a separate rendering surface and always use the stable
braced `{KEY}` grammar described later.

Explicit body-template delimiters are supplied as a pair:

```text
--start-delimiter STRING
--end-delimiter STRING
```

The effective pair is selected in this order:

1. command-line pair;
2. process-environment
   `ADRCTL_TEMPLATE_START_DELIMITER` / `ADRCTL_TEMPLATE_END_DELIMITER`;
3. project `.env` pair; and
4. automatic body-template detection.

At one explicit layer, both options SHALL be supplied together.  One-sided
configuration is invalid.  Two empty strings are valid and select `mktext`
bare-key mode.

When no explicit pair exists, `adrctl` SHALL inspect the unrendered body template
for a token with this conceptual grammar:

```text
{ OPTIONAL-BLANKS KEY OPTIONAL-BLANKS }
KEY := [A-Za-z][A-Za-z0-9_-]*
```

The candidate key, after the same uppercase normalization used by delimited
`mktext` rendering, SHALL also exist in the prepared render context.

If at least one recognized braced context token exists, the body delimiters are
`{` and `}`.  Otherwise both delimiters are empty, selecting compatibility
bare-token rendering.

An unrelated expression such as `{foo}` does not select braced mode when `FOO`
is absent from the context.

Automatic detection selects exactly one delimiter pair for one body render.
`adrctl` SHALL NOT perform implicit mixed or two-pass body rendering.

Replacement values are inserted literally and nonrecursively according to the
pinned `mktext` contract.

## Filename Pattern

Filename-pattern rendering is independent from body-template delimiter settings.
Filename patterns SHALL always use `mktext`'s stable braced `{KEY}` grammar.

The default pattern is:

```text
{NUMBER4}-{TITLE_SLUG}.md
```

Pattern precedence is:

1. explicit `--filename-pattern PATTERN`;
2. process-environment `ADRCTL_FILENAME_PATTERN`;
3. project `.env` `ADRCTL_FILENAME_PATTERN`; and
4. built-in default.

The rendered filename SHALL be one basename inside `ADR_DIR`.  It SHALL NOT be
absolute or contain `/`, and SHALL NOT escape the ADR directory through path
traversal.

An empty or unsafe rendered basename SHALL fail before mutation.

## ADR File Recognition, Ordering, and Numbering

A managed ADR filename has the conceptual form:

```text
DIGITS-TEXT.md
```

where the leading digits form the logical ADR number.

Unrelated Markdown/filesystem entries that do not match the numbered ADR shape
are ignored by listing and number allocation.

ADR ordering is numeric by logical number, with basename ordering as a stable
tie-breaker for duplicate numeric prefixes.

A new ADR chooses one greater than the greatest recognized logical number.  When
no recognized ADR exists, the first candidate number is 1.

The final destination SHALL never overwrite a file created by another process
after preflight.  A collision fails with status 1 or MAY be retried a bounded
number of times.  The initial product does not guarantee serialized multi-writer
number allocation.

## ADR Reference Resolution

Commands accepting an ADR reference SHALL support:

- exact logical number;
- exact filename/basename; and
- unique partial filename fragment.

An exact filename match wins over partial matching.

A numeric reference matches the complete logical numeric prefix and ignores
leading zeroes in the user reference.

Zero matches SHALL fail with status 1.

More than one match SHALL fail with status 1 as ambiguous and SHALL identify the
candidate basenames on standard error.

The predecessor's incidental first-match behavior is an intentional safety
deviation and is not supported.

## Markdown Structural Contract

`adrctl` uses a bounded line-oriented Markdown model rather than a complete
Markdown parser.

For compatibility-oriented documents:

- the title is the first level-one heading beginning with `# `;
- the status section begins at exact heading `## Status`;
- the status section ends when the next level-two section begins; and
- relationship lines are ordinary Markdown links inserted within the Status
  section.

A relationship line has the conceptual form:

```text
RELATIONSHIP [TARGET TITLE](TARGET-BASENAME)
```

Mutations SHALL preserve unrelated document text and formatting where practical.
The implementation SHALL NOT normalize an entire Markdown document merely to
modify owned relationship/status structure.

If required structure is absent, a mutating command SHALL fail rather than guess
an insertion point.

## Multi-File Mutation Safety

Commands that intend to create or modify more than one file SHALL complete all
reasonable validation before the first visible mutation.

Preflight includes, as applicable:

- project/configuration validation;
- ADR reference resolution;
- destination validation;
- template readability;
- body/filename renderability;
- required Markdown structure;
- file readability/writability;
- relationship argument validation; and
- collision checks.

Complete replacement contents SHALL be prepared before existing files are
replaced.

Existing files SHOULD use same-directory temporary files and atomic rename where
practical.

The project does not promise true cross-file transactional atomicity.  A rare
filesystem failure after one atomic replacement may still leave a partially
applied operation.  The implementation SHALL minimize that window and SHALL NOT
preserve avoidable predecessor partial-write behavior as a compatibility feature.

## Command: init

Invocation:

```text
adrctl init [DIRECTORY]
```

Without an explicit project-root override, `init` uses cwd.

When `DIRECTORY` is supplied:

- a relative value resolves against `PROJECT_ROOT`;
- the directory is created when necessary; and
- `.adr-dir` is written at `PROJECT_ROOT` using the supplied project-relative
  value when the value is relative.

When `DIRECTORY` is omitted, the ADR directory defaults to `doc/adr` and `init`
does not need to create `.adr-dir` merely to express the default.

`init` creates the first ADR without opening an editor.

In an empty ADR directory, the default first pathname is compatible with:

```text
0001-record-architecture-decisions.md
```

An already-populated ADR directory SHALL NOT be silently reinitialized.

On success, the created ADR pathname is written to standard output.

## Command: new

Invocation:

```text
adrctl new [-s REFERENCE]... [-l TARGET:LINK:REVERSE-LINK]... [OPTIONS] TITLE...
```

`TITLE...` arguments are joined with single spaces.  A missing/empty title is
invalid usage.

Inherited options are:

```text
-s REFERENCE
-l TARGET:LINK:REVERSE-LINK
```

Both MAY be repeated.

Each `-l` value SHALL contain exactly three non-empty colon-delimited logical
fields: target reference, forward relationship text, and reverse relationship
text.  A fourth field or additional colon is rejected as malformed input.

This is an intentional deviation from `adr-tools` 3.0.0, whose `cut -f 1/2/3`
implementation silently discarded fourth-and-later fields.  `adrctl` does not
preserve silent truncation of malformed relationship specifications.

Modern rendering options include:

```text
--template PATH
--filename-pattern PATTERN
--start-delimiter STRING
--end-delimiter STRING
```

A successful command SHALL:

1. resolve project/configuration/template inputs;
2. resolve all `-s`/`-l` targets uniquely;
3. allocate the candidate number;
4. prepare context, filename, and body;
5. prepare all reciprocal status/relationship changes;
6. preflight the complete change set;
7. publish the new file without overwriting a competing destination;
8. replace prepared existing files using the mutation-safety contract;
9. invoke the selected editor; and
10. write the created ADR pathname to standard output.

For each `-s TARGET`, compatibility relationship text is:

```text
new ADR -> Supercedes -> TARGET
TARGET  -> Superceded by -> new ADR
```

The historical misspelling is retained where it is observable compatibility
output.  The plain `Accepted` status line in the superseded target is removed when
that line is the status being replaced.

For each `-l TARGET:LINK:REVERSE-LINK`, the new ADR receives `LINK` to TARGET and
TARGET receives `REVERSE-LINK` to the new ADR.

Repeated relationships to the same target SHALL be aggregated before replacing
that target so one prepared mutation does not discard another.

Editor selection is:

```text
VISUAL
EDITOR
no-op
```

If the editor fails after files were successfully written, `new` SHALL return an
operational failure and diagnose the editor failure.  It SHALL NOT delete the
created ADR to simulate a transaction across an interactive external process.

## Command: link

Invocation:

```text
adrctl link SOURCE LINK TARGET REVERSE-LINK
```

SOURCE and TARGET are ADR references.

Both references and both Status sections SHALL be validated before either file is
replaced.

Successful behavior adds:

```text
SOURCE -> LINK         -> TARGET
TARGET -> REVERSE-LINK -> SOURCE
```

If SOURCE and TARGET resolve to the same ADR, both relationship lines are prepared
in one replacement.

## Command: list

Invocation:

```text
adrctl list
```

The command SHALL write one recognized ADR pathname per line to standard output in
numeric ADR order.

Paths are presented relative to the caller's cwd when possible, preserving the
useful predecessor-style path surface from nested directories.

If the ADR directory does not exist, `list` SHALL fail with status 1 and diagnose
on standard error.  It SHALL NOT write an error sentence into result stdout.

## Command: help

Invocation:

```text
adrctl help [COMMAND [SUBCOMMAND...]]
```

Without arguments, help summarizes built-in commands.  Built-in command/report
subjects MAY request focused help.  External plugin help is never discovered.

Pager selection is:

```text
ADR_PAGER
PAGER
more
```

`ADR_PAGER` takes precedence over `PAGER`.

Pager configuration SHALL NOT be executed with `eval`.

## Command: generate

Invocation:

```text
adrctl generate [REPORT [OPTION...]]
```

With no REPORT, the command SHALL list built-in report names in deterministic
order:

```text
toc
graph
```

Unknown reports fail with status 2.

### generate toc

Invocation:

```text
adrctl generate toc [-i INTRO_FILE] [-o OUTRO_FILE] [-p LINK_PREFIX]
```

The report writes Markdown to standard output beginning with:

```text
# Architecture Decision Records
```

Readable `INTRO_FILE` content is inserted after the heading and before ADR
entries.  Each ADR entry is a Markdown bullet linking its title to its basename,
optionally prefixed by `LINK_PREFIX`.  Readable `OUTRO_FILE` content follows the
entries.

Intro/outro files SHALL be validated before report output begins where practical.

### generate graph

Invocation:

```text
adrctl generate graph [-p LINK_PREFIX] [-e LINK_EXTENSION]
```

The default link extension is:

```text
.html
```

The command SHALL emit Graphviz DOT source to standard output and SHALL NOT invoke
Graphviz.

Each node contains its ADR title and a URL derived from basename, `LINK_PREFIX`,
and `LINK_EXTENSION`.

The report preserves predecessor-style dotted edges between successive logical
ADR numbers and emits relationship edges derived from recognized Status links.
Reverse relationship labels ending in ` by` are omitted from graph relationship
edges to avoid duplicate reciprocal presentation, preserving predecessor intent.

## Command: upgrade-repository

Invocation:

```text
adrctl upgrade-repository
```

The initial inherited migration converts Date lines of the form:

```text
Date: DD/MM/YYYY
```

into:

```text
Date: YYYY-MM-DD
```

for recognized ADR files.

Other lines are preserved.  Files already using ISO dates remain unchanged by a
second run.  The command SHALL preflight/pre-render intended replacements and use
atomic per-file replacement where practical.

The command performs no unrelated repository migrations.

## External Process Boundaries

Editor precedence for ordinary `new` is:

```text
VISUAL
EDITOR
no-op
```

Pager precedence for help is:

```text
ADR_PAGER
PAGER
more
```

Git MAY be queried for project-root fallback.  Core ADR commands SHALL NOT stage,
commit, checkout, or otherwise mutate Git state automatically.

`generate graph` emits DOT.  Graphviz is not a core runtime dependency.

External command configuration SHALL be invoked without `eval`.

## Standard Streams

Standard output is reserved for requested results, including:

- created ADR pathname;
- ADR lists;
- generated reports;
- requested help when directly emitted; and
- requested version information.

Diagnostics, warnings, migration notices, and errors SHALL go to standard error.

## Exit Statuses

The stable initial public status vocabulary is:

```text
0  successful completion
1  operational/domain failure
2  invalid usage or invalid adrctl configuration
```

Status 1 examples include unresolved/ambiguous references, unreadable required
files, detected destination collisions, and external editor/pager failures that
prevent successful completion.

Status 2 examples include unknown commands/options, missing required arguments,
malformed `-l` specifications, unknown `ADRCTL_` project keys, and invalid
delimiter pairs.

Internal `mktext` statuses SHALL be translated into this public vocabulary.

Signal termination MAY retain Bash signal-derived statuses.

## Version Output

`--version` SHALL use this stable three-line shape:

```text
adrctl VERSION
build_date=BUILD_DATE
commit=BUILD_COMMIT
```

The output is identical when the artifact is invoked as `adrctl.bash`, installed
as `adrctl`, reached through the `adr` symlink, or reached through a shell alias
that expands to the artifact path.

## Dependency Verification and Network Policy

Normal runtime operations SHALL NOT fetch dependencies or templates from the
network.

The build/release process pins `mktext` v0.0.6.  The expected release-asset
SHA-256 is:

```text
03d8b99188251ffeca394cd5737e8876813190d14d671109f2fbe236f4b13c01
```

The artifact SHALL be verified before it is embedded unchanged into
`dist/adrctl.bash`.

## Build and Release Contract

Make is the canonical orchestration interface.

The repository SHALL provide at least:

```text
all/build
check
format
test
test-report
docs
docs-clean
docs-stage
checksums
clean
distclean
```

The maintained module order used for assembly SHALL be explicit.

Release automation SHALL:

1. calculate/validate the SemVer release version without creating an early tag;
2. validate maintained source;
3. acquire and verify pinned build dependencies;
4. build the exact release-version `dist/adrctl.bash` artifact;
5. validate the exact artifact with the behavior suite;
6. validate the exact artifact under Bash 4.3;
7. generate and verify `dist/adrctl.bash.sha256`;
8. produce GitHub provenance attestation when supported; and
9. create the tag/release and publish the exact validated artifact/checksum.

The release workflow supplies the release version to Make.  Make SHALL NOT
independently calculate a different release version.

The project publishes one canonical `adrctl.bash` distribution artifact.  A
separate maintained `adr` or duplicate `adrctl` release artifact is not required.

## Documentation Contract

Documentation responsibilities are:

```text
README.md          human-facing product overview and use
AGENTS.md          contributor/agent operating guidance
doc/adr/*.md       architectural rationale and decisions
doc/adrctl-spec.md normative public behavioral contract
doc/reference/     generated source-reference documentation
source comments    implementation-level contracts and constraints
```

Hand-maintained Bash source SHALL use Doxygen-compatible documentation comments
for modules, functions, important state, side effects, streams, statuses, and
non-obvious invariants where applicable.

`make docs` SHALL regenerate browsable reference documentation.  GitHub Pages
SHOULD publish the generated reference output from the default branch.

## Development Contract

Normal behavioral/architectural work follows:

```text
document intent
-> implement the smallest coherent change
-> add/update observable-behavior tests
-> validate the generated artifact
-> review the complete diff
```

Tests MAY be written first to reproduce a defect or characterize unknown behavior.
The intended final behavior still belongs in the normative documentation before
the change is complete.

Tests SHALL prefer public commands, streams, statuses, files, filesystem effects,
configuration, reports, and literal generated-artifact behavior over private
helper structure.

## Known Intentional Deviations from adr-tools 3.0.0

The initial intentional-deviation set includes:

- ambiguous partial ADR references fail instead of choosing the first match;
- multi-file operations preflight before mutation and use atomic per-file
  replacement where practical;
- project configuration is parsed as data rather than evaluated shell code;
- any namespaced `ADRCTL_` project assignment establishes context and invalid
  namespaced keys then fail validation rather than being silently skipped;
- external plugin/subcommand discovery is not supported initially;
- ordinary failure diagnostics use stderr rather than polluting result stdout;
- malformed `-l` specifications with fourth-and-later colon fields fail instead
  of silently discarding those fields;
- built-in explanatory template prose is independently authored; and
- `adrctl` is the canonical product identity, with `adr` supported through the
  same artifact by filesystem symlink or ordinary shell alias semantics.

## Initial Non-Goals

The initial release does not promise:

- external plugin discovery;
- general Markdown parsing or formatting;
- automatic Git staging/commits;
- automatic Graphviz image rendering;
- cross-file transactional filesystem semantics;
- guaranteed multi-process sequential ADR number allocation;
- runtime dependency downloads;
- preservation of predecessor `eval`, first-match, silent-truncation, or
  avoidable partial-write implementation behavior; or
- arbitrary renaming of the `adrctl.bash` artifact as a supported product
  identity.

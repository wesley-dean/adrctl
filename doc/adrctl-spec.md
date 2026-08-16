# adrctl Behavioral Specification

## Purpose

This document is the normative behavioral specification for `adrctl`.

Architecture Decision Records under `doc/adr/` explain why the project selected
these behaviors.  This specification describes the current public contract that
implementation and tests are expected to satisfy.

Normative terms such as SHALL, SHALL NOT, SHOULD, and MAY are used deliberately.

While the initial ADR corpus remains Proposed, this specification is the working
contract for implementation.  If implementation exposes a conflict with an ADR,
the conflict SHALL be resolved in the ADR/specification rather than silently
encoded in source.

## Product and Compatibility Identity

The project, product, release artifact, and canonical executable name are:

```text
adrctl
```

The generated executable SHALL also support invocation through a symbolic link
named:

```text
adr
```

The `adr` name is a compatibility invocation alias, not a separate product mode.
Inherited commands SHALL use the same implementation and project semantics under
both names.

Help and diagnostics SHOULD use the invoked basename so examples look natural to
the user.  Version and provenance output SHALL identify the installed product as
`adrctl` regardless of invocation basename.

The initial compatibility comparator is `npryce/adr-tools` release 3.0.0 at
commit `b47d3837d452ca6d2509d2524c7a08c701e84367`.

## Runtime and Generated Artifact

`adrctl` requires Bash 4.3 or newer.

The canonical generated consumer artifact is:

```text
dist/adrctl
```

It SHALL:

- begin with `#!/usr/bin/env bash`;
- be executable with mode `0755`;
- contain the complete core runtime in one file;
- embed the verified `mktext` v0.0.6 release artifact;
- contain exactly one effective `adrctl` product entrypoint;
- work when reached through an `adr` symlink; and
- require no runtime network access for normal operation.

The embedded `mktext` artifact is a private implementation dependency.  Its
public function may be used internally, but its numeric return statuses and
standalone command surface are not automatically part of the `adrctl` CLI.

Build metadata SHALL be injected into the generated artifact:

```text
VERSION
BUILD_DATE
BUILD_COMMIT
```

`BUILD_DATE` SHALL be based on the source revision timestamp rather than the
wall-clock time at which the artifact happened to be assembled.

Runtime version reporting SHALL NOT query Git, the clock, or the network.

## Public Command Grammar

The public command grammar is conceptually:

```text
adrctl [GLOBAL-OPTION...] COMMAND [COMMAND-OPTION...] [ARGUMENT...]
```

The same grammar SHALL work with `adr` substituted for `adrctl` when the artifact
is reached through the supported symlink.

The initial public commands are:

```text
help
init
new
link
list
generate
upgrade-repository
```

The initial report names under `generate` are:

```text
toc
graph
```

No external `adr-*` or `adrctl-*` plugin discovery is supported.

### Global informational forms

These forms SHOULD be supported:

```text
adrctl help
adrctl -h
adrctl --help
adrctl --version
```

`-h` and `--help` SHALL provide top-level help without requiring a project.
`--version` SHALL provide version information without requiring a project.

### Project-root option

Commands that operate on project state SHALL accept:

```text
--project-root PATH
```

as an explicit root override.  The option is global and SHALL be interpreted
before project discovery.

The option MAY appear before the command.  The implementation MAY also accept it
in a command-specific position when doing so is unambiguous, but documentation
SHALL use the global form.

## Project Discovery

For commands operating on an existing project, `PROJECT_ROOT` SHALL be selected
in this order:

1. `--project-root PATH`;
2. process-environment `ADRCTL_PROJECT_ROOT`;
3. nearest recognized project marker while walking upward from cwd;
4. Git work-tree root, when available;
5. cwd.

Recognized project markers are:

- `.adr-dir`;
- an existing `doc/adr` directory; or
- `.env` containing at least one supported project-scoped `ADRCTL_` assignment.

An unrelated `.env` SHALL NOT establish project context.

`ADRCTL_PROJECT_ROOT` is process-environment configuration only.  It SHALL NOT be
a valid project `.env` assignment and SHALL NOT, by itself, make a `.env` file a
project marker.

When multiple ancestor markers exist, the nearest ancestor containing any
recognized marker SHALL win.

### init exception

`init` creates project context.  Unless `--project-root` or process-environment
`ADRCTL_PROJECT_ROOT` is supplied, `init` SHALL use cwd as `PROJECT_ROOT` and
SHALL NOT climb to a Git root before initialization.

## Project Configuration

After `PROJECT_ROOT` is known, `adrctl` SHALL read `${PROJECT_ROOT}/.env` when the
file exists.

The file SHALL be parsed as data and SHALL never be sourced or evaluated.

### .env grammar

The parser SHALL accept:

- blank lines;
- full-line comments whose first nonblank character is `#`;
- optional `export` before an assignment;
- `KEY=VALUE` assignments;
- optional horizontal/ordinary shell whitespace around key and value; and
- one matching outer layer of single or double quotes around a value.

The parser SHALL NOT perform:

- parameter expansion;
- command substitution;
- backtick evaluation;
- escape-sequence interpretation;
- nested quote parsing; or
- shell execution.

Keys SHALL match:

```text
[A-Za-z_][A-Za-z0-9_]*
```

Non-`ADRCTL_` keys SHALL be ignored.

An unknown or source-inappropriate `ADRCTL_` key in the selected project `.env`
SHALL fail configuration validation with status 2.

### Initial supported project keys

The initial project `.env` namespace is:

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
ADRCTL_ADR_DIR
ADRCTL_TEMPLATE
ADRCTL_FILENAME_PATTERN
ADRCTL_TEMPLATE_START_DELIMITER
ADRCTL_TEMPLATE_END_DELIMITER
```

Legacy process-environment compatibility inputs are:

```text
ADR_TEMPLATE
ADR_DATE
VISUAL
EDITOR
ADR_PAGER
PAGER
```

Where a modern and legacy variable control the same concept at the same process
environment layer, the `ADRCTL_` variable SHALL win.

### General precedence

For project-scoped settings, effective value precedence is:

```text
command-line option
process environment
project .env
compatible legacy project metadata
built-in default
```

Higher-precedence values replace lower-precedence values for the same setting.

## Path Semantics and ADR Directory

A configured path beginning with `/` is absolute.

Other configured paths SHALL be resolved relative to `PROJECT_ROOT`, unless a
command explicitly documents another path base.

The ADR directory SHALL be selected in this order:

1. explicit command option when one is defined;
2. process-environment `ADRCTL_ADR_DIR`;
3. project `.env` `ADRCTL_ADR_DIR`;
4. `.adr-dir` content at `PROJECT_ROOT`;
5. `doc/adr` relative to `PROJECT_ROOT`.

`.adr-dir` content SHALL be parsed as a path value, not shell code.

The ADR directory MAY be outside `PROJECT_ROOT` when an explicit absolute path is
configured.  Commands SHALL still treat that resolved directory as the boundary
for ADR filenames and references.

## Rendering Boundary

`adrctl` owns value acquisition and transformation.

`mktext` owns literal textual substitution.

`adrctl` SHALL prepare a Bash associative-array rendering context containing, as
applicable:

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

Future keys MAY be added without changing the meaning of existing keys.

### Context values

`NUMBER` is the logical decimal ADR number without forced padding.

`NUMBER4` is the logical number rendered with a minimum width of four decimal
digits and leading zeroes.  Values larger than four digits are not truncated.

`TITLE` is the title formed from the title arguments supplied to `new`.

`TITLE_SLUG` is a lowercase hyphen-separated filename slug.  The compatibility
implementation SHALL:

1. treat runs of non-alphanumeric title characters as separators;
2. collapse each separator run to one `-`;
3. lowercase alphabetic characters using the supported runtime locale behavior
   chosen by the implementation; and
4. remove leading and trailing separators.

The compatibility corpus SHALL lock down representative ASCII punctuation,
whitespace, mixed-case, and empty/degenerate slug cases before release.

`DATE` defaults to the current local calendar date in `YYYY-MM-DD` form.
Process-environment `ADR_DATE` remains a compatibility override for created ADRs.
A future explicit modern date option MAY take higher precedence.

`STATUS` defaults to:

```text
Accepted
```

for an ordinary compatibility-oriented `new` operation.

`PROJECT_ROOT` and `ADR_DIR` are the resolved absolute or normalized project
locations used by the current operation.

## Template Selection

For an ordinary `new` command, the body template SHALL be selected in this order:

1. explicit command template option, when supplied;
2. process-environment `ADRCTL_TEMPLATE`;
3. legacy process-environment `ADR_TEMPLATE`;
4. project `.env` `ADRCTL_TEMPLATE`;
5. `${ADR_DIR}/templates/template.md`, when that file exists;
6. built-in `adrctl` default template.

A template path from configuration SHALL follow the project-relative path rules.

The built-in default template SHALL preserve the predecessor's structural
contract: a level-one numbered/title heading, a Date line, `## Status`,
`## Context`, `## Decision`, and `## Consequences` sections.  Its explanatory
placeholder prose SHALL be independently authored for `adrctl`; exact predecessor
prose is not a compatibility requirement.

The built-in initialization template SHALL likewise be independently authored
while creating an Accepted first ADR whose title records the decision to use ADRs.

## Delimiter Selection

Explicit delimiter settings SHALL be supplied as a pair:

```text
--start-delimiter STRING
--end-delimiter STRING
```

The effective delimiter pair is selected in this order:

1. command-line pair;
2. process-environment
   `ADRCTL_TEMPLATE_START_DELIMITER` / `ADRCTL_TEMPLATE_END_DELIMITER`;
3. project `.env` pair;
4. automatic detection.

At a single explicit layer, one delimiter without the other SHALL be invalid
usage/configuration.  Two empty strings are valid and select bare-key rendering.

When no explicit pair is effective, `adrctl` SHALL inspect the unrendered template
for a braced token with this lexical form:

```text
{ OPTIONAL-BLANKS KEY OPTIONAL-BLANKS }
```

where:

```text
KEY := [A-Za-z][A-Za-z0-9_-]*
```

The candidate key, after the same uppercase normalization used by the delimited
rendering contract, SHALL also exist in the prepared render context.

If at least one recognized braced context token exists, the selected delimiters
are:

```text
{
}
```

Otherwise the selected delimiters are both empty strings, selecting `mktext`
bare-key mode for legacy templates.

Automatic detection SHALL select one delimiter pair for one render.  It SHALL NOT
perform a mixed or two-pass implicit render.

Replacement values SHALL be inserted literally and nonrecursively according to
the pinned `mktext` contract.

## Filename Selection

The default filename pattern is behaviorally equivalent to:

```text
{NUMBER4}-{TITLE_SLUG}.md
```

The pattern SHALL be selected in this order:

1. explicit filename-pattern option, when supplied;
2. process-environment `ADRCTL_FILENAME_PATTERN`;
3. project `.env` `ADRCTL_FILENAME_PATTERN`;
4. built-in default.

Filename patterns SHALL be rendered using the prepared context and `mktext`.

The rendered result SHALL be one basename within `ADR_DIR`.  It SHALL NOT be
absolute, contain `/`, or contain a `..` path component capable of escaping the
ADR directory.

A rendered empty basename or a basename that fails filesystem safety validation
SHALL fail before mutation.

## ADR File Recognition and Ordering

A managed ADR filename SHALL have a basename matching the conceptual form:

```text
DIGITS-TEXT.md
```

where the leading `DIGITS` form the logical ADR number.

`list` and number allocation SHALL ignore unrelated files that do not have a
leading decimal-number/hyphen Markdown ADR form.

ADR ordering SHALL be numeric by logical ADR number, with a stable basename
fallback for duplicate numeric prefixes.

## Number Allocation

For a new ADR, `adrctl` SHALL scan recognized ADR filenames and choose one greater
than the greatest existing logical number.  When no recognized ADR exists, the
candidate number is 1.

The destination SHALL be protected against overwrite if another process creates
the same name after preflight.

Concurrent automatic sequencing is not guaranteed.  A clean collision SHALL fail
with status 1 or MAY be retried a small bounded number of times before failing.
No retry may overwrite the competing file.

## ADR Reference Resolution

Commands accepting an ADR reference SHALL support:

- exact logical number;
- exact filename/basename; and
- unique partial filename fragment.

An exact filename match wins over partial matching.

A numeric reference SHALL match the complete logical numeric prefix, ignoring
leading zeroes in the reference.

Zero matches SHALL fail with status 1.

More than one match SHALL fail with status 1 as ambiguous and SHALL identify the
candidate basenames on standard error.

Selecting the first ambiguous match, as the predecessor happened to do, is an
intentional safety deviation and is not supported.

## Markdown Structural Contract

`adrctl` uses a bounded line-oriented Markdown model rather than a complete
Markdown parser.

For compatibility-oriented documents:

- the title is the first level-one heading (`# `), conventionally the first line;
- the status section begins at the exact heading `## Status`;
- the status section ends at the next heading that terminates that level-two
  section under the implementation's documented line-oriented rules; and
- relationship lines are ordinary Markdown links inserted within the Status
  section.

A relationship line has the conceptual form:

```text
RELATIONSHIP [TARGET TITLE](TARGET-BASENAME)
```

Mutations SHALL preserve unrelated document text and formatting where practical.
The implementation SHALL NOT normalize the entire file merely to insert or remove
the owned status/link structure.

When required structure is absent or ambiguous, mutating commands SHALL fail
before replacing files rather than guessing a new insertion location.

## Multi-File Mutation Safety

A command that intends to create or modify more than one file SHALL complete all
reasonable validation before the first visible mutation.

Preflight includes, as applicable:

- project/configuration validation;
- ADR reference resolution;
- destination validation;
- template existence/readability;
- renderability;
- required Markdown structure;
- file readability/writability;
- relationship argument parsing; and
- collision checks.

The implementation SHALL prepare complete intended file contents before replacing
existing files.

Existing files SHOULD be replaced using same-directory temporary files and atomic
rename where practical.

The project does not promise true cross-file transactional atomicity.  A rare
filesystem failure after one atomic replacement may still leave a partially
applied multi-file operation.  The implementation SHALL minimize this window and
SHALL NOT preserve avoidable predecessor partial-write behavior as a compatibility
feature.

## Command: init

Invocation:

```text
adrctl init [DIRECTORY]
```

Without an explicit root override, `init` uses cwd as `PROJECT_ROOT`.

When `DIRECTORY` is supplied:

- it is interpreted relative to `PROJECT_ROOT` unless absolute;
- the directory SHALL be created when needed; and
- `.adr-dir` SHALL be written at `PROJECT_ROOT` with a project-relative path when
  the supplied directory is project-relative, preserving the predecessor
  compatibility marker.

When `DIRECTORY` is omitted, the ADR directory defaults to `doc/adr` and `init`
need not create `.adr-dir` merely to express that default.

`init` SHALL create the first ADR using an initialization template and SHALL not
open an interactive editor for that bootstrap ADR.

In an empty target ADR directory, the first ADR number SHALL be 1 and the default
filename SHALL be compatible with:

```text
0001-record-architecture-decisions.md
```

If the target directory already contains ADRs, `init` SHALL NOT silently overwrite
or recreate ADR 1.  The exact already-initialized diagnostic behavior SHALL be
covered by tests.

The created ADR pathname SHALL be written to standard output on success.

## Command: new

Invocation:

```text
adrctl new [-s REFERENCE]... [-l TARGET:LINK:REVERSE-LINK]... [NEW-OPTION...] TITLE...
```

`TITLE...` arguments are joined with single spaces to form `TITLE`.

An empty title SHALL fail with status 2.

Inherited options are:

```text
-s REFERENCE
-l TARGET:LINK:REVERSE-LINK
```

`-s` MAY be repeated.  Each reference names an existing ADR to be superseded by
the new ADR.

`-l` MAY be repeated.  Each value SHALL contain exactly three logical fields:
existing target reference, forward relationship text, and reverse relationship
text.  The initial compatibility syntax uses `:` as the field separator.
Malformed values SHALL fail before mutation.

Modern rendering options include:

```text
--template PATH
--filename-pattern PATTERN
--start-delimiter STRING
--end-delimiter STRING
```

The command SHALL:

1. resolve project/configuration/template inputs;
2. resolve every `-s` and `-l` target uniquely;
3. allocate the candidate ADR number;
4. prepare context, filename, and body;
5. prepare all reciprocal relationship/status changes;
6. preflight the complete intended change set;
7. create/replace files according to the mutation-safety contract;
8. invoke the selected editor unless editing is disabled; and
9. write the created ADR pathname to standard output.

For each `-s TARGET`, successful compatibility behavior includes reciprocal
relationships equivalent in meaning to:

```text
new ADR -> Supercedes -> TARGET
TARGET  -> Superceded by -> new ADR
```

and removal of the plain `Accepted` status line from the superseded target when
that line is the status being replaced.

The historical misspelling above is retained where compatibility output requires
it.  New descriptive prose may use standard spelling.

For each `-l TARGET:LINK:REVERSE-LINK`, the new ADR receives `LINK` to TARGET and
TARGET receives `REVERSE-LINK` to the new ADR.

The editor is selected by `VISUAL`, then `EDITOR`, then a no-op fallback.

If the editor fails after files were successfully created, `new` SHALL return a
nonzero operational status and diagnose the editor failure.  It SHALL NOT delete
an otherwise successfully created ADR merely to simulate transactionality across
an interactive external process.

## Command: link

Invocation:

```text
adrctl link SOURCE LINK TARGET REVERSE-LINK
```

SOURCE and TARGET are ADR references.

The command SHALL resolve both references uniquely, validate both Status sections,
prepare both outputs, then add reciprocal relationship lines:

```text
SOURCE -> LINK         -> TARGET
TARGET -> REVERSE-LINK -> SOURCE
```

Both files SHALL be preflighted before either is replaced.

## Command: list

Invocation:

```text
adrctl list
```

The command SHALL write one recognized ADR pathname per line to standard output in
numeric ADR order.

Paths SHOULD use the resolved ADR-directory form consistently.  The compatibility
corpus SHALL lock down whether output is project-relative or carries the resolved
ADR-directory prefix for default and configured directories.

If the ADR directory does not exist, `list` SHALL fail with status 1 and write a
diagnostic to standard error.  It SHALL NOT write an error sentence to standard
output.

The stderr choice is an intentional cleanup of predecessor stream behavior.

## Command: help

Invocation:

```text
adrctl help [COMMAND [SUBCOMMAND...]]
```

Without arguments, help SHALL summarize available built-in commands.

With command/report arguments, help SHALL display the corresponding built-in help
when available.

Help SHALL NOT discover external plugin executables.

Pager selection is:

```text
ADR_PAGER
PAGER
more
```

An explicit unpaged help mode MAY bypass a pager.

Pager configuration SHALL not be executed with `eval`.

## Command: generate

Invocation:

```text
adrctl generate [REPORT [OPTION...]]
```

With no REPORT, the command SHALL list supported built-in report names, one per
line, in deterministic order.

Unknown report names SHALL fail with status 2 and SHALL NOT attempt external
report-generator discovery.

### generate toc

Invocation:

```text
adrctl generate toc [-i INTRO_FILE] [-o OUTRO_FILE] [-p LINK_PREFIX]
```

The report SHALL write Markdown to standard output beginning with:

```text
# Architecture Decision Records
```

When `INTRO_FILE` is supplied, its contents SHALL be inserted after the heading
and before ADR entries.

Each ADR entry SHALL be a Markdown bullet linking the ADR title to its basename,
optionally prefixed by `LINK_PREFIX`.

When `OUTRO_FILE` is supplied, its contents SHALL follow the entries.

Input files SHALL be validated for readability before report output begins where
practical so a missing intro/outro does not produce a misleading partial report.

### generate graph

Invocation:

```text
adrctl generate graph [-p LINK_PREFIX] [-e LINK_EXTENSION]
```

The default `LINK_EXTENSION` is:

```text
.html
```

The command SHALL emit Graphviz DOT source to standard output.  It SHALL NOT
invoke `dot` or require Graphviz to be installed.

Each ADR node SHALL include its title and a URL derived from the ADR basename,
`LINK_PREFIX`, and `LINK_EXTENSION`.

The report SHOULD preserve the predecessor's dotted sequential edges between
successive ADR numbers and relationship edges derived from recognized Status
links, except where malformed/ambiguous documents are rejected by the safer
parser contract.

## Command: upgrade-repository

Invocation:

```text
adrctl upgrade-repository
```

The inherited initial upgrade behavior SHALL convert predecessor Date lines of
the form:

```text
Date: DD/MM/YYYY
```

into:

```text
Date: YYYY-MM-DD
```

for recognized ADR files.

The command SHALL preflight the set of files it intends to modify and SHALL use
atomic per-file replacement where practical.

Lines not matching the documented legacy Date form SHALL be preserved.

The command SHALL be idempotent for files already using `YYYY-MM-DD` dates.

No unrelated repository migration SHALL be performed merely because the command
is named `upgrade-repository`.

## Editor, Pager, Git, and Graphviz Boundaries

The editor selection order for ordinary `new` operations is:

```text
VISUAL
EDITOR
no-op
```

The pager selection order for paged help is:

```text
ADR_PAGER
PAGER
more
```

Git MAY be queried for project-root fallback.  Core ADR commands SHALL NOT
implicitly stage, commit, checkout, or otherwise mutate Git repository state.

`generate graph` emits DOT.  Graphviz is not an initial core runtime dependency.

## Standard Streams

Standard output is reserved for requested command results, including:

- created ADR pathname;
- ADR lists;
- generated reports;
- requested help when directly emitted; and
- version information.

Diagnostics, warnings, migration notices, and errors SHALL go to standard error.

## Exit Statuses

The stable initial status vocabulary is:

```text
0  success
1  operational/domain failure
2  invalid usage or invalid adrctl configuration
```

Examples of status 1 include unresolved or ambiguous ADR references, unreadable or
unwritable required files, detected concurrent destination collisions, and
external editor/pager failure when that failure prevents successful command
completion.

Examples of status 2 include unknown commands/options, missing required arguments,
malformed `-l` specifications, unknown `ADRCTL_` project keys, and invalid
one-sided delimiter pairs.

Internal `mktext` statuses SHALL be mapped to this public vocabulary.

Signal termination MAY retain normal Bash signal-derived statuses.

## Version Output

`--version` SHALL identify the product as `adrctl` and report the embedded version,
source-revision timestamp, and source commit in a stable, testable format.

A compatible initial format is:

```text
adrctl VERSION
build_date=BUILD_DATE
commit=BUILD_COMMIT
```

This format SHALL be identical whether invoked as `adrctl --version` or through
`adr --version`.

## Dependency and Network Policy

Normal runtime commands SHALL NOT fetch dependencies or templates from the
network.

The verified `mktext` dependency is acquired only during build/release workflows
and embedded into the final artifact.

Build-time `mktext` v0.0.6 verification uses its published SHA-256 digest:

```text
03d8b99188251ffeca394cd5737e8876813190d14d671109f2fbe236f4b13c01
```

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

The release workflow SHALL validate source and behavior, acquire/verify build
dependencies, build the exact release artifact, test that artifact, generate a
SHA-256 checksum, produce GitHub provenance attestation when supported, and
publish the exact validated bytes.

The release workflow supplies the SemVer value to Make.  Make SHALL NOT calculate
a different release version independently.

## Documentation Contract

The repository documentation roles are:

```text
README.md          human-facing product overview and use
AGENTS.md          contributor/agent operational guidance
doc/adr/*.md       architectural rationale and decisions
doc/adrctl-spec.md normative public behavioral contract
doc/reference/     generated source-reference documentation
source comments    implementation-level contracts and constraints
```

Generated reference documentation SHALL be derived from Doxygen-compatible Bash
comments and SHOULD be committed/published for browser access.

## Development Contract

Behavioral or architectural changes SHALL normally proceed:

document intent -> implementation -> observable-behavior tests -> generated
artifact validation -> complete diff review.

Tests MAY be written first to reproduce a bug or characterize unknown behavior,
but documentation SHALL describe the intended final contract before the change is
considered complete.

Tests SHALL prefer public commands, streams, statuses, files, and generated
artifacts over private helper structure.

## Compatibility Classification

Every predecessor behavior characterized by the initial corpus SHALL be recorded
as:

```text
Compatible
Intentional deviation
New adrctl behavior
```

Known intentional deviations include at least:

- ambiguous partial ADR references fail instead of choosing the first match;
- multi-file operations preflight before mutation and use atomic per-file
  replacement where practical;
- configuration is parsed as data rather than evaluated shell code;
- external plugin discovery is not supported initially;
- ordinary failure diagnostics use stderr rather than polluting result stdout;
- built-in explanatory template prose is independently authored; and
- `adrctl` is the canonical product identity, with `adr` supported through a
  symlink to the same artifact.

## Non-Goals for the Initial Release

The initial release does not promise:

- external plugin discovery;
- general Markdown parsing or formatting;
- automatic Git commits or staging;
- automatic Graphviz image rendering;
- cross-file transactional filesystem semantics;
- guaranteed multi-process ADR number sequencing;
- runtime dependency downloads;
- preservation of accidental predecessor `eval`, first-match, or partial-write
  implementation behavior; or
- arbitrary renaming of the `adrctl` artifact as a supported product identity.

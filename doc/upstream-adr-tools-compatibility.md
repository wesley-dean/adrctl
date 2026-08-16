# Upstream adr-tools Compatibility and Provenance Baseline

## Purpose

This document records the upstream implementation used to establish `adrctl`
compatibility requirements and the provenance boundary that applies while the new
implementation is developed.

It is evidence for later ADRs, specifications, and compatibility tests.  It is
not itself the normative behavioral specification.

## Canonical upstream

The compatibility reference is:

```text
Repository: npryce/adr-tools
Release:    3.0.0
Tag commit: b47d3837d452ca6d2509d2524c7a08c701e84367
```

Release 3.0.0 is the latest published GitHub release.  The upstream `master`
branch is five commits ahead at:

```text
b3279baf9be2207d1a4f4bbd608fd0b591c72aee
```

A repository comparison shows that the changes after release 3.0.0 affect only
`INSTALL.md` and `README.md`; no product source or behavior-test files differ.
Therefore release 3.0.0 is a suitable stable compatibility baseline while the
current `master` branch remains useful documentation evidence.

If later investigation finds packaged downstream variants with behavior that the
project deliberately wishes to support, those variants should be recorded as
additional compatibility inputs rather than silently changing this baseline.

## Observed public behavior relevant to the rewrite

The initial source and test review establishes at least these compatibility
surfaces:

- the public command is `adr` and uses subcommands;
- `adr new` creates a numbered Markdown ADR and prints its filename to standard
  output;
- filenames use a four-digit zero-padded number by default;
- the number inserted into a legacy template is not zero-padded;
- titles are transformed into lowercase hyphenated filename slugs;
- `ADR_DATE` can override the generated date;
- `VISUAL` takes precedence over `EDITOR` for editing a newly created ADR;
- `ADR_PAGER` takes precedence over `PAGER` for help display;
- `.adr-dir` and `doc/adr` are searched for while walking upward from the current
  directory;
- project-specific body templates use unbraced `TITLE`, `STATUS`, `NUMBER`, and
  `DATE` tokens;
- legacy template substitutions are sequential `sed` substitutions;
- link and supersede operations may update multiple ADR files;
- graph and table-of-contents generation are public command surfaces; and
- subcommands in the upstream implementation are separate executable `adr-*`
  files located in the configured binary directory.

This list is an initial inventory.  The compatibility corpus should establish the
complete supported command set and exact observable contracts before the first
implementation milestone is considered complete.

## Implementation behavior is not automatically a compatibility contract

The rewrite distinguishes public behavior from upstream implementation
mechanisms.

For example, the upstream source uses shell evaluation for generated
configuration and implements subcommands as separate executable files.  Those
mechanisms are evidence about how the predecessor works; they do not by
themselves require `adrctl` to retain the same internals when the public behavior
can be preserved more safely and maintainably.

Likewise, accidental partial-write behavior on a failing multi-file command is
not promoted into a compatibility promise.  ADR-007 explicitly selects strong
preflight and atomic per-file replacement where practical while preserving
successful predecessor outcomes.

## Template compatibility with mktext

Legacy `adr-tools` project templates use bare tokens such as:

```text
TITLE
STATUS
NUMBER
DATE
```

Modern `mktext` templates commonly use braced macros such as:

```text
{TITLE}
{STATUS}
{NUMBER}
{DATE}
```

The initial grammar mismatch has been resolved by changes released in `mktext`
v0.0.6.  `mktext render` accepts explicit starting and ending delimiters; two
empty delimiters select bare-key mode with whole-token matching.  This allows one
renderer to support both legacy bare tokens and modern braced tokens without an
`adrctl`-owned compatibility renderer.

ADR-001 defines the `adrctl` policy:

1. explicit CLI delimiter configuration wins;
2. then explicit environment configuration;
3. then explicit project configuration;
4. otherwise `adrctl` inspects the template for a recognized braced render token;
5. a recognized braced token selects `{` and `}`; and
6. if none is found, empty delimiters select legacy-compatible bare-key mode.

Exactly one delimiter pair is selected for each render.  Mixed implicit
rendering and two-pass substitution are not supported.

ADR-003 pins `mktext` v0.0.6 as a verified build dependency and incorporates its
release artifact unchanged into the generated `adrctl.bash` distribution artifact.
The v0.0.6 execution guard remains inert when the same bytes are executed as
`adrctl.bash`, installed or linked as `adrctl`, or reached through an `adr`
symlink, so the final product retains one effective process entrypoint.

## License and provenance boundary

The upstream `npryce/adr-tools` repository states that the program is licensed
under the GNU General Public License, version 3 or later.  It separately states
that content the tool adds to a user's project is licensed under CC BY 4.0.

The maintainer has explicitly selected the existing CC0 1.0 Universal license for
`adrctl`; ADR-004 records that decision.

The implementation process SHALL maintain a conservative provenance boundary:

- upstream source may be inspected to establish observable behavior and discover
  compatibility cases;
- upstream tests and documentation may be used as evidence for behavior that
  needs an independently authored `adrctl` test;
- GPL-covered upstream implementation code SHALL NOT be copied, translated,
  mechanically transformed, or adapted into `adrctl` source;
- new production code SHALL be independently authored against the documented
  `adrctl` architecture, specification, and compatibility corpus; and
- where a behavior can only be understood by inspecting upstream code, the
  resulting `adrctl` documentation should describe the observable contract rather
  than reproduce implementation expression from upstream.

This is an engineering provenance rule intended to keep the implementation
history reviewable.  It is not a substitute for legal advice about copyright or
license obligations.

## Compatibility baseline policy

For the initial rewrite milestone, the default behavioral comparator is upstream
`adr-tools` 3.0.0.

Behavior should be classified as:

```text
Compatible
Intentional deviation
New adrctl behavior
```

An intentional deviation should have:

- an explicit rationale;
- a Proposed/Accepted ADR as appropriate;
- a specification entry;
- a regression test; and
- migration guidance when an existing user workflow is affected.

The comparator version should be an explicit test input so later changes to
upstream repositories cannot silently redefine the baseline.

## Resolved architectural decisions

The material questions originally identified by this baseline have now been
resolved:

- **License:** `adrctl` remains CC0 under ADR-004.
- **Executable compatibility:** `adrctl` remains the canonical product and
  installed command identity; the generated distribution artifact is
  `adrctl.bash`, and the same bytes support an `adr` symlink or ordinary shell
  alias invocation under ADR-002 and ADR-019.
- **Template compatibility:** one `mktext` renderer with automatic delimiter
  selection and explicit overrides is defined by ADR-001 and ADR-003.
- **Project discovery:** explicit root overrides win, then the nearest recognized
  `.adr-dir`, `doc/adr`, or qualifying `.env` marker, then Git root, then cwd,
  under ADR-005.
- **External plugins:** external `adr-*`/`adrctl-*` plugin discovery is not
  supported initially; supported subcommands are built into the generated
  artifact under ADR-006.
- **Failure safety:** multi-file operations preflight the full intended change and
  use atomic per-file replacement where practical under ADR-007; accidental
  predecessor partial-write states are not compatibility requirements.

These decisions remove the original material blockers to drafting the remaining
ADR corpus and normative behavioral specification.

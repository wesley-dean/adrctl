# Upstream adr-tools Compatibility and Provenance Baseline

## Purpose

This document records the upstream implementation used to establish `adrctl`
compatibility requirements and the provenance boundary that applies while the new
implementation is developed.

It is evidence for later ADRs, specifications, and compatibility tests.  It is
not itself a license determination or an accepted `adrctl` architecture.

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
- graph and table-of-contents generation are public command surfaces;
- subcommands in the upstream implementation are separate executable `adr-*`
  files and are enumerated dynamically by filename.

This list is an initial inventory.  The compatibility corpus should establish the
complete supported command set and exact observable contracts before the first
implementation milestone is considered complete.

## Implementation behavior is not automatically a compatibility contract

The rewrite should distinguish public behavior from upstream implementation
mechanisms.

For example, the upstream source uses shell evaluation for generated
configuration and implements subcommands as separate executable files.  Those
mechanisms are evidence about how the predecessor works; they do not by
themselves require `adrctl` to retain the same internals when the public behavior
can be preserved more safely and maintainably.

Likewise, accidental partial-write behavior on a failing multi-file command
should not be promoted into a compatibility promise without an explicit decision.

## Template compatibility conflict with mktext

The upstream template grammar and `mktext` grammar are different.

Legacy `adr-tools` project templates use bare tokens such as:

```text
TITLE
STATUS
NUMBER
DATE
```

The accepted `mktext` grammar recognizes braced macros such as:

```text
{TITLE}
{STATUS}
{NUMBER}
{DATE}
```

`mktext` also performs one lexical, literal, nonrecursive substitution pass and
preserves unrelated or unknown text.  Directly passing a legacy body template to
`mktext` would therefore leave its legacy tokens unchanged.

The architecture must define an explicit compatibility boundary rather than
claim that the two template languages are interchangeable.

The current engineering recommendation is:

1. preserve a legacy body-template rendering path for existing `adr-tools`
   templates and default-compatible behavior;
2. use `mktext` for new explicitly selected braced rendering surfaces, including
   configurable filename templates;
3. do not weaken or extend `mktext` itself with ADR-specific legacy grammar;
4. test both rendering contracts independently.

The precise legacy substitution semantics and the opt-in mechanism for modern
body templates belong in the Proposed ADRs and behavioral specification.

## License and provenance boundary

The upstream `npryce/adr-tools` repository states that the program is licensed
under the GNU General Public License, version 3 or later.  It separately states
that content the tool adds to a user's project is licensed under CC BY 4.0.

The current `adrctl` repository inherited a CC0 1.0 Universal license from its
template repository.

Until the maintainer explicitly decides the licensing strategy for `adrctl`, the
implementation process SHALL maintain a conservative provenance boundary:

- upstream source may be inspected to establish observable behavior and discover
  compatibility cases;
- upstream tests and documentation may be used as evidence for behavior that
  needs an independently authored `adrctl` test;
- GPL-covered upstream implementation code SHALL NOT be copied, translated,
  mechanically transformed, or adapted into `adrctl` source;
- new production code SHALL be independently authored against the documented
  `adrctl` architecture, specification, and compatibility corpus;
- where a behavior can only be understood by inspecting upstream code, the
  resulting `adrctl` documentation should describe the observable contract rather
  than reproduce implementation expression from upstream.

This is an engineering provenance rule intended to keep the implementation
history reviewable while the repository-license decision is unresolved.  It is
not a substitute for legal advice about copyright or license obligations.

## Compatibility baseline policy

For the initial rewrite milestone, the default behavioral comparator should be
upstream `adr-tools` 3.0.0.

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
- a regression test;
- migration guidance when an existing user workflow is affected.

The comparator version should be an explicit test input so later changes to
upstream repositories cannot silently redefine the baseline.

## Open architectural decisions

This baseline leaves several decisions for maintainer discussion:

- whether `adrctl` remains CC0 or adopts another software license;
- whether command compatibility requires a literal `adr` entry point or only
  equivalent subcommand behavior under `adrctl`;
- how legacy templates opt into or coexist with modern `mktext` rendering;
- whether third-party `adr-*` subcommand discovery is a supported compatibility
  surface;
- how strongly `adrctl` improves preflight and partial-failure behavior relative
  to the predecessor.

Those decisions should be resolved before the initial Proposed ADR corpus is
finalized.
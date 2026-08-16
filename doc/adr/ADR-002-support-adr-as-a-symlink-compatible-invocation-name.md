# ADR-002: Support `adr` as a Symlink-Compatible Invocation Name

Date: 2026-08-15

## Status

Accepted

## Intent and Documentation Posture

This ADR defines the relationship between the canonical `adrctl` executable name
and the historical `adr` command name used by `npryce/adr-tools`.

`adrctl` is a successor to `adr-tools` with a deliberate new product identity,
but compatibility is substantially more useful when existing shell habits,
scripts, documentation, and automation can continue to invoke `adr`.  The
single-file distribution model makes it possible to support both invocation
names without publishing or maintaining a second executable implementation.

The decision therefore treats symlink-transparent invocation as a public
compatibility property of the generated `adrctl` artifact.

## Context

Canonical `adr-tools` exposes one public command named `adr`.  Its first argument
selects a subcommand, for example:

```text
adr init
adr new Use PostgreSQL
adr link ...
adr generate toc
adr generate graph
```

The successor project is named `adrctl`, and its canonical generated executable
will also be named `adrctl`.  Requiring every existing command, script, shell
alias, or document to change from `adr` to `adrctl` would impose avoidable
migration work even when the command semantics themselves remain compatible.

Publishing two separately maintained executables would work against the selected
single-artifact distribution model and would create unnecessary release,
checksum, provenance, documentation, and test surfaces.

Unix symbolic links provide a smaller compatibility mechanism.  A user or
packager can install the canonical artifact as `adrctl` and create an `adr`
symlink that points to it.  One executable can then serve both names if runtime
behavior does not depend improperly on the physical path or basename used to
invoke it.

This requirement must be deliberate.  Bash programs frequently use `$0` to find
adjacent resources, derive behavior, or print diagnostics.  Such implementation
choices can make symlink invocation behave differently even when no difference
was intended.  The compatibility property therefore needs to be specified and
tested rather than assumed.

## Decision Drivers

- Preserve established `adr` command invocations wherever technically practical.
- Retain `adrctl` as the canonical project, executable, release, and artifact
  identity.
- Avoid maintaining or releasing a second implementation merely for command-name
  compatibility.
- Keep the generated runtime artifact self-contained and location-independent.
- Allow packagers and users to provide a familiar `adr` command with an ordinary
  symbolic link.
- Make compatibility observable and testable at the actual consumer artifact.
- Avoid hidden behavior changes based on whether the executable was reached
  directly or through a symlink.

## Decision

The canonical generated and released executable SHALL be named:

```text
adrctl
```

`adrctl` SHALL support invocation through a symbolic link named `adr`.

For example, given an installed artifact:

```text
/path/to/adrctl
```

and a symbolic link:

```text
/path/to/adr -> /path/to/adrctl
```

these invocations SHALL dispatch through the same command implementation:

```text
adrctl new Use PostgreSQL
adr new Use PostgreSQL
```

For inherited `adr-tools` commands and options that `adrctl` documents as
compatible, invocation through the `adr` symlink SHALL preserve the same
observable command semantics as invocation through `adrctl`, except where this
ADR explicitly permits presentation differences based on the invoked name.

The runtime SHALL NOT use the invocation basename to select a different command
implementation, compatibility mode, configuration model, template renderer, or
filesystem behavior.  `adr` is an invocation alias, not a separate runtime mode.

The generated executable SHALL be self-contained with respect to its required
runtime implementation.  It SHALL NOT require sibling `adr-*` scripts or other
files located relative to `$0` merely to implement its core commands.  Reaching
the executable through a symlink SHALL therefore not change how required runtime
code is located.

The basename by which the executable was invoked MAY be used for human-facing
command presentation.  In particular, help, usage text, and diagnostic prefixes
SHOULD use the invoked basename when doing so improves compatibility and clarity:

```text
adr help
adr new TITLE...
```

when invoked as `adr`, and:

```text
adrctl help
adrctl new TITLE...
```

when invoked as `adrctl`.

This presentation rule SHALL NOT change command semantics, configuration keys,
release identity, or the canonical product name.

Version and provenance output SHALL identify the product and artifact as
`adrctl`, even when reached through an `adr` symlink.  A symlink changes the
invocation name; it does not change which product was installed.

The project SHALL NOT require the release workflow to publish a second `adr`
artifact.  The canonical release artifact remains `adrctl`.  Packaging systems
or users MAY create the `adr` symlink as an installation convenience.

The project MAY later provide installation tooling that creates the symlink, but
such tooling is outside this ADR.  The compatibility contract defined here is
that a correctly created symlink works; automatic creation is a separate product
and packaging decision.

Tests SHALL exercise the exact generated consumer artifact through both names.
At minimum, the test suite SHALL verify:

- direct execution of the generated `adrctl` artifact;
- execution through an `adr` symbolic link;
- inherited subcommand dispatch through both names;
- help and usage presentation through both names;
- exit-status propagation through both names;
- project/configuration discovery through both names;
- filesystem effects through both names for representative mutating commands;
- template rendering through both names; and
- behavior when the symlink and target reside at different path depths or when a
  relative symbolic link is used.

Compatibility tests SHALL compare observable behavior rather than private Bash
function names or internal dispatch structure.

The normative behavioral specification SHALL identify which inherited
`adr-tools` commands are compatible and any intentional deviations.  This ADR
does not independently declare every historical behavior compatible; it states
that the supported compatibility surface must remain available when the same
artifact is invoked as `adr`.

## Considered Alternatives

### Require users to invoke only `adrctl`

This would give the product one command name and the smallest documentation
surface.  It was rejected because command-name migration would break existing
shell habits, scripts, examples, and automation for no corresponding improvement
in runtime architecture.

### Publish separate `adrctl` and `adr` executables

Two release artifacts could provide both names directly.  This was rejected
because the second artifact would either duplicate the implementation or become
a wrapper with its own release and verification surface.  A symbolic link can
provide the same command-name compatibility while preserving one canonical
artifact.

### Make `adr` a special legacy compatibility mode

The program could inspect its basename and deliberately select old behavior when
invoked as `adr`, while exposing newer behavior under `adrctl`.  This was
rejected because it would create two overlapping products inside one file,
complicate documentation and testing, and make behavior depend on installation
naming rather than explicit configuration or command options.

### Ignore the invocation name completely in presentation

The runtime could always print `adrctl` in help and diagnostics even when invoked
as `adr`.  That would be mechanically simple, but it would make the compatibility
alias visibly inconsistent and could produce confusing instructions such as an
`adr` command telling the user to rerun `adrctl`.  Using the invoked basename for
presentation is a narrow and understandable exception that does not create a
behavioral mode.

### Resolve the symlink target and use its basename everywhere

The runtime could canonicalize `$0` and always derive presentation from the
physical target.  This was rejected because it defeats the human-facing value of
an `adr` compatibility symlink and can introduce platform-specific path
resolution dependencies without improving command correctness.

## Consequences

Existing users can preserve familiar `adr` invocations by creating a symbolic
link to the installed `adrctl` artifact.

Packagers can provide both command names without distributing two implementations.

The generated artifact must remain insensitive to symlink location for core
runtime behavior.  This reinforces the existing single-file, self-contained
distribution direction.

Help and diagnostics require a small amount of invocation-name awareness so they
can refer naturally to `adr` or `adrctl` according to how the program was
invoked.

Release metadata remains unambiguous because the installed product continues to
identify itself as `adrctl`.

The compatibility corpus gains a second literal consumer execution path.  This
increases the test matrix slightly, but it verifies a user-visible migration
property that would otherwise be easy to break accidentally.

This decision does not promise byte-for-byte identity with historical
`adr-tools`.  Exact compatibility remains command-specific and is defined by the
normative specification and compatibility corpus.  It does promise that whatever
historical behavior `adrctl` supports remains available through the `adr` symlink
unless an explicit later ADR changes that policy.

## Open Questions and Follow-Ups

The installation and packaging design must later decide whether official install
instructions merely document creation of the `adr` symlink or whether supported
installers/packages create it automatically.

The behavioral specification must define the complete inherited command surface
and the presentation requirements for help and diagnostics.

The generated-artifact tests must include symlink invocation before this ADR can
be considered fully implemented.

## Related Decisions

- Related to: ADR-000
- Related to: ADR-001
- Adapted in part from Bootstrap ADR-006, ADR-009, ADR-024, and ADR-030.
- Compatibility lineage: `npryce/adr-tools` ADR 0003, "Single command with subcommands."
- Related working assessment: `doc/architecture-portability-assessment.md`
- Related compatibility baseline: `doc/upstream-adr-tools-compatibility.md`

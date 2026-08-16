# ADR-009: Parse Project Configuration as Data with Explicit Precedence

Date: 2026-08-15

## Status

Accepted

## Context

ADR-005 defines how `adrctl` discovers project context.  Once a project root is
known, the product still needs a safe and deterministic configuration contract.

The predecessor uses generated shell configuration and `eval`.  That mechanism
is not required for compatibility and would make a project configuration file
executable code.  Bootstrap established a safer precedent: parse configuration as
data, namespace product-owned keys, reject unknown product keys, and give explicit
runtime inputs higher precedence than project defaults.

`adrctl` also needs to preserve `.adr-dir` as a compatibility input while adding
new `ADRCTL_` configuration without allowing multiple sources to silently fight
over the same setting.

Project-root selection is intentionally separate from project-file
configuration.  A `.env` file can only be read after its project root has already
been selected, so allowing that same file to redirect `PROJECT_ROOT` would create
recursive or order-dependent discovery semantics.

## Decision

The primary project configuration file SHALL be `.env` at the resolved
`PROJECT_ROOT`.

The file SHALL be parsed as data.  `adrctl` SHALL NOT `source`, `eval`, or execute
its contents.

Product-owned configuration keys SHALL use the `ADRCTL_` prefix.

The effective value precedence for project-scoped settings SHALL be, from highest
to lowest:

1. explicit command-line option;
2. process environment variable;
3. parsed project `.env` value;
4. compatible legacy project metadata such as `.adr-dir` where applicable;
5. built-in default.

A value supplied at a higher layer SHALL completely replace the corresponding
lower-layer value.  The implementation SHALL NOT merge partial scalar values
across layers unless a future option explicitly defines merge semantics.

Unknown keys beginning with `ADRCTL_` in the project configuration SHALL be
reported as configuration errors.  This makes misspellings visible rather than
silently falling back to defaults.  Non-`ADRCTL_` keys in the same `.env` SHALL be
ignored by `adrctl`.

`ADRCTL_PROJECT_ROOT` SHALL be a process-environment override only.  It SHALL NOT
be a valid assignment in the project `.env` file.  A project file containing
`ADRCTL_PROJECT_ROOT` SHALL fail configuration validation rather than redirecting
configuration loading to another directory.

The initial project-file configuration namespace SHALL include, at minimum,
concepts for:

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

The normative specification MAY refine exact option spellings before
implementation, but configuration concepts and precedence SHALL remain as defined
here unless superseded by another ADR.

Relative configured filesystem paths SHALL resolve against `PROJECT_ROOT`, not
against the caller's current working directory.  Paths beginning with `/` SHALL
retain ordinary Unix absolute-path semantics.

An `.adr-dir` file at `PROJECT_ROOT` SHALL remain a supported compatibility input
for the ADR directory when no higher-precedence ADR directory setting exists.
Its content SHALL be treated as data and SHALL be validated before use.

When neither explicit configuration nor `.adr-dir` selects an ADR directory, the
default SHALL remain `doc/adr` relative to `PROJECT_ROOT`.

Project configuration SHALL NOT mutate process-global shell state beyond the
private variables needed by the current command.  Configuration parsing SHALL be
complete before a mutating command begins filesystem changes.

## Considered Alternatives

### Source `.env` as shell code

This would provide shell expansion and arbitrary logic, but it would make merely
using a repository execute repository-controlled code.  It also creates quoting,
portability, and reproducibility problems.

### Allow `.env` to redefine its own project root

This was rejected because discovery must already know the root before it can
select and read the file.  A root value inside that file would either be ignored,
force a second discovery pass, or create recursive configuration semantics.
Project-root overrides therefore remain CLI/process inputs.

### Silently ignore unknown `ADRCTL_` keys

That would make forward compatibility superficially permissive but would hide
configuration typos.  Product-owned unknown keys should fail loudly.

### Resolve relative paths against cwd

That makes behavior change according to which nested directory the user happens
to run the command from.  Project-relative configuration should remain stable
once `PROJECT_ROOT` is resolved.

### Replace `.adr-dir` immediately

Removing the predecessor marker would create needless migration work.  It can
remain a bounded compatibility input while `.env` supplies the richer modern
configuration surface.

## Consequences

Projects can share an application `.env` with `adrctl` without granting shell
execution or requiring every key to belong to `adrctl`.

Configuration behavior remains deterministic from nested working directories.

Legacy `.adr-dir` repositories continue to work while newer settings have an
explicit precedence model.

Project-root discovery remains one-way and cannot be redirected by the file that
discovery selected.

## Related Decisions

- Related to: ADR-001
- Related to: ADR-005
- Related to: ADR-007
- Adapted from Bootstrap ADR-023, ADR-024, ADR-040, and ADR-042.
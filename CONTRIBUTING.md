# Contributing to adrctl

Thank you for considering a contribution to `adrctl`.

`adrctl` is a compatibility-oriented Bash successor to `adr-tools`.  Changes can
affect existing command workflows, generated ADR files, project discovery,
template rendering, shell automation, or release artifacts, so contributors are
asked to make behavior changes deliberately and document the intended contract.

Please review:

- [README.md](README.md) for product orientation and current use;
- [AGENTS.md](AGENTS.md) for the contributor/agent operating model;
- [doc/adrctl-spec.md](doc/adrctl-spec.md) for the normative behavioral contract;
- [doc/adr/](doc/adr/) for architectural rationale and decisions;
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community expectations; and
- [LICENSE](LICENSE) for the CC0 dedication.

## Development approach

The project follows documentation-driven, test-second development.

For a public behavior or architectural change, the normal sequence is:

1. establish or update the documented intent;
2. implement the smallest coherent change;
3. add or update observable-behavior tests;
4. build and validate all generated distribution artifacts;
5. exercise the installed `adrctl`, `adr` symlink, or shell-alias path when
   invocation identity is relevant; and
6. review the complete diff for compatibility and documentation drift.

Tests may be written first when they are the clearest way to reproduce a defect or
characterize unknown behavior.  The intended final contract must still be
captured in the relevant documentation before the change is complete.

## Compatibility

The initial compatibility baseline is `npryce/adr-tools` 3.0.0.

When a change touches predecessor behavior, classify the result as:

```text
Compatible
Intentional deviation
New adrctl behavior
```

Intentional deviations should have a clear rationale, specification coverage,
and a regression test.  User-visible deviations from established successful
workflows should include migration guidance when appropriate.

Do not copy, translate, or mechanically adapt GPL-covered `adr-tools`
implementation code into `adrctl` production source.  Upstream source and tests
may be inspected to establish observable behavior; the `adrctl` implementation
must be independently authored against the documented contract and compatibility
evidence.

## Build and validation

Make is the canonical local orchestration surface.

Useful targets include:

```bash
make all
make deps
make deps-check
make build
make check
make test
make test-report
make format
make docs
make docs-clean
make checksums
```

A successful `make build` produces three executable flavors and three adjacent
SHA-256 check files:

```text
dist/adrctl.dev.bash
dist/adrctl.bash
dist/adrctl.min.bash
dist/adrctl.dev.bash.256
dist/adrctl.bash.256
dist/adrctl.min.bash.256
```

The development flavor retains maintained adrctl comments, `adrctl.bash` is the
standard comment-stripped distribution, and the minified flavor is produced from
the standard artifact by the manifest-managed Bash-Minifier.  These files are
build output, not maintained source, and should not be edited directly.

`make build` is network-free and expects dependency state to have been prepared.
Use `make all` from a fresh checkout or run `make deps build` explicitly.

The behavior and minimum-Bash suites validate all three executable flavors.  A
passing standard artifact does not by itself establish that the development or
minified representation is safe to release.

Doxygen reference documentation under `doc/reference/` is also generated output.
It is ignored by Git, regenerated with `make docs`, and published to GitHub Pages
by the documentation workflow rather than committed to the repository.

Tests should prefer observable behavior such as command arguments, standard
streams, exit status, generated files, filesystem effects, reports, project
configuration, and literal execution of the generated artifacts.

## Architecture changes

Architecture Decision Records are stored under `doc/adr/`.

Accepted ADRs are historical architectural records.  When a later decision
changes an accepted contract, add a new ADR that explicitly supersedes the
relevant portion rather than silently rewriting the earlier rationale.

If implementation exposes a conflict with an ADR or the behavioral
specification, surface and resolve that conflict explicitly.  Do not let source
code silently become a new architectural contract.

## Public domain

This project is dedicated to the public domain through the
[CC0 1.0 Universal public domain dedication](LICENSE).

All contributions to this project are released under the same CC0 dedication.
By submitting a pull request or issue, you agree that your contribution may be
used under those terms.

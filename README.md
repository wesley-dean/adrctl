# adrctl

[![Dependabot Updates](https://github.com/wesley-dean/adrctl/actions/workflows/dependabot/dependabot-updates/badge.svg)](https://github.com/wesley-dean/adrctl/actions/workflows/dependabot/dependabot-updates)
[![MegaLinter](https://github.com/wesley-dean/adrctl/actions/workflows/megalinter.yml/badge.svg)](https://github.com/wesley-dean/adrctl/actions/workflows/megalinter.yml)
[![Scorecard supply-chain security](https://github.com/wesley-dean/adrctl/actions/workflows/scorecard.yml/badge.svg)](https://github.com/wesley-dean/adrctl/actions/workflows/scorecard.yml)
[![Tests](https://github.com/wesley-dean/adrctl/actions/workflows/test.yml/badge.svg)](https://github.com/wesley-dean/adrctl/actions/workflows/test.yml)
[![Documentation](https://github.com/wesley-dean/adrctl/actions/workflows/static.yml/badge.svg)](https://github.com/wesley-dean/adrctl/actions/workflows/static.yml)

`adrctl` is a Bash tool for creating and maintaining Architecture Decision
Records (ADRs).  It is a deliberate successor to
[`npryce/adr-tools`](https://github.com/npryce/adr-tools) that preserves familiar
workflows where practical while improving configuration safety, failure
preflight, testing, documentation, and release discipline.

The canonical product identity is `adrctl`.  The generated and released
executable is named `adrctl.bash`.  The same generated artifact is designed to
work through an `adr` symbolic link or alias for command-name compatibility with
existing `adr-tools` habits and automation.

## Status

`adrctl` is under active development.  The current implementation, behavioral
specification, ADR corpus, documentation, and release workflow live on `main`.

The compatibility baseline is `adr-tools` 3.0.0.  Intentional deviations are
documented in the ADRs and in `doc/adrctl-spec.md` rather than being hidden in
implementation details.

## Requirements

Runtime requirements are intentionally small:

- Bash 4.3 or newer
- ordinary filesystem access appropriate to the requested operation
- Git only when Git-root fallback is needed for project discovery

Graph generation emits Graphviz DOT text and does not require Graphviz itself.
Template rendering is provided by a verified `mktext` dependency embedded into
the generated executable at build time, so normal runtime operation does not
fetch code from the network.

## Build

The maintained implementation is modular Bash source under `lib/` and `src/`.
Make assembles the exact consumer artifact:

```text
dist/adrctl.bash
```

From a fresh checkout, prepare the pinned dependencies and build the artifact with:

```bash
make all
```

`make all` deliberately performs two ordered operations.  First, `make deps`
bootstraps the pinned `vendor/bashdeps.bash` release artifact directly with
`curl`, verifies its committed SHA-256 digest, and uses it to synchronize the
project's `dependencies.txt`.  Bashdeps then materializes the current pinned
`mktext` and Bash Doxygen artifacts under `vendor/`.  After dependency
synchronization succeeds, `make all` runs `make build`.

The current dependency boundary is:

```text
Makefile
  -> vendor/bashdeps.bash
  -> make deps
       -> vendor/bashdeps.bash sync dependencies.txt
            -> vendor/mktext.bash
            -> vendor/doxygen-bash.awk
  -> make build
       -> dist/adrctl.bash
```

The Makefile owns only the bootstrap version, URL, and digest for `bashdeps.bash`.
Ordinary external dependency declarations live in `dependencies.txt`.  The
current manifest pins `mktext` v0.0.9 and `bash-doxygen` v0.0.6.

The workflow may also be run explicitly:

```bash
make deps
make deps-check
make build
```

`make deps` may use the network and repairs missing or mismatched dependency
state.  `make deps-check` verifies an already-present bashdeps bootstrap and all
manifest-managed artifacts without downloading or repairing anything.

Plain `make build` is intentionally network-free and dependency-management-free.
It consumes the prepared `vendor/mktext.bash` bytes and fails with a diagnostic
when that build input is absent.  Repeated builds therefore do not re-hash the
complete dependency set merely because another build was requested.

The verified `mktext.bash` bytes are embedded unchanged into the generated
`adrctl.bash` artifact.  `bashdeps.bash`, `dependencies.txt`, and the files under
`vendor/` are build/development inputs and are not required at runtime.

The generated artifact is build output rather than maintained source.  Do not
edit `dist/adrctl.bash` directly.

## Installation

The built or released executable is named `adrctl.bash`.  Install those bytes
under that filename, for example:

```bash
install -m 0755 dist/adrctl.bash ~/.local/bin/adrctl.bash
```

To retain the historical `adr` command name, create a symbolic link to that same
installed executable:

```bash
ln -s adrctl.bash ~/.local/bin/adr
```

### Bash startup setup

Interactive Bash users may instead add the following to `~/.bashrc`.  On shell
startup, the helper installs the latest released `adrctl.bash` only when the
configured path is missing or is not executable, verifies the published SHA-256
digest before replacing the destination, and defines `adr` as an alias for the
installed artifact.

```bash
adrctl_setup() {
  local adr_path="${adr_path:-${HOME}/.local/bin/adrctl.bash}"
  local adr_url="${adr_url:-https://github.com/wesley-dean/adrctl/releases/latest/download/adrctl.bash}"
  local checksum_url="${adr_url}.sha256"
  local tmp_path
  local checksum_path
  local expected
  local actual

  if [[ ! -x "${adr_path}" ]]; then
    mkdir -p "${adr_path%/*}" || return 1

    if ! tmp_path="$(mktemp "${adr_path}.tmp.XXXXXX")"; then
      return 1
    fi
    checksum_path="${tmp_path}.sha256"

    if ! curl -fsSL "${adr_url}" -o "${tmp_path}" ||
      ! curl -fsSL "${checksum_url}" -o "${checksum_path}"; then
      rm -f "${tmp_path}" "${checksum_path}"
      return 1
    fi

    if ! read -r expected _ <"${checksum_path}" ||
      [[ ! "${expected}" =~ ^[[:xdigit:]]{64}$ ]]; then
      printf '%s\n' 'adrctl release checksum is invalid' >&2
      rm -f "${tmp_path}" "${checksum_path}"
      return 1
    fi

    if command -v sha256sum >/dev/null 2>&1; then
      actual="$(sha256sum "${tmp_path}" | awk '{ print $1 }')"
    elif command -v shasum >/dev/null 2>&1; then
      actual="$(shasum -a 256 "${tmp_path}" | awk '{ print $1 }')"
    else
      printf '%s\n' 'adrctl setup requires sha256sum or shasum' >&2
      rm -f "${tmp_path}" "${checksum_path}"
      return 1
    fi

    if [[ "${actual}" != "${expected}" ]]; then
      printf '%s\n' 'adrctl checksum verification failed' >&2
      rm -f "${tmp_path}" "${checksum_path}"
      return 1
    fi

    rm -f "${checksum_path}"
    if ! chmod 0755 "${tmp_path}" || ! mv "${tmp_path}" "${adr_path}"; then
      rm -f "${tmp_path}"
      return 1
    fi
  fi

  printf '%s\n' "${adr_path}"
}

if adr_path="$(adrctl_setup)"; then
  # shellcheck disable=SC2139
  alias adr="${adr_path}"
fi
```

Set `adr_path` or `adr_url` before this block to override the default installation
path or release URL.  The helper intentionally does not replace an already
executable installation on every shell startup; remove or replace that file when
you deliberately want to acquire a newer release.

Direct execution of `dist/adrctl.bash` is supported and presents the canonical
`adrctl` product identity in help and diagnostics.

`adrctl` remains the canonical product identity.  The `adrctl.bash` name
identifies the generated distribution executable, while `adr` is a supported
compatibility invocation alias rather than a separate executable implementation.

## Commands

The initial public command surface, when invoking the distributed executable
directly, is:

```text
adrctl.bash init [DIRECTORY]
adrctl.bash new [-s REFERENCE]... [-l TARGET:LINK:REVERSE-LINK]... [OPTIONS] TITLE...
adrctl.bash link SOURCE LINK TARGET REVERSE-LINK
adrctl.bash list
adrctl.bash generate [toc|graph] [OPTIONS]
adrctl.bash upgrade-repository
adrctl.bash help [COMMAND [SUBCOMMAND...]]
adrctl.bash --version
```

The same commands work with `adr` substituted for `adrctl.bash` when using the
supported symbolic link or Bash alias.

### Initialize a repository

From the directory that should own the ADR project:

```bash
adrctl.bash init
```

The default ADR directory is `doc/adr`.

To use another directory while retaining the legacy compatibility marker:

```bash
adrctl.bash init decisions
```

This creates `.adr-dir` containing `decisions` and creates the first ADR without
opening an editor.

### Create an ADR

```bash
adrctl.bash new "Use PostgreSQL"
```

By default, ADR filenames preserve the established four-digit numbering pattern:

```text
0001-use-postgresql.md
```

The created pathname is written to standard output so the command remains useful
in shell automation.

Existing ADRs may be superseded:

```bash
adrctl.bash new -s 12 "Replace the original caching strategy"
```

Arbitrary reciprocal relationships use the inherited three-field form:

```bash
adrctl.bash new \
  -l '12:Depends on:Required by' \
  "Introduce a shared cache"
```

### Link existing ADRs

```bash
adrctl.bash link 12 'Depends on' 18 'Required by'
```

Both references are resolved before either document is replaced.  Ambiguous
partial references fail rather than selecting an arbitrary first match.

### Generate reports

Generate a Markdown table of contents:

```bash
adrctl.bash generate toc
```

Generate Graphviz DOT source:

```bash
adrctl.bash generate graph
```

`adrctl` does not invoke Graphviz automatically.  DOT output can be piped to a
renderer separately when desired.

## Project Discovery

For commands that operate on an existing project, `adrctl` selects the project
root in this order:

1. `--project-root PATH`
2. process-environment `ADRCTL_PROJECT_ROOT`
3. nearest recognized ancestor marker
4. Git work-tree root
5. current working directory

Recognized ancestor markers are:

- `.adr-dir`
- an existing `doc/adr` directory
- `.env` containing an `ADRCTL_` assignment

An unrelated application `.env` does not establish `adrctl` context.  A
namespaced but invalid `ADRCTL_` assignment does establish context and then fails
validation so configuration mistakes cannot be silently skipped.

`init` is intentionally different: without an explicit root override, it uses
the current working directory instead of climbing to a Git ancestor.

## Configuration

Project configuration lives in `.env` at the resolved project root and is parsed
as data.  It is never sourced or evaluated as shell code.

Initial project keys are:

```text
ADRCTL_ADR_DIR
ADRCTL_TEMPLATE
ADRCTL_FILENAME_PATTERN
ADRCTL_TEMPLATE_START_DELIMITER
ADRCTL_TEMPLATE_END_DELIMITER
```

`ADRCTL_PROJECT_ROOT` is a process-environment or command-line concern and is not
valid inside project `.env` configuration.

General precedence for project-scoped settings is:

```text
command line
process environment
project .env
compatible legacy metadata
built-in default
```

Relative configured paths resolve against the project root.

## Templates

Existing `adr-tools` body templates using bare tokens such as:

```text
NUMBER
TITLE
DATE
STATUS
```

remain supported.

Modern templates may use braced tokens such as:

```text
{NUMBER}
{TITLE}
{DATE}
{STATUS}
```

When no explicit body-template delimiter pair is configured, `adrctl` looks for
a recognized braced token whose key exists in the prepared render context.  If
one exists, `{` and `}` are selected.  Otherwise, empty delimiters select legacy
bare-token rendering.

Custom body delimiters are available with:

```text
--start-delimiter STRING
--end-delimiter STRING
```

Both options are supplied as a pair.  Two empty strings explicitly select legacy
bare-token body rendering.

Filename patterns are a separate rendering surface and retain the stable braced
`{KEY}` grammar.  The default is:

```text
{NUMBER4}-{TITLE_SLUG}.md
```

## Safety and Compatibility

`adrctl` preserves successful predecessor workflows where practical while
intentionally refusing several unsafe or accidental legacy behaviors.

In particular:

- configuration is parsed as data instead of evaluated as shell code;
- ambiguous ADR references fail instead of selecting the first match;
- multi-file operations preflight the complete intended change before writing;
- existing files use atomic per-file replacement where practical;
- newly allocated filenames are not overwritten if another process claims them;
- external `adr-*` or `adrctl-*` plugin discovery is not supported initially;
- Git state is not staged or committed automatically; and
- diagnostics are kept off script-facing standard output.

The project does not promise true cross-file filesystem transactions or guaranteed
multi-process sequential number allocation.

## Development

The canonical contributor workflow is documented in `AGENTS.md`.

Useful Make targets include:

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
make clean
make distclean
```

`make all` is the fresh-checkout convenience path: synchronize approved
dependencies and then build.  `make build` assumes dependency state has already
been prepared.  `make deps-check` provides the corresponding network-free
integrity check.

`make docs` synchronizes the manifest-managed Bash Doxygen filter before
regenerating `doc/reference/`; the generated reference tree remains ignored by
Git.

The behavior suite exercises the generated artifact rather than assuming that
valid individual source modules imply a valid assembled executable.  CI also runs
a consumer harness under Bash 4.3.

## Documentation

Project documentation is deliberately split by responsibility:

- `README.md` - human-facing product orientation and use
- `AGENTS.md` - contributor and coding-agent guidance
- `doc/adr/` - architecture decisions and rationale
- `doc/adrctl-spec.md` - normative behavioral specification
- `doc/reference/` - generated source-reference documentation, ignored by Git and
  published through GitHub Pages
- source comments - implementation contracts and invariants

The initial architecture and compatibility analysis is also retained under
`doc/` for provenance and future maintenance.

## Release Model

Releases use Semantic Versioning and publish one canonical `adrctl.bash`
distribution artifact.  The product identity remains `adrctl`; README command
examples use the released `adrctl.bash` filename unless demonstrating the
supported `adr` compatibility invocation.

Release validation synchronizes and verifies the committed dependency manifest
before building and testing the exact artifact, generates a SHA-256 checksum, and
produces GitHub provenance attestation when supported by the release platform.

## License

`adrctl` is dedicated to the public domain under CC0 1.0 Universal.  See
[LICENSE](LICENSE).

The upstream `adr-tools` implementation is GPL-licensed.  `adrctl` production
source is independently authored against documented behavior and compatibility
evidence; upstream implementation code is not copied or mechanically translated
into this repository.

## Contributing

Contributions are welcome.  Review [CONTRIBUTING.md](CONTRIBUTING.md),
[AGENTS.md](AGENTS.md), the relevant ADRs, and the behavioral specification before
making substantial changes.

Please also follow the project [Code of Conduct](CODE_OF_CONDUCT.md).

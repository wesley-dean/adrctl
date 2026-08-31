#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd -P)"
  ADRCTL="${ADRCTL_ARTIFACT:-${REPO_ROOT}/dist/adrctl.bash}"
  WORK="${BATS_TEST_TMPDIR}/graph-project"
  mkdir -p "${WORK}/doc/adr"

  export VISUAL=true
  export ADR_PAGER=cat

  unset ADRCTL_PROJECT_ROOT
  unset ADRCTL_ADR_DIR
  unset ADRCTL_ADR_GLOB
  unset ADRCTL_ADR_NUMBER_REGEX
  unset ADRCTL_TEMPLATE
  unset ADRCTL_FILENAME_PATTERN
  unset ADRCTL_TEMPLATE_START_DELIMITER
  unset ADRCTL_TEMPLATE_END_DELIMITER
  unset ADR_TEMPLATE
  unset ADR_DATE
  unset EDITOR
  unset PAGER
}

run_in() {
  local dir

  dir="$1"
  shift
  (
    cd "${dir}" || exit 1
    "$@"
  )
}

write_adr() {
  local path
  local title
  local status_line

  path="$1"
  title="$2"
  shift 2

  {
    cat <<EOF
# ${title}

Date: 2026-08-30

## Status

Accepted
EOF
    for status_line in "$@"; do
      printf '\n%s\n' "${status_line}"
    done
    cat <<'EOF'

## Context

Context.

## Decision

Decision.

## Consequences

Consequences.
EOF
  } >"${path}"
}

@test "default graph output is identical to explicit dot format" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}" "${ADRCTL}" generate graph -p '/adr/' -e '.md'
  [ "${status}" -eq 0 ]
  default_output="${output}"

  run run_in "${WORK}" "${ADRCTL}" generate graph \
    --format dot -p '/adr/' -e '.md'

  [ "${status}" -eq 0 ]
  [ "${output}" = "${default_output}" ]
  [[ "${output}" == digraph\ \{* ]]
  [[ "${output}" == *'_1 -> _2 [style="dotted", weight=1];'* ]]
}

@test "mermaid format emits raw flowchart source with sequence edges and node links" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}" "${ADRCTL}" generate graph \
    --format mermaid -p '/adr/' -e '.md'

  [ "${status}" -eq 0 ]
  [[ "${output}" == flowchart\ TD* ]]
  [[ "${output}" == *'_1["1. One"]'* ]]
  [[ "${output}" == *'_2["2. Two"]'* ]]
  [[ "${output}" == *'_1 -.-> _2'* ]]
  [[ "${output}" == *'click _1 "/adr/0001-one.md"'* ]]
  [[ "${output}" != *'```'* ]]
}

@test "dot and mermaid serializers use the same prefixed relationship semantics" {
  write_adr "${WORK}/doc/adr/ADR-0001-one.md" '1. One' \
    'Depends on [2. Two](ADR-0002-two.md)'
  write_adr "${WORK}/doc/adr/ADR-0002-two.md" '2. Two' \
    'Required by [1. One](ADR-0001-one.md)'

  run run_in "${WORK}" "${ADRCTL}" generate graph --format dot
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_1 -> _2 [label="Depends on", weight=0];'* ]]
  [[ "${output}" != *'Required by'* ]]

  run run_in "${WORK}" "${ADRCTL}" generate graph --format mermaid
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_1 -->|"Depends on"| _2'* ]]
  [[ "${output}" != *'Required by'* ]]
}

@test "custom logical-number regex is shared by both graph serializers" {
  cat >"${WORK}/.env" <<'EOF'
ADRCTL_ADR_GLOB=decision-*.md
ADRCTL_ADR_NUMBER_REGEX=^decision-[0-9]{4}-([0-9]+)-.+\.md$
EOF
  write_adr "${WORK}/doc/adr/decision-2026-0042-one.md" '42. One' \
    'Depends on [43. Two](decision-2026-0043-two.md)'
  write_adr "${WORK}/doc/adr/decision-2026-0043-two.md" '43. Two'

  run run_in "${WORK}" "${ADRCTL}" generate graph --format dot
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_42 -> _43 [style="dotted", weight=1];'* ]]
  [[ "${output}" == *'_42 -> _43 [label="Depends on", weight=0];'* ]]

  run run_in "${WORK}" "${ADRCTL}" generate graph --format mermaid
  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_42 -.-> _43'* ]]
  [[ "${output}" == *'_42 -->|"Depends on"| _43'* ]]
}

@test "mermaid escapes quoted node and relationship labels" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. Use "quoted" APIs & contracts' \
    'Depends on "quoted" & stable [2. Two](0002-two.md)'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}" "${ADRCTL}" generate graph --format mermaid

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_1["1. Use &quot;quoted&quot; APIs &amp; contracts"]'* ]]
  [[ "${output}" == *'|"Depends on &quot;quoted&quot; &amp; stable"|'* ]]
}

@test "graph format validation rejects missing repeated and unsupported values" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" "${ADRCTL}" generate graph --format
  [ "${status}" -eq 2 ]
  [[ "${output}" == *'--format expects FORMAT'* ]]

  run run_in "${WORK}" "${ADRCTL}" generate graph \
    --format dot --format mermaid
  [ "${status}" -eq 2 ]
  [[ "${output}" == *'accepts --format at most once'* ]]

  run run_in "${WORK}" "${ADRCTL}" generate graph --format svg
  [ "${status}" -eq 2 ]
  [[ "${output}" == *'unsupported graph format: svg'* ]]
}

@test "textual graph serialization does not require graphviz or mermaid executables" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" env PATH='/usr/bin:/bin' \
    "${ADRCTL}" generate graph --format dot
  [ "${status}" -eq 0 ]
  [[ "${output}" == digraph\ \{* ]]

  run run_in "${WORK}" env PATH='/usr/bin:/bin' \
    "${ADRCTL}" generate graph --format mermaid
  [ "${status}" -eq 0 ]
  [[ "${output}" == flowchart\ TD* ]]
}

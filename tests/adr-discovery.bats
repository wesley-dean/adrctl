#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd -P)"
  ADRCTL="${ADRCTL_ARTIFACT:-${REPO_ROOT}/dist/adrctl.bash}"
  WORK="${BATS_TEST_TMPDIR}/discovery-project"
  mkdir -p "${WORK}"

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

  path="$1"
  title="$2"

  mkdir -p "$(dirname "${path}")"
  cat >"${path}" <<EOF
# ${title}

Date: 2026-08-19

## Status

Accepted

## Context

Context.

## Decision

Decision.

## Consequences

Consequences.
EOF
}

@test "default discovery recognizes standard and common prefixed ADR names" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/ADR-0002-two.md" '2. Two'
  write_adr "${WORK}/doc/adr/decision-0003-three.md" '3. Three'
  printf '%s\n' 'not an ADR' >"${WORK}/doc/adr/README.md"

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = $'doc/adr/0001-one.md\ndoc/adr/ADR-0002-two.md\ndoc/adr/decision-0003-three.md' ]
}

@test "transient prefixed filename creation remains discoverable and advances numbering" {
  run run_in "${WORK}" "${ADRCTL}" new \
    --filename-pattern 'ADR-{NUMBER4}-{TITLE_SLUG}.md' \
    'Custom Filename'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/ADR-0001-custom-filename.md' ]

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/ADR-0001-custom-filename.md' ]

  run run_in "${WORK}" "${ADRCTL}" new 'Second Decision'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/0002-second-decision.md' ]
}

@test "numeric references and reciprocal links work with prefixed ADR basenames" {
  write_adr "${WORK}/doc/adr/ADR-0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/ADR-0002-two.md" '2. Two'

  run run_in "${WORK}" "${ADRCTL}" link 1 'Depends on' 2 'Required by'

  [ "${status}" -eq 0 ]
  grep -q '^Depends on \[2\. Two\](ADR-0002-two.md)$' \
    "${WORK}/doc/adr/ADR-0001-one.md"
  grep -q '^Required by \[1\. One\](ADR-0001-one.md)$' \
    "${WORK}/doc/adr/ADR-0002-two.md"
}

@test "TOC and graph include prefixed ADRs in logical numeric order" {
  write_adr "${WORK}/doc/adr/ADR-0002-two.md" '2. Two'
  write_adr "${WORK}/doc/adr/ADR-0001-one.md" '1. One'

  run run_in "${WORK}" "${ADRCTL}" generate toc

  [ "${status}" -eq 0 ]
  [[ "${output}" == *$'* [1. One](ADR-0001-one.md)\n* [2. Two](ADR-0002-two.md)'* ]]

  run run_in "${WORK}" "${ADRCTL}" generate graph

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_1 [label="1. One"; URL="ADR-0001-one.html"]'* ]]
  [[ "${output}" == *'_2 [label="2. Two"; URL="ADR-0002-two.html"]'* ]]
  [[ "${output}" == *'_1 -> _2 [style="dotted", weight=1]'* ]]
}

@test "ADRCTL_ADR_GLOB narrows candidate selection without changing number extraction" {
  write_adr "${WORK}/doc/adr/ADR-0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}" env ADRCTL_ADR_GLOB='ADR-*.md' "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/ADR-0001-one.md' ]
}

@test "ordinary discovery silently ignores candidates rejected by the number regex" {
  write_adr "${WORK}/doc/adr/ADR-0001-one.md" '1. One'
  printf '%s\n' 'not an ADR' >"${WORK}/doc/adr/ADR-not-an-adr.md"

  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR-([0-9]+)-.+\.md$' \
    "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/ADR-0001-one.md' ]
}

@test "project discovery settings work and process environment overrides both" {
  cat >"${WORK}/.env" <<'EOF'
ADRCTL_ADR_GLOB=ADR_*.md
ADRCTL_ADR_NUMBER_REGEX=^ADR_([0-9]+)_.+\.md$
EOF
  write_adr "${WORK}/doc/adr/ADR_0042_one.md" '42. One'
  write_adr "${WORK}/doc/adr/decision-0007-two.md" '7. Two'

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/ADR_0042_one.md' ]

  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='decision-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^decision-([0-9]+)-.+\.md$' \
    "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/decision-0007-two.md' ]
}

@test "custom number regex can capture a logical number after another numeric field" {
  cat >"${WORK}/.env" <<'EOF'
ADRCTL_ADR_GLOB=decision-*.md
ADRCTL_ADR_NUMBER_REGEX=^decision-[0-9]{4}-([0-9]+)-.+\.md$
ADRCTL_FILENAME_PATTERN=decision-2026-{NUMBER4}-{TITLE_SLUG}.md
EOF
  write_adr "${WORK}/doc/adr/decision-2026-0042-existing.md" '42. Existing'

  run run_in "${WORK}" "${ADRCTL}" new 'Next Decision'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/decision-2026-0043-next-decision.md' ]
}

@test "leading-zero captures normalize explicitly as decimal logical numbers" {
  write_adr "${WORK}/doc/adr/ADR-0122-existing.md" '122. Existing'

  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR-([0-9]+)-.+\.md$' \
    ADRCTL_FILENAME_PATTERN='ADR-{NUMBER4}-{TITLE_SLUG}.md' \
    "${ADRCTL}" new 'Example'

  [ "${status}" -eq 0 ]
  [ "${output}" = 'doc/adr/ADR-0123-example.md' ]
  [ -f "${WORK}/doc/adr/ADR-0123-example.md" ]
}

@test "unrelated candidates are ignored and duplicate logical numbers use basename tie-break" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/ADR-0002-zeta.md" '2. Zeta'
  write_adr "${WORK}/doc/adr/decision-0002-alpha.md" '2. Alpha'
  printf '%s\n' 'not an ADR' >"${WORK}/doc/adr/README.md"

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = $'doc/adr/0001-one.md\ndoc/adr/ADR-0002-zeta.md\ndoc/adr/decision-0002-alpha.md' ]
}

@test "invalid ADR number regex fails configuration validation" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" env ADRCTL_ADR_NUMBER_REGEX='[' "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'ADRCTL_ADR_NUMBER_REGEX is not a valid Bash ERE'* ]]
}

@test "empty or path-scoped ADR candidate globs fail configuration validation" {
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" env ADRCTL_ADR_GLOB= "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'ADRCTL_ADR_GLOB must not be empty'* ]]

  run run_in "${WORK}" env ADRCTL_ADR_GLOB='ADR/*.md' "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'ADRCTL_ADR_GLOB must match one basename'* ]]
}

@test "matching regex without decimal capture group 1 fails safely" {
  write_adr "${WORK}/doc/adr/ADR-0001-one.md" '1. One'

  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR-[0-9]+-.+\.md$' \
    "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'without decimal capture group 1'* ]]
  [[ "${output}" == *"ADRCTL_ADR_NUMBER_REGEX='^ADR-[0-9]+-.+\\.md$'"* ]]

  write_adr "${WORK}/doc/adr/ADR-foo-two.md" '2. Two'

  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR-([^-]+)-.+\.md$' \
    "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'without decimal capture group 1'* ]]
}

@test "creation identifies a missing decimal capture group contract" {
  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR-[0-9]+-.+\.md$' \
    "${ADRCTL}" new \
    --filename-pattern 'ADR-{NUMBER4}-{TITLE_SLUG}.md' \
    'Missing Capture'

  [ "${status}" -eq 2 ]
  [[ "${output}" == *"ADRCTL_ADR_NUMBER_REGEX='^ADR-[0-9]+-.+\\.md$'"* ]]
  [[ "${output}" == *"basename 'ADR-0001-missing-capture.md'"* ]]
  [[ "${output}" == *'without decimal capture group 1'* ]]
  [ ! -d "${WORK}/doc/adr" ]
}

@test "malicious-looking discovery values remain inert data" {
  local marker

  marker="${WORK}/SHOULD_NOT_EXIST"
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='$(touch SHOULD_NOT_EXIST)*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^[$][(]touch[)]([0-9]+)-.+\.md$' \
    "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
  [ ! -e "${marker}" ]
}

@test "creation fails before mutation when rendered filename misses candidate glob" {
  printf '%s\n' 'ADRCTL_ADR_GLOB=ADR-*.md' >"${WORK}/.env"

  run run_in "${WORK}" "${ADRCTL}" new 'Invisible Decision'

  [ "${status}" -eq 2 ]
  [[ "${output}" == *"rendered ADR filename '0001-invisible-decision.md'"* ]]
  [[ "${output}" == *"ADRCTL_ADR_GLOB='ADR-*.md'"* ]]
  [ ! -d "${WORK}/doc/adr" ]
}

@test "creation fails before mutation when rendered filename misses number regex" {
  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR_([0-9]+)_.+\.md$' \
    "${ADRCTL}" new \
    --filename-pattern 'ADR-{NUMBER4}-{TITLE_SLUG}.md' \
    'Regex Mismatch'

  [ "${status}" -eq 2 ]
  [[ "${output}" == *"rendered ADR filename 'ADR-0001-regex-mismatch.md'"* ]]
  [[ "${output}" == *"ADRCTL_ADR_NUMBER_REGEX='^ADR_([0-9]+)_.+\\.md$'"* ]]
  [ ! -d "${WORK}/doc/adr" ]
}

@test "creation fails before mutation when regex captures a different logical number" {
  run run_in "${WORK}" env \
    ADRCTL_ADR_GLOB='ADR-*.md' \
    ADRCTL_ADR_NUMBER_REGEX='^ADR-([0-9]+)-[0-9]+-.+\.md$' \
    "${ADRCTL}" new \
    --filename-pattern 'ADR-9999-{NUMBER4}-{TITLE_SLUG}.md' \
    'Wrong Number'

  [ "${status}" -eq 2 ]
  [[ "${output}" == *"rendered ADR filename 'ADR-9999-0001-wrong-number.md'"* ]]
  [[ "${output}" == *'captures logical number 9999'* ]]
  [[ "${output}" == *"ADRCTL_ADR_NUMBER_REGEX='^ADR-([0-9]+)-[0-9]+-.+\\.md$'"* ]]
  [[ "${output}" == *'expected 1'* ]]
  [ ! -d "${WORK}/doc/adr" ]
}

@test "init also enforces filename rediscoverability before creating files" {
  printf '%s\n' 'ADRCTL_ADR_GLOB=ADR-*.md' >"${WORK}/.env"

  run run_in "${WORK}" "${ADRCTL}" init

  [ "${status}" -eq 2 ]
  [[ "${output}" == *"ADRCTL_ADR_GLOB='ADR-*.md'"* ]]
  [ ! -d "${WORK}/doc/adr" ]
}

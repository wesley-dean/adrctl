#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd -P)"
  ADRCTL="${REPO_ROOT}/dist/adrctl"
  WORK="${BATS_TEST_TMPDIR}/project"
  mkdir -p "${WORK}"

  export VISUAL=true
  export ADR_PAGER=cat

  unset ADRCTL_PROJECT_ROOT
  unset ADRCTL_ADR_DIR
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
  local date

  path="$1"
  title="$2"
  date="${3:-2026-08-15}"

  mkdir -p "$(dirname "${path}")"
  cat >"${path}" <<EOF
# ${title}

Date: ${date}

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

@test "generated artifact reports canonical adrctl identity" {
  run "${ADRCTL}" --version

  [ "${status}" -eq 0 ]
  [[ "${output}" == adrctl\ * ]]
  [[ "${output}" == *$'\nbuild_date='* ]]
  [[ "${output}" == *$'\ncommit='* ]]
}

@test "adr symlink invokes the same generated artifact" {
  ln -s "${ADRCTL}" "${WORK}/adr"

  run "${WORK}/adr" --version

  [ "${status}" -eq 0 ]
  [[ "${output}" == adrctl\ * ]]
}

@test "help presentation follows the invoked basename" {
  ln -s "${ADRCTL}" "${WORK}/adr"

  run env ADR_PAGER=cat "${WORK}/adr" help

  [ "${status}" -eq 0 ]
  [[ "${output}" == Usage:\ adr\ * ]]
}

@test "ADR_PAGER takes precedence over a failing PAGER" {
  run env ADR_PAGER=cat PAGER=false "${ADRCTL}" help

  [ "${status}" -eq 0 ]
  [[ "${output}" == Usage:\ adrctl\ * ]]
}

@test "init creates the compatible first ADR in doc/adr" {
  run run_in "${WORK}" "${ADRCTL}" init

  [ "${status}" -eq 0 ]
  [ "${output}" = "doc/adr/0001-record-architecture-decisions.md" ]
  [ -f "${WORK}/doc/adr/0001-record-architecture-decisions.md" ]
  grep -q '^# 1\. Record architecture decisions$' \
    "${WORK}/doc/adr/0001-record-architecture-decisions.md"
  grep -q '^Accepted$' "${WORK}/doc/adr/0001-record-architecture-decisions.md"
  [ ! -e "${WORK}/.adr-dir" ]
}

@test "init with a custom directory writes the legacy marker" {
  run run_in "${WORK}" "${ADRCTL}" init decisions

  [ "${status}" -eq 0 ]
  [ "${output}" = "decisions/0001-record-architecture-decisions.md" ]
  [ "$(cat "${WORK}/.adr-dir")" = "decisions" ]
  [ -f "${WORK}/decisions/0001-record-architecture-decisions.md" ]
}

@test "legacy bare-token project template renders automatically" {
  mkdir -p "${WORK}/doc/adr/templates"
  cat >"${WORK}/doc/adr/templates/template.md" <<'EOF'
# NUMBER. TITLE

Date: DATE

## Status

STATUS

## Context

Legacy template.
EOF

  run run_in "${WORK}" "${ADRCTL}" new "Use PostgreSQL"

  [ "${status}" -eq 0 ]
  [ "${output}" = "doc/adr/0001-use-postgresql.md" ]
  grep -q '^# 1\. Use PostgreSQL$' "${WORK}/${output}"
  grep -q '^Accepted$' "${WORK}/${output}"
  ! grep -q 'NUMBER\|TITLE\|STATUS' "${WORK}/${output}"
}

@test "legacy ADR_TEMPLATE environment override remains supported" {
  cat >"${WORK}/legacy-template.md" <<'EOF'
# NUMBER. TITLE

Date: DATE

## Status

STATUS

## Context

Selected by ADR_TEMPLATE.
EOF

  run run_in "${WORK}" env ADR_TEMPLATE=legacy-template.md \
    "${ADRCTL}" new "Legacy Environment Template"

  [ "${status}" -eq 0 ]
  grep -q 'Selected by ADR_TEMPLATE\.' "${WORK}/${output}"
}

@test "recognized braced template tokens select braced rendering" {
  cat >"${WORK}/braced.md" <<'EOF'
# {NUMBER}. {TITLE}

Date: {DATE}

## Status

{STATUS}
EOF

  run run_in "${WORK}" "${ADRCTL}" new --template braced.md "Braced Template"

  [ "${status}" -eq 0 ]
  grep -q '^# 1\. Braced Template$' "${WORK}/${output}"
  grep -q '^Accepted$' "${WORK}/${output}"
}

@test "unrelated brace text does not force braced mode" {
  cat >"${WORK}/mixed.md" <<'EOF'
# NUMBER. TITLE

Date: DATE

## Status

STATUS

## Context

Literal example: {foo}
EOF

  run run_in "${WORK}" "${ADRCTL}" new --template mixed.md "Bare Wins"

  [ "${status}" -eq 0 ]
  grep -q '^# 1\. Bare Wins$' "${WORK}/${output}"
  grep -q 'Literal example: {foo}' "${WORK}/${output}"
}

@test "explicit custom body delimiters are passed to mktext" {
  cat >"${WORK}/custom.md" <<'EOF'
# <<NUMBER>>. <<TITLE>>

Date: <<DATE>>

## Status

<<STATUS>>
EOF

  run run_in "${WORK}" "${ADRCTL}" new \
    --template custom.md \
    --start-delimiter '<<' \
    --end-delimiter '>>' \
    "Custom Delimiters"

  [ "${status}" -eq 0 ]
  [ "${output}" = "doc/adr/0001-custom-delimiters.md" ]
  grep -q '^# 1\. Custom Delimiters$' "${WORK}/${output}"
}

@test "empty body delimiters do not change braced filename rendering" {
  run run_in "${WORK}" "${ADRCTL}" new \
    --start-delimiter '' \
    --end-delimiter '' \
    "Empty Delimiters"

  [ "${status}" -eq 0 ]
  [ "${output}" = "doc/adr/0001-empty-delimiters.md" ]
  [ -f "${WORK}/${output}" ]
}

@test "one-sided delimiter configuration fails before creating an ADR" {
  run run_in "${WORK}" "${ADRCTL}" new --start-delimiter '{' "Invalid Pair"

  [ "${status}" -eq 2 ]
  [ ! -d "${WORK}/doc/adr" ]
}

@test "custom filename pattern uses the stable braced filename grammar" {
  run run_in "${WORK}" "${ADRCTL}" new \
    --filename-pattern 'ADR-{NUMBER4}-{TITLE_SLUG}.md' \
    "Custom Filename"

  [ "${status}" -eq 0 ]
  [ "${output}" = "doc/adr/ADR-0001-custom-filename.md" ]
  [ -f "${WORK}/${output}" ]
}

@test "ADR_DATE overrides the generated date" {
  run run_in "${WORK}" env ADR_DATE=2001-02-03 \
    "${ADRCTL}" new "Pinned Date"

  [ "${status}" -eq 0 ]
  grep -q '^Date: 2001-02-03$' "${WORK}/${output}"
}

@test "qualifying parent env config establishes project context from nested directory" {
  mkdir -p "${WORK}/nested/deeper" "${WORK}/decisions"
  printf '%s\n' 'ADRCTL_ADR_DIR=decisions' >"${WORK}/.env"
  write_adr "${WORK}/decisions/0001-one.md" '1. One'

  run run_in "${WORK}/nested/deeper" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = "../../decisions/0001-one.md" ]
}

@test "legacy adr-dir marker is discovered from nested directories" {
  mkdir -p "${WORK}/nested/deeper" "${WORK}/decisions"
  printf '%s\n' 'decisions' >"${WORK}/.adr-dir"
  write_adr "${WORK}/decisions/0001-one.md" '1. One'

  run run_in "${WORK}/nested/deeper" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = "../../decisions/0001-one.md" ]
}

@test "unrelated nearer env file does not shadow an outer ADR project" {
  mkdir -p "${WORK}/doc/adr" "${WORK}/nested/deeper"
  printf '%s\n' 'APP_MODE=test' >"${WORK}/nested/.env"
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}/nested/deeper" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = "../../doc/adr/0001-one.md" ]
}

@test "unknown ADRCTL project key fails configuration validation" {
  printf '%s\n' 'ADRCTL_NOT_A_SETTING=value' >"${WORK}/.env"

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'unknown project configuration key'* ]]
}

@test "nearer invalid ADRCTL env marks context and fails instead of falling through" {
  mkdir -p "${WORK}/doc/adr" "${WORK}/nested/deeper"
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  printf '%s\n' 'ADRCTL_MISSPELLED=value' >"${WORK}/nested/.env"

  run run_in "${WORK}/nested/deeper" "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'ADRCTL_MISSPELLED'* ]]
}

@test "project env cannot redirect its own project root" {
  printf '%s\n' 'ADRCTL_PROJECT_ROOT=/tmp' >"${WORK}/.env"

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'ADRCTL_PROJECT_ROOT is environment/CLI only'* ]]
}

@test "project config accepts export and quoted values" {
  mkdir -p "${WORK}/decisions"
  printf '%s\n' 'export ADRCTL_ADR_DIR = "decisions"' >"${WORK}/.env"
  write_adr "${WORK}/decisions/0001-one.md" '1. One'

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = "decisions/0001-one.md" ]
}

@test "process environment ADR directory overrides project config" {
  mkdir -p "${WORK}/configured" "${WORK}/environment"
  printf '%s\n' 'ADRCTL_ADR_DIR=configured' >"${WORK}/.env"
  write_adr "${WORK}/configured/0001-configured.md" '1. Configured'
  write_adr "${WORK}/environment/0002-environment.md" '2. Environment'

  run run_in "${WORK}" env ADRCTL_ADR_DIR=environment "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = "environment/0002-environment.md" ]
}

@test "explicit project root overrides local project discovery" {
  mkdir -p "${WORK}/one/doc/adr" "${WORK}/two/doc/adr" "${WORK}/one/nested"
  write_adr "${WORK}/one/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/two/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}/one/nested" "${ADRCTL}" \
    --project-root "${WORK}/two" list

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'0002-two.md' ]]
  [[ "${output}" != *'0001-one.md' ]]
}

@test "list orders ADRs numerically" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0010-ten.md" '10. Ten'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" "${ADRCTL}" list

  [ "${status}" -eq 0 ]
  [ "${output}" = $'doc/adr/0001-one.md\ndoc/adr/0002-two.md\ndoc/adr/0010-ten.md' ]
}

@test "link adds reciprocal relationships only after both ADRs resolve" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}" "${ADRCTL}" link 1 'Depends on' 2 'Required by'

  [ "${status}" -eq 0 ]
  grep -q '^Depends on \[2\. Two\](0002-two.md)$' "${WORK}/doc/adr/0001-one.md"
  grep -q '^Required by \[1\. One\](0001-one.md)$' "${WORK}/doc/adr/0002-two.md"
}

@test "ambiguous partial ADR reference fails without modifying candidates" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-source.md" '1. Source'
  write_adr "${WORK}/doc/adr/0002-alpha-one.md" '2. Alpha One'
  write_adr "${WORK}/doc/adr/0003-alpha-two.md" '3. Alpha Two'
  before="$(cat "${WORK}/doc/adr/0001-source.md")"

  run run_in "${WORK}" "${ADRCTL}" link 1 'Depends on' alpha 'Required by'

  [ "${status}" -eq 1 ]
  [[ "${output}" == *'ambiguous ADR reference: alpha'* ]]
  [ "$(cat "${WORK}/doc/adr/0001-source.md")" = "${before}" ]
}

@test "new -s creates reciprocal supersede relationships and removes Accepted from target" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-old.md" '1. Old Decision'

  run run_in "${WORK}" "${ADRCTL}" new -s 1 "Replacement"

  [ "${status}" -eq 0 ]
  [ "${output}" = "doc/adr/0002-replacement.md" ]
  grep -q '^Supercedes \[1\. Old Decision\](0001-old.md)$' "${WORK}/${output}"
  grep -q '^Superceded by \[Replacement\](0002-replacement.md)$' \
    "${WORK}/doc/adr/0001-old.md"
  ! grep -q '^Accepted$' "${WORK}/doc/adr/0001-old.md"
}

@test "new -l creates reciprocal arbitrary relationships" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-existing.md" '1. Existing'

  run run_in "${WORK}" "${ADRCTL}" new \
    -l '1:Depends on:Required by' \
    "New Relationship"

  [ "${status}" -eq 0 ]
  grep -q '^Depends on \[1\. Existing\](0001-existing.md)$' "${WORK}/${output}"
  grep -q '^Required by \[New Relationship\](0002-new-relationship.md)$' \
    "${WORK}/doc/adr/0001-existing.md"
}

@test "repeated new -l relationships to one target are aggregated before replacement" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-existing.md" '1. Existing'

  run run_in "${WORK}" "${ADRCTL}" new \
    -l '1:Depends on:Required by' \
    -l '1:Extends:Extended by' \
    "Multiple Relationships"

  [ "${status}" -eq 0 ]
  grep -q '^Required by \[Multiple Relationships\](0002-multiple-relationships.md)$' \
    "${WORK}/doc/adr/0001-existing.md"
  grep -q '^Extended by \[Multiple Relationships\](0002-multiple-relationships.md)$' \
    "${WORK}/doc/adr/0001-existing.md"
}

@test "VISUAL takes precedence over a failing EDITOR" {
  cat >"${WORK}/visual" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$1" >"${VISUAL_RECORD}"
EOF
  chmod +x "${WORK}/visual"

  run run_in "${WORK}" env \
    VISUAL="${WORK}/visual" \
    VISUAL_RECORD="${WORK}/visual-record" \
    EDITOR=false \
    "${ADRCTL}" new "Editor Precedence"

  [ "${status}" -eq 0 ]
  [ -f "${WORK}/visual-record" ]
  [[ "$(cat "${WORK}/visual-record")" == *'0001-editor-precedence.md' ]]
}

@test "generate without a report lists built-in reports deterministically" {
  run run_in "${WORK}" "${ADRCTL}" generate

  [ "${status}" -eq 0 ]
  [ "${output}" = $'toc\ngraph' ]
}

@test "generate toc emits Markdown links in ADR order" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'

  run run_in "${WORK}" "${ADRCTL}" generate toc -p '/adr/'

  [ "${status}" -eq 0 ]
  [[ "${output}" == '# Architecture Decision Records'* ]]
  [[ "${output}" == *'* [1. One](/adr/0001-one.md)'* ]]
  [[ "${output}" == *'* [2. Two](/adr/0002-two.md)'* ]]
}

@test "generate graph emits DOT without requiring Graphviz" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'

  run run_in "${WORK}" env PATH='/usr/bin:/bin' "${ADRCTL}" generate graph

  [ "${status}" -eq 0 ]
  [[ "${output}" == digraph\ \{* ]]
  [[ "${output}" == *'_1 -> _2 [style="dotted", weight=1];'* ]]
}

@test "generate graph emits relationship edges and honors URL options" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-one.md" '1. One'
  write_adr "${WORK}/doc/adr/0002-two.md" '2. Two'
  run run_in "${WORK}" "${ADRCTL}" link 1 'Depends on' 2 'Required by'
  [ "${status}" -eq 0 ]

  run run_in "${WORK}" "${ADRCTL}" generate graph -p '/adr/' -e '.md'

  [ "${status}" -eq 0 ]
  [[ "${output}" == *'_1 -> _2 [label="Depends on", weight=0];'* ]]
  [[ "${output}" == *'URL="/adr/0001-one.md"'* ]]
}

@test "upgrade-repository converts only recognized legacy Date lines" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-old-date.md" '1. Old Date' '15/08/2026'

  run run_in "${WORK}" "${ADRCTL}" upgrade-repository

  [ "${status}" -eq 0 ]
  grep -q '^Date: 2026-08-15$' "${WORK}/doc/adr/0001-old-date.md"
}

@test "upgrade-repository is idempotent after conversion" {
  mkdir -p "${WORK}/doc/adr"
  write_adr "${WORK}/doc/adr/0001-old-date.md" '1. Old Date' '15/08/2026'
  run run_in "${WORK}" "${ADRCTL}" upgrade-repository
  [ "${status}" -eq 0 ]
  first="$(cat "${WORK}/doc/adr/0001-old-date.md")"

  run run_in "${WORK}" "${ADRCTL}" upgrade-repository

  [ "${status}" -eq 0 ]
  [ "$(cat "${WORK}/doc/adr/0001-old-date.md")" = "${first}" ]
}

@test "external adr command executables are not discovered as plugins" {
  mkdir -p "${WORK}/bin"
  cat >"${WORK}/bin/adr-foo" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' plugin-ran
EOF
  chmod +x "${WORK}/bin/adr-foo"

  run env PATH="${WORK}/bin:${PATH}" "${ADRCTL}" foo

  [ "${status}" -eq 2 ]
  [[ "${output}" == *'unknown command: foo'* ]]
  [[ "${output}" != *'plugin-ran'* ]]
}

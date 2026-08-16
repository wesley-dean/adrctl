#!/usr/bin/env bats

@test "tilde-based adr alias invokes the generated adrctl.bash artifact" {
  local repo_root
  local artifact
  local alias_home

  repo_root="$(cd "${BATS_TEST_DIRNAME}/.." && pwd -P)"
  artifact="${repo_root}/dist/adrctl.bash"
  alias_home="${BATS_TEST_TMPDIR}/alias-home"

  mkdir -p "${alias_home}/.local/bin"
  ln -s "${artifact}" "${alias_home}/.local/bin/adrctl.bash"

  cat >"${BATS_TEST_TMPDIR}/alias-test.bash" <<'EOF'
shopt -s expand_aliases
alias adr=~/.local/bin/adrctl.bash
adr --version
EOF

  run env HOME="${alias_home}" bash "${BATS_TEST_TMPDIR}/alias-test.bash"

  [ "${status}" -eq 0 ]
  [[ "${output}" == adrctl\ * ]]
}

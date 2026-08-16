#!/usr/bin/env bash

set -eu

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
adrctl="${repo_root}/dist/adrctl.bash"
work="/tmp/adrctl-bash43-$$"

cleanup() {
  rm -rf "${work}"
}
trap cleanup EXIT

mkdir -p "${work}"
export VISUAL=true
export ADR_PAGER=cat

"${adrctl}" --version >/dev/null

ln -s "${adrctl}" "${work}/adrctl"
"${work}/adrctl" --version >/dev/null

ln -s "${adrctl}" "${work}/adr"
"${work}/adr" --version >/dev/null

alias_home="${work}/home"
mkdir -p "${alias_home}/.local/bin"
ln -s "${adrctl}" "${alias_home}/.local/bin/adrctl.bash"
cat >"${work}/alias-test.bash" <<'EOF'
shopt -s expand_aliases
alias adr=~/.local/bin/adrctl.bash
adr --version >/dev/null
EOF
HOME="${alias_home}" bash "${work}/alias-test.bash"

(
  cd "${work}"
  "${adrctl}" init >/dev/null
  "${adrctl}" new 'Bash 4.3 compatibility' >/dev/null
  "${adrctl}" list >list.txt
  grep -q '0001-record-architecture-decisions.md' list.txt
  grep -q '0002-bash-4-3-compatibility.md' list.txt
)

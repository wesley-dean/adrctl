## @file lib/runtime.bash
## @brief Provides shared runtime metadata, diagnostics, and low-level helpers.
##
## @details
## This module contains no product entrypoint.  It is safe to concatenate into
## the generated artifact before the final `adrctl` dispatcher.

## @var __adrctl_version
## @brief Semantic version embedded by the generated artifact.
__adrctl_version="${__adrctl_version:-0.0.0-dev}"

## @var __adrctl_build_date
## @brief Source-revision timestamp embedded by the generated artifact.
__adrctl_build_date="${__adrctl_build_date:-unknown}"

## @var __adrctl_build_commit
## @brief Abbreviated source commit embedded by the generated artifact.
__adrctl_build_commit="${__adrctl_build_commit:-unknown}"

## @var __adrctl_exit_operational
## @brief Public operational/domain failure status.
readonly __adrctl_exit_operational=1

## @var __adrctl_exit_usage
## @brief Public invalid-usage/configuration status.
readonly __adrctl_exit_usage=2

## @fn __adrctl_invoked_name()
## @brief Writes the command name used for human-facing presentation.
## @details Direct execution of any generated distribution flavor is normalized
## to the canonical command identity `adrctl`; an `adr` compatibility symlink
## retains the historical name.
## @retval 0 The presentation name was written.
__adrctl_invoked_name() {
  local invoked

  invoked="${0##*/}"
  case "${invoked}" in
    adrctl.bash | adrctl.dev.bash | adrctl.min.bash)
      printf '%s\n' 'adrctl'
      ;;
    *)
      printf '%s\n' "${invoked}"
      ;;
  esac
}

## @fn __adrctl_print_error()
## @brief Writes one prefixed diagnostic to standard error.
## @param $* Human-readable diagnostic text.
## @retval 0 The diagnostic was written successfully.
## @retval 1 Standard error rejected the write.
__adrctl_print_error() {
  printf '%s: %s\n' "$(__adrctl_invoked_name)" "$*" >&2
}

## @fn __adrctl_fail_operational()
## @brief Writes an operational diagnostic and returns status 1.
## @param $* Human-readable diagnostic text.
## @retval 1 Always returns the public operational-failure status.
__adrctl_fail_operational() {
  __adrctl_print_error "$*" || :
  return "${__adrctl_exit_operational}"
}

## @fn __adrctl_fail_usage()
## @brief Writes a usage/configuration diagnostic and returns status 2.
## @param $* Human-readable diagnostic text.
## @retval 2 Always returns the public usage/configuration status.
__adrctl_fail_usage() {
  __adrctl_print_error "$*" || :
  return "${__adrctl_exit_usage}"
}

## @fn __adrctl_require_bash()
## @brief Validates the Bash 4.3 minimum runtime before other product behavior.
## @retval 0 The running Bash satisfies the minimum.
## @retval 1 The running Bash is too old.
__adrctl_require_bash() {
  if (( BASH_VERSINFO[0] > 4 )); then
    return 0
  fi

  if (( BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3 )); then
    return 0
  fi

  __adrctl_fail_operational \
    "Bash 4.3 or newer is required (found ${BASH_VERSION})"
}

## @fn __adrctl_trim()
## @brief Removes leading and trailing shell whitespace from one string.
## @param $1 Input string.
## @par Standard Output
## Trimmed string followed by a newline.
## @retval 0 The value was written.
__adrctl_trim() {
  local value

  value="$1"
  value="${value#"${value%%[!$' \t\r\n']*}"}"
  value="${value%"${value##*[!$' \t\r\n']}"}"
  printf '%s\n' "${value}"
}

## @fn __adrctl_unquote_simple()
## @brief Removes one matching outer layer of single or double quotes.
## @param $1 Input value.
## @par Standard Output
## Unquoted value followed by a newline.
## @retval 0 The value was written.
__adrctl_unquote_simple() {
  local value

  value="$1"

  if (( ${#value} >= 2 )); then
    if [[ ${value:0:1} == '"' && ${value: -1} == '"' ]]; then
      value="${value:1:${#value}-2}"
    elif [[ ${value:0:1} == "'" && ${value: -1} == "'" ]]; then
      value="${value:1:${#value}-2}"
    fi
  fi

  printf '%s\n' "${value}"
}

## @fn __adrctl_is_absolute_path()
## @brief Tests whether a path uses Unix absolute-path syntax.
## @param $1 Path string.
## @retval 0 The path begins with `/`.
## @retval 1 The path is relative.
__adrctl_is_absolute_path() {
  [[ $1 == /* ]]
}

## @fn __adrctl_join_path()
## @brief Resolves a configured path against a base directory.
## @param $1 Base directory.
## @param $2 Configured path.
## @par Standard Output
## Absolute or base-prefixed path followed by a newline.
## @retval 0 The path was written.
__adrctl_join_path() {
  local base
  local path

  base="$1"
  path="$2"

  if __adrctl_is_absolute_path "${path}"; then
    printf '%s\n' "${path}"
  elif [[ ${base} == / ]]; then
    printf '/%s\n' "${path}"
  else
    printf '%s/%s\n' "${base%/}" "${path}"
  fi
}

## @fn __adrctl_command_exists()
## @brief Tests whether a command name is available through PATH.
## @param $1 Command name.
## @retval 0 The command exists.
## @retval 1 The command is unavailable.
__adrctl_command_exists() {
  command -v -- "$1" >/dev/null 2>&1
}

## @fn __adrctl_print_version()
## @brief Writes stable product build metadata.
## @retval 0 Version information was written.
## @retval 1 Standard output rejected the write.
__adrctl_print_version() {
  printf 'adrctl %s\nbuild_date=%s\ncommit=%s\n' \
    "${__adrctl_version}" \
    "${__adrctl_build_date}" \
    "${__adrctl_build_commit}"
}

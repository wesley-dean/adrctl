## @file lib/project.bash
## @brief Resolves project roots, project configuration, and ADR directories.

__adrctl_project_root=''
__adrctl_adr_dir=''
__adrctl_adr_glob='*.md'
__adrctl_adr_number_regex='^[^0-9]*([0-9]+)-.+\.md$'

## @fn __adrctl_match_adr_basename()
## @brief Applies the effective candidate glob and number regex to one basename.
## @param $1 Candidate basename.
## @param $2 Output variable for normalized logical number.
## @retval 0 The basename is a managed ADR and a number was returned.
## @retval 1 The basename is not a managed ADR.
## @retval 2 The configured regex matched without decimal capture group 1.
__adrctl_match_adr_basename() {
  local base
  local digits
  local regex_status

  base="$1"

  # The configured value is intentionally a Bash pattern, not a literal string.
  # shellcheck disable=SC2053
  [[ ${base} == ${__adrctl_adr_glob} ]] || return 1

  if [[ ${base} =~ ${__adrctl_adr_number_regex} ]]; then
    digits="${BASH_REMATCH[1]-}"
  else
    # Bash returns 2 when the configured ERE is syntactically invalid.  Preserve
    # that condition status before another command can replace it.
    # shellcheck disable=SC2319
    regex_status=$?
    if (( regex_status == 2 )); then
      __adrctl_fail_usage 'ADRCTL_ADR_NUMBER_REGEX became invalid during matching'
      return $?
    fi
    return 1
  fi

  if [[ ! ${digits} =~ ^[0-9]+$ ]]; then
    __adrctl_fail_usage \
      "ADRCTL_ADR_NUMBER_REGEX matched ${base} without decimal capture group 1"
    return $?
  fi

  printf -v "$2" '%d' "$((10#${digits}))"
}

## @fn __adrctl_validate_adr_discovery_state()
## @brief Validates capture-group behavior for existing candidate files.
## @details
## Candidate files rejected by the number regex are unrelated and are ignored.
## A candidate that matches the regex without decimal capture group 1 is invalid
## configuration and fails before command-specific filesystem mutation begins.
## @retval 0 Existing candidate state satisfies the discovery contract.
## @retval 2 A candidate exposed an invalid capture-group contract.
__adrctl_validate_adr_discovery_state() {
  local path
  local base
  local number
  local status

  [[ -d ${__adrctl_adr_dir} ]] || return 0

  for path in \
    "${__adrctl_adr_dir}"/* \
    "${__adrctl_adr_dir}"/.[!.]* \
    "${__adrctl_adr_dir}"/..?*; do
    [[ -f ${path} ]] || continue
    base="${path##*/}"

    if __adrctl_match_adr_basename "${base}" number; then
      # Referencing the output also documents that successful matches always
      # produce a logical number, even though this validation pass only needs the
      # match/capture contract.
      [[ ${number} =~ ^[0-9]+$ ]] || return "${__adrctl_exit_usage}"
    else
      status=$?
      (( status == 1 )) || return "${status}"
    fi
  done
}

## @fn __adrctl_validate_new_adr_basename()
## @brief Ensures a rendered filename is rediscoverable as its assigned number.
## @param $1 Rendered basename.
## @param $2 Assigned logical ADR number.
## @retval 0 The basename satisfies the effective discovery contract.
## @retval 2 The basename would be ignored or assigned another logical number.
__adrctl_validate_new_adr_basename() {
  local base
  local expected_number
  local actual_number
  local status

  base="$1"
  expected_number="$2"

  # The configured value is intentionally a Bash pattern, not a literal string.
  # shellcheck disable=SC2053
  if [[ ${base} != ${__adrctl_adr_glob} ]]; then
    __adrctl_fail_usage \
      "rendered ADR filename does not match ADRCTL_ADR_GLOB: ${base}"
    return $?
  fi

  if __adrctl_match_adr_basename "${base}" actual_number; then
    :
  else
    status=$?
    if (( status == 1 )); then
      __adrctl_fail_usage \
        "rendered ADR filename does not match ADRCTL_ADR_NUMBER_REGEX: ${base}"
      return $?
    fi
    return "${status}"
  fi

  if (( actual_number != expected_number )); then
    __adrctl_fail_usage \
      "rendered ADR filename captures logical number ${actual_number}, expected ${expected_number}: ${base}"
    return $?
  fi
}

## @fn __adrctl_canonical_existing_dir()
## @brief Canonicalizes an existing directory through Bash `cd` and `pwd -P`.
## @param $1 Directory path.
## @par Standard Output
## Canonical physical directory path followed by a newline.
## @retval 0 Directory exists and can be entered.
## @retval 1 Directory is invalid or inaccessible.
__adrctl_canonical_existing_dir() {
  local canonical

  canonical="$(cd -- "$1" 2>/dev/null && pwd -P)" || return 1
  printf '%s\n' "${canonical}"
}

## @fn __adrctl_dir_has_project_marker()
## @brief Tests whether a directory contains a recognized adrctl marker.
## @param $1 Directory path.
## @retval 0 A recognized marker exists.
## @retval 1 No recognized marker exists.
__adrctl_dir_has_project_marker() {
  local dir

  dir="$1"

  [[ -f ${dir}/.adr-dir ]] && return 0
  [[ -d ${dir}/doc/adr ]] && return 0

  if [[ -f ${dir}/.env ]] && __adrctl_config_file_has_marker "${dir}/.env"; then
    return 0
  fi

  return 1
}

## @fn __adrctl_find_nearest_project_marker()
## @brief Walks upward from a directory and reports the nearest marked ancestor.
## @param $1 Starting directory.
## @par Standard Output
## Canonical marked directory followed by a newline.
## @retval 0 A marker was found.
## @retval 1 No ancestor contains a marker.
__adrctl_find_nearest_project_marker() {
  local current
  local parent

  current="$(__adrctl_canonical_existing_dir "$1")" || return 1

  while :; do
    if __adrctl_dir_has_project_marker "${current}"; then
      printf '%s\n' "${current}"
      return 0
    fi

    [[ ${current} == / ]] && break
    parent="${current%/*}"
    [[ -n ${parent} ]] || parent=/
    [[ ${parent} == "${current}" ]] && break
    current="${parent}"
  done

  return 1
}

## @fn __adrctl_git_root()
## @brief Reports the current Git work-tree root when Git can determine one.
## @par Standard Output
## Git top-level path followed by a newline.
## @retval 0 A Git root was found.
## @retval 1 Git is unavailable or cwd is not inside a work tree.
__adrctl_git_root() {
  local root

  __adrctl_command_exists git || return 1

  root="$(git rev-parse --show-toplevel 2>/dev/null)" || return 1
  [[ -n ${root} ]] || return 1
  __adrctl_canonical_existing_dir "${root}"
}

## @fn __adrctl_resolve_project_root()
## @brief Resolves PROJECT_ROOT according to ADR-005.
## @param $1 Command mode: `existing` or `init`.
## @param $2 Explicit CLI root value, or empty when absent.
## @param $3 Explicit CLI root presence flag (0/1).
## @param $4 Output variable for resolved root.
## @retval 0 A usable root was selected.
## @retval 1 An explicit root was invalid.
__adrctl_resolve_project_root() {
  local mode
  local cli_root
  local cli_root_set
  local root

  mode="$1"
  cli_root="$2"
  cli_root_set="$3"

  if (( cli_root_set )); then
    if ! root="$(__adrctl_canonical_existing_dir "${cli_root}")"; then
      __adrctl_fail_operational "project root is not an accessible directory: ${cli_root}"
      return $?
    fi
    printf -v "$4" '%s' "${root}"
    return 0
  fi

  if [[ -v ADRCTL_PROJECT_ROOT ]]; then
    if ! root="$(__adrctl_canonical_existing_dir "${ADRCTL_PROJECT_ROOT}")"; then
      __adrctl_fail_operational \
        "ADRCTL_PROJECT_ROOT is not an accessible directory: ${ADRCTL_PROJECT_ROOT}"
      return $?
    fi
    printf -v "$4" '%s' "${root}"
    return 0
  fi

  if [[ ${mode} == init ]]; then
    root="$(__adrctl_canonical_existing_dir .)" || {
      __adrctl_fail_operational 'cannot resolve the current working directory'
      return $?
    }
    printf -v "$4" '%s' "${root}"
    return 0
  fi

  if root="$(__adrctl_find_nearest_project_marker .)"; then
    printf -v "$4" '%s' "${root}"
    return 0
  fi

  if root="$(__adrctl_git_root)"; then
    printf -v "$4" '%s' "${root}"
    return 0
  fi

  root="$(__adrctl_canonical_existing_dir .)" || {
    __adrctl_fail_operational 'cannot resolve the current working directory'
    return $?
  }
  printf -v "$4" '%s' "${root}"
}

## @fn __adrctl_read_legacy_adr_dir()
## @brief Reads one legacy `.adr-dir` path value as data.
## @param $1 .adr-dir path.
## @param $2 Output variable for value.
## @retval 0 A non-empty value was read.
## @retval 1 The file is unreadable or empty.
__adrctl_read_legacy_adr_dir() {
  local line

  [[ -r $1 ]] || return 1
  IFS= read -r line <"$1" || [[ -n ${line} ]] || return 1
  line="$(__adrctl_trim "${line}")"
  [[ -n ${line} ]] || return 1
  printf -v "$2" '%s' "${line}"
}

## @fn __adrctl_resolve_adr_dir()
## @brief Resolves the effective ADR directory after configuration loading.
## @param $1 Project root.
## @param $2 Output variable for resolved ADR directory.
## @retval 0 A non-empty ADR directory was resolved.
## @retval 1 Selected configuration is unusable.
__adrctl_resolve_adr_dir() {
  local root
  local value
  local value_set

  root="$1"
  value=''
  value_set=0

  __adrctl_config_effective_adr_dir_value value value_set

  if (( value_set )); then
    if [[ -z ${value} ]]; then
      __adrctl_fail_operational 'ADR directory configuration must not be empty'
      return $?
    fi
    value="$(__adrctl_join_path "${root}" "${value}")"
    printf -v "$2" '%s' "${value%/}"
    return 0
  fi

  if [[ -f ${root}/.adr-dir ]]; then
    if ! __adrctl_read_legacy_adr_dir "${root}/.adr-dir" value; then
      __adrctl_fail_operational "invalid or empty legacy ADR directory file: ${root}/.adr-dir"
      return $?
    fi
    value="$(__adrctl_join_path "${root}" "${value}")"
    printf -v "$2" '%s' "${value%/}"
    return 0
  fi

  printf -v "$2" '%s' "$(__adrctl_join_path "${root}" 'doc/adr')"
}

## @fn __adrctl_load_project()
## @brief Resolves project root, configuration, ADR directory, and discovery state.
## @param $1 Command mode: `existing` or `init`.
## @param $2 Explicit CLI project-root value.
## @param $3 Explicit CLI project-root presence flag (0/1).
## @retval 0 Project state is ready for command-specific validation.
## @retval 1 Operational project failure.
## @retval 2 Invalid project configuration.
__adrctl_load_project() {
  local mode
  local cli_root
  local cli_root_set

  mode="$1"
  cli_root="$2"
  cli_root_set="$3"

  __adrctl_resolve_project_root \
    "${mode}" "${cli_root}" "${cli_root_set}" __adrctl_project_root || return $?

  __adrctl_config_load_project_file "${__adrctl_project_root}/.env" || return $?
  __adrctl_resolve_adr_dir "${__adrctl_project_root}" __adrctl_adr_dir || return $?
  __adrctl_config_effective_adr_glob __adrctl_adr_glob || return $?
  __adrctl_config_effective_adr_number_regex __adrctl_adr_number_regex || return $?
  __adrctl_validate_adr_discovery_state || return $?
}

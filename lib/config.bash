## @file lib/config.bash
## @brief Parses project-scoped adrctl configuration as inert data.

__adrctl_cfg_adr_dir=''
__adrctl_cfg_adr_dir_set=0
__adrctl_cfg_template=''
__adrctl_cfg_template_set=0
__adrctl_cfg_filename_pattern=''
__adrctl_cfg_filename_pattern_set=0
__adrctl_cfg_start_delimiter=''
__adrctl_cfg_start_delimiter_set=0
__adrctl_cfg_end_delimiter=''
__adrctl_cfg_end_delimiter_set=0

## @fn __adrctl_config_reset()
## @brief Clears project-file configuration state before loading one project.
__adrctl_config_reset() {
  __adrctl_cfg_adr_dir=''
  __adrctl_cfg_adr_dir_set=0
  __adrctl_cfg_template=''
  __adrctl_cfg_template_set=0
  __adrctl_cfg_filename_pattern=''
  __adrctl_cfg_filename_pattern_set=0
  __adrctl_cfg_start_delimiter=''
  __adrctl_cfg_start_delimiter_set=0
  __adrctl_cfg_end_delimiter=''
  __adrctl_cfg_end_delimiter_set=0
}

## @fn __adrctl_config_key_is_project_scoped()
## @brief Tests whether a key is a supported project-file adrctl setting.
## @param $1 Key name.
## @retval 0 The key is supported in project `.env`.
## @retval 1 The key is not a project-scoped setting.
__adrctl_config_key_is_project_scoped() {
  case "$1" in
    ADRCTL_ADR_DIR | ADRCTL_TEMPLATE | ADRCTL_FILENAME_PATTERN | \
      ADRCTL_TEMPLATE_START_DELIMITER | ADRCTL_TEMPLATE_END_DELIMITER)
      return 0
      ;;
  esac

  return 1
}

## @fn __adrctl_config_parse_assignment_line()
## @brief Parses one nonblank .env line into key and value output variables.
## @param $1 Raw line.
## @param $2 Output variable name for the key.
## @param $3 Output variable name for the value.
## @retval 0 A KEY=VALUE assignment was parsed.
## @retval 1 The line is blank or a comment.
## @retval 2 The line is malformed.
__adrctl_config_parse_assignment_line() {
  local line
  local key
  local value

  line="$(__adrctl_trim "$1")"

  if [[ -z ${line} || ${line} == \#* ]]; then
    return 1
  fi

  if [[ ${line} == export[[:space:]]* ]]; then
    line="${line#export}"
    line="$(__adrctl_trim "${line}")"
  fi

  if [[ ${line} != *=* ]]; then
    return 2
  fi

  key="$(__adrctl_trim "${line%%=*}")"
  value="$(__adrctl_trim "${line#*=}")"
  value="$(__adrctl_unquote_simple "${value}")"

  if [[ ! ${key} =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    return 2
  fi

  printf -v "$2" '%s' "${key}"
  printf -v "$3" '%s' "${value}"
}

## @fn __adrctl_config_file_has_marker()
## @brief Tests whether .env contains a supported project-scoped ADRCTL key.
## @param $1 .env path.
## @retval 0 At least one supported project key is present.
## @retval 1 No supported project key is present or the file is unreadable.
__adrctl_config_file_has_marker() {
  local line
  local key
  local value
  local status

  [[ -r $1 ]] || return 1

  while IFS= read -r line || [[ -n ${line} ]]; do
    key=''
    value=''
    __adrctl_config_parse_assignment_line "${line}" key value
    status=$?

    if (( status == 0 )) && __adrctl_config_key_is_project_scoped "${key}"; then
      return 0
    fi
  done <"$1"

  return 1
}

## @fn __adrctl_config_apply_project_assignment()
## @brief Applies one validated project-file assignment to private config state.
## @param $1 Key.
## @param $2 Value.
## @param $3 Source path.
## @param $4 Source line number.
## @retval 0 The assignment was applied or intentionally ignored.
## @retval 2 The key belongs to adrctl but is invalid in project configuration.
__adrctl_config_apply_project_assignment() {
  local key
  local value
  local source
  local line_number

  key="$1"
  value="$2"
  source="$3"
  line_number="$4"

  case "${key}" in
    ADRCTL_ADR_DIR)
      __adrctl_cfg_adr_dir="${value}"
      __adrctl_cfg_adr_dir_set=1
      ;;
    ADRCTL_TEMPLATE)
      __adrctl_cfg_template="${value}"
      __adrctl_cfg_template_set=1
      ;;
    ADRCTL_FILENAME_PATTERN)
      __adrctl_cfg_filename_pattern="${value}"
      __adrctl_cfg_filename_pattern_set=1
      ;;
    ADRCTL_TEMPLATE_START_DELIMITER)
      __adrctl_cfg_start_delimiter="${value}"
      __adrctl_cfg_start_delimiter_set=1
      ;;
    ADRCTL_TEMPLATE_END_DELIMITER)
      __adrctl_cfg_end_delimiter="${value}"
      __adrctl_cfg_end_delimiter_set=1
      ;;
    ADRCTL_PROJECT_ROOT)
      __adrctl_fail_usage \
        "invalid project configuration in ${source}:${line_number}: ADRCTL_PROJECT_ROOT is environment/CLI only"
      return $?
      ;;
    ADRCTL_*)
      __adrctl_fail_usage \
        "unknown project configuration key in ${source}:${line_number}: ${key}"
      return $?
      ;;
    *)
      :
      ;;
  esac
}

## @fn __adrctl_config_validate_pair()
## @brief Validates one delimiter pair and its presence flags.
## @param $1 Start-delimiter value.
## @param $2 Start value was explicitly set (0/1).
## @param $3 End-delimiter value.
## @param $4 End value was explicitly set (0/1).
## @param $5 Human-readable source.
## @retval 0 Both are absent, both empty, or both non-empty.
## @retval 2 The pair is partial or one-sided empty.
__adrctl_config_validate_pair() {
  local start
  local start_set
  local end
  local end_set
  local source

  start="$1"
  start_set="$2"
  end="$3"
  end_set="$4"
  source="$5"

  if (( start_set != end_set )); then
    __adrctl_fail_usage "${source}: template delimiters must be supplied together"
    return $?
  fi

  if (( start_set == 0 )); then
    return 0
  fi

  if [[ ( -z ${start} && -n ${end} ) || ( -n ${start} && -z ${end} ) ]]; then
    __adrctl_fail_usage "${source}: template delimiters must both be empty or both be non-empty"
    return $?
  fi

  if [[ ${start} == *$'\n'* || ${end} == *$'\n'* ]]; then
    __adrctl_fail_usage "${source}: template delimiters must not contain newline characters"
    return $?
  fi
}

## @fn __adrctl_config_load_project_file()
## @brief Loads and validates one selected project `.env` file.
## @param $1 .env path.
## @retval 0 The file was absent or loaded successfully.
## @retval 1 The file could not be read.
## @retval 2 The file contains malformed or unsupported adrctl configuration.
__adrctl_config_load_project_file() {
  local path
  local line
  local line_number
  local key
  local value
  local status

  path="$1"
  __adrctl_config_reset

  [[ -e ${path} ]] || return 0

  if [[ ! -r ${path} ]]; then
    __adrctl_fail_operational "cannot read project configuration: ${path}"
    return $?
  fi

  line_number=0
  while IFS= read -r line || [[ -n ${line} ]]; do
    line_number=$((line_number + 1))
    key=''
    value=''

    __adrctl_config_parse_assignment_line "${line}" key value
    status=$?

    case "${status}" in
      0)
        __adrctl_config_apply_project_assignment \
          "${key}" "${value}" "${path}" "${line_number}" || return $?
        ;;
      1)
        :
        ;;
      *)
        __adrctl_fail_usage \
          "invalid project configuration in ${path}:${line_number}: expected KEY=VALUE"
        return $?
        ;;
    esac
  done <"${path}"

  __adrctl_config_validate_pair \
    "${__adrctl_cfg_start_delimiter}" "${__adrctl_cfg_start_delimiter_set}" \
    "${__adrctl_cfg_end_delimiter}" "${__adrctl_cfg_end_delimiter_set}" \
    "project configuration" || return $?
}

## @fn __adrctl_config_effective_adr_dir_value()
## @brief Returns the highest-precedence modern ADR directory value if supplied.
## @param $1 Output variable for the value.
## @param $2 Output variable for presence flag.
__adrctl_config_effective_adr_dir_value() {
  if [[ -v ADRCTL_ADR_DIR ]]; then
    printf -v "$1" '%s' "${ADRCTL_ADR_DIR}"
    printf -v "$2" '%s' 1
  elif (( __adrctl_cfg_adr_dir_set )); then
    printf -v "$1" '%s' "${__adrctl_cfg_adr_dir}"
    printf -v "$2" '%s' 1
  else
    printf -v "$1" '%s' ''
    printf -v "$2" '%s' 0
  fi
}

## @fn __adrctl_config_effective_template_value()
## @brief Returns the configured body-template path before legacy/default fallback.
## @param $1 Output variable for value.
## @param $2 Output variable for presence flag.
__adrctl_config_effective_template_value() {
  if [[ -v ADRCTL_TEMPLATE ]]; then
    printf -v "$1" '%s' "${ADRCTL_TEMPLATE}"
    printf -v "$2" '%s' 1
  elif [[ -v ADR_TEMPLATE ]]; then
    printf -v "$1" '%s' "${ADR_TEMPLATE}"
    printf -v "$2" '%s' 1
  elif (( __adrctl_cfg_template_set )); then
    printf -v "$1" '%s' "${__adrctl_cfg_template}"
    printf -v "$2" '%s' 1
  else
    printf -v "$1" '%s' ''
    printf -v "$2" '%s' 0
  fi
}

## @fn __adrctl_config_effective_filename_pattern()
## @brief Returns configured filename pattern or the compatibility default.
## @param $1 Output variable.
__adrctl_config_effective_filename_pattern() {
  if [[ -v ADRCTL_FILENAME_PATTERN ]]; then
    printf -v "$1" '%s' "${ADRCTL_FILENAME_PATTERN}"
  elif (( __adrctl_cfg_filename_pattern_set )); then
    printf -v "$1" '%s' "${__adrctl_cfg_filename_pattern}"
  else
    printf -v "$1" '%s' '{NUMBER4}-{TITLE_SLUG}.md'
  fi
}

## @fn __adrctl_config_effective_delimiters()
## @brief Returns an explicit configured delimiter pair when one exists.
## @param $1 Output variable for start delimiter.
## @param $2 Output variable for end delimiter.
## @param $3 Output variable for explicit-pair flag.
## @retval 0 Pair is absent or valid.
## @retval 2 Environment pair is malformed.
__adrctl_config_effective_delimiters() {
  local env_start_set
  local env_end_set

  env_start_set=0
  env_end_set=0
  [[ -v ADRCTL_TEMPLATE_START_DELIMITER ]] && env_start_set=1
  [[ -v ADRCTL_TEMPLATE_END_DELIMITER ]] && env_end_set=1

  if (( env_start_set || env_end_set )); then
    __adrctl_config_validate_pair \
      "${ADRCTL_TEMPLATE_START_DELIMITER-}" "${env_start_set}" \
      "${ADRCTL_TEMPLATE_END_DELIMITER-}" "${env_end_set}" \
      "process environment" || return $?

    printf -v "$1" '%s' "${ADRCTL_TEMPLATE_START_DELIMITER-}"
    printf -v "$2" '%s' "${ADRCTL_TEMPLATE_END_DELIMITER-}"
    printf -v "$3" '%s' 1
    return 0
  fi

  if (( __adrctl_cfg_start_delimiter_set )); then
    printf -v "$1" '%s' "${__adrctl_cfg_start_delimiter}"
    printf -v "$2" '%s' "${__adrctl_cfg_end_delimiter}"
    printf -v "$3" '%s' 1
    return 0
  fi

  printf -v "$1" '%s' ''
  printf -v "$2" '%s' ''
  printf -v "$3" '%s' 0
}

## @file lib/render.bash
## @brief Prepares ADR rendering values and delegates substitution to mktext.

## @fn __adrctl_slugify()
## @brief Converts a title into the compatible lowercase hyphenated slug form.
## @param $1 Title text.
## @par Standard Output
## Slug followed by a newline.
## @retval 0 The slug was written.
__adrctl_slugify() {
  local input
  local output
  local character
  local pending_separator
  local index

  input="$1"
  output=''
  pending_separator=0

  for (( index = 0; index < ${#input}; index++ )); do
    character="${input:index:1}"

    if [[ ${character} =~ [[:alnum:]] ]]; then
      if (( pending_separator && ${#output} > 0 )); then
        output+='-'
      fi
      output+="${character,,}"
      pending_separator=0
    else
      pending_separator=1
    fi
  done

  printf '%s\n' "${output}"
}

## @fn __adrctl_current_date()
## @brief Produces the effective ADR date using legacy ADR_DATE compatibility.
## @par Standard Output
## Date value followed by a newline.
## @retval 0 The date was written.
__adrctl_current_date() {
  local value

  if [[ -v ADR_DATE ]]; then
    printf '%s\n' "${ADR_DATE}"
    return 0
  fi

  printf -v value '%(%Y-%m-%d)T' -1
  printf '%s\n' "${value}"
}

## @fn __adrctl_populate_context()
## @brief Populates one caller-owned associative-array render context.
## @param $1 Context variable name.
## @param $2 Logical ADR number.
## @param $3 ADR title.
## @param $4 ADR status.
## @param $5 ADR date.
## @retval 0 The complete context was populated.
## @retval 1 A mktext operation failed.
__adrctl_populate_context() {
  local context_name
  local number
  local number4
  local title
  local status
  local date
  local slug

  context_name="$1"
  number="$2"
  title="$3"
  status="$4"
  date="$5"

  printf -v number4 '%04d' "${number}"
  slug="$(__adrctl_slugify "${title}")"

  mktext set "${context_name}" NUMBER "${number}" || return 1
  mktext set "${context_name}" NUMBER4 "${number4}" || return 1
  mktext set "${context_name}" TITLE "${title}" || return 1
  mktext set "${context_name}" TITLE_SLUG "${slug}" || return 1
  mktext set "${context_name}" STATUS "${status}" || return 1
  mktext set "${context_name}" DATE "${date}" || return 1
  mktext set "${context_name}" PROJECT_ROOT "${__adrctl_project_root}" || return 1
  mktext set "${context_name}" ADR_DIR "${__adrctl_adr_dir}" || return 1
}

## @fn __adrctl_print_default_template()
## @brief Writes the independently authored built-in body template.
__adrctl_print_default_template() {
  printf '%s\n' \
    '# NUMBER. TITLE' \
    '' \
    'Date: DATE' \
    '' \
    '## Status' \
    '' \
    'STATUS' \
    '' \
    '## Context' \
    '' \
    'Describe the circumstances, forces, and constraints that led to this decision.' \
    '' \
    '## Decision' \
    '' \
    'Describe the decision and the approach that will be taken.' \
    '' \
    '## Consequences' \
    '' \
    'Describe the expected benefits, costs, risks, and follow-up work created by this decision.'
}

## @fn __adrctl_print_init_template()
## @brief Writes the independently authored initialization ADR template.
__adrctl_print_init_template() {
  printf '%s\n' \
    '# 1. Record architecture decisions' \
    '' \
    'Date: DATE' \
    '' \
    '## Status' \
    '' \
    'Accepted' \
    '' \
    '## Context' \
    '' \
    'Important architectural choices need a durable record that can be reviewed later.' \
    '' \
    '## Decision' \
    '' \
    'We will record significant architectural decisions as Architecture Decision Records.' \
    '' \
    '## Consequences' \
    '' \
    'Future contributors can review the decision history alongside the source and documentation.'
}

## @fn __adrctl_context_has_braced_token_in_line()
## @brief Tests one template line for a braced token present in the render context.
## @param $1 Context variable name.
## @param $2 Template line.
## @retval 0 A recognized braced context token exists.
## @retval 1 No recognized token exists on the line.
__adrctl_context_has_braced_token_in_line() {
  local -n context_ref="$1"
  local remaining
  local raw_key
  local key
  local match
  local prefix

  remaining="$2"

  while [[ ${remaining} =~ \{[[:blank:]]*([A-Za-z][A-Za-z0-9_-]*)[[:blank:]]*\} ]]; do
    raw_key="${BASH_REMATCH[1]}"
    key="${raw_key^^}"

    if [[ ${context_ref[${key}]+_} ]]; then
      return 0
    fi

    match="${BASH_REMATCH[0]}"
    prefix="${remaining%%"${match}"*}"
    remaining="${remaining:$(( ${#prefix} + ${#match} ))}"
  done

  return 1
}

## @fn __adrctl_template_has_braced_context_token()
## @brief Detects modern braced syntax in a template source.
## @param $1 Context variable name.
## @param $2 Template source kind: `file`, `default`, or `init`.
## @param $3 Template source value for `file`; ignored otherwise.
## @retval 0 At least one recognized braced context token exists.
## @retval 1 No recognized braced token exists.
__adrctl_template_has_braced_context_token() {
  local context_name
  local kind
  local value
  local line

  context_name="$1"
  kind="$2"
  value="$3"

  case "${kind}" in
    file)
      while IFS= read -r line || [[ -n ${line} ]]; do
        __adrctl_context_has_braced_token_in_line "${context_name}" "${line}" && return 0
      done <"${value}"
      ;;
    default)
      while IFS= read -r line || [[ -n ${line} ]]; do
        __adrctl_context_has_braced_token_in_line "${context_name}" "${line}" && return 0
      done < <(__adrctl_print_default_template)
      ;;
    init)
      while IFS= read -r line || [[ -n ${line} ]]; do
        __adrctl_context_has_braced_token_in_line "${context_name}" "${line}" && return 0
      done < <(__adrctl_print_init_template)
      ;;
  esac

  return 1
}

## @fn __adrctl_select_template_source()
## @brief Selects the effective body-template source.
## @param $1 CLI template path.
## @param $2 CLI template presence flag (0/1).
## @param $3 Output variable for source kind.
## @param $4 Output variable for source value.
## @retval 0 A readable template or built-in source was selected.
## @retval 1 An explicitly configured template was missing or unreadable.
__adrctl_select_template_source() {
  local cli_template
  local cli_template_set
  local configured
  local configured_set
  local candidate

  cli_template="$1"
  cli_template_set="$2"

  if (( cli_template_set )); then
    configured="${cli_template}"
    configured_set=1
  else
    __adrctl_config_effective_template_value configured configured_set
  fi

  if (( configured_set )); then
    if [[ -z ${configured} ]]; then
      __adrctl_fail_operational 'template path must not be empty'
      return $?
    fi
    candidate="$(__adrctl_join_path "${__adrctl_project_root}" "${configured}")"
    if [[ ! -r ${candidate} ]]; then
      __adrctl_fail_operational "cannot read template: ${candidate}"
      return $?
    fi
    printf -v "$3" '%s' file
    printf -v "$4" '%s' "${candidate}"
    return 0
  fi

  candidate="${__adrctl_adr_dir}/templates/template.md"
  if [[ -r ${candidate} ]]; then
    printf -v "$3" '%s' file
    printf -v "$4" '%s' "${candidate}"
    return 0
  fi

  printf -v "$3" '%s' default
  printf -v "$4" '%s' ''
}

## @fn __adrctl_select_body_delimiters()
## @brief Chooses the effective body-template delimiter pair.
## @param $1 Context variable name.
## @param $2 Template source kind.
## @param $3 Template source value.
## @param $4 CLI start delimiter value.
## @param $5 CLI start presence flag.
## @param $6 CLI end delimiter value.
## @param $7 CLI end presence flag.
## @param $8 Output variable for start delimiter.
## @param $9 Output variable for end delimiter.
## @retval 0 A delimiter pair was selected.
## @retval 2 An explicit pair is invalid.
__adrctl_select_body_delimiters() {
  local context_name
  local kind
  local value
  local cli_start
  local cli_start_set
  local cli_end
  local cli_end_set
  local configured_start
  local configured_end
  local configured_set

  context_name="$1"
  kind="$2"
  value="$3"
  cli_start="$4"
  cli_start_set="$5"
  cli_end="$6"
  cli_end_set="$7"

  if (( cli_start_set || cli_end_set )); then
    __adrctl_config_validate_pair \
      "${cli_start}" "${cli_start_set}" \
      "${cli_end}" "${cli_end_set}" \
      'command line' || return $?
    printf -v "$8" '%s' "${cli_start}"
    printf -v "$9" '%s' "${cli_end}"
    return 0
  fi

  __adrctl_config_effective_delimiters \
    configured_start configured_end configured_set || return $?

  if (( configured_set )); then
    printf -v "$8" '%s' "${configured_start}"
    printf -v "$9" '%s' "${configured_end}"
    return 0
  fi

  if __adrctl_template_has_braced_context_token "${context_name}" "${kind}" "${value}"; then
    printf -v "$8" '%s' '{'
    printf -v "$9" '%s' '}'
  else
    printf -v "$8" '%s' ''
    printf -v "$9" '%s' ''
  fi
}

## @fn __adrctl_render_body_to_path()
## @brief Renders one selected body-template source to a destination file.
## @param $1 Context variable name.
## @param $2 Source kind.
## @param $3 Source value.
## @param $4 Start delimiter.
## @param $5 End delimiter.
## @param $6 Destination path.
## @retval 0 Rendering completed successfully.
## @retval 1 Rendering failed.
__adrctl_render_body_to_path() {
  local context_name
  local kind
  local value
  local start
  local end
  local destination

  context_name="$1"
  kind="$2"
  value="$3"
  start="$4"
  end="$5"
  destination="$6"

  case "${kind}" in
    file)
      mktext render "${context_name}" \
        --start-delimiter "${start}" \
        --end-delimiter "${end}" \
        <"${value}" >"${destination}"
      ;;
    default)
      mktext render "${context_name}" \
        --start-delimiter "${start}" \
        --end-delimiter "${end}" \
        < <(__adrctl_print_default_template) >"${destination}"
      ;;
    init)
      mktext render "${context_name}" \
        --start-delimiter "${start}" \
        --end-delimiter "${end}" \
        < <(__adrctl_print_init_template) >"${destination}"
      ;;
    *)
      return 1
      ;;
  esac
}

## @fn __adrctl_render_filename()
## @brief Renders and validates one ADR filename pattern using braced mktext syntax.
## @param $1 Context variable name.
## @param $2 Filename pattern.
## @param $3 Output variable for rendered basename.
## @retval 0 A safe basename was rendered.
## @retval 1 Rendering failed or produced an unsafe basename.
__adrctl_render_filename() {
  local rendered

  if ! rendered="$(mktext render "$1" <<<"$2")"; then
    __adrctl_fail_operational 'failed to render ADR filename pattern'
    return $?
  fi

  if [[ -z ${rendered} || ${rendered} == /* || ${rendered} == *'/'* || ${rendered} == '.' || ${rendered} == '..' ]]; then
    __adrctl_fail_operational "filename pattern produced an unsafe basename: ${rendered}"
    return $?
  fi

  printf -v "$3" '%s' "${rendered}"
}

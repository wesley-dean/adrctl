## @file lib/adr.bash
## @brief Provides ADR file discovery, reference resolution, and bounded mutation.

## @fn __adrctl_file_number()
## @brief Extracts the logical decimal number from one managed ADR pathname.
## @param $1 ADR pathname.
## @param $2 Output variable for number.
## @retval 0 The basename is managed and a logical number was extracted.
## @retval 1 The basename is not managed by the effective discovery contract.
## @retval 2 The configured number regex violated its capture-group contract.
__adrctl_file_number() {
  local base

  base="${1##*/}"
  __adrctl_match_adr_basename "${base}" "$2"
}

## @fn __adrctl_collect_adrs()
## @brief Collects managed ADR files in numeric order with basename tie-break.
## @param $1 Output array variable name.
## @retval 0 Collection completed, including when the directory is absent.
## @retval 2 A candidate exposed an invalid number-regex capture contract.
__adrctl_collect_adrs() {
  local -n output_ref="$1"
  local path
  local i
  local j
  local left_number
  local right_number
  local status
  local swap

  output_ref=()

  # Project discovery assigns this cross-module state before ADR collection.
  # shellcheck disable=SC2154
  [[ -d ${__adrctl_adr_dir} ]] || return 0

  for path in \
    "${__adrctl_adr_dir}"/* \
    "${__adrctl_adr_dir}"/.[!.]* \
    "${__adrctl_adr_dir}"/..?*; do
    [[ -f ${path} ]] || continue

    if __adrctl_file_number "${path}" left_number; then
      output_ref+=("${path}")
    else
      status=$?
      (( status == 1 )) || return "${status}"
    fi
  done

  for (( i = 1; i < ${#output_ref[@]}; i++ )); do
    j="${i}"
    while (( j > 0 )); do
      __adrctl_file_number "${output_ref[j-1]}" left_number || return $?
      __adrctl_file_number "${output_ref[j]}" right_number || return $?

      if (( left_number < right_number )); then
        break
      fi
      if (( left_number == right_number )) && \
        [[ ${output_ref[j-1]##*/} < ${output_ref[j]##*/} ]]; then
        break
      fi

      swap="${output_ref[j-1]}"
      output_ref[j-1]="${output_ref[j]}"
      output_ref[j]="${swap}"
      j=$((j - 1))
    done
  done
}

## @fn __adrctl_next_number()
## @brief Computes one greater than the greatest managed ADR number.
## @param $1 Output variable for next number.
## @retval 0 A candidate number was produced.
## @retval 2 Discovery configuration is invalid for an existing candidate.
__adrctl_next_number() {
  local -a scanned_files
  local scanned_number
  local maximum_number
  local scanned_path

  declare -a scanned_files=()
  maximum_number=0

  __adrctl_collect_adrs scanned_files || return $?
  for scanned_path in "${scanned_files[@]}"; do
    __adrctl_file_number "${scanned_path}" scanned_number || return $?
    (( scanned_number > maximum_number )) && maximum_number="${scanned_number}"
  done

  printf -v "$1" '%d' "$((maximum_number + 1))"
}

## @fn __adrctl_relative_path()
## @brief Computes a lexical relative path from one absolute directory to a target.
## @param $1 Absolute source directory.
## @param $2 Absolute target path.
## @param $3 Output variable for relative path.
## @retval 0 A relative path was produced.
__adrctl_relative_path() {
  local from
  local target
  local from_trimmed
  local target_trimmed
  local -a from_parts
  local -a target_parts
  local common
  local i
  local result

  from="$1"
  target="$2"
  from_trimmed="${from#/}"
  target_trimmed="${target#/}"
  IFS='/' read -r -a from_parts <<<"${from_trimmed}"
  IFS='/' read -r -a target_parts <<<"${target_trimmed}"

  common=0
  while (( common < ${#from_parts[@]} && common < ${#target_parts[@]} )); do
    [[ ${from_parts[common]} == "${target_parts[common]}" ]] || break
    common=$((common + 1))
  done

  result=''
  for (( i = common; i < ${#from_parts[@]}; i++ )); do
    [[ -n ${from_parts[i]} ]] || continue
    result+='../'
  done

  for (( i = common; i < ${#target_parts[@]}; i++ )); do
    [[ -n ${target_parts[i]} ]] || continue
    result+="${target_parts[i]}"
    if (( i + 1 < ${#target_parts[@]} )); then
      result+='/'
    fi
  done

  [[ -n ${result} ]] || result='.'
  printf -v "$3" '%s' "${result}"
}

## @fn __adrctl_display_path()
## @brief Converts an absolute ADR path to predecessor-style cwd-relative output.
## @param $1 Absolute target path.
## @param $2 Output variable.
## @retval 0 A display path was produced.
## @retval 1 cwd could not be resolved.
__adrctl_display_path() {
  local cwd

  cwd="$(__adrctl_canonical_existing_dir .)" || return 1
  __adrctl_relative_path "${cwd}" "$1" "$2"
}

## @fn __adrctl_resolve_reference()
## @brief Resolves exact, numeric, or unique partial ADR references safely.
## @param $1 User-supplied reference.
## @param $2 Output variable for absolute ADR pathname.
## @retval 0 One ADR was resolved.
## @retval 1 No match or an ambiguous match exists.
## @retval 2 Discovery configuration is invalid for an existing candidate.
__adrctl_resolve_reference() {
  local reference
  local reference_base
  local -a files
  local -a matches
  local path
  local base
  local number
  local wanted_number

  reference="$1"
  reference_base="${reference##*/}"
  declare -a files=()
  declare -a matches=()

  __adrctl_collect_adrs files || return $?

  for path in "${files[@]}"; do
    base="${path##*/}"
    if [[ ${base} == "${reference_base}" ]]; then
      printf -v "$2" '%s' "${path}"
      return 0
    fi
  done

  if [[ ${reference_base} =~ ^[0-9]+$ ]]; then
    wanted_number=$((10#${reference_base}))
    for path in "${files[@]}"; do
      __adrctl_file_number "${path}" number || return $?
      (( number == wanted_number )) && matches+=("${path}")
    done
  else
    for path in "${files[@]}"; do
      base="${path##*/}"
      [[ ${base} == *"${reference_base}"* ]] && matches+=("${path}")
    done
  fi

  if (( ${#matches[@]} == 1 )); then
    printf -v "$2" '%s' "${matches[0]}"
    return 0
  fi

  if (( ${#matches[@]} == 0 )); then
    __adrctl_fail_operational "ADR reference not found: ${reference}"
    return $?
  fi

  __adrctl_print_error "ambiguous ADR reference: ${reference}" || :
  for path in "${matches[@]}"; do
    printf '  %s\n' "${path##*/}" >&2 || :
  done
  # Runtime defines the public operational exit-status constant before dispatch.
  # shellcheck disable=SC2154
  return "${__adrctl_exit_operational}"
}

## @fn __adrctl_read_title()
## @brief Reads the first level-one Markdown heading from an ADR.
## @param $1 ADR pathname.
## @param $2 Output variable for title without `# `.
## @retval 0 A title was found.
## @retval 1 No level-one title heading exists.
__adrctl_read_title() {
  local line

  while IFS= read -r line || [[ -n ${line} ]]; do
    if [[ ${line} == '# '* ]]; then
      printf -v "$2" '%s' "${line#\# }"
      return 0
    fi
  done <"$1"

  return 1
}

## @fn __adrctl_has_status_section()
## @brief Tests whether an ADR contains the exact `## Status` heading.
## @param $1 ADR pathname.
## @retval 0 Status section exists.
## @retval 1 Status section is absent.
__adrctl_has_status_section() {
  local line

  while IFS= read -r line || [[ -n ${line} ]]; do
    [[ ${line} == '## Status' ]] && return 0
  done <"$1"

  return 1
}

## @fn __adrctl_relationship_line()
## @brief Builds one Markdown relationship line to a target ADR.
## @param $1 Relationship text.
## @param $2 Target ADR pathname.
## @param $3 Output variable for rendered line.
## @retval 0 The relationship line was built.
## @retval 1 Target title could not be read.
__adrctl_relationship_line() {
  local relation_text
  local target_path
  local target_title

  relation_text="$1"
  target_path="$2"

  __adrctl_read_title "${target_path}" target_title || return 1
  printf -v "$3" '%s [%s](%s)' \
    "${relation_text}" "${target_title}" "${target_path##*/}"
}

## @fn __adrctl_temp_path()
## @brief Produces a same-directory temporary path for one target file.
## @param $1 Target path.
## @param $2 Tag used to distinguish multiple prepared outputs.
## @param $3 Output variable.
__adrctl_temp_path() {
  local target
  local dir
  local base

  target="$1"
  dir="${target%/*}"
  base="${target##*/}"
  printf -v "$3" '%s/.%s.adrctl.%s.%s.%s.tmp' \
    "${dir}" "${base}" "$$" "${RANDOM}" "$2"
}

## @fn __adrctl_prepare_status_mutation()
## @brief Prepares one ADR copy with bounded status removal and relationship adds.
## @param $1 Source ADR pathname.
## @param $2 Prepared output pathname.
## @param $3 Exact status line to remove, or empty for none.
## @param $4... Relationship lines to append.
## @retval 0 Output was prepared and a Status section existed.
## @retval 1 Source could not be transformed safely.
__adrctl_prepare_status_mutation() {
  local source
  local output
  local remove_status
  local -a links
  local line
  local in_status
  local saw_status
  local inserted
  local link

  source="$1"
  output="$2"
  remove_status="$3"
  shift 3
  links=("$@")
  in_status=0
  saw_status=0
  inserted=0

  : >"${output}" || return 1

  while IFS= read -r line || [[ -n ${line} ]]; do
    if [[ ${line} == '## Status' ]]; then
      printf '%s\n' "${line}" >>"${output}" || return 1
      in_status=1
      saw_status=1
      continue
    fi

    if (( in_status )) && [[ ${line} == '## '* ]]; then
      if (( inserted == 0 )); then
        for link in "${links[@]}"; do
          printf '%s\n' "${link}" >>"${output}" || return 1
        done
        (( ${#links[@]} > 0 )) && printf '\n' >>"${output}"
        inserted=1
      fi
      in_status=0
    fi

    if (( in_status )) && [[ -n ${remove_status} && ${line} == "${remove_status}" ]]; then
      continue
    fi

    printf '%s\n' "${line}" >>"${output}" || return 1
  done <"${source}"

  if (( in_status && inserted == 0 )); then
    for link in "${links[@]}"; do
      printf '%s\n' "${link}" >>"${output}" || return 1
    done
    (( ${#links[@]} > 0 )) && printf '\n' >>"${output}"
  fi

  (( saw_status )) || return 1
}

## @fn __adrctl_atomic_replace()
## @brief Replaces one existing target with a prepared same-directory file.
## @param $1 Prepared pathname.
## @param $2 Target pathname.
## @retval 0 Replacement succeeded.
## @retval 1 Replacement failed.
__adrctl_atomic_replace() {
  mv "$1" "$2"
}

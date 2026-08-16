## @file lib/commands.bash
## @brief Implements the public adrctl command surface.

## @fn __adrctl_publish_new_file()
## @brief Publishes a prepared same-directory file without overwriting a race winner.
## @param $1 Prepared temporary pathname.
## @param $2 Final new pathname.
## @retval 0 The final path was created with complete content.
## @retval 1 The final path already existed or publishing failed.
__adrctl_publish_new_file() {
  local prepared
  local target

  prepared="$1"
  target="$2"

  if ! ln "${prepared}" "${target}" 2>/dev/null; then
    return 1
  fi

  rm -f "${prepared}"
}

## @fn __adrctl_append_encoded_line()
## @brief Appends one line to an internal unit-separator encoded list.
## @param $1 Existing encoded value.
## @param $2 New line.
## @param $3 Output variable.
__adrctl_append_encoded_line() {
  if [[ -z $1 ]]; then
    printf -v "$3" '%s' "$2"
  else
    printf -v "$3" '%s\034%s' "$1" "$2"
  fi
}

## @fn __adrctl_decode_lines()
## @brief Decodes an internal unit-separator relationship list into an array.
## @param $1 Encoded string.
## @param $2 Output array variable name.
__adrctl_decode_lines() {
  local -n output_ref="$2"
  local value

  output_ref=()
  value="$1"
  [[ -n ${value} ]] || return 0
  IFS=$'\034' read -r -a output_ref <<<"${value}"
}

## @fn __adrctl_add_unique_path()
## @brief Adds a path to an ordered array only when it is not already present.
## @param $1 Array variable name.
## @param $2 Path.
__adrctl_add_unique_path() {
  local -n paths_ref="$1"
  local existing

  for existing in "${paths_ref[@]}"; do
    [[ ${existing} == "$2" ]] && return 0
  done
  paths_ref+=("$2")
}

## @fn __adrctl_select_filename_pattern()
## @brief Applies CLI-over-configuration filename pattern precedence.
## @param $1 CLI pattern.
## @param $2 CLI presence flag.
## @param $3 Output variable.
__adrctl_select_filename_pattern() {
  if (( $2 )); then
    printf -v "$3" '%s' "$1"
  else
    __adrctl_config_effective_filename_pattern "$3"
  fi
}

## @fn __adrctl_invoke_editor()
## @brief Opens a created ADR using VISUAL, EDITOR, or the no-op fallback.
## @param $1 ADR pathname.
## @retval 0 No editor was configured or the editor succeeded.
## @retval 1 The configured editor failed.
__adrctl_invoke_editor() {
  local command_text
  local -a command_parts

  if [[ -v VISUAL && -n ${VISUAL} ]]; then
    command_text="${VISUAL}"
  elif [[ -v EDITOR && -n ${EDITOR} ]]; then
    command_text="${EDITOR}"
  else
    return 0
  fi

  read -r -a command_parts <<<"${command_text}"
  (( ${#command_parts[@]} > 0 )) || return 0
  "${command_parts[@]}" "$1"
}

## @fn __adrctl_page_help()
## @brief Writes help text through ADR_PAGER, PAGER, or `more`.
## @param $1 Complete help text.
## @retval 0 Pager completed successfully.
## @retval 1 Pager invocation failed.
__adrctl_page_help() {
  local text
  local pager_text
  local -a pager_parts

  text="$1"
  if [[ -v ADR_PAGER && -n ${ADR_PAGER} ]]; then
    pager_text="${ADR_PAGER}"
  elif [[ -v PAGER && -n ${PAGER} ]]; then
    pager_text="${PAGER}"
  else
    pager_text='more'
  fi

  read -r -a pager_parts <<<"${pager_text}"
  (( ${#pager_parts[@]} > 0 )) || {
    printf '%s' "${text}"
    return $?
  }

  printf '%s' "${text}" | "${pager_parts[@]}"
}

## @fn __adrctl_help_text()
## @brief Builds built-in help text for the requested command path.
## @param $1 Output variable.
## @param $2... Optional command/subcommand path.
## @retval 0 Help exists.
## @retval 2 Requested help subject is unknown.
__adrctl_help_text() {
  local output_name
  local invoked
  local subject
  local text

  output_name="$1"
  shift
  invoked="$(__adrctl_invoked_name)"
  subject="${1-}"
  text=''

  case "${subject}" in
    '')
      printf -v text '%s\n' \
        "Usage: ${invoked} [--project-root PATH] COMMAND [OPTION...]" \
        '' \
        'Commands:' \
        '  init [DIRECTORY]                       Initialize an ADR repository.' \
        '  new [OPTIONS] TITLE...                 Create a numbered ADR.' \
        '  link SOURCE LINK TARGET REVERSE-LINK   Add reciprocal ADR links.' \
        '  list                                   List ADR files.' \
        '  generate [toc|graph] [OPTIONS]         Generate ADR reports.' \
        '  upgrade-repository                     Upgrade recognized legacy ADR data.' \
        '  help [COMMAND [SUBCOMMAND...]]         Show help.' \
        '' \
        'Global informational forms:' \
        "  ${invoked} -h | --help" \
        "  ${invoked} --version"
      ;;
    init)
      printf -v text '%s\n' \
        "Usage: ${invoked} init [DIRECTORY]" \
        '' \
        'Initialize the current project with Architecture Decision Records.' \
        'DIRECTORY defaults to doc/adr.  A supplied directory is recorded in .adr-dir.'
      ;;
    new)
      printf -v text '%s\n' \
        "Usage: ${invoked} new [-s REFERENCE]... [-l TARGET:LINK:REVERSE-LINK]... [OPTIONS] TITLE..." \
        '' \
        'Options:' \
        '  -s REFERENCE                    Supersede an existing ADR.' \
        '  -l TARGET:LINK:REVERSE-LINK     Add reciprocal relationships.' \
        '  --template PATH                 Use an explicit body template.' \
        '  --filename-pattern PATTERN      Override the ADR filename pattern.' \
        '  --start-delimiter STRING        Set body-template start delimiter.' \
        '  --end-delimiter STRING          Set body-template end delimiter.'
      ;;
    link)
      printf -v text '%s\n' \
        "Usage: ${invoked} link SOURCE LINK TARGET REVERSE-LINK" \
        '' \
        'Add a relationship from SOURCE to TARGET and the reciprocal relationship.'
      ;;
    list)
      printf -v text '%s\n' "Usage: ${invoked} list"
      ;;
    generate)
      if [[ ${2-} == toc ]]; then
        printf -v text '%s\n' \
          "Usage: ${invoked} generate toc [-i INTRO_FILE] [-o OUTRO_FILE] [-p LINK_PREFIX]"
      elif [[ ${2-} == graph ]]; then
        printf -v text '%s\n' \
          "Usage: ${invoked} generate graph [-p LINK_PREFIX] [-e LINK_EXTENSION]"
      elif [[ -n ${2-} ]]; then
        return "${__adrctl_exit_usage}"
      else
        printf -v text '%s\n' \
          "Usage: ${invoked} generate [REPORT [OPTION...]]" \
          '' \
          'Reports:' \
          '  toc' \
          '  graph'
      fi
      ;;
    upgrade-repository)
      printf -v text '%s\n' "Usage: ${invoked} upgrade-repository"
      ;;
    *)
      return "${__adrctl_exit_usage}"
      ;;
  esac

  printf -v "${output_name}" '%s' "${text}"
}

## @fn __adrctl_command_help()
## @brief Implements `help` and pages the selected built-in help text.
## @param $@ Optional command/subcommand path.
## @retval 0 Help was displayed.
## @retval 1 Pager failed.
## @retval 2 Help subject is unknown.
__adrctl_command_help() {
  local text

  if ! __adrctl_help_text text "$@"; then
    __adrctl_fail_usage "unknown help subject: $*"
    return $?
  fi

  if ! __adrctl_page_help "${text}"; then
    __adrctl_fail_operational 'help pager failed'
    return $?
  fi
}

## @fn __adrctl_command_list()
## @brief Implements `list` using numeric ADR ordering.
## @retval 0 ADR paths were written.
## @retval 1 ADR directory does not exist or output failed.
__adrctl_command_list() {
  local -a files
  local path
  local display

  if [[ ! -d ${__adrctl_adr_dir} ]]; then
    __adrctl_fail_operational "ADR directory does not exist: ${__adrctl_adr_dir}"
    return $?
  fi

  declare -a files=()
  __adrctl_collect_adrs files

  for path in "${files[@]}"; do
    __adrctl_display_path "${path}" display || display="${path}"
    printf '%s\n' "${display}" || return "${__adrctl_exit_operational}"
  done
}

## @fn __adrctl_command_init()
## @brief Implements repository initialization and the bootstrap ADR.
## @param $1 Optional ADR directory argument.
## @retval 0 Repository was initialized.
## @retval 1 Initialization could not be completed safely.
## @retval 2 Too many arguments were supplied.
__adrctl_command_init() {
  local directory_arg
  local directory_set
  local target_dir
  local marker_value
  local marker_temp
  local marker_target
  local number
  local date
  local filename_pattern
  local filename
  local destination
  local prepared
  local display
  local -a existing
  local -A context

  if (( $# > 1 )); then
    __adrctl_fail_usage 'init accepts at most one DIRECTORY argument'
    return $?
  fi

  directory_arg="${1-}"
  directory_set=0
  [[ $# -eq 1 ]] && directory_set=1

  if (( directory_set )); then
    if [[ -z ${directory_arg} ]]; then
      __adrctl_fail_usage 'init DIRECTORY must not be empty'
      return $?
    fi
    target_dir="$(__adrctl_join_path "${__adrctl_project_root}" "${directory_arg}")"
    marker_value="${directory_arg}"
  else
    target_dir="${__adrctl_adr_dir}"
    marker_value=''
  fi

  __adrctl_adr_dir="${target_dir%/}"
  declare -a existing=()
  __adrctl_collect_adrs existing
  if (( ${#existing[@]} > 0 )); then
    __adrctl_fail_operational "ADR repository already contains records: ${__adrctl_adr_dir}"
    return $?
  fi

  number=1
  date="$(__adrctl_current_date)"
  declare -A context=()
  if ! __adrctl_populate_context context \
    "${number}" 'Record architecture decisions' Accepted "${date}"; then
    __adrctl_fail_operational 'failed to prepare initialization template context'
    return $?
  fi

  __adrctl_config_effective_filename_pattern filename_pattern
  if ! __adrctl_render_filename context "${filename_pattern}" filename; then
    return $?
  fi

  destination="${__adrctl_adr_dir}/${filename}"
  [[ ! -e ${destination} ]] || {
    __adrctl_fail_operational "ADR destination already exists: ${destination}"
    return $?
  }

  if ! mkdir -p "${__adrctl_adr_dir}"; then
    __adrctl_fail_operational "cannot create ADR directory: ${__adrctl_adr_dir}"
    return $?
  fi

  __adrctl_temp_path "${destination}" init prepared
  if ! __adrctl_render_body_to_path context init '' '' '' "${prepared}"; then
    rm -f "${prepared}"
    __adrctl_fail_operational 'failed to render initialization ADR'
    return $?
  fi

  if (( directory_set )); then
    marker_target="${__adrctl_project_root}/.adr-dir"
    marker_temp="${__adrctl_project_root}/.adr-dir.adrctl.$$.$RANDOM.tmp"
    if ! printf '%s\n' "${marker_value}" >"${marker_temp}"; then
      rm -f "${prepared}" "${marker_temp}"
      __adrctl_fail_operational "cannot prepare ${marker_target}"
      return $?
    fi
  else
    marker_target=''
    marker_temp=''
  fi

  if ! __adrctl_publish_new_file "${prepared}" "${destination}"; then
    rm -f "${prepared}" "${marker_temp}"
    __adrctl_fail_operational \
      "ADR destination appeared during initialization: ${destination}"
    return $?
  fi

  if [[ -n ${marker_target} ]]; then
    if ! mv "${marker_temp}" "${marker_target}"; then
      __adrctl_fail_operational "failed to write legacy ADR directory marker: ${marker_target}"
      return $?
    fi
  fi

  __adrctl_display_path "${destination}" display || display="${destination}"
  printf '%s\n' "${display}"
}

## @fn __adrctl_parse_link_spec()
## @brief Parses TARGET:LINK:REVERSE-LINK using exactly two separators.
## @param $1 Encoded specification.
## @param $2 Output target variable.
## @param $3 Output forward relationship variable.
## @param $4 Output reverse relationship variable.
## @retval 0 Exactly three non-empty fields were parsed.
## @retval 2 The specification is malformed.
__adrctl_parse_link_spec() {
  local spec
  local rest
  local target
  local forward
  local reverse

  spec="$1"
  [[ ${spec} == *:*:* ]] || return "${__adrctl_exit_usage}"

  target="${spec%%:*}"
  rest="${spec#*:}"
  forward="${rest%%:*}"
  reverse="${rest#*:}"

  if [[ ${reverse} == *:* || -z ${target} || -z ${forward} || -z ${reverse} ]]; then
    return "${__adrctl_exit_usage}"
  fi

  printf -v "$2" '%s' "${target}"
  printf -v "$3" '%s' "${forward}"
  printf -v "$4" '%s' "${reverse}"
}

## @fn __adrctl_command_new()
## @brief Implements ADR creation, superseding, reciprocal links, and editor use.
## @retval 0 ADR was created and editor completed successfully.
## @retval 1 Operational failure.
## @retval 2 Invalid command usage.
__adrctl_command_new() {
  local -a superseded_refs
  local -a link_specs
  local -a title_parts
  local -a superseded_paths
  local -a link_target_paths
  local -a link_forward
  local -a link_reverse
  local cli_template
  local cli_template_set
  local cli_filename_pattern
  local cli_filename_pattern_set
  local cli_start
  local cli_start_set
  local cli_end
  local cli_end_set
  local arg
  local title
  local number
  local date
  local filename_pattern
  local filename
  local destination
  local template_kind
  local template_value
  local start_delimiter
  local end_delimiter
  local raw_temp
  local new_temp
  local display
  local index
  local target_ref
  local forward
  local reverse
  local target
  local relationship
  local encoded
  local temp
  local path
  local -a new_links
  local -a target_order
  local -a decoded_links
  local -a prepared_paths
  local -a prepared_temps
  local -A target_links
  local -A target_remove
  local -A context

  declare -a superseded_refs=()
  declare -a link_specs=()
  declare -a title_parts=()
  cli_template=''
  cli_template_set=0
  cli_filename_pattern=''
  cli_filename_pattern_set=0
  cli_start=''
  cli_start_set=0
  cli_end=''
  cli_end_set=0

  while (( $# > 0 )); do
    arg="$1"
    case "${arg}" in
      -s)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'new option -s expects REFERENCE'
          return $?
        }
        superseded_refs+=("$2")
        shift 2
        ;;
      -l)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'new option -l expects TARGET:LINK:REVERSE-LINK'
          return $?
        }
        link_specs+=("$2")
        shift 2
        ;;
      --template)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'new option --template expects PATH'
          return $?
        }
        (( cli_template_set == 0 )) || {
          __adrctl_fail_usage 'new accepts --template at most once'
          return $?
        }
        cli_template="$2"
        cli_template_set=1
        shift 2
        ;;
      --filename-pattern)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'new option --filename-pattern expects PATTERN'
          return $?
        }
        (( cli_filename_pattern_set == 0 )) || {
          __adrctl_fail_usage 'new accepts --filename-pattern at most once'
          return $?
        }
        cli_filename_pattern="$2"
        cli_filename_pattern_set=1
        shift 2
        ;;
      --start-delimiter)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'new option --start-delimiter expects STRING'
          return $?
        }
        (( cli_start_set == 0 )) || {
          __adrctl_fail_usage 'new accepts --start-delimiter at most once'
          return $?
        }
        cli_start="$2"
        cli_start_set=1
        shift 2
        ;;
      --end-delimiter)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'new option --end-delimiter expects STRING'
          return $?
        }
        (( cli_end_set == 0 )) || {
          __adrctl_fail_usage 'new accepts --end-delimiter at most once'
          return $?
        }
        cli_end="$2"
        cli_end_set=1
        shift 2
        ;;
      --)
        shift
        while (( $# > 0 )); do
          title_parts+=("$1")
          shift
        done
        ;;
      -*)
        __adrctl_fail_usage "unknown new option: ${arg}"
        return $?
        ;;
      *)
        while (( $# > 0 )); do
          title_parts+=("$1")
          shift
        done
        ;;
    esac
  done

  if (( ${#title_parts[@]} == 0 )); then
    __adrctl_fail_usage 'new requires a title'
    return $?
  fi

  title="${title_parts[*]}"
  [[ -n ${title} ]] || {
    __adrctl_fail_usage 'new requires a non-empty title'
    return $?
  }

  __adrctl_config_validate_pair \
    "${cli_start}" "${cli_start_set}" \
    "${cli_end}" "${cli_end_set}" \
    'command line' || return $?

  declare -a superseded_paths=()
  for target_ref in "${superseded_refs[@]}"; do
    __adrctl_resolve_reference "${target_ref}" target || return $?
    __adrctl_has_status_section "${target}" || {
      __adrctl_fail_operational "ADR has no ## Status section: ${target##*/}"
      return $?
    }
    superseded_paths+=("${target}")
  done

  declare -a link_target_paths=()
  declare -a link_forward=()
  declare -a link_reverse=()
  for arg in "${link_specs[@]}"; do
    if ! __adrctl_parse_link_spec "${arg}" target_ref forward reverse; then
      __adrctl_fail_usage "malformed -l specification: ${arg}"
      return $?
    fi
    __adrctl_resolve_reference "${target_ref}" target || return $?
    __adrctl_has_status_section "${target}" || {
      __adrctl_fail_operational "ADR has no ## Status section: ${target##*/}"
      return $?
    }
    link_target_paths+=("${target}")
    link_forward+=("${forward}")
    link_reverse+=("${reverse}")
  done

  __adrctl_next_number number
  date="$(__adrctl_current_date)"
  declare -A context=()
  if ! __adrctl_populate_context context "${number}" "${title}" Accepted "${date}"; then
    __adrctl_fail_operational 'failed to prepare ADR render context'
    return $?
  fi

  __adrctl_select_filename_pattern \
    "${cli_filename_pattern}" "${cli_filename_pattern_set}" filename_pattern
  __adrctl_render_filename context "${filename_pattern}" filename || return $?
  destination="${__adrctl_adr_dir}/${filename}"

  [[ ! -e ${destination} ]] || {
    __adrctl_fail_operational "ADR destination already exists: ${destination}"
    return $?
  }

  __adrctl_select_template_source \
    "${cli_template}" "${cli_template_set}" template_kind template_value || return $?
  __adrctl_select_body_delimiters \
    context "${template_kind}" "${template_value}" \
    "${cli_start}" "${cli_start_set}" "${cli_end}" "${cli_end_set}" \
    start_delimiter end_delimiter || return $?

  declare -a new_links=()
  declare -a target_order=()
  declare -A target_links=()
  declare -A target_remove=()

  for target in "${superseded_paths[@]}"; do
    __adrctl_relationship_line 'Supercedes' "${target}" relationship || {
      __adrctl_fail_operational "cannot read ADR title: ${target##*/}"
      return $?
    }
    new_links+=("${relationship}")

    relationship="Superceded by [${title}](${filename})"
    encoded="${target_links[${target}]-}"
    __adrctl_append_encoded_line "${encoded}" "${relationship}" encoded
    target_links["${target}"]="${encoded}"
    target_remove["${target}"]='Accepted'
    __adrctl_add_unique_path target_order "${target}"
  done

  for (( index = 0; index < ${#link_target_paths[@]}; index++ )); do
    target="${link_target_paths[index]}"
    __adrctl_relationship_line "${link_forward[index]}" "${target}" relationship || {
      __adrctl_fail_operational "cannot read ADR title: ${target##*/}"
      return $?
    }
    new_links+=("${relationship}")

    relationship="${link_reverse[index]} [${title}](${filename})"
    encoded="${target_links[${target}]-}"
    __adrctl_append_encoded_line "${encoded}" "${relationship}" encoded
    target_links["${target}"]="${encoded}"
    __adrctl_add_unique_path target_order "${target}"
  done

  if ! mkdir -p "${__adrctl_adr_dir}"; then
    __adrctl_fail_operational "cannot create ADR directory: ${__adrctl_adr_dir}"
    return $?
  fi

  __adrctl_temp_path "${destination}" raw raw_temp
  if ! __adrctl_render_body_to_path \
    context "${template_kind}" "${template_value}" \
    "${start_delimiter}" "${end_delimiter}" "${raw_temp}"; then
    rm -f "${raw_temp}"
    __adrctl_fail_operational 'failed to render ADR body'
    return $?
  fi

  new_temp="${raw_temp}"
  if (( ${#new_links[@]} > 0 )); then
    __adrctl_temp_path "${destination}" new new_temp
    if ! __adrctl_prepare_status_mutation \
      "${raw_temp}" "${new_temp}" '' new_links; then
      rm -f "${raw_temp}" "${new_temp}"
      __adrctl_fail_operational 'new ADR template has no usable ## Status section'
      return $?
    fi
    rm -f "${raw_temp}"
  fi

  declare -a prepared_paths=()
  declare -a prepared_temps=()
  for path in "${target_order[@]}"; do
    __adrctl_decode_lines "${target_links[${path}]-}" decoded_links
    __adrctl_temp_path "${path}" existing temp
    if ! __adrctl_prepare_status_mutation \
      "${path}" "${temp}" "${target_remove[${path}]-}" decoded_links; then
      rm -f "${new_temp}" "${prepared_temps[@]}" "${temp}"
      __adrctl_fail_operational "cannot prepare ADR mutation: ${path##*/}"
      return $?
    fi
    prepared_paths+=("${path}")
    prepared_temps+=("${temp}")
  done

  if ! __adrctl_publish_new_file "${new_temp}" "${destination}"; then
    rm -f "${new_temp}" "${prepared_temps[@]}"
    __adrctl_fail_operational \
      "ADR destination appeared during number allocation: ${destination}"
    return $?
  fi

  for (( index = 0; index < ${#prepared_paths[@]}; index++ )); do
    if ! __adrctl_atomic_replace "${prepared_temps[index]}" "${prepared_paths[index]}"; then
      __adrctl_fail_operational \
        "failed to replace prepared ADR: ${prepared_paths[index]##*/}"
      return $?
    fi
  done

  if ! __adrctl_invoke_editor "${destination}"; then
    __adrctl_fail_operational "editor failed for ${destination}"
    return $?
  fi

  __adrctl_display_path "${destination}" display || display="${destination}"
  printf '%s\n' "${display}"
}

## @fn __adrctl_command_link()
## @brief Implements reciprocal relationship creation between two ADRs.
## @retval 0 Relationships were written.
## @retval 1 References or mutations failed.
## @retval 2 Command arguments are invalid.
__adrctl_command_link() {
  local source_ref
  local forward
  local target_ref
  local reverse
  local source
  local target
  local forward_line
  local reverse_line
  local source_temp
  local target_temp
  local -a source_links
  local -a target_links

  if (( $# != 4 )); then
    __adrctl_fail_usage 'link expects SOURCE LINK TARGET REVERSE-LINK'
    return $?
  fi

  source_ref="$1"
  forward="$2"
  target_ref="$3"
  reverse="$4"

  __adrctl_resolve_reference "${source_ref}" source || return $?
  __adrctl_resolve_reference "${target_ref}" target || return $?
  __adrctl_has_status_section "${source}" || {
    __adrctl_fail_operational "ADR has no ## Status section: ${source##*/}"
    return $?
  }
  __adrctl_has_status_section "${target}" || {
    __adrctl_fail_operational "ADR has no ## Status section: ${target##*/}"
    return $?
  }

  __adrctl_relationship_line "${forward}" "${target}" forward_line || {
    __adrctl_fail_operational "cannot read ADR title: ${target##*/}"
    return $?
  }
  __adrctl_relationship_line "${reverse}" "${source}" reverse_line || {
    __adrctl_fail_operational "cannot read ADR title: ${source##*/}"
    return $?
  }

  if [[ ${source} == "${target}" ]]; then
    declare -a source_links=("${forward_line}" "${reverse_line}")
    __adrctl_temp_path "${source}" link source_temp
    if ! __adrctl_prepare_status_mutation "${source}" "${source_temp}" '' source_links; then
      rm -f "${source_temp}"
      __adrctl_fail_operational "cannot prepare ADR mutation: ${source##*/}"
      return $?
    fi
    __adrctl_atomic_replace "${source_temp}" "${source}" || {
      __adrctl_fail_operational "failed to replace ADR: ${source##*/}"
      return $?
    }
    return 0
  fi

  declare -a source_links=("${forward_line}")
  declare -a target_links=("${reverse_line}")
  __adrctl_temp_path "${source}" source source_temp
  __adrctl_temp_path "${target}" target target_temp

  if ! __adrctl_prepare_status_mutation "${source}" "${source_temp}" '' source_links; then
    rm -f "${source_temp}" "${target_temp}"
    __adrctl_fail_operational "cannot prepare ADR mutation: ${source##*/}"
    return $?
  fi
  if ! __adrctl_prepare_status_mutation "${target}" "${target_temp}" '' target_links; then
    rm -f "${source_temp}" "${target_temp}"
    __adrctl_fail_operational "cannot prepare ADR mutation: ${target##*/}"
    return $?
  fi

  __adrctl_atomic_replace "${source_temp}" "${source}" || {
    rm -f "${source_temp}" "${target_temp}"
    __adrctl_fail_operational "failed to replace ADR: ${source##*/}"
    return $?
  }
  __adrctl_atomic_replace "${target_temp}" "${target}" || {
    rm -f "${target_temp}"
    __adrctl_fail_operational "failed to replace ADR: ${target##*/}"
    return $?
  }
}

## @fn __adrctl_command_generate_toc()
## @brief Emits the Markdown table-of-contents report.
__adrctl_command_generate_toc() {
  local intro
  local outro
  local prefix
  local arg
  local -a files
  local path
  local title

  intro=''
  outro=''
  prefix=''

  while (( $# > 0 )); do
    arg="$1"
    case "${arg}" in
      -i)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'generate toc -i expects INTRO_FILE'
          return $?
        }
        intro="$2"
        shift 2
        ;;
      -o)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'generate toc -o expects OUTRO_FILE'
          return $?
        }
        outro="$2"
        shift 2
        ;;
      -p)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'generate toc -p expects LINK_PREFIX'
          return $?
        }
        prefix="$2"
        shift 2
        ;;
      *)
        __adrctl_fail_usage "unknown generate toc option: ${arg}"
        return $?
        ;;
    esac
  done

  if [[ -n ${intro} && ! -r ${intro} ]]; then
    __adrctl_fail_operational "cannot read TOC intro file: ${intro}"
    return $?
  fi
  if [[ -n ${outro} && ! -r ${outro} ]]; then
    __adrctl_fail_operational "cannot read TOC outro file: ${outro}"
    return $?
  fi
  [[ -d ${__adrctl_adr_dir} ]] || {
    __adrctl_fail_operational "ADR directory does not exist: ${__adrctl_adr_dir}"
    return $?
  }

  declare -a files=()
  __adrctl_collect_adrs files
  for path in "${files[@]}"; do
    __adrctl_read_title "${path}" title || {
      __adrctl_fail_operational "cannot read ADR title: ${path##*/}"
      return $?
    }
  done

  printf '# Architecture Decision Records\n\n' || return "${__adrctl_exit_operational}"
  if [[ -n ${intro} ]]; then
    cat "${intro}" || return "${__adrctl_exit_operational}"
    printf '\n' || return "${__adrctl_exit_operational}"
  fi

  for path in "${files[@]}"; do
    __adrctl_read_title "${path}" title || return "${__adrctl_exit_operational}"
    printf '* [%s](%s%s)\n' "${title}" "${prefix}" "${path##*/}" || \
      return "${__adrctl_exit_operational}"
  done

  if [[ -n ${outro} ]]; then
    printf '\n' || return "${__adrctl_exit_operational}"
    cat "${outro}" || return "${__adrctl_exit_operational}"
  fi
}

## @fn __adrctl_dot_escape()
## @brief Escapes backslash and double quote for a Graphviz quoted string.
## @param $1 Raw text.
## @param $2 Output variable.
__adrctl_dot_escape() {
  local value

  value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf -v "$2" '%s' "${value}"
}

## @fn __adrctl_emit_graph_relationships()
## @brief Emits Graphviz edges derived from status-section Markdown links.
## @param $1 Source ADR path.
## @param $2 Source logical number.
__adrctl_emit_graph_relationships() {
  local source
  local source_number
  local line
  local in_status
  local relation
  local target_digits
  local target_number
  local escaped_relation

  source="$1"
  source_number="$2"
  in_status=0

  while IFS= read -r line || [[ -n ${line} ]]; do
    if [[ ${line} == '## Status' ]]; then
      in_status=1
      continue
    fi
    if (( in_status )) && [[ ${line} == '## '* ]]; then
      break
    fi
    (( in_status )) || continue

    if [[ ${line} =~ ^(.+)[[:space:]]\[[^]]*\]\(([0-9]+)-[^)]*\.md\)$ ]]; then
      relation="${BASH_REMATCH[1]}"
      target_digits="${BASH_REMATCH[2]}"
      [[ ${relation} == *' by' ]] && continue
      target_number=$((10#${target_digits}))
      __adrctl_dot_escape "${relation}" escaped_relation
      printf '  _%d -> _%d [label="%s", weight=0];\n' \
        "${source_number}" "${target_number}" "${escaped_relation}" || return 1
    fi
  done <"${source}"
}

## @fn __adrctl_command_generate_graph()
## @brief Emits Graphviz DOT for ADR sequence and status relationships.
__adrctl_command_generate_graph() {
  local prefix
  local extension
  local arg
  local -a files
  local path
  local number
  local previous_number
  local title
  local escaped_title
  local url
  local escaped_url

  prefix=''
  extension='.html'

  while (( $# > 0 )); do
    arg="$1"
    case "${arg}" in
      -p)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'generate graph -p expects LINK_PREFIX'
          return $?
        }
        prefix="$2"
        shift 2
        ;;
      -e)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'generate graph -e expects LINK_EXTENSION'
          return $?
        }
        extension="$2"
        shift 2
        ;;
      *)
        __adrctl_fail_usage "unknown generate graph option: ${arg}"
        return $?
        ;;
    esac
  done

  [[ -d ${__adrctl_adr_dir} ]] || {
    __adrctl_fail_operational "ADR directory does not exist: ${__adrctl_adr_dir}"
    return $?
  }

  declare -a files=()
  __adrctl_collect_adrs files
  for path in "${files[@]}"; do
    __adrctl_file_number "${path}" number || continue
    __adrctl_read_title "${path}" title || {
      __adrctl_fail_operational "cannot read ADR title: ${path##*/}"
      return $?
    }
  done

  printf 'digraph {\n  node [shape=plaintext];\n  subgraph {\n' || return 1
  previous_number=''
  for path in "${files[@]}"; do
    __adrctl_file_number "${path}" number || continue
    __adrctl_read_title "${path}" title || return 1
    __adrctl_dot_escape "${title}" escaped_title
    url="${prefix}${path##*/}"
    url="${url%.md}${extension}"
    __adrctl_dot_escape "${url}" escaped_url
    printf '    _%d [label="%s"; URL="%s"];\n' \
      "${number}" "${escaped_title}" "${escaped_url}" || return 1

    if [[ -n ${previous_number} ]] && (( number == previous_number + 1 )); then
      printf '    _%d -> _%d [style="dotted", weight=1];\n' \
        "${previous_number}" "${number}" || return 1
    fi
    previous_number="${number}"
  done
  printf '  }\n' || return 1

  for path in "${files[@]}"; do
    __adrctl_file_number "${path}" number || continue
    __adrctl_emit_graph_relationships "${path}" "${number}" || return 1
  done

  printf '}\n'
}

## @fn __adrctl_command_generate()
## @brief Dispatches built-in report generators.
__adrctl_command_generate() {
  local report

  if (( $# == 0 )); then
    printf '%s\n' graph toc
    return $?
  fi

  report="$1"
  shift
  case "${report}" in
    toc)
      __adrctl_command_generate_toc "$@"
      ;;
    graph)
      __adrctl_command_generate_graph "$@"
      ;;
    *)
      __adrctl_fail_usage "unknown report: ${report}"
      return $?
      ;;
  esac
}

## @fn __adrctl_prepare_upgrade_file()
## @brief Prepares one ADR with DD/MM/YYYY Date lines converted to ISO form.
## @param $1 Source path.
## @param $2 Prepared output path.
## @retval 0 File was prepared.
## @retval 1 Output failed.
__adrctl_prepare_upgrade_file() {
  local line

  : >"$2" || return 1
  while IFS= read -r line || [[ -n ${line} ]]; do
    if [[ ${line} =~ ^Date:[[:space:]]+([0-9]{2})/([0-9]{2})/([0-9]{4})(.*)$ ]]; then
      line="Date: ${BASH_REMATCH[3]}-${BASH_REMATCH[2]}-${BASH_REMATCH[1]}${BASH_REMATCH[4]}"
    fi
    printf '%s\n' "${line}" >>"$2" || return 1
  done <"$1"
}

## @fn __adrctl_command_upgrade_repository()
## @brief Converts recognized legacy ADR Date lines to ISO 8601 form.
__adrctl_command_upgrade_repository() {
  local -a files
  local -a temps
  local path
  local temp
  local index

  (( $# == 0 )) || {
    __adrctl_fail_usage 'upgrade-repository accepts no arguments'
    return $?
  }

  [[ -d ${__adrctl_adr_dir} ]] || {
    __adrctl_fail_operational "ADR directory does not exist: ${__adrctl_adr_dir}"
    return $?
  }

  declare -a files=()
  declare -a temps=()
  __adrctl_collect_adrs files

  for path in "${files[@]}"; do
    __adrctl_temp_path "${path}" upgrade temp
    if ! __adrctl_prepare_upgrade_file "${path}" "${temp}"; then
      rm -f "${temps[@]}" "${temp}"
      __adrctl_fail_operational "cannot prepare repository upgrade: ${path##*/}"
      return $?
    fi
    temps+=("${temp}")
  done

  for (( index = 0; index < ${#files[@]}; index++ )); do
    if ! __adrctl_atomic_replace "${temps[index]}" "${files[index]}"; then
      __adrctl_fail_operational "failed to replace upgraded ADR: ${files[index]##*/}"
      return $?
    fi
  done
}

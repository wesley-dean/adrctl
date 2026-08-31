## @file lib/graph.bash
## @brief Builds one ADR relationship graph model and serializes it as DOT or Mermaid.

## @fn __adrctl_graph_append_relationships()
## @brief Adds graph relationship edges found in one ADR Status section.
## @param $1 Source ADR path.
## @param $2 Source logical ADR number.
## @param $3 Edge-source array variable name.
## @param $4 Edge-target array variable name.
## @param $5 Edge-label array variable name.
## @param $6 Edge-kind array variable name.
## @retval 0 Relationship discovery completed.
## @retval 2 Discovery configuration failed while interpreting a target basename.
__adrctl_graph_append_relationships() {
  local source
  local source_number
  local -n edge_sources_ref="$3"
  local -n edge_targets_ref="$4"
  local -n edge_labels_ref="$5"
  local -n edge_kinds_ref="$6"
  local line
  local in_status
  local relation
  local target_base
  local target_number
  local status
  local relationship_regex

  source="$1"
  source_number="$2"
  in_status=0
  relationship_regex='^(.+)[[:space:]]\[[^]]*\]\(([^/()]+)\)$'

  while IFS= read -r line || [[ -n ${line} ]]; do
    if [[ ${line} == '## Status' ]]; then
      in_status=1
      continue
    fi
    if (( in_status )) && [[ ${line} == '## '* ]]; then
      break
    fi
    (( in_status )) || continue

    if [[ ${line} =~ ${relationship_regex} ]]; then
      relation="${BASH_REMATCH[1]}"
      target_base="${BASH_REMATCH[2]}"
      [[ ${relation} == *' by' ]] && continue

      if __adrctl_match_adr_basename "${target_base}" target_number; then
        edge_sources_ref+=("${source_number}")
        edge_targets_ref+=("${target_number}")
        edge_labels_ref+=("${relation}")
        edge_kinds_ref+=('relationship')
      else
        status=$?
        (( status == 1 )) || return "${status}"
      fi
    fi
  done <"${source}"
}

## @fn __adrctl_graph_build_model()
## @brief Builds the ordered node and edge model shared by graph serializers.
## @param $1 Node-number array variable name.
## @param $2 Node-title array variable name.
## @param $3 Node-basename array variable name.
## @param $4 Edge-source array variable name.
## @param $5 Edge-target array variable name.
## @param $6 Edge-label array variable name.
## @param $7 Edge-kind array variable name.
## @retval 0 The complete graph model was built.
## @retval 1 A managed ADR title could not be read.
## @retval 2 Discovery configuration is invalid.
__adrctl_graph_build_model() {
  local -n node_numbers_ref="$1"
  local -n node_titles_ref="$2"
  local -n node_bases_ref="$3"
  local -n edge_sources_ref="$4"
  local -n edge_targets_ref="$5"
  local -n edge_labels_ref="$6"
  local -n edge_kinds_ref="$7"
  local -a files
  local path
  local number
  local previous_number
  local title

  node_numbers_ref=()
  node_titles_ref=()
  node_bases_ref=()
  edge_sources_ref=()
  edge_targets_ref=()
  edge_labels_ref=()
  edge_kinds_ref=()

  declare -a files=()
  __adrctl_collect_adrs files || return $?

  previous_number=''
  for path in "${files[@]}"; do
    __adrctl_file_number "${path}" number || return $?
    __adrctl_read_title "${path}" title || {
      __adrctl_fail_operational "cannot read ADR title: ${path##*/}"
      return $?
    }

    node_numbers_ref+=("${number}")
    node_titles_ref+=("${title}")
    node_bases_ref+=("${path##*/}")

    if [[ -n ${previous_number} ]] && (( number == previous_number + 1 )); then
      edge_sources_ref+=("${previous_number}")
      edge_targets_ref+=("${number}")
      edge_labels_ref+=('')
      edge_kinds_ref+=('sequence')
    fi
    previous_number="${number}"
  done

  for path in "${files[@]}"; do
    __adrctl_file_number "${path}" number || return $?
    __adrctl_graph_append_relationships \
      "${path}" "${number}" "$4" "$5" "$6" "$7" || return $?
  done
}

## @fn __adrctl_graph_dot_escape()
## @brief Escapes backslash and double quote for a Graphviz quoted string.
## @param $1 Raw text.
## @param $2 Output variable.
__adrctl_graph_dot_escape() {
  local value

  value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf -v "$2" '%s' "${value}"
}

## @fn __adrctl_graph_mermaid_escape()
## @brief Escapes text for Mermaid double-quoted labels and link strings.
## @param $1 Raw text.
## @param $2 Output variable.
__adrctl_graph_mermaid_escape() {
  local value

  value="$1"
  value="${value//&/\&amp;}"
  value="${value//\"/\&quot;}"
  value="${value//</\&lt;}"
  value="${value//>/\&gt;}"
  printf -v "$2" '%s' "${value}"
}

## @fn __adrctl_graph_url()
## @brief Builds one graph node URL from prefix, basename, and extension.
## @param $1 Link prefix.
## @param $2 ADR basename.
## @param $3 Link extension.
## @param $4 Output variable.
__adrctl_graph_url() {
  local url

  url="$1$2"
  url="${url%.md}$3"
  printf -v "$4" '%s' "${url}"
}

## @fn __adrctl_graph_emit_dot()
## @brief Serializes one graph model as compatibility Graphviz DOT.
## @param $1 Node-number array variable name.
## @param $2 Node-title array variable name.
## @param $3 Node-basename array variable name.
## @param $4 Edge-source array variable name.
## @param $5 Edge-target array variable name.
## @param $6 Edge-label array variable name.
## @param $7 Edge-kind array variable name.
## @param $8 Link prefix.
## @param $9 Link extension.
## @retval 0 DOT was written to standard output.
## @retval 1 Output failed.
__adrctl_graph_emit_dot() {
  local -n node_numbers_ref="$1"
  local -n node_titles_ref="$2"
  local -n node_bases_ref="$3"
  local -n edge_sources_ref="$4"
  local -n edge_targets_ref="$5"
  local -n edge_labels_ref="$6"
  local -n edge_kinds_ref="$7"
  local prefix
  local extension
  local node_index
  local edge_index
  local number
  local escaped_title
  local escaped_url
  local escaped_relation
  local url

  prefix="$8"
  extension="$9"

  printf 'digraph {\n  node [shape=plaintext];\n  subgraph {\n' || return 1
  for (( node_index = 0; node_index < ${#node_numbers_ref[@]}; node_index++ )); do
    number="${node_numbers_ref[node_index]}"
    __adrctl_graph_dot_escape "${node_titles_ref[node_index]}" escaped_title
    __adrctl_graph_url \
      "${prefix}" "${node_bases_ref[node_index]}" "${extension}" url
    __adrctl_graph_dot_escape "${url}" escaped_url
    printf '    _%d [label="%s"; URL="%s"];\n' \
      "${number}" "${escaped_title}" "${escaped_url}" || return 1

    for (( edge_index = 0; edge_index < ${#edge_sources_ref[@]}; edge_index++ )); do
      [[ ${edge_kinds_ref[edge_index]} == sequence ]] || continue
      (( edge_targets_ref[edge_index] == number )) || continue
      printf '    _%d -> _%d [style="dotted", weight=1];\n' \
        "${edge_sources_ref[edge_index]}" "${edge_targets_ref[edge_index]}" || return 1
    done
  done
  printf '  }\n' || return 1

  for (( edge_index = 0; edge_index < ${#edge_sources_ref[@]}; edge_index++ )); do
    [[ ${edge_kinds_ref[edge_index]} == relationship ]] || continue
    __adrctl_graph_dot_escape "${edge_labels_ref[edge_index]}" escaped_relation
    printf '  _%d -> _%d [label="%s", weight=0];\n' \
      "${edge_sources_ref[edge_index]}" "${edge_targets_ref[edge_index]}" \
      "${escaped_relation}" || return 1
  done

  printf '}\n'
}

## @fn __adrctl_graph_emit_mermaid()
## @brief Serializes one graph model as raw Mermaid flowchart source.
## @param $1 Node-number array variable name.
## @param $2 Node-title array variable name.
## @param $3 Node-basename array variable name.
## @param $4 Edge-source array variable name.
## @param $5 Edge-target array variable name.
## @param $6 Edge-label array variable name.
## @param $7 Edge-kind array variable name.
## @param $8 Link prefix.
## @param $9 Link extension.
## @retval 0 Mermaid source was written to standard output.
## @retval 1 Output failed.
__adrctl_graph_emit_mermaid() {
  local -n node_numbers_ref="$1"
  local -n node_titles_ref="$2"
  local -n node_bases_ref="$3"
  local -n edge_sources_ref="$4"
  local -n edge_targets_ref="$5"
  local -n edge_labels_ref="$6"
  local -n edge_kinds_ref="$7"
  local prefix
  local extension
  local node_index
  local edge_index
  local escaped_title
  local escaped_relation
  local escaped_url
  local url

  prefix="$8"
  extension="$9"

  printf 'flowchart TD\n' || return 1
  for (( node_index = 0; node_index < ${#node_numbers_ref[@]}; node_index++ )); do
    __adrctl_graph_mermaid_escape "${node_titles_ref[node_index]}" escaped_title
    printf '  _%d["%s"]\n' \
      "${node_numbers_ref[node_index]}" "${escaped_title}" || return 1
  done

  for (( edge_index = 0; edge_index < ${#edge_sources_ref[@]}; edge_index++ )); do
    if [[ ${edge_kinds_ref[edge_index]} == sequence ]]; then
      printf '  _%d -.-> _%d\n' \
        "${edge_sources_ref[edge_index]}" "${edge_targets_ref[edge_index]}" || return 1
      continue
    fi

    __adrctl_graph_mermaid_escape "${edge_labels_ref[edge_index]}" escaped_relation
    printf '  _%d -->|"%s"| _%d\n' \
      "${edge_sources_ref[edge_index]}" "${escaped_relation}" \
      "${edge_targets_ref[edge_index]}" || return 1
  done

  for (( node_index = 0; node_index < ${#node_numbers_ref[@]}; node_index++ )); do
    __adrctl_graph_url \
      "${prefix}" "${node_bases_ref[node_index]}" "${extension}" url
    __adrctl_graph_mermaid_escape "${url}" escaped_url
    printf '  click _%d "%s"\n' \
      "${node_numbers_ref[node_index]}" "${escaped_url}" || return 1
  done
}

## @fn __adrctl_command_generate_graph()
## @brief Emits the ADR relationship graph in the requested serialization format.
## @param $@ Graph options: `-p`, `-e`, and `--format dot|mermaid`.
## @retval 0 Graph source was written.
## @retval 1 Graph discovery or output failed.
## @retval 2 Graph options are invalid.
__adrctl_command_generate_graph() {
  local prefix
  local extension
  local format
  local format_set
  local arg
  local -a node_numbers
  local -a node_titles
  local -a node_bases
  local -a edge_sources
  local -a edge_targets
  local -a edge_labels
  local -a edge_kinds

  prefix=''
  extension='.html'
  format='dot'
  format_set=0

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
      --format)
        (( $# >= 2 )) || {
          __adrctl_fail_usage 'generate graph --format expects FORMAT'
          return $?
        }
        (( format_set == 0 )) || {
          __adrctl_fail_usage 'generate graph accepts --format at most once'
          return $?
        }
        format="$2"
        format_set=1
        shift 2
        ;;
      *)
        __adrctl_fail_usage "unknown generate graph option: ${arg}"
        return $?
        ;;
    esac
  done

  case "${format}" in
    dot | mermaid) ;;
    *)
      __adrctl_fail_usage "unsupported graph format: ${format}"
      return $?
      ;;
  esac

  [[ -d ${__adrctl_adr_dir} ]] || {
    __adrctl_fail_operational "ADR directory does not exist: ${__adrctl_adr_dir}"
    return $?
  }

  declare -a node_numbers=()
  declare -a node_titles=()
  declare -a node_bases=()
  declare -a edge_sources=()
  declare -a edge_targets=()
  declare -a edge_labels=()
  declare -a edge_kinds=()

  __adrctl_graph_build_model \
    node_numbers node_titles node_bases \
    edge_sources edge_targets edge_labels edge_kinds || return $?

  case "${format}" in
    dot)
      __adrctl_graph_emit_dot \
        node_numbers node_titles node_bases \
        edge_sources edge_targets edge_labels edge_kinds \
        "${prefix}" "${extension}"
      ;;
    mermaid)
      __adrctl_graph_emit_mermaid \
        node_numbers node_titles node_bases \
        edge_sources edge_targets edge_labels edge_kinds \
        "${prefix}" "${extension}"
      ;;
  esac
}

## @fn __adrctl_help_text()
## @brief Builds built-in help text, including selectable graph serialization.
## @param $1 Output variable.
## @param $2... Optional command/subcommand path.
## @retval 0 Help exists.
## @retval 2 Requested help subject is unknown.
## @details
## This definition intentionally follows the command module in assembly order so
## the graph-specific public grammar remains documented without duplicating graph
## serialization semantics in the command dispatcher.
__adrctl_help_text() {
  local __adrctl_local_output_name
  local __adrctl_local_invoked
  local __adrctl_local_subject
  local __adrctl_local_built_text

  __adrctl_local_output_name="$1"
  shift
  __adrctl_local_invoked="$(__adrctl_invoked_name)"
  __adrctl_local_subject="${1-}"
  __adrctl_local_built_text=''

  case "${__adrctl_local_subject}" in
    '')
      printf -v __adrctl_local_built_text '%s\n' \
        "Usage: ${__adrctl_local_invoked} [--project-root PATH] COMMAND [OPTION...]" \
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
        "  ${__adrctl_local_invoked} -h | --help" \
        "  ${__adrctl_local_invoked} --version"
      ;;
    init)
      printf -v __adrctl_local_built_text '%s\n' \
        "Usage: ${__adrctl_local_invoked} init [DIRECTORY]" \
        '' \
        'Initialize the current project with Architecture Decision Records.' \
        'DIRECTORY defaults to doc/adr.  A supplied directory is recorded in .adr-dir.'
      ;;
    new)
      printf -v __adrctl_local_built_text '%s\n' \
        "Usage: ${__adrctl_local_invoked} new [-s REFERENCE]... [-l TARGET:LINK:REVERSE-LINK]... [OPTIONS] TITLE..." \
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
      printf -v __adrctl_local_built_text '%s\n' \
        "Usage: ${__adrctl_local_invoked} link SOURCE LINK TARGET REVERSE-LINK" \
        '' \
        'Add a relationship from SOURCE to TARGET and the reciprocal relationship.'
      ;;
    list)
      printf -v __adrctl_local_built_text '%s\n' "Usage: ${__adrctl_local_invoked} list"
      ;;
    generate)
      if [[ ${2-} == toc ]]; then
        printf -v __adrctl_local_built_text '%s\n' \
          "Usage: ${__adrctl_local_invoked} generate toc [-i INTRO_FILE] [-o OUTRO_FILE] [-p LINK_PREFIX]"
      elif [[ ${2-} == graph ]]; then
        printf -v __adrctl_local_built_text '%s\n' \
          "Usage: ${__adrctl_local_invoked} generate graph [-p LINK_PREFIX] [-e LINK_EXTENSION] [--format dot|mermaid]" \
          '' \
          'DOT is the default graph serialization.  Mermaid emits raw flowchart source.'
      elif [[ -n ${2-} ]]; then
        # Runtime defines this cross-module exit status before command dispatch.
        # shellcheck disable=SC2154
        return "${__adrctl_exit_usage}"
      else
        printf -v __adrctl_local_built_text '%s\n' \
          "Usage: ${__adrctl_local_invoked} generate [REPORT [OPTION...]]" \
          '' \
          'Reports:' \
          '  toc' \
          '  graph'
      fi
      ;;
    upgrade-repository)
      printf -v __adrctl_local_built_text '%s\n' \
        "Usage: ${__adrctl_local_invoked} upgrade-repository"
      ;;
    *)
      # Runtime defines this cross-module exit status before command dispatch.
      # shellcheck disable=SC2154
      return "${__adrctl_exit_usage}"
      ;;
  esac

  printf -v "${__adrctl_local_output_name}" '%s' "${__adrctl_local_built_text}"
}

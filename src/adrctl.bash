## @file src/adrctl.bash
## @brief Provides the sole adrctl product entrypoint and command dispatcher.

## @fn __adrctl_main()
## @brief Parses global options, resolves project context, and dispatches commands.
## @param $@ Public adrctl process arguments.
## @retval 0 Command completed successfully.
## @retval 1 Operational/domain failure.
## @retval 2 Invalid usage or configuration.
__adrctl_main() {
  local project_root
  local project_root_set
  local command

  project_root=''
  project_root_set=0

  __adrctl_require_bash || return $?

  while (( $# > 0 )); do
    case "$1" in
      --project-root)
        if (( project_root_set )); then
          __adrctl_fail_usage '--project-root may be supplied at most once'
          return $?
        fi
        if (( $# < 2 )); then
          __adrctl_fail_usage '--project-root expects PATH'
          return $?
        fi
        project_root="$2"
        project_root_set=1
        shift 2
        ;;
      -h | --help)
        shift
        if (( $# > 0 )); then
          __adrctl_fail_usage '--help does not accept additional arguments'
          return $?
        fi
        __adrctl_command_help
        return $?
        ;;
      --version)
        shift
        if (( $# > 0 )); then
          __adrctl_fail_usage '--version does not accept additional arguments'
          return $?
        fi
        __adrctl_print_version
        return $?
        ;;
      --)
        shift
        break
        ;;
      -*)
        __adrctl_fail_usage "unknown global option: $1"
        return $?
        ;;
      *)
        break
        ;;
    esac
  done

  if (( $# == 0 )); then
    __adrctl_fail_usage 'missing command; use help for available commands'
    return $?
  fi

  command="$1"
  shift

  case "${command}" in
    help)
      __adrctl_command_help "$@"
      ;;
    init)
      __adrctl_load_project init "${project_root}" "${project_root_set}" || return $?
      __adrctl_command_init "$@"
      ;;
    new)
      __adrctl_load_project existing "${project_root}" "${project_root_set}" || return $?
      __adrctl_command_new "$@"
      ;;
    link)
      __adrctl_load_project existing "${project_root}" "${project_root_set}" || return $?
      __adrctl_command_link "$@"
      ;;
    list)
      (( $# == 0 )) || {
        __adrctl_fail_usage 'list accepts no arguments'
        return $?
      }
      __adrctl_load_project existing "${project_root}" "${project_root_set}" || return $?
      __adrctl_command_list
      ;;
    generate)
      __adrctl_load_project existing "${project_root}" "${project_root_set}" || return $?
      __adrctl_command_generate "$@"
      ;;
    upgrade-repository)
      __adrctl_load_project existing "${project_root}" "${project_root_set}" || return $?
      __adrctl_command_upgrade_repository "$@"
      ;;
    *)
      __adrctl_fail_usage "unknown command: ${command}"
      return $?
      ;;
  esac
}

## @brief Transfers process ownership to adrctl only for supported executable names.
## @details
## Sourcing maintained modules or the generated artifact does not dispatch a
## command.  In the generated artifact, embedded `mktext` uses its own basename
## guard and remains inert for `adrctl` and `adr`, leaving this as the one effective
## product entrypoint.
if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  case ${0##*/} in
    adrctl | adr | adrctl.bash)
      if __adrctl_main "$@"; then
        exit 0
      else
        exit $?
      fi
      ;;
  esac
fi

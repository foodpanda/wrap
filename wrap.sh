#!/usr/bin/env bash
#
#/ Runs <command> in detached `tmux` <session>, while capturing output to <logfile>.
#/
#/ Usage:
#/   wrap <command> [<session>] [<logfile>]
#

set -euo pipefail

_usage() {
    grep ^#/ "$0" | cut -c4-
    exit
}

_error() {
    echo >&2 "ERROR: ${1:-unknown error}"
    exit 1
}

_confirm () {
    read -r -p "${1:-Are you sure? [y/N]} " response

    case $response in
        [yY][eE][sS]|[yY]) true ;;
        *) false ;;
    esac
}

_tail_logs() {
    echo "Tailing logs from '${TMUX_LOG}' file ..."

    tail -f "${TMUX_LOG}"
}

_trap_cancel() {
    echo >&2
    echo >&2 "Aborted..."
    exit 1
}

_trap_success() {
    local filename
    filename=$(printf "%q" "${TMUX_LOG}")

    echo
    echo "Log still could be accessible via:"
    echo "    \$ tail -f ${filename}"
    echo "    \$ less ${filename}"
    exit
}

trap '_trap_cancel' SIGHUP SIGINT SIGQUIT SIGTERM

# prequisites
for cmd in tmux openssl cat tail time date xargs; do
    hash "${cmd}" 2>/dev/null || _error "I require '${cmd}', but it's not installed"
done

TMUX_CMD="$(echo "${1:-}" | xargs)"
TMUX_SID="$(echo "${2:-wrap}" | xargs)"
TMUX_LOG="$(echo "${3:-"wrap.log.$(echo -n "${TMUX_CMD}" | openssl sha1)"}" | xargs)"

[[ "${TMUX_CMD}" == "--help" || "${TMUX_CMD}" == '-h' ]] && _usage

TMUX_CMD="$(sed 's/;\+$//' <<< "${TMUX_CMD}")"

[[ -z "${TMUX_CMD}" ]] && _error "command could not be empty"

# unset TMUX, due warning of nested session
# is there nicer solution?
unset TMUX

# has active session?
if tmux has -t "${TMUX_SID}" 2>/dev/null; then
    trap - SIGHUP SIGINT SIGQUIT SIGTERM
    trap '_trap_success' EXIT

    tmux attach -t "${TMUX_SID}"

    if tmux has -t "${TMUX_SID}" 2>/dev/null; then
        _tail_logs
    fi

    echo "Session '${TMUX_SID}' has finished ..." | tee -a "${TMUX_LOG}"
    exit
fi

echo "wrap - run command smart in tmux"
echo
echo "  >> ${TMUX_CMD} <<  "
echo

if ! _confirm "Proceed? [y/N]"; then
  echo "Aborted..." 2>&1
  exit 1
fi

# wrap input command
TMUX_WRAP_CMD=$(cat <<==END
    _log() { echo "> \$(date -u +"%F %T") \$1"; }

    _log "Running: ${TMUX_CMD} "

    set -x
    time { ${TMUX_CMD}; }
    { retVal=\$?; set +x; echo; } 2>/dev/null

    _log "Finished (exit \${retVal})"
==END
)

mkdir -p "$(dirname "${TMUX_LOG}")"

echo "Session '${TMUX_SID}' is starting ..." > "${TMUX_LOG}"

tmux new -d -s "${TMUX_SID}" -n "${TMUX_CMD}" "{ ${TMUX_WRAP_CMD}; } 2>&1 | tee -a '${TMUX_LOG}'"

tmux set -q -t "${TMUX_SID}" -g window-status-current-format "#[fg=colour0,bg=colour39] #W #[fg=colour39,bg=colour0]"
tmux set -q -t "${TMUX_SID}" -g status-bg colour3
tmux set -q -t "${TMUX_SID}" -g status-fg colour0
tmux set -q -t "${TMUX_SID}" -g status-left-length 50
tmux set -q -t "${TMUX_SID}" -g status-right-length 50
tmux set -q -t "${TMUX_SID}" -g status-right ' %Y-%m-%d %H:%M:%S '
tmux set -q -t "${TMUX_SID}" -g status-interval 1

trap - SIGHUP SIGINT SIGQUIT SIGTERM
trap '_trap_success' EXIT

_tail_logs

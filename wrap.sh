#!/usr/bin/env bash
#/
#/ Runs <command> in detached `tmux` <session>, while capturing output to <logfile>.
#/
#/ Usage:
#/   wrap <command> [<session>] [<logfile>]
#/

set -euo pipefail

_log() {
	echo "> $(date -u +"%F %T") $1";
}

_error() {
	echo >&2 "ERROR: ${1:-unknown error}"
	exit 1
}

_usage() {
	grep ^#/ "$0" | cut -c4-
	exit
}

_trap() {
	echo
	echo "Logs could be read via:"
	echo "    \$ tail -f '${TMUX_LOG}'"
	echo "    \$ less '${TMUX_LOG}'"
	echo
}

function _confirm () {
  read -r -p "${1:-Are you sure? [y/N]} " response
  case $response in
    [yY][eE][sS]|[yY])
      true
      ;;
    *)
      false
      ;;
  esac
}

# prequisites
for cmd in tmux openssl cat tail time date xargs; do
  hash "${cmd}" 2>/dev/null || _error "I require '${cmd}', but it's not installed"
done

TMUX_CMD="$(echo ${1:-} | xargs)"
TMUX_SID="$(echo ${2:-wrap} | xargs)"
TMUX_LOG="$(echo ${3:-"wrap.$(echo -n ${TMUX_CMD} | openssl sha1).log"} | xargs)"

[[ "${TMUX_CMD}" == "--help" || "${TMUX_CMD}" == '-h' ]] && _usage

[[ -z "${TMUX_CMD}" ]] && _error "command could not be empty"

if tmux has -t "${TMUX_SID}" 2>/dev/null; then
	tmux attach -t "${TMUX_SID}"
	_trap
	exit
fi

echo "Command: ${TMUX_CMD}"

if ! _confirm "Ready to wrap this command? [y/N]"; then
  echo "Aborted..." 2>&1
  exit 1
fi

trap "echo; _trap" SIGHUP SIGINT SIGTERM

# wrap input command
TMUX_CMD=$(cat <<==END
	_log() { echo "> \$(date -u +"%F %T") \$1"; }
	_log "Running: ${TMUX_CMD} "

	set -x;	time { ${TMUX_CMD}; }
	{ retVal=\$?; set +x; echo; } 2>/dev/null

	_log "Finished (exit \${retVal})"
==END
)

_log "Starting '${TMUX_SID}' session ..."

tmux new -d -s "${TMUX_SID}" > "${TMUX_LOG}"
tmux send -t "${TMUX_SID}.0" \
	"reset" C-m \
	"{ ${TMUX_CMD}; } 2>&1 | tee '${TMUX_LOG}'" C-m \
	"exit" C-m

_log "Tailing logs from '${TMUX_LOG}' file ..."

tail -f "${TMUX_LOG}"

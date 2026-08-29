#!/bin/bash

HISTSESSION=`dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64`

# This utility requires bash-preexec to function, so get it.
# n.b. we presume cwd is ~
if [ ! -f ${HOME}/.bash-preexec.sh ]
then
    wget -q -O ${HOME}/.bash-preexec.sh 'https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh' 2> /dev/null ||
    curl -s -o ${HOME}/.bash-preexec.sh 'https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh' 2> /dev/null
fi
source ${HOME}/.bash-preexec.sh

# header guard
[ -n "$_SQLITE_HIST" ] && return || readonly _SQLITE_HIST=1

# Portable epoch-milliseconds. Resolved once at source time, not per command.
# Every branch yields a 13-digit millisecond value.
#
# Each candidate is probed by running it, not by testing whether the binary
# exists. BSD date has no %N (a GNU extension) and emits the literal text "3N";
# and perl is present on minimal CentOS installs WITHOUT Time::HiRes, so
# `command -v perl` is not evidence the perl branch can run.
__hist_ms_ok() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "${#1}" -ge 13 ]
}

if __hist_ms_ok "$(date +%s%3N 2>/dev/null)"; then
    __hist_ms() { date +%s%3N; }                       # GNU date (Linux)
elif __hist_ms_ok "$(gdate +%s%3N 2>/dev/null)"; then
    __hist_ms() { gdate +%s%3N; }                      # coreutils on macOS
elif __hist_ms_ok "$(perl -MTime::HiRes=time -e 'printf "%d", time*1000' 2>/dev/null)"; then
    __hist_ms() { perl -MTime::HiRes=time -e 'printf "%d", time*1000'; }
else
    __hist_ms() { echo "$(date +%s)000"; }             # seconds, no ms
fi

unset -f __hist_ms_ok


# Let's define some utility functions
# TODO figure out how to integrate this with the history builtins

dbhistory() {
    #sqlite3 -separator '#' ${HISTDB} "select command_id, command from command where command like '%${@}%';" | awk -F'#' '/^[0-9]+#/ {printf "%8s    %s\n", $1, substr($0,index($0,FS)+1); next} { print $0; }'
    # -list is required: sqlite3 defaults to 'box' mode when stdout is a TTY,
    # and -separator is silently ignored in that mode.
    sqlite3 -list -separator '|' ${HISTDB} "select command_id, datetime(started/1000, 'unixepoch', 'localtime') as ran_at, cwd, return, command from command;"
}

dbhist() {
    dbhistory "$@"
}

# TODO figure out how to make this function rewrite history so the up arrow
#  (or ^r searches) give you what you ran, and not the dbexec() call.
dbexec() {
    bash -c "$(sqlite3 "${HISTDB}" "select command from command where command_id='${1}';")"
}


# The magic follows

__quote_str() {
	local str
	local quoted
	str="$1"
	quoted="'$(echo "$str" | sed -e "s/'/''/g")'"
	echo "$quoted"
}
__create_histdb() {
	[[ -s $HISTDB ]] && return 0
	sqlite3 "$HISTDB" <<-EOD
	CREATE TABLE IF NOT EXISTS command (
		command_id INTEGER PRIMARY KEY,
		shell TEXT,
		command TEXT,
		cwd TEXT,
		return INTEGER,
		started INTEGER,
		ended INTEGER,
		shellsession TEXT,
		loginsession TEXT
	);
	EOD
}

preexec_bash_history_sqlite() {
	[[ -z ${HISTDB} ]] && return 0
	local cmd
	cmd="$1"

	#atomic create file if not exist
	__create_histdb

	local quotedloginsession
	if [[ -n "${LOGINSESSION}" ]]; then
		quotedloginsession=$(__quote_str "$LOGINSESSION")
	else
		quotedloginsession="NULL"
	fi
	LASTHISTID="$(sqlite3 "$HISTDB" <<-EOD
		INSERT INTO command (shell, command, cwd, started, shellsession, loginsession)
		VALUES (
			'bash',
			$(__quote_str "$cmd"),
			$(__quote_str "$PWD"),
			'$(__hist_ms)',
			$(__quote_str "$HISTSESSION"),
			$quotedloginsession
		);
		SELECT last_insert_rowid();
		EOD
	)"

	echo "$cmd" >> ~/.testlog
}

precmd_bash_history_sqlite() {
	local ret_value="$?"
	if [[ -n "${LASTHISTID}" ]]; then
		__create_histdb
		sqlite3 "$HISTDB" <<- EOD
			UPDATE command SET
				ended='$(__hist_ms)',
				return=$ret_value
			WHERE
				command_id=$LASTHISTID ;
		EOD
	fi
}

preexec_functions+=(preexec_bash_history_sqlite)
precmd_functions+=(precmd_bash_history_sqlite)

# KNOWN LIMITATION (bash 3.2 only, e.g. Apple's /bin/bash 3.2.57):
# bash-preexec installs its DEBUG trap one prompt late, so the FIRST command of
# every session is silently missing from the history database. Commands 2..n
# record normally. bash 5.x installs immediately and loses nothing.
#
# Do NOT try to fix this by calling `__bp_install` here, nor at the end of
# ~/.bashrc. Both were tested and both make it WORSE -- they install the trap
# too early, and whatever touches PROMPT_COMMAND afterwards (mise, zoxide, fzf,
# the PROMPT_COMMAND rewrite in .bashrc, and .bash_profile continuing on into
# iTerm2 shell integration) clobbers it, after which NOTHING is recorded.
#
# The verified fix is to use a bash 5.x as the interactive shell.

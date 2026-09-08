# ~/.zsh-history-sqlite.zsh
#
# zsh port of ~/.bash-history-sqlite.sh. Logs every interactive command to the
# shared SQLite database at $HISTDB (~/.hist.db), the same table/schema the bash
# version writes, so dbhist / h() / the Ctrl-R db-history widget keep working
# across both shells.
#
# Unlike the bash version this needs no bash-preexec: zsh has native preexec /
# precmd hooks. Wired via add-zsh-hook.

# header guard
[ -n "$_SQLITE_HIST" ] && return
readonly _SQLITE_HIST=1

: "${HISTDB:=$HOME/.hist.db}"

HISTSESSION="$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d '\n')"

# Portable epoch-milliseconds. Resolved once at source time, not per command.
# BSD date has no %N; perl may lack Time::HiRes -- so probe by running, not by
# testing for the binary.
__hist_ms_ok() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
    esac
    [ "${#1}" -ge 13 ]
}

if __hist_ms_ok "$(date +%s%3N 2>/dev/null)"; then
    __hist_ms() { date +%s%3N; }
elif __hist_ms_ok "$(gdate +%s%3N 2>/dev/null)"; then
    __hist_ms() { gdate +%s%3N; }
elif __hist_ms_ok "$(perl -MTime::HiRes=time -e 'printf "%d", time*1000' 2>/dev/null)"; then
    __hist_ms() { perl -MTime::HiRes=time -e 'printf "%d", time*1000'; }
else
    __hist_ms() { echo "$(date +%s)000"; }
fi
unset -f __hist_ms_ok

# dbhistory [pattern...] -- all rows, or only those whose command matches.
dbhistory() {
    local pattern where
    where=""
    if [ "$#" -gt 0 ]; then
        pattern=$(printf '%s' "$*" | sed "s/'/''/g")
        where="where command like '%${pattern}%'"
    fi
    sqlite3 -list -separator '|' "${HISTDB}" \
        "select command_id,
                datetime(started/1000, 'unixepoch', 'localtime') as ran_at,
                cwd, return, command
         from command ${where} order by command_id;"
}

dbhist() { dbhistory "$@"; }

dbexec() {
    eval "$(sqlite3 "${HISTDB}" "select command from command where command_id='${1}';")"
}

__quote_str() {
    local str quoted
    str="$1"
    quoted="'$(printf '%s' "$str" | sed -e "s/'/''/g")'"
    printf '%s' "$quoted"
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

preexec_zsh_history_sqlite() {
    [[ -z ${HISTDB} ]] && return 0
    local cmd="$1"

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
			'zsh',
			$(__quote_str "$cmd"),
			$(__quote_str "$PWD"),
			'$(__hist_ms)',
			$(__quote_str "$HISTSESSION"),
			$quotedloginsession
		);
		SELECT last_insert_rowid();
		EOD
    )"
}

precmd_zsh_history_sqlite() {
    local ret_value="$?"
    if [[ -n "${LASTHISTID}" ]]; then
        __create_histdb
        sqlite3 "$HISTDB" <<-EOD
			UPDATE command SET
				ended='$(__hist_ms)',
				return=$ret_value
			WHERE
				command_id=$LASTHISTID ;
		EOD
        LASTHISTID=""
    fi
    # stay transparent to $? so later precmd hooks (e.g. Starship's status) see
    # the real exit code of the user's command
    return $ret_value
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec preexec_zsh_history_sqlite
add-zsh-hook precmd precmd_zsh_history_sqlite

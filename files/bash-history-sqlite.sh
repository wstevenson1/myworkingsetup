#!/usr/bin/env bash
# ~/.bash-history-sqlite.sh
# Query the bash history SQLite database stored at ~/.hist.db.

HISTDB="$HOME/.hist.db"

if [ ! -f "$HISTDB" ]; then
  echo "History DB not found: $HISTDB" >&2
  exit 1
fi

if [ $# -eq 0 ]; then
  sqlite3 -column -header "$HISTDB" \
    "SELECT datetime(timestamp, 'unixepoch') AS when, command FROM history ORDER BY timestamp DESC LIMIT 200;"
else
  query="%$1%"
  sqlite3 -column -header "$HISTDB" \
    "SELECT datetime(timestamp, 'unixepoch') AS when, command FROM history WHERE command LIKE '$query' ORDER BY timestamp DESC LIMIT 200;"
fi

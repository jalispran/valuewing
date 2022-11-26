#!/bin/bash
# shellcheck disable=SC2155
# shellcheck disable=SC2162

TEMP_DIRECTORY='tmp/parking/data'
DB_FILE_NAME='database'
SESSION_FILE='session'

function get_db_path() {
  echo "$TEMP_DIRECTORY/$DB_FILE_NAME"
}

function get_session_file_path() {
  echo "$TEMP_DIRECTORY/$SESSION_FILE"
}

function append_newline_if_not_exists() {
  local dbPath=$(get_db_path)
  tail -c1 "$dbPath" | read -r _ || echo >> "$dbPath"
}

function create_db_if_not_exists() {
  local dbPath=$(get_db_path)
  if [ ! -f  "$dbPath" ]
  then
    echo 'Creating a database'
    mkdir -p $TEMP_DIRECTORY
    echo "Slot No.,Registration No." > "$dbPath"
  fi
}

function start_session() {
  local size="$1"
  local sess_file=$(get_session_file_path)
  if [ ! -f  "$sess_file" ]
    then
    echo 'Creating session'
    mkdir -p $TEMP_DIRECTORY
  fi
  echo "$size" > "$sess_file"
}

function create() {
  local lot_size="$1"
  start_session "$lot_size"

}

create_db_if_not_exists
append_newline_if_not_exists
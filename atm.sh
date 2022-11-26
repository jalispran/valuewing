#!/bin/bash
# shellcheck disable=SC2155
# shellcheck disable=SC2162

TEMP_DIRECTORY='tmp/atm/data'
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
    echo "name,amount" > "$dbPath"
  fi
}

function start_session() {
  local user_name="$1"
  local sess_file=$(get_session_file_path)
  if [ ! -f  "$sess_file" ]
    then
    mkdir -p $TEMP_DIRECTORY
  fi
  echo "$user_name" > "$sess_file"
}

function add_user() {
  local name="$1"
  local dbFile=$(get_db_path)
  echo "$name,0" >> "$dbFile"
}

function get_current_user() {
  local sess_file=$(get_session_file_path)
  if [ ! -f  "$sess_file" ]; then
    return
  fi
  cat "$sess_file"
}

function check_user_exists() {
  local user="$1"
  local dbFile=$(get_db_path)
  {
    read
    while IFS=, read -r user_name amount
    do
      if [ "$user_name" = "$user" ]; then
        echo true
        return
      fi
    done
  } < "$dbFile"
  echo false
}

function get_amount_for_user() {
  local name="$1"
  local dbFile=$(get_db_path)
  {
    read
    while IFS=, read -r user_name amount
    do
      if [ "$user_name" = "$name" ]; then
        echo "$amount"
      fi
    done
  } < "$dbFile"
}

function deposit_to_account() {
  local current_user="$1"
  local amount="$2"
  local dbFile=$(get_db_path)
  local current_amount=$(get_amount_for_user "$current_user")
  current_amount=$((amount + current_amount))
  local dump=$(sed -E "/^$current_user,/s/[0-9]+$/$current_amount/" "$dbFile")
  echo "$dump" > "$dbFile"
  local balance=$(get_amount_for_user "$current_user")
  echo "$balance"
}

function withdraw_from_account() {
  local current_user="$1"
  local amount="$2"

  local current_user_amount=$(get_amount_for_user "$current_user")
  if [ "$current_user_amount" -lt "$amount" ]; then
    return
  fi

  current_user_amount=$((current_user_amount - amount))

  local dbFile=$(get_db_path)
  local dump=$(sed -E "/^$current_user,/s/[0-9]+$/$current_user_amount/" "$dbFile")
  echo "$dump" > "$dbFile"
  local balance=$(get_amount_for_user "$current_user")
  echo "$balance"
}

function login() {
  local name=$1
  read amount < <(get_amount_for_user "$name")

  if [ "$amount" = "" ]; then
    add_user "$name"
  fi

  read amount < <(get_amount_for_user "$name")
  echo "Hello, $name!"
  echo "Your balance is \$$amount"

  start_session "$name"
}

function deposit() {
  local amount="$1"
  local current_user=$(get_current_user)
  if [ "$current_user" = "" ]; then
    echo 'No user login detected. Please login to proceed'
    return
  fi
  local balance=$(deposit_to_account "$current_user" "$amount")
  echo "Your balance is \$$balance"
}

function withdraw() {
  local amount="$1"
  local current_user=$(get_current_user)
  if [ "$current_user" = "" ]; then
    echo 'No user login detected. Please login to proceed'
    return
  fi

  local balance=$(withdraw_from_account "$current_user" "$amount")
  if [ "$balance" != "" ]; then
    echo "Your balance is \$$balance"
  else
    echo "Insufficient funds"
  fi
}

function transfer() {
  local target="$1"
  local amount="$2"
  local current_user=$(get_current_user)
  if [ "$current_user" = "" ]; then
    echo 'No user login detected. Please login to proceed'
    return
  fi

  local user_exists=$(check_user_exists "$target")
  if [ "$user_exists" = false ]; then
    echo "Target account does not exist"
    return
  fi

  local withdraw_balance=$(withdraw_from_account "$current_user" "$amount")
  if [ "$withdraw_balance" = "" ]; then
    echo "Insufficient funds"
    return
  fi

  local deposit_amount=$(deposit_to_account "$target" "$amount")
  echo "Transferred \$$deposit_amount to $target"
  echo "Your balance is \$$withdraw_balance"
}

function logout() {
  local current_user=$(get_current_user)
  if [ "$current_user" = "" ]; then
    echo 'No user login detected. Please login to proceed'
    return
  fi
  local sess_file=$(get_session_file_path)
  rm -rf "$sess_file"
  echo "Goodbye, $current_user!"
}

create_db_if_not_exists
append_newline_if_not_exists

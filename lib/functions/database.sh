#!/bin/bash
#
# File: database.sh -> common database operations
#
# Usage: source database.sh
#
#

## - start here

function create_app_key() {
  uuidgen | sed -E -e 's/[[:space:]]+//g' -e 's/\-//g' | tr '[:upper:]' '[:lower:]'
}

function update_database() {
  local generated_app_key="$(create_app_key)" dib_app_key="$DIB_APP_KEY"
  local new_project_value="$APP_FRAMEWORK:$APP_PROJECT:$APP_IMAGE"
  local old_project_value="$(get_project_value_by_app_key "$dib_app_key")"
  local old_app_key="$(get_app_key_by_project_value "$new_project_value")"

  if [[ -s "$DIB_APP_DATABASE_FILE" ]]
  then
    cp "$DIB_APP_DATABASE_FILE" "$DIB_APP_DATABASE_FILE_COPY"
  fi

  if [[ -z "$old_app_key" && -z "$old_project_value" ]]
  then
    echo "$generated_app_key $new_project_value" 1>> "$DIB_APP_DATABASE_FILE"
    export DIB_APP_KEY="$generated_app_key"
  elif [[ -n "$old_app_key" && -z "$old_project_value" ]]
  then
    remove_entry_by_app_key "$old_app_key"
    echo "$old_app_key $new_project_value" 1>> "$DIB_APP_DATABASE_FILE"
    export DIB_APP_KEY="$old_app_key"
  elif [[ -z "$old_app_key" && -n "$old_project_value" ]]
  then
    remove_entry_by_project_value "$old_project_value"
    echo "$generated_app_key $old_project_value" 1>> "$DIB_APP_DATABASE_FILE"
    export DIB_APP_KEY="$generated_app_key"
  elif [[ -n "$old_app_key" && -n "$old_project_value" ]]
  then
    export DIB_APP_KEY="$old_app_key"
  fi
}

function get_app_key_by_project_value() {
  local project_value="$1"

  if [[ -f "$DIB_APP_DATABASE_FILE" && -n "$project_value" ]]
  then
    grep "$project_value" "$DIB_APP_DATABASE_FILE" | \
    cut -d' ' -f1 | \
    grep -E --color=never "$DIB_APP_DATABASE_KEY_PATTERN"
  fi
}

function get_project_value_by_app_key() {
  local app_key="$1"

  if [[ -f "$DIB_APP_DATABASE_FILE" && -n "$app_key" ]]
  then
    grep "$app_key" "$DIB_APP_DATABASE_FILE" | \
    cut -d' ' -f2 | \
    grep -E --color=never "$DIB_APP_DATABASE_VALUE_PATTERN"
  fi
}

function remove_entry_by_app_key() {
  local app_key="$1"

  if [[ -f "$DIB_APP_DATABASE_FILE" ]]
  then
    sed -i '.sed-backup' -e "/${app_key}/d" "$DIB_APP_DATABASE_FILE" 
    rm -f '*.sed-backup'
  fi
}

function remove_entry_by_project_value() {
  local project_value="$1"

  if [[ -f "$DIB_APP_DATABASE_FILE" ]]
  then
    sed -i '.sed-backup' -e "/${project_value}/d" "$DIB_APP_DATABASE_FILE" 
    rm -f '*.sed-backup'
  fi
}

function get_all_database_entries() {
  [[ -f "$DIB_APP_DATABASE_FILE" ]] && exec cat "$DIB_APP_DATABASE_FILE"
}

## -- finish
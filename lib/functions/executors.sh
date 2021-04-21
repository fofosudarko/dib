#!/bin/bash
#
# File: executors.sh -> common executors operations
#
# Usage: source executors.sh
#
#

## - start here

function execute_init_command() {
  
  function create_directories_on_init() {
    local directories=

    directories="$DIB_APPS_DIR $DIB_APPS_CONFIG_DIR $DIB_APPS_KEYSTORES_DIR"
    directories="$directories $DIB_APPS_COMPOSE_DIR $DIB_APPS_ENV_DIR $DIB_APPS_K8S_ANNOTATIONS_DIR"
    directories="$directories $DIB_APPS_KUBERNETES_DIR $DIB_APPS_CACHE_DIR $DIB_APPS_SECRETS_DIR"

    create_directories_if_not_exist "$directories"
  }

  check_parameter_validity "$DIB_HOME" "$DIB_HOME_PLACEHOLDER"
  create_directories_on_init
  exit 0
}

function execute_goto_command() {
  
  function save_data_to_root_cache_on_goto() {
    save_data_to_root_cache
  }

  load_core
  check_parameter_validity "$DIB_HOME" "$DIB_HOME_PLACEHOLDER"
  check_parameter_validity "$APP_FRAMEWORK" "$DIB_APP_FRAMEWORK_PLACEHOLDER"
  check_parameter_validity "$APP_PROJECT" "$DIB_APP_PROJECT_PLACEHOLDER"
  check_parameter_validity "$APP_IMAGE" "$DIB_APP_IMAGE_PLACEHOLDER"
  check_app_framework_validity
  update_database
  format_root_cache_file
  save_data_to_root_cache_on_goto
  msg "$DIB_APP_KEY"
  exit 0
}

function execute_switch_command() {
  
  function set_directories_on_switch() {
    set_project_directories
  }

  function save_data_to_root_cache_on_switch() {
    save_data_to_root_cache
  }

  load_core
  ensure_core_variables_validity
  check_app_framework_validity
  check_app_environment_validity
  set_directories_on_switch
  save_data_to_root_cache_on_switch
  exit 0
}

function execute_cache_command() {
  [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]] && cat "$DIB_APP_ROOT_CACHE_FILE"
  exit 0
}

function execute_copy_command() {
  
  function set_directories_on_copy() {
    set_project_directories
  }

  function save_data_to_root_cache_on_copy() {
    save_data_to_root_cache
  }

  load_core
  set_directories_on_copy
  copy_docker_project "$DIB_APP_BUILD_SRC" "$DIB_APP_BUILD_DEST"
  save_data_to_root_cache_on_copy
  exit 0
}

function execute_reset_command() {
  clear_root_cache
  exit 0
}

function execute_version_command() {
  echo "$DIB_APP_VERSION"
  exit 0
}


function execute_build_command() {
  build_docker_image || abort_build_process
  save_data_to_app_cache
}

function execute_build_and_push_command() {
  build_docker_image || abort_build_process
  push_docker_image
  save_data_to_app_cache
}

function execute_build_push_deploy_command() {
  build_docker_image || abort_build_process
  push_docker_image
  deploy_to_k8s_cluster
  save_data_to_app_cache
}

function execute_push_command() {
  push_docker_image
  save_data_to_app_cache
}

function execute_deploy_command() {
  deploy_to_k8s_cluster
  save_data_to_app_cache
}

function execute_run_command() {
  run_docker_container
}

function execute_stop_command() {
  stop_docker_container
}

function execute_ps_command() {
  ps_docker_container
}

function execute_generate_command() {
  if generate_kubernetes_manifests
  then
    msg "The kubernetes manifests can be found here: $DIB_APP_COMPOSE_K8S_DIR"
  fi

  save_data_to_app_cache
}

function execute_doctor_command() {
  check_app_dependencies
  exit 0
}

function execute_help_command() {
  local command="${1:-all}"

  case "$command"
  in
    all) show_help;;
    goto) show_goto_help;;
    get:key) show_get_key_help;;
    get:project) show_get_project_help;;
    build) show_build_help;;
    build:push) show_build_push_help;;
    build:push:deploy) show_build_push_deploy_help;;
    push) show_push_help;;
    deploy) show_deploy_help;;
    generate) show_generate_help;;
    edit) show_edit_help;;
    show) show_show_help;;
    path) show_path_help;;
    restore) show_restore_help;;
    erase) show_erase_help;;
    env) show_env_help;;
    switch) show_switch_help;;
    copy) show_copy_help;;
    run) show_run_help;;
    *) show_help;;
  esac
  
  exit 0
}

function execute_get_key_command() {
  get_app_key_by_project_value "$1"
  exit 0
}

function execute_get_project_command() {
  get_project_value_by_app_key "$1"
  exit 0
}

function execute_get_all_command() {
  get_all_database_entries
  exit 0
}

function execute_env_command() {
  local env_type="$1"

  case "$env_type"
  in
    all) 
      get_all_envvars
    ;;
    globals) 
      get_globals_envvars
    ;;
    users) 
      get_users_envvars
    ;;
    app) 
      get_app_envvars
    ;;
    docker) 
      get_docker_envvars
    ;;
    kompose) 
      get_kompose_envvars
    ;;
    kubernetes) 
      get_kubernetes_envvars
    ;;
    *)
      get_all_envvars
    ;;
  esac
}

function execute_edit_command() {
  local file_type="$1" file_resource="$2"
  execute_file_command "edit" "$file_type" "$file_resource"
}

function execute_show_command() {
  local file_type="$1" file_resource="$2"
  execute_file_command "show" "$file_type" "$file_resource"
}

function execute_path_command() {
  local file_type="$1" file_resource="$2"
  execute_file_command "path" "$file_type" "$file_resource"
}

function execute_erase_command() {
  local file_type="$1" file_resource="$2"
  execute_file_command "erase" "$file_type" "$file_resource"
}

function execute_restore_command() {
  local file_type="$1" file_resource="$2"
  execute_file_command "restore" "$file_type" "$file_resource"
}

function execute_view_command() {
  local file_type="$1" file_resource="$2"
  execute_file_command "view" "$file_type" "$file_resource"
}

## -- finish

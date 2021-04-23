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

    directories="$DIB_APPS_APPS_DIR $DIB_APPS_CONFIG_DIR $DIB_APPS_KEYSTORES_DIR"
    directories="$directories $DIB_APPS_COMPOSE_DIR $DIB_APPS_ENV_DIR $DIB_APPS_K8S_ANNOTATIONS_DIR"
    directories="$directories $DIB_APPS_KUBERNETES_DIR $DIB_APPS_CACHE_DIR $DIB_APPS_SECRETS_DIR"

    create_directories_if_not_exist "$directories"
  }

  check_parameter_validity "$DIB_HOME" "$DIB_HOME_PLACEHOLDER"
  create_directories_on_init
}

function execute_goto_command() {
  
  function save_data_to_root_cache_on_goto() {
    save_data_to_root_cache
  }

  USER_DIB_APP_FRAMEWORK="${1:-}"
  USER_DIB_APP_PROJECT="${2:-}"
  USER_DIB_APP_IMAGE="${3:-$USER_DIB_APP_PROJECT}"

  should_show_help "$USER_DIB_APP_FRAMEWORK" && show_goto_help
  update_core_variables_if_changed
  load_core_data
  check_parameter_validity "$DIB_HOME" "$DIB_HOME_PLACEHOLDER"
  check_parameter_validity "$APP_FRAMEWORK" "$DIB_APP_FRAMEWORK_PLACEHOLDER"
  check_parameter_validity "$APP_PROJECT" "$DIB_APP_PROJECT_PLACEHOLDER"
  check_parameter_validity "$APP_IMAGE" "$DIB_APP_IMAGE_PLACEHOLDER"
  check_app_framework_validity
  update_database
  format_root_cache_file
  save_data_to_root_cache_on_goto
  echo "$DIB_APP_KEY"
}

function execute_switch_command() {
  
  function set_project_directories_on_switch() {
    set_project_directories
  }

  function save_data_to_root_cache_on_switch() {
    save_data_to_root_cache
  }

  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_ENVIRONMENT="${2:-}"
  
  should_show_help "$USER_DIB_APP_IMAGE" && show_switch_help
  check_app_key_validity
  perform_root_cache_operations
  load_core_data
  ensure_core_variables_validity
  check_app_framework_validity
  check_app_environment_validity
  set_project_directories_on_switch
  save_data_to_root_cache_on_switch
}

function execute_cache_command() {
  perform_root_cache_operations
  [[ -f "$DIB_APP_ROOT_CACHE_FILE" ]] && cat "$DIB_APP_ROOT_CACHE_FILE"
}

function execute_copy_command() {
  
  function set_project_directories_on_copy() {
    set_project_directories
  }

  function save_data_to_root_cache_on_copy() {
    save_data_to_root_cache
  }

  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_BUILD_SRC="${2:-}"
  USER_DIB_APP_BUILD_DEST="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_copy_help
  perform_root_cache_operations
  load_core_data
  set_project_directories_on_copy
  copy_docker_project
  save_data_to_root_cache_on_copy
}

function execute_copy_env_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_DEST_ENV="${2:-}"
  DIB_APP_SRC_ENV="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_copy_env_help
  perform_root_cache_operations
  perform_app_cache_operations
  transfer_dirs_data_from_src_to_dest_env_on_copy_env
}

function execute_copy_env_new_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_IMAGE_NEW="${2:-}"
  DIB_APP_DEST_ENV="${3:-}"
  DIB_APP_SRC_ENV="${4:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_copy_env_new_help
  perform_root_cache_operations
  perform_app_cache_operations
  transfer_dirs_data_from_src_to_dest_env_on_copy_env_new
}

function execute_reset_command() {
  perform_root_cache_operations
  clear_root_cache
}

function execute_version_command() {
  echo "$DIB_APP_VERSION"
}

function execute_build_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_build_help
  perform_root_cache_operations
  perform_app_cache_operations
  build_docker_image || abort_build_process
  save_data_to_app_cache
}

function execute_build_push_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_build_push_help
  perform_root_cache_operations
  perform_app_cache_operations
  build_docker_image || abort_build_process
  push_docker_image
  save_data_to_app_cache
}

function execute_build_push_deploy_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_build_push_deploy_help
  perform_root_cache_operations
  perform_app_cache_operations
  build_docker_image || abort_build_process
  push_docker_image
  deploy_to_k8s_cluster
  save_data_to_app_cache
}

function execute_build_run_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_build_run_help
  perform_root_cache_operations
  perform_app_cache_operations
  build_docker_image || abort_build_process
  run_docker_container
}

function execute_push_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_push_help
  perform_root_cache_operations
  perform_app_cache_operations
  push_docker_image
  save_data_to_app_cache
}

function execute_deploy_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_deploy_help
  perform_root_cache_operations
  perform_app_cache_operations
  deploy_to_k8s_cluster
  save_data_to_app_cache
}

function execute_run_command() {
  perform_root_cache_operations
  perform_app_cache_operations
  run_docker_container
}

function execute_stop_command() {
  perform_root_cache_operations
  perform_app_cache_operations
  stop_docker_container
}

function execute_ps_command() {
  perform_root_cache_operations
  perform_app_cache_operations
  ps_docker_container
}

function execute_generate_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  USER_DIB_APP_IMAGE_TAG="${2:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_generate_help
  perform_root_cache_operations
  perform_app_cache_operations

  if generate_kubernetes_manifests
  then
    msg "The kubernetes manifests can be found here: $DIB_APP_COMPOSE_K8S_DIR"
  fi

  save_data_to_app_cache
}

function execute_doctor_command() {
  check_app_dependencies
}

function execute_help_command() {
  show_help
}

function execute_get_key_command() {
  should_show_help "$1" && show_get_key_help
  get_app_key_by_project_value "$1"
}

function execute_get_project_command() {
  should_show_help "$1" && show_get_project_help
  get_project_value_by_app_key "$1"
}

function execute_get_all_command() {
  get_all_database_entries
}

function execute_env_command() {
  DIB_APP_ENV_TYPE="${1:-}"

  should_show_help "$DIB_APP_ENV_TYPE" && show_env_help
  perform_root_cache_operations
  perform_app_cache_operations

  case "$DIB_APP_ENV_TYPE"
  in
    all) 
      get_all_envvars
    ;;
    globals) 
      get_globals_envvars
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
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_edit_help
  perform_root_cache_operations
  perform_app_cache_operations
  execute_file_command "edit"
}

function execute_show_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_show_help
  perform_root_cache_operations
  perform_app_cache_operations
  execute_file_command "show"
}

function execute_path_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_path_help
  perform_root_cache_operations
  perform_app_cache_operations
  execute_file_command "path"
}

function execute_erase_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_erase_help
  perform_root_cache_operations
  perform_app_cache_operations
  execute_file_command "erase"
}

function execute_restore_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_restore_help
  perform_root_cache_operations
  perform_app_cache_operations
  execute_file_command "restore"
}

function execute_view_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_view_help
  perform_root_cache_operations
  perform_app_cache_operations
  execute_file_command "view"
}

function execute_edit_deploy_command() {
  USER_DIB_APP_IMAGE="${1:-}"
  DIB_APP_FILE_TYPE="${2:-}"
  DIB_APP_FILE_RESOURCE="${3:-}"
  USER_DIB_APP_IMAGE_TAG="${4:-}"

  should_show_help "$USER_DIB_APP_IMAGE" && show_edit_deploy_help
  perform_root_cache_operations
  perform_app_cache_operations
  msg 'Oops, not implemented yet.'
}

## -- finish

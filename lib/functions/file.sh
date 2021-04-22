#!/bin/bash
#
# File: file.sh -> common file operations
#
# Usage: source file.sh
#
#

## - start here

function edit_file() {
  local file="$1" file_copy="$2" 
  local directory=$(dirname "$file")

  check_path_validity "$directory"
  create_directory_if_not_exist "$directory"

  [[ -s "$file" ]] && cp "$file" "$file_copy"

  $EDITOR_CMD "$file"

  return "$?"
}

function restore_file() {
  local file_copy="$1" file="$2" 
  [[ -s "$file_copy" ]] && cp "$file_copy" "$file"
}

function show_file() {
  local file="$1"
  exec $PAGER_CMD "$file"
}

function view_file() {
  show_file "$1"
}

function locate_file() {
  local file="$1"
  exec ls "$file"
}

function erase_file() {
  local file="$1"
  exec cp /dev/null "$file"
}

function execute_file_command() {
  local command="$1" file_type="$2" file_resource="$3"

  case "$file_type"
  in
    env)
      case "$file_resource"
      in
        app-env)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_ENV_CHANGED_FILE" "$DIB_APP_ENV_CHANGED_FILE_COPY" && \
              file_changes_detected "$DIB_APP_ENV_CHANGED_FILE_COPY" "$DIB_APP_ENV_CHANGED_FILE" && \
              update_env_file \
                "$DIB_APP_ENV_FILE" \
                "$DIB_APP_ENV_CHANGED_FILE" \
                "$DIB_APP_ENV_SYMLINKED_FILE"
            ;;
            show)
              show_file "$DIB_APP_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_ENV_CHANGED_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_ENV_CHANGED_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_ENV_CHANGED_FILE_COPY" "$DIB_APP_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
        service-env)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE" "$DIB_APP_SERVICE_ENV_CHANGED_FILE_COPY" && \
              file_changes_detected "$DIB_APP_SERVICE_ENV_CHANGED_FILE_COPY" "$DIB_APP_ENV_SERVICE_CHANGED_FILE" && \
              update_env_file \
                "$DIB_APP_SERVICE_ENV_FILE" \
                "$DIB_APP_SERVICE_ENV_CHANGED_FILE" \
                "$DIB_APP_SERVICE_ENV_SYMLINKED_FILE"
            ;;
            show)
              show_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE_COPY" "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
        common-env)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_COMMON_ENV_CHANGED_FILE" "$DIB_APP_COMMON_ENV_CHANGED_FILE_COPY" && \
              file_changes_detected "$DIB_APP_COMMON_ENV_CHANGED_FILE_COPY" "$DIB_APP_COMMON_ENV_CHANGED_FILE" && \
              update_env_file \
                "$DIB_APP_COMMON_ENV_FILE" \
                "$DIB_APP_COMMON_ENV_CHANGED_FILE" \
                "$DIB_APP_COMMON_ENV_SYMLINKED_FILE"
            ;;
            show)
              show_file "$DIB_APP_COMMON_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_COMMON_ENV_CHANGED_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_COMMON_ENV_CHANGED_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_COMMON_ENV_CHANGED_FILE_COPY" "$DIB_APP_COMMON_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
        project-env)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE" "$DIB_APP_PROJECT_ENV_CHANGED_FILE_COPY" && \
              file_changes_detected "$DIB_APP_PROJECT_ENV_CHANGED_FILE_COPY" "$DIB_APP_PROJECT_ENV_CHANGED_FILE" && \
              update_env_file \
                "$DIB_APP_PROJECT_ENV_FILE" \
                "$DIB_APP_PROJECT_ENV_CHANGED_FILE" \
                "$DIB_APP_PROJECT_ENV_SYMLINKED_FILE"
            ;;
            show)
              show_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE_COPY" "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
      esac
    ;;
    config)
      case "$file_resource"
      in
        dockerfile)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_CONFIG_DOCKER_FILE" "$DIB_APP_CONFIG_DOCKER_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_CONFIG_DOCKER_FILE"
            ;;
            path)
              locate_file "$DIB_APP_CONFIG_DOCKER_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_CONFIG_DOCKER_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_CONFIG_DOCKER_FILE_COPY" "$DIB_APP_CONFIG_DOCKER_FILE"
            ;;
          esac
        ;;
        dockercomposefile)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE" "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE_COPY" 
            ;;
            show)
              show_file "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            view)
              view_file "$DIB_APP_CONFIG_DOCKER_COMPOSE_FILE"
            ;;
            path)
              locate_file "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE_COPY" "$DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
          esac
        ;;
        runscript)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_CONFIG_RUN_SCRIPT" "$DIB_APP_CONFIG_RUN_SCRIPT_COPY"
            ;;
            show)
              show_file "$DIB_APP_CONFIG_RUN_SCRIPT"
            ;;
            path)
              locate_file "$DIB_APP_CONFIG_RUN_SCRIPT"
            ;;
            erase)
              erase_file "$DIB_APP_CONFIG_RUN_SCRIPT"
            ;;
            restore)
              restore_file "$DIB_APP_CONFIG_RUN_SCRIPT_COPY" "$DIB_APP_CONFIG_RUN_SCRIPT"
            ;;
          esac
        ;;
      esac
    ;;
    compose)
      case "$file_resource"
      in
        dockercomposefile)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE" "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            view)
              show_file "$DIB_APP_COMPOSE_DOCKER_COMPOSE_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE_COPY" "$DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
          esac
        ;;
      esac
    ;;
    k8s-annotations)
      if [[ -n "$file_resource" ]]
      then
        k8s_resource_annotations_file="${DIB_APP_K8S_RESOURCE_ANNOTATIONS_CHANGED_FILE/$K8S_RESOURCE_TEMPLATE/$file_resource}"
        k8s_resource_annotations_file_copy="${DIB_APP_K8S_RESOURCE_ANNOTATIONS_CHANGED_FILE_COPY/$K8S_RESOURCE_TEMPLATE/$file_resource}"

        case "$command"
          in
            edit)
              edit_file "$k8s_resource_annotations_file" "$k8s_resource_annotations_file_copy"
            ;;
            show)
              show_file "$k8s_resource_annotations_file"
            ;;
            path)
              locate_file "$k8s_resource_annotations_file"
            ;;
            erase)
              erase_file "$k8s_resource_annotations_file"
            ;;
            restore)
              restore_file "$k8s_resource_annotations_file_copy" "$k8s_resource_annotations_file"
            ;;
        esac
      fi
    ;;
    spring)
      case "$file_resource"
      in
        application-properties)
          case "$command"
          in
            edit)
              edit_file "$SPRING_APPLICATION_PROPERTIES" "$SPRING_APPLICATION_PROPERTIES_COPY"
            ;;
            show)
              show_file "$SPRING_APPLICATION_PROPERTIES"
            ;;
            path)
              locate_file "$SPRING_APPLICATION_PROPERTIES"
            ;;
            erase)
              erase_file "$SPRING_APPLICATION_PROPERTIES"
            ;;
            restore)
              restore_file "$SPRING_APPLICATION_PROPERTIES_COPY" "$SPRING_APPLICATION_PROPERTIES"
            ;;
          esac
        ;;
      esac
    ;;
    cache)
      case "$command"
      in
        edit)
          [[ -s "$DIB_APP_CACHE_FILE" ]] || save_data_to_app_cache
          edit_file "$DIB_APP_CACHE_FILE" "$DIB_APP_CACHE_FILE_COPY"
        ;;
        show)
          show_file "$DIB_APP_CACHE_FILE"
        ;;
        path)
          locate_file "$DIB_APP_CACHE_FILE"
        ;;
        erase)
          erase_file "$DIB_APP_CACHE_FILE"
        ;;
        restore)
          restore_file "$DIB_APP_CACHE_FILE_COPY" "$DIB_APP_CACHE_FILE"
        ;;
      esac
    ;;
    run)
      case "$file_resource"
      in
        dockercomposefile)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE" "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE_COPY" 
            ;;
            show)
              show_file "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            view)
              view_file "$DIB_APP_RUN_DOCKER_COMPOSE_FILE"
            ;;
            path)
              locate_file "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            erase)
              erase_file "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
            restore)
              restore_file "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE_COPY" "$DIB_APP_RUN_DOCKER_COMPOSE_TEMPLATE_FILE"
            ;;
          esac
        ;;
      esac
    ;;
  esac
}

## -- finish

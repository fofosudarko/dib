#!/bin/bash
#
# File: file.sh -> common file operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
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

  run_as "$DIB_USER" "[[ -s '$file' ]] && cp '$file' '$file_copy' ; exec $EDITOR_CMD '$file'"
}

function show_file() {
  local file="$1"

  run_as "$DIB_USER" "exec $PAGER_CMD '$file'"
}

function locate_file() {
  local file="$1"

  run_as "$DIB_USER" "exec ls '$file'"
}

function parse_edit_command() {
  local file_type="$1" file_resource="$2"

  parse_file_command "edit" "$file_type" "$file_resource"
}

function parse_show_command() {
  local file_type="$1" file_resource="$2"

  parse_file_command "show" "$file_type" "$file_resource"
}

function parse_path_command() {
  local file_type="$1" file_resource="$2"

  parse_file_command "path" "$file_type" "$file_resource"
}

function parse_file_command() {
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
              edit_file "$DIB_APP_ENV_CHANGED_FILE" "$DIB_APP_ENV_CHANGED_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
        common-env)
          case "$command"
          in
            edit)
               edit_file "$DIB_APP_COMMON_ENV_CHANGED_FILE" "$DIB_APP_COMMON_ENV_CHANGED_FILE_COPY"
            ;;
            show)
               show_file "$DIB_APP_COMMON_ENV_CHANGED_FILE"
            ;;
            path)
               locate_file "$DIB_APP_COMMON_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
        service-env)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE" "$DIB_APP_SERVICE_ENV_CHANGED_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_SERVICE_ENV_CHANGED_FILE"
            ;;
          esac
        ;;
        project-env)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE" "$DIB_APP_PROJECT_ENV_CHANGED_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
            ;;
            path)
              locate_file "$DIB_APP_PROJECT_ENV_CHANGED_FILE"
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
          esac
        ;;
        dockercomposefile)
          case "$command"
          in
            edit)
              edit_file "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE" "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE"
            ;;
            path)
              locate_file "$DIB_APP_CONFIG_COMPOSE_TEMPLATE_FILE"
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
              edit_file "$DIB_APP_COMPOSE_COMPOSE_TEMPLATE_FILE" "$DIB_APP_COMPOSE_COMPOSE_TEMPLATE_FILE_COPY"
            ;;
            show)
              show_file "$DIB_APP_COMPOSE_COMPOSE_TEMPLATE_FILE"
            ;;
            path)
              locate_file "$DIB_APP_COMPOSE_COMPOSE_TEMPLATE_FILE"
            ;;
          esac
        ;;
      esac
    ;;
    k8s-annotations)
      if [[ -n "$file_resource" ]]
      then
        k8s_annotations_file="${DIB_APP_K8S_ANNOTATIONS_CHANGED_FILE/$K8S_RESOURCE_ANNOTATION_TEMPLATE/$file_resource}"
        k8s_annotations_file_copy="${DIB_APP_K8S_ANNOTATIONS_CHANGED_FILE_COPY/$K8S_RESOURCE_ANNOTATION_TEMPLATE/$file_resource}"

        case "$command"
          in
            edit)
              edit_file "$k8s_annotations_file" "$k8s_annotations_file_copy"
            ;;
            show)
              show_file "$k8s_annotations_file"
            ;;
            path)
              locate_file "$k8s_annotations_file"
            ;;
        esac
      fi
    ;;
    springboot)
      case "$file_resource"
      in
        application-properties)
          case "$command"
          in
            edit)
              edit_file "$SPRINGBOOT_APPLICATION_PROPERTIES" "$SPRINGBOOT_APPLICATION_PROPERTIES_COPY"
            ;;
            show)
              show_file "$SPRINGBOOT_APPLICATION_PROPERTIES"
            ;;
            path)
              locate_file "$SPRINGBOOT_APPLICATION_PROPERTIES"
            ;;
          esac
        ;;
      esac
    ;;
    cache)
      case "$command"
      in
        edit)
          edit_file "$DIB_APP_CACHE_FILE" "$DIB_APP_CACHE_FILE_COPY"
        ;;
        show)
          show_file "$DIB_APP_CACHE_FILE"
        ;;
        path)
          locate_file "$DIB_APP_CACHE_FILE"
        ;;
      esac
    ;;
  esac
}

## -- finish

#!/bin/bash
#
# File: editor.sh -> common editor operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source editor.sh
#
#

## - start here

function edit_file() {
  local file="$1" file_copy="$2"

  run_as "$DOCKER_USER" "
  [[ -s '$file' ]] && cp '$file' '$file_copy'

  exec $EDITOR_CMD '$file'

  exit \$?
  " || return 1

  return 0
}

function parse_edit_command() {
  local file_type="$1" file_resource="$2" edit_status=

  case "$file_type"
  in
    env)
      case "$file_resource"
      in
        app-env)
          if edit_file "$DOCKER_APP_ENV_CHANGED_FILE" "$DOCKER_APP_ENV_CHANGED_FILE_COPY"
          then
            msg "$DOCKER_APP_ENV_CHANGED_FILE edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
        common-env)
          if edit_file "$DOCKER_APP_COMMON_ENV_CHANGED_FILE" "$DOCKER_APP_COMMON_ENV_CHANGED_FILE_COPY"
          then
            msg "$DOCKER_APP_COMMON_ENV_CHANGED_FILE edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
        service-env)
          if edit_file "$DOCKER_APP_SERVICE_ENV_CHANGED_FILE" "$DOCKER_APP_SERVICE_ENV_CHANGED_FILE_COPY"
          then
            msg "$DOCKER_APP_SERVICE_ENV_CHANGED_FILE edited successfully"
            edit_status=0 
          else
            edit_status=1
          fi
        ;;
        project-env)
          if edit_file "$DOCKER_APP_PROJECT_ENV_CHANGED_FILE" "$DOCKER_APP_PROJECT_ENV_CHANGED_FILE_COPY"
          then
            msg "$DOCKER_APP_PROJECT_ENV_CHANGED_FILE edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
      esac
    ;;
    config)
      case "$file_resource"
      in
        dockerfile)
          if edit_file "$DOCKER_APP_CONFIG_DOCKER_FILE" "$DOCKER_APP_CONFIG_DOCKER_FILE_COPY"
          then
            msg "$DOCKER_APP_CONFIG_DOCKER_FILE edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
        dockercomposefile)
          if edit_file "$DOCKER_APP_CONFIG_COMPOSE_TEMPLATE_FILE" "$DOCKER_APP_CONFIG_COMPOSE_TEMPLATE_FILE_COPY"
          then
            msg "$DOCKER_APP_CONFIG_COMPOSE_TEMPLATE_FILE edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
        runscript)
          if edit_file "$DOCKER_APP_CONFIG_RUN_SCRIPT" "$DOCKER_APP_CONFIG_RUN_SCRIPT_COPY"
          then
            msg "$DOCKER_APP_CONFIG_RUN_SCRIPT edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
      esac
    ;;
    compose)
      case "$file_resource"
      in
        dockercomposefile)
          if edit_file "$DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE" "$DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE_COPY"
          then
            msg "$DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
      esac
    ;;
    k8s-annotations)
      if [[ -n "$file_resource" ]]
      then
        k8s_annotations_file="${DOCKER_APP_K8S_ANNOTATIONS_CHANGED_FILE/$K8S_RESOURCE_ANNOTATION_TEMPLATE/$file_resource}"
        k8s_annotations_file_copy="${DOCKER_APP_K8S_ANNOTATIONS_CHANGED_FILE_COPY/$K8S_RESOURCE_ANNOTATION_TEMPLATE/$file_resource}"

        if edit_file "$k8s_annotations_file" "$k8s_annotations_file_copy"
        then
          msg "$k8s_annotations_file edited successfully"
          edit_status=0 
        else
          edit_status=1
        fi
      fi
    ;;
    springboot)
      case "$file_resource"
      in
        application-properties)
          if edit_file "$SPRINGBOOT_APPLICATION_PROPERTIES" "$SPRINGBOOT_APPLICATION_PROPERTIES_COPY"
          then
            msg "$SPRINGBOOT_APPLICATION_PROPERTIES edited successfully"
            edit_status=0
          else
            edit_status=1
          fi
        ;;
      esac
    ;;
  esac

  return "$edit_status"
}

## -- finish

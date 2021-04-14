#!/bin/bash
#
# File: paths.sh -> common paths
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source paths.sh
#
#

## - start here

# dib

: ${DIB_APP_DOCKER_BUILD_FILES="$DIB_APP_CONFIG_DIR/Dockerfile"}
: ${DIB_APP_DOCKER_COMPOSE_BUILD_FILES="$DIB_APP_CONFIG_DIR/{Dockerfile,docker-compose.yml}"}
: ${DIB_APP_PROJECT_ENV_CHANGED_FILE="$DIB_APP_PROJECT_ENV_DIR/project.env.changed"}
: ${DIB_APP_PROJECT_ENV_CHANGED_FILE_COPY="${DIB_APP_PROJECT_ENV_CHANGED_FILE}.copy"}
: ${DIB_APP_COMMON_ENV_CHANGED_FILE="$DIB_APP_COMMON_ENV_DIR/common.env.changed"}
: ${DIB_APP_COMMON_ENV_CHANGED_FILE_COPY="${DIB_APP_COMMON_ENV_CHANGED_FILE}.copy"}
: ${DIB_APP_SERVICE_ENV_CHANGED_FILE="$DIB_APP_SERVICE_ENV_DIR/service.env.changed"}
: ${DIB_APP_SERVICE_ENV_CHANGED_FILE_COPY="${DIB_APP_SERVICE_ENV_CHANGED_FILE}.copy"}
: ${DIB_APP_ENV_CHANGED_FILE="$DIB_APP_COMPOSE_DIR/app.env.changed"}
: ${DIB_APP_ENV_CHANGED_FILE_COPY="${DIB_APP_ENV_CHANGED_FILE}.copy"}
: ${DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE="$DIB_APP_COMPOSE_DIR/docker-compose.template.yml"}
: ${DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE_COPY="${DIB_APP_COMPOSE_DOCKER_COMPOSE_TEMPLATE_FILE}.copy"}
: ${DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE="$DIB_APP_CONFIG_DIR/docker-compose.template.yml"}
: ${DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE_COPY="${DIB_APP_CONFIG_DOCKER_COMPOSE_TEMPLATE_FILE}.copy"}
: ${DIB_APP_K8S_RESOURCE_ANNOTATIONS_CHANGED_FILE="$DIB_APP_K8S_ANNOTATIONS_DIR/$K8S_RESOURCE_TEMPLATE.k8s-annotations.changed"}
: ${DIB_APP_K8S_RESOURCE_ANNOTATIONS_CHANGED_FILE_COPY="${DIB_APP_K8S_RESOURCE_ANNOTATIONS_CHANGED_FILE}.copy"}
: ${DIB_APP_CONFIG_DOCKER_FILE="$DIB_APP_CONFIG_DIR/Dockerfile"}
: ${DIB_APP_CONFIG_DOCKER_FILE_COPY="${DIB_APP_CONFIG_DOCKER_FILE}.copy"}
: ${DIB_APP_CONFIG_RUN_SCRIPT="$DIB_APP_CONFIG_DIR/run.sh"}
: ${DIB_APP_CONFIG_RUN_SCRIPT_COPY="${DIB_APP_CONFIG_RUN_SCRIPT}.copy"}
: ${DIB_APP_CACHE_FILE="$DIB_APP_CACHE_DIR/cache"}
: ${DIB_APP_CACHE_FILE_COPY="${DIB_APP_CACHE_FILE}.copy"}

# springboot

: ${SPRINGBOOT_APPLICATION_PROPERTIES_DIR="$DIB_APP_BUILD_DEST/src/main/resources"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES="$DIB_APP_CONFIG_DIR/application.properties"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES_COPY="${SPRINGBOOT_APPLICATION_PROPERTIES}.copy"}
: ${MAVEN_WRAPPER_PROPERTIES_SRC="${DIB_APPS_CONFIG_DIR}/${APP_FRAMEWORK}/maven-wrapper/"}
: ${MAVEN_WRAPPER_PROPERTIES_DEST="$DIB_APP_BUILD_DEST"}

## -- finish

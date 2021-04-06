#!/bin/bash
#
# File: variables.sh -> common variables
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source variables.sh
#
#

## - start here

# globals

: ${BUILD_DATE=`date +'%Y%m%d'`}
: ${USE_GIT_COMMIT=${DIB_USE_GIT_COMMIT:-'false'}}
: ${USE_BUILD_DATE=${DIB_USE_BUILD_DATE:-'false'}}
: ${USE_SUDO=${DIB_USE_SUDO:-'false'}}
: ${EDITOR_CMD=${EDITOR:-"$NANO_CMD"}}

# filters

: ${DIB_RUN_COMMANDS='^(build|build\-push|build\-push\-deploy|push|deploy|doctor)$'}
: ${DIB_APP_ENVIRONMENTS='^(development|staging|beta|production|demo|alpha)$'}
: ${DIB_APP_FRAMEWORKS='^(springboot|angular|react|flask|express|mux|feathers|nuxt|next)$'}

# templates

: ${K8S_RESOURCE_ANNOTATION_TEMPLATE='@@K8S_RESOURCE_ANNOTATION@@'}

# users

: ${DOCKER_USER=${DIB_DOCKER_USER:-'docker'}}
: ${CI_USER=${DIB_CI_USER:-'jenkins'}}
: ${SUPER_USER=${DIB_SUPER_USER:-'root'}}

# app

: ${APP_PROJECT=${DIB_APP_PROJECT:-'example-project'}}
: ${APP_FRAMEWORK=${DIB_APP_FRAMEWORK:-''}}
: ${APP_ENVIRONMENT=${DIB_APP_ENVIRONMENT:-'development'}}
: ${APP_IMAGE=${DIB_APP_IMAGE:-'example-service'}}
: ${APP_IMAGE_TAG=${DIB_APP_IMAGE_TAG:-"$(get_app_image_tag "$DIB_APP_IMAGE_TAG")"}}
: ${APP_KUBERNETES_NAMESPACE=${DIB_APP_KUBERNETES_NAMESPACE:-'default'}}
: ${APP_DB_CONNECTION_POOL=${DIB_APP_DB_CONNECTION_POOL:-'transaction'}}
: ${APP_KUBERNETES_CONTEXT=${DIB_APP_KUBERNETES_CONTEXT:-'microk8s'}}
: ${APP_BUILD_MODE=${DIB_APP_BUILD_MODE:-'spa'}}
: ${APP_NPM_RUN_COMMANDS=${DIB_APP_NPM_RUN_COMMANDS:-'build:docker'}}
: ${APP_BASE_HREF=${DIB_APP_BASE_HREF:-'/'}}
: ${APP_DEPLOY_URL=${DIB_APP_DEPLOY_URL:-'/'}}
: ${APP_BUILD_CONFIGURATION=${DIB_APP_BUILD_CONFIGURATION:-'staging-docker'}}
: ${APP_NPM_BUILD_COMMAND_DELIMITER=${DIB_APP_NPM_BUILD_COMMAND_DELIMITER:-','}}
: ${APP_REPO=${DIB_APP_REPO:-'example-service'}}

# ci

: ${CI_WORKSPACE=${DIB_CI_WORKSPACE:-'/var/lib/jenkins/workspace'}}
: ${CI_JOB=${DIB_CI_JOB:-"${APP_IMAGE}-job"}}

# dib

: ${DIB_HOME=${DIB_HOME:-'/home/docker'}}
: ${DIB_CACHE="${DIB_HOME}/.cache"}

# docker

: ${DOCKER_LOGIN_USERNAME=${DIB_DOCKER_LOGIN_USERNAME:-'builder-script'}}
: ${DOCKER_LOGIN_PASSWORD=${DIB_DOCKER_LOGIN_PASSWORD:-"$DIB_HOME/.secrets/${DOCKER_LOGIN_USERNAME}"}}
: ${DOCKER_APPS_DIR="$DIB_HOME/apps"}
: ${DOCKER_APPS_CONFIG_DIR="$DIB_HOME/config"}
: ${DOCKER_APPS_KEYSTORES_DIR="$DIB_HOME/keystores"}
: ${DOCKER_APPS_COMPOSE_DIR="$DIB_HOME/compose"}
: ${DOCKER_APPS_ENV_DIR="$DIB_HOME/env"}
: ${DOCKER_APPS_K8S_ANNOTATIONS_DIR="$DIB_HOME/k8s-annotations"}
: ${DOCKER_APPS_KUBERNETES_DIR="$DIB_HOME/.kube"}
: ${DOCKER_APPS_CONTAINER_REGISTRY=${DIB_CONTAINER_REGISTRY:-'docker.io'}}
: ${DOCKER_APP_BUILD_SRC=${DIB_APP_BUILD_SRC:-"$CI_WORKSPACE/$CI_JOB"}}
: ${DOCKER_APP_BUILD_DEST="$DOCKER_APPS_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_JOB"}
: ${DOCKER_APP_CONFIG_DIR="$DOCKER_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_JOB"}
: ${DOCKER_APP_COMPOSE_DIR="$DOCKER_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_JOB"}
: ${DOCKER_APP_COMPOSE_K8S_DIR="$DOCKER_APP_COMPOSE_DIR/kubernetes"}
: ${DOCKER_APP_K8S_ANNOTATIONS_DIR="$DOCKER_APPS_K8S_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_JOB"}
: ${DOCKER_APP_BUILD_FILES="$DOCKER_APP_CONFIG_DIR/*{Dockerfile,docker-compose}*"}
: ${DOCKER_APP_KEYSTORES_SRC="$DIB_HOME/keystores/$APP_PROJECT/$APP_ENVIRONMENT/keystores"}
: ${DOCKER_APP_KEYSTORES_DEST="$DOCKER_APP_BUILD_DEST"}
: ${DOCKER_APP_COMMON_ENV_DIR="$DOCKER_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_ENVIRONMENT"}
: ${DOCKER_APP_PROJECT_ENV_DIR="$DOCKER_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT"}
: ${DOCKER_APP_SERVICE_ENV_DIR="$DOCKER_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE"}
: ${DOCKER_APP_PROJECT_ENV_CHANGED_FILE="$DOCKER_APP_PROJECT_ENV_DIR/project.env.changed"}
: ${DOCKER_APP_PROJECT_ENV_CHANGED_FILE_COPY="${DOCKER_APP_PROJECT_ENV_CHANGED_FILE}.copy"}
: ${DOCKER_APP_COMMON_ENV_CHANGED_FILE="$DOCKER_APP_COMMON_ENV_DIR/common.env.changed"}
: ${DOCKER_APP_COMMON_ENV_CHANGED_FILE_COPY="${DOCKER_APP_COMMON_ENV_CHANGED_FILE}.copy"}
: ${DOCKER_APP_SERVICE_ENV_CHANGED_FILE="$DOCKER_APP_SERVICE_ENV_DIR/service.env.changed"}
: ${DOCKER_APP_SERVICE_ENV_CHANGED_FILE_COPY="${DOCKER_APP_SERVICE_ENV_CHANGED_FILE}.copy"}
: ${DOCKER_APP_ENV_CHANGED_FILE="$DOCKER_APP_COMPOSE_DIR/app.env.changed"}
: ${DOCKER_APP_ENV_CHANGED_FILE_COPY="${DOCKER_APP_ENV_CHANGED_FILE}.copy"}
: ${DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE="$DOCKER_APP_COMPOSE_DIR/docker-compose.template.yml"}
: ${DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE_COPY="${DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE}.copy"}
: ${DOCKER_APP_CONFIG_COMPOSE_TEMPLATE_FILE="$DOCKER_APP_CONFIG_DIR/docker-compose.template.yml"}
: ${DOCKER_APP_CONFIG_COMPOSE_TEMPLATE_FILE_COPY="${DOCKER_APP_CONFIG_COMPOSE_TEMPLATE_FILE}.copy"}
: ${DOCKER_APP_K8S_ANNOTATIONS_CHANGED_FILE="$DOCKER_APP_K8S_ANNOTATIONS_DIR/$K8S_RESOURCE_ANNOTATION_TEMPLATE.k8s-annotations.changed"}
: ${DOCKER_APP_K8S_ANNOTATIONS_CHANGED_FILE_COPY="${DOCKER_APP_K8S_ANNOTATIONS_CHANGED_FILE}.copy"}
: ${DOCKER_APP_CONFIG_DOCKER_FILE="$DOCKER_APP_CONFIG_DIR/Dockerfile"}
: ${DOCKER_APP_CONFIG_DOCKER_FILE_COPY="${DOCKER_APP_CONFIG_DOCKER_FILE}.copy"}
: ${DOCKER_APP_CONFIG_RUN_SCRIPT="$DOCKER_APP_CONFIG_DIR/run.sh"}
: ${DOCKER_APP_CONFIG_RUN_SCRIPT_COPY="${DOCKER_APP_CONFIG_RUN_SCRIPT}.copy"}
: ${DOCKER_FILE="$DOCKER_APP_BUILD_DEST/Dockerfile"}

# kompose

: ${KOMPOSE_IMAGE_PULL_SECRET=${DIB_KOMPOSE_IMAGE_PULL_SECRET:-'your-builder-script'}}
: ${KOMPOSE_IMAGE_PULL_POLICY=${DIB_KOMPOSE_IMAGE_PULL_POLICY:-'Always'}}
: ${KOMPOSE_SERVICE_TYPE=${DIB_KOMPOSE_SERVICE_TYPE:-'nodeport'}}
: ${KOMPOSE_SERVICE_EXPOSE=${DIB_KOMPOSE_SERVICE_EXPOSE:-'service-test.example.com'}}
: ${KOMPOSE_SERVICE_EXPOSE_TLS_SECRET=${DIB_KOMPOSE_SERVICE_EXPOSE_TLS_SECRET:-'example-service-staging'}}
: ${KOMPOSE_SERVICE_NODEPORT_PORT=${DIB_KOMPOSE_SERVICE_NODEPORT_PORT:-'5000'}}

# kubernetes

: ${KUBE_HOME=${KUBE_HOME:-${DOCKER_APPS_KUBERNETES_DIR}}}
: ${KUBECONFIGS=${DIB_KUBECONFIGS:-'microk8s-config'}}
: ${KUBERNETES_SERVICE_LABEL=${DIB_KUBERNETES_SERVICE_LABEL:-'io.kompose.service'}}

# springboot

: ${SPRINGBOOT_APPLICATION_PROPERTIES_DIR="$DOCKER_APP_BUILD_DEST/src/main/resources"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES="$DOCKER_APP_CONFIG_DIR/application.properties"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES_COPY="${SPRINGBOOT_APPLICATION_PROPERTIES}.copy"}
: ${MAVEN_WRAPPER_PROPERTIES_SRC="${DOCKER_APPS_CONFIG_DIR}/${APP_FRAMEWORK}/maven-wrapper/"}
: ${MAVEN_WRAPPER_PROPERTIES_DEST="$DOCKER_APP_BUILD_DEST"}

## -- finish

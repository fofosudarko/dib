#!/bin/bash
#
# File: vars.sh -> common variables
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source vars.sh
#
#

## - start here

: ${DOCKER_CMD="$(which docker)"}
: ${DOCKER_COMPOSE_CMD="$(which docker-compose)"}
: ${KOMPOSE_CMD="$(which kompose)"}
: ${KUBECTL_CMD="$(which kubectl)"}
: ${CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-hub.docker.com}}
: ${RUN_COMMANDS='^(build|build\-push|build\-push\-deploy|push|deploy)$'}
: ${APP_ENVIRONMENTS='^(development|staging|beta|production|demo|alpha)$'}
: ${CI_SERVER_WORKSPACE='/var/lib/jenkins/workspace'}
: ${DOCKER_USER='docker'}
: ${JENKINS_USER='jenkins'}
: ${SUPER_USER='root'}
: ${DOCKER_HOME='/home/docker'}
: ${DOCKER_APPS_DIR="$DOCKER_HOME/apps"}
: ${DOCKER_APPS_CONFIG_DIR="$DOCKER_HOME/config"}
: ${DOCKER_APPS_KEYSTORES_DIR="$DOCKER_HOME/keystores"}
: ${DOCKER_APPS_COMPOSE_DIR="$DOCKER_HOME/compose"}
: ${DOCKER_APPS_ENV_DIR="$DOCKER_HOME/env"}
: ${DOCKER_APPS_KUBERNETES_ANNOTATIONS_DIR="$DOCKER_HOME/k8s-annotations"}
: ${DOCKER_APPS_KUBERNETES_DIR="$DOCKER_HOME/.kube"}
: ${DOCKER_APP_BUILD_SRC="$CI_SERVER_WORKSPACE/$CI_SERVER_JOB"}
: ${DOCKER_APP_BUILD_DEST="$DOCKER_APPS_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_SERVER_JOB"}
: ${DOCKER_APP_CONFIG_DIR="$DOCKER_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_SERVER_JOB"}
: ${DOCKER_APP_COMPOSE_DIR="$DOCKER_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_SERVER_JOB"}
: ${DOCKER_APP_COMPOSE_K8S_DIR="$DOCKER_APP_COMPOSE_DIR/kubernetes"}
: ${DOCKER_APP_K8S_ANNOTATIONS_DIR="$DOCKER_APPS_KUBERNETES_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$CI_SERVER_JOB"}
: ${DOCKER_APP_BUILD_FILES="$DOCKER_APP_CONFIG_DIR/*{Dockerfile,docker-compose}*"}
: ${DOCKER_LOGIN_USERNAME=${DOCKER_LOGIN_USERNAME:-'builder-script'}}
: ${DOCKER_LOGIN_PASSWORD="$DOCKER_HOME/.secrets/${DOCKER_LOGIN_USERNAME}"}
: ${DOCKER_APP_KEYSTORES_SRC="$DOCKER_HOME/keystores/$APP_PROJECT/$APP_ENVIRONMENT/keystores"}
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
: ${MAVEN_WRAPPER_PROPERTIES_SRC="${DOCKER_APPS_CONFIG_DIR}/${APP_FRAMEWORK}/maven-wrapper/"}
: ${MAVEN_WRAPPER_PROPERTIES_DEST="$DOCKER_APP_BUILD_DEST"}
: ${BUILD_DATE=`date +'%Y%m%d'`}
: ${KUBE_HOME=${KUBE_HOME:-${DOCKER_APPS_KUBERNETES_DIR}}}
: ${SPRINGBOOT_APPLICATION_PROPERTIES_DIR="$DOCKER_APP_BUILD_DEST/src/main/resources"}
: ${SPRINGBOOT_BASE_APPLICATION_PROPERTIES="$DOCKER_APP_CONFIG_DIR/application.properties"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES="$DOCKER_APP_CONFIG_DIR/application-docker.properties"}

## -- finish

#!/bin/bash
#
# File: init.sh -> init variables
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source init.sh
#
#

## - start here

# init

# filters

: ${DIB_RUN_COMMANDS='^(build|build\-push|build\-push\-deploy|push|deploy|doctor)$'}
: ${DIB_APP_ENVIRONMENTS='^(dev|develop|development|staging|beta|prod|production|demo|alpha)$'}
: ${DIB_APP_FRAMEWORKS='^(springboot|angular|react|flask|express|mux|feathers|nuxt|next)$'}
: ${DIB_APP_INVALID_PATH_TOKENS='example\-(project|framework|environment|service)'}
: ${DIB_APP_CONFIG_EXCLUDE_PATTERNS='*Dockerfile*\n*docker-compose*\n*application*properties\n'}

# globals

: ${BUILD_DATE=`date +'%Y%m%d'`}
: ${USE_GIT_COMMIT=${DIB_USE_GIT_COMMIT:-'false'}}
: ${USE_BUILD_DATE=${DIB_USE_BUILD_DATE:-'false'}}
: ${USE_SUDO=${DIB_USE_SUDO:-'false'}}
: ${EDITOR_CMD=${EDITOR:-"$NANO_CMD"}}
: ${PAGER_CMD=${PAGER:-"$LESS_CMD"}}

# users

: ${DIB_USER=${DIB_DOCKER_USER:-'docker'}}
: ${CI_USER=${DIB_CI_USER:-'jenkins'}}
: ${SUPER_USER=${DIB_SUPER_USER:-'root'}}

# placeholders

: ${DIB_HOME_PLACEHOLDER='/home/example'}
: ${DIB_APP_PROJECT_PLACEHOLDER='example-project'}
: ${DIB_APP_IMAGE_PLACEHOLDER='example-service'}
: ${DIB_APP_FRAMEWORK_PLACEHOLDER='example-framework'}
: ${DIB_APP_ENVIRONMENT_PLACEHOLDER='example-environment'}


: ${DIB_HOME=${DIB_HOME:-$DIB_HOME_PLACEHOLDER}}
: ${DIB_CACHE="${DIB_HOME}/.cache"}
: ${DIB_APPS_DIR="$DIB_HOME/apps"}
: ${DIB_APPS_CONFIG_DIR="$DIB_HOME/config"}
: ${DIB_APPS_KEYSTORES_DIR="$DIB_HOME/keystores"}
: ${DIB_APPS_COMPOSE_DIR="$DIB_HOME/compose"}
: ${DIB_APPS_ENV_DIR="$DIB_HOME/env"}
: ${DIB_APPS_K8S_ANNOTATIONS_DIR="$DIB_HOME/k8s-annotations"}
: ${DIB_APPS_KUBERNETES_DIR="$DIB_HOME/.kube"}
: ${DIB_APPS_CACHE_DIR="$DIB_HOME/cache"}
: ${DIB_APP_ROOT_CACHE_FILE="$DIB_APPS_CACHE_DIR/root_cache"}
: ${DIB_APP_ROOT_CACHE_FILE_COPY="${DIB_APP_ROOT_CACHE_FILE}.copy"}

# templates

: ${K8S_RESOURCE_ANNOTATION_TEMPLATE='@@K8S_RESOURCE_ANNOTATION@@'}

## -- finish

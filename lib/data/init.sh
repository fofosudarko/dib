#!/bin/bash
#
# File: init.sh -> init variables
#
# Usage: source init.sh
#
#

## - start here

# init

# filters

: ${DIB_APP_ENVIRONMENTS='^(dev|develop|development|test|staging|beta|prod|production|demo|alpha)$'}
: ${DIB_APP_FRAMEWORKS='^(spring|angular|react|flask|express|mux|feathers|nuxt|next|rails|django|hugo|jekyll|gatsby|dotnet|vue|laravel|redwood)$'}
: ${DIB_APP_INVALID_PATH_TOKENS='example\-(project|framework|environment|service)'}
: ${DIB_APP_CONFIG_EXCLUDE_PATTERNS='application*properties\n*copy'}
: ${DIB_APP_DATABASE_KEY_PATTERN='^[[:alnum:]]+$'}
: ${DIB_APP_DATABASE_VALUE_PATTERN='^[[:alnum:]]+\:[[:alnum:]_-]+\:[[:alnum:]_-]+$'}

# globals

: ${BUILD_DATE=`date +'%Y%m%d'`}
: ${USE_GIT_COMMIT=${DIB_USE_GIT_COMMIT:-'false'}}
: ${USE_BUILD_DATE=${DIB_USE_BUILD_DATE:-'false'}}
: ${USE_APP_ENVIRONMENT=${DIB_USE_APP_ENVIRONMENT:-'false'}}
: ${USE_MERCURIAL_REVISION=${DIB_USE_MERCURIAL_REVISION:-'false'}}
: ${EDITOR_CMD=${EDITOR:-"$NANO_CMD"}}
: ${PAGER_CMD=${PAGER:-"$LESS_CMD"}}

# placeholders

: ${DIB_HOME_PLACEHOLDER='/home/example'}
: ${DIB_APP_PROJECT_PLACEHOLDER='example-project'}
: ${DIB_APP_IMAGE_PLACEHOLDER='example-service'}
: ${DIB_APP_FRAMEWORK_PLACEHOLDER='example-framework'}
: ${DIB_APP_ENVIRONMENT_PLACEHOLDER='example-environment'}
: ${DIB_APP_VERSION='v1.1.0'}

# dirs

: ${DIB_HOME=${DIB_HOME:-$DIB_HOME_PLACEHOLDER}}
: ${DIB_APPS_APPS_DIR="$DIB_HOME/apps"}
: ${DIB_APPS_CONFIG_DIR="$DIB_HOME/config"}
: ${DIB_APPS_KEYSTORES_DIR="$DIB_HOME/keystores"}
: ${DIB_APPS_COMPOSE_DIR="$DIB_HOME/compose"}
: ${DIB_APPS_ENV_DIR="$DIB_HOME/env"}
: ${DIB_APPS_K8S_ANNOTATIONS_DIR="$DIB_HOME/k8s-annotations"}
: ${DIB_APPS_KUBERNETES_DIR="$DIB_HOME/.kube"}
: ${DIB_APPS_CACHE_DIR="$DIB_HOME/.cache"}
: ${DIB_APPS_SECRETS_DIR="$DIB_HOME/.secrets"}
: ${DIB_APPS_RUN_DIR="$DIB_HOME/run"}

# templates

: ${K8S_RESOURCE_TEMPLATE='{{K8S_RESOURCE_TEMPLATE}}'}
: ${ROOT_CACHE_DIR_TEMPLATE='{{ROOT_CACHE_DIR_TEMPLATE}}'}

# files

DIB_APP_DATABASE_FILE="$DIB_APPS_CACHE_DIR/.dib-database"
DIB_APP_DATABASE_FILE_COPY="${DIB_APP_DATABASE_FILE}.copy"
DIB_APP_ROOT_CACHE_FILE="$DIB_APPS_CACHE_DIR/$ROOT_CACHE_DIR_TEMPLATE/root_cache"
DIB_APP_ROOT_CACHE_FILE_COPY="${DIB_APP_ROOT_CACHE_FILE}.copy"
DIB_APP_TMP_FILE=$(mktemp)

## -- finish

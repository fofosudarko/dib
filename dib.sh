#!/bin/bash
#
# File: dib.sh -> Build, push docker images to a registry and/or deploy to a Kubernetes cluster
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: bash dib.sh RUN_COMMAND CI_SERVER_JOB APP_PROJECT APP_ENVIRONMENT APP_FRAMEWORK APP_IMAGE 
#   ENV_VARS: APP_IMAGE_TAG APP_KUBERNETES_NAMESPACE APP_DB_CONNECTION_POOL
#             APP_KUBERNETES_CONTEXT APP_BUILD_MODE APP_NPM_RUN_COMMANDS KUBECONFIGS
#             KUBERNETES_SERVICE_LABEL USE_GIT_COMMIT USE_BUILD_DATE
#
#

## - start here

set -eux

: ${SCRIPT_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))}

loadFunctions ()
{
  local lib="${SCRIPT_DIR}/lib"
  
  test -f "$lib/vars.sh" && source "$lib/vars.sh"
  test -f "$lib/common.sh" && source "$lib/common.sh"
  test -f "$lib/springboot.sh" && source "$lib/springboot.sh"
  test -f "$lib/docker.sh"  && source "$lib/docker.sh"
  test -f "$lib/kubernetes.sh" && source "$lib/kubernetes.sh"
}

COMMAND="$0"

if [[ "$#" -ne 6 ]]
then
  msg 'expects 5 arguments i.e. RUN_COMMAND CI_SERVER_JOB APP_PROJECT APP_FRAMEWORK APP_IMAGE'
  exit 1
fi

RUN_COMMAND="${1:-build}"
CI_SERVER_JOB="$2"
APP_PROJECT="$3"
APP_ENVIRONMENT="$4"
APP_FRAMEWORK="$5"
APP_IMAGE="$6"

APP_IMAGE_TAG=${APP_IMAGE_TAG:-latest}
APP_KUBERNETES_NAMESPACE=${APP_KUBERNETES_NAMESPACE:-default}
APP_DB_CONNECTION_POOL=${APP_DB_CONNECTION_POOL:-transaction}
APP_KUBERNETES_CONTEXT=${APP_KUBERNETES_CONTEXT:-microk8s}
APP_BUILD_MODE=${APP_BUILD_MODE:-spa}
APP_NPM_RUN_COMMANDS=${APP_NPM_RUN_COMMANDS:-'build:docker'}
KUBERNETES_SERVICE_LABEL=${KUBERNETES_SERVICE_LABEL:-'io.kompose.service'}

loadFunctions

KUBECONFIGS_INITIAL=microk8s-config
KUBECONFIGS=${KUBECONFIGS:-${KUBECONFIGS_INITIAL}}
KUBECONFIG=
DOCKER_COMPOSE_FILE_CHANGED=0
K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=0
APP_ENV_FILE_CHANGED=0
APP_COMMON_ENV_FILE_CHANGED=0
APP_PROJECT_ENV_FILE_CHANGED=0
APP_SERVICE_ENV_FILE_CHANGED=0
APP_IMAGE_TAG=$(getAppImageTag)
DOCKERFILE=$DOCKER_APP_BUILD_DEST/Dockerfile

# test Run commands
[[ -x "$DOCKER_CMD" ]] || { msg 'docker command not found'; exit 1; }
[[ -x "$DOCKER_COMPOSE_CMD" ]] || { msg 'docker-compose command not found'; exit 1; }
[[ -x "$KOMPOSE_CMD" ]] || { msg 'kompose command not found'; exit 1; }
[[ -x "$KUBECTL_CMD" ]] || { msg 'kubectl command not found'; exit 1; }

# check kompose version
if ! isKomposeVersionValid
then
  msg "Invalid kompose command version. Please upgrade to a version greater than 1.20.x"
  exit 1
fi

# check passed Run command
if ! echo -ne "$RUN_COMMAND"| grep -qP "$RUN_COMMANDS"
then
  msg "Run command must be in $RUN_COMMANDS"
  exit 1
fi

# check passed app environment
if ! echo -ne "$APP_ENVIRONMENT"| grep -qP "$APP_ENVIRONMENTS"
then
  msg "App environment must be in $APP_ENVIRONMENTS"
  exit 1
fi

createDefaultDirectoriesIfNotExist

copyDockerProject "$DOCKER_APP_BUILD_SRC" "$(dirname $DOCKER_APP_BUILD_DEST)"

copyDockerBuildFiles "$DOCKER_APP_BUILD_FILES" "$DOCKER_APP_BUILD_DEST"

case "$APP_FRAMEWORK"
in
  springboot)
    runAs "$DOCKER_USER" "
      [[ -d $SPRINGBOOT_APPLICATION_PROPERTIES_DIR ]] || mkdir -p $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
      cp $SPRINGBOOT_BASE_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
      cp $SPRINGBOOT_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
    "
  ;;
  angular|react|flask|express|mux|feathers)
    runAs "$DOCKER_USER" "rsync -av $DOCKER_APP_CONFIG_DIR/ $DOCKER_APP_BUILD_DEST"
  ;;
  nuxt|next)
    setAppFrontendBuildMode || exit 1
  ;;
  *)
    msg "app framework '$APP_FRAMEWORK' unknown"
    exit 1
  ;;
esac

if [[ "$RUN_COMMAND" == "build" ]]
then
  buildDockerImage || abortBuildProcess
elif [[ "$RUN_COMMAND" == "build-push" ]]
then
  buildDockerImage || abortBuildProcess
  pushDockerImage
elif [[ "$RUN_COMMAND" == "build-push-deploy" ]]
then
  buildDockerImage || abortBuildProcess
  pushDockerImage
  deployToKubernetes
elif [[ "$RUN_COMMAND" == "push" ]]
then
  pushDockerImage
elif [[ "$RUN_COMMAND" == "deploy" ]]
then
  deployToKubernetes
else
  msg 'no Run command specified'
  exit 1
fi

exit 0

## -- finish
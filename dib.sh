#!/bin/bash
#
# File: dib.sh -> Build, push docker images to a registry and/or deploy to a Kubernetes cluster
#
# Author: Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: bash dib.sh BUILD_COMMAND JENKINS_JOB APP_PROJECT APP_ENVIRONMENT APP_FRAMEWORK APP_IMAGE 
#   ENV_VARS: APP_IMAGE_TAG APP_KUBERNETES_NAMESPACE APP_DB_CONNECTION_POOL
#             APP_KUBERNETES_CONTEXT APP_BUILD_MODE APP_NPM_BUILD_COMMANDS KUBECONFIGS
#             KUBERNETES_SERVICE_LABEL USE_GIT_COMMIT USE_BUILD_DATE
#
#

## - start here

msg ()
{
  echo >&2 "$COMMAND: $1"
}

runAs ()
{
  sudo su "$1" -c "$2"
}

addMavenWrapperProperties ()
{
  local mavenWrapperPropertiesSrc="$1" mavenWrapperPropertiesDest="$2"

  runAs "$DOCKER_USER" "rsync -av $mavenWrapperPropertiesSrc $mavenWrapperPropertiesDest"
}

addSpringbootKeystores ()
{
  local dockerFile="$1" keystoresSrc="$2" keystoresDest="$3"
  
  if grep -qP 'keystores' "$dockerFile" 2> /dev/null
  then
    runAs "$DOCKER_USER" "rsync -av $keystoresSrc $keystoresDest"
  fi
}

copyDockerProject ()
{
  local jenkinsProject="$1" dockerProject="$2"

  msg 'Copying docker project ...'
  runAs "$DOCKER_USER" "
  rm -rf $dockerProject/*
  rsync -av --exclude='.git/' $jenkinsProject $dockerProject
"
}

copyDockerBuildFiles ()
{ 
  local buildFiles="$1" dockerProject="$2"

  local dockerComposeTemplate="$DOCKER_APP_CONFIG_DIR/docker-compose.template.yml"

  if [ -s "$dockerComposeTemplate" ]
  then
    dockerComposeFile="$DOCKER_APP_CONFIG_DIR/docker-compose.yml"
    formatDockerComposeTemplate "$dockerComposeTemplate" "$dockerComposeFile"
  fi

  msg 'Copying docker build files ...'
  runAs "$DOCKER_USER" "
  rsync -av --exclude='$(basename $dockerComposeTemplate)' $buildFiles $dockerProject 2> /dev/null
"
}

buildSpringbootDockerImage ()
{
  local applicationProperties="$1"
  local springbootProfile="spring.profiles.active=docker"
  local dockerFile="$DOCKERFILE"
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local imageBuildStatus=0

  msg 'Building springboot docker image ...'

  testDockerfile=$(runAs "$DOCKER_USER" "test -f $dockerFile; echo -ne \$?")

  if [[ "$testDockerfile" != "0" ]]
  then
    msg 'no Dockerfile found'
    exit 1
  fi

  addMavenWrapperProperties "$MAVEN_WRAPPER_PROPERTIES_SRC" "$MAVEN_WRAPPER_PROPERTIES_DEST"
  addSpringbootKeystores "$dockerFile" "$DOCKER_APP_KEYSTORES_SRC" "$DOCKER_APP_KEYSTORES_DEST"

  runAs "$DOCKER_USER" "
  sed -i 's/^spring\.profiles\.active\=.*/$springbootProfile/g' $applicationProperties
  $DOCKER_CMD build -t'$targetImage' $DOCKER_APP_BUILD_DEST
  exit \$?
" || imageBuildStatus=1

  runAs "$DOCKER_USER" "cp -a $SPRINGBOOT_BASE_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR 2> /dev/null"

  return "$imageBuildStatus"
}

buildDockerImageFromComposeFile ()
{
  local dockerFile="$DOCKERFILE"
  local dockerComposeFile="$DOCKER_APP_BUILD_DEST/docker-compose.yml"
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local imageBuildStatus=0

  runAs "$DOCKER_USER" "
  if [[ ! -f \"$dockerFile\" ]]
  then
    echo $COMMAND: no Dockerfile found
    exit 1
  fi

  if [[ ! -f \"$dockerComposeFile\" ]]
  then
    echo $COMMAND: no docker compose file found
    exit 1
  fi

  exit 0
" || exit 1

  runAs "$DOCKER_USER" "$DOCKER_COMPOSE_CMD -f $dockerComposeFile build; exit \$?" || imageBuildStatus=1

  return "$imageBuildStatus"
}

buildDockerImageFromFile ()
{
  local dockerFile="$DOCKERFILE"
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local imageBuildStatus=0

  runAs "$DOCKER_USER" "
  if [[ ! -f \"$dockerFile\" ]]
  then
    echo $COMMAND: no Dockerfile found
    exit 1
  fi

  exit 0
" || exit 1

  runAs "$DOCKER_USER" " 
  $DOCKER_CMD build -t'$targetImage' $DOCKER_APP_BUILD_DEST
  exit \$?
  " || imageBuildStatus=1

  return "$imageBuildStatus"
}

buildAngularDockerImage ()
{
  msg 'Building angular docker image ...'
  buildDockerImageFromComposeFile
}

buildReactDockerImage ()
{
  msg 'Building react docker image ...'
  buildDockerImageFromComposeFile
}

buildFlaskDockerImage ()
{
  msg 'Building flask docker image ...'
  buildDockerImageFromFile
}

buildNuxtDockerImage ()
{
  msg 'Building nuxt docker image ...'
  buildDockerImageFromComposeFile
}

buildNextDockerImage ()
{
  msg 'Building next docker image ...'
  buildDockerImageFromComposeFile
}

buildFeathersDockerImage ()
{
  msg 'Building feathers docker image ...'
  buildDockerImageFromFile
}

buildExpressDockerImage ()
{
  msg 'Building express docker image ...'
  buildDockerImageFromFile
}

buildMuxDockerImage ()
{
  msg 'Building mux docker image ...'
  buildDockerImageFromFile
}

buildDockerImage ()
{
  case "$APP_FRAMEWORK" in
    springboot)
      buildSpringbootDockerImage "$SPRINGBOOT_APPLICATION_PROPERTIES_DIR/application.properties"
    ;;
    angular)
      buildAngularDockerImage
    ;;
    react)
      buildReactDockerImage
    ;;
    flask)
      buildFlaskDockerImage
    ;;
    nuxt)
      buildNuxtDockerImage
    ;;
    next)
      buildNextDockerImage
    ;;
    feathers)
      buildFeathersDockerImage
    ;;
    express)
      buildExpressDockerImage
    ;;
    mux)
      buildMuxDockerImage
    ;;
    *)
      msg "$APP_FRAMEWORK unknown"
      exit 1
    ;;
  esac
}

pushDockerImage ()
{
  local targetImage="$APP_IMAGE:$APP_IMAGE_TAG"
  local remoteTargetImage="$CONTAINER_REGISTRY/$APP_PROJECT/$targetImage"

  msg 'Pushing docker image ...'

  runAs "$DOCKER_USER" "
  $DOCKER_CMD logout
  $DOCKER_CMD login --username '$DOCKER_LOGIN_USERNAME' --password-stdin < '$DOCKER_LOGIN_PASSWORD' '$CONTAINER_REGISTRY'
  $DOCKER_CMD tag '$targetImage' '$remoteTargetImage'
  $DOCKER_CMD push '$remoteTargetImage'
  $DOCKER_CMD logout
"
}

setKubernetesConfigs ()
{
  local kubeDir=$KUBE_HOME

  msg 'Setting Kubernetes configs ...'

  while read -r kubeConfig
  do
    [[ -n "$kubeConfig" ]] && KUBECONFIG="${kubeDir}/${kubeConfig}:${KUBECONFIG}"
  done < <(echo -ne "$KUBECONFIGS"| sed -e 's/:/\n/g' -e 's/$/\n/g')
}

formatDockerComposeTemplate ()
{
  local dockerComposeTemplate="$1" dockerComposeOut="$2"
  
  if [[ -s "$dockerComposeTemplate" ]]
  then
    runAs "$DOCKER_USER" "
      sed -e 's/@@APP_IMAGE@@/${APP_IMAGE}/g' \
      -e 's/@@APP_PROJECT@@/${APP_PROJECT}/g' \
      -e 's/@@CONTAINER_REGISTRY@@/${CONTAINER_REGISTRY}/g' \
      -e 's/@@APP_IMAGE_TAG@@/${APP_IMAGE_TAG}/g' \
      -e 's/@@APP_ENVIRONMENT@@/${APP_ENVIRONMENT}/g' \
      -e 's/@@APP_FRAMEWORK@@/${APP_FRAMEWORK}/g' \
      -e 's/@@APP_NPM_BUILD_COMMANDS@@/${APP_NPM_BUILD_COMMANDS}/g' '$dockerComposeTemplate' 1> '$dockerComposeOut'
    "
  fi
}

updateEnvFile ()
{  
  local envFile="$1" changedEnvFile="$2" originalEnvFile="$3" symlinkedEnvFile="$4"
  
  
  if [[ -s "$changedEnvFile" ]]
  then
    runAs "$DOCKER_USER" "
    cp $changedEnvFile $originalEnvFile 2> /dev/null
    cp $changedEnvFile $envFile 2> /dev/null
    [[ -h '$symlinkedEnvFile' ]] || ln -s $envFile $symlinkedEnvFile 2> /dev/null
  "
  else
    runAs "$DOCKER_USER" "
    test -f $changedEnvFile || \
      touch $changedEnvFile && cp $changedEnvFile $envFile && ln -s $envFile $symlinkedEnvFile
  "
  fi
}

detectFileChanged ()
{
  local originalFile="$1" changedFile="$2"

  if [[ "$(diff $originalFile $changedFile 2> /dev/null| wc -l)" -ne 0 ]]
  then
    return 0
  fi

  return 1
}

generateKubernetesManifests ()
{
  kubernetesResourcesAnnotationsChanged ()
  {
    local changedKubernetesResourcesAnnotations=$DOCKER_APP_K8S_ANNOTATIONS_DIR/*changed
    local originalKubernetesResourcesAnnotations=$DOCKER_APP_K8S_ANNOTATIONS_DIR/*original
    local newEntries=$(diff \
      <(sort $changedKubernetesResourcesAnnotations 2> /dev/null) \
      <(sort $originalKubernetesResourcesAnnotations 2> /dev/null) | wc -l)
    
    if [[ "$newEntries" -ne 0 ]]
    then
      return 0
    fi
    
    return 1
  }

  dockerComposeFileChanged ()
  {
    return "$(detectFileChanged "$originalComposeFile" "$changedComposeFile")"
  }

  envFileChanged ()
  {
    local envFile="$1" originalEnvFile="$2" changedEnvFile="$3" symlinkedEnvFile="$4"
    
    if detectFileChanged "$originalEnvFile" "$changedEnvFile" || [[ ! -e "$symlinkedEnvFile" ]]
    then
      updateEnvFile "$envFile" "$changedEnvFile" "$originalEnvFile" "$symlinkedEnvFile"
      return 0
    fi

    return 1
  }

  appProjectEnvFileChanged ()
  {
    local appProjectEnvFile=$DOCKER_APP_PROJECT_ENV_DIR/project.env
    local originalAppProjectEnvFile=$DOCKER_APP_PROJECT_ENV_DIR/project.env.original
    local changedAppProjectEnvFile=$DOCKER_APP_PROJECT_ENV_DIR/project.env.changed
    local symlinkedAppProjectEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-project.env

    return $(envFileChanged \
      "$appProjectEnvFile" "$originalAppProjectEnvFile" "$changedAppProjectEnvFile" "$symlinkedAppProjectEnvFile")
  }

  appCommonEnvFileChanged ()
  {
    local appCommonEnvFile=$DOCKER_APP_COMMON_ENV_DIR/common.env
    local originalAppCommonEnvFile=$DOCKER_APP_COMMON_ENV_DIR/common.env.original
    local changedAppCommonEnvFile=$DOCKER_APP_COMMON_ENV_DIR/common.env.changed
    local symlinkedAppCommonEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-${APP_ENVIRONMENT}-common.env

    return $(envFileChanged \
      "$appCommonEnvFile" "$originalAppCommonEnvFile" "$changedAppCommonEnvFile" "$symlinkedAppCommonEnvFile")
  }

  appServiceEnvFileChanged ()
  {
    local appServiceEnvFile=$DOCKER_APP_SERVICE_ENV_DIR/service.env
    local originalAppServiceEnvFile=$DOCKER_APP_SERVICE_ENV_DIR/service.env.original
    local changedAppServiceEnvFile=$DOCKER_APP_SERVICE_ENV_DIR/service.env.changed
    local symlinkedAppServiceEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_IMAGE}-service.env

    return $(envFileChanged \
      "$appServiceEnvFile" "$originalAppServiceEnvFile" "$changedAppServiceEnvFile" "$symlinkedAppServiceEnvFile")
  }

  appEnvFileChanged ()
  {
    local appEnvFile=$DOCKER_APP_COMPOSE_DIR/app.env
    local originalAppEnvFile=$DOCKER_APP_COMPOSE_DIR/app.env.original
    local changedAppEnvFile=$DOCKER_APP_COMPOSE_DIR/app.env.changed
    local symlinkedAppEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_IMAGE}-app.env

    return $(envFileChanged \
      "$appEnvFile" "$originalAppEnvFile" "$changedAppEnvFile" "$symlinkedAppEnvFile")
  }

  msg 'Generating Kubernetes manifests ...'

  local originalComposeFile=$DOCKER_APP_COMPOSE_DIR/docker-compose.original.yml
  local changedComposeFile=$DOCKER_APP_COMPOSE_DIR/docker-compose.changed.yml
  local templateComposeFile=$DOCKER_APP_COMPOSE_DIR/docker-compose.template.yml

  formatDockerComposeTemplate "$templateComposeFile" "$changedComposeFile"

  dockerComposeFileChanged && DOCKER_COMPOSE_FILE_CHANGED=1
  kubernetesResourcesAnnotationsChanged && K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=1
  appEnvFileChanged && APP_ENV_FILE_CHANGED=1
  appServiceEnvFileChanged && APP_SERVICE_ENV_FILE_CHANGED=1
  appCommonEnvFileChanged && APP_COMMON_ENV_FILE_CHANGED=1
  appProjectEnvFileChanged && APP_PROJECT_ENV_FILE_CHANGED=1

  if [[ "$DOCKER_COMPOSE_FILE_CHANGED" -eq 0 ]] && \
    [[ "$K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED" -eq 0 ]] && \
    [[ "$APP_ENV_FILE_CHANGED" -eq 0 ]] && \
    [[ "$APP_COMMON_ENV_FILE_CHANGED" -eq 0 ]] && \
    [[ "$APP_PROJECT_ENV_FILE_CHANGED" -eq 0 ]] && \
    [[ "$APP_SERVICE_ENV_FILE_CHANGED" -eq 0 ]]
  then
    return 1
  fi
  
  runAs "$DOCKER_USER" "
  
  getKubernetesResourcesAnnotations ()
  {
    dir -1 $DOCKER_APP_K8S_ANNOTATIONS_DIR/*changed 2> /dev/null
  }

  getKubernetesResources ()
  {
    dir -1 $DOCKER_APP_COMPOSE_K8S_DIR/* 2> /dev/null
  }

  getKubernetesResourceFromAnnotationFile ()
  {
    echo -ne \"\$(basename \$1)\"| cut -d. -f1
  }

  getSpecLineNo ()
  {
    grep -n 'spec:' --color=never \"\$1\"| cut -d: -f1
  }

  printLinesBeforeSpec ()
  {
    sed -n \"1,\$((\$1 - 1))p\" \$2
  }

  printLinesAfterSpecInclusive ()
  {
    sed -n \"\$1,\\\$p\" \$2
  }

  selectKubernetesResource ()
  {
    echo \"\$1\"| grep --color=never \"\$2\"
  }

  addKubernetesResourceAnnotations ()
  {
    local k8sResourceAnnotations=\"\$1\"
    
    cat <<EOF             
  annotations:
\$(while read -r annotation; do echo \"    \$annotation\"; done < \$k8sResourceAnnotations)  
EOF
  }

  insertKubernetesResourceAnnotations ()
  {
    local kubernetesResource=\"\$1\"
    local kubernetesResourceAnnotations=\"\$2\"
    local kubernetesResourceCopy=\"\$kubernetesResource\".copy

    cp \$kubernetesResource \$kubernetesResourceCopy

    local specLineNo=\"\$(getSpecLineNo \$kubernetesResource)\"

    (
      printLinesBeforeSpec \"\$specLineNo\" \"\$kubernetesResourceCopy\"
      addKubernetesResourceAnnotations \"\$kubernetesResourceAnnotations\"
      printLinesAfterSpecInclusive \"\$specLineNo\" \"\$kubernetesResourceCopy\"
    ) > \$kubernetesResource || cp \$kubernetesResourceCopy \$kubernetesResource

    rm -f \$kubernetesResourceCopy
  }

  updateKubernetesResourcesWithAnnotations ()
  {
    local kubernetesResources=\"\$(getKubernetesResources)\"
    local kubernetesResourcesAnnotations=\"\$(getKubernetesResourcesAnnotations)\"

    if [[ -n \"\$kubernetesResourcesAnnotations\" ]]
    then
      for kubernetesResourceAnnotation in \"\$kubernetesResourcesAnnotations\"
      do
        resourceAnnotation=\$(getKubernetesResourceFromAnnotationFile \"\$kubernetesResourceAnnotation\")
        kubernetesResource=\$(selectKubernetesResource \"\$kubernetesResources\" \"\$resourceAnnotation\")
        changedResourceAnnotation=$DOCKER_APP_K8S_ANNOTATIONS_DIR/\${resourceAnnotation}.k8s-annotations.changed
        originalResourceAnnotation=$DOCKER_APP_K8S_ANNOTATIONS_DIR/\${resourceAnnotation}.k8s-annotations.original
        
        if [[ -n \"\$kubernetesResource\" ]]
        then
          insertKubernetesResourceAnnotations \"\$kubernetesResource\" \"\$kubernetesResourceAnnotation\"
          cp \$changedResourceAnnotation \$originalResourceAnnotation
        fi
      done
    fi
  }

  generateKubernetesManifests ()
  {
    [[ -d \"$DOCKER_APP_COMPOSE_K8S_DIR\" ]] || mkdir -p \"$DOCKER_APP_COMPOSE_K8S_DIR\"
    
    cd $DOCKER_APP_COMPOSE_K8S_DIR
    
    $KOMPOSE_CMD convert -f $changedComposeFile
    
    if [[ \"$KUBERNETES_SERVICE_LABEL\" != \"io.kompose.service\" ]]
    then
      sed -i 's/io\.kompose\.service\:/${KUBERNETES_SERVICE_LABEL}:/g' *
    fi
    
    sed -i 's/${KUBERNETES_SERVICE_LABEL}\: ${APP_IMAGE}-/${KUBERNETES_SERVICE_LABEL}: /g' *configmap* 2> /dev/null
  }

  generateKubernetesManifests

  updateKubernetesResourcesWithAnnotations
  
  cp $changedComposeFile $originalComposeFile
"
  return 0
}

getKubernetesContexts ()
{
  local kubernetesContextFilter="${APP_KUBERNETES_CONTEXT}"
  
  runAs "$DOCKER_USER" "
  KUBECONFIG=${KUBECONFIG} $KUBECTL_CMD config get-contexts --no-headers| \
  grep -P '$kubernetesContextFilter'| \
  tr -s '[:space:]'| awk '{ print \$2; }'
"
}

deployToKubernetes ()
{
  setKubernetesConfigs
  
  generateKubernetesManifests
  
  while IFS=$'\n' read -r kubernetesContext
  do
    runAs "$SUPER_USER" "

  createKubernetesNamespaceIfNotExists ()
  {
    if ! $KUBECTL_CMD get namespaces --all-namespaces -o wide --no-headers| grep -q $APP_KUBERNETES_NAMESPACE
    then
      $KUBECTL_CMD create namespace $APP_KUBERNETES_NAMESPACE
    fi
  }

  kubernetesDeploymentsExist ()
  {
    if $KUBECTL_CMD get deployments -n $APP_KUBERNETES_NAMESPACE -l $KUBERNETES_SERVICE_LABEL=$APP_IMAGE -o wide --no-headers| \
      grep -q $APP_IMAGE:$APP_IMAGE_TAG
    then
      return 0
    fi

    return 1
  }

  kubernetesDeploymentsScaledToZero ()
  {
    local deployments=\$($KUBECTL_CMD get deployments -n $APP_KUBERNETES_NAMESPACE -l $KUBERNETES_SERVICE_LABEL=$APP_IMAGE -o wide --no-headers| \
      grep $APP_IMAGE:$APP_IMAGE_TAG|awk '{ print \$2; }')

    if [[ \"\$deployments\" == \"0/0\" ]]
    then
      return 0
    fi

    return 1
  }

  export KUBECONFIG=${KUBECONFIG}

  echo $COMMAND: Switching kubernetes context to $kubernetesContext ...

  $KUBECTL_CMD config use-context $kubernetesContext

  APP_DB_CONNECTION_POOL=$APP_DB_CONNECTION_POOL

  createKubernetesNamespaceIfNotExists

  if [[ \$APP_DB_CONNECTION_POOL == 'session' ]]
  then
    echo $COMMAND: Scale kubernetes deployments to zero ...
    $KUBECTL_CMD scale deployment/$APP_IMAGE --replicas=0 -n $APP_KUBERNETES_NAMESPACE 
  fi

  if \$(kubernetesDeploymentsExist) && \
    ! \$(kubernetesDeploymentsScaledToZero) && \
    [[ \"$DOCKER_COMPOSE_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_ENV_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_COMMON_ENV_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_SERVICE_ENV_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_PROJECT_ENV_FILE_CHANGED\" == \"0\" ]]
  then
    echo $COMMAND: Patching kubernetes deployments ...
    eval \"$(patchKubernetesDeployment)\"
  else
    echo $COMMAND: Applying kubernetes manifests ...
    $KUBECTL_CMD apply -f $DOCKER_APP_COMPOSE_K8S_DIR -n $APP_KUBERNETES_NAMESPACE
  fi
"
  done < <(getKubernetesContexts)

  msg 'Kubernetes manifests deployed successfully'
}

getKubernetesDeploymentPatchSpec ()
{
  cat <<EOF
spec:
  template:
    metadata:
      creationTimestamp: '$(date +'%FT%H:%M:%SZ')'
EOF
}

patchKubernetesDeployment ()
{
  local KUBERNETES_DEPLOYMENT_PATCH=$(getKubernetesDeploymentPatchSpec)
  
  cat <<EOF
  $KUBECTL_CMD patch -n $APP_KUBERNETES_NAMESPACE -f $DOCKER_APP_COMPOSE_K8S_DIR/*deployment* --patch '$KUBERNETES_DEPLOYMENT_PATCH'
EOF
}

abortBuildProcess ()
{
  msg 'docker image build process aborted'
  exit 1
}

getAppImageTag ()
{
  local appImageTag=${APP_IMAGE_TAG}

  if [[ "$USE_GIT_COMMIT" = "true" ]] && [[ -n "$GIT_COMMIT" ]]
  then
    appImageTag=$(echo -ne $GIT_COMMIT| cut -c1-10)
  fi

  if [[ "$USE_BUILD_DATE" = "true" ]] && [[ -n "$BUILD_DATE" ]]
  then
    appImageTag="${BUILD_DATE}-${appImageTag}"
  fi

  case "$APP_ENVIRONMENT"
  in
    development) appImageTag="dev-${appImageTag}";;
    staging) appImageTag="staging-${appImageTag}";;
    beta) appImageTag="beta-${appImageTag}";;
    production) appImageTag="prod-${appImageTag}";;
    demo) appImageTag="demo-${appImageTag}";;
    alpha) appImageTag="alpha-${appImageTag}";;
    *)
      msg "app environment '$APP_ENVIRONMENT' unknown"
      exit 1
    ;;
  esac

  printf '%s' $appImageTag
}

createDefaultDirectoriesIfNotExist ()
{
  runAs "$DOCKER_USER" "
  defaultDirs=(
    ${DOCKER_APP_BUILD_DEST}
    ${DOCKER_APP_CONFIG_DIR}
    ${DOCKER_APP_COMPOSE_DIR}
    ${DOCKER_APP_COMPOSE_K8S_DIR}
    ${DOCKER_APP_KEYSTORES_SRC}
    ${MAVEN_WRAPPER_PROPERTIES_SRC}
    ${DOCKER_APP_K8S_ANNOTATIONS_DIR}
    ${DOCKER_APP_COMMON_ENV_DIR}
    ${DOCKER_APP_PROJECT_ENV_DIR}
    ${DOCKER_APP_SERVICE_ENV_DIR}
  )

  for defaultDir in \${defaultDirs[@]}
  do
    [[ ! -d \"\$defaultDir\" ]] && mkdir -p \"\$defaultDir\"
  done
"
}

isKomposeVersionValid ()
{
  local komposeVersion=$($KOMPOSE_CMD version) minorVersion=

  if grep -qP '^1' <<< "$komposeVersion"
  then
    minorVersion=$(grep -oP '\.\d{2}\.' <<< "$komposeVersion"| tr -d '.')
    
    if [[ -n "$minorVersion" && "$minorVersion" -lt "21" ]]
    then
      return 1
    fi
  fi
  
  return 0
}

setAppFrontendBuildMode () 
{
  case "$APP_BUILD_MODE"
  in
    spa)
      runAs "$DOCKER_USER" "cp $DOCKER_APP_BUILD_DEST/Dockerfile-spa $DOCKERFILE"
    ;;
    universal)
      runAs "$DOCKER_USER" "cp $DOCKER_APP_BUILD_DEST/Dockerfile-universal $DOCKERFILE"
    ;;
    *)
      msg "app build mode '$APP_BUILD_MODE' unknown"
      return 1
    ;;
  esac

  return 0
}

COMMAND="$0"

if [[ "$#" -ne 6 ]]
then
  msg 'expects 5 arguments i.e. BUILD_COMMAND JENKINS_JOB APP_PROJECT APP_FRAMEWORK APP_IMAGE'
  exit 1
fi

BUILD_COMMAND="${1:-build}"
JENKINS_JOB="$2"
APP_PROJECT="$3"
APP_ENVIRONMENT="$4"
APP_FRAMEWORK="$5"
APP_IMAGE="$6"

APP_IMAGE_TAG=${APP_IMAGE_TAG:-latest}
APP_KUBERNETES_NAMESPACE=${APP_KUBERNETES_NAMESPACE:-default}
APP_DB_CONNECTION_POOL=${APP_DB_CONNECTION_POOL:-transaction}
APP_KUBERNETES_CONTEXT=${APP_KUBERNETES_CONTEXT:-microk8s}
APP_BUILD_MODE=${APP_BUILD_MODE:-spa}
APP_NPM_BUILD_COMMANDS=${APP_NPM_BUILD_COMMANDS:-'build:docker'}
KUBERNETES_SERVICE_LABEL=${KUBERNETES_SERVICE_LABEL:-'io.kompose.service'}

: ${DOCKER_CMD="$(which docker)"}
: ${DOCKER_COMPOSE_CMD="$(which docker-compose)"}
: ${KOMPOSE_CMD="$(which kompose)"}
: ${KUBECTL_CMD="$(which kubectl)"}
: ${CONTAINER_REGISTRY=${CONTAINER_REGISTRY:-hub.docker.com}}
: ${BUILD_COMMANDS='^(build|build\-push|build\-push\-deploy|push|deploy)$'}
: ${APP_ENVIRONMENTS='^(development|staging|beta|production|demo|alpha)$'}
: ${JENKINS_WORKSPACE='/var/lib/jenkins/workspace'}
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
: ${DOCKER_APP_BUILD_SRC="$JENKINS_WORKSPACE/$JENKINS_JOB"}
: ${DOCKER_APP_BUILD_DEST="$DOCKER_APPS_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$JENKINS_JOB"}
: ${DOCKER_APP_CONFIG_DIR="$DOCKER_APPS_CONFIG_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$JENKINS_JOB"}
: ${DOCKER_APP_COMPOSE_DIR="$DOCKER_APPS_COMPOSE_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$JENKINS_JOB"}
: ${DOCKER_APP_COMPOSE_K8S_DIR="$DOCKER_APP_COMPOSE_DIR/kubernetes"}
: ${DOCKER_APP_K8S_ANNOTATIONS_DIR="$DOCKER_APPS_KUBERNETES_ANNOTATIONS_DIR/$APP_FRAMEWORK/$APP_ENVIRONMENT/$JENKINS_JOB"}
: ${DOCKER_APP_BUILD_FILES="$DOCKER_APP_CONFIG_DIR/*{Dockerfile,docker-compose}*"}
: ${DOCKER_LOGIN_USERNAME=${DOCKER_LOGIN_USERNAME:-'builder-script'}}
: ${DOCKER_LOGIN_PASSWORD="$DOCKER_HOME/.secrets/${DOCKER_LOGIN_USERNAME}"}
: ${DOCKER_APP_KEYSTORES_SRC="$DOCKER_HOME/keystores/$APP_PROJECT/$APP_ENVIRONMENT/keystores"}
: ${DOCKER_APP_KEYSTORES_DEST="$DOCKER_APP_BUILD_DEST"}
: ${MAVEN_WRAPPER_PROPERTIES_SRC="${DOCKER_APPS_CONFIG_DIR}/${APP_FRAMEWORK}/maven-wrapper/"}
: ${MAVEN_WRAPPER_PROPERTIES_DEST="$DOCKER_APP_BUILD_DEST"}
: ${BUILD_DATE=`date +'%Y%m%d'`}
: ${KUBE_HOME=${KUBE_HOME:-${DOCKER_APPS_KUBERNETES_DIR}}}
: ${DOCKER_APP_COMMON_ENV_DIR="$DOCKER_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_ENVIRONMENT"}
: ${DOCKER_APP_PROJECT_ENV_DIR="$DOCKER_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT"}
: ${DOCKER_APP_SERVICE_ENV_DIR="$DOCKER_APPS_ENV_DIR/$APP_FRAMEWORK/$APP_PROJECT/$APP_IMAGE"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES_DIR="$DOCKER_APP_BUILD_DEST/src/main/resources"}
: ${SPRINGBOOT_BASE_APPLICATION_PROPERTIES="$DOCKER_APP_CONFIG_DIR/application.properties"}
: ${SPRINGBOOT_APPLICATION_PROPERTIES="$DOCKER_APP_CONFIG_DIR/application-docker.properties"}

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

# test build commands
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

# check passed build command
if ! echo -ne "$BUILD_COMMAND"| grep -qP "$BUILD_COMMANDS"
then
  msg "Build command must be in $BUILD_COMMANDS"
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

if [[ "$BUILD_COMMAND" == "build" ]]
then
  buildDockerImage || abortBuildProcess
elif [[ "$BUILD_COMMAND" == "build-push" ]]
then
  buildDockerImage || abortBuildProcess
  pushDockerImage
elif [[ "$BUILD_COMMAND" == "build-push-deploy" ]]
then
  buildDockerImage || abortBuildProcess
  pushDockerImage
  deployToKubernetes
elif [[ "$BUILD_COMMAND" == "push" ]]
then
  pushDockerImage
elif [[ "$BUILD_COMMAND" == "deploy" ]]
then
  deployToKubernetes
else
  msg 'no build command specified'
  exit 1
fi

exit 0

## -- finish
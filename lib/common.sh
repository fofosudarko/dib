#!/bin/bash
#
# File: common.sh -> common script operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source common.sh
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

formatDockerComposeTemplate ()
{
  local dockerComposeTemplate="$1" dockerComposeOut="$2"
  
  if [[ -s "$dockerComposeTemplate" ]]
  then
    runAs "$DOCKER_USER" "
      sed -e 's/@@DIB_APP_IMAGE@@/${APP_IMAGE}/g' \
      -e 's/@@DIB_APP_PROJECT@@/${APP_PROJECT}/g' \
      -e 's/@@DIB_CONTAINER_REGISTRY@@/${CONTAINER_REGISTRY}/g' \
      -e 's/@@DIB_APP_IMAGE_TAG@@/${APP_IMAGE_TAG}/g' \
      -e 's/@@DIB_APP_ENVIRONMENT@@/${APP_ENVIRONMENT}/g' \
      -e 's/@@DIB_APP_FRAMEWORK@@/${APP_FRAMEWORK}/g' \
      -e 's/@@DIB_APP_NPM_RUN_COMMANDS@@/${APP_NPM_RUN_COMMANDS}/g' '$dockerComposeTemplate' 1> '$dockerComposeOut'
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

abortBuildProcess ()
{
  msg 'docker image build process aborted'
  exit 1
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
  local symlinkedAppProjectEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-project.env
  local changedAppProjectEnvFile="$DOCKER_APP_PROJECT_ENV_CHANGED_FILE"
  
  return $(envFileChanged \
    "$appProjectEnvFile" "$originalAppProjectEnvFile" "$changedAppProjectEnvFile" "$symlinkedAppProjectEnvFile")
}

appCommonEnvFileChanged ()
{
  local appCommonEnvFile=$DOCKER_APP_COMMON_ENV_DIR/common.env
  local originalAppCommonEnvFile=$DOCKER_APP_COMMON_ENV_DIR/common.env.original
  local symlinkedAppCommonEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_PROJECT}-${APP_FRAMEWORK}-${APP_ENVIRONMENT}-common.env
  local changedAppCommonEnvFile="$DOCKER_APP_COMMON_ENV_CHANGED_FILE"
  
  return $(envFileChanged \
    "$appCommonEnvFile" "$originalAppCommonEnvFile" "$changedAppCommonEnvFile" "$symlinkedAppCommonEnvFile")
}

appServiceEnvFileChanged ()
{
  local appServiceEnvFile=$DOCKER_APP_SERVICE_ENV_DIR/service.env
  local originalAppServiceEnvFile=$DOCKER_APP_SERVICE_ENV_DIR/service.env.original
  local symlinkedAppServiceEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_IMAGE}-service.env
  local changedAppServiceEnvFile="$DOCKER_APP_SERVICE_ENV_CHANGED_FILE"
  
  return $(envFileChanged \
    "$appServiceEnvFile" "$originalAppServiceEnvFile" "$changedAppServiceEnvFile" "$symlinkedAppServiceEnvFile")
}

appEnvFileChanged ()
{
  local appEnvFile=$DOCKER_APP_COMPOSE_DIR/app.env
  local originalAppEnvFile=$DOCKER_APP_COMPOSE_DIR/app.env.original
  local symlinkedAppEnvFile=$DOCKER_APP_COMPOSE_DIR/${APP_IMAGE}-app.env
  local changedAppEnvFile="$DOCKER_APP_ENV_CHANGED_FILE"
  
  return $(envFileChanged \
    "$appEnvFile" "$originalAppEnvFile" "$changedAppEnvFile" "$symlinkedAppEnvFile")
}

## -- finish

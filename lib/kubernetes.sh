#!/bin/bash
#
# File: kubernetes.sh -> common kubernetes operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source kubernetes.sh
#
#

## - start here

setKubernetesConfigs ()
{
  local kubeDir=$KUBE_HOME

  msg 'Setting Kubernetes configs ...'

  while read -r kubeConfig
  do
    [[ -n "$kubeConfig" ]] && KUBECONFIG="${kubeDir}/${kubeConfig}:${KUBECONFIG}"
  done < <(echo -ne "$KUBECONFIGS"| sed -e 's/:/\n/g' -e 's/$/\n/g')
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

generateKubernetesManifests ()
{
  dockerComposeFileChanged ()
  {
    return "$(detectFileChanged "$originalComposeFile" "$changedComposeFile")"
  }
  
  msg 'Generating Kubernetes manifests ...'

  local originalComposeFile=$DOCKER_APP_COMPOSE_DIR/docker-compose.original.yml
  local changedComposeFile=$DOCKER_APP_COMPOSE_DIR/docker-compose.changed.yml
  local templateComposeFile="$DOCKER_APP_COMPOSE_COMPOSE_TEMPLATE_FILE"

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

## -- finish

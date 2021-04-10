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

function set_kubernetes_configs() {
  local kube_dir=$KUBE_HOME

  msg 'Setting Kubernetes configs ...'

  while read -r kube_config
  do
    [[ -n "$kube_config" ]] && KUBECONFIG="${kube_dir}/${kube_config}:${KUBECONFIG}"
  done < <(echo -ne "$KUBECONFIGS"| sed -e 's/:/\n/g' -e 's/$/\n/g')
}

function get_kubernetes_contexts() {
  local kubernetes_context_filter="${APP_KUBERNETES_CONTEXT}"
  
  run_as "$DIB_USER" "
  KUBECONFIG=${KUBECONFIG} $KUBECTL_CMD config get-contexts --no-headers| \
  grep -E '$kubernetes_context_filter'| \
  tr -s '[:space:]'| awk '{ print \$2; }'
"
}

function generate_kubernetes_manifests() {
  
  function docker_compose_file_changed() {
    ensure_paths_exist "$changed_compose_file"
    return $(detect_file_changed "$original_compose_file" "$changed_compose_file")
  }
  
  msg 'Generating Kubernetes manifests ...'

  local original_compose_file=$DIB_APP_COMPOSE_DIR/docker-compose.original.yml
  local changed_compose_file=$DIB_APP_COMPOSE_DIR/docker-compose.changed.yml
  local template_compose_file="$DIB_APP_COMPOSE_COMPOSE_TEMPLATE_FILE"

  ensure_paths_exist "$template_compose_file"

  format_docker_compose_template "$template_compose_file" "$changed_compose_file"

  docker_compose_file_changed && DOCKER_COMPOSE_FILE_CHANGED=1
  kubernetes_resources_annotations_changed && K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED=1
  app_env_file_changed && APP_ENV_FILE_CHANGED=1
  app_service_env_file_changed && APP_SERVICE_ENV_FILE_CHANGED=1
  app_common_env_file_changed && APP_COMMON_ENV_FILE_CHANGED=1
  app_project_env_file_changed && APP_PROJECT_ENV_FILE_CHANGED=1

  if [[ "$DOCKER_COMPOSE_FILE_CHANGED" -eq 0 ]] && \
    [[ "$K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED" -eq 0 ]] && \
    [[ "$APP_ENV_FILE_CHANGED" -eq 0 ]] && \
    [[ "$APP_COMMON_ENV_FILE_CHANGED" -eq 0 ]] && \
    [[ "$APP_PROJECT_ENV_FILE_CHANGED" -eq 0 ]] && \
    [[ "$APP_SERVICE_ENV_FILE_CHANGED" -eq 0 ]]
  then
    return 1
  fi
  
  run_as "$DIB_USER" "
  function get_kubernetes_resources_annotations() {
    dir -1 $DIB_APP_K8S_ANNOTATIONS_DIR/*changed 2> /dev/null
  }

  function get_kubernetes_resources() {
    dir -1 $DIB_APP_COMPOSE_K8S_DIR/* 2> /dev/null
  }

  function get_kubernetes_resource_from_annotation_file() {
    echo -ne \"\$(basename \$1)\"| cut -d. -f1
  }

  function get_spec_line_no() {
    grep -n 'spec:' --color=never \"\$1\"| cut -d: -f1
  }

  function print_lines_before_spec() {
    sed -n \"1,\$((\$1 - 1))p\" \$2
  }

  function print_lines_after_spec_inclusive() {
    sed -n \"\$1,\\\$p\" \$2
  }

  function select_kubernetes_resource() {
    echo \"\$1\"| grep --color=never \"\$2\"
  }

  function add_kubernetes_resource_annotations() {
    local k8s_resource_annotations=\"\$1\"
    
    cat <<EOF             
  annotations:
\$(while read -r annotation; do echo \"    \$annotation\"; done < \$k8s_resource_annotations)  
EOF
  }

  function insert_kubernetes_resource_annotations() {
    local kubernetes_resource=\"\$1\"
    local kubernetes_resource_annotations=\"\$2\"
    local kubernetes_resource_copy=\"\$kubernetes_resource\".copy

    cp \$kubernetes_resource \$kubernetes_resource_copy

    local spec_line_no=\"\$(get_spec_line_no \$kubernetes_resource)\"

    (
      print_lines_before_spec \"\$spec_line_no\" \"\$kubernetes_resource_copy\"
      add_kubernetes_resource_annotations \"\$kubernetes_resource_annotations\"
      print_lines_after_spec_inclusive \"\$spec_line_no\" \"\$kubernetes_resource_copy\"
    ) > \$kubernetes_resource || cp \$kubernetes_resource_copy \$kubernetes_resource

    rm -f \$kubernetes_resource_copy
  }

  function update_kubernetes_resources_with_annotations() {
    local kubernetes_resources=\"\$(get_kubernetes_resources)\"
    local kubernetes_resources_annotations=\"\$(get_kubernetes_resources_annotations)\"

    if [[ -n \"\$kubernetes_resources_annotations\" ]]
    then
      for kubernetes_resource_annotation in \"\$kubernetes_resources_annotations\"
      do
        resource_annotation=\$(get_kubernetes_resource_from_annotation_file \"\$kubernetes_resource_annotation\")
        kubernetes_resource=\$(select_kubernetes_resource \"\$kubernetes_resources\" \"\$resource_annotation\")
        changed_resource_annotation=$DIB_APP_K8S_ANNOTATIONS_DIR/\${resource_annotation}.k8s-annotations.changed
        original_resource_annotation=$DIB_APP_K8S_ANNOTATIONS_DIR/\${resource_annotation}.k8s-annotations.original
        
        if [[ -n \"\$kubernetes_resource\" ]]
        then
          insert_kubernetes_resource_annotations \"\$kubernetes_resource\" \"\$kubernetes_resource_annotation\"
          cp \$changed_resource_annotation \$original_resource_annotation
        fi
      done
    fi
  }

  function generate_kubernetes_manifests() {
    [[ -d \"$DIB_APP_COMPOSE_K8S_DIR\" ]] || mkdir -p \"$DIB_APP_COMPOSE_K8S_DIR\"
    
    cd $DIB_APP_COMPOSE_K8S_DIR
    
    $KOMPOSE_CMD convert -f $changed_compose_file
    
    if [[ \"$KUBERNETES_SERVICE_LABEL\" != \"io.kompose.service\" ]]
    then
      sed -i'.sed-backup' -E 's/io\.kompose\.service\:/${KUBERNETES_SERVICE_LABEL}:/g' *
    fi
    
    sed -i'.sed-backup' -E 's/${KUBERNETES_SERVICE_LABEL}\: ${APP_IMAGE}-/${KUBERNETES_SERVICE_LABEL}: /g' *configmap* 2> /dev/null

    rm -f *sed-backup 2> /dev/null
  }

  generate_kubernetes_manifests
  update_kubernetes_resources_with_annotations
  cp $changed_compose_file $original_compose_file
"
  
  return 0
}

function deploy_to_kubernetes_cluster() {
  check_kompose_validity
  set_kubernetes_configs
  generate_kubernetes_manifests
  
  while IFS=$'\n' read -r kubernetes_context
  do
    msg "Deploying to $kubernetes_context ..."
    
    run_as "$SUPER_USER" "
  function create_kubernetes_namespace_if_not_exists() {
    if ! $KUBECTL_CMD get namespaces --all-namespaces -o wide --no-headers| grep -q $APP_KUBERNETES_NAMESPACE
    then
      $KUBECTL_CMD create namespace $APP_KUBERNETES_NAMESPACE
    fi
  }

  function kubernetes_deployments_exist() {
    if $KUBECTL_CMD get deployments -n $APP_KUBERNETES_NAMESPACE -l $KUBERNETES_SERVICE_LABEL=$APP_IMAGE -o wide --no-headers| \
      grep -q $APP_IMAGE:$APP_IMAGE_TAG
    then
      return 0
    fi

    return 1
  }

  function kubernetes_deployments_scaled_to_zero() {
    local deployments=\$($KUBECTL_CMD get deployments -n $APP_KUBERNETES_NAMESPACE -l $KUBERNETES_SERVICE_LABEL=$APP_IMAGE -o wide --no-headers| \
      grep $APP_IMAGE:$APP_IMAGE_TAG| awk '{ print \$2; }')

    if [[ \"\$deployments\" == \"0/0\" ]]
    then
      return 0
    fi

    return 1
  }

  export KUBECONFIG=${KUBECONFIG}

  echo Switching kubernetes context to $kubernetes_context ...

  $KUBECTL_CMD config use-context $kubernetes_context

  APP_DB_CONNECTION_POOL=$APP_DB_CONNECTION_POOL

  create_kubernetes_namespace_if_not_exists

  if [[ \$APP_DB_CONNECTION_POOL == 'session' ]]
  then
    echo Scale kubernetes deployments to zero ...
    $KUBECTL_CMD scale deployment/$APP_IMAGE --replicas=0 -n $APP_KUBERNETES_NAMESPACE 
  fi

  if \$(kubernetes_deployments_exist) && \
    ! \$(kubernetes_deployments_scaled_to_zero) && \
    [[ \"$DOCKER_COMPOSE_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$K8S_RESOURCES_ANNOTATIONS_FILES_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_ENV_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_COMMON_ENV_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_SERVICE_ENV_FILE_CHANGED\" == \"0\" ]] && \
    [[ \"$APP_PROJECT_ENV_FILE_CHANGED\" == \"0\" ]]
  then
    echo Patching kubernetes deployments ...
    eval \"$(patch_kubernetes_deployment)\"
  else
    echo Applying kubernetes manifests ...
    $KUBECTL_CMD apply -f $DIB_APP_COMPOSE_K8S_DIR -n $APP_KUBERNETES_NAMESPACE
  fi

  echo Kubernetes manifests deployed successfully
" || return 1
  done < <(get_kubernetes_contexts)

  return 0
}

function get_kubernetes_deployment_patch_spec() {
  cat <<EOF
spec:
  template:
    metadata:
      creationTimestamp: '$(date +'%FT%H:%M:%SZ')'
EOF
}

function patch_kubernetes_deployment() {
  local kubernetes_deployment_patch=$(get_kubernetes_deployment_patch_spec)
  
  cat <<EOF
  $KUBECTL_CMD patch -n $APP_KUBERNETES_NAMESPACE -f $DIB_APP_COMPOSE_K8S_DIR/*deployment* --patch '$kubernetes_deployment_patch'
EOF
}

## -- finish

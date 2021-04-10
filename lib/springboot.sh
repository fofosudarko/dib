#!/bin/bash
#
# File: springboot.sh -> common springboot operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source springboot.sh
#
#

## - start here

function add_springboot_application_properties() {
  run_as "$DIB_USER" "
  [[ -d $SPRINGBOOT_APPLICATION_PROPERTIES_DIR ]] || mkdir -p $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
  cp $SPRINGBOOT_APPLICATION_PROPERTIES $SPRINGBOOT_APPLICATION_PROPERTIES_DIR
"
}

function add_maven_wrapper_properties() {
  local maven_wrapper_properties_src="$1" maven_wrapper_properties_dest="$2"

  run_as "$DIB_USER" "
  if [[ ! -d '${DIB_APP_BUILD_DEST}/.mvn/wrapper' ]]
  then
    rsync -av $maven_wrapper_properties_src $maven_wrapper_properties_dest
  fi
"
}

function add_springboot_keystores() {
  local docker_file="$1" keystores_src="$2" keystores_dest="$3"

  run_as "$DIB_USER" "
    if grep -qE 'keystores' '$docker_file' 2> /dev/null
    then
      rsync -av $keystores_src $keystores_dest
    fi
  "
}

## -- finish

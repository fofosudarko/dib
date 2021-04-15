#!/bin/bash
#
# File: spring.sh -> common spring operations
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source spring.sh
#
#

## - start here

function add_spring_application_properties() {
  [[ -d $SPRING_APPLICATION_PROPERTIES_DIR ]] || mkdir -p $SPRING_APPLICATION_PROPERTIES_DIR
  cp $SPRING_APPLICATION_PROPERTIES $SPRING_APPLICATION_PROPERTIES_DIR
}

function add_maven_wrapper_properties() {
  local maven_wrapper_properties_src="$1" maven_wrapper_properties_dest="$2"

  if [[ ! -d '${DIB_APP_BUILD_DEST}/.mvn/wrapper' ]]
  then
    rsync -av $maven_wrapper_properties_src $maven_wrapper_properties_dest
  fi
}

function add_spring_keystores() {
  local docker_file="$1" keystores_src="$2" keystores_dest="$3"

  if grep -qE 'keystores' "$docker_file" 2> /dev/null
  then
    rsync -av $keystores_src $keystores_dest
  fi
}

## -- finish

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

function add_maven_wrapper_properties() {
  local maven_wrapper_properties_src="$1" maven_wrapper_properties_dest="$2"

  run_as "$DOCKER_USER" "rsync -av $maven_wrapper_properties_src $maven_wrapper_properties_dest"
}

function add_springboot_keystores() {
  local docker_file="$1" keystores_src="$2" keystores_dest="$3"
  
  if grep -qE 'keystores' "$docker_file" 2> /dev/null
  then
    run_as "$DOCKER_USER" "rsync -av $keystores_src $keystores_dest"
  fi
}

## -- finish

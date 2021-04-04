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

## -- finish

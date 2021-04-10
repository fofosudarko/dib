#!/bin/bash
#
# File: core.sh -> core variables
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source core.sh
#
#

## - start here

# core

: ${APP_PROJECT=${DIB_APP_PROJECT:-$DIB_APP_PROJECT_PLACEHOLDER}}
: ${APP_FRAMEWORK=${DIB_APP_FRAMEWORK:-$DIB_APP_FRAMEWORK_PLACEHOLDER}}
: ${APP_IMAGE=${DIB_APP_IMAGE:-$DIB_APP_IMAGE_PLACEHOLDER}}
: ${APP_ENVIRONMENT=${DIB_APP_ENVIRONMENT:-$DIB_APP_ENVIRONMENT_PLACEHOLDER}}

: ${CI_WORKSPACE=${DIB_CI_WORKSPACE:-'/var/lib/jenkins/workspace'}}
: ${CI_JOB=${DIB_CI_JOB:-"${APP_IMAGE}-job"}}

## -- finish

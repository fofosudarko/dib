#!/bin/bash
#
# File: commands.sh -> system commands
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source commands.sh
#
#

## - start here

# system commands

: ${DOCKER_CMD="$(which docker 2> /dev/null)"}
: ${DOCKER_COMPOSE_CMD="$(which docker-compose 2> /dev/null)"}
: ${KOMPOSE_CMD="$(which kompose 2> /dev/null)"}
: ${KUBECTL_CMD="$(which kubectl 2> /dev/null)"}
: ${NANO_CMD="$(which nano 2> /dev/null)"}
: ${SHELL_CMD="$(which bash 2> /dev/null)"}
: ${LESS_CMD="$(which less 2> /dev/null)"}

## -- finish

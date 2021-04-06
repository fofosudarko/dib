#!/bin/bash
#
# File: system_commands.sh -> system commands
#
# (c) 2021 Frederick Ofosu-Darko <fofosudarko@gmail.com>
#
# Usage: source system_commands.sh
#
#

## - start here

# system commands

: ${DOCKER_CMD="$(which docker)"}
: ${DOCKER_COMPOSE_CMD="$(which docker-compose)"}
: ${KOMPOSE_CMD="$(which kompose)"}
: ${KUBECTL_CMD="$(which kubectl)"}
: ${NANO_CMD="$(which nano)"}
: ${SHELL_CMD="$(which bash)"}

## -- finish

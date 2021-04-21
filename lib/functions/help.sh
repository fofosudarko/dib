#!/bin/bash
#
# File: help.sh -> common help operations
#
# Usage: source help.sh
#
#

## - start here

function show_help() {
  msg "
Usage: dib [OPTIONS] COMMAND

A simple tool to aid your cloud native deployments

Options:
  -h, --help        Show help information and quit
  -v, --version     Show version information and quit

Commands:
  build                  Build docker image
  build:push             Build docker image and push it to a container registry
  build:push:deploy      Build docker image, push it to a container registry and deploy to a Kubernetes cluster
  cache                  Show cache information for current working environment
  copy                   Copy application source to a build area                 
  deploy                 Deploy manifests to a Kubernetes cluster
  doctor                 Check whether dependencies have been met
  edit                   Edit files
  env                    Show current working environment variables
  erase                  Erase files
  generate               Generate Kubernetes manifests
  get:all                Get all database entries
  get:key                Get key by project from database
  get:project            Get project by key from database
  goto                   Go to a new or current project
  help                   Show help information and quit
  init                   Initialize dib environment once
  path                   Show paths to files
  ps                     Show status of running docker container
  push                   Push docker image to a container registry
  reset                  Reset cache for current working environment
  restore                Restore files
  run                    Run a docker container
  show                   Show content of files
  stop                   Stop a running docker container
  switch                 Switch project environments
  version                Show version information and quit
  view                   Show content of formatted template files

Enter dib COMMAND --help for more information
"
}

function show_goto_help() {
  msg "show goto help"
}

function show_get_key_help() {
  msg "show get:key help"
}

function show_get_project_help() {
  msg "show get:project help"
}

function show_build_help() {
  msg "show build help"
}

function show_build_push_help() {
  msg "show build:push help"
}

function show_build_push_deploy_help() {
  msg "show build:push:deploy help"
}

function show_push_help() {
  msg "show push help"
}

function show_deploy_help() {
  msg "show deploy help"
}

function show_generate_help() {
  msg "show generate help"
}

function show_edit_help() {
  msg "show edit help"
}

function show_show_help() {
  msg "show show help"
}

function show_path_help() {
  msg "show path help"
}

function show_restore_help() {
  msg "show restore help"
}

function show_erase_help() {
  msg "show erase help"
}

function show_env_help() {
  msg "show env help"
}

function show_switch_help() {
  msg "show switch help"
}

function show_copy_help() {
  msg "show copy help"
}

function show_run_help() {
  msg "show run help"
}

## -- finish

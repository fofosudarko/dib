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

A simple tool to aid your cloud native workflow

Options:
  -h, --help        Show help information and quit
  -v, --version     Show version information and quit

Commands:
  build                  Build container image
  build:push             Build container image and push it to a container registry
  build:push:deploy      Build container image, push it to a container registry and deploy to a kubernetes cluster
  build:run              Build container image and run it locally
  cache                  Show cache information for current working environment
  copy                   Copy application source to a build area                 
  deploy                 Deploy manifests to a kubernetes cluster
  doctor                 Check whether dependencies have been met
  edit                   Edit files
  env                    Show current working environment variables
  erase                  Erase files
  generate               Generate kubernetes manifests
  get:all                Get all database entries
  get:key                Get key by project from database
  get:project            Get project by key from database
  goto                   Go to a new or existing project
  help                   Show help information and quit
  init                   Initialize dib environment once
  path                   Show paths to files
  ps                     Show status of a running container
  push                   Push container image to a container registry
  reset                  Reset cache for current working environment
  restore                Restore files
  run                    Run a container locally
  show                   Show content of files
  stop                   Stop a running container
  switch                 Switch project environments
  version                Show version information and quit
  view                   Show content of formatted template files

Enter dib COMMAND --help for more information
"
  exit 0
}

function show_goto_help() {
  msg "
Go to a new or existing project

Usage:
  dib goto DIB_APP_FRAMEWORK DIB_APP_PROJECT DIB_APP_IMAGE
  dib goto DIB_APP_FRAMEWORK DIB_APP_IMAGE

Where:
  DIB_APP_FRAMEWORK represents the software framework that your application is built with
  DIB_APP_PROJECT   represents the main project where your application may consist of many subprojects
  DIB_APP_IMAGE     represents the name used to produce the container image. It may be your subproject name.

Returns:
  DIB_APP_KEY       represents the unique key used during the application runtime for a subproject

Example:
  dib goto spring bricks bricks-api
  dib goto spring bricks-api
"
  exit 0
}

function show_get_key_help() {
  msg "
Get key by project from database

Usage:
  dib get:key DIB_APP_FRAMEWORK:DIB_APP_PROJECT:DIB_APP_IMAGE

Example:
  dib get:key spring:bricks:bricks-api
"
  exit 0
}

function show_get_project_help() {
  msg "
Get project by key from database

Usage:
  dib get:project DIB_APP_KEY

Example:
  dib get:project aac87fe5e61c49a5861e7870b0292748
"
  exit 0
}

function show_build_help() {
  msg "
Build container image

Usage:
  dib build DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib build bricks-api v1.0.1
"
  exit 0
}

function show_build_push_help() {
  msg "
Build container image and push it to a container registry

Usage:
  dib build:push DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib build:push bricks-api v1.0.1
"
  exit 0
}

function show_build_push_deploy_help() {
  msg "
Build container image, push it to a container registry and deploy to a kubernetes cluster

Usage:
  dib build:push DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib build:push:deploy bricks-api v1.0.1  
"
  exit 0
}

function show_build_run_help() {
  msg "
Build container image and run it locally

Usage:
  dib build:run DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib build:run bricks-api v1.0.1
"
  exit 0
}

function show_push_help() {
  msg "
Push container image to a container registry

Usage:
  dib push DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib push bricks-api v1.0.1
"
  exit 0
}

function show_deploy_help() {
  msg "
Deploy manifests to a kubernetes cluster

Usage:
  dib deploy DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib deploy bricks-api v1.0.1
"
  exit 0
}

function show_generate_help() {
  msg "
Generate kubernetes manifests

Usage:
  dib generate DIB_APP_IMAGE DIB_APP_IMAGE_TAG

Where:
  DIB_APP_IMAGE      represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_IMAGE_TAG  represents the tag for the container image

Example:
  dib generate bricks-api v1.0.1
"
  exit 0
}

function show_edit_help() {
  msg "
Edit files

Usage:
  dib edit DIB_APP_IMAGE DIB_APP_FILE_TYPE DIB_APP_FILE_RESOURCE

Where:
  DIB_APP_IMAGE          represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_FILE_TYPE      represents the type of file to edit. It may be env, config, compose, k8s-annotations, spring, cache, and run
  DIB_APP_FILE_RESOURCE  represents the file resource to edit.

  Below are the file resources for each file type:
    env                  app-env, service-env, common-env, and project-env
    config               dockerfile, dockercomposefile, and runscript
    compose              dockercomposefile
    k8s-annotations      <name of kubernetes resource> e.g. ingress
    spring               application-properties
    cache                <no file resource>
    run                  dockercomposefile

Example:
  dib edit bricks-api env app-env
"
  exit 0
}

function show_show_help() {
  msg "
Show content of files

Usage:
  dib show DIB_APP_IMAGE DIB_APP_FILE_TYPE DIB_APP_FILE_RESOURCE

Where:
  DIB_APP_IMAGE          represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_FILE_TYPE      represents the type of file to show. It may be env, config, compose, k8s-annotations, spring, cache, and run
  DIB_APP_FILE_RESOURCE  represents the file resource to show.

  Below are the file resources for each file type:
    env                  app-env, service-env, common-env, and project-env
    config               dockerfile, dockercomposefile, and runscript
    compose              dockercomposefile
    k8s-annotations      <name of kubernetes resource> e.g. ingress
    spring               application-properties
    cache                <no file resource>
    run                  dockercomposefile

Example:
  dib show bricks-api env app-env
"
  exit 0
}

function show_path_help() {
  msg "
Show paths to files

Usage:
  dib path DIB_APP_IMAGE DIB_APP_FILE_TYPE DIB_APP_FILE_RESOURCE

Where:
  DIB_APP_IMAGE          represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_FILE_TYPE      represents the file type path. It may be env, config, compose, k8s-annotations, spring, cache, and run
  DIB_APP_FILE_RESOURCE  represents the file resource path.

  Below are the file resources for each file type:
    env                  app-env, service-env, common-env, and project-env
    config               dockerfile, dockercomposefile, and runscript
    compose              dockercomposefile
    k8s-annotations      <name of kubernetes resource> e.g. ingress
    spring               application-properties
    cache                <no file resource>
    run                  dockercomposefile

Example:
  dib path bricks-api env app-env
"
  exit 0
}

function show_restore_help() {
  msg "
Restore files

Usage:
  dib restore DIB_APP_IMAGE DIB_APP_FILE_TYPE DIB_APP_FILE_RESOURCE

Where:
  DIB_APP_IMAGE          represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_FILE_TYPE      represents the type of file to restore. It may be env, config, compose, k8s-annotations, spring, cache, and run
  DIB_APP_FILE_RESOURCE  represents the file resource to restore.

  Below are the file resources for each file type:
    env                  app-env, service-env, common-env, and project-env
    config               dockerfile, dockercomposefile, and runscript
    compose              dockercomposefile
    k8s-annotations      <name of kubernetes resource> e.g. ingress
    spring               application-properties
    cache                <no file resource>
    run                  dockercomposefile

Example:
  dib restore bricks-api env app-env
"
  exit 0
}

function show_erase_help() {
  msg "
Erase files

Usage:
  dib erase DIB_APP_IMAGE DIB_APP_FILE_TYPE DIB_APP_FILE_RESOURCE

Where:
  DIB_APP_IMAGE          represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_FILE_TYPE      represents the type of file to erase. It may be env, config, compose, k8s-annotations, spring, cache, and run
  DIB_APP_FILE_RESOURCE  represents the file resource to erase.

  Below are the file resources for each file type:
    env                  app-env, service-env, common-env, and project-env
    config               dockerfile, dockercomposefile, and runscript
    compose              dockercomposefile
    k8s-annotations      <name of kubernetes resource> e.g. ingress
    spring               application-properties
    cache                <no file resource>
    run                  dockercomposefile

Example:
  dib erase bricks-api env app-env
"
  exit 0
}

function show_view_help() {
  msg "
Show content of formatted template files

Usage:
  dib view DIB_APP_IMAGE DIB_APP_FILE_TYPE DIB_APP_FILE_RESOURCE

Where:
  DIB_APP_IMAGE          represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_FILE_TYPE      represents the type of file to view. It may be env, config, compose, k8s-annotations, spring, cache, and run
  DIB_APP_FILE_RESOURCE  represents the file resource to view.

  Below are the file resources for each file type:
    config               dockercomposefile
    compose              dockercomposefile
    run                  dockercomposefile

Example:
  dib view bricks-api config dockercomposefile
"
  exit 0
}

function show_env_help() {
  msg "
Show current working environment variables

Usage:
  dib env DIB_APP_ENV_TYPE

Where:
  DIB_APP_ENV_TYPE   represents the environment variables to show. It may be all, globals, app, docker, kompose, and kubernetes

Example:
  dib env all
"
  exit 0
}

function show_switch_help() {
  msg "
Switch project environments

Usage:
  dib switch DIB_APP_IMAGE DIB_APP_ENVIRONMENT

Where:
  DIB_APP_IMAGE        represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_ENVIRONMENT  represents the environment the application switches to

Example:
  dib switch bricks-api dev
"
  exit 0
}

function show_copy_help() {
  msg "
Copy application source to a build area

Usage:
  dib copy DIB_APP_IMAGE DIB_APP_BUILD_SRC [DIB_APP_BUILD_DEST]

Where:
  DIB_APP_IMAGE        represents the name used to produce the container image. It may be your subproject name.
  DIB_APP_BUILD_SRC    represents the application source
  DIB_APP_BUILD_DEST   represents the build area for the application. This is very optional.

Example:
  dib copy bricks-api /Users/example/Projects/spring/bricks-api
  dib copy bricks-api /Users/example/Projects/spring/bricks-api /Users/example/Projects/container-images/bricks-api
"
  exit 0
}

function show_edit_deploy_help() {
  msg "Oops, not implemented yet."
  exit 0
}

## -- finish

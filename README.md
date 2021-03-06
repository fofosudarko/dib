# dib

Docker Images Builder

## Outside Jenkins

```sh
DIB_HOME=/home/example/dib
DIB_USER=example
DIB_APP_FRAMEWORK=spring
DIB_APP_PROJECT=bricks
DIB_APP_IMAGE=bricks-api
DIB_APP_ENVIRONMENT=dev
DIB_APP_BUILD_SRC=$WORKSPACE  # WORKSPACE => /var/lib/jenkins/<JENKINS_JOB>
DIB_APP_IMAGE_TAG=v1.0.0
DIB_APP_ENVIRONMENT=false

sudo su $DIB_USER -c "
export DIB_HOME=$DIB_HOME
export DIB_APP_ENVIRONMENT=$DIB_APP_ENVIRONMENT
export DIB_APP_KEY=\$(dib get:key $DIB_APP_FRAMEWORK:$DIB_APP_PROJECT:$DIB_APP_IMAGE)

dib switch $DIB_APP_IMAGE $DIB_APP_ENVIRONMENT && \
dib copy $DIB_APP_IMAGE $DIB_APP_BUILD_SRC && \
dib build:run $DIB_APP_IMAGE $DIB_APP_IMAGE_TAG && \
dib ps
"
```

## Inside Jenkins

```sh
DIB_APP_FRAMEWORK=spring
DIB_APP_PROJECT=bricks
DIB_APP_IMAGE=bricks-api
DIB_APP_ENVIRONMENT=dev
DIB_APP_BUILD_SRC=$WORKSPACE # WORKSPACE => /var/lib/jenkins/<JENKINS_JOB>
DIB_APP_IMAGE_TAG=v1.0.1

export DIB_HOME=$JENKINS_HOME/dib
export DIB_APP_KEY=$(dib get:key $DIB_APP_FRAMEWORK:$DIB_APP_PROJECT:$DIB_APP_IMAGE)

dib switch $DIB_APP_IMAGE $DIB_APP_ENVIRONMENT && \
dib copy $DIB_APP_IMAGE $DIB_APP_BUILD_SRC && \
dib build:run $DIB_APP_IMAGE $DIB_APP_IMAGE_TAG && \
dib ps
```

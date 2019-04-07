#!/usr/bin/env bash

TAG=${1}
APP_NAME=${2:-xmlui}

if [[ -z "${TAG}" ]]; then
    >&2 echo "Missing first argument"
    exit 1
fi;

docker build \
    -t itsziget/dspace-${APP_NAME}:${TAG} \
    --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
    --build-arg APP_NAME=${APP_NAME} .
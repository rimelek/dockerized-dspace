#!/usr/bin/env bash

set -e

if [[ -z "$@" ]]; then
    WORKDIR="$(pwd)"

    cd /app/bin
    source resources.sh
    prepareDSpaceApp

    cd "${WORKDIR}"
    exec catalina.sh run
else
    exec $@
fi;
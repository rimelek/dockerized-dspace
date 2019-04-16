#!/usr/bin/env bash

set -e

if [[ -z "$@" ]]; then
    WORKDIR="$(pwd)"

    cd /app/bin
    source resources.sh

    [[ -f "custom/beforePrepare.sh" ]] && custom/beforePrepare.sh
    prepareDSpaceApp
    [[ -f "custom/afterPrepare.sh" ]] && custom/afterPrepare.sh

    cd "${WORKDIR}"
    exec catalina.sh run
else
    exec $@
fi;
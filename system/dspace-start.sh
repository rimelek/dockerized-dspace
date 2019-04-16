#!/usr/bin/env bash

set -e

if [[ -z "$@" ]]; then
    source /resources.sh

    prepareDSpaceApp

    exec catalina.sh run
else
    exec $@
fi;
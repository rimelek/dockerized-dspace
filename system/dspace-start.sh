#!/usr/bin/env bash

WORKING_DIR=$(pwd)

cd /

source resources.sh

CUSTOM_COMMAND=$@

checkRequiredEnv || exit $?

renderTemplates
waitForDatabase

cd "${WORKING_DIR}"
if [[ -z "${CUSTOM_COMMAND}" ]]; then
    exec catalina.sh run
else
    exec $@
fi;
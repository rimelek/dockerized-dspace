#!/usr/bin/env bash

WORKING_DIR=$(pwd)

cd /

if [[ -f "config.sh" ]]; then
    source config.sh
fi;

source resources.sh

CUSTOM_COMMAND=$@

checkRequiredEnv || exit $?

if [[ -e "${CFG_DSPACE}.tpl" ]]; then
    cp "${CFG_DSPACE}.tpl" "${CFG_DSPACE}"
fi;

for file in $(cat /templatize.txt); do
    if [[ -f "${file}.tpl" ]]; then
        cp "${file}.tpl" "${file}"
    fi;
done;

renderLocalConfig
renderLogConfig
renderOAIDescription
renderRobotsTxt
renderSubmissionMap
renderFormMap
waitForDatabase

cd "${WORKING_DIR}"
if [[ -z "${CUSTOM_COMMAND}" ]]; then
    exec catalina.sh run
else
    exec $@
fi;
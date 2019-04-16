#!/usr/bin/env bash

WORKING_DIR=$(pwd)

cd /

if [[ -f "config.sh" ]]; then
    source config.sh
fi;

source resources.sh

CUSTOM_COMMAND=$@

checkRequiredEnv || exit $?

if [[ "${DS_PORT}" != "" ]]; then
    DS_PORT_SUFFIX=":${DS_PORT}"
fi;

declare -A DIRECTIVES=(
    ['DB_HOST']=${DS_DB_HOST}
    ['DB_PORT']=${DS_DB_PORT}
    ['DB_SERVICE_NAME']=${DS_DB_SERVICE_NAME}
    ['PROTOCOL']=${DS_PROTOCOL}
    ['SOLR_HOSTNAME']=${DS_SOLR_HOSTNAME}
    ['PORT_SUFFIX']=${DS_PORT_SUFFIX:-}
)

if [[ -e "${CFG_DSPACE}.tpl" ]]; then
    cp "${CFG_DSPACE}.tpl" "${CFG_DSPACE}"
fi;

for file in $(cat /templatize.txt); do
    if [[ -f "${file}.tpl" ]]; then
        cp "${file}.tpl" "${file}"
    fi;
done;

removeOverriddenConfigs

for i in ${!DIRECTIVES[@]}; do
    TMP_FILE=$(mktemp)
    echo "${DIRECTIVES[${i}]}" > "${TMP_FILE}"
    ESCAPED_DIRECTIVE=$(sed 's/[\/&]/\\&/g' "${TMP_FILE}")
    sed -i "s/{{$i}}/${ESCAPED_DIRECTIVE}/g" "${CFG_DSPACE}"
    EXIT_CODE=$?
    if [[ "${EXIT_CODE}" != "0" ]]; then
        >&2 echo "sed FAILED: {{$i}}"
        exit 1;
    fi;
    for file in $(cat /templatize.txt); do
        if [[ -f "${file}" ]]; then
            sed -i "s/{{$i}}/${ESCAPED_DIRECTIVE}/g" "${file}"
        fi;
    done;
done;

echo "# generated configurations" >> "${CFG_DSPACE}"
if [[ ! -z "${DS_HIDDEN_METADATA}" ]]; then
    IFS=$', \n\r'
    for i in ${DS_HIDDEN_METADATA}; do
        echo "metadata.hide.${i} = true" >> "${CFG_DSPACE}"
    done;
fi;

if [[ ! -z "${DS_CUSTOM_CONFIG}" ]]; then
    IFS=$'\n\r'
    for i in ${DS_CUSTOM_CONFIG}; do
        echo "${i}" >> "${CFG_DSPACE}"
    done;
fi;

getConfigMap >> "${CFG_DSPACE}"

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
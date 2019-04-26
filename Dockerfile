ARG BUILDER_IMAGE="localhost/dspace/dspace-builder"
ARG TOMCAT_IMAGE="localhost/dspace/dspace-tomcat"

FROM ${BUILDER_IMAGE} as builder

FROM ${TOMCAT_IMAGE}

ARG GIT_COMMIT=""

LABEL hu.itsziget.dspace-tomcat-build.git-commit=$GIT_COMMIT

RUN if [ -z "${GIT_COMMIT}" ]; then >&2 echo "Missing build argument: GIT_COMMIT"; exit 1; fi;
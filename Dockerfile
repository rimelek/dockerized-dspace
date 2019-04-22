ARG BUILDER_IMAGE="dspace-builder"
ARG DSPACE_IMAGE="dspace-tomcat"

FROM ${BUILDER_IMAGE} as builder

FROM ${DSPACE_IMAGE}
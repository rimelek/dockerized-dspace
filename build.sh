#!/usr/bin/env bash

TAG=""
OWNER=""
REGISTRY=""
APP_NAME=""
BUILD_NAME=""

ltrim() {
    local STR="$(echo "${@:-"$(cat -)"}")"
    echo "${STR}" | sed -e 's/^[[:space:]]*//'
}

rtrim() {
    local STR="$(echo "${@:-"$(cat -)"}")"
    echo "${STR}" | sed -e 's/[[:space:]]*$//'
}

trim() {
    local STR="$(echo "${@:-"$(cat -)"}")"
    rtrim "$(ltrim "${STR}")"
}

usage() {
    echo "Usage: $0 [-r <REGISTRY>] [-o <OWNER>] [-t <TAG>] [-a <APP_NAME>] [-b <BUILD_NAME>]"
    echo
    echo "  -a <APP_NAME>    The name of the DSpace app in case you want to build an application image too."
    echo "                   You can pass multiple names but then you need to specify a build name using the option -b. "
    echo "  -b <BUILD_NAME>  If APP_NAME contains only one app then it is the name of the app by default."
    echo "  -o <OWNER>       The owner of the image."
    echo "  -r <REGISTRY>    The name of the registry. (\"localhost\" by default)"
    echo "  -t <TAG>         The tag of the image."
    echo
    echo "  -h               Show the help"
    echo
    echo "The patterns of the final images:"
    echo "builder: <REGISTRY>/<OWNER>/dspace-builder:<TAG>"
    echo "tomcat:  <REGISTRY>/<OWNER>/dspace-tomcat:<TAG>"
    echo "app:     <REGISTRY>/<OWNER>/dspace-tomcat-<BUILD_NAME>"
}

while getopts ':t:a:b:o:r:h' opt; do
    case "${opt}" in
        a)
            APP_NAME="${OPTARG}"
            ;;
        b)
            BUILD_NAME="${OPTARG}"
            ;;
        t)
            TAG="${OPTARG}";
            ;;
        o)
            OWNER="${OPTARG}"
            ;;
        r)
            REGISTRY="${OPTARG}"
            ;;
        h)
            usage
            exit 0
            ;;
        *)
            >&2 echo "Invalid option: ${opt}"
            >&2 usage
            exit 1
    esac
done
shift $((OPTIND-1))

if [[ -z "${TAG}" ]]; then
    >&2 echo "Required option: -t <TAG>"
    exit 1
fi

if [[ -z "${OWNER}" ]]; then
    OWNER="dspace"
fi

if [[ -z "${REGISTRY}" ]]; then
    REGISTRY="localhost"
fi

if [[ -n "${APP_NAME}" ]] && [[ -z "${BUILD_NAME}" ]]; then
    APP_NAME="$(trim "${APP_NAME}")"
    if [[ ! "${APP_NAME}" =~ *" "* ]]; then
        BUILD_NAME="${APP_NAME}"
    else
        >&2 echo "-b <BUILD_NAME> is required when APP_NAME contains multiple applications"
        ecit 1
    fi
fi

# build the builder
BUILDER_IMAGE="${REGISTRY}/${OWNER}/dspace-builder:${TAG}"
docker build \
    -t "${BUILDER_IMAGE}" \
    -f builder.Dockerfile \
    --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
    .

# build the base tomcat
TOMCAT_IMAGE="${REGISTRY}/${OWNER}/dspace-tomcat:${TAG}"
docker build \
    -t "${TOMCAT_IMAGE}" \
    -f tomcat.Dockerfile \
    --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
    .

if [[ -n "${APP_NAME}" ]]; then
    docker build \
        -t ${REGISTRY}/${OWNER}/dspace-tomcat-${BUILD_NAME} \
        --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
        --build-arg APP_NAME="${APP_NAME}" \
        --build-arg BUILDER_IMAGE="${BUILDER_IMAGE}" \
        --build-arg DSPACE_IMAGE="${TOMCAT_IMAGE}" \
        .
fi

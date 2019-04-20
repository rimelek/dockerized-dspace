ARG BUILDER_IMAGE="dspace-builder"

FROM ${BUILDER_IMAGE} as builder

FROM tomcat:8.5-jre8-alpine as app


ARG REDISSON_VERSION=3.10.6

RUN rm -rf ${CATALINA_HOME}/webapps \
 && wget "https://repository.sonatype.org/service/local/repositories/central-proxy/content/org/redisson/redisson-all/${REDISSON_VERSION}/redisson-all-${REDISSON_VERSION}.jar" \
        -O "${CATALINA_HOME}/lib/redisson-all-${REDISSON_VERSION}.jar" \
 && wget "https://repository.sonatype.org/service/local/repositories/central-proxy/content/org/redisson/redisson-tomcat-8/${REDISSON_VERSION}/redisson-tomcat-8-${REDISSON_VERSION}.jar" \
        -O "${CATALINA_HOME}/lib/redisson-tomcat-8-${REDISSON_VERSION}.jar"

COPY --from=builder /app/dspace /app/dspace
COPY --from=builder /dspace-webapps ${CATALINA_HOME}/webapps
COPY system /
COPY tomcat-solr /tmp/tomcat-solr
COPY tomcat-xmlui /tmp/tomcat-xmlui

ARG APP_NAME=xmlui
ARG APP_ROOT=xmlui

ENV APP_NAME=${APP_NAME}

RUN if [ "${APP_NAME}" == "${APP_ROOT}" ]; then \
        ln -s ${CATALINA_HOME}/webapps/${APP_NAME} ${CATALINA_HOME}/webapps/ROOT; \
    fi \
 && if [ -d "/tmp/tomcat-${APP_NAME}" ]; then \
        cp -R /tmp/tomcat-${APP_NAME}/. /usr/local/tomcat/. && rm -rf /tmp/tomcat-${APP_NAME}; \
    fi \
 && chmod +x -R /app/bin/*.sh \
 && source /app/bin/resources.sh \
 && templatize \
 && sed -i  's~<themes>~<themes><theme name="Mirage 2" regex=".*" path="Mirage2/" />~' "${DSPACE_DIR}/config/xmlui.xconf"

ENV DS_PORT="8080" \
    DS_DB_HOST="db" \
    DS_DB_PORT="5432" \
    DS_DB_SERVICE_NAME="dspace" \
    DS_LOGLEVEL_OTHER="WARN" \
    DS_LOGLEVEL_DSPACE="WARN" \
    DS_PROTOCOL="http" \
    DS_SOLR_HOSTNAME="solr" \
    DS_CUSTOM_CONFIG=""

ENV config.dspace.ui="xmlui" \
    config.dspace.url="\${dspace.baseUrl}" \
    config.handle.canonical.prefix="\${dspace.url}/handle/" \
    config.swordv2-server.url="\${dspace.url}/swordv2" \
    config.swordv2-server.servicedocument.url="\${swordv2-server.url}/servicedocument"

ENV submission-map.traditional="default" \
    form-map.traditional="default"

ARG GIT_COMMIT=""

LABEL hu.itsziget.dspace.git-commit=$GIT_COMMIT
ENV GIT_COMMIT_DSPACE=$GIT_COMMIT

RUN if [ -z "${GIT_COMMIT_DSPACE}" ]; then >&2 echo "Missing build argument: GIT_COMMIT"; exit 1; fi;

ENTRYPOINT ["/app/bin/dspace-start.sh"]
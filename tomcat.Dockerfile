FROM tomcat:8.5-jre8-alpine

ARG REDISSON_VERSION=3.10.6

RUN rm -rf ${CATALINA_HOME}/webapps \
 && wget "https://repository.sonatype.org/service/local/repositories/central-proxy/content/org/redisson/redisson-all/${REDISSON_VERSION}/redisson-all-${REDISSON_VERSION}.jar" \
        -O "${CATALINA_HOME}/lib/redisson-all-${REDISSON_VERSION}.jar" \
 && wget "https://repository.sonatype.org/service/local/repositories/central-proxy/content/org/redisson/redisson-tomcat-8/${REDISSON_VERSION}/redisson-tomcat-8-${REDISSON_VERSION}.jar" \
        -O "${CATALINA_HOME}/lib/redisson-tomcat-8-${REDISSON_VERSION}.jar"

COPY system /

ONBUILD COPY --from=builder /app/dspace /app/dspace
ONBUILD COPY --from=builder /dspace-webapps ${CATALINA_HOME}/webapps

ONBUILD ARG APP_NAME=xmlui
ONBUILD ARG APP_ROOT=xmlui

ONBUILD ENV APP_NAME=${APP_NAME}

ONBUILD RUN chmod +x -R /app/bin/*.sh \
         && source /app/bin/resources.sh \
         && if [ "${APP_NAME}" == "${APP_ROOT}" ]; then \
                ln -s ${CATALINA_HOME}/webapps/${APP_NAME} ${CATALINA_HOME}/webapps/ROOT; \
            fi \
         && if [ -d "/app/tomcat/webapps/${APP_NAME}" ]; then \
                cp -R "/app/tomcat/webapps/${APP_NAME}/." "/usr/local/tomcat/webapps/${APP_NAME}/."; \
            fi \
         && templatize \
         && sed -i  's~<themes>~<themes><theme name="Mirage 2" regex=".*" path="Mirage2/" />~' "${DSPACE_DIR}/config/xmlui.xconf"

ONBUILD ENV DS_PORT="8080" \
            DS_DB_HOST="db" \
            DS_DB_PORT="5432" \
            DS_DB_SERVICE_NAME="dspace" \
            DS_LOGLEVEL_OTHER="WARN" \
            DS_LOGLEVEL_DSPACE="WARN" \
            DS_PROTOCOL="http" \
            DS_SOLR_HOSTNAME="solr" \
            DS_CUSTOM_CONFIG="" \
            DS_REST_FORCE_SSL="true"

ONBUILD ENV config.dspace.ui="xmlui" \
            config.dspace.url="\${dspace.baseUrl}" \
            config.handle.canonical.prefix="\${dspace.url}/handle/" \
            config.swordv2-server.url="\${dspace.url}/swordv2" \
            config.swordv2-server.servicedocument.url="\${swordv2-server.url}/servicedocument"

ONBUILD ENV submission-map.traditional="default" \
            form-map.traditional="default"

ARG GIT_COMMIT=""

LABEL hu.itsziget.dspace-tomcat.git-commit=$GIT_COMMIT

RUN if [ -z "${GIT_COMMIT}" ]; then >&2 echo "Missing build argument: GIT_COMMIT"; exit 1; fi;

ENTRYPOINT ["/app/bin/dspace-start.sh"]
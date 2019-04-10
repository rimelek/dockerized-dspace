FROM maven:3.5-jdk-8-alpine as builder

# system packages

RUN apk --no-cache add nodejs \
 && apk --no-cache add npm \
 && apk --no-cache add ruby \
 && apk --no-cache add ruby-dev \
 && apk --no-cache add ruby-rdoc \
 && apk --no-cache add ruby-irb \
 && apk --no-cache add libffi-dev \
 && apk --no-cache add gcc \
 && apk --no-cache add musl-dev \
 && apk --no-cache add make \
 && apk --no-cache add git \
 && apk --no-cache add wget

# nodejs / ruby packages
RUN echo "export GEM_HOME=\$(gem environment gemhome)" >> /etc/profile.d/dspace.sh \
 && echo "export GEM_PATH=\$(gem environment gempath)" >> /etc/profile.d/dspace.sh \
 && chmod +x /etc/profile.d/dspace.sh

RUN npm install -g npm@6.4.0 \
 && npm update -g \
 && npm install -g grunt-cli bower \
 && gem install compass

ENV ANT_VERSION=1.10.1

RUN wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz \
        && wget --no-check-certificate --no-cookies http://archive.apache.org/dist/ant/binaries/apache-ant-${ANT_VERSION}-bin.tar.gz.md5 \
        && echo "$(cat apache-ant-${ANT_VERSION}-bin.tar.gz.md5)  apache-ant-${ANT_VERSION}-bin.tar.gz" | md5sum -c \
        && mkdir -p /opt \
        && tar -zvxf apache-ant-${ANT_VERSION}-bin.tar.gz -C /opt/ \
        && ln -s /opt/apache-ant-${ANT_VERSION} /opt/ant \
        && ln -s /opt/ant/bin/ant /usr/bin/ant \
        && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz \
        && rm -f apache-ant-${ANT_VERSION}-bin.tar.gz.md5

# mirage2

ARG DSPACE_VERSION=6.3
# COPY src /src
RUN mkdir /src \
 && wget -qO- https://github.com/DSpace/DSpace/releases/download/dspace-${DSPACE_VERSION}/dspace-${DSPACE_VERSION}-src-release.tar.gz | tar xvz --strip 1 -C /src
COPY srcCustom /src

RUN cd /src/dspace-xmlui-mirage2/src/main/webapp \
 && adduser -D builder \
 && chown builder -R . \
 && su -c "npm install" builder

# dspace build

RUN cd /src \
 && . /etc/profile.d/dspace.sh \
 && mvn package -Dmirage2.on=true -Dmirage2.deps.included=false -Djava.version=1.8

RUN cd /src/dspace/target/dspace-installer \
 && ant install_code \
 && ant copy_webapps \
 && ant update_geolite

ARG APP_NAME=xmlui

RUN mkdir /dspace-webapps \
 && cp -rp /dspace/webapps/${APP_NAME}/. /dspace-webapps/${APP_NAME} \
 && rm -rf /dspace/webapps

FROM tomcat:8.5-jre8-alpine as app


ARG REDISSON_VERSION=3.10.6

RUN rm -rf ${CATALINA_HOME}/webapps \
 && wget "https://repository.sonatype.org/service/local/repositories/central-proxy/content/org/redisson/redisson-all/${REDISSON_VERSION}/redisson-all-${REDISSON_VERSION}.jar" \
        -O "${CATALINA_HOME}/lib/redisson-all-${REDISSON_VERSION}.jar" \
 && wget "https://repository.sonatype.org/service/local/repositories/central-proxy/content/org/redisson/redisson-tomcat-8/${REDISSON_VERSION}/redisson-tomcat-8-${REDISSON_VERSION}.jar" \
        -O "${CATALINA_HOME}/lib/redisson-tomcat-8-${REDISSON_VERSION}.jar"

COPY --from=builder /dspace /dspace
COPY --from=builder /dspace-webapps ${CATALINA_HOME}/webapps
COPY system /
COPY dspace /dspace
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
 && chmod +x /dspace-start.sh /cron.sh \
 && echo "/dspace/config/log4j.properties" >> /templatize.txt \
 && echo "/dspace/config/crosswalks/oai/description.xml" >> /templatize.txt \
 && echo "${CATALINA_HOME}/webapps/${APP_NAME}/static/robots.txt" >> /templatize.txt \
 && IFS=$'\r\n' \
 && for i in $(cat /templatize.txt); do \
       if [ -f "${i}" ]; then \
          mv "${i}" "${i}.tpl"; \
       fi; \
    done

ENV DS_PORT="8080" \
    DS_DB_HOST="database" \
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


ARG GIT_COMMIT=""

LABEL git-commit=$GIT_COMMIT
ENV GIT_COMMIT=$GIT_COMMIT

RUN if [ -z "${GIT_COMMIT}" ]; then >&2 echo "Missing build argument: GIT_COMMIT"; exit 1; fi;

ENTRYPOINT ["/dspace-start.sh"]
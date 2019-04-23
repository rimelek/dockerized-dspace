FROM maven:3.5-jdk-8-alpine

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

RUN mkdir /src \
 && wget -qO- https://github.com/DSpace/DSpace/releases/download/dspace-${DSPACE_VERSION}/dspace-${DSPACE_VERSION}-src-release.tar.gz | tar xvz --strip 1 -C /src

# onbuild

ONBUILD COPY srcCustom /src

ONBUILD RUN cd /src/dspace-xmlui-mirage2/src/main/webapp \
         && adduser -D builder \
         && chown builder -R . \
         && su -c "npm install" builder \
         && cd /src \
         && . /etc/profile.d/dspace.sh \
         && sed -i 's~^dspace.dir\(.*\)~dspace.dir = /app/dspace~' /src/dspace/config/dspace.cfg \
         && mvn package -Dmirage2.on=true -Dmirage2.deps.included=false -Djava.version=1.8 \
         && cd /src/dspace/target/dspace-installer \
         && ant install_code \
         && ant copy_webapps \
         && ant update_geolite \
         && rm -rf /src

ONBUILD ARG APP_NAME=xmlui

ONBUILD RUN mkdir /dspace-webapps \
         && cp -rp /app/dspace/webapps/${APP_NAME}/. /dspace-webapps/${APP_NAME} \
         && rm -rf /app/dspace/webapps

ARG GIT_COMMIT=""

LABEL hu.itsziget.dspace-builder.git-commit=$GIT_COMMIT
ENV GIT_COMMIT_DSPACCE_BUILDER=$GIT_COMMIT

RUN if [ -z "${GIT_COMMIT_DSPACCE_BUILDER}" ]; then >&2 echo "Missing build argument: GIT_COMMIT"; exit 1; fi;
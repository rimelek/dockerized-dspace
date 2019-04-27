# Dockerized DSpace

Running DSpace inside docker containers can be tricky. This project helps you to run each webapp in separate containers.
In fact, you can decide which app you want to install; therefore you can still run each of them in the same container.

Supported application are:

* oai
* rest
* solr
* swordv2
* xmlui

## Installation

### Build the images

[builder.Dockerfile](builder.Dockerfile) is to build DSpace. It contains [ONBUILD](https://docs.docker.com/engine/reference/builder/#onbuild)
instructions so you can place your customization into "srcCustom" directory next to your Dockerfile.
Your custom sourcecode must be in the same structure as the [official DSpace code](https://github.com/DSpace/DSpace/tree/dspace-6.3).
The custom code will be merged with the original code downloaded from GitHub.

Build the builder

```bash
docker build \
    -t "localhost/dspace/dspace-builder" \
    -f builder.Dockerfile \
    --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
    .
```

or download it from [Docker Hub](https://cloud.docker.com/u/itsziget/repository/docker/itsziget/dspace-builder)

[tomcat.Dockerfile](tomcat.Dockerfile) is similar to the builder except it helps you create a tomcat image
for DSpace applications. It contains configuration templates, Redis session support and scripts to let you 
change configurations using environment variables.

Build the base tomcat image:

```bash
docker build \
    -t "localhost/dspace/dspace-tomcat" \
    -f tomcat.Dockerfile \
    --build-arg GIT_COMMIT=$(git rev-parse HEAD) \
    .
```

or download it from [Docker Hub](https://cloud.docker.com/u/itsziget/repository/docker/itsziget/dspace-tomcat)

If you want to build the final application image, you need to create a Dockerfile like the following:

```Dockerfile
FROM localhost/dspace/dspace-builder as builder

FROM localhost/dspace/dspace-tomcat
```

and place the custom sourcecode into "srcCustom" and the tomcat image customization into "system" directory.

You can use the images from Docker Hub of course.

**NOTE**: "as builder" is important at the and of the first line. The second stage will copy the built files
from the "builder" stage.

This way you can use any compatible builder and tomcat images.

Use [build.sh](build.sh) to build both of the above images and create the application image using [Dockerfile](Dockerfile)

See the output of the following command for more information:

```
./build.sh -h
```

### Prepare the database

First of all, you need to start the database:

```bash
docker-compose up -d db
```

**Create a user and database**

Run the following commands:

```bash
echo $'password\npassword' | docker-compose exec -T --user postgres db createuser dspace --pwprompt
docker-compose exec --user postgres db createdb dspace --owner dspace
```

Install pgcrypto extension:

```bash
docker-compose exec --user postgres db psql dspace -c 'create extension pgcrypto;'
```

### Install DSpace

The database will be installed automatically when xmlui starts. Let's run it:

If you want to run each app in separate container

```bash
docker-compose up -d xmlui
```

Or run each app in the same container:

```bash
docker-compose up -d allapps
```

Now you need to create an administrator:

```bash
docker-compose exec xmlui /dspace/bin/dspace create-administrator
```
or
```bash
docker-compose exec allapps /dspace/bin/dspace create-administrator
```

### Open the web applications in your browser

You have three options:

**1. Use the docker containers IP addresses**

Each container has an IP address. Inspect the containers and get the addresses:

```bash
APP=xmlui docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$value.IPAddress}}{{end}}' $(docker-compose ps -q ${APP}
# output: 172.20.0.2
``` 

Examples:

* **xmlui:** 172.20.0.2:8080
* **oai:** 172.20.0.3:8080/oai
* **solr:** 172.20.0.4:8080/solr
* **mailer:** 172.20.0.5:8025
* **pgadmin:** 172.20.0.6

Note that the IP addresses can be changed so it is not the recommended way.

**2. Automatically updated hosts file**

If you are on linux host, you can update the hosts file automatically and use custom hostnames instead of the IP addresses.
[docker-compose.hosts-updater](docker-compose.hosts-updater.yml) contains the necessary services.

Before you run the hosts updater create a copy of "/etc/hosts" as "/etc/hosts.docker.tpl".
hosts.docker.tpl will never be changed. It will be a template so the hosts file will always contain everything
from the hosts.tpl and the updater appends the additional domains. If anything goes wrong and your hosts file becomes corrupted
restore it from the template manually.

```bash
docker-compose -f docker-compose.yml -f docker-comose.hosts-updater.yml up -d xmlui
```

Default hosts:

* **xmlui:** dspace:8080
* **oai:** oai.dspace:8080/oai
* **solr:** solr.dspace:8080/solr
* **mailer:** mailer.dspace:8025
* **pgadmin:** pgadmin.dspace

**3. proxy**

Use a reverse proxy service like [nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy)

**4. Use port mapping**

Map the containers ports to the host so you can use fix local ip addresses.
See [docker-compose.portmap.yml](docker-compose.portmap.yml)

```bash
docker-compose -f docker-compose.yml -f docker-compose.portmap.yml up -d xmlui
```

In this case the following addresses can be used:

* **xmlui:** 127.0.10.1:8080
* **oai:** 127.0.10.2:8080/oai
* **solr:** 127.0.10.3:8080/solr
* **mailer:** 127.0.0.4:8025
* **pgadmin:** 127.0.0.5

## Custom configuration

There are environment variables to customize configurations like database connection and URL-s:

* **DS_PORT:** (default: 8080) Public port of the XMLUI webinterface.
* **DS_DB_HOST:** (default: "db") The host of the postgresql database server 
* **DS_DB_PORT:** (default: 5432) The port of the postgresql database server
* **DS_DB_SERVICE_NAME:** (default: "dspace") The name of the postgresql database
* **DS_LOGLEVEL_OTHER:** (default: "WARN") Value of loglevel.other in log4j.properties
* **DS_LOGLEVEL_DSPACE:** (default: "WARN") Value of loglevel.dspace in log4j.properties
* **DS_PROTOCOL:** (default: "http") Protocol of the XMLUI. https or http \
* **DS_SOLR_HOSTNAME:** (default: "solr") Internal hostname of solr server. It will always use http protocol.
* **DS_SOLR_ALLOW_REMOTE:** (default: "false") If it is "true" solr can be accessible from anywhere. In this case you
                            should use an external firewall/proxy to deny untrusted clients to connect.   
* **DS_CUSTOM_CONFIG:** (default: "") It is a multiline string for custom configurations that you could use in dspace.cfg
* **DS_REST_FORCE_SSL:** (default: "true") The rest API requires secure connection by default. Using containers
                         it can be unnecessary behind a secure proxy. You can turn it off by setting it to "false"
* **DS_REDIS_SESSION:** (default: true) During an upgrade, you would lose all of the sessions without an external session database.
                        However, if you do not wish to use [Redis](https://redis.io/), you can turn it off by setting
                        the variable to "false". Currently, the redis server must be accessible as "redis".
                        Docker lets you map custom hostnames to IP addresses.
                        See [docker run](https://docs.docker.com/engine/reference/commandline/run/)
                        for more information.

Any configuration directive can be set using environment variables prefixed by "config.".

Example:

```yaml
xmlui:
  environment:
    config.dspace.url: https://mydspace.tld:8080
```

The following are set by default in each docker image:

* **config.dspace.ui:** "xmlui"
* **config.dspace.url:** "${dspace.baseUrl}"
* **config.handle.canonical.prefix:** "${dspace.url}/handle/"
* **config.swordv2-server.url:** "${dspace.url}/swordv2"
* **config.swordv2-server.servicedocument.url:** "${swordv2-server.url}/servicedocument"
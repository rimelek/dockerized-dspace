# Dockerized DSpace

Running DSpace inside docker containers can be tricky. This project helps you to run each webapp in separate containers.

## Installation

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

```bash
docker-compose up -d xmlui
```

Now you need to create an administrator:

```bash
docker-compose exec xmlui /dspace/bin/dspace create-administrator
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
* **DS_CUSTOM_CONFIG:** (default: "") It is a multiline string for custom configurations that you could use in dspace.cfg

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
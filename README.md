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
APP=xmlui docker inspect -f '{{range $key, $value := .NetworkSettings.Networks}}{{$value.IPAddress}}{{end}}' $(docker-compose ps -q ${APP};
# output: 172.20.0.2
``` 

Examples:

* **xmlui:** 172.20.0.2:8080
* **oai:** 172.20.0.3:8080/oai
* **solr:** 172.20.0.4:8080/solr
* **mailer:** 172.20.0.5:8025

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

## Custom configuration

Coming soon...
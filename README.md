# Dockerized DSpace

Running DSpace inside docker containers can be tricky. This project helps you to run each webapp in separate containers.

## Installation

First of all, you need to start xmlui:

```bash
docker-compose up -d xmlui
```

### Prepare the database

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

The database will be installed automatically when xmlui starts. Now you need to create an administrator:

```bash
docker-compose exec xmlui ./dspace create-administrator
```

### Access the XMLUI

Coming soon...
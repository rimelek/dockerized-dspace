dspace.dir = /app/dspace
dspace.baseUrl = {{PROTOCOL}}://${dspace.hostname}{{PORT_SUFFIX}}
solr.server = http://{{SOLR_HOSTNAME}}:8080/solr
db.url = jdbc:postgresql://{{DB_HOST}}:{{DB_PORT}}/{{DB_SERVICE_NAME}}

plugin.sequence.org.dspace.authenticate.AuthenticationMethod = \
    org.dspace.authenticate.IPAuthentication, \
    org.dspace.authenticate.PasswordAuthentication

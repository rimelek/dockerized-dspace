dspace.baseUrl = {{PROTOCOL}}://${dspace.hostname}{{PORT_SUFFIX}}
solr.server = http://{{SOLR_HOSTNAME}}:8080/solr
db.url = jdbc:postgresql://{{DB_HOST}}:{{DB_PORT}}/{{DB_SERVICE_NAME}}

plugin.sequence.org.dspace.authenticate.AuthenticationMethod = \
    org.dspace.authenticate.IPAuthentication, \
    org.dspace.authenticate.PasswordAuthentication, \
    hu.pte.lib.pea.authenticate.LDAPAuthentication

module_dir = modules

include = \
    ${module_dir}/authentication-pealdap.cfg, \
    ${module_dir}/pea.cfg, \
    ${module_dir}/languages.cfg

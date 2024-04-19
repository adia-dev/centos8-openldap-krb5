#!/bin/bash

set -Eeuo pipefail

log() {
    echo "[setup_slapd] $1" | tee -a /var/log/openldap_setup.log
}

handle_error() {
    log "ERROR: An error occurred in the LDAP setup process."
    exit 1
}

ldap_modify() {
    echo "[setup_slapd] Applying modification: $1" | tee -a /var/log/openldap_setup.log
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f $1
}

ldap_add() {
    echo "[setup_slapd] Adding: $1" | tee -a /var/log/openldap_setup.log
    ldapadd -Q -Y EXTERNAL -H ldapi:/// -f $1
}

ldap_add_binded() {
    echo "[setup_slapd] Adding: $1" | tee -a /var/log/openldap_setup.log
    LDAP_PASSWORD='Respons11'
    ldapadd -xc -w $LDAP_PASSWORD -D 'cn=admin,dc=example,dc=com' -f $1
}

trap 'handle_error' ERR

start_slapd_service() {
    log "Attempting to start slapd service..."
    systemctl enable slapd && systemctl start slapd
    log "slapd started successfully."
}

prepare_ldap_environment() {
    log "Copying DB_CONFIG to /var/lib/ldap..."
    cp /setup-openldap/database/DB_CONFIG /var/lib/ldap/DB_CONFIG

    log "Copying tls certs to /etc/openldap/certs..."
    cp /setup-openldap/certs/* /etc/openldap/certs

    log "Copying ldap.conf /etc/openldap/..."
    cp /setup-openldap/config/ldap.conf /etc/openldap/

    log "Changing ownership of /var/lib/ldap and /setup-openldap to ldap:ldap..."
    chown -R ldap:ldap /var/lib/ldap/ /etc/openldap/certs/ /setup-openldap/
    chmod 0640 /etc/openldap/certs/server.key
}

add_ldap_schemas() {
    log "Adding LDAP core schemas..."
    ldap_add /etc/openldap/schema/cosine.ldif
    ldap_add /etc/openldap/schema/nis.ldif
    ldap_add /etc/openldap/schema/inetorgperson.ldif

    log "Adding LDAP custom schemas..."
    ldap_add /setup-openldap/config/schema/criteo.ldif
}

update_ldap_config() {
    log "Setting up logging"
    ldap_modify /setup-openldap/ldif/logging.ldif

    log "Setting up db indexes"
    ldap_modify /setup-openldap/ldif/db_index.ldif

    log "Setting up root pw..."
    ldap_modify /setup-openldap/ldif/ch_root_pw.ldif

    log "Setting up domain..."
    ldap_modify /setup-openldap/ldif/ch_domain.ldif

    log "Setting up organization..."
    ldap_add_binded /setup-openldap/ldif/organization.ldif
}

enable_tls() {
    log "Setting up tls..."
    ldap_modify /setup-openldap/ldif/ch_tls.ldif

    # Check TLS
    ldapwhoami -x -ZZ -H ldap://example.com
    log "TLS is enabled"
}

enable_logging() {
    log "Activating openldap rsyslog..."
    echo "local4.*    /var/log/slapd.log" >> /etc/rsyslog.conf
    systemctl restart rsyslog
    log "Restarting rsyslog daemon..."
}

restart_slapd() {
    log "Restarting slapd to apply changes..."
    systemctl restart slapd
    log "slapd is running and ready to use."
}

main() {
    start_slapd_service
    prepare_ldap_environment
    add_ldap_schemas
    update_ldap_config
    enable_logging
    enable_tls
    restart_slapd

    tail --retry --follow=name /var/log/slapd.log &
}

main

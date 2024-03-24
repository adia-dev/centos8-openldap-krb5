#!/bin/bash

set -e

echo "Attempting to start slapd service..."
if systemctl enable slapd && systemctl start slapd; then
    echo "slapd started successfully."
else
    echo "Error: Failed to setup slapd."
    exit 1
fi

echo "Copying DB_CONFIG example to /var/lib/ldap..."
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG

echo "Changing ownership of /var/lib/ldap to ldap:ldap..."
chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /srv/openldap

echo "Adding LDAP core schemas..."
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

echo "Setting up default domain, slapd domain, and user..."
default_domain=$(hostname)
default_slapd_domain=$(echo $default_domain | sed 's/\./,dc=/g; s/^/dc=/')
default_slapd_user='admin'
default_slapd_organization='Example Organization'
default_password='Respons11'
default_slapd_password=$(slappasswd -s $default_password)

export SLAPD_ROOT_PASSWORD="${SLAPD_ROOT_PASSWORD:-$default_slapd_password}"
export SLAPD_ROOT_USER="${SLAPD_ROOT_USER:-$default_slapd_user}"
export SLAPD_DOMAIN="${SLAPD_DOMAIN:-$default_slapd_domain}"
export SLAPD_DC=$(hostname | cut -d '.' -f 1)
export SLAPD_ORGANIZATION="${SLAPD_ORGANIZATION:-$default_slapd_organization}"

hydrate_template() {
    echo "Hydrating template: $1"
    sed \
        -e "s/{{SLAPD_ROOT_PASSWORD}}/$SLAPD_ROOT_PASSWORD/g" \
        -e "s/{{SLAPD_ROOT_USER}}/$SLAPD_ROOT_USER/g" \
        -e "s/{{SLAPD_DOMAIN}}/$SLAPD_DOMAIN/g" \
        -e "s/{{SLAPD_DC}}/$SLAPD_DC/g" \
        -e "s/{{SLAPD_ORGANIZATION}}/$SLAPD_ORGANIZATION/g" \
        "$1" > "$2"
}

perform_ldap_modify() {
    echo "Modifying LDAP configuration for $1..."
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$1"
    if [ $? -eq 0 ]; then
        echo "Successfully modified $1"
    else
        echo "Error modifying $1"
        exit 1
    fi
}

hydrate_template /srv/openldap/ldif/templates/chrootpw.template.ldif   /tmp/chrootpw.ldif
hydrate_template /srv/openldap/ldif/templates/chdomain.template.ldif   /tmp/chdomain.ldif
hydrate_template /srv/openldap/ldif/templates/monitor.template.ldif    /tmp/monitor.ldif
hydrate_template /srv/openldap/ldif/templates/basedomain.template.ldif /tmp/basedomain.ldif

echo "Modifying LDAP configuration..."
perform_ldap_modify /tmp/chrootpw.ldif

echo "Setting up the root identity"
perform_ldap_modify /tmp/chdomain.ldif

echo "Setting up the monitoring database"
perform_ldap_modify /tmp/monitor.ldif

echo "Setting up logging"
perform_ldap_modify /srv/openldap/ldif/core/logging.ldif

echo "Adding base domain to LDAP..."
ldapadd -x -D "cn=$SLAPD_ROOT_USER,$SLAPD_DOMAIN" -w $SLAPD_ROOT_PASSWORD -f /tmp/basedomain.ldif

echo "Restarting slapd and rsyslog to apply changes..."
systemctl restart slapd
systemctl restart rsyslog

echo "Adding uid next to LDAP..."
ldapmodify -Y EXTERNAL -H ldapi:/// -f /srv/openldap/ldif/core/uidnext.ldif
ldapadd -x -D "cn=$SLAPD_ROOT_USER,$SLAPD_DOMAIN" -w $SLAPD_ROOT_PASSWORD -f /srv/openldap/ldif/uidnext.ldif
ldapadd -cx -D "cn=$SLAPD_ROOT_USER,$SLAPD_DOMAIN" -w $SLAPD_ROOT_PASSWORD -f /srv/openldap/ldif/users.ldif

echo "slapd is running and ready to use."

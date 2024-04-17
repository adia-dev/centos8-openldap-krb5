#!/bin/bash

set -e

echo "Attempting to start slapd service..."
if systemctl enable slapd && systemctl start slapd; then
    echo "slapd started successfully."
else
    echo "Error: Failed to setup slapd."
    exit 1
fi

echo "Copying DB_CONFIG to /var/lib/ldap..."
cp /setup-openldap/database/DB_CONFIG /var/lib/ldap/DB_CONFIG

echo "Changing ownership of /var/lib/ldap and /setup-openldap to ldap:ldap..."
chown -R ldap:ldap /var/lib/ldap/
chown -R ldap:ldap /setup-openldap

echo "Adding LDAP core schemas..."
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

echo "Adding LDAP custom schemas..."
ldapadd -Q -Y EXTERNAL -H ldapi:/// -f /setup-openldap/config/schema/criteo.ldif

echo "Setting up logging"
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /setup-openldap/ldif/core/logging.ldif

echo "Setting up db indexes"
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f /setup-openldap/ldif/core/db_index.ldif

echo "Restarting slapd to apply changes..."
systemctl restart slapd

echo "slapd is running and ready to use."

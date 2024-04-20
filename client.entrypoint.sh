#!/bin/bash

set -e

trap 'error_handler' ERR

export LDAP_SERVER_HOST="172.17.0.3"
export LDAP_SERVER_HOSTNAME="ldap.example.com"

error_handler() {
    echo "[ERROR] An error occurred during LDAP setup." >&2
    exit 1
}

add_ldap_server_host() {
    echo "Adding LDAP server host to /etc/hosts ($LDAP_SERVER_HOST)..."

    echo "$LDAP_SERVER_HOST     $LDAP_SERVER_HOSTNAME" >> /etc/hosts

    echo "LDAP server host added to /etc/hosts."
}

setup_sshd() {
    echo "Setting up sshd services..."

    systemctl restart sshd
    systemctl enable sshd

    echo "sshd is enabled."
}

setup_sssd() {
    echo "Setting up sssd services..."
    authselect select sssd with-mkhomedir --force
    cp /setup-openldap-client/config/sssd/sssd.conf /etc/sssd/sssd.conf
    cp /setup-openldap-client/config/sssd/nslcd.conf /etc/nslcd.conf
    chmod 600 /etc/sssd/sssd.conf
    chmod 600 /etc/nslcd.conf

    systemctl restart sssd oddjobd nslcd
    systemctl enable sssd oddjobd nslcd

    cp -Rp /usr/share/authselect/default/sssd /etc/authselect/custom/nslcd
    cd /etc/authselect/custom/nslcd
    sed -i 's/sss/ldap/g' fingerprint-auth
    sed -i 's/sss/ldap/g' password-auth
    sed -i 's/sss/ldap/g' smartcard-auth
    sed -i 's/sss/ldap/g' system-auth
    sed -i 's/sss/ldap/g' nsswitch.conf
    sed -i 's/SSSD/NSLCD/g' REQUIREMENTS

    authselect select custom/nslcd --force

    echo "SSSD is enabled."
}

main() {
    echo "Starting setup process..."

    add_ldap_server_host
    setup_sssd
    setup_sshd

    echo "System is ready."
}

# Echo the initialization message
echo "Initialization sequence is now backgrounded."

# Run the main function in the background
(sleep 3; main) &

# Execute /usr/sbin/init in the foreground
exec /usr/sbin/init

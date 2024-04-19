#!/bin/bash

# Use 'set -e' to exit the script when a command fails
set -e

# Use 'trap' to capture EXIT signals and handle errors
trap 'error_handler' ERR

# Function to handle errors
error_handler() {
    echo "[ERROR] An error occurred during LDAP setup." >&2
    # Here you can add additional logging or error notification mechanisms
    exit 1
}

# Set up OpenLDAP services
setup_sssd() {
    echo "Setting up sssd services..."
    authselect select sssd with-mkhomedir --force
    cp /setup-openldap-client/sssd/sssd.conf /etc/sssd/sssd.conf
    chmod 600 /etc/sssd/sssd.conf

    systemctl restart sssd oddjobd
    systemctl enable sssd oddjobd
}

main() {
    echo "Starting setup process..."

    setup_sssd

    echo "System is ready."
}

# Echo the initialization message
echo "Initialization sequence is now backgrounded."

# Run the main function in the background
(sleep 3; main) &

# Execute /usr/sbin/init in the foreground
exec /usr/sbin/init

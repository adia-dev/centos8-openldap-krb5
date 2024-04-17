#!/bin/bash

setup_openldap() {
    echo "Setting up OpenLDAP services..."
    /setup-openldap/scripts/setup_slapd.sh
}

# Perform health checks on LDAP service
perform_health_check() {
    local max_retries=25
    local retries=1
    local retry_delay=1

    echo "Performing health check on LDAP service..."
    until ldapsearch -x -b "" -s base "objectclass=*" -H ldapi:/// >/dev/null 2>&1; do
        if (( retries < max_retries )); then
            echo "Waiting for slapd to start, retrying in $retry_delay seconds (Retry $retries of $max_retries)..."
            ((retries++))
            sleep $retry_delay
        else
            echo "Error: slapd failed to start after $max_retries retries."
            exit 1
        fi
    done
    echo "OpenLDAP is healthy."
}

# Main function to control the flow of operations
main() {
    echo "Starting setup process..."

    setup_openldap
    perform_health_check

    echo "System is ready."
}

echo "Initialization sequence is now backgrounded."
(sleep 3; main) &

exec /usr/sbin/init

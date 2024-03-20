#!/bin/bash

# Function to setup slapd
setup_slapd() {
    sleep 10
    echo "Waiting for systemd to launch..."
    if systemctl enable slapd && systemctl start slapd; then
        echo "slapd setup completed successfully."
    else
        echo "Error: Failed to setup slapd."
        exit 1
    fi
}

# Function to perform health check
perform_health_check() {
    local max_retries=20
    local retries=1
    until ldapsearch -x -b "" -s base "objectclass=*" -H ldapi:/// >/dev/null 2>&1; do
        if [ $retries -lt $max_retries ]; then
            echo "Waiting for slapd to start, retrying in 3 seconds (Retry $retries of $max_retries)..."
            ((retries++))
            sleep 3
        else
            echo "Error: slapd failed to start after $max_retries retries."
            exit 1
        fi
    done
    echo "slapd is running."
}

# Main execution
setup_slapd &
perform_health_check &

# Start the init process
echo "Starting the init process..."
exec /usr/sbin/init
echo "Init process completed, systemd operations should be accessible now."

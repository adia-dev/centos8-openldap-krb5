#!/bin/bash

set -e

sed -i 's/FirewallBackend=nftables/FirewallBackend=iptables/g' /etc/firewalld/firewalld.conf

if systemctl enable firewalld && systemctl restart firewalld; then
    echo "firewalld started successfully."
else
    echo "Error: Failed to setup firewalld."
    exit 1
fi

echo "Configuring firewall for LDAP..."
firewall-cmd --add-service=ldap --permanent
firewall-cmd --reload

# Disabling for debug purposes
systemctl stop firewalld

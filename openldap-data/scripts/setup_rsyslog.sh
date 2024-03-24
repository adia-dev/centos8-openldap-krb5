#!/bin/bash

if systemctl enable rsyslog && systemctl start rsyslog; then
    echo -e "# Slapd logs" >> /etc/rsyslog.d/slapd.conf
    echo -e "local4.*                                                /var/log/ldap.log" >> /etc/rsyslog.d/slapd.conf

    sed -i 's/#module(load="imudp")/module(load="imudp")/g' /etc/rsyslog.conf
    sed -i 's/#input(type="imudp" port="514")/input(type="imudp" port="514")/g' /etc/rsyslog.conf

    echo "rsyslog setup completed successfully."
else
    echo "Error: Failed to setup rsyslog."
    exit 1
fi

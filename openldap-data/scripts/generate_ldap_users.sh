#!/bin/bash

USERNAME='adia'
USER_ID=10000
TEMPLATE=$(cat ../ldif/ldapuser.ldif)

display_usage() {
    echo "Usage: $0 <number>"
    echo "This script generates LDAP user entries based on a template."
    echo "  <number>: Number of user entries to generate."
}

if [ $# -ne 1 ]; then
    display_usage
    exit 1
fi

for ((i = 1; i <= $1; i++)); do
    entry=$(echo "$TEMPLATE" | sed -e "s/{{USERNAME}}/$USERNAME/g" -e "s/{{USER_ID}}/$((USER_ID + i))/g")
    echo "$entry"
    echo ""
done

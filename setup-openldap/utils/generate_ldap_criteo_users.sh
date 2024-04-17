
#!/bin/bash

USERNAME='anonymous'
UMS_ID=0
TEMPLATE_PATH="../ldif/templates/criteo_users.template.ldif"

LOCALES=("fr-FR" "en-US" "zh-CN" "zh-TW")

display_usage() {
    echo "Usage: $0 <number>"
    echo "Generates specified number of LDAP user entries based on a predefined template."
    echo "  <number>: The number of user entries to generate."
}

select_random_locale() {
    local random_index=$((RANDOM % ${#LOCALES[@]}))
    echo "${LOCALES[random_index]}"
}

if [ $# -ne 1 ]; then
    display_usage
    exit 1
fi

TEMPLATE=$(cat "$TEMPLATE_PATH")

for ((i = 1; i <= $1; i++)); do
    RANDOM_PREFERRED_LANGUAGE=$(select_random_locale)
    entry=$(echo "$TEMPLATE" | sed -e "s/{{USERNAME}}/$USERNAME/g" -e "s/{{UMS_ID}}/$((UMS_ID + i))/g" -e "s/{{PREFERRED_LANGUAGE}}/$RANDOM_PREFERRED_LANGUAGE/g")
    echo "$entry"
    echo "" 
done

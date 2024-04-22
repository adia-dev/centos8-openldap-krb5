#!/bin/bash

# Default configuration
HOSTNAME="example.com"
PLATFORM="linux/amd64"
CONTAINER_NAME="centos-openldap-server"
IMAGE="centos-openldap-server"
DOCKERFILE="Dockerfile"
ENV_FILE=".env"
TYPE="server"
SHOULD_CONNECT=false
SHOULD_BUILD=false
DETACH=false
RETRY_INTERVAL=5
MAX_RETRIES=5
PORT_MAPPINGS=()

# Function to print usage instructions
print_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  --hostname HOSTNAME            Set the hostname for the container. Default: $HOSTNAME
  --platform PLATFORM            Set the platform for the container. Default: $PLATFORM
  --name NAME          Set the container name. Default: $CONTAINER_NAME
  --port PORT_MAPPING            Map container port to host, can be used multiple times for multiple ports.
  --connect                      Attempt to connect to a bash instance in the container after it is running.
  --detach                       Detach the container to run in the background.
  --build                        Build the container before running it.
  --client                       <client|server> run either a client or a server
  --help, -h                     Print this help message and exit.

Example:
  $0 --hostname mycustomhost.com --platform linux/arm64 --name my-ldap-client --volume-source ./custom-data/ --port 8080:80 --port 389:389 --connect

This script runs a Docker container with OpenLDAP and Kerberos configuration.
EOF
}

error_exit() {
    echo "Error: $1" >&2
    exit 1
}

warn() {
    echo "Warning: $1" >&2
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --hostname) HOSTNAME="$2"; shift ;;
        --platform) PLATFORM="$2"; shift ;;
        --name) CONTAINER_NAME="$2"; shift ;;
        --port) PORT_MAPPINGS+=("-p $2"); shift ;;
        --connect) SHOULD_CONNECT=true ;;
        --detach) DETACH=true ;;
        --client) 
            TYPE="client"
            CONTAINER_NAME="centos-openldap-client" 
            DOCKERFILE="client.Dockerfile"
            IMAGE="centos-openldap-client"
            ;;
        --build) SHOULD_BUILD=true ;;
        -h|--help) print_help; exit 0 ;;
        *) error_exit "Unknown parameter passed: $1" ;;
    esac
    shift
done

# Construct port mappings string
PORT_MAPPING_STR=$(IFS=" " ; echo "${PORT_MAPPINGS[*]}")

# Stop the container if it's already running
echo "Stopping container $CONTAINER_NAME..."
docker stop $CONTAINER_NAME >/dev/null 2>&1 || warn "Failed to stop container $CONTAINER_NAME."

if $SHOULD_BUILD; then
    echo "Building the container..."
    docker build -t $CONTAINER_NAME --platform=$PLATFORM . -f $DOCKERFILE >/dev/null || error_exit "Failed to build the container."
fi

echo "Starting container $CONTAINER_NAME..."
case $TYPE in
    "client") 
        docker run --rm \
            --detach=$DETACH \
            --platform="$PLATFORM" \
            --privileged=true \
            --env-file="$ENV_FILE" \
            --name "$CONTAINER_NAME" \
            --volume ./in:/in \
            --volume ./out:/out \
            "$IMAGE" >/dev/null || error_exit "Failed to start container $CONTAINER_NAME."
        ;;
    "server") 
        docker run --rm \
            --detach=$DETACH \
            -h "$HOSTNAME" \
            --platform="$PLATFORM" \
            --privileged=true \
            --env-file="$ENV_FILE" \
            --name "$CONTAINER_NAME" \
            --volume ./backup:/backup \
            --volume ./in:/in \
            --volume ./out:/out \
            ${PORT_MAPPING_STR} \
            "$IMAGE" >/dev/null || error_exit "Failed to start container $CONTAINER_NAME."
        ;;
    *) error_exit "Unknown type passed: $TYPE" ;;
esac

echo "Container $CONTAINER_NAME is starting..."

# Attempt to connect to container bash if requested
if $SHOULD_CONNECT; then
    echo "Attempting to connect to container's bash..."
    retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if docker exec "$CONTAINER_NAME" /bin/bash -c "echo 'Connection successful'" >/dev/null; then
            echo "Connected to container's bash."
            docker exec -it "$CONTAINER_NAME" /bin/bash
            exit 0
        else
            echo "Unable to connect, retrying in $RETRY_INTERVAL seconds..."
            ((retry_count++))
            sleep $RETRY_INTERVAL
        fi
    done
    
    echo "Failed to connect to the container after $MAX_RETRIES attempts."
    exit 1
fi

exit 0

#!/bin/bash

# Load credentials from external file
source "$(dirname "$0")/docker-creds.env"

# Variables
NAMESPACE="build"
SECRET_NAME="regcred"

# Load Docker credentials from external file
source "$(dirname "$0")/docker-creds.env"

kubectl create secret docker-registry $SECRET_NAME \
  --docker-server=$DOCKER_SERVER \
  --docker-username=$DOCKER_USERNAME \
  --docker-password=$DOCKER_PASSWORD \
  --docker-email=$DOCKER_EMAIL \
  -n $NAMESPACE

echo "✅ Docker registry secret '$SECRET_NAME' created in namespace '$NAMESPACE'"

#!/bin/bash

# Load credentials from external file
source "$(dirname "$0")/git-creds.env"

# Variables
NAMESPACE="cicd"
SECRET_NAME="git-credentials"

# Create secret
kubectl create secret generic $SECRET_NAME \
  --from-literal=username=$GIT_USERNAME \
  --from-literal=password=$GIT_TOKEN \
  -n $NAMESPACE

echo "✅ Git credentials secret '$SECRET_NAME' created in namespace '$NAMESPACE'"

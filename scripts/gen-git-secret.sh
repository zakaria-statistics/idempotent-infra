#!/bin/bash

# Load credentials from external file
source "$(dirname "$0")/git-creds.env"

NAMESPACE="build"
SECRET_NAME="git-credentials"

# Load Git credentials from external file
source "$(dirname "$0")/git-creds.env"

kubectl create secret generic $SECRET_NAME \
  --from-literal=username=$GIT_USERNAME \
  --from-literal=password=$GIT_TOKEN \
  -n $NAMESPACE

echo "✅ GitHub credentials secret '$SECRET_NAME' created in namespace '$NAMESPACE'"

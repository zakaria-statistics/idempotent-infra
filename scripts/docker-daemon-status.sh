#!/bin/bash

# Persist DOCKER_HOST for current user
if ! grep -q 'DOCKER_HOST' ~/.bashrc; then
  echo 'export DOCKER_HOST=tcp://localhost:32075' >> ~/.bashrc
  source ~/.bashrc
fi

echo "Waiting for docker-daemon pod to be in Running state (timeout: 15 minutes)..."

for ((i=0; i<900; i+=10)); do
  status=$(kubectl get pods -n cicd -l app=docker-daemon -o jsonpath="{.items[0].status.phase}" 2>/dev/null)
  if [ "$status" == "Running" ]; then
    echo "Docker daemon pod is running. Waiting for Docker to become ready..."
    docker info
    exit 0
  fi
  sleep 10
done

echo "Docker daemon pod not running after timeout. Continuing..."

#!/bin/bash

REPO_NAME=$1  # e.g., "myapp"
TAG=$2        # e.g., "v1.2"

# Loop through all deployments in all namespaces
kubectl get deployments --all-namespaces -o jsonpath="{range .items[*]}{.metadata.namespace}{' '}{.metadata.name}{'\n'}{end}" | while read namespace deploy; do
    # Find the container(s) using the specified image within the deployment
    containers=$(kubectl get deployment $deploy -n $namespace -o jsonpath="{.spec.template.spec.containers[?(@.image == \"$REPO_NAME:$TAG\")].name}")

    # If containers are found, update their image
    for container in $containers; do
        kubectl set image deployment/$deploy $container=$REPO_NAME:$TAG -n $namespace
    done
done
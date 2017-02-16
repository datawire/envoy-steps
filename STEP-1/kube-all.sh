#!/bin/sh

usage () {
    echo "Usage: $(basename $0) up|down" >&2
}

kubectl_foreach () {
    cmd="$1"
    type="$2"

    for dir in postgres user-service; do
        kubectl $cmd -f $dir/$type.yaml
    done
}

if [ -z "$1" ]; then
    usage
    exit 1
elif [ $1 == 'up' ]; then
    # Build Docker images
    docker build -t usersvc:step1 user-service

    # Create services
    kubectl_foreach create service

    # Create deployments
    kubectl_foreach create deployment
elif [ $1 == 'down' ]; then
    # Delete deployments
    kubectl_foreach delete deployment

    # Delete services
    kubectl_foreach delete service
else
    usage
    exit 1
fi

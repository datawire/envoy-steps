#!/bin/bash

set -e

DIR=$1

if [ -z "$DIR" ]; then
    echo "Usage: $(basename $0) dir" >&2
    exit 1
fi

if [ -f "${DIR}/build.sh" ]; then
    ( cd "${DIR}" && sh build.sh )
fi

kubectl create -f "${DIR}/deployment.yaml"
kubectl create -f "${DIR}/service.yaml"

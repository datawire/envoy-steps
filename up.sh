#!/bin/bash

set -ex

DIR=$1

if [ -n "$DIR" ]; then
    echo "Usage: $(basename $0) dir" >&2
    exit 1
fi

( cd "${DIR}" && sh build.sh )

kubectl create -f "${DIR}/deployment.yaml"
kubectl create -f "${DIR}/service.yaml"

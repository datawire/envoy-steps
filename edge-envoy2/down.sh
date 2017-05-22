#!/bin/bash

set -ex

DIR=$1

if [ -n "$DIR" ]; then
    echo "Usage: $(basename $0) dir" >&2
    exit 1
fi

kubectl delete -f "${DIR}/deployment.yaml"
kubectl delete -f "${DIR}/service.yaml"

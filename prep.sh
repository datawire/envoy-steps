#!/bin/sh

set -ex

REGISTRY="$1"

if [ "X$REGISTRY" = "X" ]; then
    echo "Usage: $(basename $0) registry-info" >&2
    exit 1
fi

if [ "$REGISTRY" = "-" ]; then
    REGISTRY=
fi

if [ $(echo $REGISTRY | egrep -c '/$') -eq 0 ]; then
    REGISTRY="$REGISTRY/"
fi

for file in $(find . -iname '*-template'); do
    new=$(echo $file | sed -e 's/-template$//')
    sed -e "s,{{REGISTRY}},$REGISTRY,g" < $file > $new
done

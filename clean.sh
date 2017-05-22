#!/bin/bash

set -e

for file in $(find . -iname '*-template'); do
    new=$(echo $file | sed -e 's/-template$//')
    rm -f "$new"
done

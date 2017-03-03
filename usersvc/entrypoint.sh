#!/bin/sh

python /application/service.py &
/usr/local/bin/envoy -c /application/envoy.json

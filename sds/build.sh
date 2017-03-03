DIR=$(dirname $0)

docker build -t usersvc-sds:step2 ${DIR}

if [ -n "$REGISTRY" ]; then
    docker tag usersvc-sds:step2 ${REGISTRY}/usersvc-sds:step2
    docker push ${REGISTRY}/usersvc-sds:step2
fi

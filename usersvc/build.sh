DIR=$(dirname $0)

docker build -t usersvc:step2 ${DIR}

if [ -n "$REGISTRY" ]; then
    docker tag usersvc:step2 ${REGISTRY}/usersvc:step2
    docker push ${REGISTRY}/usersvc:step2
fi

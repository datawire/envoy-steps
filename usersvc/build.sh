DIR=$(dirname $0)

docker build -t usersvc:step1 ${DIR}

if [ -n "$REGISTRY" ]; then
    docker tag usersvc:step1 ${REGISTRY}/usersvc:step1
    docker push ${REGISTRY}/usersvc:step1
fi

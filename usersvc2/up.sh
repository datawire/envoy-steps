DIR=$(dirname $0)

docker build -t usersvc:step2 ${DIR}

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

DIR=$(dirname $0)

docker build -t usersvc:step1 ${DIR}

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

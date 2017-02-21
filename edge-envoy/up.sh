DIR=$(dirname $0)

docker build -t edge-envoy:step2 ${DIR}

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

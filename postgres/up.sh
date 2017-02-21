DIR=$(dirname $0)

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

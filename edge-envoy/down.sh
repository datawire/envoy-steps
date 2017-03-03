DIR=$(dirname $0)

kubectl delete -f ${DIR}/deployment.yaml
kubectl delete -f ${DIR}/service.yaml

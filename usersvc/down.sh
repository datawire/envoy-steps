DIR=$(dirname $0)

kubectl delete -f ${DIR}/ingress.yaml
kubectl delete -f ${DIR}/service.yaml
kubectl delete -f ${DIR}/deployment.yaml

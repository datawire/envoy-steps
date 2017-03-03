DIR=$(dirname $0)

sh ${DIR}/build.sh

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

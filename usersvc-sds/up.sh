DIR=$(dirname $0)

docker build -t usersvc-sds:step2 ${DIR}
docker tag usersvc-sds:step1 dwflynn/usersvc-sds:step1
docker push dwflynn/usersvc-sds:step1

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

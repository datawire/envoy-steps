DIR=$(dirname $0)

docker build -t usersvc:step2 ${DIR}
docker tag usersvc:step2 dwflynn/usersvc:step2
docker push dwflynn/usersvc:step2

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

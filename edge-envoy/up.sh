DIR=$(dirname $0)

docker build -t edge-envoy:step2 ${DIR}
# docker tag edge-envoy:step2 dwflynn/edge-envoy:step2
# docker push dwflynn/edge-envoy:step2

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

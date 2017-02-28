DIR=$(dirname $0)

docker build -t edge-envoy:step3 ${DIR}
# docker tag edge-envoy:step3 dwflynn/edge-envoy:step3
# docker push dwflynn/edge-envoy:step3

kubectl create -f ${DIR}/deployment.yaml
kubectl create -f ${DIR}/service.yaml

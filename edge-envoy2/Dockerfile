FROM lyft/envoy:latest

RUN apt-get update && apt-get -q install -y \
    curl \
    dnsutils
COPY envoy.json /etc/envoy.json
CMD /usr/local/bin/envoy -c /etc/envoy.json

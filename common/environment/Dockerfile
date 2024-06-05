FROM hashicorp/consul-template:0.37.2 as consul-template
FROM vault:1.13.3
RUN apk add bash jq
COPY --from=consul-template /bin/consul-template /bin/consul-template
# What?

This repository helps you with end to end setup of commonly required services for any project in a quick way (< 1 hr) and at the same time provides you with a standard way to add new services specific to your project.

 Common services are as follows:

1. [Loki](https://github.com/grafana/loki) - database to store logs
2. [Prometheus](https://github.com/prometheus/prometheus) - time series database to store different metrics
3. [Minio](https://github.com/minio/minio) - s3 compatible object storage (e.g., it is used by loki to store old logs)
4. [Grafana](https://github.com/grafana/grafana) - data visualisation platform (e.g., logs can be viewed here)
5.  [Promtail](https://grafana.com/docs/loki/latest/send-data/promtail/) - used to push local logs to loki
6. [Cadvisor](https://github.com/google/cadvisor) - exposes container metrics
7. [Node Exporter](https://github.com/prometheus/node_exporter) - exposes node metrics
8. [Vault](https://github.com/hashicorp/vault) - used for secrets management
9. [Webhook Server](https://github.com/adnanh/webhook) - used to enable cd through an API
10. [Caddy](https://github.com/caddyserver/caddy) - used to expose services to end users
11. [Uptime](https://github.com/louislam/uptime-kuma) - used to monitor services

# Why?

In general every project requires observability, ci/cd pipelines, environment management, etc and these things don't change from project to project. This repository helps standardise setup of these so that separate effort on each project can be minimised.

## Developer Documentaion

1. [Onboarding a service](./docs/onboarding.md) 

## Useful Commands 

1. Deploy a newly added service or pull and redeploy a service

    `make deploy [services=<service_name>]`

3. Stop a service 

    `make stop [services=<service_name>]`

4. Restart a service 

    `make restart [services=<service_name>]`

5. Delete a service 

    `make down [services=<service_name>]`
    
    Note: Volumes are preserved
    
6. Pull images
    `make pull [services=<service_name>]`

7. Build images
    `make build [services=<service_name>]`

> [!NOTE]
>  Optional environment variable to tweak behaviour of Makefile:
> 1. `ENABLE_FORCE_RECREATE` (set this to 1 to enable force recreations of containers every time a service is deployed)
> 2. `DISABLE_ANSI` (set this to 1 to prevent ANSI output from Docker CLI)
> 3. `DISABLE_REMOVE_ORPHANS` (orphan containers are removed by default when your run `make deploy` without <service_name>, set this to 1 to disable this behaviour)
> 4. `DISABLE_PULL` (images are pulled/rebuilt by default (if you provide `<service_name>`, image for only that service is pulled/rebuilt) when you run `make deploy [services=<service_name>]`,  set this to 1 to disable this behaviour)
> 5. `<service_name>` accepts either one or multiple values separated by space

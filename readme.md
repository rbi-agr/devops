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

# Axibase Collector

## Overview

The [Axibase Collector](https://github.com/axibase/axibase-collector/blob/master/README.md) is a Java-based ETL application that queries external data sources on a defined schedule and uploads the data as series, properties, messages, and files into the [Axibase Time Series Database](http://axibase.com/products/axibase-time-series-database/) (ATSD).

## Image Summary

* Image name: `axibase/collector:latest`
* Base Image: Ubuntu 16.04
* [Dockerfile](https://github.com/axibase/docker-axibase-collector/blob/master/Dockerfile)
* [Docker Hub](https://hub.docker.com/r/axibase/collector/)

## Start Container

> Using Collector to monitor Docker? Launch container in privileged mode as described in this [document](https://github.com/axibase/axibase-collector/blob/master/jobs/docker.md#local-collection).

```properties
docker run \
 --detach \
 --publish-all \
 --restart=always \
 --name=axibase-collector \
 axibase/collector:latest
```

To automatically configure a connection to the Axibase Time Series Database, add the `-atsd-url` parameter containing the ATSD hostname and https port (default 8443), as well as [collector account](https://github.com/axibase/atsd/blob/master/administration/collector-account.md) credentials:

```properties
docker run \
 --detach \
 --publish-all \
 --restart=always \
 --name=axibase-collector \
 axibase/collector:latest \
  -atsd-url=https://collector-user:collector-password@atsd_host:atsd_https_port
```

If the user name or password contains a `$`, `&`, `#`, or `!` character, escape it with backslash `\`.

The password must contain at least **six** (6) characters and is subject to the following [requirements](https://github.com/axibase/atsd/blob/master/administration/user-authentication.md#password-requirements).

For example, for user `adm-dev` with the password `my$pwd` sending data to ATSD at https://10.102.0.6:8443, specify:

```properties
docker run \
 --detach \
 --publish-all \
 --restart=always \
 --name=axibase-collector \
 axibase/collector:latest \
  -atsd-url=https://adm-dev:my\$pwd@10.102.0.6:8443
```

## Check Installation

```
docker logs -f axibase-collector
```

It may take up to 5 minutes to initialize the database.

You should see 'start completed' message at the end of the log:

```
 * [Collector] Starting ...
 * [Collector] Waiting for Collector to start, pid=45 ...
 * [Collector] Checking Collector web-interface port 9443 ...
 * [Collector] Waiting for Collector to bind to port 9443 ...( 1 of 30 )
...
 * [Collector] Collector web interface:
 * [Collector] https://172.17.0.3:9443
 * [Collector] https://127.0.0.1:9443
 * [Collector] Collector start completed.
```

## Launch Parameters

| **Name** | **Required** | **Description** |
|:---|:---|:---|
|`--detach` | Yes | Run container in background and print container id. |
|`--name` | No | Assign a unique name to the container. |
|`--restart` | No | Auto-restart policy. _Not supported in all Docker Engine versions._ |
|`--publish-all` | No | Publish exposed https port (9443) to a random port. |

To bind the collector to a particular port instead of a random one, replace `--publish-all` with `--publish 10443:9443`, where the first number indicates an available port on the Docker host.

## Environment Variables

| **Name** | **Required** | **Description** |
|:---|:---|:---|
|`--env COLLECTOR_USER_NAME` | No | User name for a data collector account. |
|`--env COLLECTOR_USER_PASSWORD` | No | [Password](https://github.com/axibase/atsd-docs/blob/master/administration/user-authentication.md#password-requirements) for a data collector account.|
|`--env ATSD_URL` | No | URL for a connection to the Axibase Time Series Database.|

## Additional Parameters

* [Job Autostart](https://github.com/axibase/axibase-collector/blob/master/job-autostart.md)

## Troubleshooting

Review the following log files for any errors:

```sh
docker exec -it axibase-collector tail -n 100 /opt/axibase-collector/logs/axibase-collector.log
```

```sh
docker exec -it axibase-collector tail -n 100 /opt/axibase-collector/logs/err-collector.log
```

## Validation

```sh
docker ps | grep axibase-collector
```

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                     NAMES
ee15099d9f88        axibase/collector   "/bin/bash /opt/axiba"   33 seconds ago      Up 32 seconds       0.0.0.0:32768->9443/tcp   axibase-collector
```

Take note of the public https port assigned to axibase-collector container, i.e. **32768** in the example above.

## Login

Open https://docker_hostname:32768 in your browser and create an [administrator account](https://github.com/axibase/axibase-collector/blob/master/configure-administrator-account.md).

`docker_hostname` is the hostname or IP address of the Docker host and **32768** is the external port number assigned to the Collector container in the previous step.
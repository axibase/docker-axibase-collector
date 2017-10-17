% registry.connect.redhat.com/axibase/collector:17626
% Axibase Corporation
% October 17, 2017

# DESCRIPTION
Axibase Collector is a standalone Java application that collects statistics, properties, messages, and files from external data sources and uploads them into Axibase Time Series Database using its API. 

# USAGE
## Start Container

Execute the command as described above.

```properties
docker run \
 --detach \
 --publish 9443:9443 \
 --restart=always \
 --name=axibase-collector \
 registry.connect.redhat.com/axibase/collector:17626
```

To automatically configure a connection to the Axibase Time Series Database, add the `-atsd-url` parameter containing the ATSD hostname and https port (default 8443), as well as [collector account](https://github.com/axibase/atsd/blob/master/administration/collector-account.md) credentials:

```properties
docker run \
 --detach \
 --publish 9443:9443 \
 --restart=always \
 --name=axibase-collector \
 registry.connect.redhat.com/axibase/collector:17626 \
  -atsd-url=https://collector-user:collector-password@atsd_host:atsd_https_port
```

If the user name or password contains a `$`, `&`, `#`, or `!` character, escape it with backslash `\`.

The password must contain at least **six** (6) characters and is subject to the following [requirements](https://github.com/axibase/atsd/blob/master/administration/user-authentication.md#password-requirements).

For example, for user `adm-dev` with the password `my$pwd` sending data to ATSD at https://10.102.0.6:8443, specify:

```properties
docker run \
 --detach \
 --publish 9443:9443 \
 --restart=always \
 --name=axibase-collector \
 registry.connect.redhat.com/axibase/collector:17626 \
  -atsd-url=https://adm-dev:my\$pwd@10.102.0.6:8443
```


## Check Installation

It may take up to 5 minutes to initialize the application.

```sh
docker exec -it axibase-collector tail -f /opt/axibase-collector/logs/axibase-collector.log
```

Wait until the following message appears:

> _FrameworkServlet 'dispatcher': initialization completed._

This message indicates that the initial configuration is complete.

## Validation

```sh
docker ps | grep axibase-collector
```

```
CONTAINER ID        IMAGE                                                 COMMAND                  CREATED             STATUS              PORTS                    NAMES
e0056ff08b8a        registry.connect.redhat.com/axibase/collector:17626   "/bin/bash /opt/axiba"   7 minutes ago       Up 7 minutes        0.0.0.0:9443->9443/tcp   axibase-collector```

Take note of the public https port assigned to axibase-collector container, i.e. **32769** in the example above.

## Launch Parameters

**Name** | **Required** | **Description**
----- | ----- | -----
`--detach` | Yes | Run container in background and print container id.
`--publish-all` | No | Publish exposed https port (9443) to a random port.
`--restart` | No | Auto-restart policy. _Not supported in all Docker Engine versions._
`--name` | No | Assign a host-unique name to the container.

To bind the collector to a particular port instead of a random one, replace `--publish-all` with `--publish 10443:9443`, where the first number indicates an available port on the Docker host.

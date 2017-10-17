FROM registry.access.redhat.com/rhel7
MAINTAINER ATSD Developers <dev-atsd@axibase.com>

ENV version 17626
ENV LANG en_US.UTF-8
#metadata
LABEL com.axibase.vendor="Axibase Corporation" \
      com.axibase.product="Axibase Collector" \
      com.axibase.code="AC" \
      com.axibase.revision="${version}" \
      name="registry.connect.redhat.com/axibase/collector" \
      vendor="Axibase Corporation" \
      version="${version}" \
      release="5" \
      summary="Axibase Collector" \
      description="Axibase Collector is a standalone Java application that collects statistics, properties, messages, and files from external data sources and uploads them into Axibase Time Series Database using its API." \
      url="https://www.axibase.com" \
      run="docker run \
            --detach \
            --publish 9443:9443 \
            --restart=always \
            --name=axibase-collector \
            registry.connect.redhat.com/axibase/collector:${version}" \
      stop="docker stop axibase-collector" \
      io.k8s.display-name="Collector" \
      io.k8s.description="Axibase Collector" \
      io.openshift.expose-services="9443:https" \
      io.openshift.tags="Collector"

#entrypoint script
COPY entrypoint.sh preinit.sh /tmp/

COPY help.1 /
COPY licenses /licenses

#install jdk, wget, unzip, nano, iproute
RUN REPOLIST=rhel-7-server-rpms &&\
    yum -y update-minimal --security --sec-severity=Important --sec-severity=Critical --setopt=tsflags=nodocs \
    && yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs postfix java-1.8.0-openjdk wget unzip nano iproute \
    && yum clean all
#install collector
RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz

#explode (unpack) war file to speed up inital startup
RUN mkdir -p /opt/axibase-collector/exploded/webapp \
    && unzip /opt/axibase-collector/lib/axibase-collector.war -d /opt/axibase-collector/exploded/webapp \
    && mv /tmp/entrypoint.sh /opt/axibase-collector/bin/ \
    && /tmp/preinit.sh

#comment cron for rhel because of required root privileges for it
RUN sed '68,75 {s/^/#/}' /opt/axibase-collector/bin/entrypoint.sh > newFile && mv newFile /opt/axibase-collector/bin/entrypoint.sh

#expose UI https port
EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/entrypoint.sh"]

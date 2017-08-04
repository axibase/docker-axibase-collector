FROM ubuntu:16.04
MAINTAINER ATSD Developers <dev-atsd@axibase.com>
ENV version 16943
ENV LANG en_US.UTF-8
#metadata
LABEL com.axibase.vendor="Axibase Corporation" \
    com.axibase.product="Axibase Collector" \
    com.axibase.code="AC" \
    com.axibase.revision="${version}"

#install jre, install cron
RUN apt-get update && apt-get install --no-install-recommends -y postfix openjdk-8-jre wget unzip cron nano \
    && rm -rf /var/lib/apt/lists/*

#install collector
RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz

#explode (unpack) war file to speed up inital startup
RUN mkdir -p /opt/axibase-collector/exploded/webapp \
    && unzip /opt/axibase-collector/lib/axibase-collector.war -d /opt/axibase-collector/exploded/webapp

#expose UI https port
EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/entrypoint.sh"]


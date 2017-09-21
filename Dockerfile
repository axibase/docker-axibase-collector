FROM ubuntu:16.04
ENV version=17407 LANG=en_US.UTF-8
#metadata
LABEL maintainer="ATSD Developers <dev-atsd@axibase.com>" \
    com.axibase.vendor="Axibase Corporation" \
    com.axibase.product="Axibase Collector" \
    com.axibase.code="AC" \
    com.axibase.revision="${version}"

#entrypoint script
COPY entrypoint.sh /tmp/entrypoint.sh

#install jre, cron, collector, explode (unpack) war file to speed up inital startup
RUN apt-get update && apt-get install --no-install-recommends -y postfix openjdk-8-jre wget unzip cron nano net-tools \
    && rm -rf /var/lib/apt/lists/* \
    && wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz \
    && mkdir -p /opt/axibase-collector/exploded/webapp \
    && unzip /opt/axibase-collector/lib/axibase-collector.war -d /opt/axibase-collector/exploded/webapp \
    && mv /tmp/entrypoint.sh /opt/axibase-collector/bin/

#expose UI https port
EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/entrypoint.sh"]


FROM java:openjdk-8-jre-alpine
ENV version=19576 LANG=en_US.UTF-8
#metadata
LABEL maintainer="ATSD Developers <dev-atsd@axibase.com>" \
    com.axibase.vendor="Axibase Corporation" \
    com.axibase.product="Axibase Collector" \
    com.axibase.code="AC" \
    com.axibase.revision="${version}"

#entrypoint script
COPY entrypoint.sh preinit.sh /tmp/

#install jre, cron, collector, explode (unpack) war file to speed up inital startup
RUN apk update && apk add wget bash dcron coreutils iproute2 && mkdir /opt
    
RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz \
    && mv /tmp/entrypoint.sh /opt/axibase-collector/bin/ \
    && /tmp/preinit.sh

RUN apk del wget && rm -rf /var/cache/apk/*

#expose UI https port
EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/entrypoint.sh"]

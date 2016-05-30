FROM ubuntu:14.04
MAINTAINER ATSD Developers <dev-atsd@axibase.com>
ENV version 13266
#metadata
LABEL com.axibase.vendor="Axibase Corporation" \
    com.axibase.product="Axibase Collector" \
    com.axibase.code="AC" \
    com.axibase.revision="${version}"

#configure system 
RUN apt-get update && apt-get install -y openjdk-7-jdk wget;

#install collector
RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz


EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/entrypoint.sh"]



FROM ubuntu:14.04
MAINTAINER ATSD Developers <dev-atsd@axibase.com>
ENV version 12500

#configure users
RUN adduser --disabled-password --quiet --gecos "" axibase && apt-get update && apt-get install -y openjdk-7-jre;


RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz

RUN chmod +x /opt/axibase-collector/bin/start_container.sh &&\
    chown -R axibase /opt/axibase-collector

EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/start_container.sh"]



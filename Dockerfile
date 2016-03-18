FROM java:openjdk-7-jre
MAINTAINER ATSD Developers <dev-atsd@axibase.com>
ENV version 12482

#configure users
RUN adduser --disabled-password --quiet --gecos "" axibase;


RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/

RUN chmod +x /opt/axibase-collector/bin/start_container.sh &&\
    chown -R axibase /opt/axibase-collector

EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/start_container.sh"]



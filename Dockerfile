FROM ubuntu:14.04
MAINTAINER ATSD Developers <dev-atsd@axibase.com>
ENV version 15177
#metadata
LABEL com.axibase.vendor="Axibase Corporation" \
    com.axibase.product="Axibase Collector" \
    com.axibase.code="AC" \
    com.axibase.revision="${version}"

#configure system 
RUN apt-get update && apt-get install -y openjdk-7-jdk wget && touch /etc/cron.d/root \
    && printf "# An empty line is required at the end of this file for a valid cron file\n" > /etc/cron.d/root \
    && chmod 0644 /etc/cron.d/root && crontab /etc/cron.d/root;

# run cron on startup
CMD cron -f &;

#install collector
RUN wget https://www.axibase.com/public/axibase-collector-v${version}.tar.gz \
    && tar -xzvf axibase-collector-*.tar.gz -C /opt/ && rm axibase-collector-*.tar.gz

#expose warfile
RUN mkdir -p /opt/axibase-collector/exploded/webapp \
    && cd /opt/axibase-collector/exploded/webapp && jar -xvf ../../lib/axibase-collector.war

EXPOSE 9443

VOLUME ["/opt/axibase-collector"]

ENTRYPOINT ["/bin/bash","/opt/axibase-collector/bin/entrypoint.sh"]



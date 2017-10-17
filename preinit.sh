#!/usr/bin/env bash

COLLECTOR_HOME=/opt/axibase-collector

# Start Collector to create Derby tables
${COLLECTOR_HOME}/bin/start-collector.sh
${COLLECTOR_HOME}/bin/stop-collector.sh

# Remove logs and keystore
rm -rfv ${COLLECTOR_HOME}/logs ${COLLECTOR_HOME}conf/keystores/client.keystore

# Download Derby to get ij tool
DERBY_DOWNLOAD_LINK='http://mirror.linux-ia64.org/apache/db/derby/db-derby-10.12.1.1/db-derby-10.12.1.1-lib.zip'
wget -O /tmp/derby.zip "${DERBY_DOWNLOAD_LINK}"

# Cleanup tables
unzip /tmp/derby.zip -d /tmp
cat <<EOF >/tmp/cleanup_tables.sql
--connect to the local database
CONNECT 'jdbc:derby:/opt/axibase-collector/acdb';
--delete link to default atsd
UPDATE JOB_CONFIG SET ATSD_CONFIGURATION=NULL;
--delete pool for default atsd
DELETE FROM CONNECTION_POOL WHERE ID IN (SELECT CONNECTION_POOL_CONFIG FROM ATSD_CONFIGURATION);
--delete default atsd
DELETE FROM ATSD_CONFIGURATION;
EXIT;
EOF

DERBY_LIB='/tmp/db-derby-10.12.1.1-lib/lib'
export CLASSPATH="${DERBY_LIB}/derby.jar:${DERBY_LIB}/derbytools.jar"
java org.apache.derby.tools.ij /tmp/cleanup_tables.sql

# Remove temporary files
rm $(readlink -f "${BASH_SOURCE[0]}")
rm -rfv /tmp/*

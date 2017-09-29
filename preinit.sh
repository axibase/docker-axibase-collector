#!/usr/bin/env bash

# Start Collector to create Derby tables
/opt/axibase-collector/bin/start-collector.sh
/opt/axibase-collector/bin/stop-collector.sh

# Remove logs and keystore
rm -rfv /opt/axibase-collector/logs /opt/axibase-collector/conf/keystores/client.keystore

# Download Derby to get ij tool
DERBY_DOWNLOAD_LINK='http://mirror.linux-ia64.org/apache/db/derby/db-derby-10.12.1.1/db-derby-10.12.1.1-lib.zip'
wget "${DERBY_DOWNLOAD_LINK}" -O /tmp/derby.zip

# Cleanup tables
cd /tmp
unzip /tmp/derby.zip
cat <<EOF >/tmp/cleanup_tables.sql
--connect to the local database
CONNECT 'jdbc:derby:/opt/axibase-collector/acdb';
--delete link to default ptsd
UPDATE JOB_CONFIG SET ATSD_CONFIGURATION=NULL;
--delete pool for default atsd
DELETE FROM CONNECTION_POOL WHERE ID IN (SELECT CONNECTION_POOL_CONFIG FROM ATSD_CONFIGURATION);
--delete default atsd
DELETE FROM ATSD_CONFIGURATION;
EOF

export CLASSPATH='/tmp/db-derby-10.12.1.1-lib/lib/derby.jar:/tmp/db-derby-10.12.1.1-lib/lib/derbytools.jar'
java org.apache.derby.tools.ij /tmp/cleanup_tables.sql

# Remove temporary files
rm -rvf /tmp/derby* /tmp/db-derby*
rm $(readlink -f "${BASH_SOURCE[0]}")

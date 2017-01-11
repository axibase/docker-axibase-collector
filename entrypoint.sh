#!/bin/sh

SCRIPT=$(readlink -f $0)
SCRIPTS_HOME="`dirname $SCRIPT`"
executing="true"

owner=`stat -c %U "${SCRIPTS_HOME}"`
if [ $# -eq 0 ];  then
    args="${COLLECTOR_ARGS}"
else
    args="$@"
fi

if [ `whoami` != "$owner" ]; then
    echo "Current user: `whoami`. Expecting user: $owner. User mismatch, switching user to $owner."
    su -c "$SCRIPT $args" "$owner"
    exit $?
fi

cd ${SCRIPTS_HOME}
echo "Starting services ..."
#Create empty cron job
touch /etc/cron.d/root
chmod +x /etc/cron.d/root
printf "# Empty line\n" >> /etc/cron.d/root
crontab /etc/cron.d/root
#Enable system logging
rsyslogd
#Start cron
cron -f &
./start-collector.sh "$args"

while [ "$executing" = "true" ]; do
    sleep 1
    #trap 'echo "kill signal handled, stopping processes ..."; executing="false"' SIGINT SIGTERM
done
#echo "SIGTERM handled ( docker stop ). Stopping services ..."
#./stop-collector.sh
#exit 0

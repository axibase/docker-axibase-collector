#!/bin/sh

SCRIPT=$(readlink -f $0)
SCRIPTS_HOME="`dirname $SCRIPT`"
STOP_SIGNAL="-1"
executing="true"

owner=`stat -c %U "${SCRIPTS_HOME}"`
if [ $# -eq 0 ];  then
    args="${COLLECTOR_ARGS}"
else
    args="$@"
fi

if [ `whoami` != "$owner" ]; then
    echo "Current user: `whoami`. Installation user: $owner. Switching user to $owner."
    su -c "$SCRIPT $args" "$owner"
    exit $?
fi

cd ${SCRIPTS_HOME}
echo "Starting Axibase Collector ..."

for i in $args; do
    case $i in
        -atsd-host=*)
        ATSD_HOST="${i#*=}"
        shift
        ;;
        -atsd-url=*)
        ATSD_URL="${i#*=}"
        shift
        ;;
        *)
        # other options
        ;;
    esac
done

error="false"
function validate_hostname {
    if [[ $1 == *"_"* ]]; then
        echo "Error: Hostname in '$2' is not valid (contains an underscore)."
        error="true"
    fi
}

function validate_password {
    if [[ ${#1} -lt 6 ]]; then
        echo "Error: Password in '$2' contains less than 6 characters."
        error="true"
    fi
}

validate_hostname ${ATSD_HOST} "-atsd-host"

URL_PATTERN="^(http[s]?|unix):\/\/(.*):(.*)@([^:\/[:space:]]+)(:([[:digit:]]+))?((\/[A-Za-z0-9_\-]*)*)\$"
if [[ ${ATSD_URL} =~ $URL_PATTERN ]]; then
    validate_password ${BASH_REMATCH[3]} "-atsd-url"
    validate_hostname ${BASH_REMATCH[4]} "-atsd-url"
fi

if [ "$error" = "true" ]; then
    echo "Axibase Collector failed to start"
    exit 0
fi

#Create empty cron job
touch /etc/cron.d/root
chmod +x /etc/cron.d/root
printf "# Empty line\n" >> /etc/cron.d/root
crontab /etc/cron.d/root

#Start cron
cron -f &

#Start collector
./start-collector.sh "$args"

#Waiting for stop signal
trap 'executing="false"' SIGTERM
while [ "$executing" = "true" ]; do
    sleep 1
done

#Stop collector
echo "Stopping Axibase Collector ..."
./stop-collector.sh "$STOP_SIGNAL"
exit 0

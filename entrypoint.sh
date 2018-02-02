#!/bin/sh

SCRIPT=$(readlink -f $0)
SCRIPTS_HOME="`dirname $SCRIPT`"
STOP_SIGNAL="-1"

USERINFO_CHARS_REGEX="[[:alnum:]%\._~!\$'()*+,;=-]"
USERINFO_FIELD_REGEX="($USERINFO_CHARS_REGEX+)(:$USERINFO_CHARS_REGEX+)?@"
IPV6_REGEX="[0-9a-fA-F:]+"
AUTHORITY_ALL_CHARS_REGEX="^:\/[:space:]@"
AUTHORITY_REGEX="(\[($IPV6_REGEX)\]|(($USERINFO_FIELD_REGEX)?([$AUTHORITY_ALL_CHARS_REGEX]+)))(:([[:digit:]]*))?(.*)?\$"

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
        -atsd-tcp-host=*)
        ATSD_TCP_HOST="${i#*=}"
        shift
        ;;
        -atsd-tcp-port=*)
        ATSD_TCP_PORT="${i#*=}"
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

function print_error {
    echo "Error: $1"
}

function validate_hostname {
    if [[ -z "$1" ]]; then
        print_error "host is null in the $2"
        exit 1
    fi
    HOST_REGEX="^[[:alnum:]\.\-]+\$"
    if ! [[ $1 =~ $HOST_REGEX ]]; then
        print_error "invalid hostname '$1' in the $2"
        exit 1
    fi
    validate_ipv4 "$1" "$2"
}

function validate_ipv4 {
    IP_REGEX="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\$"
    if [[ $1 =~ $IP_REGEX ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($1)
        IFS=$OIFS
        if ! [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]; then
            print_error "invalid ipv4 address '$1' in the $2"
            exit 1
        fi
    fi
}

function validate_ipv6 {
    IP_REGEX="^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}\$"
    if ! [[ $1 =~ $IP_REGEX ]]; then
        print_error "invalid ipv6 address '$1' in the $2"
        exit 1
    fi
}

function validate_port {
    if [[ -z "$1" ]]; then
        if [[ "$3" == ":" ]]; then
            print_error "invalid port for authority '$4' in the $2"
            exit 1
        fi
        return
    fi
    PORT_REGEX="^[[:digit:]]{1,5}\$"
    if [[ $1 =~ $PORT_REGEX ]]; then
        if [[ "$1" -le 65535 ]]; then
            return
        fi
    fi
    print_error "invalid port '$1' in the $2"
    exit 1
}

function validate_password {
    if [[ ${#1} -lt 6 ]]; then
        print_error "password contains less than 6 characters in the $2"
        exit 1
    fi
}

function validate_scheme {
    SCHEME_REGEX="^http[s]?\$"
    scheme=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    if ! [[ $scheme =~ $SCHEME_REGEX ]]; then
        print_error "invalid scheme '$1' in the url '$2'"
        exit 1
    fi
}

function validate_userinfo {
    if [[ -z "$1" ]]; then
        return
    fi
    USERINFO_REGEX="^($USERINFO_CHARS_REGEX+)(:($USERINFO_CHARS_REGEX+))?@\$"
    if [[ $1 =~ $USERINFO_REGEX ]]; then
        user="${BASH_REMATCH[1]}"
        password="${BASH_REMATCH[3]}"
        if [[ -z "$password" ]]; then
            print_error "no user password in the url '$2'"
            exit 1
        fi
        validate_password "$password" "url '$2'"
    else
        print_error "invalid userinfo in the url '$2'"
        exit 1
    fi
}

function validate_authority {
    if [[ $1 =~ $AUTHORITY_REGEX ]]; then
        ipv6="${BASH_REMATCH[2]}"
        userinfo="${BASH_REMATCH[4]}"
        host="${BASH_REMATCH[7]}"
        portGroup="${BASH_REMATCH[8]}"
        port="${BASH_REMATCH[9]}"
        path="${BASH_REMATCH[10]}"
        if [[ -z "$ipv6" ]]; then
            validate_userinfo "$userinfo" $2
            validate_hostname "$host" "url '$2'"
            validate_port "$port" "url '$2'" "$portGroup" $1
            validate_path "$path" $2
        else
            validate_ipv6 "$ipv6" $2
            validate_port "$port" "url '$2'" "$portGroup" $1
        fi
    else
        print_error "invalid authority in the '$2'"
        exit 1
    fi
}

function validate_path {
    if [[ -z "$1" ]]; then
        return
    fi
    PATH_REGEX="^/[[:alnum:]\-:@&?=+,.!/~*'%\$_;\(\)]*\$"
    if ! [[ $1 =~ $PATH_REGEX ]]; then
        print_error "invalid path in the '$2'"
        exit 1
    fi
}

function validate_url {
    URL_REGEX="^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?\$"
    if [[ $1 =~ $URL_REGEX ]]; then
        scheme=${BASH_REMATCH[2]}
        authority="${BASH_REMATCH[4]}"
        path="${BASH_REMATCH[5]}"
        if [[ -z "$scheme" ]] || [[ -z "$authority" ]]; then
            print_error "invalid url '$1'"
            exit 1
    fi
        validate_scheme "$scheme" $1
        validate_authority "$authority" $1
    else
        print_error "invalid url '$1'"
        exit 1
    fi
}

function validate_docker_socket {
    echo -n "Checking docker socket..."
    check_res=`java -classpath "../exploded/webapp/WEB-INF/classes:../exploded/webapp/WEB-INF/lib/*" com.axibase.collector.util.UnixSocketUtil /var/run/docker.sock 2>&1`;
    if ! [[ -z "$check_res" ]]; then
        if [ "$check_res" == "OK" ]; then
            echo "OK"
        elif [[ "$check_res" == "FAILED"* ]]; then
            echo "$check_res"
        elif [[ "$check_res" == "Unable to read"* ]]; then
            echo
            print_error "$check_res"
            exit 1
        else
            echo
            echo "$check_res"
        fi
    fi
}

if [ -e "/var/run/docker.sock" ]; then
    validate_docker_socket
fi

if ! [[ -z "$ATSD_URL" ]]; then
    validate_url "$ATSD_URL"
fi

if ! [[ -z "$ATSD_TCP_HOST" ]]; then
    validate_hostname "$ATSD_TCP_HOST" "arg '-atsd-tcp-host'"
fi

if ! [[ -z "$ATSD_TCP_PORT" ]]; then
    validate_port "$ATSD_TCP_PORT" "arg '-atsd-tcp-port'"
fi

if ! [[ -z "$COLLECTOR_USER_PASSWORD" ]]; then
    validate_password "$COLLECTOR_USER_PASSWORD" "env 'COLLECTOR_USER_PASSWORD'"
fi

if ! [[ -z "$ATSD_SERVICE_HOST" ]]; then
    validate_hostname "$ATSD_SERVICE_HOST" "env 'ATSD_SERVICE_HOST'"
fi

if ! [[ -z "$ATSD_SERVICE_PORT_HTTPS" ]]; then
    validate_port "$ATSD_SERVICE_PORT_HTTPS" "env 'ATSD_SERVICE_PORT_HTTPS'"
fi

if ! [[ -z "$ATSD_SERVICE_PORT_TCP" ]]; then
    validate_port "$ATSD_SERVICE_PORT_TCP" "env 'ATSD_SERVICE_PORT_TCP'"
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

#/bin/sh

#
# Config
#
BASE_URL="http://169.254.169.254/latest/meta-data/"
AZ_URL="${BASE_URL}placement/availability-zone"
REGION=$(curl -s $AZ_URL | sed -e 's/.$//')

#
# Options
#
exit_usage() {
    echo "Usage: entrypoint.sh [-h|--help] [--cpu 10] [--command 'yes > /dev/null']"
    exit 1
}

OPTSHORT="h"
OPTLONG="help,cpu:,command:"
GETOPT=`getopt -q -o $OPTSHORT -l $OPTLONG -- "$@"`
[ $? != 0 ] && exit_usage
eval set -- "$GETOPT"

while true
do
    case $1 in
        -h|--help) exit_usage ;;
        --cpu)     CPU=$2;     shift 2;;
        --command) COMMAND=$2; shift 2;;
        --) shift; break ;;
        *)  exit_usage ;;
    esac
done

#
# Loading cpu usage to N%
#
echo "Cheking CPU option."
if [ ! -z "$CPU" ]; then
    TIMEOUT=$(echo "scale=2; $CPU / 100" | bc)
    SLEEP=$(echo "scale=2; 1.0 - $TIMEOUT" | bc)

    echo "Starting CPU check."
    echo "Specified CPU Usage is $CPU, timeout is $TIMEOUT, SLEEP is $SLEEP"
    while true;
    do
        timeout ${TIMEOUT} yes > /dev/null
        sleep $SLEEP
    done &
fi

#
# Additional Command
#
echo "Checking COMMAND option."
if [ ! -z "$COMMAND" ]; then
    echo "Starting COMMAND ($COMMAND)"
    ${COMMAND} &
fi

#
# Environment
#
echo "Getting environment variables."
ENV=${ENV:-None}
SSM_PREFIX="/app/$ENV/"
SSM_QUERY='.Parameters| .[] | "export " + .Name + "=" + .Value'

if [ "$ENV" != "None" ]; then
    echo "Starting command aws ssm, and exporting envs."
    $(aws ssm get-parameters-by-path --with-decryption --path "${SSM_PREFIX}" --region "${REGION}" \
    | jq -r "${SSM_QUERY}" \
    | sed -e "s~${SSM_PREFIX}~~")
fi

#
# Daemons
#
echo "Starting daemons."
nginx -c /etc/nginx/nginx.conf
bundle exec unicorn -c config/unicorn.rb

tail -f /dev/null

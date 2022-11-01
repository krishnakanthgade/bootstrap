#!/bin/bash

touch /var/log/bootstap-output.log

get_agent_status()
{
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - >> /var/log/bootstap-output.log 
    echo "$(date) : Checking $1 agent status..." >> /var/log/bootstap-output.log
    AGENT_STATUS=$(systemctl is-active $1)
    if [ "$AGENT_STATUS" == "active" ]; then
        echo "$(date) : Status check completed agent $1 is active" >> /var/log/bootstap-output.log
	echo "$(date) : Service Status:" >> /var/log/bootstap-output.log
	echo "$(systemctl status $1)" >> /var/log/bootstap-output.log
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - >> /var/log/bootstap-output.log

    else
        echo "$(date) : Status check completed agent $1 is in $agent_status state"
	echo "$(date) : Service Status:" >> /var/log/bootstap-output.log
        echo $(systemctl status $1) >> /var/log/bootstap-output.log
        printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - >> /var/log/bootstap-output.log
   fi
}

validate_id()
{
    if [ "$1" == "cid" ]; then
        HEX_TYPE=$(/opt/CrowdStrike/falconctl -g -cid | awk -F "=" '{gsub(/"/, "", $2); print $1}')
        HEX=$(/opt/CrowdStrike/falconctl -g -cid | awk -F "=" '{gsub(/"/, "", $2); print $2}')
    elif [ "$1" == "aid" ]; then
        HEX_TYPE=$(/opt/CrowdStrike/falconctl -g -aid | awk -F "=" '{gsub(/"/, "", $2); print $1}')
        HEX=$(/opt/CrowdStrike/falconctl -g -cid | awk -F "=" '{gsub(/"/, "", $2); print $2}')
    fi
    HEX=$(cat test | awk -F "=" '{gsub(/"/, "", $2); print $2}')
    echo "Validating $HEX_TYPE..." >> /var/log/bootstap-output.log
    if [ "$HEX_COUNT" == '17' ]; then
        if ! [[ $HEX =~ ^[0-9A-Fa-f]{1,}$ ]] ; then
            echo "Invalid $HEX_TYPE returned" >> /var/log/bootstap-output.log
        else
            echo "Valid $HEX_TYPE returned" >> /var/log/bootstap-output.log
        fi
   else
       echo "$HEX_TYPE invalid character count" >> /var/log/bootstap-output.log
   fi
}

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - > /var/log/bootstap-output.log
echo "\n\n$(date) : Qualys agent status check starting..." >> /var/log/bootstap-output.log
get_agent_status qualys-cloud-agent

echo "\n\n $(date) Qualys endpoint rechability check starting..." >> /var/log/bootstap-output.log
QUALYS_CURL_OUTPUT=$(curl -s -o /dev/null -w "%{http_code}" https://qagpublic.nam.nsroot.net/CloudAgent)
if ["$QUALYS_CURL_OUTPUT" == "200"]; then
    echo "$(date) : Qualys endpoint curl returned 200 response code" >> /var/log/bootstap-output.log
else
    echo "$(date) : Qualys endpoint curl returned $qualys_curlt_output reponse code" >> /var/log/bootstap-output.log 
fi

echo "\n\n$(date) : Tanium agent status check starting..." >> /var/log/bootstap-output.log
get_agent_status taniumclient

echo "\n\n$(date) : Falcon agent status check starting..." >> /var/log/bootstap-output.log
get_agent_status falcon-sensor

validate_id cid
validate_id aid

echo "Checking falcon rfm state..."
LOOP_COUNT=4
while [ $LOOP_COUNT -gt 0 ]
do
    FALCON_RFM_STATE=$(opt/CrowdStrike/ falconctl -g –rfm-state)
    if [ "$FALCON_RFM_STATE" == "true" ]; then
        echo "Falcon rfm state is true. The program will sleep for 20 minute and recheck the state" >> /var/log/bootstap-output.log
        sleep 20m
        LOOP_COUNT=$((LOOP_COUNT-1))
        echo echo "Checking falcon rfm state..." >> /var/log/bootstap-output.log
        echo $LOOP_COUNT
    else
       echo "Falcon rfm state is false" >> /var/log/bootstap-output.log
       LOOP_COUNT=0
    fi
done

echo "Checkin falcon agent conection status..." >> /var/log/bootstap-output.log
sudo netstat -tapn | grep ssm-agent-work | grep "ESTABLISHED" >>
if [ "$?" == "0" ]; then
        echo "Falcon agent have established connection" >> /var/log/bootstap-output.log
else
        echo "Falcon agent failed to establish connection" >> /var/log/bootstap-output.log
fi

printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - > /var/log/bootstap-output.log
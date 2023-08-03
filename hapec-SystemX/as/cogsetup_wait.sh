#!/bin/sh
set +e

echo -e "Starting System X Analytic Server container \033[36m[executing]\033[0m"

echo -e "Starting System X Analytic Server container logging \033[36m[executing]\033[0m"
[ ! -d "${SYSTEMX_ANALYTICSERVER_PATH}/logs" ] && mkdir "${SYSTEMX_ANALYTICSERVER_PATH}/logs"
[ ! -d "${SYSTEMX_ANALYTICSERVER_PATH}/logs/cognosserver.log" ] && touch "${SYSTEMX_ANALYTICSERVER_PATH}/logs/tm1_messages.log"
[ ! -d "/TM1Servers/hapecAnalyticServer/logs/tm1server.log" ] && touch "/TM1Servers/hapecAnalyticServer/logs/tm1server.log"

#container background Task
tail -f -n 0 ${SYSTEMX_ANALYTICSERVER_PATH}/logs/tm1_messages.log | stdbuf --output=L awk '
  function removeWhiteSpace(str) {
    gsub(/[[:space:]]{3,}/, "   ", str);
    return str;
  }

  $2 ~ /INFO/ {
    print "\033[33mAnalytic Server:\033[0m \033[37m" removeWhiteSpace($0) "\033[0m";
    next;
  }

  $2 ~ /ERROR/ {
    print "\033[33mAnalytic Server:\033[0m \033[31m" removeWhiteSpace($0) "\033[0m";
    next;
  }

  {
    print "\033[33mAnalytic Server:\033[0m", removeWhiteSpace($0);
  }
' &
SystemXLoggerPID=$!

tail -f -n 0 /TM1Servers/hapecAnalyticServer/logs/tm1server.log | stdbuf --output=L awk '
function removeWhiteSpace(str) {
    gsub(/[[:space:]]{3,}/, "   ", str);
    return str;
}

{
    print "\033[35mhapecAnalyticServer:\033[0m", removeWhiteSpace($0);
}
' &

echo -e "Starting System X Analytic Server container logging \033[32m[done]\033[0m"

echo -e "Configuring System X Analytic Server according to container environment \033[36m[executing]\033[0m"

# Set SYSTEMX_RS_STARTUP to true if it is unset or null
SYSTEMX_AS_STARTUP=${SYSTEMX_AS_STARTUP:-true}

### CHECK vm.max_map_count HERE!!!! ###
sysctl vm.max_map_count

echo -e "Backup System X Analytic Server configuration \033[36m[executing]\033[0m"
cp ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup.xml \
   ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_backup_$(date +'%Y%m%d_%H%M%S').xml
echo -e "Backup System X Analytic Server configuration \033[32m[done]\033[0m"

# Check if the template file exists
if [ -e "${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_template.xml" ]; then
    echo -e "Performing initial System X Reporting Server configuration according to docker image \033[36m[executing]\033[0m"

	cp ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_template.xml ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_image_template.xml

	# configure pmpExternalURI
	xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='pmpService']/crn:value/crn:parameter[@name='pmpExternalURI']/crn:value" -v "http://${SYSTEMX_AS_IPV4_ADDRESS}:9510" ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_template.xml

	mv ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_template.xml ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup.xml

	echo -e "Initial System X Reporting Server configuration according to docker image \033[32m[done]\033[0m"
else
    echo -e "Initial System X Reporting Server configuration according to docker image \033[32m[done]\033[0m"
fi


echo -e "Configuring System X Analytic Server according to container environment \033[32m[done]\033[0m"

if [ $SYSTEMX_AS_STARTUP = true ]; then

	retriesLeft=${COGNOS_MAX_RETRIES}
	CONFIG_STATUS=3
	while [ $retriesLeft -gt 0 -a $CONFIG_STATUS -ne 0 ]; do
		echo -e "Starting System X Analytic Server - retries left: " ${retiresLeft} " \033[36m[executing]\033[0m"


		cd ${SYSTEMX_ANALYTICSERVER_PATH}/bin64
		./cogconfig.sh -s
		CONFIG_STATUS=$?
		echo -e "\nSystem X Analytic Server configuration status: ${CONFIG_STATUS}"
		if [ $CONFIG_STATUS -ne 0 ]; then
			cat ${SYSTEMX_ANALYTICSERVER_PATH}/logs/cogconfig_response.csv | awk '
			/INFO/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
			/SUCCESS/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
			/WARNING/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
			/ERROR/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
			/EXEC/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
			!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mAnalytic Server Configuration:\033[0m",$0}'
		fi

		retriesLeft=$(( $retriesLeft - 1 ))

	done

	if [ $CONFIG_STATUS -eq 0 ]; then
		
		cat ${SYSTEMX_ANALYTICSERVER_PATH}/logs/cogconfig_response.csv | awk '
			/INFO/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
			/SUCCESS/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
			/WARNING/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
			/ERROR/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
			/EXEC/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
			!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mAnalytic Server Configuration:\033[0m",$0}'

	else
		echo -e "Starting System X Analytic Server - too many retries \033[31m[failed]\033[0m"
		kill -TERM "$SystemXLoggerPID" 2>/dev/null
	fi

else
	echo -e "Starting System X Analytic Server - disabled by SYSTEMX_AS_NOSTARTUP \033[33m[skipped]\033[0m"
fi  

echo -e "Preparing System X Analytic Server container SIGTERM handling \033[36m[executing]\033[0m"
# Prepare for SIGTERM
#Define cleanup procedure
term_handler() {
    echo -e "\nStopping System X Analytic Server - recieved SIGTERM \033[36m[executing]\033[0m"

	cd ${SYSTEMX_ANALYTICSERVER_PATH}/bin64
	./cogconfig.sh -stop
	CONFIG_STATUS=$?
	echo -e "\nSystem X Analytic Server configuration status: ${CONFIG_STATUS}"

	cat ${SYSTEMX_ANALYTICSERVER_PATH}/logs/cogconfig_response.csv | awk '
		/INFO/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
		/SUCCESS/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
		/WARNING/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
		/ERROR/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
		/EXEC/ {print "\033[32mAnalytic Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mAnalytic Server Configuration:\033[0m",$0}'

	echo -e "Stopping System X Analytic Server \033[32m[done]\033[0m"

	#kill -TERM "$SystemXLoggerPID" 2>/dev/null
	
}
#Trap SIGTERM
trap term_handler SIGTERM
echo -e "Preparing System X Analytic Server container SIGTERM handling \033[32m[done]\033[0m"

echo -e "Starting System X Analytic Server - container is ready \033[32m[done]\033[0m"

wait "$SystemXLoggerPID"

echo -e "System X Analytic Server - container is down \033[31m[stopped]\033[0m"
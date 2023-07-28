#!/bin/sh
set +e

echo -e "Starting System X Reporting Server container \033[36m[executing]\033[0m"

echo -e "Starting System X Reporting Server container logging \033[36m[executing]\033[0m"
mkdir ${SYSTEMX_REPORTINGSERVER_PATH}/logs
touch ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cognosserver.log

#container background Task
tail -f -n 0 ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cognosserver.log | awk '
  function removeWhiteSpace(str) {
    gsub(/[[:space:]]{3,}/, "   ", str);
    return str;
  }

  $2 ~ /INFO/ {
    print "\033[33mReporting Server:\033[0m \033[37m" removeWhiteSpace($0) "\033[0m";
    next;
  }

  $2 ~ /ERROR/ {
    print "\033[33mReporting Server:\033[0m \033[31m" removeWhiteSpace($0) "\033[0m";
    next;
  }

  {
    print "\033[33mReporting Server:\033[0m", removeWhiteSpace($0);
  }
' &
SystemXLoggerPID=$!

echo -e "Starting System X Reporting Server container logging \033[32m[done]\033[0m"

echo -e "Configuring System X Reporting Server according to container environment \033[36m[executing]\033[0m"

echo -e "Creating System X Reporting Server container logging \033[36m[executing]\033[0m"
mv ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml \
   ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_backup_$(date +'%Y%m%d_%H%M%S').xml
echo -e "Starting System X Reporting Server container logging \033[32m[done]\033[0m"

#COFIG EXPORT (UNENCRYPTED)
# echo -e "Configuring System X Reporting Server with according to container environment \033[36m[executing]\033[0m"
# cd ${SYSTEMX_REPORTINGSERVER_PATH}/bin64
# ./cogconfig.sh -e ../configuration/cogstartup_unencrypted.xml
# CONFIG_STATUS=$?
# echo "System X Reporting Server configuration status: ${CONFIG_STATUS}"
# if [ $CONFIG_STATUS -eq 0 ]; then
# 	cat ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk '
		# /INFO/ {print "\033[32mReporting Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
		# /SUCCESS/ {print "\033[32mReporting Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
		# /WARNING/ {print "\033[32mReporting Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
		# /ERROR/ {print "\033[32mReporting Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
		# /EXEC/ {print "\033[32mReporting Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
		# !(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mReporting Server Configuration:\033[0m",$0}'
# else
# 	echo -e "Configuring System X Reporting Server with according to container environment \034[31m[failed]\033[0m"
# fi

# Check if the template file exists
if [ -e "${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml" ]; then
    echo -e "Performing initial System X Reporting Server configuration accoring to docker image \033[36m[executing]\033[0m"

	cp ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_image_template.xml

	# Configure Content Store Username
	xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='CM']/crn:value/crn:instances[@name='database']/crn:instance[@name='dbHAPECContentstore']/crn:parameter[@name='user']/crn:value/credential/username" -v ${SYSTEMX_CONTENTSTORE_USERNAME} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml
	# Configure Content Store Password
	xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='CM']/crn:value/crn:instances[@name='database']/crn:instance[@name='dbHAPECContentstore']/crn:parameter[@name='user']/crn:value/credential/password" -v ${SYSTEMX_CONTENTSTORE_PASSWORD} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml

	mv ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml

	echo -e "Initial System X Reporting Server configuration according to docker image \033[32m[done]\033[0m"
else
    echo -e "Initial System X Reporting Server configuration according to docker image \033[32m[done]\033[0m"
fi

echo -e "Configuring System X Reporting Server according to container environment \033[32m[done]\033[0m"

#if [[ -z "${COGNOS_WAIT_DB_MINS_DEF}" ]]; then
#  COGNOS_WAIT_DB_MINS=${COGNOS_WAIT_CONTENTSTORE}
#  echo "Using default contentstore wait time ${COGNOS_WAIT_DB_MINS}"
#fi

#echo "--------------------------------------------------------"

echo -e "Waiting for System X Reporting Server Content Store container to become ready \033[36m[executing]\033[0m"

HOST="mssql"
PORT="1433"

while true; do
	nc -z -w1 "$HOST" "$PORT"
	
	if [ $? -eq 0 ]; then
		echo -e "System X Content Store Database server is online! \033[32m[continue]\033[0m"
		break
	else
		echo -e "System X Content Store Database server is not ready yet! \033[33m[waiting]\033[0m"
	fi
	
	sleep 1
done

while true; do
  # Check if the database exists using sqlcmd
  query="IF DB_ID('${SYSTEMX_CONTENTSTORE_DATABASE}') IS NOT NULL PRINT 'Database exists';"
  result=$(/opt/mssql-tools/bin/sqlcmd -S $HOST -U ${SYSTEMX_CONTENTSTORE_USERNAME} -P ${SYSTEMX_CONTENTSTORE_PASSWORD} -d master -h -1 -Q "$query")

  # Check the result to determine if the database exists or not
  if [[ $result == "Database exists" ]]; then
    echo -e "System X Content Store Database is available! \033[32m[continue]\033[0m"
    break  # Exit the loop when the database is found
  else
    echo -e "System X Content Store Database has not been created yet! \033[33m[waiting]\033[0m"
  fi

  # Wait for 1 second before the next iteration
  sleep 1
done

retriesLeft=${COGNOS_MAX_RETRIES}
CONFIG_STATUS=3
while [ $retriesLeft -gt 0 -a $CONFIG_STATUS -ne 0 ]; do
	
	echo -e "Starting System X Reporting Server - retries left: " ${retiresLeft} " \033[36m[executing]\033[0m"

	#waitcnt=${COGNOS_WAIT_DB_MINS}
	#while [ $waitcnt -gt 0 ]; do
	#	echo "Waiting ${waitcnt} minutes to startup the contentstore database container"
	#	sleep 1m
	#	waitcnt=$(( $waitcnt - 1 ))
	#done

	cd ${SYSTEMX_REPORTINGSERVER_PATH}/bin64
	./cogconfig.sh -s
	CONFIG_STATUS=$?
	echo -e "\nSystem X Reporting Server configuration status: ${CONFIG_STATUS}"
	if [ $CONFIG_STATUS -ne 0 ]; then
		cat ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk '
		/INFO/ {print "\033[32mReporting Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
		/SUCCESS/ {print "\033[32mReporting Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
		/WARNING/ {print "\033[32mReporting Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
		/ERROR/ {print "\033[32mReporting Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
		/EXEC/ {print "\033[32mReporting Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mReporting Server Configuration:\033[0m",$0}'
	fi

	retriesLeft=$(( $retriesLeft - 1 ))

done

if [ $CONFIG_STATUS -eq 0 ]; then
	
	cat ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk '
		/INFO/ {print "\033[32mReporting Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
		/SUCCESS/ {print "\033[32mReporting Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
		/WARNING/ {print "\033[32mReporting Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
		/ERROR/ {print "\033[32mReporting Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
		/EXEC/ {print "\033[32mReporting Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mReporting Server Configuration:\033[0m",$0}'

else
	echo -e "Starting System X Reporting Server - too many retries \033[31m[failed]\033[0m"
	kill -TERM "$SystemXLoggerPID" 2>/dev/null
fi

echo -e "Preparing System X Reporting Server container SIGTERM handling \033[36m[executing]\033[0m"
# Prepare for SIGTERM
#Define cleanup procedure
term_handler() {
    echo -e "\nStopping System X Reporting Server - recieved SIGTERM \033[36m[executing]\033[0m"

	cd ${SYSTEMX_REPORTINGSERVER_PATH}/bin64
	./cogconfig.sh -stop
	CONFIG_STATUS=$?
	echo -e "\nSystem X Reporting Server configuration status: ${CONFIG_STATUS}"

	cat ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk '
		/INFO/ {print "\033[32mReporting Server Configuration:\033[0m \033[37m" $0 "\033[0m"}
		/SUCCESS/ {print "\033[32mReporting Server Configuration:\033[0m \033[32m" $0 "\033[0m"}
		/WARNING/ {print "\033[32mReporting Server Configuration:\033[0m \033[33m" $0 "\033[0m"}
		/ERROR/ {print "\033[32mReporting Server Configuration:\033[0m \033[31m" $0 "\033[0m"}
		/EXEC/ {print "\033[32mReporting Server Configuration:\033[0m \033[36m" $0 "\033[0m"}
		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print "\033[32mReporting Server Configuration:\033[0m",$0}'

	echo -e "Stopping System X Reporting Server \033[32m[done]\033[0m"

	#kill -TERM "$SystemXLoggerPID" 2>/dev/null
	
}
#Trap SIGTERM
trap term_handler SIGTERM
echo -e "Preparing System X Reporting Server container SIGTERM handling \033[32m[done]\033[0m"

echo -e "Starting System X Reporting Server - container is ready \033[32m[done]\033[0m"

wait "$SystemXLoggerPID"

echo -e "System X Reporting Server - container is down \033[31m[stopped]\033[0m"
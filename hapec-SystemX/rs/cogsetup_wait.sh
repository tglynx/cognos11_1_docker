#!/bin/sh
set +e

echo "Starting System X Reporting Server container ..."
echo "Configuring System X Service Parameters ..."

mv ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml_backup

# Configure Content Store Username
xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='CM']/crn:value/crn:instances[@name='database']/crn:instance[@name='dbHAPECContentstore']/crn:parameter[@name='user']/crn:value/credential/username" -v ${SYSTEMX_CONTENTSTORE_USERNAME} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml
# Configure Content Store Password
xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='CM']/crn:value/crn:instances[@name='database']/crn:instance[@name='dbHAPECContentstore']/crn:parameter[@name='user']/crn:value/credential/password" -v ${SYSTEMX_CONTENTSTORE_PASSWORD} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml

cp ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml

echo "Starting System X Reporting Server container logging ..."
mkdir ${SYSTEMX_REPORTINGSERVER_PATH}/logs
touch ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cognosserver.log
tail -f -n 0 ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cognosserver.log | awk '
	$2 ~ /INFO/ {print "\033[37m" $0 "\033[0m"}
	$2 ~ /ERROR/ {print "\033[31m" $0 "\033[0m"}
	!( $2 ~ /INFO/ || $2 ~ /ERROR/ ) {print $0}
	' | awk '{print "\033[33mReporting Server:\033[0m",$0}' &

if [[ -z "${COGNOS_WAIT_DB_MINS_DEF}" ]]; then
  COGNOS_WAIT_DB_MINS=${COGNOS_WAIT_CONTENTSTORE}
  echo "Using default contentstore wait time ${COGNOS_WAIT_DB_MINS}"
fi

echo "--------------------------------------------------------"

retriesLeft=${COGNOS_MAX_RETRIES}
CONFIG_STATUS=3
while [ $retriesLeft -gt 0 -a $CONFIG_STATUS -ne 0 ]; do
echo "======= Attempting to start Cognos ${retriesLeft} times ========="

waitcnt=${COGNOS_WAIT_DB_MINS}
while [ $waitcnt -gt 0 ]; do
	echo "Waiting ${waitcnt} minutes to startup the contentstore database container"
	sleep 1m
	waitcnt=$(( $waitcnt - 1 ))
done

echo "====== Running Cognos Unattended config =================="
cd ${SYSTEMX_REPORTINGSERVER_PATH}/bin64
./cogconfig.sh -s
CONFIG_STATUS=$?
echo "====== Cognos configuration status: ${CONFIG_STATUS} ====="
if [ $CONFIG_STATUS -ne 0 ]; then
	cat ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk '
		/INFO/ {print "\033[37m" $0 "\033[0m"}
		/SUCCESS/ {print "\033[32m" $0 "\033[0m"}
		/WARNING/ {print "\033[33m" $0 "\033[0m"}
		/ERROR/ {print "\033[31m" $0 "\033[0m"}
		/EXEC/ {print "\033[36m" $0 "\033[0m"}
		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print $0}' | awk '{print "\033[32mReporting Server Configuration:\033[0m",$0}'
fi

retriesLeft=$(( $retriesLeft - 1 ))
done

if [ $CONFIG_STATUS -eq 0 ]; then
	tail -n+0 -f ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk '
		/INFO/ {print "\033[37m" $0 "\033[0m"}
		/SUCCESS/ {print "\033[32m" $0 "\033[0m"}
		/WARNING/ {print "\033[33m" $0 "\033[0m"}
		/ERROR/ {print "\033[31m" $0 "\033[0m"}
		/EXEC/ {print "\033[36m" $0 "\033[0m"}
		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print $0}' | awk '{print "\033[32mReporting Server Configuration:\033[0m",$0}'
else
	echo "Too many retries, exiting "
fi
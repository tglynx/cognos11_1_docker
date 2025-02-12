#######################################################################################################
# Dockerfile based on Dockerfile from Philippe Gregoire (philippe.gregoire@fr.ibm.com)
# Base Image
FROM consol/rocky-xfce-vnc

# VNC and HTML-VNC ports
EXPOSE 5901 6901

# Switch to root user
USER 0

#######################################################################################################
# IBM Cognos Analytics
# Based on RHEL Dockerfile from dnastaci@us.ibm.com

# Cognos settings
ENV COGNOS_MAX_RETRIES 1

ENV SYSTEMX_BASEPATH /opt/hapec/SystemX
ENV SYSTEMX_REPORTINGSERVER_PATH ${SYSTEMX_BASEPATH}/ReportingServer

ARG COGNOS_USER=cognosusr
ARG COGNOS_PW=password
ARG COGNOS_UID=1000
ARG COGNOS_GID=1000

ARG SYSTEMX_REPOSITORY_PATH=/install/hapec/SystemX

ARG COGNOS_PROPERTIES=cognosca_reponse.properties
ARG COGNOS_HOST=rs

# IBM Cognos Analytics Installer
ARG SYSTEMX_INSTALLER_URL=${SYSTEMX_INSTALLER_URL}
ARG SYSTEMX_INSTALLER_FILENAME=${SYSTEMX_INSTALLER_FILENAME}

# IBM Cognos Analytics Server 
ARG SYSTEMX_REPORTINGSERVER_REPOSITORY_URL=${SYSTEMX_REPORTINGSERVER_REPOSITORY_URL}
ARG SYSTEMX_REPORTINGSERVER_REPOSITORY=${SYSTEMX_REPORTINGSERVER_REPOSITORY}

# Cognos Prepreq (See https://www.ibm.com/support/knowledgecenter/en/SS5R93_5.3.0/com.ibm.spectrum.sc.doc/ins_cognos_analytics_Linux_single.html)
# - glibc-2.12-1.166.el6 or later (both i686 and x86_64 packages)
# - libstdc++-4.4.7-16.el6 or later (both i686 and x86_64 packages)
# - nspr-4.9.2-1.el6 or later (both i686 and x86_64 packages)
# - nss-3.14.0.0-12.el6 or later (both i686 and x86_64 packages)
# - openmotif-2.3.3-5.el6 or later (both i686 and x86_64 packages)
#
# We also add useful utilities 
RUN yum install -y \
	gcc \
	which \
	unzip \
	sudo \
	glibc.x86_64 glibc.i686 glibc-langpack-en \
	libstdc++.x86_64 libstdc++.i686 \
	libXtst libX11.so.6 libnsl libnsl.so.1 libstdc++.so.6 \
	nspr.x86_64 nspr.i686 \
	nss.x86_64 nss.i686 \
	motif.i686 motif.x86_64 \
	gedit \
	xmlstarlet \
	nc 

# mssql-tools for contentstore check
RUN curl -# https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo
RUN ACCEPT_EULA=Y yum install -y mssql-tools

# yum cleanup
RUN yum clean all && rm -rf /tmp/*
	
#zlib fix for cognos confighuration gui
RUN cd /opt/ && \
	curl -# -o zlib-1.2.9.zip https://codeload.github.com/madler/zlib/zip/refs/tags/v1.2.9 && \
	unzip zlib-1.2.9.zip && \
	cd zlib-1.2.9 && \
	./configure && \
	make && \
	make install


# For the record, re: https://www.ibm.com/support/knowledgecenter/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/c_inst_ulimitsettingsonunixandlinuxoperatingsystems.html
RUN \
	ulimit -f -t -u -m -n -s -v && \
	echo "Current hostname: `hostname`" && \
	echo "VNC password is ${VNC_PW}"
	
# Setup Cognos user as user 1000 and run installer
RUN \
	echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel && \
    chmod 0440 /etc/sudoers.d/wheel && \
	groupadd -f -g ${COGNOS_GID} ${COGNOS_USER} && \
	useradd -u ${COGNOS_UID} -g ${COGNOS_GID} -G wheel ${COGNOS_USER} -m && \
	echo "$COGNOS_USER:$COGNOS_PW" | chpasswd 

# Copy Cognos installer files into the container's filesystem
#COPY /media/$SYSTEMX_INSTALLER_FILENAME ${SYSTEMX_REPOSITORY_PATH}/

# Download repositories
#RUN echo wget --progress=bar:force:noscroll $SYSTEMX_INSTALLER_URL -P ${SYSTEMX_REPOSITORY_PATH}/ -O ${SYSTEMX_INSTALLER_FILENAME}.wget
#RUN wget --progress=bar:force:noscroll $SYSTEMX_INSTALLER_URL -P ${SYSTEMX_REPOSITORY_PATH}/ -O ${SYSTEMX_INSTALLER_FILENAME}.wget

#RUN echo curl -# -o ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_INSTALLER_FILENAME}.curl $SYSTEMX_INSTALLER_URL

RUN mkdir -p ${SYSTEMX_REPOSITORY_PATH}
RUN curl -# -o ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_INSTALLER_FILENAME} $SYSTEMX_INSTALLER_URL
RUN curl -# -o ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_REPORTINGSERVER_REPOSITORY} $SYSTEMX_REPORTINGSERVER_REPOSITORY_URL

#COPY /media/$SYSTEMX_REPORTINGSERVER_REPOSITORY ${SYSTEMX_REPOSITORY_PATH}/
#COPY /media/$COGNOS_SAMPLES ${SYSTEMX_REPOSITORY_PATH}/

# Copy properties
COPY ${COGNOS_PROPERTIES} ${SYSTEMX_REPOSITORY_PATH}

# Run silent installer
# See also: https://www.ibm.com/support/knowledgecenter/en/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/t_inst_response_templates.html
RUN	mkdir -p "${SYSTEMX_REPORTINGSERVER_PATH}" 
RUN	chown -R ${COGNOS_USER}:${COGNOS_USER} "${SYSTEMX_BASEPATH}" 
RUN	chmod uo+x "${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_INSTALLER_FILENAME}" 
RUN	echo "Running cognos silent installer with config:" 
#RUN	cat ${SYSTEMX_REPOSITORY_PATH}/${COGNOS_PROPERTIES} 
#RUN	echo REPO=${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_REPORTINGSERVER_REPOSITORY} >>${SYSTEMX_REPOSITORY_PATH}/${COGNOS_PROPERTIES} 
#RUN	echo "BUILD_HOST=`hostname`"> ${SYSTEMX_BASEPATH}/build_host.txt 
RUN su - ${COGNOS_USER} -c "\"${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_INSTALLER_FILENAME}\" -f \"${SYSTEMX_REPOSITORY_PATH}/${COGNOS_PROPERTIES}\" -i silent"	

# RUN	cp ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml_`hostname` 
# RUN	sed -i "s/`hostname`/${COGNOS_HOST}/g" ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml 
# RUN	cp ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml_${COGNOS_HOST}

# Copy Microsoft SQL Server jar
COPY /media/mssql-jdbc-7.4.1.jre8.jar ${SYSTEMX_REPORTINGSERVER_PATH}/drivers/
RUN chmod +x ${SYSTEMX_REPORTINGSERVER_PATH}/drivers/*.jar

# Link zlib fix 
RUN cd ${SYSTEMX_REPORTINGSERVER_PATH}/bin64 && \
	ln -s -f /opt/zlib-1.2.9/libz.so.1.2.9 ./libz.so.1

# Set JAVA_HOME
ENV JAVA_HOME ${SYSTEMX_REPORTINGSERVER_PATH}/ibm-jre/jre
	
# Setup unattended configuration on container start
#See https://www.ibm.com/support/knowledgecenter/en/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/t_unatt_cnfg.html#unatt_cnfg

COPY cogstartup_template.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml

RUN mkdir ${SYSTEMX_REPORTINGSERVER_PATH}/data

# Set modified path credentials
RUN	chown -R ${COGNOS_USER}:${COGNOS_USER} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration
RUN	chown -R ${COGNOS_USER}:${COGNOS_USER} ${SYSTEMX_REPORTINGSERVER_PATH}/data

# should be done in run phase of the container by environment variables
# Configure Content Store Username
# RUN xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='CM']/crn:value/crn:instances[@name='database']/crn:instance[@name='dbHAPECContentstore']/crn:parameter[@name='user']/crn:value/credential/username" -v ${SYSTEMX_CONTENTSTORE_USERNAME} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml
# Configure Content Store Password
# RUN xmlstarlet ed -L -N crn="http://developer.cognos.com/schemas/crconfig/1/" -u "/crn:parameters/crn:parameter[@name='CM']/crn:value/crn:instances[@name='database']/crn:instance[@name='dbHAPECContentstore']/crn:parameter[@name='user']/crn:value/credential/password" -v ${SYSTEMX_CONTENTSTORE_PASSWORD} ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup_template.xml

COPY cogsetup_wait.sh /dockerstartup/
RUN chmod uo+x /dockerstartup/*.sh
		
# Cognos UI port
EXPOSE 9300

# Copy desktop shortcuts
COPY ["Reporting Server Configuration.desktop", "/headless/Desktop/"] 

# Switch back to regular user
USER 1000

# RUN echo "====== Config validation ==================" && \
# cd ${SYSTEMX_REPORTINGSERVER_PATH}/bin64 && \
# ./cogconfig.sh -e ../configuration/cogstartup_unencrypted.xml && \
# CONFIG_STATUS=$? && \
# echo "====== Cognos configuration status: ${CONFIG_STATUS} =====" && \
# cat ${SYSTEMX_REPORTINGSERVER_PATH}/logs/cogconfig_response.csv | awk ' \
# 		/INFO/ {print "\033[37m" $0 "\033[0m"} \
# 		/SUCCESS/ {print "\033[32m" $0 "\033[0m"} \
# 		/WARNING/ {print "\033[33m" $0 "\033[0m"} \
# 		/ERROR/ {print "\033[31m" $0 "\033[0m"} \
# 		/EXEC/ {print "\033[36m" $0 "\033[0m"} \
# 		!(/INFO/ || /SUCCESS/ || /WARNING/ || /ERROR/ || /EXEC/ ) {print $0}' | awk '{print "\033[32mReporting Server Configuration:\033[0m",$0}' 

# Kick-off unattended Cognos configuration
CMD ["/dockerstartup/cogsetup_wait.sh"]
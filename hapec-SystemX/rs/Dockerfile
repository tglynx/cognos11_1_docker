# Dockerfile based on Dockerfile from Philippe Gregoire (philippe.gregoire@fr.ibm.com)
# Base Image
FROM consol/rocky-xfce-vnc

# VNC and HTML-VNC ports
EXPOSE 5901 6901

# Switch to root user
USER 0

#######################################################################################################
# Cognos setup
# Based on RHEL Dockerfile from dnastaci@us.ibm.com

# How long to wait for contentstore database to come up, default (in minutes)
ENV COGNOS_WAIT_CONTENTSTORE 1 	

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
ARG COGNOS_HOST=cognos11srv

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
	nano \
	rsync \
	glibc.x86_64 glibc.i686 glibc-langpack-en \
	libstdc++.x86_64 libstdc++.i686 \
	libXtst libX11.so.6 libnsl libnsl.so.1 libstdc++.so.6 \
	nspr.x86_64 nspr.i686 \
	nss.x86_64 nss.i686 \
	motif.i686 motif.x86_64 \
	gedit \
	&& yum clean all && rm -rf /tmp/*
	
#zlib fix for cognos confighuration gui
RUN cd /opt/ && \
	curl -# -o zlib-1.2.9.tar.gz https://github.com/madler/zlib/archive/refs/tags/v1.2.9.zip && \
	tar -xzvf zlib-1.2.9.tar.gz && \
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
RUN	chmod -R uo+x "${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_INSTALLER_FILENAME}" 
RUN	echo "Running cognos silent installer with config:" 
RUN	cat ${SYSTEMX_REPOSITORY_PATH}/${COGNOS_PROPERTIES} 
RUN	echo REPO=${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_REPORTINGSERVER_REPOSITORY} >>${SYSTEMX_REPOSITORY_PATH}/${COGNOS_PROPERTIES} 
RUN	echo "BUILD_HOST=`hostname`"> ${SYSTEMX_BASEPATH}/build_host.txt 
RUN su - ${COGNOS_USER} -c "\"${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_INSTALLER_FILENAME}\" -f \"${SYSTEMX_REPOSITORY_PATH}/${COGNOS_PROPERTIES}\" -i silent"	

RUN	cp ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml_`hostname` 
RUN	sed -i "s/`hostname`/${COGNOS_HOST}/g" ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml 
RUN	cp ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/cogstartup.xml_${COGNOS_HOST}

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
COPY cogstartup.xml_configured ${SYSTEMX_REPORTINGSERVER_PATH}/configuration/
COPY cogsetup_wait.sh /dockerstartup/
RUN \
	sed -i 's/\r//g' /dockerstartup/cogsetup_wait.sh && \
	chmod uo+x /dockerstartup/*.sh
		
# Cognos UI port
EXPOSE 9300

# Copy desktop shortcuts
COPY ["Reporting Server Configuration.desktop", "/headless/Desktop/"] 

# Switch back to regular user
USER 1000

# Kick-off unattended Cognos configuration
CMD ["/dockerstartup/cogsetup_wait.sh"]

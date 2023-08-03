FROM consol/rocky-xfce-vnc

# VNC and HTML-VNC ports
EXPOSE 5901 6901

# Switch to root user
USER 0

#######################################################################################################
# IBM Planning Analytics

# Cognos settings
ENV COGNOS_MAX_RETRIES 1

ENV SYSTEMX_BASEPATH /opt/hapec/SystemX
ENV SYSTEMX_ANALYTICSERVER_PATH ${SYSTEMX_BASEPATH}/AnalyticServer

ARG COGNOS_USER=cognosusr
ARG COGNOS_PW=password
ARG COGNOS_UID=1000
ARG COGNOS_GID=1000

ARG SYSTEMX_REPOSITORY_PATH=/install/hapec/SystemX

ARG JAVA_PROPERTIES=installer.properties
ARG COGNOS_PROPERTIES=response.ats
ARG COGNOS_HOST=as

# IBM Java 8 Installer
ARG SYSTEMX_JAVA_INSTALLER_URL=${SYSTEMX_JAVA_INSTALLER_URL}
ARG SYSTEMX_JAVA_INSTALLER=${SYSTEMX_JAVA_INSTALLER} 

# IBM Planning Analytics Installer 2.0 Linux x86 Multilingual
ARG SYSTEMX_ANALYTICSERVER_REPOSITORY_URL=${SYSTEMX_ANALYTICSERVER_REPOSITORY_URL}
ARG SYSTEMX_ANALYTICSERVER_REPOSITORY=${SYSTEMX_ANALYTICSERVER_REPOSITORY}

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
	
# yum cleanup
RUN yum clean all && rm -rf /tmp/*

#zlib fix for cognos configuration gui
# RUN cd /opt/ && \
# 	curl -# -o zlib-1.2.3.3.zip https://codeload.github.com/madler/zlib/zip/refs/tags/v1.2.3.3 && \
# 	unzip zlib-1.2.3.3.zip && \
# 	cd zlib-1.2.3.3 && \
# 	./configure && \
# 	make && \
# 	make install

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
# COPY /media/$COGNOS_INSTALLER ${COGNOS_MEDIA_DIR}/

# WORKDIR ${COGNOS_MEDIA_DIR}
# RUN mkdir pa
# RUN tar -xzvf ${COGNOS_INSTALLER} -C ./pa

# Install Repository
RUN mkdir -p ${SYSTEMX_REPOSITORY_PATH}

# Download JRE
RUN curl -# -o ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_JAVA_INSTALLER} ${SYSTEMX_JAVA_INSTALLER_URL}
RUN	chmod uo+x ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_JAVA_INSTALLER}

# Download PA
RUN curl -# -o ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_ANALYTICSERVER_REPOSITORY} $SYSTEMX_ANALYTICSERVER_REPOSITORY_URL

WORKDIR ${SYSTEMX_REPOSITORY_PATH}

# Extract installer and cleanup
RUN tar -xzvf ${SYSTEMX_ANALYTICSERVER_REPOSITORY} && rm -f ${SYSTEMX_ANALYTICSERVER_REPOSITORY} 

# Copy properties
COPY ${JAVA_PROPERTIES} ${SYSTEMX_REPOSITORY_PATH}
COPY ${COGNOS_PROPERTIES} ${SYSTEMX_REPOSITORY_PATH}/linuxi38664h

# Run silent installer
# See also: https://www.ibm.com/support/knowledgecenter/en/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/t_inst_response_templates.html
RUN	mkdir -p "${SYSTEMX_ANALYTICSERVER_PATH}" 
RUN	chown -R ${COGNOS_USER}:${COGNOS_USER} "${SYSTEMX_BASEPATH}" 

# Install JRE from Installer Binary
#WORKDIR ${SYSTEMX_REPOSITORY_PATH}
#RUN ./${SYSTEMX_JAVA_INSTALLER} -f ./${JAVA_PROPERTIES} -i silent

# Deploy JRE from ZIP
WORKDIR ${SYSTEMX_BASEPATH}
RUN mv ${SYSTEMX_REPOSITORY_PATH}/${SYSTEMX_JAVA_INSTALLER} .
RUN unzip ${SYSTEMX_JAVA_INSTALLER}
RUN rm -f ${SYSTEMX_JAVA_INSTALLER}

# Set JAVA_HOME
ENV JAVA_HOME ${SYSTEMX_BASEPATH}/ibm-jre/jre

USER 1000
WORKDIR ${SYSTEMX_REPOSITORY_PATH}/linuxi38664h
RUN	./issetup -s
USER 0

# Link zlib fix 
# from https://www.ibm.com/support/pages/undefined-symbol-gzopen64-version-zlib-error-when-opening-cogconfig
#RUN cd ${SYSTEMX_ANALYTICSERVER_PATH}/bin64 && \
#	ln -s -f /opt/zlib-1.2.3.3/libz.so.1.2.3.3 ./libz.so.1

RUN cd ${SYSTEMX_ANALYTICSERVER_PATH}/bin64 && \
	mv libz.so libz.so.bak && \
	mv libz.so.1 libz.so.1.bak && \
	ln -s /usr/lib64/libz.so.1 libz.so && \
	cd ${SYSTEMX_ANALYTICSERVER_PATH}/bin && \
	mv libz.so libz.so.bak && \
	mv libz.so.1 libz.so.1.bak && \
	ln -s /usr/lib/libz.so.1 libz.so && \
	ln -s /usr/lib/libz.so.1 libz.so.1


#Import applixca.pem root ca certificate in java truststore
#RUN ${SYSTEMX_BASEPATH}/ibm-jre/bin/keytool -import -file ${SYSTEMX_ANALYTICSERVER_PATH}/bin64/ssl/applixca.pem -keystore ${SYSTEMX_BASEPATH}/ibm-jre/jre/lib/security/cacerts -storepass changeit -noprompt -alias applixca
#RUN ${SYSTEMX_BASEPATH}/ibm-jre/bin/keytool -import -file ${SYSTEMX_ANALYTICSERVER_PATH}/bin64/ssl/tm1admsvrcert.pem -keystore ${SYSTEMX_BASEPATH}/ibm-jre/jre/lib/security/cacerts -storepass changeit -noprompt -alias tm1admsvrcert
#RUN ${SYSTEMX_BASEPATH}/ibm-jre/bin/keytool -import -file ${SYSTEMX_ANALYTICSERVER_PATH}/bin64/ssl/tm1svrcert.pem -keystore ${SYSTEMX_BASEPATH}/ibm-jre/jre/lib/security/cacerts -storepass changeit -noprompt -alias tm1svrcert


# Xercxes? 
#RUN curl -# -o ${SYSTEMX_REPOSITORY_PATH}/Xerces-J-bin.2.12.2.zip https://dlcdn.apache.org//xerces/j/binaries/Xerces-J-bin.2.12.2.zip

#LD_LIBRARY_PATH
#ENV LD_LIBRARY_PATH ${SYSTEMX_ANALYTICSERVER_PATH}/webapps/pmpsvc/WEB-INF/bin64/:$LD_LIBRARY_PATH
#ENV LD_LIBRARY_PATH ${SYSTEMX_ANALYTICSERVER_PATH}/bin64/:$LD_LIBRARY_PATH

# Copy cogstartup_template
COPY cogstartup_template.xml ${SYSTEMX_ANALYTICSERVER_PATH}/configuration/cogstartup_template.xml
RUN	chown -R ${COGNOS_USER}:${COGNOS_USER} ${SYSTEMX_ANALYTICSERVER_PATH}/configuration

# Run unattended configuration 
#See https://www.ibm.com/support/knowledgecenter/en/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/t_unatt_cnfg.html#unatt_cnfg
#COPY cogstartup.xml_configured SYSTEMX_ANALYTICSERVER_PATH/configuration/
COPY cogsetup_wait.sh /dockerstartup/
RUN \
	sed -i 's/\r//g' /dockerstartup/cogsetup_wait.sh && \
	chmod uo+x /dockerstartup/*.sh

# TM1 Admin Server plain
EXPOSE 5495 

# TM1 Admin Server SSL
EXPOSE 5498

# TM1 Instance hapecAnalyticServer
EXPOSE 5500

# pmpsvc port
EXPOSE 9510 


# Copy desktop shortcuts
COPY ["Analytic Server Configuration.desktop", "/headless/Desktop/"] 

# Prepare /TM1Servers/hapecAnalyticServer
RUN	mkdir -p /TM1Servers/hapecAnalyticServer/data
RUN	mkdir -p /TM1Servers/hapecAnalyticServer/logs

# Deploy hapecAnalyticServer TM1 Instance Template
COPY tm1s.cfg /TM1Servers/hapecAnalyticServer

# Set acl for /TM1Servers
RUN	chown -R ${COGNOS_USER}:${COGNOS_USER} /TM1Servers

# Switch back to regular user
USER 1000

# The below command is used to keep the base xfce up and running, replaced by our startup
#CMD ["-d --wait"]

# Kick-off unattended Cognos configuration
CMD ["/dockerstartup/cogsetup_wait.sh"]
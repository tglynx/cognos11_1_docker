FROM consol/centos-xfce-vnc

MAINTAINER Michael Sommer

# VNC and HTML-VNC ports
EXPOSE 5901 6901

# Switch to root user
USER 0

# Cognos settings
ENV COGNOS_MAX_RETRIES 1
ENV COGNOS_BASE_DIR /opt/ibm/cognos
ENV COGNOS_DIR      ${COGNOS_BASE_DIR}/tm1_64

ARG COGNOS_USER=cognosusr
ARG COGNOS_PW=password
ARG COGNOS_UID=1000
ARG COGNOS_GID=1000

ARG COGNOS_MEDIA_DIR=/installer/cognos

ARG COGNOS_PROPERTIES=response.ats
ARG COGNOS_HOST=ca

# IBM Planning Analytics Installer 2.0 Linux x86 Multilingual
ARG COGNOS_INSTALLER=pa_2.0.9_l86-64_ml.tar.gz

# Cognos Prepreq (See https://www.ibm.com/support/knowledgecenter/en/SS5R93_5.3.0/com.ibm.spectrum.sc.doc/ins_cognos_analytics_Linux_single.html)
# - glibc-2.12-1.166.el6 or later (both i686 and x86_64 packages)
# - libstdc++-4.4.7-16.el6 or later (both i686 and x86_64 packages)
# - nspr-4.9.2-1.el6 or later (both i686 and x86_64 packages)
# - nss-3.14.0.0-12.el6 or later (both i686 and x86_64 packages)
# - openmotif-2.3.3-5.el6 or later (both i686 and x86_64 packages)
#
# We also add useful utilities 
RUN yum install -y \
	which \
	unzip \
	sudo \
	nano \
	rsync \
	glibc.x86_64 glibc.i686 \
	libstdc++.x86_64 libstdc++.i686 \
	nspr.x86_64 nspr.i686 \
	nss.x86_64 nss.i686 \
	openmotif.x86_64 openmotif.i686 \
	gedit \
	&& yum clean all && rm -rf /tmp/*
	
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
	useradd --help && \
	useradd -u ${COGNOS_UID} -g ${COGNOS_GID} -G wheel ${COGNOS_USER} -m && \
	echo "$COGNOS_USER:$COGNOS_PW" | chpasswd && \
	cat /etc/passwd

# Copy Cognos installer files into the container's filesystem
COPY /media/$COGNOS_INSTALLER ${COGNOS_MEDIA_DIR}/

WORKDIR ${COGNOS_MEDIA_DIR}
RUN mkdir pa
RUN tar -xzvf ${COGNOS_INSTALLER} -C ./pa


# Copy properties
COPY ${COGNOS_PROPERTIES} ${COGNOS_MEDIA_DIR}/pa/linuxi38664h

WORKDIR ${COGNOS_MEDIA_DIR}/pa/linuxi38664h

# Run silent installer
# See also: https://www.ibm.com/support/knowledgecenter/en/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/t_inst_response_templates.html
RUN	echo "Running Planning Analytics silent installer"
RUN	./issetupnx -s


# Set JAVA_HOME
ENV JAVA_HOME ${COGNOS_DIR}/jre

	
# Run unattended configuration 
#See https://www.ibm.com/support/knowledgecenter/en/SSEP7J_11.0.0/com.ibm.swg.ba.cognos.inst_cr_winux.doc/t_unatt_cnfg.html#unatt_cnfg
#COPY cogstartup.xml_configured ${COGNOS_DIR}/configuration/
COPY cogsetup_wait.sh /dockerstartup/
RUN \
	sed -i 's/\r//g' /dockerstartup/cogsetup_wait.sh && \
	chmod uo+x /dockerstartup/*.sh
		
# Cognos UI port
EXPOSE 9300

# Copy desktop shortcuts
COPY Cognos_Config.desktop /headless/Desktop

# Switch back to regular user
USER 1000

# The below command is used to keep the base xfce up and running, replaced by our startup
#CMD ["-d --wait"]

# Kick-off unattended Cognos configuration
CMD ["/dockerstartup/cogsetup_wait.sh"]

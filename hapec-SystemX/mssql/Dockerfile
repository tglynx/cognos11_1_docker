FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN apt-get -y update  && \
        apt-get install -y netcat && \
        apt-get clean

USER mssql

RUN mkdir -p /usr/mssql
WORKDIR /usr/mssql

COPY ./systemx-contentstore.sh .
COPY ./create-contentstore.sql .
COPY ./entrypoint.sh .

ENV ACCEPT_EULA="Y"
ENV MSSQL_SA_PASSWORD=${SYSTEMX_CONTENTSTORE_PASSWORD}
ENV MSSQL_PID Express

CMD /bin/bash /usr/mssql/entrypoint.sh
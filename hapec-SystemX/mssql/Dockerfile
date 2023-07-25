FROM mcr.microsoft.com/mssql/server:2022-latest

RUN mkdir -p /usr/mssql
WORKDIR /usr/mssql

COPY ./create-contentstore.sh .
COPY ./create-contentstore.sql .
COPY ./entrypoint.sh .

ENV ACCEPT_EULA="Y"
ENV MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}
ENV MSSQL_PID Express

CMD /bin/bash /usr/mssql/entrypoint.sh
FROM mcr.microsoft.com/mssql/server:2019-latest

RUN mkdir -p /usr/mssql
WORKDIR /usr/mssql

COPY ./create-contentstore.sh .
COPY ./create-contentstore.sql .
COPY ./entrypoint.sh .

ENV ACCEPT_EULA="Y"
ENV SA_PASSWORD=${SA_PASSWORD}
ENV MSSQL_PID Express

CMD /bin/bash /usr/mssql/entrypoint.sh

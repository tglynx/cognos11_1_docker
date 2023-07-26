echo "waiting for the SQL-Server to come up"
sleep 20s
#tail -n+0 /var/opt/mssql/log/errorlog | awk '{print "\033[34mContent Store:\033[0m",$0}'
sleep 20s

echo "checking for content store database"
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P ${MSSQL_SA_PASSWORD} -i create-contentstore.sql

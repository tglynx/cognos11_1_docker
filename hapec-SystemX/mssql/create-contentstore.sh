echo "waiting for the SQL-Server to come up"
sleep 40s

echo "checking for content store database"
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P ${SA_PASSWORD} -i create-contentstore.sql

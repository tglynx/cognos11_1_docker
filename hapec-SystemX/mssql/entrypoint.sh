#start SQL Server, start the script to create the DB and import the data, start the app
echo "Starting Microsoft SQL-Server Express on Linux (2019) - System X Content Store Database"
/usr/mssql/systemx-contentstore.sh & /opt/mssql/bin/sqlservr | tr -d '\r'

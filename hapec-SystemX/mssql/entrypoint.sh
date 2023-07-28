#!/bin/sh

#start SQL Server, start the script to create the DB and import the data, start the app
echo -e  "Starting Microsoft SQL-Server Express on Linux (2019) - System X Content Store database \033[36m[executing]\033[0m"

/opt/mssql/bin/sqlservr | tr -d '\r' & 
SystemXSQLServerPID=$!

/usr/mssql/systemx-contentstore.sh & 

# echo -e "Preparing System X Content Store container SIGTERM handling \033[36m[executing]\033[0m"
# # Prepare for SIGTERM
# #Define cleanup procedure
# term_handler() {
#     echo -e "\nStopping System X Content Store container - recieved SIGTERM \033[36m[executing]\033[0m"

#     #pkill -TERM sqlservr

#     while true; do
#         echo 'still here...'
#     done

# 	echo -e "Stopping System X Content Store container \033[32m[done]\033[0m"
# }
# #Trap SIGTERM
# trap term_handler SIGTERM
# echo -e "Preparing System X Reporting Server container SIGTERM handling \033[32m[done]\033[0m"

echo -e "Starting Microsoft SQL-Server Express on Linux (2019) - System X Content Store database \033[32m[done]\033[0m"

wait "$SystemXSQLServerPID"

echo -e "System X Content Store - container is down \033[31m[stopped]\033[0m"
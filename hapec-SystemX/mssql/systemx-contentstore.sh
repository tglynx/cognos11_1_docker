echo -e "Checking for System X Content Store database \033[33m[waiting]\033[0m"
# sleep 20s
# #tail -n+0 /var/opt/mssql/log/errorlog | awk '{print "\033[34mContent Store:\033[0m",$0}'
# sleep 20s
# echo -e "System X Content Store Database server is ready! \033[32m[continue]\033[0m"

HOST="localhost"
PORT="1433"

while true; do
  nc -z -w1 "$HOST" "$PORT"
  if [ $? -eq 0 ]; then
    echo -e "System X Content Store Database server is ready! \033[32m[continue]\033[0m"
	break
  else
    echo -e "System X Content Store Database server is not ready yet! \033[33m[waiting]\033[0m"
  fi
  sleep 1
done

echo -e "Checking System X Content Store Database! \033[36m[executing]\033[0m"
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P ${MSSQL_SA_PASSWORD} -i create-contentstore.sql
echo -e "Checking System X Content Store Database! \033[32m[done]\033[0m"
echo -e "Starting Microsoft SQL-Server Express on Linux (2019) - System X Content Store database \033[32m[done]\033[0m"

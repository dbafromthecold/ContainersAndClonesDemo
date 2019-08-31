sleep 15
 
/opt/mssql-tools/bin/sqlcmd -S . -U sa -P Testing1122 \
-Q "CREATE DATABASE [DatabaseB] ON (FILENAME = '/var/opt/sqlserver/DatabaseB.mdf'),(FILENAME = '/var/opt/sqlserver/DatabaseB_log.ldf') FOR ATTACH"
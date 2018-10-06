FROM mcr.microsoft.com/mssql/server:latest

RUN mkdir /var/opt/sqlserver

COPY DatabaseB.mdf /var/opt/sqlserver
COPY DatabaseB_log.ldf /var/opt/sqlserver

HEALTHCHECK --interval=10s  \
CMD /opt/mssql/bin/sqlservr & \
	/opt/mssql-tools/bin/sqlcmd -S . -U sa -P $SA_PASSWORD \
		-Q "CREATE DATABASE [DatabaseB] ON (FILENAME = '/var/opt/sqlserver/DatabaseB.mdf'),(FILENAME = '/var/opt/sqlserver/DatabaseB_log.ldf') FOR ATTACH"
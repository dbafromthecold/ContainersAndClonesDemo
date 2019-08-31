FROM mcr.microsoft.com/mssql/server:2019-RC1-ubuntu

RUN mkdir /var/opt/sqlserver

COPY DatabaseB.mdf /var/opt/sqlserver
COPY DatabaseB_log.ldf /var/opt/sqlserver

COPY attach-db.sh /var/opt/sqlserver

RUN chmod +x /var/opt/sqlserver/attach-db.sh

ENTRYPOINT /var/opt/sqlserver/attach-db.sh & /opt/mssql/bin/sqlservr
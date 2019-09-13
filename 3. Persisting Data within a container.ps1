# Pre-requisites
Install-Module CredentialManager -Force
Install-Module dbatools -Force

Import-Module CredentialManager
Import-Module dbatools


Get-Module 

Set-Location C:\


# set credentials to connect to SQL instances
$cred = Get-StoredCredential -Target "SqlDocker"

if (!$cred){
    New-StoredCredential -Target "SqlDocker" -UserName "sa" -Password "Testing1122" -Persist Session
}

$cred = Get-StoredCredential -Target "SqlDocker"


# https://dbafromthecold.com/2017/06/28/persisting-data-in-docker-containers-part-two/
## Named Volumes



# remove unused volumes
docker volume prune -f



# create the named volume
docker volume create mssqlsystem
docker volume create mssqluser



# verify named volume is there
docker volume ls



# spin up a container with named volume mapped
docker container run -d -p 15999:1433 `
--volume mssqlsystem:/var/opt/mssql `
--volume mssqluser:/var/opt/sqlserver `
--env ACCEPT_EULA=Y `
--env SA_PASSWORD=Testing1122 `
--name testcontainer3 `
mcr.microsoft.com/mssql/server:2019-RC1-ubuntu



# check the container is running
docker ps -a  



# create database on the named volume
$Query = "CREATE DATABASE [DatabaseC]
ON PRIMARY
(NAME = N'DatabaseC', FILENAME = N'/var/opt/sqlserver/DatabaseC.mdf')
LOG ON
(NAME = N'DatabaseC_log', FILENAME = N'/var/opt/sqlserver/DatabaseC_log.ldf')"

Invoke-DbaQuery -SqlInstance 'localhost,15999' -SqlCredential $Cred -Query $Query

                

# check database is there
Get-DbaDatabase -SqlInstance 'localhost,15999' -SqlCredential $Cred | Select-Object Name                         



# create a test table and insert some data
$Query = "CREATE TABLE dbo.TestTable(ID INT);INSERT INTO dbo.TestTable(ID) SELECT TOP 200 1 FROM sys.all_columns"
Invoke-DBaQuery -SqlInstance 'localhost,15999' -Database 'DatabaseC' -SqlCredential $Cred -Query $Query



# query the test table
Invoke-DBaQuery -SqlInstance 'localhost,15999' -Database 'DatabaseC' -SqlCredential $Cred `
-Query  "SELECT COUNT(*) AS Records FROM dbo.TestTable"



# blow away container
docker kill testcontainer3
docker rm testcontainer3



# check that named volume is still there
docker volume ls



# spin up another container
docker container run -d -p 16100:1433 `
--volume mssqlsystem:/var/opt/mssql `
--volume mssqluser:/var/opt/sqlserver `
--env ACCEPT_EULA=Y `
--env SA_PASSWORD=Testing1122 `
--name testcontainer4 `
mcr.microsoft.com/mssql/server:2019-RC1-ubuntu


# verify container is running
docker ps -a



# check database is there
Get-DbaDatabase -SqlInstance 'localhost,16100' -SqlCredential $Cred | Select-Object Name 



# query the test table       
Invoke-DbaQuery -SqlInstance 'localhost,16100' -Database 'DatabaseC' -SqlCredential $Cred `
-Query "SELECT COUNT(*) AS Records FROM dbo.TestTable"



# clean up
docker kill testcontainer4
docker rm testcontainer4
docker volume rm mssqlsystem mssqluser

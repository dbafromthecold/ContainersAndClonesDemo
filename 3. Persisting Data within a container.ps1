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
docker volume prune



# create the named volume
docker volume create sqlserver


# verify named volume is there
docker volume ls


# spin up a container with named volume mapped
docker run -d -p 15999:1433 `
    -v sqlserver:/sqlserver `
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 `
            --name testcontainer3 `
                mcr.microsoft.com/mssql/server:vNext-CTP2.0-ubuntu



# check the container is running
docker ps -a  



# create database on the named volume
Invoke-Sqlcmd2 -ServerInstance 'localhost,15999' `
    -Credential $Cred `
        -Query "CREATE DATABASE [DatabaseC]
                ON PRIMARY
                    (NAME = N'DatabaseC', FILENAME = N'/sqlserver/DatabaseC.mdf')
                LOG ON
                    (NAME = N'DatabaseC_log', FILENAME = N'/sqlserver/DatabaseC_log.ldf')"

                

# check database is there
Get-DbaDatabase -SqlInstance 'localhost,15999' -SqlCredential $Cred `
    | Select-Object Name                         



# create a test table and insert some data
$db = Get-DbaDatabase -SqlInstance 'localhost,15999' -Database 'DatabaseC' -SqlCredential $Cred
    $db.Query("CREATE TABLE dbo.TestTable(ID INT);")
        $db.Query("INSERT INTO dbo.TestTable(ID) SELECT TOP 200 1 FROM sys.all_columns")



# query the test table
$db = Get-DbaDatabase -SqlInstance 'localhost,15999' -Database 'DatabaseC' -SqlCredential $Cred
    $db.Query("SELECT COUNT(*) AS Records FROM dbo.TestTable")



# blow away container
docker kill testcontainer3
docker rm testcontainer3



# check that named volume is still there
docker volume ls



# spin up another container
docker run -d -p 16100:1433 `
    -v sqlserver:/sqlserver `
        --env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 `
            --name testcontainer4 `
                mcr.microsoft.com/mssql/server:vNext-CTP2.0-ubuntu



# verify container is running
docker ps -a



# now attach the database
$fileStructure = New-Object System.Collections.Specialized.StringCollection
    $fileStructure.Add('/sqlserver/DatabaseC.mdf')
    $filestructure.Add('/sqlserver/DatabaseC_log.ldf')

Mount-DbaDatabase -SqlInstance "localhost,16100" `
    -Database DatabaseC -SqlCredential $Cred `
        -FileStructure $fileStructure



# check database is there
Get-DbaDatabase -SqlInstance 'localhost,16100' -SqlCredential $Cred `
    | Select-Object Name 



# query the test table       
$db = Get-DbaDatabase -SqlInstance 'localhost,16100' -Database 'DatabaseC' -SqlCredential $Cred
    $db.Query("SELECT COUNT(*) AS Records FROM dbo.TestTable") 



# clean up
docker kill testcontainer4
docker rm testcontainer4
docker volume rm sqlserver

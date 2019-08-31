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

# https://dbafromthecold.com/2016/11/16/sql-server-containers-part-one/


# verify docker service is running
Get-Service *docker*



# verify docker is responding to commands
docker version



# search for an image on the docker hub
docker search microsoft/mssql



# view the image tags in the MCR
$repo = invoke-webrequest https://mcr.microsoft.com/v2/mssql/server/tags/list -UseBasicParsing
$repo.content



# pull image down to local repository
docker pull mcr.microsoft.com/mssql/server:2019-RC1-ubuntu



# verify image is in repository
docker images



# run a container
docker run -d -p 15111:1433 `
    --env ACCEPT_EULA=Y `
        --env SA_PASSWORD=Testing1122 `
            --name testcontainer1 `
                mcr.microsoft.com/mssql/server:2019-RC1-ubuntu



# verify container is running
docker ps -a



# cool! container is running. Checking the logs...
docker logs testcontainer1



# check version of SQL
Connect-DbaInstance -SqlInstance 'localhost,15111' -SqlCredential $cred `
    | Select-Object Product, HostDistribution, HostPlatform, Version



# copy a backup file into the container
$filepath = "C:\Git\dbafromthecold\ContainersAndClonesDemo\DatabaseBackup"
docker cp $filepath\DatabaseA.bak testcontainer1:'/var/opt/mssql/data/'


 
# exec into container
docker exec -it testcontainer1 bash



# navigate to copied file location
cd /var/opt/mssql/data



# view files
ls -al



# exit container
exit



# restore database in container
Restore-DbaDatabase -SqlInstance 'localhost,15111' `
    -SqlCredential $cred `
        -Path '/var/opt/mssql/data/DatabaseA.bak' `
            -DestinationDataDirectory '/var/opt/mssql/data/' `
                -DestinationLogDirectory '/var/opt/mssql/log'

            

# check databases in container
Get-DbaDatabase -SqlInstance 'localhost,15111' -SqlCredential $Cred `
    | Select-Object Name  



# stats on container usage
docker stats



# clean up
docker kill testcontainer1
docker rm testcontainer1


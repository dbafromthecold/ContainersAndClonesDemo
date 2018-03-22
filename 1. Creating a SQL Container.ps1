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


Get-StoredCredential -Target "SqlDocker"

# https://dbafromthecold.com/2016/11/16/sql-server-containers-part-one/


# verify docker service is running
Get-Service *docker*



# verify docker is responding to commands
docker version



# search for an image on the docker hub
docker search microsoft/mssql



# pull image down to local repository
docker pull microsoft/mssql-server-linux:latest



# verify image is in repository
docker images



# run another container, accepting the EULA
docker run -d -p 15111:1433 `
    --env ACCEPT_EULA=Y `
        --env SA_PASSWORD=Testing1122 `
            --name testcontainer1 `
                microsoft/mssql-server-linux:latest



# verify container is running
docker ps -a



# cool! container is running. Checking the logs...
docker logs testcontainer1



# check version of SQL
Connect-DbaInstance -SqlInstance 'localhost,15111' -Credential $cred `
    | Select-Object Product, HostDistribution, HostPlatform, Version




# let's have a look within the container
docker exec -it testcontainer1 bash



# copy a backup file into the container
$filepath = "C:\Git\PrivateCodeRepo\ContainerDemos\DatabaseBackup"
docker cp $filepath\DatabaseA.bak `
        testcontainer1:'/var/opt/mssql/data/'


 
# check that the backup file is there
docker exec -it testcontainer1 bash



# restore database in container
Restore-DbaDatabase -SqlInstance 'localhost,15111' `
    -SqlCredential $cred `
        -Path '/var/opt/mssql/data/DatabaseA.bak' `
            -DestinationDataDirectory '/var/opt/mssql/data/' `
                -DestinationLogDirectory '/var/opt/mssql/log'

            

# check databases in container
Get-DbaDatabase -SqlInstance 'localhost,15111' -SqlCredential $Cred `
    | Select-Object Name  



# have a look at the system stats
docker system df --verbose



# stats on container usage
docker stats



# clean up
docker kill testcontainer1
docker rm testcontainer1


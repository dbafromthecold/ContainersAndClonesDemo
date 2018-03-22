# Pre-requisites
Install-Module CredentialManager -Force
Install-Module dbatools -Force
Install-Module sqlserver -Force

Import-Module CredentialManager
Import-Module dbatools
Import-Module sqlserver 

Get-Module 

Set-Location C:\


# set credentials to connect to SQL instances
$cred = Get-StoredCredential -Target "SqlDocker"

if (!$cred){
    New-StoredCredential -Target "SqlDocker" -UserName "sa" -Password "Testing1122" -Persist LocalMachine
}


# https://dbafromthecold.com/2017/02/08/sql-container-from-dockerfile/


# check local repository
docker images



# check image is in local repository
docker images



# build another custom image from second dockerfile
docker build -t testimage1 `
    "C:\Git\PrivateCodeRepo\ContainerDemos\Dockerfiles\Dockerfile2"



# verify new custom image is in local repository
docker images



# run container from second custom image
docker run -d -p 15666:15666 `
    --name testcontainer2 testimage1



# verify new container is running    
docker ps -a



# check databases in container
$srv = Connect-DbaInstance 'localhost,15666' -Credential $cred
    $srv.Databases



# check version of SQL
$srv = Connect-DbaInstance 'localhost,15666' -Credential $cred
    $srv.Information
    $srv.Edition
    $srv.HostDistribution
    $srv.HostPlatform
    $srv.Version



# clean up
docker kill testcontainer2
docker rm testcontainer2

docker rmi testimage1



# import required powershell modules
import-module dbatools
import-module psframework
import-module psdatabaseclone



# create credential
$cred = Get-Credential  



# create image
New-PSDCImage -SourceSqlInstance Windows10-Jump -DestinationSqlInstance Windows10-Jump `
 -ImageNetworkPath \\windows10-Jump\C$\clones -Database testdatabase -CreateFullBackup `
 -SourceSqlCredential $cred -DestinationSqlCredential $cred



# create clone
New-PSDCClone -SqlInstance Windows10-Jump -CloneName testdatabase_clone -Database testdatabase -LatestImage -SqlCredential $cred



# connect to local instance
mssql-cli -S Windows10-Jump -U sa



# detach database
EXEC master.dbo.sp_detach_db @dbname = N'testdatabase_clone';



# exit SQL
exit



# spin up container with clone files location
docker run -d -p 15789:1433 `
--env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 `
-v C:\sqlserver\clone:/opt/sqlserver `
--name testcontainer1 `
mcr.microsoft.com/mssql/server:2019-RC1-ubuntu



# reattach the database
$fileStructure = New-Object System.Collections.Specialized.StringCollection
    $fileStructure.Add('/opt/sqlserver/testdatabase_clone_tsCzJ/data/testdatabase.mdf')
    $filestructure.Add('/opt/sqlserver/testdatabase_clone_tsCzJ/log/testdatabase_log.ldf')

Mount-DbaDatabase -SqlInstance "localhost,15789" `
    -Database testdatabase -SqlCredential $Cred `
        -FileStructure $fileStructure
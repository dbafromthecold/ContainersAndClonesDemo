

# import required powershell modules
import-module dbatools
import-module psframework
import-module psdatabaseclone



# create credential
$cred = Get-Credential  


# set database name
$Database = "testdatabase4"


# create image
New-PSDCImage -SourceSqlInstance Windows10-Jump -DestinationSqlInstance Windows10-Jump `
 -ImageNetworkPath \\windows10-Jump\C$\clones -Database $Database4 -CreateFullBackup `
 -SourceSqlCredential $cred -DestinationSqlCredential $cred



# create clone
$clone = New-PSDCClone -SqlInstance Windows10-Jump -CloneName "$($Database)_clone" -Database $Database -LatestImage -SqlCredential $cred



# detach database
$Query = "EXEC sp_detach_db @dbname = N'$Database'"
Invoke-DBaQuery -SqlInstance 'Windows10-Jump' -Database 'master' -SqlCredential $Cred -Query $Query



# set permissions
$folder = $clone.AccessPath

$files = Get-ChildItem $folder -Recurse -File

foreach($file in $files){

    $FullPath = $File.FullName

    # set owner
    $ACL = Get-ACL $FullPath
    $Group = New-Object System.Security.Principal.NTAccount("andrew.pruski")
    $ACL.SetOwner($Group)
    Set-Acl -Path $FullPath -AclObject $ACL

    # set file permissions
    $arguments = @("EVERYONE","FullControl", "Allow")
    $Acl2 = Get-Acl $FullPath
    $Ar = New-Object system.security.accesscontrol.filesystemaccessrule($arguments)
    $Acl2.SetAccessRule($Ar)
    Set-Acl $FullPath $Acl2
}


# spin up container with clone files location
docker run -d -p 15789:1433 `
--env ACCEPT_EULA=Y --env SA_PASSWORD=Testing1122 `
-v C:\sqlserver\clone:/opt/sqlserver `
--name testcontainer1 `
mcr.microsoft.com/mssql/server:2019-RC1-ubuntu



# reattach the database
$a = $folder.LastIndexOf('\') + 1
$b = $folder.Length - $a

$CloneLocation = $folder.Substring($a,$b)

$DataPath = "/opt/sqlserver/$CloneLocation/data/$Database.mdf"
$LogPath = "/opt/sqlserver/$CloneLocation/log/$Database_log.ldf"

$fileStructure = New-Object System.Collections.Specialized.StringCollection
    $fileStructure.Add($DataPath)
    $filestructure.Add($LogPath)

Mount-DbaDatabase -SqlInstance "localhost,15789" `
    -Database testdatabase -SqlCredential $Cred `
        -FileStructure $fileStructure

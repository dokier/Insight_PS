<#
 .Synopsis
  Finds if SQL Instance exists on Instances Table

 .Description
  Finds if SQL Instance exists on Instances Table. This function queries Instances table on Insight database

 .Parameter Name
  Instance Name

 .Example
   # Serch for Instances with the name like 'SQLServer'
   Find-InsightInstance -Name 'SQLServer'
#>
function Refresh-CMS {

$Cred = Get-StoredCredential -Target "Insight_DS"
$Cred.Password.MakeReadOnly()
$SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username, $Cred.password)

$script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

$SQLQuery = "exec GenerateCmsList"
$SQLConnection = New-Object System.Data.SqlClient.SqlConnection

$config = Get-Content -Path $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
$SQLConnection.ConnectionString = $config.settings.dbconnection
$SQLConnection.Credential = $SQLCred
$SQLCmd = New-Object System.Data.SqlClient.SqlCommand
$SQLCmd.CommandText = $SQLQuery
$SQLCmd.Connection = $SQLConnection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
[void]$SqlAdapter.Fill($DataSet)
[void]$SQLConnection.Close
 
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.RegisteredServers")
 
$cmserver = $config.settings.cmsserver
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $cmserver
$cmstore = new-object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServersStore($server.ConnectionContext.SqlConnectionObject)
$dbstore = $cmstore.DatabaseEngineServerGroup
 
#$servers = Import-Csv -Path $csvfile
 
foreach($row in $DataSet.Tables[0].Rows)
{
   $servername = $row.servername
   $groupname = $row.groupname
   $regservername = $row.servername
   #$regserverdescription = $newcmserver.regserverdescription
   
   #if ($regservername -eq $null) { $regservername = $servername }
   
   if ($null -ne $groupname)
   { 
 $grouplist = $groupname.Split("\")
 $groupstore = $dbstore
 
 # Traverse down, creating groups as you go.
 foreach ($group in $grouplist) {
 $groupobject = $groupstore.ServerGroups[$group]
 if ($null -eq $groupobject) {
 Write-Warning "Creating group $group"
 $newgroup = New-Object Microsoft.SqlServer.Management.RegisteredServers.ServerGroup($groupstore, $group)
 $newgroup.create()
 $groupstore.refresh()
 }
 $groupstore = $groupstore.ServerGroups[$group]
 } 
   }
   
   if($groupstore.RegisteredServers.name -notcontains $regservername)
      {
           Write-Host "Adding Server $servername"
           $newserver = New-Object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServer($groupstore, $regservername)
           $newserver.ServerName = $servername
    #$newserver.Description = $regserverdescription
           $newserver.Create()
    Write-Host "Added Server $servername" -ForegroundColor Green
      }
      else
      {
            Write-Warning "Server $servername already exists. Skipped"
      }
}

}

Export-ModuleMember -Function Refresh-CMS
<#
 .Synopsis
  Drops CMS Root Folder

 .Description
  Drops CMS Root Folder

 .Parameter Name
  None

 .Example
   # Drop CMS Root Folder
   Drop-CMS
#>
function Drop-CMS {

$script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName
$config = Get-Content -Path $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
$cmserver = $config.settings.cmsserver
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.RegisteredServers')
 
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $cmserver
$store = new-object Microsoft.SqlServer.Management.RegisteredServers.RegisteredServersStore($server.ConnectionContext.SqlConnectionObject)
 
$registeredServers = $store.DatabaseEngineServerGroup.RegisteredServers
foreach ($server in $registeredServers) {
 $registeredServers.refresh()
 Write-Warning "Dropping server $($server.name)"
 $server.drop()
}
 
$groups = $store.DatabaseEngineServerGroup.ServerGroups
foreach ($group in $groups) {
$groups.refresh()
 Write-Warning "Dropping group $($group.name)"
 $group.drop()
}

    }
    
    Export-ModuleMember -Function Drop-CMS

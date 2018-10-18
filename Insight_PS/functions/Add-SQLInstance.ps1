<#
 .Synopsis
  Add Instance to Instances table

 .Description
  Add Instance to Instances table. This function add a new entry on the Instances table

 .Parameter Name
  Instance Name

 .Parameter Env
  Environment

 .Example
   # Disables Instance with the name like 'SQLServer'
   Add-InsightInstance -Name 'SQLServer' -Env 'DEV"
#>
function Add-SQLInstance {
    #---------------------------------------------------------[Parameters]------------------------------------------------------------
    param(
        [Parameter(Mandatory = $true)]
        [string] $Name,
        [Parameter(Mandatory = $true)]
        [ValidateSet("DEV", "TST", "STG", "PRD")]
        [string] $Env
        )

    #---------------------------------------------------------[Initializations]-------------------------------------------------------
    $Today = Get-Date
    $BotMessage = "Added on $Today by BenderBot - "

    $script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

    $Cred = Get-StoredCredential -Target "Insight_DS"
    $Cred.Password.MakeReadOnly()
    $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username,$Cred.password)

    $SQLQuery = "INSERT INTO Instances Values ('$Name','$Env', 1, 'N/A','$BotMessage')"
    $SQLConnection = New-Object System.Data.SqlClient.SqlConnection
    
    $config = Get-Content -Path $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
    $SQLConnection.ConnectionString = $config.settings.dbconnection
    $SQLConnection.Credential = $SQLCred
    $SQLConnection.Open()
    $SQLCmd = New-Object System.Data.SqlClient.SqlCommand
    $SQLCmd.CommandText = $SQLQuery
    $SQLCmd.Connection = $SQLConnection
    $rowsAffected = $SQLCmd.ExecuteNonQuery()
    [void]$SQLConnection.Close()

    If ($rowsAffected -ne 0) { Write-Host "Instance added successfully"} else {Write-Host "Something went wrong - Could not add the Instance"}
}

Export-ModuleMember -Function Add-SQLInstance
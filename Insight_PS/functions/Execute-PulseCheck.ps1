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
function Execute-PulseCheck {
    #---------------------------------------------------------[Parameters]------------------------------------------------------------

    param([Parameter(Mandatory = $true)][string] $Environment)

    #---------------------------------------------------------[Initializations]-------------------------------------------------------

    $Cred = Get-StoredCredential -Target "Insight_DS"
    $Cred.Password.MakeReadOnly()
    $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username, $Cred.password)

    $script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

    $SQLQuery = "SELECT Name, Environment FROM Instances WHERE Active = 1 and Environment like '%$Environment%'"
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

    if ($DataSet.Tables[0].Rows.Count -gt 0) {
        $aResults = @()
        $aFailedResuts = @()

        foreach ($row in $DataSet.Tables[0].Rows) {
            try{
                $Cred = Get-StoredCredential -Target "SQLAdmin"
                $Cred.Password.MakeReadOnly()
                $SQLConnection = New-Object System.Data.SqlClient.SqlConnection
                $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username, $Cred.password)
                $SQLConnection.ConnectionString = "Server = $($row.Name)"
                $SQLConnection.Credential = $SQLCred
                $SQLConnection.Open()
                [void]$SQLConnection.Close()
                $Status = "Success"
            }
            catch{
                $Status = "Failed"
            }
            $objectDetails = [PSCustomObject]@{
            Name        = "$($row.Name)"
            Environment = "$($row.Environment)"
            Status = $Status
            }
            $aResults += $objectDetails
        }

        $aResults | Format-Table -AutoSize 
    }
    else {Write-Host "Environment: [$Environment] not found" -AsCode}
}

Export-ModuleMember -Function Execute-PulseCheck
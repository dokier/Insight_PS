<#
 .Synopsis
  Disable Instance from Insight batch process

 .Description
  Disable Instance from Insight batch process. This function sets "Active" value to 0 on Instances table

 .Parameter Name
  Instance Name

 .Example
   # Disables Instance with the name like 'SQLServer'
   Disable-InsightInstance -Name 'SQLServer'
#>
function Disable-SQLInstance {
    #---------------------------------------------------------[Parameters]------------------------------------------------------------
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]] $Name,

        [string] $Comment
    )

    #---------------------------------------------------------[Initializations]-------------------------------------------------------
    #region Initialization code
    Begin {
        $Today = Get-Date
        $BotMessage = "Disabled on $Today by BenderBot - "
        if ($Comment -eq $null) {$Comment = $BotMessage} else {$Comment = $BotMessage + $Comment}
 
        $script:PSConfigPath = (Get-Item $PSScriptRoot).Parent.FullName

        $Cred = Get-StoredCredential -Target "Insight_DS"
        $Cred.Password.MakeReadOnly()
        $SQLCred = New-Object System.Data.SqlClient.SqlCredential($Cred.username, $Cred.password)
        $SQLConnection = New-Object System.Data.SqlClient.SqlConnection
    
        $config = Get-Content -Path $script:PSConfigPath\Insight.config.json -Raw | ConvertFrom-Json
        $SQLConnection.ConnectionString = $config.settings.dbconnection
        $SQLConnection.Credential = $SQLCred
        $SQLConnection.Open()
    }
    #endregion Initialization code

    #region Process data
    Process {
        ForEach ($Nm in $Name) {
            $SQLCmd = New-Object System.Data.SqlClient.SqlCommand
            $SQLQuery = "UPDATE Instances SET Active = 0, Comments = '$Comment' WHERE Name = '$Nm'"
            $SQLCmd.CommandText = $SQLQuery
            $SQLCmd.Connection = $SQLConnection
            $rowsAffected = $SQLCmd.ExecuteNonQuery()
            If ($rowsAffected -ne 0) { Write-Host "Instance $Nm disabled successfully"} else {Write-Host "Instance could not be found"}
        }
    }
    #endregion Process data

    #region Finalize everything 
    End {  
        [void]$SQLConnection.Close()
    }
    #endregion Finalize everything  
}

Export-ModuleMember -Function Disable-SQLInstance
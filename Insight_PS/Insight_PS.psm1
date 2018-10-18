 # All exported functions
$script:PSModuleRoot = $PSScriptRoot
Get-ChildItem -Path $script:PSModuleRoot\functions\*.ps1 | Foreach-Object{ . $_.FullName } 
Export-ModuleMember -Function * -Alias *
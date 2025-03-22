# This file was used to register autocomplete options.
# I realized a menu would be a better experience so I threw this away.

$ConfigFile = ((Get-Content -Path "$PSScriptRoot/config.json") | ConvertFrom-Json).Actions.FunctionGroups

Write-Host $ConfigFile

foreach ($ActionType in $ConfigFile.PSObject.Properties) {

    Write-host $ActionType.Name
    Write-host $ActionType.Value

    Register-ArgumentCompleter -CommandName $ActionType.Name -ParameterName Parameter -ScriptBlock {

        foreach ($Parameter in $ConfigFile.$ActionType.Value.Parameters.PSObject.Properties) {
            New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @(
                $Parameter.Name
                $Parameter.Name
                'ParameterValue'
                $Parameter.Name
            )
        }
    }.GetNewClosure()
}

Remove-Variable -Name ConfigFile
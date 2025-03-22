# This script was used to create and export functions based on a configuration file.

[PSObject]$Config = Use-Config
[Array]$Actions = @()

foreach ($Group in $Config.Data.Actions.FunctionGroups.PSObject.Properties) {

    #Create the functions defined in config.json.
    $ScriptBlock = {
        param(
            [string]$PathKey
        )

        $Group = $Config.Data.Actions.FunctionGroups.($MyInvocation.MyCommand.Name)
        $ParameterKey = if ($PathKey) { $Pathkey } else { (Read-Menu -MenuArray ($Group.Parameters.PSObject.Properties.Name)) }
        $Parameter = $Group.Parameters.$ParameterKey
                
        if (-not $Parameter) {
            Write-Host "Key not found."
            return
        }
                
        Invoke-Expression $Group.Function
    }

    New-Item -Path "Function:Global:$($Group.Name)" -Value $ScriptBlock

    if ($Group.Value.Description) {
        $Actions += [PSCustomObject]@{
            Name        = $Group.Name
            Description = $Group.Value.Description
        }    
    }
}

if ($Actions.Count) {
    New-Item -Path "Function:Global:Actions" -Value {
        Write-Host
        foreach ($ActionType in $Actions) {
            Write-Host "$($ActionType.Name):" $ActionType.Description
        }
        Write-Host
    }
}

Export-ModuleMember Actions
Import-Module PUM-Utils

[PSObject]$Config = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json -Depth 7
[array]$Actions = @()

foreach ($Group in $Config.Actions.FunctionGroups.PSObject.Properties) {

    #Create the functions defined in config.json.
    Set-Content -Path "Function:Global:$($Group.Name)" -Value {
        param([string]$PathKey)

        $Group = $Config.Actions.FunctionGroups.($MyInvocation.MyCommand.Name)

        $ParameterKey = (!!$PathKey ? $PathKey : (Read-Menu -MenuArray ($Group.Parameters.PSObject.Properties.Name)))

        $Parameter = $Group.Parameters.$ParameterKey
                
        if (!$Parameter) {
            Write-Host "Key not found."
            return
        }
                
        Invoke-Expression $Group.Function
    }

    if ($Group.Value.Description) {
        $Actions += [PSObject]@{"Name" = $Group.Name; "Description" = "$($Group.Value.Description)" }
    }
}

if ($Actions) {
    Set-Item -Path "Function:Global:Actions" -Value {
        Write-Host
        foreach ($ActionType in $Actions) {
            Write-Host "$($ActionType.Name):" $ActionType.Description
        }
        Write-Host
    }
}

Export-ModuleMember Actions, Edit, Folder, Run, Terminal, Web
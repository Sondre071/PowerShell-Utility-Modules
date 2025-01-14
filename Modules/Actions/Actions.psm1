Import-Module PUM-Utils

class ActionsManager {

    [PSObject] $Config
    [array] $Actions = @()

    ActionsManager() {

        $this.Config = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json -Depth 7

        foreach ($Group in $this.Config.Actions.FunctionGroups.PSObject.Properties) {

            #Create the functions defined in config.json.
            Set-Content -Path "Function:Global:$($Group.Name)" -Value {
                param([string]$PathKey)

                $Group = $ActionsInstance.Config.Actions.FunctionGroups.($MyInvocation.MyCommand.Name)

                $ParameterKey = (!!$PathKey ? $PathKey : (Read-Menu -MenuArray ($Group.Parameters.PSObject.Properties.Name)))

                $Parameter = $Group.Parameters.$ParameterKey
                
                if (!$Parameter) {
                    Write-Host "Key not found."
                    return
                }
                
                Invoke-Expression $Group.Function
            }

            if ($Group.Value.Description) {
                $this.Actions += [PSObject]@{"Name" = $Group.Name; "Description" = "$($Group.Value.Description)" }
            }
        }

        if ($this.Actions) {
            Set-Item -Path "Function:Global:Actions" -Value {
                Write-Host
                foreach ($ActionType in $ActionsInstance.Actions) {
                    Write-Host "$($ActionType.Name):" $ActionType.Description
                }
                Write-Host
            }
        }
    }
}

$ActionsInstance = [ActionsManager]::new()

Export-ModuleMember Actions, Edit, Folder, Run, Terminal, Web
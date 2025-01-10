class ActionsManager {

    [PSObject] $Config
    [array] $Actions = @()

    ActionsManager() {
        
        $this.Config = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json -Depth 7

        foreach ($Group in $this.Config.Actions.FunctionGroups.PSObject.Properties) {

            #Create the functions defined in config.json
            Set-Content -Path "Function:Global:$($Group.Name)" -Value {
                param([string]$PathKey)

                $GroupName = $MyInvocation.MyCommand.Name
                $Group = $ActionsInstance.Config.Actions.FunctionGroups.$GroupName

                $FunctionValue = $Group.Function

                $Parameter = $Group.Parameters.$PathKey

                if (!$PathKey) {
                    $ActionsInstance.ListKeys($GroupName)
                    return
                }
                
                if (!$Parameter) {
                    Write-Host "`nKey not found.`n"
                    return
                }
                
                Invoke-Expression $FunctionValue

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

    [void] ListKeys($GroupName) {
        $GroupParameters = $this.Config.Actions.FunctionGroups.$GroupName.Parameters
        
        Write-Host
        foreach ($Parameter in $GroupParameters.PSObject.Properties) {
            Write-Host $Parameter.Name
        }

        Write-Host
    }
}

$ActionsInstance = [ActionsManager]::new()

Export-ModuleMember Actions, Edit, Folder, Run, Terminal, Web
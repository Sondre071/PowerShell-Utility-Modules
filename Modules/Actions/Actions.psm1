class ActionsManager {

    [PSObject]$Config
    [array]$Actions = @()

    ActionsManager() {
        
        $this.Config = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json -Depth 7

        foreach ($Group in $this.Config.Actions.FunctionGroups.PSObject.Properties) {

            Set-Content -Path "Function:Global:$($Group.Name)" -Value {
                param([string]$PathKey)

                $GroupName = $MyInvocation.MyCommand.Name
                $Group = $ActionsInstance.Config.Actions.FunctionGroups.$GroupName
                $FunctionValue = $Group.Function

                $Path = $Group.Parameters.$PathKey

                if (!$Path) {
                    Write-Host "`nKey not found.`n"
                    return
                }

                Invoke-Expression $FunctionValue
            }

            if ($Group.Value.Description) {
                $this.Actions += [PSObject]@{"Name" = $Group.Name; "Description" = "$($Group.Value.Description)"}
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

        # Necessary to maintain access within the function scope
        $ThisClass = $this

        # foreach ($ActionType in $this.Actions) {

        #     Register-ArgumentCompleter -CommandName $ActionType.Name -ParameterName Path -ScriptBlock {

        #         foreach ($Parameter in $ThisClass.Config.Actions.Paths.($ActionType.Name).PSObject.Properties) {
        #             New-Object -TypeName System.Management.Automation.CompletionResult -ArgumentList @(
        #                 $Parameter.Name
        #                 $Parameter.Name
        #                 'ParameterValue'
        #                 $Parameter.Name
        #             )
        #         }
        #     }.GetNewClosure()
        # }
    }
}

$ActionsInstance = [ActionsManager]::new()

Export-ModuleMember Actions, Edit, Folder, Run, Terminal, Web
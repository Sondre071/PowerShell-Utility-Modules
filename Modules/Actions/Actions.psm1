class ActionsManager {
    [PSObject]$Config
    [array]$Actions = @()

    ActionsManager() {
        $this.Config = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json

        if ($null -ne $this.Config.Actions.Edit) {
            Set-Item -Path "Function:Global:Edit" -Value {
                param ([string]$Path)

                if ($ActionsInstance.PathExists('Edit', $Path)) {
                    code $ActionsInstance.Config.Actions.Edit.$Path
                }
            }
            $this.Actions += [PSObject]@{"Name" = "Edit"; "Description" = "Edit directory in VSCode." }
        }
        if ($null -ne $this.Config.Actions.Folder) {
            Set-Item -Path "Function:Global:Folder" -Value {
                param ([string]$Path)

                if ($ActionsInstance.PathExists('Folder', $Path)) {
                    $TotalPath = $ActionsInstance.Config.Actions.Folder.$Path
                    explorer ($TotalPath -replace '/', '\')
                }
            }
            $this.Actions += [PSObject]@{"Name" = "Folder"; "Description" = "Open directory in explorer." }
        }
        if ($null -ne $this.Config.Actions.Run) {
            Set-Item -Path "Function:Global:Run" -Value {
                param ([string]$Path)

                if ($ActionsInstance.PathExists('Run', $Path)) {
                    & $ActionsInstance.Config.Actions.Run.$Path
                }
            }
            $this.Actions += [PSObject]@{"Name" = "Run"; "Description" = "Run file." }
        }

        if ($null -ne $this.Config.Actions.Terminal) {
            Set-Item -Path "Function:Global:Terminal" -Value { 
                param ([string]$Path)

                if ($ActionsInstance.PathExists('Terminal', $Path)) {    
                    $TotalPath = $ActionsInstance.Config.Actions.Terminal.$Path
                    Set-Location $TotalPath
                }
            }
            $this.Actions += [PSObject]@{"Name" = "Terminal"; "Description" = "Change to directory location." }
        }

        if ($null -ne $this.Config.Actions.Web -and $null -ne $this.Config.BrowserUrl) {
            Set-Item -Path "Function:Global:Web" -Value {
                param ([string]$Path)

                if ($ActionsInstance.PathExists('Web', $Path)) {
                    
                    Start-Process -FilePath "`"$($ActionsInstance.Config.BrowserUrl)`"" -ArgumentList "`"$($ActionsInstance.Config.Actions.Web.$Path)`""
                }
            }
            $this.Actions += [PSObject]@{"Name" = "Web"; "Description" = "Open link in the browser." }
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

    [boolean]PathExists($ActionType, $Path) {
        $PathBool = $this.Config.Actions.$ActionType.$Path

        if (!$PathBool) {
            Write-Host `nKey not found.`n
            return $false
        }

        return $true
    }

    [void]ListActions() {
        Write-Host
        foreach ($ActionType in $this.Actions) {
            Write-Host "$($ActionType.Name):" $ActionType.Description
        }
        Write-Host
    }
}

$ActionsInstance = [ActionsManager]::new()

Export-ModuleMember Actions, Edit, Folder, Run, Terminal, Web
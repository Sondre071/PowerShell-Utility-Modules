[PSObject]$Config = (Use-Config).Data.Folder

function Folder($Parameter) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."`n
        return
    }

    $PathKey = if ($Parameter) { $Parameter } else { (Read-Menu -Options ($Config.Paths.PSObject.Properties.Name) -WithExit) }

    if (-not $PathKey) {
        Write-Host "Key not found."`n
        return
    }

    if ($PathKey -eq 'Exit') {
        Write-Host
        return
    }

    $Path = $Config.Paths.$PathKey

    Write-Host

    explorer ($Path -replace '/', '\')
}

Export-ModuleMember -Function Folder
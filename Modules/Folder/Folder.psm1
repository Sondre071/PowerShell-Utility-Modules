[PSObject]$Config = (Use-Config).Data.Folder

function Folder($PathKey) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."
        return
    }

    $ConfigKey = if ($PathKey) { $PathKey } else { (Read-Menu -MenuArray ($Config.Paths.PSObject.Properties.Name)) }

    if (-not $ConfigKey) {
        Write-Host "Key not found."
        return
    }

    $Path = $Config.Paths.$ConfigKey

    explorer ($Path -replace '/', '\')
}

Export-ModuleMember -Function Folder
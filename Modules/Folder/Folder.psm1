[PSObject]$Config = (Use-Config).Data.Folder

function Folder($PathKey) {
    $ConfigKey = if ($PathKey) { $PathKey } else { (Read-Menu -MenuArray ($Config.Parameters.PSObject.Properties.Name)) }

    if (-not $ConfigKey) {
        Write-Host "Key not found."
        return
    }

    $Path = $Config.Parameters.$ConfigKey

    explorer ($Path -replace '/', '\')
}

Export-ModuleMember -Function Folder
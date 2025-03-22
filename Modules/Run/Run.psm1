[PSObject]$Config = (Use-Config).Data.Run

function Run($PathKey) {
    if (-not $Config.Parameters.PSObject.Properties.Length) {
        Write-Host "No keys found."
        return
    }

    $ConfigKey = if ($PathKey) { $PathKey } else { (Read-Menu -MenuArray ($Config.Parameters.PSObject.Properties.Name)) }

    if (-not $ConfigKey) {
        Write-Host "Key not found."
        return
    }

    $Path = $Config.Parameters.$ConfigKey

    & $Path
}

Export-ModuleMember -Function Run
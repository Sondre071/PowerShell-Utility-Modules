[PSObject]$Config = (Use-Config).Data.Run

function Run($Parameter) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."
        return
    }

    $PathKey = if ($Parameter) { $Parameter } else { (Read-Menu -Options ($Config.Paths.PSObject.Properties.Name)) }

    if (-not $PathKey) {
        Write-Host "Key not found."
        return
    }

    $Path = $Config.Paths.$PathKey

    & $Path
}

Export-ModuleMember -Function Run
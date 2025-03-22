[PSObject]$Config = (Use-Config).Data.Terminal

function Terminal($Parameter) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."
        return
    }

    $PathKey = if ($Parameter) { $Parameter } else { (Read-Menu -MenuArray ($Config.Paths.PSObject.Properties.Name)) }

    if (-not $PathKey) {
        Write-Host "Key not found."
        return
    }

    $Path = $Config.Paths.$PathKey

    Set-Location $Path
}

Export-ModuleMember -Function Terminal
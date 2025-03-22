[PSObject]$Config = (Use-Config).Data.Web

function Web($Parameter) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."
        return
    }

    $Pathkey = if ($Parameter) { $Parameter } else { (Read-Menu -Options ($Config.Paths.PSObject.Properties.Name)) }

    if (-not $PathKey) {
        Write-Host "Key not found."
        return
    }

    $BrowserPath = $Config.BrowserPath

    if (-not $BrowserPath) {
        Write-Host "Browser path not found."
        return
    }

    $Path = $Config.Paths.$PathKey

    Start-Process -FilePath $BrowserPath -ArgumentList ($Path)
}

Export-ModuleMember -Function Web
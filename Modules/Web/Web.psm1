[PSObject]$Config = (Use-Config).Data.Web

function Web($Parameter) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."`n
        return
    }

    $Pathkey = if ($Parameter) { $Parameter } else { (Read-Menu -Options ($Config.Paths.PSObject.Properties.Name) -WithExit) }

    if (-not $PathKey) {
        Write-Host "Key not found."`n
        return
    }

    if ($PathKey -eq 'Exit') {
        Write-Host
        return
    }

    $BrowserPath = $Config.BrowserPath

    if (-not $BrowserPath) {
        Write-Host "Browser path not found."`n
        return
    }

    $Path = $Config.Paths.$PathKey

    Start-Process -FilePath $BrowserPath -ArgumentList ($Path)
}

Export-ModuleMember -Function Web
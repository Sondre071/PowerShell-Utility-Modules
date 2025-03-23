[PSObject]$Config = (Use-Config).Data.Terminal

function Terminal($Parameter) {
    if (-not $Config.Paths.PSObject.Properties.Length) {
        Write-Host "No keys found."`n
        return
    }

    $PathKey = if ($Parameter) { $Parameter } else { (Read-Menu -Options ($Config.Paths.PSObject.Properties.Name) -WithExit ) }

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

    Set-Location $Path
}

Export-ModuleMember -Function Terminal
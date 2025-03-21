[PSObject]$Config = (Use-Config).Data.Folder

function Folder($Parameter) {
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

    explorer ($Path -replace '/', '\')
}

Export-ModuleMember -Function Folder
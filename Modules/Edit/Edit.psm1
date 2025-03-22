[PSObject]$Config = (Use-Config).Data.Edit

function Edit($PathKey) {
    $ConfigKey = if ($PathKey) { $PathKey } else { (Read-Menu -MenuArray ($Config.Parameters.PSObject.Properties.Name)) }

    if (-not $ConfigKey) {
        Write-Host "Key not found."
        return
    }

    $Path = $Config.Parameters.$ConfigKey

    code ($Path)
}

Export-ModuleMember -Function Edit
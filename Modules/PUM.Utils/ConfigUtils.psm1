function Get-Config {
    param (
        [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json")
    )

    if (-not (Test-Path -Path $ConfigPath)) {
        throw "Config file not found at $ConfigPath"
    }

    try {
        return Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json -Depth 7
    } catch {
        throw "Failed to parse config file: $_"
    }
}

Export-ModuleMember -Function Get-Config
class ModuleConfig {
    [string]$ConfigPath
    [psobject]$Data

    ModuleConfig([string]$path) {
        $this.ConfigPath = $path
        $this.Load()
    }

    [void] Load() {
        if (-not (Test-Path -Path $this.ConfigPath)) {
            throw "Config file not found at $($this.ConfigPath)."
        }

        try {
            $this.Data = Get-Content -Path $this.ConfigPath -Raw | ConvertFrom-Json -Depth 7
        }
        catch {
            throw "Failed to parse config file: $_."
        }
    }
}

function Use-Config() {
    return [ModuleConfig]::new((Join-Path -Path $PSScriptRoot -ChildPath '..\..\config.json'))
}

Export-ModuleMember -Function Use-Config

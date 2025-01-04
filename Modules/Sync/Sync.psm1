function Sync() {
    $UserConfig = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json
}

function RenderMenu() {
    Write-Host "THIS IS A MENU ...."
}

Export-ModuleMember Sync
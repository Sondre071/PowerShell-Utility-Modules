param (
    [Parameter(Mandatory = $True)]
    [string[]]$MenuArray
)

Function Write-Menu($CurrentIndex, $MenuArray, $StartingRow) {
    if ($Null -ne $StartingRow) { [System.Console]::SetCursorPosition(0, $StartingRow) }

    for ($i = 0; $i -lt $MenuArray.Count; $i++) {

        $ForegroundColor = "$($i -eq $CurrentIndex ? 'Yellow' : 'Gray')"
        Write-Host ">  $($MenuArray[$i])" -ForegroundColor $ForegroundColor

    }
}

[System.Console]::CursorVisible = $False

$CurrentIndex = 0
$StartingRow = [System.Console]::CursorTop

Write-Menu -Currentindex $CurrentIndex -MenuArray $MenuArray -StartingRow $StartingRow

While ($True) {
    if ([Console]::KeyAvailable) {
        $KeyPress = (Get-Host).UI.RawUI.ReadKey("NoEcho, IncludeKeyDown").VirtualKeyCode

        Switch ($KeyPress) {
            38 {
                #Up Arrow
                $CurrentIndex = [Math]::Max(0, $CurrentIndex - 1)
                Break
            }
            40 {
                #Down Arrow
                $CurrentIndex = [Math]::Min($MenuArray.Count - 1, $CurrentIndex + 1)
                Break
            }
            13 {
                #Enter - return item
                Return $MenuArray[$CurrentIndex]
            }
        }

        # Re-render menu
        Write-Menu -CurrentIndex $CurrentIndex -MenuArray $MenuArray -StartingRow $StartingRow
    }
}
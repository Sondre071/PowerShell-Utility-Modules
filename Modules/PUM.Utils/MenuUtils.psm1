function Read-Menu {

    param (
        [Parameter(Mandatory = $true)]
        [string[]]$MenuArray
    )

    [System.Console]::CursorVisible = $False

    $CurrentIndex = 0
    $StartingRow = [System.Console]::CursorTop

    while ($true) {
        [System.Console]::SetCursorPosition(0, $StartingRow)

        for ($i = 0; $i -lt $MenuArray.Count; $i++) {
            $ForegroundColor = "$($i -eq $CurrentIndex ? 'Yellow' : 'Gray')"
            Write-Host ">  $($MenuArray[$i])" -ForegroundColor $ForegroundColor
        }

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
                    [System.Console]::CursorVisible = $True
                    Return $MenuArray[$CurrentIndex]
                }
            }
        }
    }
}

Export-ModuleMember -Function Read-Menu
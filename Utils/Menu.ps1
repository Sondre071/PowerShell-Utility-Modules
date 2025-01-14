Function RenderMenu($CurrentIndex, $MenuItems, $StartingRow) {
    [System.Console]::SetCursorPosition(0, $StartingRow)

    for ($i = 0; $i -lt $MenuItems.Count; $i++) {
        Write-Host ">  $($MenuItems[$i])" -ForegroundColor "$($i -eq $CurrentIndex ? 'Yellow' : 'Gray')"
    }
}

Function Menu($MenuList) {
    [System.Console]::CursorVisible = $False

    $CurrentIndex = 0
    $StartingRow = [System.Console]::CursorTop
    $MenuItems = $MenuList

    RenderMenu -Currentindex $CurrentIndex -MenuItems $MenuItems -StartingRow $StartingRow

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
                    $CurrentIndex = [Math]::Min($MenuItems.Count - 1, $CurrentIndex + 1)
                    Break
                }
                13 {
                    #Enter - commit action
                    Return
                }
            }

            # Re-render menu
            RenderMenu -CurrentIndex $CurrentIndex -MenuItems $MenuItems -StartingRow $StartingRow
        }
    }
}
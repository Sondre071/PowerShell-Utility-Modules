function Read-Menu {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$MenuArray,

        # Optional parameter to add an exit option.
        [switch]$WithExit
    )

    $SortedMenuArray = $MenuArray | Sort-Object

    if ($WithExit) {
        $SortedMenuArray += 'Exit'
    }

    [System.Console]::CursorVisible = $False

    $CurrentIndex = 0
    $StartingRow = [System.Console]::CursorTop

    while ($true) {
        for ($i = 0; $i -lt $SortedMenuArray.Count; $i++) {
            $color = if ($i -eq $CurrentIndex) { 'Yellow' } else { 'Gray' }
            Write-Host ">  $($SortedMenuArray[$i])" -ForegroundColor $color
        }

        if ([Console]::KeyAvailable) {
            $keyInfo = [Console]::ReadKey($true)

            switch ($keyInfo.Key) {
                { $_ -in "UpArrow", "K" } {
                    $CurrentIndex = [Math]::Max(0, $CurrentIndex - 1)
                    Break
                }
                { $_ -in "DownArrow", "J" } {
                    $CurrentIndex = [Math]::Min($SortedMenuArray.Count - 1, $CurrentIndex + 1)
                    Break
                }
                { $_ -in "Enter", "L" } {
                    [System.Console]::CursorVisible = $true
                    Return $SortedMenuArray[$CurrentIndex]
                }
                { $_ -in "Escape", "Q" -and $WithExit } {
                    [System.Console]::CursorVisible = $true
                    Return 'Exit'
                }
            }
        }

        $StartingRow = [System.Console]::CursorTop - $SortedMenuArray.Length
        [System.Console]::SetCursorPosition(0, $StartingRow)
    }
}

Export-ModuleMember -Function Read-Menu
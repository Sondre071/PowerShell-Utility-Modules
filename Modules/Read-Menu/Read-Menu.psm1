function Read-Menu {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$MenuArray
    )

    [System.Console]::CursorVisible = $False

    $CurrentIndex = 0
    $StartingRow = [System.Console]::CursorTop

    while ($true) {
        for ($i = 0; $i -lt $MenuArray.Count; $i++) {
            $color = if ($i -eq $CurrentIndex) { 'Yellow' } else { 'Gray' }
            Write-Host ">  $($MenuArray[$i])" -ForegroundColor $color
        }

        if ([Console]::KeyAvailable) {
            $keyInfo = [Console]::ReadKey($true)

            switch ($keyInfo.Key) {
                { $_ -in "UpArrow", "K" } {
                    $CurrentIndex = [Math]::Max(0, $CurrentIndex - 1)
                    Break
                }
                { $_ -in "DownArrow", "J" } {
                    $CurrentIndex = [Math]::Min($MenuArray.Count - 1, $CurrentIndex + 1)
                    Break
                }
                { $_ -in "Enter", "L" } {
                    [System.Console]::CursorVisible = $true
                    Return $MenuArray[$CurrentIndex]
                }
            }
        }

        $StartingRow = [System.Console]::CursorTop - $MenuArray.Length
        [System.Console]::SetCursorPosition(0, $StartingRow)
    }
}

Export-ModuleMember -Function Read-Menu
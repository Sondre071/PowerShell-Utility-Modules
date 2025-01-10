$Menu = @("Hi1", "Hi2", "Hi3", "Hi4", "Hi5")

Function RenderMenu($OldIndex, $Direction) {
    $NewIndex = $OldIndex

    # 38 is up arrow, 40 is down arrow
    if ($Null -ne $Direction) {
        if ($Direction -eq 38) {
            $NewIndex--
        }
        elseif ($Direction -eq 40) {
            $NewIndex++
        }
    }

    for ($i = 1; $i -le $Menu.Count; $i++) {
        if ($NewIndex -eq $i) {
            Write-Host "`t$($Menu[$i])" -ForegroundColor "Yellow"
        }
        else {
            Write-Host "`t$($Menu[$i])"
        }
    }

    $MenuHeight = $Menu.Count

    return @($NewIndex, $MenuHeight)
}

Function Test1() {
    [System.Console]::CursorVisible = $False
    $CurrentIndex, $MenuHeight = RenderMenu -OldIndex 1 -Direction $Null

    While ($True) {
        $KeyPress = $Null
        Do {
            if ([Console]::KeyAvailable) {
                $KeyPress = (Get-Host).UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode
            }
        } While ($Null -eq $KeyPress)

        [System.Console]::SetCursorPosition(0, [Math]::Max(0, [Console]::CursorTop - $MenuHeight))

        $CurrentIndex, $MenuHeight = RenderMenu -OldIndex $CurrentIndex -Direction $KeyPress
    }
}
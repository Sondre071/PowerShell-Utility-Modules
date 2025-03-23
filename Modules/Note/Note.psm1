[PSObject]$Config = Use-Config
[PSObject]$NotesConfig = $Config.Data.Note

$NoteColor = $Config.Data.UserSettings.Colors.Note

function Note($Parameter) {
    if (-not $NotesConfig.Categories.PSObject.Properties.Length) {
        Write-Host "No categories found."
        return
    }

    $CategoryKey = if ($Parameter) { $Parameter } else { Read-Menu -Options ($NotesConfig.Categories.PSObject.Properties.Name) -WithExit }

    if (-not $CategoryKey) {
        Write-Host "Category not found."`n
        return
    }

    if ($CategoryKey -eq 'Exit') {
        Write-Host
        return
    }

    $Category = $NotesConfig.Categories.$CategoryKey

    Write-Host

    $NoteKey = Read-Menu -Options ($Category.PSObject.Properties.Name) -WithExit

    if (-not $NoteKey) {
        Write-Host "Note not found."`n
        return
    }

    if ($NoteKey -eq 'Exit') {
        Write-Host
        return
    }

    $Note = $Category.$NoteKey

    Write-Host

    $Note | ForEach-Object { Write-Host " $($_)" -ForegroundColor $NoteColor }

    Write-Host

    return
}

Export-ModuleMember -Function Note
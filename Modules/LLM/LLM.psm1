Import-Module PMU-Utils

$config = (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json)

$ApiUrl = $config.LLM.ApiUrl
$ApiKey = $config.LLM.ApiKey
$Model = $config.LLM.CurrentModel
$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

Function LLM() {
    Write-Host `n"New session. Type 'info' for more information.`n" -ForegroundColor "Yellow"

    while ($true) {
        $UserInput = Read-Host "You"

        Run($UserInput)
    }
}

Function IsCommand($UserInput) {
    switch ($UserInput) {
        'clear' {
            Clear-Host
            $MessageHistory.Clear()
            Write-Host "`nSession history cleared.`n" -ForegroundColor "Yellow"
            return $True
        }
        'info' {
            Write-Host "`nPress Q to cancel current stream." -ForegroundColor "Yellow"
            Write-Host "Press R to reset and not save to message history." -ForegroundColor "Yellow"
            Write-Host "Type 'clear' to clear chat history." -ForegroundColor "Yellow"
            Write-Host "Type 'model' to add or change models.`n" -ForegroundColor "Yellow"
            return $True
        }
             
        'model' {
            $Config = (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json)

            Write-Host "`nCurrent model is: $($Model)`n" -ForegroundColor "Yellow"

            $NewModelOption = Read-Menu -MenuArray ($Config.LLM.Models + 'Add new model')

            $NewModel = ($NewModelOption -eq 'Add new model') ? (Read-Host "`nAdd new model") : $NewModelOption

            $Model = $NewModel
            $Config.LLM.CurrentModel = $NewModel

            if ($Config.LLM.Models -notcontains $NewModel) {
                $Config.LLM.Models += $NewModel
            }

            Set-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") -Value ($Config | ConvertTo-Json -Depth 7)
                        
            Write-Host "`n$NewModel set as current model.`n" -ForegroundColor "Yellow"

            return $True
        }

    }

    return $False
}

Function Run($UserInput) {
    if (IsCommand($UserInput)) {
        return
    }

    $HttpClient = [System.Net.Http.HttpClient]::new()

    $CurrentMessageHistory = $MessageHistory
    $CurrentMessageHistory += @{
        'role' = 'user'; 'content' = $UserInput
    }

    $Request = [System.Net.Http.HttpRequestMessage]::new()
    $Request.Headers.Add('Authorization', "Bearer $($ApiKey)")
    $Request.Headers.Add('Accept', "application/json")
    $Request.Method = 'POST'
    $Request.RequestUri = $ApiUrl
    $Request.Content = [System.Net.Http.StringContent]::new(
            (@{
            'model'    = $model
            'messages' = $CurrentMessageHistory
            'stream'   = 'true'
        } | ConvertTo-Json),
        [System.Text.Encoding]::UTF8, 'application/json'
    )

    $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
    $CancellationToken = $CancellationTokenSource.Token

    $ResultMessage = $HttpClient.SendAsync($Request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancellationToken).GetAwaiter().GetResult()

    if ($ResultMessage.StatusCode -ne 200) {
        Throw $ResultMessage.StatusCode
    }

    $Stream = $ResultMessage.Content.ReadAsStreamAsync($CancellationToken).GetAwaiter().GetResult()
    $Reader = [System.Io.StreamReader]::new($Stream)

    $ModelResponse = ""

    Write-Host

    # Loop through every line of the stream.
    while (!$Reader.EndOfStream) {

        # If the user presses Q or R, terminates the loop.
        if ([System.Console]::KeyAvailable) {
            $Key = [System.Console]::ReadKey($true)

            if ($Key.Key -eq 'Q' -or $Key.Key -eq 'R') {

                $OutputMessage = "Stream cancelled."

                if ($Key.Key -eq 'R') {
                    $ModelResponse = $null
                    $OutputMessage += " Message history is unchanged."
                }
                    
                $CancellationTokenSource.Cancel()
                $Stream.Close()
                $Reader.Close()
                    
                Write-Host -NoNewLine "`n`n$OutputMessage" -ForegroundColor "Yellow"
                Break
            }
        }
            
        $Line = $Reader.ReadLine()
            
        try {
                
            <# If the message has meaningful content, it's printed and saved.
                If not, such as with SSE streaming comments, it fails during parsing. #>
            $ParsedLine = ($Line.Substring(6) | ConvertFrom-Json).choices.delta.content
                
            Write-Host -NoNewline -ForegroundColor Green $ParsedLine
            $ModelResponse += $ParsedLine
        }
        catch {
            continue
        }
    }

    $Reader.Dispose()
    $Stream.Dispose()
    $HttpClient.Dispose()

    Write-Host `n

    # Message history stays the same if model returnes nothing, or if user resets the current stream.
    if ($null -ne $ModelResponse) {
        $MessageHistory.Add([PSObject]@{
                'role' = 'user'; 'content' = $UserInput
            })
        $MessageHistory.Add([PSObject]@{
                'role' = 'assistant'; 'content' = $ModelResponse
            })
    }
}

Export-ModuleMember LLM

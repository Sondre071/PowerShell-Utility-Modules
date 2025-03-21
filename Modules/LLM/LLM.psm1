Import-Module PUM.Utils
Import-Module "$PSScriptRoot\..\PUM.Utils\ConfigUtils.psm1" -Function Get-Config

$Config = Get-Config
$ApiKey = $Config.LLM.ApiKey
$ApiUrl = $Config.LLM.ApiUrl
$Model = $Config.LLM.CurrentModel
$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

Function LLM() {
    $Option = Read-Menu -MenuArray @('New session', 'Info', 'Model')

    switch ($Option) {
        'New session' {

            $MessageHistory.Clear()

            While ($True) {
                $UserInput = Read-Host "You"

                $HttpClient = [System.Net.Http.HttpClient]::new()

                $Stream = SendRequest -HttpClient $HttpClient -UserInput $UserInput

                $ModelResponse = StreamResponse($Stream)

                SaveToMessageHistory($ModelResponse)
            }

            Break;
        }
        'Info' {
            Write-Host "Press Q to stop the current response.`nPress R to stop and not save the current response to message history." -ForegroundColor "Yellow"

            Break;
        }
        'Model' {
            Write-Host "yeah..."
            Break;
        }
    }
}

Function SendRequest() {
    param(
        [System.Net.Http.HttpClient]$HttpClient,
        [string]$UserInput
    )

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

    return $Stream
}

Function StreamResponse($Stream) {
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

    Write-Host `n

    $Reader.Dispose()
    $Stream.Dispose()
    $HttpClient.Dispose()

    return $ModelResponse
}

Function SaveToMessageHistory($ModelResponse) {

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

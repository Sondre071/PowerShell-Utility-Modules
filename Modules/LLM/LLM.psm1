class LLM {

    hidden [string] $ApiUrl
    hidden [string] $ApiKey
    [array]$MessageHistory = @()

    # Currently missing support for handling exceptions. As of now it either works or it fails silently.
    LLM() {

        $this.ApiUrl = "https://openrouter.ai/api/v1/chat/completions"

        # Add your OpenRouter api key to the property "apikey" in your config.json
        $this.APiKey = (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json).ApiKey

        Set-Item -Path "Function:Global:LLM" -Value {
            param ([string]$UserInput)

            Write-Host `n"New session. Type 'info' for extra info`n" -ForegroundColor "Yellow"

            while ($true) {
                $UserInput = Read-Host "You"
                    
                $LLM.Run($UserInput)
            }
        }
    }

    [boolean] IsCommand($UserInput) {
        switch ($UserInput) {
            'clear' {
                Clear-Host
                Write-Host "`nHistory cleared.`n" -ForegroundColor "Yellow"
                return $True
            }
            'info' {
                Write-Host "`nPress Q to cancel current stream.`nPress R to cancel and delete current stream from history." -ForegroundColor "Yellow"

                Write-Host "Type 'clear' to clear chat history.`n" -ForegroundColor "Yellow"
                return $True
            }
        }
        return $False
    }

    [void] Run($UserInput) {
        if ($this.IsCommand($UserInput)) {
            return
        }

        $HttpClient = [System.Net.Http.HttpClient]::new()

        $CurrentMessageHistory = $this.MessageHistory
        $CurrentMessageHistory += @{
            'role' = 'user'; 'content' = $UserInput
        }

        $Request = [System.Net.Http.HttpRequestMessage]::new()
        $Request.Headers.Add('Authorization', "Bearer $($this.ApiKey)")
        $Request.Headers.Add('Accept', "application/json")
        $Request.Method = 'POST'
        $Request.RequestUri = $this.ApiUrl
        $Request.Content = [System.Net.Http.StringContent]::new(
            (@{
                #'model'    = "meta-llama/llama-3.3-70b-instruct"
                'model'    = "deepseek/deepseek-chat"
                'messages' = $CurrentMessageHistory
                'stream'   = 'true'
            } | ConvertTo-Json),
            [System.Text.Encoding]::UTF8, 'application/json'
        )

        $CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
        $CancellationToken = $CancellationTokenSource.Token

        $ResultMessage = $HttpClient.SendAsync($Request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancellationToken).GetAwaiter().GetResult()

        $Stream = $ResultMessage.Content.ReadAsStreamAsync($CancellationToken).GetAwaiter().GetResult()
        $Reader = [System.Io.StreamReader]::new($Stream)

        $ModelResponse = ""

        Write-Host # Visual padding

        # Loop through every line of the stream.
        while (!$Reader.EndOfStream) {

            # If the user presses Q, the loop, and session terminate
            if ([System.Console]::KeyAvailable) {
                $Key = [System.Console]::ReadKey($true)

                if ($Key.Key -eq 'Q' -or $Key.Key -eq 'R') {

                    if ($Key.Key -eq 'R') {
                        $ModelResponse = $null
                    }
                    
                    $CancellationTokenSource.Cancel()
                    $Stream.Close()
                    $Reader.Close()
                    
                    Write-Host -NoNewLine -ForegroundColor DarkGreen `n`n"## Stream cancelled. ##"
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

        Write-Host `n # Visual padding

        # Message history stays the same if model returnes nothing, or if user resets the session.
        if ($null -ne $ModelResponse) {
            $this.MessageHistory += @{
                'role' = 'user'; 'content' = $UserInput
            }
            $this.MessageHistory += @{
                'role' = 'assistant'; 'content' = $ModelResponse
            }
        }
    }

}

# Create an instance
$LLM = [LLM]::new()

Export-ModuleMember LLM
class LLM {

    hidden [string] $ApiUrl
    hidden [string] $ApiKey
    [array]$MessageHistory = @()

    LLM() {

        $this.ApiUrl = "https://openrouter.ai/api/v1/chat/completions"

        # Make a text file to hold ONLY the api key, and refer to it here.
        $this.ApiKey = (Get-Content -Path "$Global:HOME/Dev-Utilities/Secrets/OpenRouterApiKey.txt")

        <# Creates the function used to run this whole thing.
        Example use: LLM "Hi Llama, give me a random color." #>
        Set-Item -Path "Function:Global:LLM" -Value {
            param ([string]$UserInput)

            if ($UserInput -eq 'info' -or !$UserInput) {
                Write-Host "`nWELCOME TO SONDRE'S LLM MODULE`n" -ForegroundColor "Yellow"
                Write-Host "Type 'LLM Session' for an interactive chat, or simply 'LLM "myPrompt"' (a string) to send a single message. In both instances the message history is saved." -ForegroundColor "Yellow"
                Write-Host "Cancel the current streaming response by pressing Q. Cancel and disregard the lastest prompt and response by pressing R." -ForegroundColor "Yellow"
                Write-Host "Type 'LLM reset' to clear the message history.`n" -ForegroundColor "Yellow"
            } elseif ($UserInput -eq 'session') {
                Write-Host `n"LLM chat session. Type 'Info' for extra info" -ForegroundColor "Yellow"

                while ($true) {
                    $UserInput = Read-Host "You"
                    
                    if ($UserInput -eq 'info') {
                        Write-Host "`nWhile streaming the response press Q to cancel the current stream.`nPress R to reset, canceling the current stream and wiping the submitted prompt and response.`n" -ForegroundColor "Yellow"
                    } else {
                        $LLM.Run($UserInput)
                    }    
                }
            } elseif ($UserInput -eq 'reset') {
                $LLM.MessageHistory = @()
                Write-Host "`nHistory cleared.`n " -ForegroundColor "Yellow"
            } else {
                $LLM.Run($UserInput)
            }

        }
    }

    [void] Run($UserInput) {
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

        # No clue what these GET methods are, but they seem to work.
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
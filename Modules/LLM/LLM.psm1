class LLM {

    hidden [string] $ApiUrl
    hidden [string] $ApiKey
    hidden [string] $Model
    [array]$MessageHistory = @()

    LLM() {

        $config = (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json)

        $this.ApiUrl = $config.LLM.ApiUrl
        $this.ApiKey = $config.LLM.ApiKey
        $this.Model = $config.LLM.CurrentModel

        Set-Item -Path "Function:Global:LLM" -Value {
            param ([string]$UserInput)

            Write-Host `n"New session. Type 'info' for more information.`n" -ForegroundColor "Yellow"

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
                Write-Host "`nPress Q to cancel current stream." -ForegroundColor "Yellow"
                Write-Host "Press R to reset and not save to message history." -ForegroundColor "Yellow"
                Write-Host "Type 'clear' to clear chat history.`n" -ForegroundColor "Yellow"
                Write-Host "Type 'model' to see and change current model.`n" -ForegroundColor "Yellow"
                return $True
            }
            'model' {
                $Config = (Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") | ConvertFrom-Json)

                Write-Host "`nCurrent model is: $($this.Model)`n"

                $Count = 1
                foreach ($Model in $Config.LLM.Models) {
                    Write-Host "$Count. $Model"
                    $Count++
                }

                $ModelNumber = ((Read-Host "`nEnter a number") - 1)

                if (($ModelNumber -gt -1) -and ($ModelNumber -lt $Config.LLM.Models.Length)) {

                    $this.Model = $Config.LLM.Models[$ModelNumber]
                    $Config.LLM.CurrentModel = $Config.LLM.Models[$ModelNumber]

                    Set-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "..\..\config.json") -Value ($Config | ConvertTo-Json -Depth 5)

                    Write-Host "`n$($Config.LLM.CurrentModel) set as current model.`n" -ForegroundColor "Yellow"
                }

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
                'model'    = $this.model
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
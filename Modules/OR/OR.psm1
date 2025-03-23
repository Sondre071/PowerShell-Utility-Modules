$Config = Use-Config

$ORConfig = $Config.Data.OR
$MenuTextColor = $Config.Data.UserSettings.Colors.MenuText
$LLMTextColor = $Config.Data.UserSettings.Colors.LLMText

$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

function OR() {
    $Action = Read-Menu -Options @('New session', 'Model') -SkipSorting -WithExit

    switch ($Action) {
        'New session' {

            Write-Host `n"Choose a prompt" -ForegroundColor $MenuTextColor

            $PromptKeys = $ORConfig.Prompts.PSObject.Properties.Name
            $PromptKey = Read-Menu -FirstOptions @('None') -Options $PromptKeys -LastOptions @('- Create new prompt -')

            $SystemPrompt = ""

            switch ($PromptKey) {
                'Create new prompt' {
                    Write-Host `n"Enter a new prompt: " -ForegroundColor $MenuTextColor -NoNewLine
                    $NewPrompt = Read-Host

                    if (-not $NewPrompt) {
                        Write-Host "No prompt provided." -ForegroundColor $MenuTextColor
                    }

                    $SystemPrompt = $NewPrompt
                }
                'None' { 
                    break 
                }
                default {
                    $SystemPrompt = $ORConfig.Prompts.$PromptKey
                }
            }

            New-Session -SystemPrompt $SystemPrompt
        }
        'Model' {
            Open-Model-Menu
        }
        'Exit' {
            Write-Host
        }
    }
}

function New-Session($SystemPrompt) {
    $MessageHistory.Clear()

    $HttpClient = [System.Net.Http.HttpClient]::new()

    while ($true) {

        Write-Host
        $UserInput = Read-Host "You"
        Write-Host

        try {
            $Stream = New-Stream -UserInput $UserInput -SystemPrompt $SystemPrompt -HttpClient $HttpClient 

            $ModelResponse = Read-Stream $Stream

            SaveToMessageHistory -UserInput $UserInput -ModelResponse $ModelResponse
        }
        catch {
            throw "Error: $_"
        }
    }
}

function New-Stream($UserInput, $SystemPrompt, $HttpClient) {
    $Messages = @()

    if ($SystemPrompt) {
        $Messages += @{
            role    = 'system'
            content = $SystemPrompt
        }    
    }

    if ($MessageHistory) {
        $Messages += $MessageHistory
    }

    $Messages += @{
        role    = 'user'
        content = $UserInput
    }

    $RequestBody = @{
        model    = $Config.CurrentModel
        messages = $Messages
        stream   = 'true'
    } | ConvertTo-Json

    $Request = [System.Net.Http.HttpRequestMessage]::new('POST', $($ORConfig.ApiUrl))
    $Request.Headers.Add('Authorization', "Bearer $($ORConfig.ApiKey)")
    $Request.Content = [System.Net.Http.StringContent]::new($RequestBody, [System.Text.Encoding]::UTF8, 'application/json')

    $CancellationToken = [System.Threading.CancellationTokenSource]::new().Token

    $Response = $HttpClient.SendAsync($Request, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead, $CancellationToken).GetAwaiter().GetResult()

    if (-not $Response.IsSuccessStatusCode) {
        throw "Request failed with status code $($Response.StatusCode)."
    }

    return $Response.Content.ReadAsStreamAsync($CancellationToken).GetAwaiter().GetResult()
}

function Read-Stream($Stream) {
    $Reader = [System.IO.StreamReader]::new($Stream)

    $ModelResponse = ""

    $FirstToken = $true

    while (-not $Reader.EndOfStream) {
        $Line = $Reader.ReadLine()
        $ValuesToSkip = @(': OPENROUTER PROCESSING', 'data: [DONE]', '')

        if ($Line -in $ValuesToSkip) { continue }

        try {
            $ParsedLine = ($Line.Substring(6) | ConvertFrom-Json).choices.delta.content

            # Trim leading whitespace from the first token.
            if ($FirstToken) {
                $ParsedLine = $ParsedLine.TrimStart()
                $FirstToken = $false
            }

            Write-Host -NoNewLine -ForegroundColor $LLMTextColor $ParsedLine
            $ModelResponse += $ParsedLine
        }
        catch {
            throw "Stream error: $_"
        }
    }

    Write-Host

    return $ModelResponse
}

function SaveToMessageHistory($UserInput, $ModelResponse) {
    if ($ModelResponse) {
        $MessageHistory.Add(@{
                role    = 'user'
                content = $UserInput
            })
        $MessageHistory.Add(@{
                role    = 'model'
                content = $ModelResponse
            })
    }
}

function Open-Model-Menu() {
    Write-Host `n"Current model is: $($ORConfig.CurrentModel)" -ForegroundColor $MenuTextColor

    $Action = Read-Menu -Options @('Add model', 'Change model') -WithExit

    switch ($Action) {
        'Add model' {
            Write-Host `n"Enter OpenRouter model id: " -ForegroundColor $MenuTextColor -NoNewLine 

            $NewModel = Read-Host

            if (-not $NewModel) {
                Write-Host "No model provided." -ForegroundColor $MenuTextColor
            }

            $Config.Data.OR.CurrentModel = $NewModel
            $Config.Data.OR.Models += $NewModel

            $Config.Save()

            Write-Host `n"$NewModel set to current model."`n -ForegroundColor $MenuTextColor
        }
        'Change model' {
            Write-Host -ForegroundColor $MenuTextColor `n"Select model:"
            $NewModel = Read-Menu -Options $ORConfig.Models -WithExit

            if ($NewModel -eq 'Exit') {
                Write-Host
                break
            }

            $ORConfig.CurrentModel = $NewModel

            $Config.Save()

            Write-Host -ForegroundColor $MenuTextColor `n"Current model set to $NewModel."`n
        }
        'Exit' {
            Write-Host
        }
    }
}

Export-ModuleMember OR
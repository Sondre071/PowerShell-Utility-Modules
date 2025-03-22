$Config = Use-Config
$ORConfig = $Config.Data.Or
$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

function OR() {
    $Action = Read-Menu -MenuArray @('New session', 'Model') -WithExit

    switch ($Action) {
        'New session' {
            New-Session 
        }
        'Model' {
            Open-Model-Menu
        }
        'Exit' {
            Write-Host
        }
    }
}

function New-Session() {
    $MessageHistory.Clear()

    $HttpClient = [System.Net.Http.HttpClient]::new()

    while ($true) {

        Write-Host
        $UserInput = Read-Host "You"
        Write-Host

        try {
            $Stream = New-Stream -HttpClient $HttpClient -UserInput $UserInput

            $ModelResponse = Read-Stream $Stream

            SaveToMessageHistory -UserInput $UserInput -ModelResponse $ModelResponse
        }
        catch {
            throw "Error: $_"
        }
    }
}

function New-Stream($UserInput, $HttpClient) {
    $RequestBody = @{
        model    = $Config.CurrentModel
        messages = $MessageHistory + @{
            role    = 'user'
            content = $UserInput
        }
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

    $FirstToken = $false

    while (-not $Reader.EndOfStream) {
        $Line = $Reader.ReadLine()
        $ValuesToSkip = @(': OPENROUTER PROCESSING', 'data: [DONE]', '')

        if ($Line -in $ValuesToSkip) { continue }

        try {
            $ParsedLine = ($Line.Substring(6) | ConvertFrom-Json).choices.delta.content

            # Trim leading whitespace from the first token.
            if (-not $FirstToken) {
                $ParsedLine = $ParsedLine.TrimStart()
                $FirstToken = $true
            }

            Write-Host -NoNewLine -ForegroundColor Green $ParsedLine
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
    Write-Host `n"Current model is: $($ORConfig.CurrentModel)" -ForegroundColor Yellow

    $Action = Read-Menu -MenuArray @('Add model', 'Change model') -WithExit

    switch ($Action) {
        'Add model' {
            Write-Host `n"Enter OpenRouter model id: " -ForegroundColor Yellow -NoNewLine 

            $NewModel = Read-Host

            if (-not $NewModel) {
                Write-Host "No model provided." -ForegroundColor Yellow
            }

            $Config.Data.OR.CurrentModel = $NewModel
            $Config.Data.OR.Models += $NewModel

            $Config.Save()

            Write-Host `n"$NewModel set to current model."`n -ForegroundColor Yellow
        }
        'Change model' {
            Write-Host -ForegroundColor Yellow `n"Select model:"
            $NewModel = Read-Menu -MenuArray $ORConfig.Models -WithExit

            if ($NewModel -eq 'Exit') {
                Write-Host
                break
            }

            $ORConfig.CurrentModel = $NewModel

            $Config.Save()

            Write-Host -ForegroundColor Yellow `n"Current model set to $NewModel."`n
        }
        'Exit' {
            Write-Host
        }
    }
}

Export-ModuleMember OR
$Config = Use-Config
$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

function OR() {
    $Action = Read-Menu -MenuArray @('New session', 'Info', 'Model')

    switch ($Action) {
        'New session' {
            New-Session 
        }
        'Model' {
            ModelScreen
        }
        'Exit' {
            break
        }
    }

    Write-Host "hi"
}

function New-Session() {
    $MessageHistory.Clear()

    $HttpClient = [System.Net.Http.HttpClient]::new()

    while ($true) {

        $UserInput = Read-Host "You"

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
        model    = $Config.Data.OR.CurrentModel
        messages = $MessageHistory + @{
            role    = 'user'
            content = $UserInput
        }
        stream   = 'true'
    } | ConvertTo-Json

    $Request = [System.Net.Http.HttpRequestMessage]::new('POST', $($Config.Data.OR.ApiUrl))
    $Request.Headers.Add('Authorization', "Bearer $($Config.Data.OR.ApiKey)")
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

    Write-Host

    while (-not $Reader.EndOfStream) {
        $Line = $Reader.ReadLine()

        try {
            $ParsedLine = ($Line.Substring(6) | ConvertFrom-Json).choices.delta.content

            Write-Host -NoNewLine -ForegroundColor Green $ParsedLine
            $ModelResponse += $ParsedLine
        }
        catch {
            continue
        }
    }

    Write-Host `n

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

function ModelScreen() {
    Write-Host `n"Current model is: $($Config.Data.OR.Model)" -ForegroundColor Yellow

    $Action = Read-Menu -MenuArray @('Add model', 'Change model', 'Exit')

    switch ($Action) {
        'Add model' {
            Read-Host "Enter model name" -ForegroundColor Yellow | OR.CurrentModel
            Write-Host Done. -ForegroundColor Yellow
        }
        'Change model' {
            Change-Model
        }
        'Exit' {
            break
        }
    }
}

Export-ModuleMember OR
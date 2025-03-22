$Config = Use-Config
$ORConfig = $Config.Data.Or
$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

function OR() {
    $Action = Read-Menu -MenuArray @('New session', 'Info', 'Model') -LastEntry 'Exit'

    switch ($Action) {
        'New session' {
            New-Session 
        }
        'Model' {
            Open-Model-Menu
        }
        'Exit' {
            Write-Host
            break
        }
    }
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

    Write-Host

    while (-not $Reader.EndOfStream) {
        $Line = $Reader.ReadLine()

        try {
            $ParsedLine = ($Line.Substring(7) | ConvertFrom-Json).choices.delta.content

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

function Open-Model-Menu() {
    Write-Host `n"Current model is: $($ORConfig.CurrentModel)" -ForegroundColor Yellow

    $Action = Read-Menu -MenuArray @('Add model', 'Change model') -LastEntry 'Exit'

    switch ($Action) {
        'Add model' {
            Write-Host -ForegroundColor Yellow -NoNewLine "Enter OpenRouter model id: " 

            $NewModel = Read-Host

            Write-Host Done. -ForegroundColor Yellow
        }
        'Change model' {
            Write-Host -ForegroundColor Yellow `n"Select model:" 

            $NewModel = Read-Menu -MenuArray $ORConfig.Models
            $ORConfig.CurrentModel = $NewModel

            $Config.Save()

            Write-Host -ForegroundColor Yellow `n"Current model set to $NewModel."`n
        }
        'Exit' {
            Write-Host
            break
        }
    }
}

Export-ModuleMember OR
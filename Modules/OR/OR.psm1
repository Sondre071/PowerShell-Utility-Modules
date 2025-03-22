$Config = Get-Config
$ApiKey = $Config.OR.ApiKey
$ApiUrl = $Config.OR.ApiUrl
$Model = $Config.OR.CurrentModel
$MessageHistory = [System.Collections.Generic.List[PSObject]]::new()

function OR() {
    $Action = Read-Menu -MenuArray @('New session', 'Info', 'Model')

    switch ($Action) {
        'New session' {
            New-Session 
        }
        'Info' {
            Write-Host "Some info.."
        }
        'Model' {
            Write-Host "Model.."
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
        model    = $Model
        messages = $MessageHistory + @{
            role    = 'user'
            content = $UserInput
        }
        stream   = 'true'
    } | ConvertTo-Json

    $Request = [System.Net.Http.HttpRequestMessage]::new('POST', $ApiUrl)
    $Request.Headers.Add('Authorization', "Bearer $ApiKey")
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

Export-ModuleMember OR
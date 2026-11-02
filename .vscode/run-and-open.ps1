param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ComposeArgs
)

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Error "Docker was not found. Start Docker Desktop and make sure 'docker' is available in PATH."
    exit 1
}

& docker compose @ComposeArgs
$composeExitCode = $LASTEXITCODE
if ($composeExitCode -ne 0) {
    exit $composeExitCode
}

$upIndex = [Array]::IndexOf($ComposeArgs, 'up')
if ($upIndex -lt 0) {
    exit 0
}

$services = [System.Collections.Generic.List[string]]::new()
$skipNext = $false
$optionsWithValues = @('--scale', '--timeout', '--pull', '--exit-code-from', '--attach', '--no-attach')

for ($i = $upIndex + 1; $i -lt $ComposeArgs.Count; $i++) {
    $arg = $ComposeArgs[$i]

    if ($skipNext) {
        $skipNext = $false
        continue
    }

    if ($optionsWithValues -contains $arg) {
        $skipNext = $true
        continue
    }

    if ($arg.StartsWith('-')) {
        continue
    }

    $services.Add($arg)
}

if ($services.Count -eq 0) {
    $services.AddRange([string[]]@('admin', 'client', 'api'))
}

$urls = @{
    admin  = 'http://localhost:8082'
    client = 'http://localhost:8081'
    api    = 'http://localhost:8000/docs'
}

foreach ($service in $services) {
    if ($urls.ContainsKey($service)) {
        $url = $urls[$service]
        Write-Host "Opening ${service}: $url"
        try {
            Start-Process $url
        }
        catch {
            Write-Warning "Could not open ${url} automatically. Open it in your browser."
        }
    }
}

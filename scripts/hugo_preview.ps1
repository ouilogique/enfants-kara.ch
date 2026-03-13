param(
    [string]$Port = "1313"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
Set-Location $ProjectDir

function Get-LocalIPv4Address {
    $config = Get-NetIPConfiguration |
        Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.IPv4Address -ne $null } |
        Select-Object -First 1

    if ($config -and $config.IPv4Address) {
        return $config.IPv4Address.IPAddress
    }

    return "127.0.0.1"
}

function Get-HugoExecutable {
    $candidates = @()

    try {
        $command = Get-Command hugo -ErrorAction Stop
        if ($command.Source) {
            $candidates += $command.Source
        }
    } catch {
    }

    $winGetPackage = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path $winGetPackage) {
        $candidates += Get-ChildItem $winGetPackage -Recurse -Filter hugo.exe -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (-not (Test-Path $candidate)) {
            continue
        }

        try {
            & $candidate version *> $null
            return $candidate
        } catch {
        }
    }

    throw "Hugo executable not found or not runnable. Install Hugo Extended first."
}

function Prepend-Path([string]$PathEntry) {
    if (-not (Test-Path $PathEntry)) {
        return
    }

    $parts = $env:Path -split ";" | Where-Object { $_ }
    $filtered = $parts | Where-Object { $_ -ne $PathEntry }
    $env:Path = ($PathEntry + ";" + ($filtered -join ";")).TrimEnd(";")
}

function Test-PortAvailable([string]$BindAddress, [int]$CandidatePort) {
    $listener = $null

    try {
        $ipAddress = [System.Net.IPAddress]::Parse($BindAddress)
        $listener = [System.Net.Sockets.TcpListener]::new($ipAddress, $CandidatePort)
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($listener) {
            $listener.Stop()
        }
    }
}

function Get-AvailablePort([string]$BindAddress, [int]$PreferredPort) {
    $candidate = $PreferredPort

    while (-not (Test-PortAvailable -BindAddress $BindAddress -CandidatePort $candidate)) {
        $candidate += 1
    }

    return $candidate
}

$dartSassDir = "C:\Tools\dart-sass"
Prepend-Path $dartSassDir

$ip = Get-LocalIPv4Address
$resolvedPort = Get-AvailablePort -BindAddress $ip -PreferredPort ([int]$Port)
$baseUrl = "http://$ip"
$fullUrl = "${baseUrl}:$resolvedPort"
$publicDir = Join-Path $ProjectDir "public"

if (Test-Path $publicDir) {
    Remove-Item -Recurse -Force $publicDir
}

$qrencode = Get-Command qrencode -ErrorAction SilentlyContinue
if ($qrencode) {
    & $qrencode.Source -t ANSI $fullUrl
} else {
    Write-Host ""
    Write-Host "Install qrencode to display a terminal QR code."
}

Write-Host ""
Write-Host $fullUrl
if ($resolvedPort -ne [int]$Port) {
    Write-Host "Port $Port unavailable, using $resolvedPort."
}
Write-Host ""

$hugo = Get-HugoExecutable

& $hugo server `
    --environment dev-local `
    --watch `
    -D `
    --gc `
    --disableFastRender `
    --baseURL=$baseUrl `
    --bind=$ip `
    --port=$resolvedPort `
    --appendPort=true `
    --openBrowser

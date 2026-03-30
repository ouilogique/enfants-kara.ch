param(
    [string]$InstallRoot = "C:\Tools",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-ArchiveSuffix {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture

    switch ($arch) {
        "X64" { return "windows-x64" }
        "Arm64" { return "windows-arm64" }
        "X86" { return "windows-ia32" }
        default { throw "Architecture non supportee: $arch" }
    }
}

function Get-LatestVersion {
    $response = Invoke-WebRequest `
        -MaximumRedirection 0 `
        -ErrorAction SilentlyContinue `
        https://github.com/sass/dart-sass/releases/latest

    if (-not $response.Headers.Location) {
        throw "Impossible de determiner la derniere version de Dart Sass."
    }

    return (Split-Path $response.Headers.Location -Leaf)
}

function Set-UserPathPrepend([string]$PathEntry) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()

    if ($userPath) {
        $parts = $userPath -split ";" | Where-Object { $_ -and ($_ -ne $PathEntry) }
    }

    $newUserPath = ($PathEntry + ";" + ($parts -join ";")).TrimEnd(";")
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")

    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $env:Path = ($newUserPath + ";" + $machinePath).TrimEnd(";")
}

$targetDir = Join-Path $InstallRoot "dart-sass"
$archiveSuffix = Get-ArchiveSuffix
$version = Get-LatestVersion
$zipUrl = "https://github.com/sass/dart-sass/releases/download/$version/dart-sass-$version-$archiveSuffix.zip"
$tmpZip = Join-Path $env:TEMP "dart-sass-$version-$archiveSuffix.zip"

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null

Write-Host "Telechargement de $zipUrl"
Invoke-WebRequest -Uri $zipUrl -OutFile $tmpZip

if (Test-Path $targetDir) {
    if (-not $Force) {
        throw "Le dossier $targetDir existe deja. Relancez avec -Force pour le remplacer."
    }

    Remove-Item -Recurse -Force $targetDir
}

Write-Host "Extraction vers $InstallRoot"
Expand-Archive -Path $tmpZip -DestinationPath $InstallRoot -Force
Remove-Item $tmpZip -Force

if (-not (Test-Path (Join-Path $targetDir "sass.bat"))) {
    throw "Installation invalide: sass.bat introuvable dans $targetDir"
}

Set-UserPathPrepend $targetDir

Write-Host ""
Write-Host "Verification:"
where.exe sass
& (Join-Path $targetDir "sass.bat") --version

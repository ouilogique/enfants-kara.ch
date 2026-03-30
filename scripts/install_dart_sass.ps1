# Execution:
#   powershell -ExecutionPolicy Bypass -File .\scripts\install_dart_sass.ps1
#   powershell -ExecutionPolicy Bypass -File .\scripts\install_dart_sass.ps1 -Force

param(
    [string]$InstallRoot = "C:\Tools",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-ArchiveSuffix {
    $arch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture

    switch ($arch) {
        ([System.Runtime.InteropServices.Architecture]::X64) { return "windows-x64" }
        ([System.Runtime.InteropServices.Architecture]::Arm64) { return "windows-arm64" }
        ([System.Runtime.InteropServices.Architecture]::X86) { return "windows-ia32" }
        default { throw "Architecture non supportee: $arch" }
    }
}

function Get-LatestReleaseTag {
    $release = Invoke-RestMethod `
        -Headers @{ "User-Agent" = "enfants-kara-install-dart-sass" } `
        -Uri "https://api.github.com/repos/sass/dart-sass/releases/latest"

    if (-not $release.tag_name) {
        throw "Impossible de determiner la derniere version de Dart Sass."
    }

    return [string]$release.tag_name
}

function Prepend-UserPath([string]$PathEntry) {
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $parts = @()

    if ($userPath) {
        $parts = $userPath -split ";" | Where-Object { $_ -and ($_ -ne $PathEntry) }
    }

    $newUserPath = ($PathEntry + ";" + ($parts -join ";")).TrimEnd(";")
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")

    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $processParts = @($PathEntry)

    if ($userPath) {
        $processParts += ($newUserPath -split ";" | Where-Object { $_ -and ($_ -ne $PathEntry) })
    }

    if ($machinePath) {
        $processParts += ($machinePath -split ";" | Where-Object { $_ })
    }

    $env:Path = (($processParts | Select-Object -Unique) -join ";").TrimEnd(";")
}

function Get-DownloadedArchivePath([string]$Version, [string]$ArchiveSuffix, [string]$TempDir) {
    $fileName = "dart-sass-$Version-$ArchiveSuffix.zip"
    $archiveUrl = "https://github.com/sass/dart-sass/releases/download/$Version/$fileName"
    $archivePath = Join-Path $TempDir $fileName

    Write-Host "Telechargement de $archiveUrl"
    Invoke-WebRequest `
        -Headers @{ "User-Agent" = "enfants-kara-install-dart-sass" } `
        -Uri $archiveUrl `
        -OutFile $archivePath

    return $archivePath
}

function Get-ExpandedSourceDir([string]$ArchivePath, [string]$TempDir) {
    $expandedDir = Join-Path $TempDir "expanded"
    Expand-Archive -Path $ArchivePath -DestinationPath $expandedDir -Force

    $sourceDir = Join-Path $expandedDir "dart-sass"
    if (-not (Test-Path (Join-Path $sourceDir "sass.bat"))) {
        throw "Archive Dart Sass invalide: sass.bat introuvable."
    }

    return $sourceDir
}

$targetDir = Join-Path $InstallRoot "dart-sass"
$archiveSuffix = Get-ArchiveSuffix
$version = Get-LatestReleaseTag
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("dart-sass-install-" + [System.Guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

try {
    $archivePath = Get-DownloadedArchivePath -Version $version -ArchiveSuffix $archiveSuffix -TempDir $tempDir
    $sourceDir = Get-ExpandedSourceDir -ArchivePath $archivePath -TempDir $tempDir

    if (Test-Path $targetDir) {
        if (-not $Force) {
            throw "Le dossier $targetDir existe deja. Relancez avec -Force pour le remplacer."
        }

        Remove-Item -Recurse -Force $targetDir
    }

    Write-Host "Installation dans $targetDir"
    Move-Item -Path $sourceDir -Destination $targetDir

    Prepend-UserPath -PathEntry $targetDir

    Write-Host ""
    Write-Host "Verification:"
    $whereOutput = where.exe sass 2>&1
    $whereOutput | ForEach-Object { Write-Host $_ }

    $sassBat = Join-Path $targetDir "sass.bat"
    & $sassBat --version

    if (-not ($whereOutput | Select-String -SimpleMatch $sassBat)) {
        Write-Warning "where.exe sass ne montre pas encore $sassBat en priorite. Ouvrez un nouveau terminal PowerShell ou CMD puis reessayez."
    }
} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
}

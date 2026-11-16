#Requires -Version 5.1
<#
.SYNOPSIS
Builds the local Hear Me Out beta artifacts.

.DESCRIPTION
Builds the release web bundle. Unless -WebOnly is set, also requires the
Android toolchain and builds the release APK. A missing or incomplete toolchain
fails the script with a clear message instead of silently producing a web-only
build.

The script does not upload anything and does not call a product analytics
service. Flutter's toolchain check and dependency resolution may use the
network on a machine that has not built the app. The Android build uses the
repository's debug signing key; it is a sideload artifact, not a store build.

.PARAMETER WebOnly
Builds the web bundle only. Use this when the beta is web-only or when the
machine does not have the Android SDK.

.PARAMETER FlutterPath
Full path to flutter.bat. Omit it to use flutter from PATH, then FLUTTER_ROOT,
then the default per-user SDK folder.

.EXAMPLE
.\tool\beta\build_beta.ps1

.EXAMPLE
.\tool\beta\build_beta.ps1 -WebOnly
#>
[CmdletBinding()]
param(
    [switch]$WebOnly,
    [string]$FlutterPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Fail {
    param([string]$Message)
    Write-Host ''
    Write-Host "BUILD FAILED: $Message" -ForegroundColor Red
    Write-Host ''
    exit 1
}

$flutterGlobalArgs = @('--suppress-analytics', '--no-version-check')

function Invoke-Flutter {
    param([string[]]$Arguments)
    Write-Step ('flutter ' + ($Arguments -join ' '))
    & $flutter @flutterGlobalArgs @Arguments
    if ($LASTEXITCODE -ne 0) {
        Fail ("flutter {0} exited with code {1}." -f $Arguments[0], $LASTEXITCODE)
    }
}

$appRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
if (-not (Test-Path (Join-Path $appRoot 'pubspec.yaml'))) {
    Fail "Could not find flutter_app\pubspec.yaml at $appRoot."
}

$flutter = $null
if ($FlutterPath) {
    if (-not (Test-Path $FlutterPath)) {
        Fail "FlutterPath does not exist: $FlutterPath"
    }
    $flutter = (Resolve-Path $FlutterPath).Path
}
else {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($command) {
        $flutter = $command.Source
    }
    elseif ($env:FLUTTER_ROOT -and (Test-Path (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat'))) {
        $flutter = (Resolve-Path (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat')).Path
    }
    elseif (Test-Path (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')) {
        $flutter = (Resolve-Path (Join-Path $env:USERPROFILE 'flutter\bin\flutter.bat')).Path
    }
    else {
        Fail @'
Flutter was not found.
Add Flutter to PATH, set FLUTTER_ROOT, or pass -FlutterPath with the full path
to flutter.bat. On this repository's Windows machine the verified SDK is:
  C:\Users\<you>\flutter\bin\flutter.bat
'@
    }
}

Write-Host ''
Write-Host "Hear Me Out beta build" -ForegroundColor Green
Write-Host "  App:     $appRoot"
Write-Host "  Flutter: $flutter"
Write-Host ''

# Check the Android toolchain before the web build so a missing SDK fails fast.
if (-not $WebOnly) {
    Write-Step 'Checking the Android toolchain'
    $doctorOutput = (& $flutter @flutterGlobalArgs doctor -v 2>&1) -join "`n"
    $androidLine = ($doctorOutput -split "`r?`n" |
        Where-Object { $_ -match 'Android toolchain' } |
        Select-Object -First 1)
    if ($androidLine) {
        $androidLine = $androidLine -replace '^\[\s*\]\s*', ''
    }

    if (-not $androidLine) {
        Fail @'
Could not read the Android toolchain state from "flutter doctor -v".
Install Android Studio with the Android SDK, run "flutter doctor", and retry.
For a web-only beta build, run with -WebOnly.
'@
    }

    if ($androidLine -match '\[!\]') {
        Fail ("Android toolchain is incomplete: {0}`nRun ""flutter doctor -v"", fix the Android SDK, and retry.`nFor a web-only beta build, run with -WebOnly." -f $androidLine.Trim())
    }

    if ($androidLine -match '\[X\]') {
        Fail ("Android toolchain is missing: {0}`nInstall Android Studio with the Android SDK, run ""flutter doctor"", and retry.`nFor a web-only beta build, run with -WebOnly." -f $androidLine.Trim())
    }

    Write-Host "Android toolchain found." -ForegroundColor Green
}
else {
    Write-Host 'Web-only build requested; the Android toolchain is not checked.' -ForegroundColor Yellow
}

Push-Location $appRoot
try {
    Invoke-Flutter @('build', 'web', '--release')
    $webDir = Join-Path $appRoot 'build\web'
    $webIndex = Join-Path $webDir 'index.html'
    if (-not (Test-Path $webIndex)) {
        Fail "The web build finished but $webIndex is missing."
    }

    $apkPath = $null
    if (-not $WebOnly) {
        Invoke-Flutter @('build', 'apk', '--release')
        $apkPath = Join-Path $appRoot 'build\app\outputs\flutter-apk\app-release.apk'
        if (-not (Test-Path $apkPath)) {
            Fail "The APK build finished but $apkPath is missing."
        }
    }
}
finally {
    Pop-Location
}

Write-Host ''
Write-Host 'Beta artifacts:' -ForegroundColor Green
Write-Host "  Web folder: $webDir"
Write-Host "  Web entry:  $webIndex"
if ($apkPath) {
    Write-Host "  APK:        $apkPath"
    $apkSizeMb = [math]::Round((Get-Item $apkPath).Length / 1MB, 1)
    Write-Host "  APK size:   $apkSizeMb MB"
    Write-Host ''
    Write-Host 'The APK uses the repository debug signing key. It is for sideloaded' -ForegroundColor Yellow
    Write-Host 'beta installs only, not a Play Store upload.' -ForegroundColor Yellow
}
else {
    Write-Host '  APK:        skipped (-WebOnly)'
}
Write-Host ''
Write-Host 'Serve the web build from flutter_app with:' -ForegroundColor Green
Write-Host '  python -m http.server 8080 --bind 0.0.0.0 --directory build\web'
Write-Host ''

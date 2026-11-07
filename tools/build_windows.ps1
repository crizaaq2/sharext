# Build the Windows EXE on a Windows 10/11 machine.
# Requires Flutter stable (with desktop support) and the "Desktop development
# with C++" workload of Visual Studio 2022. Flutter cannot cross-compile the
# Windows runner, so this script must run on Windows.
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Push-Location (Join-Path $root "app")
try {
    flutter pub get
    flutter gen-l10n
    flutter build windows --release

    $release = Join-Path (Get-Location) "build\windows\x64\runner\Release"
    $zip = Join-Path $root "sharext-windows.zip"
    if (Test-Path $zip) { Remove-Item $zip }
    Compress-Archive -Path (Join-Path $release "*") -DestinationPath $zip

    Write-Host ""
    Write-Host "EXE:  $release\sharext.exe"
    Write-Host "ZIP:  $zip"
}
finally {
    Pop-Location
}

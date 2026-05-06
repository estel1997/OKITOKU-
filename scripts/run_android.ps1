#Requires -Version 5.1
<#
.SYNOPSIS
  Android エミュレータを起動し、起動完了後に shopping_price_watch を flutter run します。

.DESCRIPTION
  - SDK の emulator.exe は %LOCALAPPDATA%\Android\Sdk を優先し、なければ ANDROID_HOME / ANDROID_SDK_ROOT を参照します。
  - AVD 名はデフォルトで Medium_Phone_API_36.1（Android Studio の Device Manager と同じ名前に合わせてください）。
  - 既にエミュレータが起動していれば、その端末へそのまま flutter run します。

.EXAMPLE
  .\scripts\run_android.ps1
  .\scripts\run_android.ps1 -AvdName "Pixel_8_API_35"
#>
param(
    [string] $AvdName = "Medium_Phone_API_36.1",
    [string] $FlutterExe = "flutter",
    [int] $BootWaitSeconds = 180
)

$ErrorActionPreference = "Stop"
# scripts\ の親 = プロジェクトルート
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path -LiteralPath (Join-Path $ProjectRoot "pubspec.yaml"))) {
    Write-Error "pubspec.yaml が見つかりません。shopping_price_watch 内の scripts\run_android.ps1 から実行してください。"
}

function Find-EmulatorExe {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Android\Sdk\emulator\emulator.exe"),
        $(if ($env:ANDROID_HOME) { Join-Path $env:ANDROID_HOME "emulator\emulator.exe" }),
        $(if ($env:ANDROID_SDK_ROOT) { Join-Path $env:ANDROID_SDK_ROOT "emulator\emulator.exe" })
    ) | Where-Object { $_ }

    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Find-AdbExe {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"),
        $(if ($env:ANDROID_HOME) { Join-Path $env:ANDROID_HOME "platform-tools\adb.exe" }),
        $(if ($env:ANDROID_SDK_ROOT) { Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe" })
    ) | Where-Object { $_ }

    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    return $null
}

function Test-EmulatorRunning {
    param([string] $Adb)
    if (-not $Adb) { return $false }
    $out = & $Adb devices 2>$null
    return $out -match "emulator-\d+\s+device"
}

function Wait-AndroidBoot {
    param([string] $Adb, [int] $TimeoutSec)
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
        $s = & $Adb shell getprop sys.boot_completed 2>$null
        if ($s -match "1") { return $true }
        Start-Sleep -Seconds 2
    }
    return $false
}

$emulatorExe = Find-EmulatorExe
$adbExe = Find-AdbExe

if (-not $emulatorExe) {
    Write-Error "emulator.exe が見つかりません。Android Studio の SDK パスを確認するか、ANDROID_HOME を設定してください。"
}

if (-not $adbExe) {
    Write-Error "adb.exe が見つかりません。Android SDK Platform-Tools をインストールしてください。"
}

Write-Host "emulator: $emulatorExe"
Write-Host "adb:      $adbExe"
Write-Host "project:  $ProjectRoot"

if (-not (Test-EmulatorRunning -Adb $adbExe)) {
    Write-Host "エミュレータを起動しています: -avd $AvdName"
    Start-Process -FilePath $emulatorExe -ArgumentList @("-avd", $AvdName) -WindowStyle Normal
    Write-Host "ADB が接続するまで待機..."
    & $adbExe wait-for-device
    Write-Host "起動完了を待機（最大 ${BootWaitSeconds}s）..."
    $booted = Wait-AndroidBoot -Adb $adbExe -TimeoutSec $BootWaitSeconds
    if (-not $booted) {
        Write-Warning "boot_completed の確認がタイムアウトしました。続行します..."
    }
} else {
    Write-Host "既にエミュレータが接続されています。"
}

Set-Location -LiteralPath $ProjectRoot
Write-Host "flutter run を実行します..."
& $FlutterExe run

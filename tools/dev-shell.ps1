# 在 PowerShell 中运行：. ./tools/dev-shell.ps1
# 仅设置当前终端环境，不修改系统/用户永久环境变量。
param(
    [string]$FlutterRoot = "$env:USERPROFILE\dev\flutter",
    [string]$JdkRoot = "$env:USERPROFILE\dev\jdk-17.0.20.1+1",
    [string]$AndroidSdk = "$env:LOCALAPPDATA\Android\Sdk",
    [switch]$UseMirrors
)
$ErrorActionPreference = 'Stop'
foreach ($required in @("$FlutterRoot\bin\flutter.bat", "$JdkRoot\bin\java.exe", "$AndroidSdk\platform-tools\adb.exe")) {
    if (-not (Test-Path -LiteralPath $required)) { throw "缺少工具：$required" }
}
$env:JAVA_HOME = $JdkRoot
$env:ANDROID_HOME = $AndroidSdk
$env:Path = "$FlutterRoot\bin;$JdkRoot\bin;$AndroidSdk\platform-tools;$env:Path"
if ($UseMirrors) {
    $initDirectory = Join-Path $env:USERPROFILE '.gradle\init.d'
    New-Item -ItemType Directory -Force $initDirectory | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'gradle-mirrors.init.gradle') -Destination (Join-Path $initDirectory 'wallehog-mirrors.gradle')
    $env:WALLEHOG_BUILD_MIRRORS = '1'
    $env:WALLEHOG_ANDROID_DIR = (Resolve-Path (Join-Path $PSScriptRoot '..\android')).Path
} else {
    $env:WALLEHOG_BUILD_MIRRORS = '0'
}
Write-Output '已为当前终端配置 Wallehog Android 开发工具。'

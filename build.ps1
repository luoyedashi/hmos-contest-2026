# 信息卫士 - 一键编译脚本
$env:DEVECO_SDK_HOME = "D:\Harmony\DevEcoStudio\sdk"
$env:HIVGOR_USER_HOME = "D:\Huawei\hvigor-home"
$env:JAVA_HOME = "D:\Harmony\DevEcoStudio\jbr"
$env:PATH = "D:\Harmony\DevEcoStudio\jbr\bin;$env:PATH"

$projectRoot = "D:\hmos-contest-2026"
$nodeExe = "D:\Harmony\DevEcoStudio\tools\node\node.exe"
$hvigorJs = "D:\Harmony\DevEcoStudio\tools\hvigor\bin\hvigorw.js"

Write-Host "=== 信息卫士 - 开始编译 ===" -ForegroundColor Cyan
Write-Host "DEVECO_SDK_HOME: $env:DEVECO_SDK_HOME"
Write-Host "JAVA_HOME: $env:JAVA_HOME"

Push-Location $projectRoot
try {
    & $nodeExe $hvigorJs assembleHap 2>&1
    $exitCode = $LASTEXITCODE

    $hapPath = "$projectRoot\entry\build\default\outputs\default\entry-default-unsigned.hap"
    if (Test-Path $hapPath) {
        Write-Host "`n=== 编译成功！ ===" -ForegroundColor Green
        Write-Host "HAP 产物: $hapPath"
        $hapSize = [math]::Round((Get-Item $hapPath).Length / 1KB, 1)
        Write-Host "文件大小: ${hapSize}KB"
    } else {
        Write-Host "`n=== 编译失败 (exit code: $exitCode) ===" -ForegroundColor Red
    }
} finally {
    Pop-Location
}

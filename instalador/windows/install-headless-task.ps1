param(
    [string]$ExePath = "$PSScriptRoot\balanca_service.exe"
)

$ConfigDir = Join-Path $env:ProgramData "Balanca"

if (-not (Test-Path $ExePath)) {
    throw "Executavel nao encontrado: $ExePath"
}

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir | Out-Null
}

$Action = New-ScheduledTaskAction -Execute $ExePath -Argument ("--config-dir=`"" + $ConfigDir + "`"")
$Trigger = New-ScheduledTaskTrigger -AtStartup
$Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask `
    -TaskName "BalancaHeadless" `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Description "Balanca headless - serial, HTTP e WebSocket" `
    -Force

Write-Host "Tarefa BalancaHeadless instalada."
Write-Host "Iniciar: Start-ScheduledTask -TaskName BalancaHeadless"
Write-Host "Parar:   Stop-ScheduledTask -TaskName BalancaHeadless"

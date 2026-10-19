# Правила брандмауэра для сервера RustDesk.
# Запускать от имени администратора.

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Нужны права администратора. Запустите PowerShell от имени администратора.' -ForegroundColor Red
    exit 1
}

function Set-TcpRule {
    param([string]$Name, [int[]]$Ports)
    $old = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    if ($old) { Remove-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue }
    New-NetFirewallRule -DisplayName $Name -Direction Inbound -Action Allow -Protocol TCP -LocalPort $Ports -Profile Any | Out-Null
    Write-Host ("TCP " + ($Ports -join ',') + " — " + $Name)
}

function Set-UdpRule {
    param([string]$Name, [int[]]$Ports)
    $old = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    if ($old) { Remove-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue }
    New-NetFirewallRule -DisplayName $Name -Direction Inbound -Action Allow -Protocol UDP -LocalPort $Ports -Profile Any | Out-Null
    Write-Host ("UDP " + ($Ports -join ',') + " — " + $Name)
}

Set-TcpRule -Name 'RustDesk hbbs TCP 21115-21119' -Ports @(21115, 21116, 21117, 21118, 21119)
Set-UdpRule -Name 'RustDesk hbbs UDP 21116-21119' -Ports @(21116, 21117, 21118, 21119)

Write-Host ''
Write-Host 'Готово. Проверить правила:' -ForegroundColor Green
Write-Host '  Get-NetFirewallRule | Where-Object DisplayName -like "RustDesk*"'

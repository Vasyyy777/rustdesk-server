# Сторож точки доступа: проверяет, что Wi-Fi сеть поднята и адрес 192.168.137.1 на месте,
# при необходимости запускает её и включает общий доступ.
# Запускать по расписанию (например, каждые 5 минут) от имени администратора.

$log = 'C:\ProgramData\RustDesk\hotspot-watchdog.log'
$logDir = Split-Path $log
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log([string]$text) {
    ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ' + $text) | Out-File $log -Append -Encoding UTF8
}

function Get-ApAdapter {
    Get-NetAdapter -ErrorAction SilentlyContinue |
        Where-Object { $_.InterfaceDescription -like '*Hosted Network*' } |
        Select-Object -First 1
}

function Test-ApUp {
    $a = Get-ApAdapter
    if (-not $a) { return $false }
    return ($a.Status -eq 'Up')
}

function Test-ApAddress {
    return [bool](Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -eq '192.168.137.1' })
}

function Start-Ap {
    Write-Log 'запускаю размещённую сеть'
    $r = netsh wlan start hostednetwork 2>&1 | Out-String
    Write-Log ('  ' + $r.Trim())
    Start-Sleep -Seconds 12
}

function Set-Ics {
    $pubAlias = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -notlike '192.168.137.*' -and $_.IPAddress -ne '127.0.0.1' } |
        Select-Object -First 1).InterfaceAlias
    Write-Log ('внешний адаптер: ' + $pubAlias)

    $ns = New-Object -ComObject HNetCfg.HNetShare
    $pub = $null
    $priv = $null
    foreach ($c in $ns.EnumEveryConnection) {
        $p = $ns.NetConnectionProps.Invoke($c)
        if ($p.Name -eq $pubAlias) { $pub = $c }
        if ($p.DeviceName -like '*Hosted Network*') { $priv = $c }
    }
    if (-not ($pub -and $priv)) { Write-Log 'адаптеры не найдены'; return }

    $pc = $ns.INetSharingConfigurationForINetConnection.Invoke($pub)
    $qc = $ns.INetSharingConfigurationForINetConnection.Invoke($priv)
    try { $pc.DisableSharing() } catch { }
    try { $qc.DisableSharing() } catch { }
    Start-Sleep -Seconds 3
    try { $qc.EnableSharing(1); Write-Log 'общий доступ для Wi-Fi включён' } catch { Write-Log ('ошибка Wi-Fi: ' + $_.Exception.Message) }
    Start-Sleep -Seconds 2
    try { $pc.EnableSharing(0); Write-Log 'общий доступ для внешнего адаптера включён' } catch { Write-Log ('ошибка внешнего: ' + $_.Exception.Message) }
    Start-Sleep -Seconds 20
}

Write-Log '=== проверка ==='

try {
    for ($pass = 1; $pass -le 3; $pass++) {
        if (-not (Test-ApUp)) { Start-Ap }
        if (-not (Test-ApAddress)) {
            Write-Log ('проход ' + $pass + ': нет адреса 192.168.137.1, включаю общий доступ')
            Set-Ics
        }
        if ((Test-ApUp) -and (Test-ApAddress)) { break }
    }
    Write-Log ('сеть поднята: ' + (Test-ApUp) + ', адрес на месте: ' + (Test-ApAddress))
} catch {
    Write-Log ('критическая ошибка: ' + $_.Exception.Message)
}

Write-Log '=== конец ==='

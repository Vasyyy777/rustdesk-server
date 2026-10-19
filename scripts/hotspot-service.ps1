# Поднимает «Размещённую сеть» Windows и включает общий доступ к интернету (ICS).
# Запускать от имени администратора. Результат пишется в C:\ProgramData\RustDesk\hotspot.log

$log = 'C:\ProgramData\RustDesk\hotspot.log'
$logDir = Split-Path $log
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

function Write-Log([string]$text) {
    ('[' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + '] ' + $text) | Out-File $log -Append -Encoding UTF8
}

Write-Log '=== запуск точки доступа ==='

try {
    $hn = netsh wlan show hostednetwork | Out-String
    if ($hn -notmatch 'Started') {
        Write-Log 'запускаю размещённую сеть'
        Write-Log (netsh wlan start hostednetwork | Out-String)
        Start-Sleep -Seconds 10
    } else {
        Write-Log 'сеть уже запущена'
    }
} catch {
    Write-Log ('ошибка запуска сети: ' + $_.Exception.Message)
}

Start-Sleep -Seconds 5

try {
    # Внешний адаптер — любой IPv4, кроме локального и адреса точки доступа.
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
    Write-Log ('найден внешний: ' + [bool]$pub + ', найден Wi-Fi: ' + [bool]$priv)

    if ($pub -and $priv) {
        $pc = $ns.INetSharingConfigurationForINetConnection.Invoke($pub)
        $qc = $ns.INetSharingConfigurationForINetConnection.Invoke($priv)
        try { $pc.DisableSharing() } catch { }
        try { $qc.DisableSharing() } catch { }
        Start-Sleep -Seconds 3
        try { $qc.EnableSharing(1); Write-Log 'общий доступ для Wi-Fi включён' } catch { Write-Log ('ошибка Wi-Fi: ' + $_.Exception.Message) }
        Start-Sleep -Seconds 2
        try { $pc.EnableSharing(0); Write-Log 'общий доступ для внешнего адаптера включён' } catch { Write-Log ('ошибка внешнего: ' + $_.Exception.Message) }
    }
} catch {
    Write-Log ('ошибка ICS: ' + $_.Exception.Message)
}

Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -eq '192.168.137.1' } |
    ForEach-Object { Write-Log ('адрес точки доступа: ' + $_.IPAddress) }

Write-Log '=== готово ==='

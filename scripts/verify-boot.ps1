# Отчёт о состоянии сервера RustDesk после перезагрузки.
# Ждёт 60 секунд, собирает данные и кладёт отчёт в
# C:\ProgramData\RustDesk\verify-report.txt (и копию на рабочий стол).

$delaySec = 60
$report = 'C:\ProgramData\RustDesk\verify-report.txt'
$desktopCopy = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Проверка после перезагрузки.txt'

Start-Sleep -Seconds $delaySec

$out = @()
$out += 'Время проверки: ' + (Get-Date).ToString('dd.MM.yyyy HH:mm:ss')
$out += 'Загрузка системы: ' + (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$out += ''

$out += '=== СЛУЖБЫ ==='
Get-Service RustDesk, SharedAccess -ErrorAction SilentlyContinue |
    ForEach-Object { $out += ('  ' + $_.Name + ' = ' + $_.Status + ' / ' + $_.StartType) }

$out += '=== ПРОЦЕССЫ ==='
$hp = Get-Process hbbs, hbbr -ErrorAction SilentlyContinue
if ($hp) {
    $hp | ForEach-Object { $out += ('  ' + $_.ProcessName + ' pid=' + $_.Id + ' запущен ' + $_.StartTime) }
} else {
    $out += '  ВНИМАНИЕ: hbbs/hbbr не запущены'
}

$out += '=== ПОРТЫ 21115-21119 ==='
$l = netstat -ano | Select-String '2111[5-9]' | Select-String 'LISTENING'
if ($l) { $l | ForEach-Object { $out += ('  ' + $_.ToString().Trim()) } } else { $out += '  ВНИМАНИЕ: порты не слушаются' }

$out += '=== ПОДКЛЮЧЕНИЯ (21116) ==='
$c = netstat -ano | Select-String ':21116' | Select-String 'ESTABLISHED'
if ($c) { $c | ForEach-Object { $out += ('  ' + $_.ToString().Trim()) } } else { $out += '  нет соединений' }

$out += '=== КЛИЕНТ RUSTDESK ==='
$rd = Get-Process rustdesk -ErrorAction SilentlyContinue
if ($rd) {
    $rd | ForEach-Object { $out += ('  rustdesk pid=' + $_.Id + ' сессия=' + $_.SessionId) }
} else {
    $out += '  ВНИМАНИЕ: клиент не запущен'
}

$out += '=== WI-FI ТОЧКА ДОСТУПА ==='
$out += (netsh wlan show hostednetwork | Out-String)

$out += '=== IP-АДРЕСА ==='
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notmatch '^127\.' } |
    ForEach-Object { $out += ('  ' + $_.InterfaceAlias + ' = ' + $_.IPAddress) }

$out += '=== ОШИБКИ В ЛОГЕ КЛИЕНТА ==='
$log = 'C:\Users\' + $env:USERNAME + '\AppData\Roaming\RustDesk\log\rustdesk_rCURRENT.log'
if (Test-Path $log) {
    $e = Get-Content $log | Where-Object { $_ -match 'ERROR' }
    $out += ('  строк ERROR: ' + $e.Count)
    $e | Select-Object -Last 10 | ForEach-Object { $out += ('  ' + $_) }
} else {
    $out += '  лог не найден'
}

$out += '=== ОШИБКИ WINDOWS (10 минут после загрузки) ==='
$ev = Get-WinEvent -FilterHashtable @{ LogName = 'System', 'Application'; Level = 1, 2; StartTime = (Get-Date).AddMinutes(-10) } -ErrorAction SilentlyContinue
if ($ev) {
    $ev | Select-Object -First 15 | ForEach-Object { $out += ('  ' + $_.TimeCreated + ' | id=' + $_.Id + ' | ' + (($_.Message -split "`n")[0])) }
} else {
    $out += '  ошибок нет'
}

$out += ''
$out += '=== ИТОГ ==='
$ok = ($hp -ne $null) -and ($l -ne $null) -and ($rd -ne $null)
$out += $(if ($ok) { 'Сервер, порты и клиент — OK' } else { 'Есть проблемы — смотрите разделы выше' })

$out | Out-File $report -Encoding UTF8
try { Copy-Item $report $desktopCopy -Force -ErrorAction Stop } catch { }

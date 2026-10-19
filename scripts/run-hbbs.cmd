@echo off
rem Starts hbbs (ID/rendezvous server) with logging.
rem 1) Put your server IP into SERVER_IP.
rem 2) Put the content of id_ed25519 (private key, 88 chars) into KEY.
rem 3) Adjust BIN if hbbs.exe is installed elsewhere.

set "SERVER_IP=YOUR_SERVER_IP"
set "KEY=YOUR_PRIVATE_KEY"
set "BIN=%~dp0..\bin"
set "LOGDIR=C:\ProgramData\RustDesk"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
cd /d "%BIN%"
echo. >> "%LOGDIR%\hbbs.log"
echo ==== START %DATE% %TIME% ==== >> "%LOGDIR%\hbbs.log"
set RUST_LOG=info
hbbs.exe -k %KEY% -r %SERVER_IP%:21117 >> "%LOGDIR%\hbbs.log" 2>&1

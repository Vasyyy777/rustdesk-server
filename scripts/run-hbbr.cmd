@echo off
rem Starts hbbr (relay server) with logging.
rem Put the content of id_ed25519 (private key, 88 chars) into KEY.
rem Adjust BIN if hbbr.exe is installed elsewhere.

set "KEY=YOUR_PRIVATE_KEY"
set "BIN=%~dp0..\bin"
set "LOGDIR=C:\ProgramData\RustDesk"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
cd /d "%BIN%"
echo. >> "%LOGDIR%\hbbr.log"
echo ==== START %DATE% %TIME% ==== >> "%LOGDIR%\hbbr.log"
set RUST_LOG=info
hbbr.exe -k %KEY% >> "%LOGDIR%\hbbr.log" 2>&1

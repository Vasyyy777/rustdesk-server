@echo off
rem Starts RustDesk server (hbbs + hbbr).
rem Each process starts only if it is not already running.
rem Put a shortcut to this file into the Startup folder,
rem or run it from Task Scheduler at logon.

tasklist /FI "IMAGENAME eq hbbs.exe" 2>NUL | find /I "hbbs.exe" >NUL
if errorlevel 1 start "hbbs" /MIN "%~dp0run-hbbs.cmd"

tasklist /FI "IMAGENAME eq hbbr.exe" 2>NUL | find /I "hbbr.exe" >NUL
if errorlevel 1 start "hbbr" /MIN "%~dp0run-hbbr.cmd"

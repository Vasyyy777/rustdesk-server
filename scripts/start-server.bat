@echo off
rem Starts RustDesk server (hbbs + hbbr).
rem Put a shortcut to this file into the Startup folder,
rem or run it from Task Scheduler at logon.

start "hbbs" /MIN "%~dp0run-hbbs.cmd"
start "hbbr" /MIN "%~dp0run-hbbr.cmd"

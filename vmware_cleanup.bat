@echo off
echo ============================================
echo   VMware Driver Cleanup Script
echo   Please run as Administrator
echo ============================================
echo.

echo Stopping VMware services...
net stop VMAuthdService 2>nul
net stop VMnetDHCP 2>nul
net stop VMUSBArbService 2>nul
net stop "VMware NAT Service" 2>nul
net stop VmwareAutostartService 2>nul

echo.
echo Deleting VMware driver files...
del /f /q "C:\Windows\System32\drivers\vmx86.sys" 2>nul && echo Deleted: vmx86.sys || echo Not found or locked: vmx86.sys
del /f /q "C:\Windows\System32\drivers\vmci.sys" 2>nul && echo Deleted: vmci.sys || echo Not found or locked: vmci.sys
del /f /q "C:\Windows\System32\drivers\vmnet.sys" 2>nul && echo Deleted: vmnet.sys || echo Not found or locked: vmnet.sys
del /f /q "C:\Windows\System32\drivers\vmnetadapter.sys" 2>nul && echo Deleted: vmnetadapter.sys
del /f /q "C:\Windows\System32\drivers\vmnetbridge.sys" 2>nul && echo Deleted: vmnetbridge.sys
del /f /q "C:\Windows\System32\drivers\vmnetuserif.sys" 2>nul && echo Deleted: vmnetuserif.sys
del /f /q "C:\Windows\System32\drivers\vms3cap.sys" 2>nul && echo Deleted: vms3cap.sys

echo.
echo Deleting VMware directories...
rd /s /q "C:\Program Files (x86)\VMware" 2>nul
rd /s /q "C:\ProgramData\VMware" 2>nul
rd /s /q "%APPDATA%\VMware" 2>nul
rd /s /q "%LOCALAPPDATA%\VMware" 2>nul

echo.
echo ============================================
echo   Cleanup completed!
echo   Please restart your computer now.
echo ============================================
echo.
pause

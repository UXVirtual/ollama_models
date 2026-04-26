@echo off
setlocal

set PORT=11434

:: Firewall
netsh advfirewall firewall show rule name="Ollama WSL2" >nul 2>&1
if %errorlevel% neq 0 (
    netsh advfirewall firewall add rule name="Ollama WSL2" dir=in action=allow protocol=TCP localport=%PORT%
    echo Firewall rule created
) else (
    echo Firewall rule already exists
)

:: Start WSL and keep it alive
echo Starting WSL2...
start "" /B wsl -e sh -c "while true; do sleep 10; done"

:: Determine LAN IP (Specifically look for 192.168.x.x addresses)
for /f "delims=" %%I in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like '192.168.*' } | Select-Object -First 1).IPAddress"') do set LAN_IP=%%I

if "%LAN_IP%"=="" (
    echo ERROR: No LAN IP found.
    exit /b 1
)
echo LAN IP: %LAN_IP%

:: Portproxy: LAN-IP -> localhost (WSL2 localhost forwarding)
netsh interface portproxy delete v4tov4 listenport=%PORT% listenaddress=%LAN_IP% >nul 2>&1
netsh interface portproxy add v4tov4 listenport=%PORT% listenaddress=%LAN_IP% connectport=%PORT% connectaddress=127.0.0.1

echo Forwarding %LAN_IP%:%PORT% -^> 127.0.0.1:%PORT% (WSL2 localhost forwarding)
echo.
echo Ollama is accessible from the following network addresses:
echo   - http://localhost:%PORT%
echo   - http://%LAN_IP%:%PORT%
echo.
echo Press any key in this window to shut down...
pause >nul

:: Cleanup
netsh interface portproxy delete v4tov4 listenport=%PORT% listenaddress=%LAN_IP% >nul 2>&1
wsl --shutdown
echo WSL2 shut down.

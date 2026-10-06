@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
rem ===================== 配置 =====================
set "HOTSPOT=改成你的手机热点名"
rem ================================================
title 恢复到手机热点 %HOTSPOT%
echo ============================================================
echo   切回手机热点 %HOTSPOT%
echo ============================================================
echo.
if "%HOTSPOT%"=="改成你的手机热点名" (
  echo    *** 先打开这个 bat, 把上面的 HOTSPOT 改成你手机热点的名字
  goto :end
)
echo 正在连接 %HOTSPOT% ...
netsh wlan connect name="%HOTSPOT%" >nul 2>&1
ping -n 8 127.0.0.1 >nul
echo.
echo 当前连接的网络:
echo ------------------------------------------------------------
netsh wlan show interfaces | findstr /C:"SSID" /C:"BSSID"
powershell -NoProfile -Command "'Link speed: ' + (Get-NetAdapter -Name WLAN).LinkSpeed"
echo ------------------------------------------------------------
%SystemRoot%\System32\curl.exe -s -m 8 --ssl-no-revoke -o NUL -w "%%{http_code}" http://www.baidu.com/ > "%TEMP%\hot_code.txt" 2>NUL
set "CODE="
for /f "usebackq" %%C in ("%TEMP%\hot_code.txt") do set CODE=%%C
del "%TEMP%\hot_code.txt" >nul 2>&1
echo.
echo 百度返回码: %CODE%
echo.
if "%CODE%"=="000" (
  echo   *** 热点不通: 检查手机「个人热点」是否开着、手机是否还有流量
) else (
  echo   *** 已回到手机热点, 网络正常
)
echo.
echo  * 想让热点本身更快: 手机「设置-其他网络与连接-个人热点-
echo    热点配置-AP频段」改成 5GHz
echo.
:end
echo %cmdcmdline% | findstr /i /c:"%~nx0" >nul && pause
exit /b

@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
title 校园网一键: 切5GHz + 认证助手
rem ===================== 配置 =====================
set "SSID=CUMT_Stu"
set "MENTER=http://9.9.9.9"
rem 校园网络助手.exe 是可选的自动登录器, 放同目录或 Downloads 里就会被用上
set "USERINFO=C:\Users\Public\Documents\user.info"
set "HELPER="
if exist "%~dp0校园网络助手.exe" set "HELPER=%~dp0校园网络助手.exe"
if not defined HELPER if exist "%USERPROFILE%\Downloads\校园网络助手.exe" set "HELPER=%USERPROFILE%\Downloads\校园网络助手.exe"
rem ================================================

echo ============================================================
echo  切 5GHz 校园网 %SSID%  +  认证助手
echo ============================================================
echo.
echo [1/6] 当前状态:
call :show
echo.
echo [2/6] 连接 %SSID% ...
netsh wlan show interfaces | findstr /C:"%SSID%" >nul
if errorlevel 1 netsh wlan connect name=%SSID% >nul 2>&1
echo.
echo [3/6] 等 IP 地址就绪 （IP 没定下来就开认证页, 页面带着旧 IP, 输完点登录会没反应）
set /a TRY=0
:waitip
set "IP="
for /f "tokens=2 delims=:(" %%a in ('ipconfig ^| findstr /C:"IPv4"') do set "IP=%%a"
set "IP=%IP: =%"
set /a TRY+=1
if not "%IP%"=="" echo    IP = %IP%
if "%IP%"=="" if %TRY% LSS 20 (ping -n 2 127.0.0.1 >nul & goto :waitip)
if "%IP%"=="" goto :ipfail
echo.
echo [4/6] 检查频段 （2.4GHz 实测会掉到几十 KB/s, 尽量待在 5GHz）
set "B5="
set "B24="
netsh wlan show interfaces | findstr /C:"5 GHz" >nul && set "B5=1"
netsh wlan show interfaces | findstr /C:"2.4 GHz" >nul && set "B24=1"
if defined B24 (
  echo    现在挂在 2.4GHz, 重连一次试试 5GHz ...
  netsh wlan disconnect >nul 2>&1
  ping -n 4 127.0.0.1 >nul
  netsh wlan connect name=%SSID% >nul 2>&1
  ping -n 8 127.0.0.1 >nul
  call :show
) else (
  if defined B5 echo    频段 OK: 5 GHz
)
echo.
echo [5/6] 判断要不要登录
call :check
if "%CODE%"=="200" goto :online
echo.
echo [6/6] 认证
if not defined HELPER goto :manual
if not exist "%HELPER%" goto :manual
if exist "%USERINFO%" (
  echo    用 校园网络助手 自动登录 （账号已保存, 不用再输）
) else (
  echo    第一次用: 在弹出的窗口里输一次 学号 密码 运营商 （0联通 1电信 2移动）, 它会记住
)
echo    若助手窗口没有自动关掉, 按里面提示操作完再关它
start "" /wait "%HELPER%"
call :check
if "%CODE%"=="200" goto :ok
echo    自动登录没成功, 改用浏览器认证页兜底
goto :manual

:manual
echo    打开认证页 %MENTER% ...
start "" %MENTER%
:key
if not defined SESSIONNAME goto :afterkey
choice /c rq /n /t 180 /d q /m "  按 R 重开认证页 / 按 Q 结束: "
if errorlevel 2 goto :afterkey
start "" %MENTER%
echo    已重开认证页, 再登录一次
goto :key
:afterkey
call :check
if "%CODE%"=="200" goto :ok
echo    *** 还没成功: 检查账号密码 / 登录时选的线路 / 终端数上限
goto :tips

:ok
echo    *** 认证成功, 可以上网了
goto :tips

:online
echo    已经联网, 不用登录 （认证后 9.9.9.9 打不开是正常的: 认证页只在未认证时才有）

:tips
echo.
echo ==================== 出问题了看这里 ====================
echo  * 提示「终端IP已在线」= 去 9.9.9.9 的自助服务-在线状态 下线旧终端
echo  * 一个账号最多 3 个终端同时在线, 别同时用助手的自动登录和网页登录
echo  * 学生账号 周日-周四 23:30 至次日 07:00 停止上网认证
echo  * 校园网登不上/太慢: 双击「恢复到手机热点.bat」切回热点
echo  * 报修 400-008-9233 / 83592139
echo ========================================================
goto :end

:ipfail
echo    *** 20 秒没拿到 IP: 认证服务器或宿舍AP 的问题, 关掉再开 Wi-Fi 或稍后再试
:end
echo.
echo %cmdcmdline% | findstr /i /c:"%~nx0" >nul && pause
exit /b

:show
netsh wlan show interfaces | findstr /C:"SSID" /C:"BSSID"
powershell -NoProfile -Command "'Link speed: ' + (Get-NetAdapter -Name WLAN).LinkSpeed"
set "B5="
set "B24="
netsh wlan show interfaces | findstr /C:"5 GHz" >nul && set "B5=1"
netsh wlan show interfaces | findstr /C:"2.4 GHz" >nul && set "B24=1"
if defined B24 echo    频段: 2.4 GHz  （慢）
if defined B5 if not defined B24 echo    频段: 5 GHz  （快）
if not defined B5 if not defined B24 echo    频段: 读不到
goto :eof

:check
%SystemRoot%\System32\curl.exe -s -m 8 --ssl-no-revoke -o NUL -w "%%{http_code}" http://www.baidu.com/ > "%TEMP%\cumt_code.txt" 2>NUL
set "CODE="
for /f "usebackq" %%C in ("%TEMP%\cumt_code.txt") do set CODE=%%C
del "%TEMP%\cumt_code.txt" >nul 2>&1
echo    百度返回码: %CODE%   (000=没认证, 200=已联网)
goto :eof

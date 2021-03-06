@ECHO OFF

REM This script builds and signs the Windows packages on Gitlab

if %ARCH% == 32 (
  SET ARCHLONG=i686
  SET CYGROOT=C:\cygwin
  SET SETUP=setup-x86.exe
)

if %ARCH% == 64 (
  SET ARCHLONG=x86_64
  SET CYGROOT=C:\cygwin64
  SET SETUP=setup-x86_64.exe
)

powershell -Command "(New-Object Net.WebClient).DownloadFile('http://www.cygwin.com/%SETUP%', '%SETUP%')"
SET CYGCACHE=%CYGROOT%\var\cache\setup
SET CI_PROJECT_DIR_MFMT=%CI_PROJECT_DIR:\=/%
SET CI_PROJECT_DIR_CFMT=%CI_PROJECT_DIR_MFMT:C:/=/cygdrive/c/%
SET DESTCOQ=C:\coq%ARCH%_inst
SET COQREGTESTING=Y
SET PATH=%PATH%;C:\Program Files\7-Zip\;C:\Program Files\Microsoft SDKs\Windows\v7.1\Bin

if exist %CYGROOT%\build\ rd /s /q %CYGROOT%\build
if exist %DESTCOQ%\ rd /s /q %DESTCOQ%

call %CI_PROJECT_DIR%\dev\build\windows\MakeCoq_MinGW.bat -threads=1 ^
  -arch=%ARCH% -installer=Y -coqver=%CI_PROJECT_DIR_CFMT% ^
  -destcyg=%CYGROOT% -destcoq=%DESTCOQ% -cygcache=%CYGCACHE% ^
  -addon=bignums -make=N ^
  -setup %CI_PROJECT_DIR%\%SETUP% || GOTO ErrorExit

copy "%CYGROOT%\build\coq-local\dev\nsis\*.exe" dev\nsis || GOTO ErrorExit
7z a coq-opensource-archive-windows-%ARCHLONG%.zip %CYGROOT%\build\tarballs\* || GOTO ErrorExit

REM DO NOT echo the signing command below, as this would leak secrets in the logs
IF DEFINED WIN_CERTIFICATE_PATH (
  IF DEFINED WIN_CERTIFICATE_PASSWORD (
    ECHO Signing package
    @signtool sign /f %WIN_CERTIFICATE_PATH% /p %WIN_CERTIFICATE_PASSWORD% dev\nsis\*.exe
    signtool verify /pa dev\nsis\*.exe
  )
)

GOTO :EOF

:ErrorExit
  ECHO ERROR %0 failed
  EXIT /b 1

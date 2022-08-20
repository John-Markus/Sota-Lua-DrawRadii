@ECHO OFF
SETLOCAL
SET SCRIPTNAME=Sota-Lua-DrawRadii.app.lua
SET SCRIPTDIR=%~dp0
SET LUADIR=%APPDATA%\Portalarium\Shroud of the Avatar\Lua
ECHO --------------------------------------------------------------------------
ECHO Windows Lua Hardlink installer
ECHO --------------------------------------------------------------------------
ECHO.
ECHO Script path:     %SCRIPTDIR%\%SCRIPTNAME%
ECHO SotA Lua folder: %LUADIR%
IF NOT EXIST "%SCRIPTDIR%\%SCRIPTNAME%" GOTO NO_SCRIPT
net session >nul 2>&1
IF NOT %errorLevel% == 0 GOTO NOT_ADMIN
ECHO.
ECHO Would you like to install this lua script ?
ECHO Using command: MKLINK %LUADIR%\%SCRIPTNAME% 
ECHO.                      %SCRIPTDIR%\%SCRIPTNAME%
PAUSE
MKLINK "%LUADIR%\%SCRIPTNAME%" "%SCRIPTDIR%\%SCRIPTNAME%"
PAUSE
EXIT /B
:NO_SCRIPT
ECHO - Error: cannot find script to install: %SCRIPTDIR%\%SCRIPTNAME%
PAUSE
EXIT /B
:NOT_ADMIN
ECHO - Error: Please run this script with Administrator Priviledges
PAUSE
EXIT /B
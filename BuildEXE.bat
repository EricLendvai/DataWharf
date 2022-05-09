@echo off

::echo on
::echo HB_FASTCGI_ROOT = %HB_FASTCGI_ROOT%
::echo EXEName = %EXEName%
::echo BuildMode = %BuildMode%
::echo SiteRootFolder = %SiteRootFolder%
::echo HB_COMPILER = %HB_COMPILER%

if %HB_FASTCGI_ROOT%. == . goto MissingEnvironmentVariables
if %EXEName%. == . goto MissingEnvironmentVariables
if %BuildMode%. == . goto MissingEnvironmentVariables
if %SiteRootFolder%. ==. goto MissingEnvironmentVariables
if %HB_COMPILER%. ==. goto MissingEnvironmentVariables

if not exist %EXEName%_windows.hbp (
    echo Invalid Workspace Folder. Missing file %EXEName%_windows.hbp
    goto End
)

if %BuildMode%. == debug.   goto GoodParameters
if %BuildMode%. == release. goto GoodParameters

echo You must set Environment Variable BuildMode as "debug" or "release"
goto End

:GoodParameters

rem The following command most likely will do nothing if the SoftKill task was called first.
taskkill /IM FCGI%EXEName%.exe /f /t 2>nul

if %HB_COMPILER% == msvc64 call "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x86_amd64

if %HB_COMPILER% == mingw64 set PATH=C:\Program Files\mingw-w64\x86_64-8.1.0-win32-seh-rt_v6-rev0\mingw64\bin;%PATH%

set HB_PATH=C:\Harbour

set PATH=%HB_PATH%\bin\win\%HB_COMPILER%;C:\HarbourTools;%PATH%

echo HB_PATH     = %HB_PATH%
echo HB_COMPILER = %HB_COMPILER%
echo PATH        = %PATH%

md build 2>nul
md build\win64 2>nul
md build\win64\%HB_COMPILER% 2>nul
md build\win64\%HB_COMPILER%\%BuildMode% 2>nul
md build\win64\%HB_COMPILER%\%BuildMode%\hbmk2 2>nul

rem the following will output the current datetime
for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
set mytime=%time%
echo local l_cBuildInfo := "%HB_COMPILER% %BuildMode% %mydate% %mytime%">BuildInfo.txt

del build\win64\%HB_COMPILER%\%BuildMode%\%EXEName%.exe 2>nul
if exist build\win64\%HB_COMPILER%\%BuildMode%\%EXEName%.exe (
    echo Could not delete previous version of %EXEName%.exe
    goto End
)

::	-b        = debug
::  /w3       = warn for variable declarations
::  /es2      = process warning as errors
::  /gc3      = Pure C code with no HVM
::  /p        = Leave generated ppo files

if %BuildMode% == debug (
    copy debugger_on.hbm debugger.hbm
rem  cannot used -shared due to some libs. Still researching into this matter.
rem    hbmk2 %EXEName%_windows.hbp -b -p -w3 -dDEBUGVIEW
    hbmk2 %EXEName%_windows.hbp %HB_FASTCGI_ROOT%\hb_fcgi\hb_fcgi_windows.hbm -b -p -w3 -dDEBUGVIEW
) else (
    copy debugger_off.hbm debugger.hbm
    rem can not do -fullstatic due to libfcgi
rem    hbmk2 %EXEName%_windows.hbp -w3  -static -dDEBUGVIEW
    hbmk2 %EXEName%_windows.hbp %HB_FASTCGI_ROOT%\hb_fcgi\hb_fcgi_windows.hbm  -w3  -static -dDEBUGVIEW
)

echo Current time is %mydate% %mytime%

if not exist build\win64\%HB_COMPILER%\%BuildMode%\%EXEName%.exe (
    echo Failed To build %EXEName%.exe
) else (
    if errorlevel 0 (
        echo.
        echo No Errors

        del %WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe
        if exist %WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe (
            echo Failed to delete previous version of %WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe
            goto End
        )
        rem Extra files needed if compiled with mingw64
        if %HB_COMPILER% == mingw64 copy "c:\Program Files\mingw-w64\x86_64-8.1.0-win32-seh-rt_v6-rev0\mingw64\bin\libstdc++-6.dll"    "%WebsiteDrive%%SiteRootFolder%backend\libstdc++-6.dll"
        if %HB_COMPILER% == mingw64 copy "c:\Program Files\mingw-w64\x86_64-8.1.0-win32-seh-rt_v6-rev0\mingw64\bin\libgcc_s_seh-1.dll" "%WebsiteDrive%%SiteRootFolder%backend\libgcc_s_seh-1.dll"

        if %HB_COMPILER% == msvc64 del "%WebsiteDrive%%SiteRootFolder%backend\libstdc++-6.dll"
        if %HB_COMPILER% == msvc64 del "%WebsiteDrive%%SiteRootFolder%backend\libgcc_s_seh-1.dll"

        copy "build\win64\%HB_COMPILER%\%BuildMode%\%EXEName%.exe" "%WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe"
        if exist %WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe (
            echo Copied file build\win64\%HB_COMPILER%\%BuildMode%\%EXEName%.exe to %WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe
        ) else (
            echo Failed to update file %WebsiteDrive%%SiteRootFolder%backend\FCGI%EXEName%.exe
        )

        copy %HB_FASTCGI_ROOT%\fcgi-2.4.1\libfcgi\%HB_COMPILER%\release\libfcgi.dll "build\win64\%HB_COMPILER%\%BuildMode%\libfcgi.dll"
        copy %HB_FASTCGI_ROOT%\fcgi-2.4.1\libfcgi\%HB_COMPILER%\release\libfcgi.dll "%WebsiteDrive%%SiteRootFolder%backend\libfcgi.dll"

        echo.
        echo Ready            BuildMode = %BuildMode%
        
    ) else (
        echo Compilation Error
        if errorlevel  1 echo Unknown platform
        if errorlevel  2 echo Unknown compiler
        if errorlevel  3 echo Failed Harbour detection
        if errorlevel  5 echo Failed stub creation
        if errorlevel  6 echo Failed in compilation (Harbour, C compiler, Resource compiler)
        if errorlevel  7 echo Failed in final assembly (linker or library manager)
        if errorlevel  8 echo Unsupported
        if errorlevel  9 echo Failed to create working directory
        if errorlevel 19 echo Help
        if errorlevel 10 echo Dependency missing or disabled
        if errorlevel 20 echo Plugin initialization
        if errorlevel 30 echo Too deep nesting
        if errorlevel 50 echo Stop requested
    )
)

goto End
:MissingEnvironmentVariables
echo Missing Environment Variables
:End
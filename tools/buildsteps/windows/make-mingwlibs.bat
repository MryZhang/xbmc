@ECHO OFF
SETLOCAL

rem batch file to compile mingw libs via BuildSetup
PUSHD %~dp0\..\..\..
SET WORKDIR=%CD%
POPD

SET PROMPTLEVEL=prompt
SET BUILDMODE=clean
SET opt=mintty
SET build32=yes
SET build64=no
SET buildArm=no
SET vcarch=x86
SET msys2=msys64
SET tools=mingw
SET win10=no
SET UWPSDKVer=

FOR %%b in (%1, %2, %3, %4) DO (
  IF %%b==noprompt SET PROMPTLEVEL=noprompt
  IF %%b==clean SET BUILDMODE=clean
  IF %%b==noclean SET BUILDMODE=noclean
  IF %%b==sh SET opt=sh
  IF %%b==build64 ( 
    SET build64=yes 
    SET build32=no
    SET buildArm=no
    SET vcarch=amd64
    )
  IF %%b==buildArm ( 
    SET build64=no 
    SET build32=no
    SET buildArm=yes
    SET vcarch=arm
    )
  IF %%b==msvc SET tools=msvc
  IF %%b==win10 (
    SET tools=msvc
    SET win10=yes
  )
)
:: Export full current PATH from environment into MSYS2
set MSYS2_PATH_TYPE=inherit

:: setup MSVC env
SET vcstore=
IF %win10%==yes (
  SET vcstore=store
  SET UWPSDKVer=10.0.14393.0
)

IF %vcarch%==amd64 goto SetupMSVC
if exist "%VS140COMNTOOLS%..\..\VC\bin\amd64_%vcarch%" set vcarch=amd64_%vcarch%
:SetupMSVC
echo setup MSVC for %vcarch% %vcstore% %UWPSDKVer%
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat" %vcarch% %vcstore% %UWPSDKVer% || exit /b 1

REM Prepend the msys and mingw paths onto %PATH%
SET MSYS_INSTALL_PATH=%WORKDIR%\project\BuildDependencies\msys
SET PATH=%MSYS_INSTALL_PATH%\mingw\bin;%MSYS_INSTALL_PATH%\bin;%PATH%
SET ERRORFILE=%WORKDIR%\project\Win32BuildSetup\errormingw
SET BS_DIR=%WORKDIR%\project\Win32BuildSetup

IF EXIST %ERRORFILE% del %ERRORFILE% > NUL

rem compiles a bunch of mingw libs and not more
IF %opt%==sh (
  IF EXIST %WORKDIR%\project\BuildDependencies\%msys2%\usr\bin\sh.exe (
    ECHO starting sh shell
    %WORKDIR%\project\BuildDependencies\%msys2%\usr\bin\sh.exe --login -i /xbmc/tools/buildsteps/windows/make-mingwlibs.sh --prompt=%PROMPTLEVEL% --mode=%BUILDMODE% --build32=%build32% --build64=%build64% --buildArm=%buildArm% --tools=%tools% --win10=%win10%
    GOTO END
  ) ELSE (
    GOTO ENDWITHERROR
  )
)
IF EXIST %WORKDIR%\project\BuildDependencies\%msys2%\usr\bin\mintty.exe (
  ECHO starting mintty shell
  %WORKDIR%\project\BuildDependencies\%msys2%\usr\bin\mintty.exe -d -i /msys2.ico /usr/bin/bash --login /xbmc/tools/buildsteps/windows/make-mingwlibs.sh --prompt=%PROMPTLEVEL% --mode=%BUILDMODE% --build32=%build32% --build64=%build64% --buildArm=%buildArm% --tools=%tools% --win10=%win10%
  GOTO END
)
GOTO ENDWITHERROR

:ENDWITHERROR
  ECHO msys environment not found
  ECHO bla>%ERRORFILE%
  EXIT /B 1
  
:END
  ECHO exiting msys environment
  IF EXIST %ERRORFILE% (
    ECHO failed to build mingw libs
    EXIT /B 1
  )
  EXIT /B 0

ENDLOCAL

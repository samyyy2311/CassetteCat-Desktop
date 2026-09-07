@echo off
set "PATH=C:\Qt\6.11.2\mingw_64\bin;C:\Qt\Tools\mingw1310_64\bin;%PATH%"
if /I "%~1"=="release" (
    if not exist "%~dp0build\release\CassetteCat.exe" (
        echo Release build not found. Run: cmake --build --preset release --parallel 1
        exit /b 1
    )
    cd /D "%~dp0build\release"
) else (
    cd /D "%~dp0build\dev"
)
start "" "CassetteCat.exe"

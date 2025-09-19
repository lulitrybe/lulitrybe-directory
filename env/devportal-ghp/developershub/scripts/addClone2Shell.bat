@echo off

REM Get the directory where this script (and the 'clone' script) is located
set SCRIPT_DIR=%~dp0
set CLONE_SCRIPT_PATH=%SCRIPT_DIR%clone.bat
set USER_BIN_DIR=%USERPROFILE%\.local\bin
set INSTALL_TARGET=%USER_BIN_DIR%\clone.bat
set SYSTEM_INSTALL_DONE=false

REM --- Debugging ---
echo Executing addClone2Shell.bat
echo SCRIPT_DIR is: %SCRIPT_DIR%
echo Expecting clone script at: %CLONE_SCRIPT_PATH%
echo Checking if file exists...
if exist "%CLONE_SCRIPT_PATH%" (
    echo Clone script found.
) else (
    echo Clone script not found.
)

REM Verify source script exists
if not exist "%CLONE_SCRIPT_PATH%" (
    echo Error: clone script not found at %CLONE_SCRIPT_PATH%
    exit /b 1
)

REM --- Create user bin directory and copy script ---
echo Setting up user-specific installation to %INSTALL_TARGET%...
if not exist "%USER_BIN_DIR%" (
    echo Creating directory: %USER_BIN_DIR%
    mkdir "%USER_BIN_DIR%"
)

echo Copying clone script to %INSTALL_TARGET%
copy "%CLONE_SCRIPT_PATH%" "%INSTALL_TARGET%" >nul
if %errorlevel% equ 0 (
    echo Successfully copied clone script to %INSTALL_TARGET%
) else (
    echo Error: Failed to copy clone script
    exit /b 1
)

REM --- Add to PATH if not already present ---
echo Checking if %USER_BIN_DIR% is in PATH...
echo %PATH% | findstr /i "%USER_BIN_DIR%" >nul
if %errorlevel% neq 0 (
    echo Adding %USER_BIN_DIR% to beginning of user PATH...
    setx PATH "%USER_BIN_DIR%;%PATH%" >nul 2>nul
    if %errorlevel% equ 0 (
        echo Successfully added %USER_BIN_DIR% to PATH
        echo Please restart your command prompt for changes to take effect
    ) else (
        echo setx failed, trying PowerShell method...
        REM Replace single backslashes with double backslashes for PowerShell
        set PS_USER_BIN_DIR=%USER_BIN_DIR:\=\\%
        powershell -Command "& { param($newPath) try { $userPath = [Environment]::GetEnvironmentVariable('PATH', 'User'); if ($userPath -notlike '*' + $newPath + '*') { [Environment]::SetEnvironmentVariable('PATH', $newPath + ';' + $userPath, 'User'); Write-Host 'Successfully added' $newPath 'to beginning of PATH using PowerShell'; exit 0 } else { Write-Host $newPath 'already in user PATH'; exit 0 } } catch { Write-Host 'PowerShell method failed'; exit 1 } }" -ArgumentList "%PS_USER_BIN_DIR%"
        if %errorlevel% equ 0 (
            echo Please restart your command prompt for changes to take effect
        ) else (
            echo Warning: Failed to add directory to PATH automatically
            echo Please manually add %USER_BIN_DIR% to the beginning of your PATH environment variable
        )
    )
) else (
    echo %USER_BIN_DIR% is already in PATH
)

echo Setup completed successfully!
exit /b 0

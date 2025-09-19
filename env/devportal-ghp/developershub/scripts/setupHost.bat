@echo off
REM Get the directory where this script is located
set SCRIPT_DIR=%~dp0

REM --- Run additional setup scripts ---

REM Run getSubProjects script
set GET_SUB_PROJECTS_SCRIPT=%SCRIPT_DIR%getSubProjects.bat
if exist "%GET_SUB_PROJECTS_SCRIPT%" (
    echo Running setup script: %GET_SUB_PROJECTS_SCRIPT%
    call "%GET_SUB_PROJECTS_SCRIPT%"
    if %ERRORLEVEL% neq 0 (
        echo Warning: %GET_SUB_PROJECTS_SCRIPT% finished with errors.
    ) else (
        echo %GET_SUB_PROJECTS_SCRIPT% completed successfully.
    )
) else (
    echo Warning: Setup script not found: %GET_SUB_PROJECTS_SCRIPT%
)

REM Run addClone2Shell script
set ADD_CLONE_SCRIPT=%SCRIPT_DIR%addClone2Shell.bat
if exist "%ADD_CLONE_SCRIPT%" (
    echo Running additional setup script: %ADD_CLONE_SCRIPT%
    call "%ADD_CLONE_SCRIPT%"
    if %ERRORLEVEL% neq 0 (
        echo Warning: %ADD_CLONE_SCRIPT% finished with errors.
    ) else (
        echo %ADD_CLONE_SCRIPT% completed successfully.
    )
) else (
    echo Warning: Additional setup script not found: %ADD_CLONE_SCRIPT%
)

echo - The 'clone' command symlink created in ~/.local/bin/
echo -----------------------------------------------------
echo Setup finished.
echo -----------------------------------------------------
pause


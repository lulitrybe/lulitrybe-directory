@echo off
setlocal enabledelayedexpansion

REM Check for help option first
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help

REM Initialize variables
set VERBOSE=false
set REMOVE=false
set SITE_MODE=false
set REPO_NAME=
set SITE_NAME=

REM Parse arguments with proper loop
set ARG_COUNT=0
for %%a in (%*) do set /a ARG_COUNT+=1

set /a CURRENT_ARG=1
:parse_args
if %CURRENT_ARG% gtr %ARG_COUNT% goto args_parsed

call set ARG=%%%CURRENT_ARG%

if "!ARG!"=="--verbose" (
    set VERBOSE=true
    goto next_arg
)
if "!ARG!"=="-v" (
    set VERBOSE=true
    goto next_arg
)
if "!ARG!"=="--remove" (
    set REMOVE=true
    goto next_arg
)
if "!ARG!"=="-rm" (
    set REMOVE=true
    goto next_arg
)
if "!ARG!"=="--site" (
    set SITE_MODE=true
    goto next_arg
)
if "!ARG!"=="-s" (
    set SITE_MODE=true
    goto next_arg
)
if "!ARG:~0,1!"=="-" (
    echo Error: Unknown option '!ARG!'
    echo Usage: clone [--verbose ^| -v] [--remove ^| -rm] [--site ^| -s] ^<repo-name-or-site-name^>
    exit /b 1
)

REM This should be the repository name or site name
if "%SITE_MODE%"=="true" (
    set SITE_NAME=!ARG!
) else (
    set REPO_NAME=!ARG!
)

:next_arg
set /a CURRENT_ARG+=1
goto parse_args

:args_parsed
REM Function to log messages in verbose mode
if "%VERBOSE%"=="true" echo [DEBUG] Starting clone script

REM Validate arguments
if "%SITE_MODE%"=="true" (
    if "%SITE_NAME%"=="" (
        echo Error: The --site or -s option must be followed by a site name.
        echo Usage: clone [--verbose ^| -v] [--remove ^| -rm] --site ^<site-name^>
        exit /b 1
    )
) else (
    if "%REPO_NAME%"=="" (
        echo Usage: clone [--verbose ^| -v] [--remove ^| -rm] [--site ^| -s] ^<repo-name-or-site-name^>
        exit /b 1
    )
    REM Skip character validation for now - SEO is a valid name
    REM echo "%REPO_NAME%" | findstr /r "[^a-zA-Z0-9_.-]" >nul
    REM if %errorlevel% equ 0 (
    REM     echo Error: Repository name '%REPO_NAME%' contains invalid characters. Use only letters, numbers, hyphens, periods, and underscores.
    REM     exit /b 1
    REM )
)

REM Set repo slug and project based on mode
if "%SITE_MODE%"=="true" (
    if "%VERBOSE%"=="true" echo [DEBUG] Site mode: %SITE_NAME%
) else (
    set REPO_SLUG=Nop.Plugin.Opensoft.%REPO_NAME%
    if "%VERBOSE%"=="true" echo [DEBUG] Single repo mode: %REPO_SLUG%
)
set DEVOPS_PROJECT=git@ssh.dev.azure.com:v3/FarHeapSolutions/Nop%%20Plugins

REM Get current directory
set CURRENT_DIR=%CD%
if "%VERBOSE%"=="true" echo [DEBUG] Current directory: %CURRENT_DIR%

REM Search for solution files - use array approach
set SOLUTION_COUNT=0
set CHOSEN_SOLUTION=

REM Search up the directory tree
set SEARCH_DIR=%CD%
:search_up_loop
if "%VERBOSE%"=="true" echo [DEBUG] Searching up in: %SEARCH_DIR%

REM Check for .sln files in current search directory
for %%f in ("%SEARCH_DIR%\*.sln") do (
    if exist "%%f" (
        set /a SOLUTION_COUNT+=1
        REM Normalize path to remove double slashes
        set "NORMALIZED_PATH=%%f"
        set "NORMALIZED_PATH=!NORMALIZED_PATH:\\=\!"
        set SOLUTION_!SOLUTION_COUNT!=!NORMALIZED_PATH!
        if "%VERBOSE%"=="true" echo [DEBUG] Found solution: !NORMALIZED_PATH!
    )
)

REM Check if we've reached nopSetup or workspace folder
for %%d in ("%SEARCH_DIR%") do set DIR_NAME=%%~nd
if /i "%DIR_NAME%"=="nopSetup" goto end_search_up
if /i "%DIR_NAME%"=="workspace" goto end_search_up

REM Move up one directory
for %%d in ("%SEARCH_DIR%") do set PARENT_DIR=%%~dpd
set PARENT_DIR=%PARENT_DIR:~0,-1%
if "%SEARCH_DIR%"=="%PARENT_DIR%" goto end_search_up
set SEARCH_DIR=%PARENT_DIR%
goto search_up_loop

:end_search_up
REM If no solutions found going up, search down 3 levels
if %SOLUTION_COUNT%==0 (
    if "%VERBOSE%"=="true" echo [DEBUG] No solutions found going up, searching down 3 levels
    call :search_down "%CURRENT_DIR%" 0
)

REM Handle solution selection - simplified version
if %SOLUTION_COUNT%==0 (
    echo No solution file found
    exit /b 1
)

if %SOLUTION_COUNT%==1 (
    set CHOSEN_SOLUTION=!SOLUTION_1!
    if "%VERBOSE%"=="true" echo [DEBUG] Using single solution: !CHOSEN_SOLUTION!
    goto solution_selected
)

REM Multiple solutions - show enhanced selection menu
echo.
echo Multiple solution files found:
echo ================================
call :display_solution_choices
echo.
set /p CHOICE=Please choose a solution file (1-%SOLUTION_COUNT%):
call :validate_and_set_choice

:solution_selected
if "%CHOSEN_SOLUTION%"=="" (
    echo Invalid selection
    exit /b 1
)

REM Get solution directory
for %%f in ("%CHOSEN_SOLUTION%") do set SOLUTION_DIR=%%~dpf
set SOLUTION_DIR=%SOLUTION_DIR:~0,-1%
if "%VERBOSE%"=="true" echo [DEBUG] Solution directory: %SOLUTION_DIR%

REM Check if Plugins folder exists
if not exist "%SOLUTION_DIR%\Plugins" (
    echo Error: Plugins folder not found at %SOLUTION_DIR%\Plugins
    exit /b 1
)

set PLUGINS_DIR=%SOLUTION_DIR%\Plugins
if "%VERBOSE%"=="true" echo [DEBUG] Plugins directory: %PLUGINS_DIR%

REM Handle operations based on parsed arguments
if "%SITE_MODE%"=="true" goto handle_site_mode

REM Handle single repository operations
if "%REMOVE%"=="true" (
    call :process_repository remove "%REPO_NAME%"
) else (
    call :process_repository clone "%REPO_NAME%"
)

cd /d "%CURRENT_DIR%"
echo Script completed successfully.
exit /b 0

:handle_site_mode
REM Determine workspace root more reliably
pushd "%~dp0"
cd ..
set WORKSPACE_ROOT=%CD%
popd

set PLUGIN_LIST_FILE=%WORKSPACE_ROOT%\sites\%SITE_NAME%\PluginList.txt

if "%VERBOSE%"=="true" echo [DEBUG] Looking for plugin list at: %PLUGIN_LIST_FILE%

if not exist "%PLUGIN_LIST_FILE%" (
    echo Error: PluginList.txt file not found at '%PLUGIN_LIST_FILE%'.
    echo.
    echo Expected structure:
    echo   %WORKSPACE_ROOT%\sites\%SITE_NAME%\PluginList.txt
    echo.
    echo Available sites:
    if exist "%WORKSPACE_ROOT%\sites" (
        for /d %%d in ("%WORKSPACE_ROOT%\sites\*") do echo   - %%~nd
    ) else (
        echo   No sites folder found at %WORKSPACE_ROOT%\sites
    )
    exit /b 1
)

if "%REMOVE%"=="true" (
    echo Removing repositories for site '%SITE_NAME%' listed in %PLUGIN_LIST_FILE%...
    set OPERATION_NAME=remove
) else (
    echo Cloning repositories for site '%SITE_NAME%' listed in %PLUGIN_LIST_FILE%...
    set OPERATION_NAME=clone
)

REM Count total repositories for progress tracking
set TOTAL_REPOS=0
for /f "usebackq eol=# delims=" %%i in ("%PLUGIN_LIST_FILE%") do (
    if not "%%i"=="" set /a TOTAL_REPOS+=1
)

set CURRENT_REPO=0
for /f "usebackq eol=# delims=" %%i in ("%PLUGIN_LIST_FILE%") do (
    if not "%%i"=="" (
        set /a CURRENT_REPO+=1
        echo [!CURRENT_REPO!/!TOTAL_REPOS!] Processing repository: %%i
        call :process_repository !OPERATION_NAME! "%%i"
    )
)

if "%REMOVE%"=="true" (
    echo All repositories for site '%SITE_NAME%' have been removed.
) else (
    echo All repositories for site '%SITE_NAME%' processed.
)
cd /d "%CURRENT_DIR%"
exit /b 0

:show_help
echo.
echo Clone Script - NopCommerce Plugin Management
echo ============================================
echo.
echo USAGE:
echo   clone [OPTIONS] ^<repo-name^>
echo   clone [OPTIONS] --site ^<site-name^>
echo   clone --remove [OPTIONS] ^<repo-name^>
echo   clone --remove --site ^<site-name^>
echo.
echo OPTIONS:
echo   -h, --help              Show this help message
echo   -v, --verbose           Enable verbose output for debugging
echo   -rm, --remove           Remove a repository instead of cloning
echo   -s, --site              Clone/remove all repositories for a specific site
echo.
echo EXAMPLES:
echo   clone SEO               Clone the SEO plugin repository
echo   clone -v PayPal         Clone PayPal plugin with verbose output
echo   clone -rm SEO           Remove the SEO plugin repository
echo   clone --site MySite     Clone all plugins for a site
echo   clone -rm -s MySite     Remove all plugins for a site
echo.
echo DESCRIPTION:
echo   This script manages NopCommerce plugin repositories by cloning them from
echo   Azure DevOps and adding them to the solution. It automatically finds the
echo   solution file and creates the appropriate directory structure.
echo.
echo   For site operations, the script reads from PluginList.txt files located at:
echo   sites/^<site-name^>/PluginList.txt
echo.
exit /b 0

REM Function to process a single repository (clone or remove)
:process_repository
setlocal enabledelayedexpansion
set OPERATION=%~1
set REPO_NAME_PARAM=%~2
set REPO_SLUG_LOCAL=Nop.Plugin.Opensoft.%REPO_NAME_PARAM%
set CLONE_DIR_LOCAL=%PLUGINS_DIR%\%REPO_SLUG_LOCAL%

if "%VERBOSE%"=="true" echo [DEBUG] Processing: %OPERATION% %REPO_NAME_PARAM%

if "%OPERATION%"=="clone" (
    echo --- Cloning %REPO_NAME_PARAM% ---

    if exist "%CLONE_DIR_LOCAL%" (
        echo Repository %REPO_SLUG_LOCAL% already exists. Skipping clone.
        goto process_end
    )

    git clone "%DEVOPS_PROJECT%/%REPO_SLUG_LOCAL%" "%CLONE_DIR_LOCAL%"
    if !errorlevel! neq 0 (
        echo Error: Failed to clone %REPO_SLUG_LOCAL%. Skipping.
        goto process_end
    )

    REM Verify the clone was successful by checking for the project file
    if not exist "%CLONE_DIR_LOCAL%\%REPO_SLUG_LOCAL%.csproj" (
        echo Error: Repository cloned but project file '%REPO_SLUG_LOCAL%.csproj' is missing
        echo Removing incomplete clone...
        rmdir /s /q "%CLONE_DIR_LOCAL%"
        goto process_end
    )

    pushd "%CLONE_DIR_LOCAL%"
    git checkout 4.80/develop
    if !errorlevel! neq 0 (
        echo Warning: Failed to switch to branch '4.80/develop' for %REPO_SLUG_LOCAL%
        echo The repository was cloned but may be on a different default branch.
    )
    popd

    REM Add to solution
    pushd "%SOLUTION_DIR%"
    if exist "Plugins\%REPO_SLUG_LOCAL%\%REPO_SLUG_LOCAL%.csproj" (
        dotnet sln "%CHOSEN_SOLUTION%" add --solution-folder Plugins "Plugins\%REPO_SLUG_LOCAL%\%REPO_SLUG_LOCAL%.csproj"
        if !errorlevel! equ 0 (
            echo Project %REPO_SLUG_LOCAL% added to solution.
        ) else (
            echo Warning: Failed to add %REPO_SLUG_LOCAL% to solution.
        )
    ) else (
        echo Warning: Project file not found for %REPO_SLUG_LOCAL%
    )
    popd
    echo --- Finished cloning %REPO_NAME_PARAM% ---

) else if "%OPERATION%"=="remove" (
    echo --- Removing %REPO_NAME_PARAM% ---

    if exist "%CLONE_DIR_LOCAL%" (
        rmdir /s /q "%CLONE_DIR_LOCAL%"
        echo Folder '%CLONE_DIR_LOCAL%' removed.
    ) else (
        echo Folder '%CLONE_DIR_LOCAL%' does not exist.
    )

    pushd "%SOLUTION_DIR%"
    dotnet sln "%CHOSEN_SOLUTION%" remove "Plugins\%REPO_SLUG_LOCAL%\%REPO_SLUG_LOCAL%.csproj" 2>nul
    echo Project %REPO_SLUG_LOCAL% removed from solution.
    popd
    echo --- Finished removing %REPO_NAME_PARAM% ---
)

:process_end
endlocal
goto :eof

REM Function to search down directories
:search_down
set SEARCH_PATH=%~1
set DEPTH=%~2
if %DEPTH% geq 3 goto :eof

if "%VERBOSE%"=="true" echo [DEBUG] Searching down in: %SEARCH_PATH% (depth %DEPTH%)

REM Check for .sln files in current directory
for %%f in ("%SEARCH_PATH%\*.sln") do (
    if exist "%%f" (
        set /a SOLUTION_COUNT+=1
        REM Normalize path to remove double slashes
        set "NORMALIZED_PATH=%%f"
        set "NORMALIZED_PATH=!NORMALIZED_PATH:\\=\!"
        set SOLUTION_!SOLUTION_COUNT!=!NORMALIZED_PATH!
        if "%VERBOSE%"=="true" echo [DEBUG] Found solution: !NORMALIZED_PATH!
    )
)

REM Search subdirectories
set /a NEXT_DEPTH=%DEPTH%+1
for /d %%d in ("%SEARCH_PATH%\*") do (
    call :search_down "%%d" %NEXT_DEPTH%
)
goto :eof

REM Function to display solution choices with highlighted differences
:display_solution_choices
set INDEX=1
:display_loop
if %INDEX% gtr %SOLUTION_COUNT% goto :eof
call set CURRENT_SOL=%%SOLUTION_%INDEX%%%
for %%f in ("%CURRENT_SOL%") do (
    echo   %INDEX%. %%~nxf
    echo      ^> %%f
)
set /a INDEX+=1
goto display_loop

REM Function to validate choice and set chosen solution
:validate_and_set_choice
REM Trim any whitespace from CHOICE
for /f "tokens=* delims= " %%a in ("%CHOICE%") do set CHOICE=%%a

REM Validate range
if %CHOICE% lss 1 (
    echo Invalid choice. Please enter a number between 1 and %SOLUTION_COUNT%.
    exit /b 1
)
if %CHOICE% gtr %SOLUTION_COUNT% (
    echo Invalid choice. Please enter a number between 1 and %SOLUTION_COUNT%.
    exit /b 1
)

REM Set chosen solution using array index
call set CHOSEN_SOLUTION=%%SOLUTION_%CHOICE%%%
goto :eof

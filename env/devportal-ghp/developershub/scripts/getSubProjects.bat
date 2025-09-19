@echo off

set NOPVERSION=4.80.6
set NOP_GITHUB_BASE_URL=https://github.com/nopSolutions/nopCommerce/releases/download/release-%NOPVERSION%/
set NOP_GITHUB_SOURCE_FILE=nopCommerce_%NOPVERSION%_Source.zip
set NOP_DOWNLOADED_BINARIES_ZIP=nopCommerce_%NOPVERSION%_binaries.zip
set NOP_GITHUB_BINARIES_PREFIX=%NOP_GITHUB_BASE_URL%nopCommerce_%NOPVERSION%_NoSource_
set NOP_GITHUB_BINARIES_SUFFIX=_x64.zip
set NOP_PLUGINS_RELATIVE_PATH=nopPlugins\bin\Debug\net9.0\
set DOWNLOAD_DIR=%~dp0..

REM Check if tar is available
where tar >nul 2>nul
if %errorlevel% neq 0 (
    echo "Error: 'tar' command not found. Please install it and ensure it's in your PATH."
    exit /b 1
)

REM Clone or update nopCommerce repository
if exist nopCommerce\.git (
    echo "'nopCommerce' directory exists. Updating repository..."
    pushd nopCommerce
    git checkout develop
    git pull origin develop
    popd
) else (
    if exist nopCommerce (
        echo "Warning: 'nopCommerce' directory exists but is not a Git repository. Removing it..."
        rmdir /s /q nopCommerce
    )
    echo "Cloning nopCommerce repository..."
    git clone git@github.com:opensoft/nopCommerce.git nopCommerce
    if %errorlevel% neq 0 (
        echo "Error: Failed to clone 'nopCommerce' repository."
        exit /b 1
    )
    pushd nopCommerce
    git checkout develop
    popd
)

REM Download and extract nopCommerce source
echo "Downloading nopCommerce source zip %NOPVERSION%..."
curl -L -o "%DOWNLOAD_DIR%\%NOP_GITHUB_SOURCE_FILE%" "%NOP_GITHUB_BASE_URL%%NOP_GITHUB_SOURCE_FILE%"
if %errorlevel% neq 0 (
    echo "Error: Failed to download nopCommerce source zip."
    exit /b 1
)
echo "Extracting nopCommerce source..."
if not exist "%DOWNLOAD_DIR%\nopSolution" mkdir "%DOWNLOAD_DIR%\nopSolution"
tar -xf "%DOWNLOAD_DIR%\%NOP_GITHUB_SOURCE_FILE%" -C "%DOWNLOAD_DIR%\nopSolution"
if %errorlevel% neq 0 (
    echo "Error: Failed to extract nopCommerce source."
    exit /b 1
)
del "%DOWNLOAD_DIR%\%NOP_GITHUB_SOURCE_FILE%"

REM Download and extract nopCommerce binaries
set OS_TYPE=win
set NOP_GITHUB_BINARIES_URL=%NOP_GITHUB_BINARIES_PREFIX%%OS_TYPE%%NOP_GITHUB_BINARIES_SUFFIX%
echo "Downloading nopCommerce binaries zip..."
curl -L -o "%DOWNLOAD_DIR%\%NOP_DOWNLOADED_BINARIES_ZIP%" "%NOP_GITHUB_BINARIES_URL%"
if %errorlevel% neq 0 (
    echo "Error: Failed to download nopCommerce binaries zip."
    exit /b 1
)
echo "Extracting nopCommerce binaries..."
if not exist "%DOWNLOAD_DIR%\nopPlugins" md "%DOWNLOAD_DIR%\nopPlugins"
if not exist "%DOWNLOAD_DIR%\nopPlugins\bin" md "%DOWNLOAD_DIR%\nopPlugins\bin"
if not exist "%DOWNLOAD_DIR%\nopPlugins\bin\Debug" md "%DOWNLOAD_DIR%\nopPlugins\bin\Debug"
if not exist "%DOWNLOAD_DIR%\nopPlugins\bin\Debug\net9.0" md "%DOWNLOAD_DIR%\nopPlugins\bin\Debug\net9.0"
pushd "%DOWNLOAD_DIR%\%NOP_PLUGINS_RELATIVE_PATH%"
set EXTRACT_DIR=%CD%
popd
tar -xf "%DOWNLOAD_DIR%\%NOP_DOWNLOADED_BINARIES_ZIP%" -C "%EXTRACT_DIR%"
if %errorlevel% neq 0 (
    echo "Error: Failed to extract nopCommerce binaries."
    exit /b 1
)
del "%DOWNLOAD_DIR%\%NOP_DOWNLOADED_BINARIES_ZIP%"

echo "Setup complete!"


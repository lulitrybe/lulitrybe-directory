#!/bin/bash



NOPVERSION="4.80.6" # Set the nopCommerce version here

SOURCE_TYPE=""
NOP_GITHUB_URL=""
NOP_GITHUB_BASE_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-${NOPVERSION}/"
NOP_GITHUB_SOURCE_FILE="nopCommerce_${NOPVERSION}_Source.zip"
NOP_DOWNLOADED_BINARIES_ZIP="nopCommerce_${NOPVERSION}_binaries.zip"
NOP_GITHUB_BINARIES_PREFIX="${NOP_GITHUB_BASE_URL}nopCommerce_${NOPVERSION}_NoSource_"
NOP_GITHUB_BINARIES_SUFFIX="_x64.zip"
NOP_PLUGINS_RELATIVE_PATH="nopPlugins/bin/Debug/net9.0/"
# Define the download directory explicitly as the nopSetup folder
# This needs to be defined *before* we potentially change directories into nopCommerce
DOWNLOAD_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Check OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running on Linux"
    OS_TYPE="linux"
    # Check and install unzip
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found. Attempting to install..."
        # Try apt first, then yum/dnf for broader Linux compatibility
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y unzip
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y unzip
        elif command -v yum &> /dev/null; then
            sudo yum install -y unzip
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm unzip
        else
            echo "Could not determine package manager. Please install 'unzip' manually."
            exit 1
        fi
        # Verify installation
        if ! command -v unzip &> /dev/null; then
            echo "Failed to install 'unzip'. Please install it manually and re-run the script."
            exit 1
        else
            echo "'unzip' installed successfully."
        fi
    else
        echo "'unzip' is already installed."
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS"
    OS_TYPE="mac"
    # Check and install unzip
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found. Attempting to install..."
        if command -v brew &> /dev/null; then
            brew install unzip
        else
            echo "Homebrew not found. Please install 'unzip' manually or install Homebrew first (https://brew.sh/)."
            exit 1
        fi
        # Verify installation
        if ! command -v unzip &> /dev/null; then
            echo "Failed to install 'unzip'. Please install it manually and re-run the script."
            exit 1
        else
            echo "'unzip' installed successfully."
        fi
    else
        echo "'unzip' is already installed."
    fi
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Running on Windows (using Cygwin/MSYS/Git Bash)"
    OS_TYPE="win"
    # Check for unzip
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found."
        echo "Running on Windows. Please ensure 'unzip' is installed and available in your PATH."
        echo "You might need to install it via Chocolatey ('choco install unzip') or download it manually."
        echo "Script will exit now. Please install unzip and re-run."
        exit 1
    else
        echo "'unzip' is already installed."
    fi
else
    echo "Running on an unknown OS ($OSTYPE)"
    # Check for unzip on unknown OS
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found on this unknown OS."
        echo "Please install 'unzip' manually and ensure it's in your PATH."
        exit 1
    else
         echo "'unzip' is already installed."
    fi
fi






#############################################################
#                                                           #
#      --- nopSolution Source Download and Setup ---        #
#                                                           #
#############################################################

echo "Setting up nopCommerce repository..."
# Define the download directory explicitly as the nopSetup folder
# This needs to be defined *before* we potentially change directories into nopCommerce
DOWNLOAD_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_FOLDER="$DOWNLOAD_DIR/temp_nop_config_backup" # Define temp folder path using the new name

if [ -d "nopCommerce/.git" ]; then
    # Directory exists and is a Git repository
    echo "'nopCommerce' directory exists. Checking out 'develop' and pulling latest changes..."
    cd nopCommerce || exit 1
    git checkout develop
    git pull origin develop # Assuming 'origin' is the remote name
    cd .. || exit 1
    echo "NopCommerce repository updated."
elif [ -d "nopCommerce" ]; then
    # Directory exists but is not a Git repository
    echo "Warning: 'nopCommerce' directory exists but is not a valid Git repository."
    echo "Backing up .devcontainer and .vscode folders (if they exist)..."
    rm -rf "$TEMP_FOLDER" # Clean up any previous temp folder
    mkdir -p "$TEMP_FOLDER"
    CLONE_FAILED=0 # Flag to track clone status

    if [ -d "nopCommerce/.devcontainer" ]; then
        echo "Copying .devcontainer to temporary location..."
        cp -R "nopCommerce/.devcontainer" "$TEMP_FOLDER/"
    fi
    if [ -d "nopCommerce/.vscode" ]; then
        echo "Copying .vscode to temporary location..."
        cp -R "nopCommerce/.vscode" "$TEMP_FOLDER/"
    fi

    echo "Removing existing 'nopCommerce' directory..."
    rm -rf nopCommerce

    echo "Cloning nopCommerce repository..."
    git clone git@github.com:opensoft/nopCommerce.git nopCommerce
    if [ $? -ne 0 ]; then
        echo "Error: Cloning 'nopCommerce' repository failed."
        CLONE_FAILED=1 # Set the flag
        # Do not exit yet, proceed to restore
    fi

    echo "Restoring .devcontainer and .vscode folders..."
    # Ensure the target directory exists before attempting to copy back, even if clone failed partially
    mkdir -p nopCommerce
    if [ -d "$TEMP_FOLDER/.devcontainer" ]; then
        echo "Restoring .devcontainer..."
        cp -R "$TEMP_FOLDER/.devcontainer" "nopCommerce/"
    fi
    if [ -d "$TEMP_FOLDER/.vscode" ]; then
        echo "Restoring .vscode..."
        cp -R "$TEMP_FOLDER/.vscode" "nopCommerce/"
    fi

    echo "Cleaning up temporary backup directory..."
    rm -rf "$TEMP_FOLDER"
    echo "Configuration folders restored."

    # Now check the flag and exit if the clone failed
    if [ $CLONE_FAILED -eq 1 ]; then
        echo "Exiting due to git clone failure."
        exit 1
    fi

    # If clone succeeded, checkout develop
    cd nopCommerce || exit 1
    git checkout develop
    cd .. || exit 1
    echo "NopCommerce repository cloned and set to develop branch."

else
    # Directory does not exist
    echo "Cloning nopCommerce repository..."
    git clone git@github.com:opensoft/nopCommerce.git nopCommerce
    if [ $? -ne 0 ]; then
        echo "Error: Cloning 'nopCommerce' repository failed."
        exit 1
    fi
    cd nopCommerce || exit 1
    git checkout develop
    cd .. || exit 1
    echo "NopCommerce repository cloned successfully."
fi






#############################################################
#                                                           #
#      --- nopSolution Source Download and Setup ---        #
#                                                           #
#############################################################


# DOWNLOAD_DIR is already defined above, ensure we are in the correct directory before proceeding
cd "$DOWNLOAD_DIR" || exit 1
echo "This is the full source of the nopSolution framework (specific version)"
echo "This is NOT a repo. Use this for reference or plugin development alongside the repos."
echo "Downloading nopCommerce source zip $NOPVERSION..."
curl -L -o "$DOWNLOAD_DIR/$NOP_GITHUB_SOURCE_FILE" "${NOP_GITHUB_BASE_URL}${NOP_GITHUB_SOURCE_FILE}"
echo "nopCommerce source zip downloaded."

# Create the nopSolution directory inside nopSetup and unzip the source code into it
echo "Creating nopSetup/nopSolution directory and unzipping source..."
mkdir -p "$DOWNLOAD_DIR/nopSolution"
unzip -q "$DOWNLOAD_DIR/$NOP_GITHUB_SOURCE_FILE" -d "$DOWNLOAD_DIR/nopSolution"
echo "nopCommerce source unzipped into nopSetup/nopSolution directory."

# Remove files at the root of nopSolution, keep subdirectories
echo "Cleaning up root files in nopSetup/nopSolution..."
find "$DOWNLOAD_DIR/nopSolution/" -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSetup/nopSolution, if any."

# # Remove files at the root of nopSolution/src, keep subdirectories
# echo "Cleaning up root files in nopSetup/nopSolution/src..."
# find "$DOWNLOAD_DIR/nopSolution/src/" -maxdepth 1 -type f -delete
# echo "Removed files at the root of nopSetup/nopSolution/src, if any."

# Clean up the downloaded zip file
echo "Removing downloaded zip file..."
rm "$DOWNLOAD_DIR/$NOP_GITHUB_SOURCE_FILE"
echo "Zip file removed."
echo "nopSolution source setup complete."
echo "-----------------------------------------------------" # Added separator





#############################################################
#                                                           #
#      --- nopPlugins Binaries Download and Setup ---       #
#                                                           #
#############################################################


# These are the official DLLs of this version of the nopCommerce framework
# This is NOT a repo. Use this for reference alongside the repos.
# !!! UPDATE THE URL AND VERSION (X.Y.Z) at the top of file !!!
echo "Preparig nopPlugins setup"
NOP_GITHUB_BINARIES_URL="${NOP_GITHUB_BINARIES_PREFIX}${OS_TYPE}${NOP_GITHUB_BINARIES_SUFFIX}"
echo "Downloading $NOP_DOWNLOADED_BINARIES_ZIP from: ${NOP_GITHUB_BINARIES_URL} to: $DOWNLOAD_DIR"
curl -L -o "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP" "${NOP_GITHUB_BINARIES_URL}"
if [ $? -ne 0 ]; then
    echo "Error downloading nopCommerce binaries zip. Please check the URL and version."
    exit 1
else
    echo "nopCommerce binaries zip downloaded successfully."
fi

# Verify the integrity of the downloaded zip file
echo "Verifying the integrity of the downloaded zip file..."
unzip -t "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: The downloaded zip file is invalid or corrupted. Please check the URL or re-download."
    rm -f $NOP_DOWNLOADED_BINARIES_ZIP
    exit 1
else
    echo "Zip file integrity verified successfully."
fi
# Create the nopPlugins directory and unzip the source code into it
echo "Creating nopPlugins directory and unzipping source..."
mkdir -p "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH"

echo "Unzipping $NOP_DOWNLOADED_BINARIES_ZIP "
echo "into nopPlugins directory at $DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH"
# Unzip the downloaded binaries into the nopPlugins directory
unzip -q "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP" -d "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH"
if [ $? -eq 0 ]; then
    echo "nopPlugins binaries unzipped into nopPlugins directory."
else
    echo "Error: Failed to unzip nopPlugins binaries."
    exit 1
fi
# # Remove files at the root of nopPlugins, keep subdirectories, and exclude .sln files
# echo "Cleaning up root files in nopPlugins, excluding .sln files..."
# find "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH" -maxdepth 1 -type f ! -name "*.sln" -delete
# echo "Removed files at the root of nopPlugins, excluding .sln files."

# # Remove files at the root of nopPlugins/src, keep subdirectories, and exclude .sln files (if applicable)
# if [ -d "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH/src" ]; then
#     echo "Cleaning up root files in nopPlugins/src, excluding .sln files..."
#     find "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH/src" -maxdepth 1 -type f ! -name "*.sln" -delete
#     echo "Removed files at the root of nopPlugins/src, excluding .sln files."
# fi

# Clean up the downloaded zip file
echo "Removing downloaded Binaries zip file..."
rm "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP"
echo "Binaries zip file removed."
echo "-----------------------------------------------------" # Added separator


# --- Final Messages ---
echo ""
echo "-----------------------------------------------------"
echo "nopCommerce development environment setup complete!"
echo " - nopCommerce repository cloned into 'nopCommerce/'"
echo " - nopCommerce v4.80.6 source extracted into 'nopSolution/' (cleaned)"
echo " - nopCommerce v4.80.6 binaries extracted into 'nopPlugins/bin/Debug/net9.0/' (cleaned)"

echo "-----------------------------------------------------"


echo "-----------------------------------------------------"
echo "Setup finished."
echo "-----------------------------------------------------"


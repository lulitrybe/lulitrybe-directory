#!/bin/bash

# Get the directory where this script (and the 'clone' script) is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLONE_SCRIPT_PATH="$SCRIPT_DIR/clone"
INSTALL_TARGET="/usr/local/bin/clone"
SYSTEM_INSTALL_DONE=false

# --- Debugging ---
echo "Executing addClone2Shell.sh"
echo "SCRIPT_DIR is: $SCRIPT_DIR"
echo "Expecting clone script at: $CLONE_SCRIPT_PATH" # <--- This exit 1 will stop the container/build
echo "Checking if file exists..."
ls -l "$SCRIPT_DIR" # List contents of the script directory for verification
# --- End Debugging ---

# Verify source script exists
if [ ! -f "$CLONE_SCRIPT_PATH" ]; then
    echo "Error: clone script not found at $CLONE_SCRIPT_PATH"
    exit 1
fi

# --- Attempt System-Wide Install ---
echo "Attempting system-wide installation to $INSTALL_TARGET..."
if [ -d "/usr/local/bin" ]; then
    # Attempt direct copy (will require root privileges or write permissions)
    if [ -w "/usr/local/bin" ]; then
         echo "Attempting direct copy to /usr/local/bin..."
         cp "$CLONE_SCRIPT_PATH" "$INSTALL_TARGET" && chmod 755 "$INSTALL_TARGET"
         CP_EXIT_CODE=$?
    else
        echo "Cannot write to /usr/local/bin. Skipping direct copy."
        CP_EXIT_CODE=1
    fi

    if [ $CP_EXIT_CODE -eq 0 ]; then
        echo "Successfully copied clone script to $INSTALL_TARGET"
        # Verify installation in PATH
        if command -v clone >/dev/null 2>&1 && [[ "$(command -v clone)" == "$INSTALL_TARGET" ]]; then
            echo "Success: 'clone' command is available system-wide."
            SYSTEM_INSTALL_DONE=true
        else
            echo "Warning: Copied script, but 'clone' command not found or points elsewhere in PATH."
            echo "You might need to adjust your PATH or restart your shell."
            # Even if verification fails, we consider the copy successful for now.
            SYSTEM_INSTALL_DONE=true
        fi
    else
        echo "Failed to copy script to $INSTALL_TARGET. Insufficient permissions or error during copy."
    fi
else
    echo "Directory /usr/local/bin does not exist. Skipping system-wide installation."
fi

# --- Fallback to User PATH Modification ---
if [ "$SYSTEM_INSTALL_DONE" = false ]; then
    echo "System-wide installation failed or skipped. Setting up user-specific PATH..."

    # Ensure the script itself is executable
    chmod +x "$CLONE_SCRIPT_PATH"

    # Add script's directory to PATH in shell profile if not already present
    SHELL_PROFILE=""
    EXPORT_LINE="export PATH=\"\$PATH:$SCRIPT_DIR\""
    COMMENT_LINE="# Add clone script directory to PATH"

    if [[ -f "$HOME/.bashrc" ]]; then
        SHELL_PROFILE="$HOME/.bashrc"
    elif [[ -f "$HOME/.zshrc" ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ -f "$HOME/.profile" ]]; then
        # Fallback for other shells or login shells
        SHELL_PROFILE="$HOME/.profile"
    fi

    if [[ -z "$SHELL_PROFILE" ]]; then
        # If no profile file was found after checking
        echo "Warning: Could not find .bashrc, .zshrc, or .profile."
        echo "Cannot automatically add $SCRIPT_DIR to PATH."
        echo "You may need to add it manually or ensure one of these files exists."
        # *** Ensure we don't proceed if SHELL_PROFILE is empty ***
    else
        # Proceed with checking and modifying the found SHELL_PROFILE
        echo "Using profile: $SHELL_PROFILE" # Added for clarity
        # Check if the exact line or the directory is already in PATH definition
        if ! grep -qF -- "$EXPORT_LINE" "$SHELL_PROFILE" && ! grep -q "PATH=.*$SCRIPT_DIR" "$SHELL_PROFILE"; then
            echo "Adding $SCRIPT_DIR to PATH in $SHELL_PROFILE"
            # Add a comment and the export line
            echo "" >> "$SHELL_PROFILE" # Add a newline for separation
            echo "$COMMENT_LINE" >> "$SHELL_PROFILE"
            echo "$EXPORT_LINE" >> "$SHELL_PROFILE"
            echo "Please run 'source $SHELL_PROFILE' or restart your shell for changes to take effect."
        else
            echo "$SCRIPT_DIR seems to be already configured in PATH in $SHELL_PROFILE."
        fi

        # Verify if the directory is now in the *current* session's PATH (might not be if profile wasn't sourced)
        if [[ ":$PATH:" == *":$SCRIPT_DIR:"* ]]; then
             echo "Success: $SCRIPT_DIR is in the current PATH."
             # Further check if 'clone' command resolves correctly
             if command -v clone >/dev/null 2>&1 && [[ "$(command -v clone)" == "$CLONE_SCRIPT_PATH" ]]; then
                  echo "'clone' command is available from $SCRIPT_DIR."
             else
                  echo "Warning: $SCRIPT_DIR is in PATH, but 'clone' command doesn't resolve correctly. Try sourcing your profile or restarting."
             fi
        else
             echo "Warning: $SCRIPT_DIR added to $SHELL_PROFILE, but not found in the current session's PATH."
             echo "Please run 'source $SHELL_PROFILE' or restart your shell."
        fi
    fi
fi

exit 0 # Indicate overall success or completion of attempt

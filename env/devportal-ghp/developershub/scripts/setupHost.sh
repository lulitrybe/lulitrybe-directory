#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"




# --- Run additional setup scripts ---

# Run getSubProjects script
GET_SUB_PROJECTS_SCRIPT="$SCRIPT_DIR/getSubProjects.sh" # Assuming location relative to setup.sh
if [ -f "$GET_SUB_PROJECTS_SCRIPT" ]; then
    echo "Running setup script: $GET_SUB_PROJECTS_SCRIPT"
    bash "$GET_SUB_PROJECTS_SCRIPT"
    if [ $? -ne 0 ]; then
        echo "Warning: $GET_SUB_PROJECTS_SCRIPT finished with errors."
    else
        echo "$GET_SUB_PROJECTS_SCRIPT completed successfully."
    fi
else
    echo "Warning: Setup script not found: $GET_SUB_PROJECTS_SCRIPT"
fi

# Run addClone2Shell script
ADD_CLONE_SCRIPT="$SCRIPT_DIR/addClone2Shell.sh" # Corrected path and added missing quote
if [ -f "$ADD_CLONE_SCRIPT" ]; then
    echo "Running additional setup script: $ADD_CLONE_SCRIPT"
    bash "$ADD_CLONE_SCRIPT"
    if [ $? -ne 0 ]; then
        echo "Warning: $ADD_CLONE_SCRIPT finished with errors."
    else
        echo "$ADD_CLONE_SCRIPT completed successfully."
    fi
else
    echo "Warning: Additional setup script not found: $ADD_CLONE_SCRIPT"
fi
echo " - The 'clone' command symlink created in ~/.local/bin/" # Updated this line for clarity
echo "-----------------------------------------------------"
echo "Setup finished."
echo "-----------------------------------------------------"


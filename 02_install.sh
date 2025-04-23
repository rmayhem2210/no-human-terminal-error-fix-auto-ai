#!/bin/bash
# Script to set up dependencies for the CodeForge Pipeline.
# Creates a virtual environment if it doesn't exist, upgrades pip, and installs requirements.

# Ensure logs directory exists
mkdir -p logs

LOG_FILE="logs/pipeline.log"

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [INSTALL] $1" >> "$LOG_FILE"
    echo "[$timestamp] [INSTALL] $1"
}

log_message "Starting dependency installation process..."

# Define VENV_DIR for clarity and consistency
VENV_DIR="venv"

# Check if virtual environment exists and is valid
if [ -d "$VENV_DIR" ]; then
    log_message "Virtual environment already exists. Checking if it's valid..."
    if [ -f "$VENV_DIR/bin/activate" ]; then
        # Temporarily source to check validity or if needed for immediate operations
        # In this script's context, it's more about checking presence/validity
        # Actual activation for pip install etc. happens later or is managed by the script calling this one
        if ! source "$VENV_DIR/bin/activate" > /dev/null 2>&1; then
             log_message "WARNING: Could not activate existing virtual environment, it may be corrupted. Recreating..."
             # Fall through to recreate logic below
        else
             log_message "Existing virtual environment found and appears valid."
             deactivate # Deactivate after check
             # The logic below will now handle recreation unconditionally, bypassing the prompt
        fi
    else
        log_message "ERROR: Invalid virtual environment (activate script not found). Recreating..."
        # Fall through to recreate logic below
    fi

    # --- MODIFIED SECTION TO BYPASS INTERACTIVE PROMPT ---
    # The original code here checked if the user wanted to recreate.
    # We are commenting out the prompt and input read to force recreation always if venv exists.

    # echo -n "Do you want to recreate the virtual environment? (y/n): " # COMMENTED OUT: Skip the interactive prompt
    # read -r recreate_venv_response                                  # COMMENTED OUT: Skip reading user input

    # if [[ "$recreate_venv_response" =~ ^[Yy]$ ]]; then              # COMMENTED OUT: Skip checking the response
        log_message "Removing existing virtual environment."        # KEEP THIS LINE: Log that we are removing
        rm -rf "$VENV_DIR"                                          # KEEP THIS LINE: Remove the old venv
        log_message "Virtual environment recreated at $VENV_DIR."   # KEEP THIS LINE: Log that we are recreating
        python3 -m venv "$VENV_DIR" || {                            # KEEP THIS LINE: Create the new venv
            log_message "ERROR: Failed to create virtual environment."
            exit 1
        }
        # We will activate below unconditionally for pip operations
    # else                                                          # COMMENTED OUT: Skip the 'else' branch
    #     log_message "Skipping virtual environment recreation."       # COMMENTED OUT: Skip the 'skip' message
    # fi                                                            # COMMENTED OUT: Close the 'if' block
    # --- END OF MODIFIED SECTION ---

else
    # Original logic if venv does NOT exist (this part is fine and runs automatically)
    log_message "Virtual environment not found. Creating new virtual environment at $VENV_DIR."
    python3 -m venv "$VENV_DIR" || {
        log_message "ERROR: Failed to create virtual environment."
        exit 1
    }
fi

# --- Activation for subsequent commands (pip install etc.) ---
# This should run whether the venv was just created or already existed/recreated
log_message "Activating virtual environment."
source "$VENV_DIR/bin/activate" || {
    log_message "ERROR: Failed to activate virtual environment after creation/check."
    exit 1
}
log_message "Virtual environment activated."


# Upgrade pip
log_message "Upgrading pip in virtual environment."
pip install --upgrade pip >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log_message "ERROR: Failed to upgrade pip."
    # No deactivate here, as we are exiting
    exit 1
fi
log_message "Pip upgraded successfully."


# Install dependencies
log_message "Installing dependencies from requirements.txt."
# Use the full path to requirements.txt just in case
pip install -r requirements.txt >> "$LOG_FILE" 2>&1
if [ $? -ne 0 ]; then
    log_message "ERROR: Failed to install dependencies. Check logs for details."
    # No deactivate here, as we are exiting
    exit 1
fi
log_message "Dependencies installed successfully."

# Deactivate virtual environment before exiting this script
deactivate
log_message "Virtual environment deactivated." # Log the deactivation

log_message "Dependency installation process completed successfully."

exit 0

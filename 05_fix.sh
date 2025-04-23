#!/bin/bash
# Script: 05_fix.sh
# Description: Shell script for applying fixes based on diagnosis using the PatchApplier class.
# Activates virtual environment, runs fixing process, and logs outcomes.

# Exit on any error
set -e

# Define logging function
log_message() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
  local level="$1"
  local message="$2"
  echo "[$timestamp] [$level] $message" >> "logs/pipeline.log"
  if [ "$level" == "ERROR" ]; then
    echo "[$timestamp] [$level] $message" >&2
  else
    echo "[$timestamp] [$level] $message"
  fi
}

# Ensure logs directory exists
mkdir -p logs

log_message "INFO" "Starting self-healing step (05_fix.sh)"

# Check if venv exists
if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
  log_message "ERROR" "Virtual environment not found. Please run 02_install.sh first."
  exit 1
fi

# Activate virtual environment
source venv/bin/activate || {
  log_message "ERROR" "Failed to activate virtual environment."
  exit 1
}

log_message "INFO" "Virtual environment activated."

# Set default diagnosis report path
DIAGNOSIS_REPORT="output/diagnosis.json"

# Parse command-line arguments (using original logic from file)
while [[ $# -gt 0 ]]; do
  case $1 in
    # <<< --- MODIFICATION HERE: Changed argument name --- >>>
    --diagnosis-file) # Changed from --diagnosis-report
      DIAGNOSIS_REPORT="$2"
      shift 2
      ;;
    *)
      log_message "WARNING" "Unknown argument: $1"
      shift
      ;;
  esac
done

log_message "INFO" "Applying fixes based on diagnosis report: $DIAGNOSIS_REPORT"

# Execute Python patch applier using the corrected argument name
# <<< --- MODIFICATION HERE: Changed argument name --- >>>
python -m modules.healers.patch_applier --diagnosis-file "$DIAGNOSIS_REPORT" || {
  log_message "ERROR" "Self-healing process failed."
  deactivate
  exit 1
}

log_message "INFO" "Self-healing process completed successfully."

# Deactivate virtual environment
deactivate
log_message "INFO" "Virtual environment deactivated."

log_message "INFO" "Self-healing step (05_fix.sh) finished."
exit 0
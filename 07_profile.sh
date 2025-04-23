#!/bin/bash
# Script: 07_profile.sh
# Description: Shell script for profiling a target command using the Profiler class.
# Activates virtual environment, runs profiling, and logs outcomes.

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

log_message "INFO" "Starting profiling step (07_profile.sh)"

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

# Default target command to profile
TARGET_COMMAND="./scripts/03_run.sh"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --target)
      TARGET_COMMAND="$2"
      shift 2
      ;;
    *)
      log_message "WARNING" "Unknown argument: $1"
      shift
      ;;
  esac
done

log_message "INFO" "Profiling target command: $TARGET_COMMAND"

# Execute Python profiling
# <<< --- MODIFICATION START --- >>>
# Uncommented the call to the metrics profiler module
python -m modules.metrics.profiler --target "$TARGET_COMMAND"
PROFILER_EXIT_CODE=$? # Capture exit code
# <<< --- MODIFICATION END --- >>>

# Check exit code from the profiler script
if [ $PROFILER_EXIT_CODE -ne 0 ]; then
  log_message "ERROR" "Profiling failed with exit code $PROFILER_EXIT_CODE."
  deactivate
  exit 1 # Exit with error if profiler fails
else
  log_message "INFO" "Profiling completed successfully."
fi

# Deactivate virtual environment
deactivate
log_message "INFO" "Virtual environment deactivated."

log_message "INFO" "Profiling step (07_profile.sh) finished."
exit 0 # Exit successfully
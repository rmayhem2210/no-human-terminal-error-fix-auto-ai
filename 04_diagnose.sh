#!/bin/bash
# Script: 04_diagnose.sh
# Description: Shell script for running log diagnosis using the LogParser class.
# Activates virtual environment, runs diagnosis, and logs outcomes.

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

# Ensure logs and output directories exist
mkdir -p logs output

log_message "INFO" "Starting diagnosis step (04_diagnose.sh)"

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

# Set default log file path
LOG_FILE="logs/pipeline.log"
OUTPUT_FILE="output/diagnosis.json"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --output-file)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      log_message "WARNING" "Unknown argument: $1"
      shift
      ;;
  esac
done

log_message "INFO" "Diagnosing log file: $LOG_FILE, output to: $OUTPUT_FILE"

# Execute Python log parsing
python -m modules.diagnostics.log_parser --log-file "$LOG_FILE" --output-file "$OUTPUT_FILE" || {
  log_message "ERROR" "Log diagnosis failed."
  deactivate
  exit 1
}

log_message "INFO" "Log diagnosis completed successfully."

# Deactivate virtual environment
deactivate
log_message "INFO" "Virtual environment deactivated."

log_message "INFO" "Diagnosis step (04_diagnose.sh) finished."
exit 0

#!/bin/bash
# Script: 04_diagnose.sh
# Purpose: Execute log parsing and diagnostics for the CodeForge Pipeline.
# This script activates the virtual environment and runs the log parser to
# generate a structured diagnosis report.

# Exit on any error
set -e

# Define log file path
LOG_FILE="logs/pipeline.log"

# Function to log messages with timestamp
log_message() {
    local level="$1"
    local msg="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S.%N') [$level] $msg" >> "$LOG_FILE"
    echo "[$level] $msg"
}

# Ensure logs and output directories exist
mkdir -p logs output

log_message "INFO" "Starting diagnosis step (04_diagnose.sh)"

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    log_message "ERROR" "Virtual environment not found. Run 02_install.sh first."
    exit 1
fi

# Activate virtual environment
source venv/bin/activate || {
    log_message "ERROR" "Failed to activate virtual environment."
    exit 1
}

# Run log parser to generate diagnosis report
LOG_PATH="logs/pipeline.log"
OUTPUT_PATH="output/diagnosis.json"
log_message "INFO" "Running log parser on $LOG_PATH, output to $OUTPUT_PATH..."
python -m modules.diagnostics.log_parser --log-file "$LOG_PATH" --output-file "$OUTPUT_PATH" || {
    log_message "ERROR" "Log parsing failed."
    deactivate
    exit 1
}

log_message "INFO" "Diagnosis report generated at $OUTPUT_PATH."

# Deactivate virtual environment
deactivate

log_message "INFO" "Diagnosis step (04_diagnose.sh) finished."
exit 0
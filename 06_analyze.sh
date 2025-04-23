#!/bin/bash
# Script: 06_analyze.sh
# Description: Shell script for running static analysis using pylint and bandit.
# Activates virtual environment, runs analysis tools, and logs outcomes.

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

log_message "INFO" "Starting static analysis step (06_analyze.sh)"

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

# Run pylint analysis
log_message "INFO" "Running pylint analysis on modules, scripts, and tests."
pylint modules/ scripts/ tests/ --output-format=json > output/pylint_report.json 2> logs/pylint_error.log || {
  log_message "WARNING" "Pylint analysis encountered issues. Check logs/pylint_error.log for details."
  PYLINT_EXIT_CODE=$?
}

# Run bandit analysis
log_message "INFO" "Running bandit security analysis on modules and scripts."
bandit -r modules/ scripts/ -f json -o output/bandit_report.json 2> logs/bandit_error.log || {
  log_message "WARNING" "Bandit analysis encountered issues. Check logs/bandit_error.log for details."
  BANDIT_EXIT_CODE=$?
}

# Summarize results
if [ -f "output/pylint_report.json" ]; then
  PYLINT_ISSUES=$(jq '. | length' output/pylint_report.json)
  log_message "INFO" "Pylint analysis completed. Found $PYLINT_ISSUES issues."
else
  log_message "ERROR" "Pylint report not generated."
fi

if [ -f "output/bandit_report.json" ]; then
  BANDIT_ISSUES=$(jq '.results | length' output/bandit_report.json)
  log_message "INFO" "Bandit analysis completed. Found $BANDIT_ISSUES security issues."
else
  log_message "ERROR" "Bandit report not generated."
fi

# Deactivate virtual environment
deactivate
log_message "INFO" "Virtual environment deactivated."

log_message "INFO" "Static analysis step (06_analyze.sh) finished."
exit 0

#!/bin/bash
# Script: 06_analyze.sh
# Purpose: Perform static analysis on the CodeForge Pipeline codebase using pylint and bandit.
# This script activates the virtual environment, runs analysis tools, and generates JSON reports.

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

log_message "INFO" "Starting static analysis step (06_analyze.sh)"

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

# Run pylint analysis
PYLINT_REPORT="output/pylint_report.json"
log_message "INFO" "Running pylint analysis, output to $PYLINT_REPORT..."
pylint modules/ scripts/ tests/ --output-format=json > "$PYLINT_REPORT" 2>> "$LOG_FILE" || {
    log_message "WARNING" "pylint analysis completed with issues. Check $PYLINT_REPORT for details."
}

# Run bandit analysis
BANDIT_REPORT="output/bandit_report.json"
log_message "INFO" "Running bandit analysis, output to $BANDIT_REPORT..."
bandit -r modules/ scripts/ tests/ -f json -o "$BANDIT_REPORT" 2>> "$LOG_FILE" || {
    log_message "WARNING" "bandit analysis completed with issues. Check $BANDIT_REPORT for details."
}

# Summarize results (basic parsing of JSON for summary)
if [ -f "$PYLINT_REPORT" ]; then
    PYLINT_ISSUES=$(jq length "$PYLINT_REPORT" 2>/dev/null || echo "unknown")
    log_message "INFO" "pylint found $PYLINT_ISSUES issues."
fi

if [ -f "$BANDIT_REPORT" ]; then
    BANDIT_ISSUES=$(jq '.results | length' "$BANDIT_REPORT" 2>/dev/null || echo "unknown")
    log_message "INFO" "bandit found $BANDIT_ISSUES security issues."
fi

# Deactivate virtual environment
deactivate

log_message "INFO" "Static analysis step (06_analyze.sh) finished."
exit 0
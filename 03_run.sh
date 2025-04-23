#!/bin/bash
# Script: 03_run.sh
# Description: Shell script for running tests using pytest with coverage and detailed reporting.
# Activates virtual environment, runs tests, and logs outcomes.

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

log_message "INFO" "Starting execution and testing step (03_run.sh)"

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

# <<< --- MODIFICATION START --- >>>
# Explicitly add the project root to PYTHONPATH for pytest
export PYTHONPATH="${PYTHONPATH}:/home/egladdenx/codeforge-pipeline"
# <<< --- MODIFICATION END --- >>>

# Run pytest with coverage and reporting
log_message "INFO" "Running pytest with coverage analysis."
mkdir -p logs output
# Using the pytest command structure from the first version in your provided file
pytest tests/ -v --cov=./modules --cov=./scripts --cov-report html:output/coverage_html --cov-report xml:output/coverage.xml --junitxml=logs/test_report.xml 2>&1 | tee logs/pytest_output.log
PYTEST_EXIT_CODE=${PIPESTATUS[0]}

# Analyze pytest exit code
case $PYTEST_EXIT_CODE in
  0)
    log_message "INFO" "All tests passed successfully."
    ;;
  1)
    log_message "ERROR" "Some tests failed."
    ;;
  2)
    log_message "ERROR" "Test collection error or interrupted by user."
    ;;
  3)
    log_message "ERROR" "Internal pytest error."
    ;;
  4)
    log_message "ERROR" "Pytest usage error."
    ;;
  5)
    log_message "INFO" "No tests were collected."
    ;;
  *)
    log_message "ERROR" "Unknown pytest exit code: $PYTEST_EXIT_CODE"
    ;;
esac

# Deactivate virtual environment
deactivate
log_message "INFO" "Virtual environment deactivated."

log_message "INFO" "Execution and testing step (03_run.sh) finished with exit code $PYTEST_EXIT_CODE."
exit $PYTEST_EXIT_CODE

# Note: There was duplicate content at the end of your provided 03_run.sh.
# This version uses the structure from the first part and incorporates the fix.
# Ensure this matches the primary logic you intended.
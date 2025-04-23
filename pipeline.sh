#!/bin/bash
# Script: pipeline.sh
# Description: Main orchestration script for CodeForge Pipeline.
# Reads configuration, executes steps with retries and timeouts, logs metrics and outcomes.

# Exit on any error
set -e

# Define logging function
log_message() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S.%3N')
  local level="$1"
  local message="$2"
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
  if [ "$level" == "ERROR" ]; then
    echo "[$timestamp] [$level] $message" >&2
  else
    echo "[$timestamp] [$level] $message"
  fi
}

# Ensure logs and output directories exist
CONFIG_FILE="config/pipeline_config.json"
LOG_FILE="logs/pipeline.log"
METRICS_DB="logs/metrics.db"
OUTPUT_DIR="output"

mkdir -p logs "$OUTPUT_DIR"

log_message "INFO" "Starting CodeForge Pipeline orchestration."

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
  log_message "ERROR" "Configuration file $CONFIG_FILE not found."
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  log_message "ERROR" "jq is not installed. Please install jq to parse JSON configuration."
  exit 1
fi

# Read global settings from config
GLOBAL_TIMEOUT=$(jq -r '.global_timeout' "$CONFIG_FILE")
VERBOSE=$(jq -r '.verbose' "$CONFIG_FILE")
CLEAN_OUTPUT=$(jq -r '.clean_output_before_run' "$CONFIG_FILE")

if [ "$CLEAN_OUTPUT" = "true" ]; then
  log_message "INFO" "Cleaning output directory before run."
  rm -rf "$OUTPUT_DIR"/*
fi

log_message "INFO" "Pipeline configuration loaded. Global timeout: $GLOBAL_TIMEOUT seconds, Verbose: $VERBOSE"

# Function to log metrics using Python utility
log_metrics() {
  local step_name="$1"
  local status="$2"
  local runtime_ms="$3"
  local mem_usage_mb="$4"
  local outcome="$5"
  local log_path="$6"
  local diagnosis_path="$7"
  local report_paths="$8"
  if [ -d "venv" ] && [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    # <<< --- MODIFICATION START --- >>>
    # Commented out the call to the missing metrics module
    # python -m modules.metrics.utils log_outcome \
    #   --step "$step_name" \
    #   --status "$status" \
    #   --runtime-ms "$runtime_ms" \
    #   --mem-usage-mb "$mem_usage_mb" \
    #   --outcome "$outcome" \
    #   --log-path "$log_path" \
    #   --diagnosis-path "$diagnosis_path" \
    #   --report-paths "$report_paths" \
    #   --db "$METRICS_DB"
    log_message "INFO" "Metrics logging call via modules.metrics.utils is currently commented out in pipeline.sh"
    # <<< --- MODIFICATION END --- >>>
    deactivate
  else
    log_message "WARNING" "Virtual environment not found. Skipping metrics logging for $step_name."
  fi
}

# Trap signals for graceful interruption
trap 'log_message "ERROR" "Pipeline interrupted by user."; exit 1' SIGINT SIGTERM

# Iterate over steps defined in configuration
STEPS_COUNT=$(jq -r '.steps | length' "$CONFIG_FILE")
log_message "INFO" "Executing $STEPS_COUNT pipeline steps."

for ((i=0; i<STEPS_COUNT; i++)); do
  STEP_NAME=$(jq -r ".steps[$i].name" "$CONFIG_FILE")
  STEP_SCRIPT=$(jq -r ".steps[$i].script" "$CONFIG_FILE")
  STEP_TIMEOUT=$(jq -r ".steps[$i].timeout" "$CONFIG_FILE")
  STEP_RETRIES=$(jq -r ".steps[$i].retries" "$CONFIG_FILE")
  STEP_CRITICAL=$(jq -r ".steps[$i].critical" "$CONFIG_FILE")

  log_message "INFO" "Starting step: $STEP_NAME (Script: $STEP_SCRIPT, Timeout: $STEP_TIMEOUT s, Retries: $STEP_RETRIES, Critical: $STEP_CRITICAL)"

  ATTEMPT=0
  SUCCESS=false
  while [ $ATTEMPT -le $STEP_RETRIES ]; do
    START_TIME=$(date +%s%N)
    log_message "INFO" "Executing $STEP_NAME (Attempt $((ATTEMPT+1)) of $((STEP_RETRIES+1)))"

    # Execute step with timeout if available
    if command -v timeout &> /dev/null; then
      timeout "$STEP_TIMEOUT" "$STEP_SCRIPT" && EXIT_CODE=0 || EXIT_CODE=$?
    else
      "$STEP_SCRIPT" && EXIT_CODE=0 || EXIT_CODE=$?
    fi

    END_TIME=$(date +%s%N)
    RUNTIME_MS=$(( (END_TIME - START_TIME) / 1000000 ))

    # Placeholder for memory usage (would be integrated with profiling)
    MEM_USAGE_MB=0.0

    if [ $EXIT_CODE -eq 0 ]; then
      log_message "INFO" "Step $STEP_NAME completed successfully in $RUNTIME_MS ms."
      STATUS="SUCCESS"
      OUTCOME="Completed"
      SUCCESS=true
      # Log metrics even on success (call is commented out inside function)
      log_metrics "$STEP_NAME" "$STATUS" "$RUNTIME_MS" "$MEM_USAGE_MB" "$OUTCOME" "$LOG_FILE" "output/diagnosis.json" "output/*.json"
      break # Exit loop on success
    else
      log_message "ERROR" "Step $STEP_NAME failed with exit code $EXIT_CODE in $RUNTIME_MS ms (Attempt $((ATTEMPT+1)))."
      STATUS="FAILED"
      if [ $ATTEMPT -lt $STEP_RETRIES ]; then
        OUTCOME="Failed (Retry)"
        log_message "INFO" "Retrying step $STEP_NAME."
      else
        OUTCOME="Failed (Stop)"
        log_message "ERROR" "Step $STEP_NAME failed after $((STEP_RETRIES+1)) attempts."
      fi
    fi

    # Log metrics for this attempt (call is commented out inside function)
    log_metrics "$STEP_NAME" "$STATUS" "$RUNTIME_MS" "$MEM_USAGE_MB" "$OUTCOME" "$LOG_FILE" "output/diagnosis.json" "output/*.json"

    ATTEMPT=$((ATTEMPT+1))
  done

  if [ "$SUCCESS" != "true" ] && [ "$STEP_CRITICAL" = "true" ]; then
    log_message "ERROR" "Critical step $STEP_NAME failed after all retries. Aborting pipeline."
    # Log final critical failure metric (call is commented out inside function)
    # Note: Runtime here reflects the last failed attempt. Consider calculating total time if needed.
    log_metrics "$STEP_NAME" "FAILED" "$RUNTIME_MS" "$MEM_USAGE_MB" "Failed (Critical Abort)" "$LOG_FILE" "output/diagnosis.json" "output/*.json"
    exit 1
  fi
done

log_message "INFO" "CodeForge Pipeline completed successfully."
exit 0
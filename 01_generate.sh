#!/bin/bash
# Script: 01_generate.sh
# Description: Shell script for initiating code generation using LLM via the CodeGenerator class.
# This script activates the virtual environment, parses arguments, triggers code generation,
# AND saves the output to a file in the output/ directory.

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
    # Also print INFO messages to console for visibility during generation
    echo "[$timestamp] [$level] $message"
  fi
}

# Ensure logs and output directories exist
mkdir -p logs output

log_message "INFO" "Starting code generation step (01_generate.sh)"

# Check if venv exists and is valid
if [ ! -d "venv" ] || [ ! -f "venv/bin/activate" ]; then
  log_message "ERROR" "Virtual environment not found. Please run 02_install.sh first."
  exit 1
fi

# Activate virtual environment
# Use subshell to avoid polluting current shell if script fails
(
  source venv/bin/activate || {
    log_message "ERROR" "Failed to activate virtual environment."
    exit 1 # Exit subshell
  }

  # Parse command-line arguments passed TO THIS SHELL SCRIPT
  PROMPT_NAME="generation_prompt_template" # Default prompt
  PROMPTS_FILE_PATH="config/llm_prompts.json" # Default prompts file path
  LLM_CONFIG_FILE_PATH=""                  # Default LLM config path (empty, meaning use env vars)
  OUTPUT_FILENAME_BASE=""                  # Optional explicit output filename base

  while [[ $# -gt 0 ]]; do
    case $1 in
      --prompt)
        PROMPT_NAME="$2"
        shift 2
        ;;
      # Allow overriding prompts file path via shell script argument
      --prompts-path)
        PROMPTS_FILE_PATH="$2"
        shift 2
        ;;
      # Allow specifying LLM config file via shell script argument
      --llm-config-path)
        LLM_CONFIG_FILE_PATH="$2"
        shift 2
        ;;
      --output-file) # Optional: Allow specifying output filename base directly
        OUTPUT_FILENAME_BASE="$2"
        shift 2
        ;;
      *)
        log_message "WARNING" "Unknown argument to 01_generate.sh: $1"
        shift
        ;;
    esac
  done

  log_message "INFO" "Using prompt: $PROMPT_NAME from prompts file: $PROMPTS_FILE_PATH"
  if [ -n "$LLM_CONFIG_FILE_PATH" ]; then
      log_message "INFO" "Using LLM config file: $LLM_CONFIG_FILE_PATH"
  else
      log_message "INFO" "Using LLM config from environment variables."
  fi

  # Determine output path logic (same as before)
  OUTPUT_DIR="output"
  mkdir -p "$OUTPUT_DIR"
  if [ -n "$OUTPUT_FILENAME_BASE" ]; then
      OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILENAME_BASE"
      log_message "INFO" "Using specified output filename base: $OUTPUT_FILENAME_BASE"
  else
      if [[ "$PROMPT_NAME" == *"python"* || "$PROMPT_NAME" == *"process_monitor"* ]]; then
        OUTPUT_FILENAME="${PROMPT_NAME}.py"
      elif [[ "$PROMPT_NAME" == *"script"* || "$PROMPT_NAME" == *"reporter"* || "$PROMPT_NAME" == *"monitor"* ]]; then
        OUTPUT_FILENAME="${PROMPT_NAME}.sh"
      else
        OUTPUT_FILENAME="${PROMPT_NAME}.txt" # Default extension
      fi
      OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILENAME"
      log_message "INFO" "Derived output filename: $OUTPUT_FILENAME"
  fi

  # Prepare arguments for the Python script
  PYTHON_ARGS=(
      "--prompt-name" "$PROMPT_NAME"
      "--prompts-path" "$PROMPTS_FILE_PATH"
  )
  # Add LLM config path only if it was provided to the shell script
  if [ -n "$LLM_CONFIG_FILE_PATH" ]; then
      PYTHON_ARGS+=( "--llm-config-path" "$LLM_CONFIG_FILE_PATH" )
  fi

  # Execute Python code generation AND redirect its standard output to save it to the file
  log_message "INFO" "Generating code and saving to $OUTPUT_PATH ..."
  # <<< --- MODIFICATION HERE: Changed --config-path to --prompts-path and pass args array --- >>>
  if python -m modules.codegen.generator "${PYTHON_ARGS[@]}" > "$OUTPUT_PATH"; then
  # <<< --- END MODIFICATION --- >>>
    # Check if the output file was actually created and is not empty
    if [ -s "$OUTPUT_PATH" ]; then
        log_message "INFO" "Code generation completed successfully and saved to $OUTPUT_PATH."
    else
        log_message "WARNING" "Code generation script ran successfully, but output file '$OUTPUT_PATH' is empty or was not created."
        # exit 1 # Optional: fail if output is empty
    fi
  else
    # Capture exit code if python script fails
    GEN_EXIT_CODE=$?
    log_message "ERROR" "Code generation python script failed with exit code $GEN_EXIT_CODE."
    # rm -f "$OUTPUT_PATH" # Optional: remove empty/partial file
    exit $GEN_EXIT_CODE
  fi
) # End of subshell

SUBSHELL_EXIT_CODE=$?
if [ $SUBSHELL_EXIT_CODE -ne 0 ]; then
    log_message "ERROR" "Code generation step failed within subshell (Exit code: $SUBSHELL_EXIT_CODE)."
    exit $SUBSHELL_EXIT_CODE
fi

log_message "INFO" "Code generation step (01_generate.sh) finished successfully."
exit 0
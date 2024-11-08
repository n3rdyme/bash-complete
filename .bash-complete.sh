#!/bin/bash
# .bash-complete.sh: Shell script for command autocompletion and command override with nested command support

# Initialize an array of supported command names
SUPPORTED_COMMANDS=("yarn")

# Get the directory of the current script to locate .bash-complete-update.cjs
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Function to override supported commands and log them with .bash-complete-update.cjs
_bashcomplete_override() {
  local cmd_name="$1"  # The command name to override (e.g., yarn)
  shift  # Shift off the command name to get the rest of the arguments

  # Capture the full command with arguments and the current working directory
  local full_command=("$cmd_name" "$@")
  local cwd="$(pwd)"

  if [[ "$1" == "auto" ]]; then
    node "$SCRIPT_DIR/.bash-complete-update.cjs" "$cmd_name" --auto
    return 0
  fi

  # Run the actual command and capture its exit code
  command "$cmd_name" "$@"
  local exit_code=$?

  # Run the Node script only if the command exited successfully, hiding all output
  if [[ $exit_code -eq 0 ]]; then
    node "$SCRIPT_DIR/.bash-complete-update.cjs" "${full_command[@]}"
  fi

  # Return the original exit code immediately
  return $exit_code
}

# Autocomplete function with support for nested commands and quoted arguments
_bashcomplete() {
  local cmd_name="$1"
  local cur_word="${COMP_WORDS[COMP_CWORD]}"
  local cwd="$(pwd)"
  local json_path="$SCRIPT_DIR/.bash-complete.json"

  # Check if the JSON file exists
  if [[ ! -f "$json_path" ]]; then
    return 0
  fi

  # Function to escape double quotes for use in jq
  escape_quotes() {
    echo "$1" | sed 's/"/\\"/g'  # Escape double quotes
  }

  # Construct the jq filter based on provided arguments, escaping double quotes
  local jq_filter=".[\$cwd][\"$cmd_name\"]"
  for ((i=1; i < COMP_CWORD; i++)); do
    local arg="$(escape_quotes "${COMP_WORDS[i]}")"
    jq_filter+="[\"$arg\"]"
  done

  # Retrieve possible completions based on the current argument chain
  local commands=$(jq -r --arg cwd "$cwd" "$jq_filter | keys | .[]" "$json_path" 2>/dev/null)

  # Temporarily set COMP_WORDBREAKS to only a space to avoid issues with special characters
  local original_breaks="${COMP_WORDBREAKS}"
  COMP_WORDBREAKS=" "

  # Generate autocompletion suggestions for the current word
  COMPREPLY=($(compgen -W "$commands" -- "$cur_word"))

  # Restore the original COMP_WORDBREAKS
  COMP_WORDBREAKS="$original_breaks"
}

# Register the command overrides and autocomplete for each supported command
for cmd_name in "${SUPPORTED_COMMANDS[@]}"; do
  # Define a function for each supported command
  eval "
  function $cmd_name() {
    _bashcomplete_override \"$cmd_name\" \"\$@\"
    return \$?
  }
  "

  # Register the autocomplete function for each supported command
  complete -F _bashcomplete yarn
done

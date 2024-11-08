#!/bin/bash
# .install.sh: Installer script for bash-complete setup

set -e

# Get the directory of the current script to locate .bash-complete-update.cjs
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Variables
HOME_DIR="$HOME"
BASH_COMPLETE_JSON="$HOME_DIR/.bash-complete.json"
BASH_COMPLETE_UPDATE_CJS="$HOME_DIR/.bash-complete-update.cjs"
BASH_COMPLETE_SH="$HOME_DIR/.bash-complete.sh"
BASHRC_ENTRY="
# bash-complete setup
source ~/.bash-complete.sh
"

# Check for 'jq' dependency
if ! command -v jq &> /dev/null; then
  echo "Error: 'jq' is not installed."
  echo "Please install 'jq' to continue:"
  echo "  - On Debian/Ubuntu: sudo apt-get install jq"
  echo "  - On macOS: brew install jq"
  echo "  - On Red Hat/Fedora: sudo dnf install jq"
  exit 1
fi

# Function to copy file with prompt for overwriting
copy_file() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" ]]; then
    echo "$dest already exists. Do you want to overwrite it? (y/N)"
    read -r overwrite
    if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
      echo "Skipping $dest"
      return
    fi
  fi

  echo "Copying $src to $dest..."
  cp "$src" "$dest"
}

# Copy files to the user's home directory
copy_file "$SCRIPT_DIR/.bash-complete.sh" "$BASH_COMPLETE_SH"
copy_file "$SCRIPT_DIR/.bash-complete-update.cjs" "$BASH_COMPLETE_UPDATE_CJS"

# Create .bash-complete.json if it doesn't exist, with default content '{}'
if [[ ! -e "$BASH_COMPLETE_JSON" ]]; then
  echo "Creating $BASH_COMPLETE_JSON with default content '{}'"
  echo "{}" > "$BASH_COMPLETE_JSON"
fi

# Determine the correct shell configuration file to modify
if [[ "$SHELL" == *"zsh"* ]]; then
  SHELL_CONFIG="$HOME_DIR/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  if [[ -f "$HOME_DIR/.bash_profile" ]]; then
    SHELL_CONFIG="$HOME_DIR/.bash_profile"
  else
    SHELL_CONFIG="$HOME_DIR/.bashrc"
  fi
fi

# Update the shell config file only if it doesn't already include bash-complete setup
if [[ -n "$SHELL_CONFIG" ]]; then
  if ! grep -q "bash-complete" "$SHELL_CONFIG"; then
    echo "Updating $SHELL_CONFIG to include bash-complete setup..."
    echo "$BASHRC_ENTRY" >> "$SHELL_CONFIG"
    echo "Updated $SHELL_CONFIG to include bash-complete setup."
  fi
else
  echo "No supported shell configuration file found. Please add 'source ~/.bash-complete.sh' to your shell's config file manually."
fi

# Done
echo -e "\nInstallation complete."

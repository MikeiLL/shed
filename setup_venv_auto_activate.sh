#!/bin/bash

# This script sets up auto-activation of the virtual environment on directory change.

# Function to add the auto-activation script to Bash or Zsh config files
add_autoactivate_script() {
    local shell_config_file="$1"
    local shell_type="$2"

    # Check if the script is already in the config file
    if grep -q "auto_activate_venv" "$shell_config_file"; then
        echo "Auto-activation script already exists in $shell_config_file."
        return
    fi

    echo "Adding auto-activation script to $shell_config_file..."

    if [[ "$shell_type" == "bash" ]]; then
        cat >> "$shell_config_file" << 'EOF'

# Auto activate virtual environment if in a project directory with a venv folder
function auto_activate_venv() {
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
}

# Trigger auto_activate_venv function on directory change
PROMPT_COMMAND="auto_activate_venv; $PROMPT_COMMAND"
EOF

    elif [[ "$shell_type" == "zsh" ]]; then
        cat >> "$shell_config_file" << 'EOF'

# Auto activate virtual environment if in a project directory with a venv folder
function auto_activate_venv() {
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
    fi
}

# Trigger auto_activate_venv function on directory change
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_activate_venv
EOF
    fi

    echo "Auto-activation script added to $shell_config_file. Please restart your terminal or run 'source $shell_config_file' to apply changes."
}

# Check if the user is using Bash or Zsh
SHELL_TYPE=$(basename "$SHELL")

if [[ "$SHELL_TYPE" == "bash" ]]; then
    SHELL_CONFIG_FILE="$HOME/.bashrc"
    add_autoactivate_script "$SHELL_CONFIG_FILE" "bash"
elif [[ "$SHELL_TYPE" == "zsh" ]]; then
    SHELL_CONFIG_FILE="$HOME/.zshrc"
    add_autoactivate_script "$SHELL_CONFIG_FILE" "zsh"
else
    echo "Unsupported shell detected. This script currently supports only Bash and Zsh."
    exit 1
fi
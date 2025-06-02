#!/usr/bin/env bash
# This library script provides common helper functions for the configuration
# generation scripts located in the 'scripts/config/' directory.
set -euo pipefail

# Prepares for writing a single target configuration file.
# Creates the parent directory if it doesn't exist.
# Arguments:
#   $1: target_file - The full path to the configuration file to be generated.
#   $2: component_name - A human-readable name of the component for logging.
prepare_target_file_write() {
    local target_file="$1"
    local component_name="$2"
    echo "Generating $component_name configuration: $target_file..."
    mkdir -p "$(dirname "$target_file")" # Ensure parent directory exists
}

# Finishes the process of writing a single target configuration file.
# Prints a success message.
# Arguments:
#   $1: target_file - The full path to the configuration file that was generated.
#   $2: component_name - A human-readable name of the component for logging.
finish_target_file_write() {
    local target_file="$1"
    local component_name="$2"
    echo "$component_name configuration ($target_file) generated."
}

# Prepares a target directory where multiple script files might be generated.
# Creates the directory if it doesn't exist.
# Arguments:
#   $1: target_dir - The full path to the directory.
#   $2: description - A human-readable description of the scripts being generated for logging.
prepare_script_generation_dir() {
    local target_dir="$1"
    local description="$2"
    echo "Generating $description in $target_dir..."
    mkdir -p "$target_dir" # Ensure the directory exists
}

# Finishes the process of generating scripts in a target directory.
# Prints a success message and makes any generated '*.sh' files executable.
# Arguments:
#   $1: target_dir - The full path to the directory where scripts were generated.
#   $2: description - A human-readable description for logging.
finish_script_generation_dir() {
    local target_dir="$1"
    local description="$2"
    echo "$description generated in $target_dir."
    # Find all .sh files in the target directory (non-recursive) and make them executable.
    # -maxdepth 1: Prevents find from descending into subdirectories.
    # -name '*.sh': Finds files ending with .sh.
    # -exec chmod +x {} +: Executes chmod +x on the found files.
    #   The '{}' is replaced by the found file names, and '+' groups multiple files
    #   into a single chmod command for efficiency.
    # If no .sh files are found, chmod will not be executed.
    find "$target_dir" -maxdepth 1 -name '*.sh' -exec chmod +x {} +

    # Note: It's harder to conditionally print "Made scripts executable" without
    # re-running find or checking its output. A generic message or no message
    # after this simplified command is common. For now, we'll assume the action
    # is attempted and trust find/chmod to handle no-ops gracefully.
    # If specific feedback is needed, the previous approach was more explicit.
    # For simplicity and common practice with 'find -exec', we omit the conditional echo.
    # A more advanced approach could count files first if the message is critical.
    echo "Attempted to make shell scripts in $target_dir executable (if any were found)."
}

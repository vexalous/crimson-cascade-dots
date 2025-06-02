#!/usr/bin/env bash
# This script provides reusable shell functions for common file system operations
# needed during the dotfiles setup process, such as creating directories and
# copying files and components.
set -euo pipefail

# Ensures that specified subdirectories exist within a base target directory.
# Arguments:
#   $1: base_target_dir - The base directory under which subdirectories will be created.
#   $@: sub_dirs_to_create - An array of subdirectory names to create (after $1).
ensure_target_dirs() {
    local base_target_dir="$1"
    shift # Removes the first argument ($1), so $@ now contains only sub_dirs_to_create.
    local sub_dirs_to_create=("$@")

    echo "Ensuring target directories in $base_target_dir/ ..."
    for sub_dir in "${sub_dirs_to_create[@]}"; do
        mkdir -p "$base_target_dir/$sub_dir"
    done
    echo "Target directories ensured."
    echo ""
}

copy_component() {
    local source_base_dir="$1"
    local target_base_dir="$2"
    local component_rel_path="$3"
    local component_name_for_msg="$4"

    local full_source_path="$source_base_dir/$component_rel_path"
    local full_target_path="$target_base_dir/$component_rel_path"
    local target_dir
    target_dir=$(dirname "$full_target_path")

    if [ ! -e "$full_source_path" ]; then
        echo "WARNING: Source $full_source_path not found. Skipping $component_name_for_msg."
        return 1
    fi

    echo "Processing $component_name_for_msg..."
    if ! mkdir -p "$target_dir"; then
        echo "ERROR: Failed to create target directory $target_dir for $component_name_for_msg." >&2
        exit 1
    fi

    # This function can cause the script to exit if critical operations like mkdir or cp fail.
    if [ -d "$full_source_path" ]; then
        if ! mkdir -p "$full_target_path"; then
             echo "ERROR: Failed to create target directory $full_target_path for $component_name_for_msg." >&2
             exit 1 # Critical error, exit script
        fi
        # -r: recursive, -T: treat source as a normal file.
        # This ensures the *contents* of $full_source_path are copied into $full_target_path.
        if ! cp -rT "$full_source_path/" "$full_target_path/"; then
            echo "ERROR: Failed to copy directory $component_name_for_msg from $full_source_path to $full_target_path." >&2
            exit 1 # Critical error, exit script
        fi
    else
        if ! cp "$full_source_path" "$full_target_path"; then
            echo "ERROR: Failed to copy file $component_name_for_msg from $full_source_path to $full_target_path." >&2
            exit 1
        fi
    fi

    echo "$component_name_for_msg files copied to $full_target_path."
    
    # Special handling: If the component is Hyprland and it has a scripts directory, make scripts executable.
    if [ "$component_name_for_msg" == "Hyprland" ] && [ -d "$full_target_path/scripts" ]; then
        if ! chmod +x "$full_target_path/scripts/"*.sh; then
            # This is a warning, not a critical error. Setup continues.
            echo "WARNING: Failed to make Hyprland scripts executable in $full_target_path/scripts/." >&2
        else
            echo "Made Hyprland scripts executable."
        fi
    fi
    echo ""
}

# Copies a single file from a source location (relative to a base) to a target location (relative to a base).
# This function can cause the script to exit if critical operations like mkdir or cp fail.
# Arguments:
#   $1: source_file_rel_path - Relative path of the source file within source_base_dir.
#   $2: target_file_rel_path - Relative path for the target file within target_base_dir.
#   $3: source_base_dir      - The base directory for the source file.
#   $4: target_base_dir      - The base directory for the target file.
#   $5: component_name_for_msg - User-friendly name for logging.
copy_single_file() {
    local source_file_rel_path="$1"
    local target_file_rel_path="$2"
    local source_base_dir="$3"
    local target_base_dir="$4"
    local component_name_for_msg="$5"

    local full_source_path="$source_base_dir/$source_file_rel_path"
    local full_target_path="$target_base_dir/$target_file_rel_path"
    local target_dir
    target_dir=$(dirname "$full_target_path")

    if [ -f "$full_source_path" ]; then
        echo "Copying $component_name_for_msg file..."
        if ! mkdir -p "$target_dir"; then
            echo "ERROR: Failed to create target directory $target_dir for $component_name_for_msg file." >&2
            exit 1 # Critical error, exit script
        fi
        if ! cp "$full_source_path" "$full_target_path"; then
            echo "ERROR: Failed to copy $component_name_for_msg file from $full_source_path to $full_target_path." >&2
            exit 1 # Critical error, exit script
        fi
        echo "$component_name_for_msg file copied."
    else
        echo "WARNING: Source '$full_source_path' not found. $component_name_for_msg config not copied."
    fi
    echo ""
}

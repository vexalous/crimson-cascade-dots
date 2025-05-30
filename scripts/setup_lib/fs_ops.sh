#!/usr/bin/env bash
set -euo pipefail

ensure_target_dirs() {
    local base_target_dir="$1"
    shift
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
    mkdir -p "$target_dir"

    if [ -d "$full_source_path" ]; then
        mkdir -p "$full_target_path"
        cp -rT "$full_source_path/" "$full_target_path/"
    else
        cp "$full_source_path" "$full_target_path"
    fi

    if [ $? -eq 0 ]; then
        echo "$component_name_for_msg files copied to $full_target_path."
        if [ "$component_name_for_msg" == "Hyprland" ] && [ -d "$full_target_path/scripts" ]; then
            chmod +x "$full_target_path/scripts/"*.sh
        fi
    else
        echo "ERROR: Failed to copy $component_name_for_msg from $full_source_path."
    fi
    echo ""
}

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
        mkdir -p "$target_dir"
        cp "$full_source_path" "$full_target_path"
        if [ $? -eq 0 ]; then
            echo "$component_name_for_msg file copied."
        else
            echo "ERROR: Failed to copy $component_name_for_msg file."
        fi
    else
        echo "WARNING: Source '$full_source_path' not found. $component_name_for_msg config not copied."
    fi
    echo ""
}

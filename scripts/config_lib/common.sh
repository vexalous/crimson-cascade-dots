#!/usr/bin/env bash
set -euo pipefail

prepare_target_file_write() {
    local target_file="$1"
    local component_name="$2"
    echo "Generating $component_name configuration: $target_file..."
    mkdir -p "$(dirname "$target_file")"
}

finish_target_file_write() {
    local target_file="$1"
    local component_name="$2"
    echo "$component_name configuration ($target_file) generated."
}

prepare_script_generation_dir() {
    local target_dir="$1"
    local description="$2"
    echo "Generating $description in $target_dir..."
    mkdir -p "$target_dir"
}

finish_script_generation_dir() {
    local target_dir="$1"
    local description="$2"
    echo "$description generated in $target_dir."
    if [ -n "$(ls -A "$target_dir"/*.sh 2>/dev/null)" ]; then
        chmod +x "$target_dir"/*.sh
        echo "Made scripts in $target_dir executable."
    fi
}

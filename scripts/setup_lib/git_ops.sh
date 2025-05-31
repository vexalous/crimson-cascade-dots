#!/usr/bin/env bash
set -euo pipefail

determine_source_dir() {
    local local_dotfiles_source_dir=""
    local local_temp_clone_dir=""
    if [ -d ".git" ] && [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/hypr" ]; then
        echo "Running from Git repository. Attempting to update..." >&2
        local_dotfiles_source_dir="$(git rev-parse --show-toplevel)"
        git -C "$local_dotfiles_source_dir" pull origin main
        if [ $? -ne 0 ]; then
            echo "ERROR: 'git pull' failed." >&2
            exit 1
        fi
        echo "Repository updated from $local_dotfiles_source_dir." >&2
        local_temp_clone_dir=""
    else
        echo "Not in a recognized local dotfiles Git repository. Cloning fresh..." >&2
        local_temp_clone_dir=$(mktemp -d -t "${REPO_NAME}_XXXXXX")
        git clone --depth 1 "$GIT_REPO_URL" "$local_temp_clone_dir"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to clone $GIT_REPO_URL." >&2
            rm -rf "$local_temp_clone_dir"
            exit 1
        fi
        local_dotfiles_source_dir="$local_temp_clone_dir"
        echo "Repository cloned to $local_dotfiles_source_dir for this run." >&2
    fi
    echo "$local_dotfiles_source_dir $local_temp_clone_dir"
}

cleanup_temp_dir() {
    local temp_dir_to_clean="$1"
    if [ -n "$temp_dir_to_clean" ] && [ -d "$temp_dir_to_clean" ]; then
        echo "Removing temporary clone directory $temp_dir_to_clean..."
        rm -rf "$temp_dir_to_clean"
    fi
}

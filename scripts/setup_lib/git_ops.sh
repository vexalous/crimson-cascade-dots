#!/usr/bin/env bash
set -euo pipefail

determine_source_dir() {
    if [ -d ".git" ] && [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/hypr" ]; then
        echo "Running from Git repository. Attempting to update..."
        DOTFILES_SOURCE_DIR_GLOBAL="$(git rev-parse --show-toplevel)"
        git -C "$DOTFILES_SOURCE_DIR_GLOBAL" pull origin main
        if [ $? -ne 0 ]; then
            echo "ERROR: 'git pull' failed."
            exit 1
        fi
        echo "Repository updated from $DOTFILES_SOURCE_DIR_GLOBAL."
        TEMP_CLONE_DIR_GLOBAL=""
    else
        echo "Not in a recognized local dotfiles Git repository. Cloning fresh..."
        TEMP_CLONE_DIR_GLOBAL=$(mktemp -d -t "${REPO_NAME}_XXXXXX")
        git clone --depth 1 "$GIT_REPO_URL" "$TEMP_CLONE_DIR_GLOBAL"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to clone $GIT_REPO_URL."
            rm -rf "$TEMP_CLONE_DIR_GLOBAL"
            exit 1
        fi
        DOTFILES_SOURCE_DIR_GLOBAL="$TEMP_CLONE_DIR_GLOBAL"
        echo "Repository cloned to $DOTFILES_SOURCE_DIR_GLOBAL for this run."
    fi
    echo ""
}

cleanup_temp_dir() {
    local temp_dir_to_clean="$1"
    if [ -n "$temp_dir_to_clean" ] && [ -d "$temp_dir_to_clean" ]; then
        echo "Removing temporary clone directory $temp_dir_to_clean..."
        rm -rf "$temp_dir_to_clean"
    fi
}

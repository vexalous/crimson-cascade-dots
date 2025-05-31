#!/usr/bin/env bash
set -euo pipefail

determine_source_dir() {
    local local_dotfiles_source_dir=""
    local local_temp_clone_dir=""
    if [ -d ".git" ] && [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/hypr" ]; then
        echo "Running from Git repository. Attempting to update..." >&2
        local_dotfiles_source_dir="$(git rev-parse --show-toplevel)"

        current_branch=$(git -C "$local_dotfiles_source_dir" symbolic-ref --short HEAD 2>/dev/null || echo "")

        echo "Fetching updates from origin..." >&2
        if ! git -C "$local_dotfiles_source_dir" fetch origin >&2; then
            echo "ERROR: 'git fetch origin' failed. Cannot ensure repository is up to date." >&2
            exit 1
        fi

        if [ "$current_branch" != "main" ]; then
            echo "Current branch is '$current_branch', attempting to switch to 'main' branch..." >&2
            if git -C "$local_dotfiles_source_dir" rev-parse --verify main >/dev/null 2>&1; then
                git -C "$local_dotfiles_source_dir" checkout main >&2
                if [ $? -ne 0 ]; then
                    echo "ERROR: Failed to checkout 'main' branch. Please resolve manually." >&2
                    exit 1
                fi
            elif git -C "$local_dotfiles_source_dir" rev-parse --verify origin/main >/dev/null 2>&1; then
                git -C "$local_dotfiles_source_dir" checkout -b main --track origin/main >&2
                 if [ $? -ne 0 ]; then
                    echo "ERROR: Failed to create and checkout 'main' branch tracking 'origin/main'. Please resolve manually." >&2
                    exit 1
                fi
            else
                echo "ERROR: Neither local 'main' nor 'origin/main' found. Cannot proceed with update." >&2
                exit 1
            fi
            current_branch="main"
        fi

        echo "Ensuring local 'main' branch tracks 'origin/main'..." >&2
        if ! git -C "$local_dotfiles_source_dir" branch --set-upstream-to=origin/main main >&2; then
            echo "ERROR: Failed to set 'main' to track 'origin/main'. Cannot ensure correct pull behavior." >&2
            exit 1
        fi

        echo "Pulling changes for 'main' branch..." >&2
        git -C "$local_dotfiles_source_dir" pull >&2
        if [ $? -ne 0 ]; then
            echo "ERROR: 'git pull' failed. Please resolve conflicts or issues manually." >&2
            exit 1
        fi
        echo "Repository updated from $local_dotfiles_source_dir." >&2
        local_temp_clone_dir=""
    else
        echo "Not in a recognized local dotfiles Git repository. Cloning fresh..." >&2
        local_temp_clone_dir=$(mktemp -d -t "${REPO_NAME}_XXXXXX")
        if [ -z "${REPO_NAME:-}" ]; then
            echo "ERROR: REPO_NAME variable is not set. Cannot clone." >&2
            exit 1
        fi
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

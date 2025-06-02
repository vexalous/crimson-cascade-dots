#!/usr/bin/env bash
# This script provides functions for managing the source of the dotfiles,
# either by updating an existing local Git repository or by cloning a fresh copy.
# It's designed to be sourced by the main setup script.
set -euo pipefail

# Determines the source directory for dotfiles.
# If running within a recognized local git repository of the dotfiles, it attempts to:
# 1. Fetch updates from 'origin'.
# 2. Switch to the 'main' branch if not already on it.
# 3. Ensure the local 'main' tracks 'origin/main'.
# 4. Pull the latest changes.
# If not in a recognized repository, it clones a fresh copy from GIT_REPO_URL into a temporary directory.
#
# Outputs two values to STDOUT, space-separated:
# 1. The determined dotfiles source directory path.
# 2. The temporary clone directory path (empty string if not cloned temporarily).
# The caller should use 'read' to capture these, e.g.,
#   read -r DOTFILES_SOURCE_DIR TEMP_CLONE_DIR <<< "$(determine_source_dir)"
#
# Expects GIT_REPO_URL and REPO_NAME to be set in the calling environment if cloning is necessary.
determine_source_dir() {
    local local_dotfiles_source_dir=""
    local local_temp_clone_dir="" # Will store the path if a temporary clone is made

    # Check if current directory is within a Git repo and if a 'hypr' subdirectory exists at the repo root.
    # The 'hypr' check is a heuristic to ensure it's the correct dotfiles repository.
    if [ -d ".git" ] && [ -d "$(git rev-parse --show-toplevel 2>/dev/null)/hypr" ]; then
        echo "Running from local Git repository. Attempting to update..." >&2
        local_dotfiles_source_dir="$(git rev-parse --show-toplevel)"

        # Get the current branch name.
        current_branch=$(git -C "$local_dotfiles_source_dir" symbolic-ref --short HEAD 2>/dev/null || echo "")

        echo "Fetching updates from origin..." >&2
        if ! git -C "$local_dotfiles_source_dir" fetch origin >&2; then
            echo "ERROR: 'git fetch origin' failed. Cannot ensure repository is up to date." >&2
            exit 1
        fi

        # Ensure we are on the 'main' branch.
        if [ "$current_branch" != "main" ]; then
            echo "Current branch is '$current_branch', attempting to switch to 'main' branch..." >&2
            # Check if a local 'main' branch exists.
            if git -C "$local_dotfiles_source_dir" rev-parse --verify main >/dev/null 2>&1; then
                # Local 'main' exists, check it out.
                git -C "$local_dotfiles_source_dir" checkout main >&2
                if [ $? -ne 0 ]; then
                    echo "ERROR: Failed to checkout 'main' branch. Please resolve manually." >&2
                    exit 1
                fi
            # Check if 'origin/main' exists (remote tracking branch).
            elif git -C "$local_dotfiles_source_dir" rev-parse --verify origin/main >/dev/null 2>&1; then
                # Create local 'main' tracking 'origin/main'.
                git -C "$local_dotfiles_source_dir" checkout -b main --track origin/main >&2
                 if [ $? -ne 0 ]; then
                    echo "ERROR: Failed to create and checkout 'main' branch tracking 'origin/main'. Please resolve manually." >&2
                    exit 1
                fi
            else
                # Neither local 'main' nor 'origin/main' exists, which is unexpected for a typical setup.
                echo "ERROR: Neither local 'main' nor 'origin/main' found. Cannot proceed with update." >&2
                exit 1
            fi
            current_branch="main" # Update current branch variable after successful checkout
        fi

        # Ensure the local 'main' branch is set up to track 'origin/main'.
        # This is important for 'git pull' to work as expected.
        echo "Ensuring local 'main' branch tracks 'origin/main'..." >&2
        if ! git -C "$local_dotfiles_source_dir" branch --set-upstream-to=origin/main main >&2; then
            echo "ERROR: Failed to set 'main' to track 'origin/main'. Cannot ensure correct pull behavior." >&2
            exit 1
        fi

        # Pull the latest changes from the remote 'main' branch.
        echo "Pulling changes for 'main' branch..." >&2
        git -C "$local_dotfiles_source_dir" pull >&2
        if [ $? -ne 0 ]; then
            echo "ERROR: 'git pull' failed. Please resolve conflicts or issues manually." >&2
            exit 1
        fi
        echo "Repository updated from $local_dotfiles_source_dir." >&2
        # local_temp_clone_dir remains empty as we used the existing directory
    else
        # Not in a recognized git repository, so clone it fresh.
        echo "Not in a recognized local dotfiles Git repository. Cloning fresh..." >&2
        # REPO_NAME and GIT_REPO_URL must be set by the calling script.
        if [ -z "${REPO_NAME:-}" ] || [ -z "${GIT_REPO_URL:-}" ]; then
            echo "ERROR: REPO_NAME and/or GIT_REPO_URL variables are not set. Cannot clone." >&2
            exit 1
        fi
        local_temp_clone_dir=$(mktemp -d -t "${REPO_NAME}_XXXXXX") # Create a temporary directory for cloning
        git clone --depth 1 "$GIT_REPO_URL" "$local_temp_clone_dir" # Clone with depth 1 for speed
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

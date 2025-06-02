#!/usr/bin/env bash
# This script robustly generates the hyprlock.conf configuration file.
# It is designed for developers to create the version of hyprlock.conf that
# will be committed to the repository.
#
# Key features:
# - Validates required environment variables (colors, paths, etc.).
# - Checks for essential command-line tools.
# - Validates wallpaper file existence and readability.
# - Performs an atomic write to the target hyprlock.conf file by using a
#   temporary file and 'mv -T' to prevent data corruption.
# - Includes extensive error checking and informative exit codes.
# - Uses 'declare -gr' for global read-only variables (requires Bash 4.3+).

set -euo pipefail

# Source common library functions (e.g., for logging start/finish of file write).
source "$(dirname "$0")/../config_lib/common.sh"

# Ensure Bash version is sufficient for 'declare -gr'.
if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
    printf "FATAL: This script requires Bash version 4.3 or later for 'declare -gr' and robust variable checks.\n" >&2
    exit 2 # Specific exit code for version incompatibility
fi

# declare -gr: Defines global read-only variables.
# SC2155: For SCRIPT_NAME and SCRIPT_ABSOLUTE_PATH, splitting declare and assignment.
declare -g SCRIPT_NAME
SCRIPT_NAME="$(basename "$0")" # Script's own name for messages
readonly SCRIPT_NAME

declare -g SCRIPT_ABSOLUTE_PATH
SCRIPT_ABSOLUTE_PATH="$(readlink -m "${BASH_SOURCE[0]}")" # Absolute path to this script
readonly SCRIPT_ABSOLUTE_PATH

# Developer Usage Notes for WALLPAPER_FILE:
# This script (`hyprlock.sh`) is intended for developers to generate the
# `hyprlock.conf` file that will be committed to the repository.
#
# The `WALLPAPER_FILE` environment variable is used directly in the generated
# configuration file for the `background { path = ... }` directive.
# It is also checked by this script for existence and readability *at the time
# this script is run*.
#
# Therefore, when a developer runs this script:
# 1. `WALLPAPER_FILE` must be set to the exact path string that `hyprlock`
#    should use at runtime on the end-user's system.
#    - If Hyprlock expands `~` or `$HOME`, you can use those. For example:
#      `export WALLPAPER_FILE="\$HOME/.config/hypr/wallpaper/my_lockscreen.png"`
#      (Note: `\$HOME` ensures it's a literal string if set via a script that might expand it).
#    - If Hyprlock requires an absolute path, provide that.
#
# 2. For this script's validation checks (`[ -f "$WALLPAPER_FILE" ]`, etc.) to pass,
#    the path specified by `WALLPAPER_FILE` must exist and be readable *during script execution*.
#    - If `WALLPAPER_FILE` is set to a path like `\$HOME/...` (intended for runtime),
#      the validation will likely fail unless that exact path (e.g., literally
#      `$HOME/...` if HOME is not set, or the expanded path if HOME is set) exists.
#    - To satisfy validation when using such runtime paths:
#      a) Ensure the actual wallpaper file (e.g., `my_lockscreen.png`) is present in the
#         repository (e.g., in `hypr/wallpaper/`).
#      b) Temporarily create the runtime path or a symlink to it before running this script,
#         OR modify this script to separate validation paths from output paths if needed.
#         For example, you might `ln -s "$(pwd)/hypr/wallpaper/my_lockscreen.png" "$HOME/.config/hypr/wallpaper/my_lockscreen.png"`
#         before running, assuming `WALLPAPER_FILE` is set to `$HOME/.config/hypr/wallpaper/my_lockscreen.png`.
#
# The `setup.sh` script is responsible for ensuring the actual wallpaper image
# is copied to the location expected by the generated `hyprlock.conf` on the
# end-user's system.

# SC2155: For REQUIRED_VARS array, splitting declare and assignment.
declare -g REQUIRED_VARS
REQUIRED_VARS=(
    "HYPRLOCK_TARGET_FILE"
    "WALLPAPER_FILE"
    "HL_NEAR_BLACK_RGBA"
    "HL_DARK_GRAY_INPUT_BG"
    "HL_CRIMSON_SOLID"
    "HL_TEXT_FIELD_FONT_COLOR"
    "HL_DIM_GRAY_PLACEHOLDER"
    "HL_DARK_RED_FAIL"
    "HL_OFF_WHITE_TEXT"
    "HL_LIGHT_GRAY_TEXT"
) # List of environment variables that must be set for the script to run.
readonly REQUIRED_VARS

# Centralized error handling function.
# Prints a formatted error message to stderr and exits the script.
# Arguments:
#   $1: Error message string.
#   $2: Exit code (integer, defaults to 1).
_exit_with_error() {
    local message="${1:-An unspecified critical error occurred}"
    local exit_code="${2:-1}"
    printf "%s: FATAL: %s (Exiting with code %d)\n" "$SCRIPT_NAME" "$message" "$exit_code" >&2
    exit "$exit_code"
}

_ensure_essential_commands_exist() {
    local cmd
    # List of essential POSIX/GNU utilities required by this script.
    for cmd in "cat" "dirname" "mktemp" "mv" "printf" "date" "mkdir" "rm" "readlink"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then # Check if command is in PATH
            _exit_with_error "Essential command '$cmd' is not found in PATH. Please install it or correct your PATH." 3
        fi
    done
}

# Validates that all environment variables listed in REQUIRED_VARS are set, non-empty,
# and that paths like HYPRLOCK_TARGET_FILE and WALLPAPER_FILE meet specific safety
# and existence criteria. Exits with an error if any validation fails.
_validate_critical_environment_variables() {
    local missing_var_count=0
    local var_name
    local i
    for i in "${!REQUIRED_VARS[@]}"; do
        var_name="${REQUIRED_VARS[$i]}"
        if ! [[ -v "$var_name" && -n "${!var_name}" ]]; then
            printf "%s: ERROR: Required environment variable '%s' is not set or is empty.\n" "$SCRIPT_NAME" "$var_name" >&2
            missing_var_count=$((missing_var_count + 1))
        fi
    done

    if ((missing_var_count > 0)); then
        _exit_with_error "Halting due to missing or empty required environment variables. See details above." 4
    fi

    if [[ "$HYPRLOCK_TARGET_FILE" == "/" || "$HYPRLOCK_TARGET_FILE" == "." || "$HYPRLOCK_TARGET_FILE" == ".." || "$HYPRLOCK_TARGET_FILE" =~ /\.\.$ || "$HYPRLOCK_TARGET_FILE" =~ /\.$ || "$HYPRLOCK_TARGET_FILE" =~ ^\.\./ ]]; then
        _exit_with_error "HYPRLOCK_TARGET_FILE ('$HYPRLOCK_TARGET_FILE') appears to be an unsafe or ambiguous path." 5
    fi
    
    local resolved_target_path
    if ! resolved_target_path="$(readlink -m "$HYPRLOCK_TARGET_FILE")"; then
        _exit_with_error "Could not resolve HYPRLOCK_TARGET_FILE ('$HYPRLOCK_TARGET_FILE') to an absolute path. Check existence and permissions of parent directories." 6
    fi
    if [[ "$resolved_target_path" == "$SCRIPT_ABSOLUTE_PATH" ]]; then
        _exit_with_error "HYPRLOCK_TARGET_FILE ('$HYPRLOCK_TARGET_FILE') cannot be the script itself ('$SCRIPT_ABSOLUTE_PATH')." 7
    fi


    if [ ! -f "$WALLPAPER_FILE" ]; then
        _exit_with_error "WALLPAPER_FILE ('$WALLPAPER_FILE') does not exist or is not a regular file." 8
    fi
    if [ ! -r "$WALLPAPER_FILE" ]; then
        _exit_with_error "WALLPAPER_FILE ('$WALLPAPER_FILE') is not readable. Check permissions." 9
    fi
    if ! [ -s "$WALLPAPER_FILE" ]; then
        _exit_with_error "WALLPAPER_FILE ('$WALLPAPER_FILE') is empty. Please provide a valid wallpaper file." 10
    fi
}

_generate_hyprlock_config_content_string() {
    # This function outputs the content of hyprlock.conf.
    # Environment variables (e.g., $WALLPAPER_FILE, $HL_NEAR_BLACK_RGBA)
    # are expanded here by Bash when the cat << EOF block is processed.
    cat << EOF
# Hyprlock Configuration File
# Generated by $SCRIPT_NAME

general {
    disable_loading_bar = true; # Disables the loading bar animation.
    hide_cursor = true;         # Hides the cursor when the lockscreen is active.
    grace = 0;                  # No grace period after locking (immediate lock).
    no_fade_in = false;         # Enables a fade-in animation for the lockscreen.
}

background {
    # Path to the wallpaper image. $WALLPAPER_FILE is an environment variable
    # set when this hyprlock.conf generator script is run.
    path = $WALLPAPER_FILE;

    # Fallback color if the wallpaper cannot be loaded or is transparent.
    # $HL_NEAR_BLACK_RGBA is an environment variable for the color value.
    color = $HL_NEAR_BLACK_RGBA;
}

input-field {
    monitor = ;                   # Empty means apply to all monitors.
    size = 400, 55;               # Width and height of the input field.
    outline_thickness = 3;        # Thickness of the border outline.
    dots_size = 0.28;             # Size of the dots representing typed characters.
    dots_spacing = 0.28;          # Spacing between dots.
    dots_center = true;           # Center the dots within the input field.
    dots_rounding = -1;           # Rounding of the dots (-1 for fully rounded).
    inner_color = $HL_DARK_GRAY_INPUT_BG; # Background color of the input field.
    outer_color = $HL_CRIMSON_SOLID;    # Color of the border outline.
    font_color = $HL_TEXT_FIELD_FONT_COLOR; # Color of the input text (if not hidden).
    fade_on_empty = true;         # Whether the input field should fade when empty.
    fade_timeout = 800;           # Timeout in milliseconds for the fade effect.
    fade_alpha = 0.15;            # Opacity level for the fade effect.
    placeholder_text = <i>ENTER PASSWORD</i>; # Text shown when the input field is empty.
    placeholder_color = $HL_DIM_GRAY_PLACEHOLDER; # Color of the placeholder text.
    hide_input = false;           # Set to true to hide input characters (e.g., with asterisks).
                                  # Note: Dots settings above provide visual obfuscation.
    rounding = 10;                # Corner rounding for the input field.
    check_color = $HL_CRIMSON_SOLID; # Color of the checkmark/dots on successful input (unused if hidden).
    fail_color = $HL_DARK_RED_FAIL;   # Color of the input field on authentication failure.
    # Text displayed on authentication failure (uses Pango markup).
    fail_text = <b><span foreground="$HL_OFF_WHITE_TEXT" background="$HL_DARK_RED_FAIL" size="large"> ACCESS DENIED </span></b>;
    fail_transition = 400;        # Duration in ms for the fail animation.
    position = 0, 50;             # Position (x, y offset from center).
    halign = center;              # Horizontal alignment.
    valign = center;              # Vertical alignment.
}

# Time Label (HH:MM)
label {
    monitor = ;
    # text uses 'cmd[update_interval_ms] command_to_run' to dynamically update.
    text = cmd[update:1000] echo \$(date +"%H:%M"); # Updates every 1000ms (1 second).
    color = $HL_OFF_WHITE_TEXT;
    font_size = 90;
    font_family = "JetBrainsMono Nerd Font ExtraBold";
    position = 0, -150; # Positioned above the input field.
    halign = center;
    valign = center;
    shadow_passes = 2;  # Number of shadow rendering passes for a softer shadow.
    shadow_color = rgba(0,0,0,0.4); # Shadow color.
    shadow_size = 3;    # Shadow offset/blur.
    shadow_boost = 1.1; # Multiplier for shadow intensity.
}

# Date Label (MM/DD/YY)
label {
    monitor = ;
    text = cmd[update:3600000] echo \$(date +"%m/%d/%y"); # Updates every hour.
    color = $HL_LIGHT_GRAY_TEXT;
    font_size = 24;
    font_family = "JetBrainsMono Nerd Font";
    position = 0, -70; # Positioned between the time and input field.
    halign = center;
    valign = center;
    shadow_passes = 1;
    shadow_color = rgba(0,0,0,0.3);
    shadow_size = 2;
}
EOF
}

_safe_cleanup_temporary_file() {
    local temp_file_to_clean="$1"
    if [ -n "$temp_file_to_clean" ] && [ -e "$temp_file_to_clean" ]; then
        if ! rm -f "$temp_file_to_clean"; then
            printf "%s: WARNING: Failed to remove temporary file '%s'. Manual cleanup may be required.\n" "$SCRIPT_NAME" "$temp_file_to_clean" >&2
        fi
    fi
}

_perform_main_operation() {
    _ensure_essential_commands_exist
    _validate_critical_environment_variables

    _ensure_essential_commands_exist
    _validate_critical_environment_variables

    # Resolve HYPRLOCK_TARGET_FILE to an absolute, canonical path.
    # 'readlink -m' resolves symlinks, '..', '.' and makes the path absolute.
    local final_target_path
    final_target_path="$(readlink -m "$HYPRLOCK_TARGET_FILE")"
    
    # Log start of operation (uses function from common.sh)
    prepare_target_file_write "$final_target_path" "Hyprlock"

    local target_parent_directory
    target_parent_directory="$(dirname "$final_target_path")"

    # --- Pre-write checks for target directory ---
    if [ -z "$target_parent_directory" ]; then
        _exit_with_error "Could not determine parent directory from resolved path ('$final_target_path'). This should not happen if path resolution succeeded." 11
    fi
    if ! mkdir -p "$target_parent_directory"; then # Ensure parent directory exists
        _exit_with_error "Failed to create or ensure parent directory structure exists for: '$target_parent_directory'." 12
    fi
    if ! [ -d "$target_parent_directory" ]; then
        _exit_with_error "Target parent directory path '$target_parent_directory' is not a directory after 'mkdir -p' attempt. This is unexpected." 13
    fi
    if ! [ -w "$target_parent_directory" ]; then # Check if writable
        _exit_with_error "Target parent directory '$target_parent_directory' is not writable. Check permissions." 14
    fi
    if ! [ -x "$target_parent_directory" ]; then # Check if searchable/executable
        _exit_with_error "Target parent directory '$target_parent_directory' is not searchable (execute permission missing). Cannot create files within." 15
    fi

    # --- Create a temporary file for writing the configuration ---
    # This allows for an atomic update of the final configuration file, preventing corruption.
    local temp_config_file_path=""
    # mktemp creates a unique temporary file in the target's parent directory.
    # The XXXXXX is replaced by random characters.
    if ! temp_config_file_path="$(mktemp "$target_parent_directory/hyprlock.conf.temp.XXXXXX")"; then
        _exit_with_error "mktemp failed to create a temporary file in '$target_parent_directory'. Check permissions, available inodes, and disk space." 16
    fi
    
    # --- Robustness checks for mktemp's output ---
    if [ -z "$temp_config_file_path" ]; then # Should be caught by mktemp's exit code, but as a safeguard.
        _safe_cleanup_temporary_file "$temp_config_file_path"
        _exit_with_error "mktemp succeeded but returned an empty file name. This is a critical system anomaly." 17
    fi
    if ! [ -f "$temp_config_file_path" ]; then
        _safe_cleanup_temporary_file "$temp_config_file_path"
        _exit_with_error "Temporary file '$temp_config_file_path' reported by mktemp does not exist or is not a regular file." 18
    fi
    if ! [ -w "$temp_config_file_path" ]; then # Check if writable
        _safe_cleanup_temporary_file "$temp_config_file_path"
        _exit_with_error "Temporary file '$temp_config_file_path' created by mktemp is not writable." 19
    fi

    # Ensure temporary file is cleaned up on script exit or interruption.
    trap '_safe_cleanup_temporary_file "$temp_config_file_path"' EXIT HUP INT QUIT PIPE TERM

    printf "%s: INFO: Generating content into temporary file: %s\n" "$SCRIPT_NAME" "$temp_config_file_path"
    # Write the generated Hyprlock configuration to the temporary file.
    if ! _generate_hyprlock_config_content_string > "$temp_config_file_path"; then
        _exit_with_error "Failed to write configuration to temporary file '$temp_config_file_path'. Content generation failed, disk full, or file became unwritable." 20
    fi
    
    # Check if the temporary file has content.
    if ! [ -s "$temp_config_file_path" ]; then
         _exit_with_error "Temporary file '$temp_config_file_path' is empty after content generation. This indicates a critical problem with the generation process or immediate data loss." 21
    fi

    # --- Pre-move checks for the final target path ---
    if [ -e "$final_target_path" ] && [ ! -f "$final_target_path" ]; then # Target exists but is not a regular file
        _exit_with_error "Target path '$final_target_path' exists but is not a regular file (e.g., it is a directory). Cannot overwrite with a file." 22
    fi
    if [ -e "$final_target_path" ] && [ -f "$final_target_path" ] && [ ! -w "$final_target_path" ]; then # Target exists, is a file, but not writable
         _exit_with_error "Target file '$final_target_path' exists, is a regular file, but is not writable. Check permissions." 23
    fi

    # Atomically replace the final target file with the temporary file.
    # 'mv -T' (treat destination as a normal file) helps ensure this if the target is a symlink,
    # though its primary purpose here with a non-symlink target is atomicity on the same filesystem.
    printf "%s: INFO: Atomically replacing/creating %s\n" "$SCRIPT_NAME" "$final_target_path"
    if ! mv -T "$temp_config_file_path" "$final_target_path"; then
        _exit_with_error "Failed to move temporary file '$temp_config_file_path' to '$final_target_path'. The temporary file may still exist. Check permissions, disk space, or if the target is on a different filesystem that 'mv -T' cannot handle atomically." 24
    fi
    
    # Successfully moved, remove the trap for normal exit.
    trap - EXIT

    # Log completion (uses function from common.sh)
    finish_target_file_write "$final_target_path" "Hyprlock"
}

# Ensures the script's main operation is run only when executed directly, not when sourced.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _perform_main_operation "$@"
fi

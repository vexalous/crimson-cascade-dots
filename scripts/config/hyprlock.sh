#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3) )); then
    printf "FATAL: This script requires Bash version 4.3 or later for 'declare -gr' and robust variable checks.\n" >&2
    exit 2
fi

declare -gr SCRIPT_NAME="$(basename "$0")"
declare -gr SCRIPT_ABSOLUTE_PATH="$(readlink -m "${BASH_SOURCE[0]}")"

declare -gr REQUIRED_VARS=(
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
)

_exit_with_error() {
    local message="${1:-An unspecified critical error occurred}"
    local exit_code="${2:-1}"
    printf "%s: FATAL: %s (Exiting with code %d)\n" "$SCRIPT_NAME" "$message" "$exit_code" >&2
    exit "$exit_code"
}

_ensure_essential_commands_exist() {
    local cmd
    for cmd in "cat" "dirname" "mktemp" "mv" "printf" "date" "mkdir" "rm" "readlink"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            _exit_with_error "Essential command '$cmd' is not found in PATH. Please install it or correct your PATH." 3
        fi
    done
}

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
    cat << EOF
general {
    disable_loading_bar = true;
    hide_cursor = true;
    grace = 0;
    no_fade_in = false;
}

background {
    path = $WALLPAPER_FILE;
    color = $HL_NEAR_BLACK_RGBA;
}

input-field {
    monitor = ;
    size = 400, 55;
    outline_thickness = 3;
    dots_size = 0.28;
    dots_spacing = 0.28;
    dots_center = true;
    dots_rounding = -1;
    inner_color = $HL_DARK_GRAY_INPUT_BG;
    outer_color = $HL_CRIMSON_SOLID;
    font_color = $HL_TEXT_FIELD_FONT_COLOR;
    fade_on_empty = true;
    fade_timeout = 800;
    fade_alpha = 0.15;
    placeholder_text = <i>ENTER PASSWORD</i>;
    placeholder_color = $HL_DIM_GRAY_PLACEHOLDER;
    hide_input = false;
    rounding = 10;
    check_color = $HL_CRIMSON_SOLID;
    fail_color = $HL_DARK_RED_FAIL;
    fail_text = <b><span foreground="$HL_OFF_WHITE_TEXT" background="$HL_DARK_RED_FAIL" size="large"> ACCESS DENIED </span></b>;
    fail_transition = 400;
    position = 0, 50;
    halign = center;
    valign = center;
}

label {
    monitor = ;
    text = cmd[update:1000] echo \$(date +"%H:%M");
    color = $HL_OFF_WHITE_TEXT;
    font_size = 90;
    font_family = "JetBrainsMono Nerd Font ExtraBold";
    position = 0, -150;
    halign = center;
    valign = center;
    shadow_passes = 2;
    shadow_color = rgba(0,0,0,0.4);
    shadow_size = 3;
    shadow_boost = 1.1;
}

label {
    monitor = ;
    text = cmd[update:3600000] echo \$(date +"%m/%d/%y");
    color = $HL_LIGHT_GRAY_TEXT;
    font_size = 24;
    font_family = "JetBrainsMono Nerd Font";
    position = 0, -70;
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

    local final_target_path
    final_target_path="$(readlink -m "$HYPRLOCK_TARGET_FILE")"
    
    prepare_target_file_write "$final_target_path" "Hyprlock"

    local target_parent_directory
    target_parent_directory="$(dirname "$final_target_path")"

    if [ -z "$target_parent_directory" ]; then
        _exit_with_error "Could not determine parent directory from resolved path ('$final_target_path'). This should not happen if path resolution succeeded." 11
    fi

    if ! mkdir -p "$target_parent_directory"; then
        _exit_with_error "Failed to create or ensure parent directory structure exists for: '$target_parent_directory'." 12
    fi

    if ! [ -d "$target_parent_directory" ]; then
        _exit_with_error "Target parent directory path '$target_parent_directory' is not a directory after 'mkdir -p' attempt. This is unexpected." 13
    fi
    
    if ! [ -w "$target_parent_directory" ]; then
        _exit_with_error "Target parent directory '$target_parent_directory' is not writable. Check permissions." 14
    fi
    
    if ! [ -x "$target_parent_directory" ]; then
        _exit_with_error "Target parent directory '$target_parent_directory' is not searchable (execute permission missing). Cannot create files within." 15
    fi

    local temp_config_file_path=""
    if ! temp_config_file_path="$(mktemp "$target_parent_directory/hyprlock.conf.temp.XXXXXX")"; then
        _exit_with_error "mktemp failed to create a temporary file in '$target_parent_directory'. Check permissions, available inodes, and disk space." 16
    fi
    
    if [ -z "$temp_config_file_path" ]; then
        _safe_cleanup_temporary_file "$temp_config_file_path"
        _exit_with_error "mktemp succeeded but returned an empty file name. This is a critical system anomaly." 17
    fi
    if ! [ -f "$temp_config_file_path" ]; then
        _safe_cleanup_temporary_file "$temp_config_file_path"
        _exit_with_error "Temporary file '$temp_config_file_path' reported by mktemp does not exist or is not a regular file." 18
    fi
    if ! [ -w "$temp_config_file_path" ]; then
        _safe_cleanup_temporary_file "$temp_config_file_path"
        _exit_with_error "Temporary file '$temp_config_file_path' created by mktemp is not writable." 19
    fi

    trap '_safe_cleanup_temporary_file "$temp_config_file_path"' EXIT HUP INT QUIT PIPE TERM

    printf "%s: INFO: Generating content into temporary file: %s\n" "$SCRIPT_NAME" "$temp_config_file_path"
    if ! _generate_hyprlock_config_content_string > "$temp_config_file_path"; then
        _exit_with_error "Failed to write configuration to temporary file '$temp_config_file_path'. Content generation failed, disk full, or file became unwritable." 20
    fi
    
    if ! [ -s "$temp_config_file_path" ]; then
         _exit_with_error "Temporary file '$temp_config_file_path' is empty after content generation. This indicates a critical problem with the generation process or immediate data loss." 21
    fi

    if [ -e "$final_target_path" ] && [ ! -f "$final_target_path" ]; then
        _exit_with_error "Target path '$final_target_path' exists but is not a regular file (e.g., it is a directory). Cannot overwrite with a file." 22
    fi
    
    if [ -e "$final_target_path" ] && [ -f "$final_target_path" ] && [ ! -w "$final_target_path" ]; then
         _exit_with_error "Target file '$final_target_path' exists, is a regular file, but is not writable. Check permissions." 23
    fi

    printf "%s: INFO: Atomically replacing/creating %s\n" "$SCRIPT_NAME" "$final_target_path"
    if ! mv -T "$temp_config_file_path" "$final_target_path"; then
        _exit_with_error "Failed to move temporary file '$temp_config_file_path' to '$final_target_path'. The temporary file may still exist. Check permissions, disk space, or if the target is on a different filesystem that 'mv -T' cannot handle atomically." 24
    fi
    
    trap - EXIT

    finish_target_file_write "$final_target_path" "Hyprlock"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _perform_main_operation "$@"
fi

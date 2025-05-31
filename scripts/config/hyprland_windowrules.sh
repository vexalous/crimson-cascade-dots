#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../config_lib/common.sh"

export LC_ALL=C

readonly SCRIPT_BASENAME="${0##*/}"
readonly WINDOWRULES_CONFIG_FILENAME="windowrules.conf"
_TEMP_CONFIG_FILE_PATH=""

_log_message() {
    printf '%s: %s\n' "${SCRIPT_BASENAME}" "${1-}" >&2
}

_exit_with_error() {
    local error_message="$1"
    local exit_code="${2-1}"
    _log_message "FATAL ERROR: ${error_message}"
    exit "${exit_code}"
}

_perform_cleanup() {
    if [[ -n "${_TEMP_CONFIG_FILE_PATH:-}" && -f "${_TEMP_CONFIG_FILE_PATH}" ]]; then
        rm -f -- "${_TEMP_CONFIG_FILE_PATH}"
    fi
}

trap _perform_cleanup EXIT HUP INT QUIT PIPE TERM

_ensure_command_exists() {
    local cmd
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            _exit_with_error "Required command '${cmd}' is not installed or not in PATH."
        fi
    done
}

_ensure_command_exists realpath mktemp dirname mkdir cat mv chmod date printf

if [[ -z "${HOME:-}" || ! -d "${HOME}" ]]; then
    _exit_with_error "HOME environment variable is not set or does not point to a valid directory."
fi
readonly _CANONICAL_HOME_DIR="$(realpath -- "${HOME}")"

if [[ "${HYPR_CONF_TARGET_DIR+is_set}" && -z "${HYPR_CONF_TARGET_DIR}" ]]; then
    _exit_with_error "HYPR_CONF_TARGET_DIR environment variable is set but empty. Unset it or provide a valid path."
fi

readonly _EFFECTIVE_XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${_CANONICAL_HOME_DIR}/.config}"
readonly _DEFAULT_HYPRLAND_CONFIG_DIR="${_EFFECTIVE_XDG_CONFIG_HOME}/hypr"

_RAW_TARGET_CONFIG_DIR="${HYPR_CONF_TARGET_DIR:-${_DEFAULT_HYPRLAND_CONFIG_DIR}}"

_RESOLVED_TARGET_DIR_PATH_ATTEMPT="$(realpath -m -- "${_RAW_TARGET_CONFIG_DIR}")"
if [[ $? -ne 0 || -z "${_RESOLVED_TARGET_DIR_PATH_ATTEMPT}" ]]; then
     _exit_with_error "Failed to resolve target directory path: '${_RAW_TARGET_CONFIG_DIR}' using realpath."
fi
readonly _CANONICAL_TARGET_CONFIG_DIR="${_RESOLVED_TARGET_DIR_PATH_ATTEMPT}"


if ! [[ "${_CANONICAL_TARGET_CONFIG_DIR}" == "${_CANONICAL_HOME_DIR}" || "${_CANONICAL_TARGET_CONFIG_DIR}" == "${_CANONICAL_HOME_DIR}/"* ]]; then
    _exit_with_error "Security Violation: Target directory '${_CANONICAL_TARGET_CONFIG_DIR}' (derived from '${_RAW_TARGET_CONFIG_DIR}') is outside the user's home directory ('${_CANONICAL_HOME_DIR}'). Aborting operation."
fi

readonly _FINAL_CONFIG_FILE_PATH="${_CANONICAL_TARGET_CONFIG_DIR}/${WINDOWRULES_CONFIG_FILENAME}"

prepare_target_file_write "$_FINAL_CONFIG_FILE_PATH" "Hyprland Window Rules"

if ! mkdir -p -- "${_CANONICAL_TARGET_CONFIG_DIR}"; then
    _exit_with_error "Failed to create target directory: '${_CANONICAL_TARGET_CONFIG_DIR}'."
fi

if ! chmod 0700 -- "${_CANONICAL_TARGET_CONFIG_DIR}"; then
    _exit_with_error "Failed to set permissions (0700) on directory: '${_CANONICAL_TARGET_CONFIG_DIR}'. Verify ownership and existing permissions."
fi

_TEMP_CONFIG_FILE_PATH="$(mktemp "${_CANONICAL_TARGET_CONFIG_DIR}/${WINDOWRULES_CONFIG_FILENAME}.tmp.XXXXXX")"
if [[ $? -ne 0 ]]; then
    _exit_with_error "Failed to create temporary configuration file in '${_CANONICAL_TARGET_CONFIG_DIR}'."
fi


if ! chmod 0600 -- "${_TEMP_CONFIG_FILE_PATH}"; then
    _exit_with_error "Failed to set permissions (0600) on temporary file: '${_TEMP_CONFIG_FILE_PATH}'."
fi

_write_hyprland_config_to_file() {
    local target_output_file="$1"
    cat << EOF > "${target_output_file}"
windowrulev2 = workspace special:scratchpad silent, title:^(AlacrittyScratchpad)$
windowrulev2 = float, title:^(AlacrittyScratchpad)$
windowrulev2 = size 60% 60%, title:^(AlacrittyScratchpad)$
windowrulev2 = center, title:^(AlacrittyScratchpad)$
windowrulev2 = float,class:^(pavucontrol)$
windowrulev2 = float,class:^(blueman-manager)$
windowrulev2 = float,class:^(nm-connection-editor)$
windowrulev2 = float,class:^(org.kde.polkit-kde-authentication-agent-1)$
windowrulev2 = float,title:^(Open File)(.*)$
windowrulev2 = float,title:^(Select File)(.*)$
windowrulev2 = float,title:^(Choose wallpaper)(.*)$
windowrulev2 = float,title:^(Open Folder)(.*)$
windowrulev2 = float,title:^(Save As)(.*)$
windowrulev2 = float,title:^(File Upload)(.*)$
windowrulev2 = float,title:^(Volume Control)$
windowrulev2 = center,floating:1
windowrulev2 = opacity 0.94 0.88,class:^(Alacritty)$,title:^((?!AlacrittyScratchpad).)*$
layerrule = blur, mako
layerrule = ignorezero, mako
EOF
}

if ! _write_hyprland_config_to_file "${_TEMP_CONFIG_FILE_PATH}"; then
    _exit_with_error "Failed to write configuration content to temporary file: '${_TEMP_CONFIG_FILE_PATH}'."
fi

if ! mv -f -- "${_TEMP_CONFIG_FILE_PATH}" "${_FINAL_CONFIG_FILE_PATH}"; then
    _exit_with_error "Failed to atomically move temporary file '${_TEMP_CONFIG_FILE_PATH}' to final destination '${_FINAL_CONFIG_FILE_PATH}'."
fi
_TEMP_CONFIG_FILE_PATH=""

if ! chmod 0600 -- "${_FINAL_CONFIG_FILE_PATH}"; then
    _exit_with_error "Failed to set permissions (0600) on the final configuration file: '${_FINAL_CONFIG_FILE_PATH}'. Verify ownership."
fi

finish_target_file_write "$_FINAL_CONFIG_FILE_PATH" "Hyprland Window Rules"
exit 0

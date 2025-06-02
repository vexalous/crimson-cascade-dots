#!/usr/bin/env bash

# Strict mode: exit on error, unset variable, or pipe failure
set -o errexit -o nounset -o pipefail
# Set Internal Field Separator to only newline and tab
IFS=$'\n\t'

# --- Script Identity & Constants ---
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
LOCK_FILE="/tmp/${SCRIPT_NAME}.lock"
readonly LOCK_FILE
DEFAULT_SCRIPT_LOG_FILE="/tmp/${SCRIPT_NAME}.$(date +%Y%m%d).log"
readonly DEFAULT_SCRIPT_LOG_FILE
readonly SCRIPT_VERSION="2.0.0-UNCONDITIONALLY-FORCEFUL"

# --- Configuration Constants ---
declare -xr BACKUP_DIR_BASE="${HOME}/config_backups_crimson_cascade"
declare -xr GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
declare -xr REPO_NAME="crimson-cascade-dots"

readonly CONFIG_TARGET_DIR="${HOME}/.config"
readonly DEFAULT_WALLPAPER_FILE="crimson_black_wallpaper.png"
readonly USER_HYPR_SCRIPTS_DIR="${CONFIG_TARGET_DIR}/hypr/scripts"
readonly WALLPAPER_CONFIG_DIR="${CONFIG_TARGET_DIR}/hypr/wallpaper"

# --- Global Variables (State & Configuration) ---
DOTFILES_SOURCE_DIR=""
TEMP_CLONE_DIR=""

DEBUG_MODE=false
SKIP_BACKUPS=false
SKIP_SERVICES=false
SKIP_HYPR_ENV=false
SCRIPT_LOG_FILE="${DEFAULT_SCRIPT_LOG_FILE}"
OVERALL_SCRIPT_STATUS=0

# --- Logging Framework (for high-level steps) ---
log_message() {
    local type="$1" message="$2" timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[${type}] [${timestamp}] ${message}"
    printf '%s\n' "${formatted_message}" >> "${SCRIPT_LOG_FILE}"
    case "${type}" in
        ERROR|CRITICAL) printf '%s\n' "${formatted_message}" >&2 ;;
        WARNING) printf '%s\n' "${formatted_message}" >&2 ;;
        INFO) printf '%s\n' "${formatted_message}" ;;
        DEBUG) [[ "${DEBUG_MODE}" == "true" ]] && printf '%s\n' "${formatted_message}" ;;
    esac
}
error_msg() { log_message "ERROR" "$*"; }
warning_msg() { log_message "WARNING" "$*"; }
info_msg() { log_message "INFO" "$*"; }
debug_msg() { log_message "DEBUG" "$*"; }
critical_exit() { log_message "CRITICAL" "$*"; OVERALL_SCRIPT_STATUS=1; exit 1; }

# --- Lockfile Management ---
acquire_lock() {
    (set -o noclobber; echo "$$" > "${LOCK_FILE}") 2>/dev/null || {
        local locked_pid; locked_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "unknown")
        error_msg "${SCRIPT_NAME} already running (PID: ${locked_pid}) or lockfile stale."
        if [[ "${locked_pid}" != "unknown" ]] && ! ps -p "${locked_pid}" > /dev/null; then
            warning_msg "Stale lock (PID ${locked_pid} not running). Removing: ${LOCK_FILE}"
            rm -f "${LOCK_FILE}" && info_msg "Stale lock removed. Try again."
        fi
        return 1
    }
    debug_msg "Lock acquired: ${LOCK_FILE}"; return 0
}
release_lock() { rm -f "${LOCK_FILE}" && debug_msg "Lock released: ${LOCK_FILE}"; }

# --- Library Sourcing ---
source_libraries() {
    info_msg "Sourcing library scripts from '${SCRIPT_DIR}/scripts/setup_lib'..."
    local lib_dir="${SCRIPT_DIR}/scripts/setup_lib"
    for lib in ui.sh dependencies.sh backup.sh fs_ops.sh git_ops.sh; do # fs_ops may still be used by cleanup
        local lib_path="${lib_dir}/${lib}"
        if [[ ! -f "${lib_path}" ]]; then critical_exit "Lib not found: ${lib_path}"; fi
        # shellcheck source=/dev/null
        source "${lib_path}"
        debug_msg "Sourced library: ${lib_path}"
    done
    info_msg "All library scripts sourced."
}

# --- Core Function Implementations ---

perform_backups() {
    if [[ "${SKIP_BACKUPS}" == "true" ]]; then info_msg "Skipping backups."; return 0; fi
    info_msg "Starting backup process..."
    handle_backup_process "hypr" "waybar" "alacritty" "rofi" || {
        warning_msg "Backup process encountered issues. Continuing."
        return 1 # Non-critical
    }
    info_msg "Backup process completed."; return 0
}

setup_target_directories() {
    info_msg "Ensuring base target configuration directory exists: ${CONFIG_TARGET_DIR}..."
    # This is the ONLY mkdir the main script does before copy_configurations
    mkdir -p "${CONFIG_TARGET_DIR}"
    info_msg "Base target directory ${CONFIG_TARGET_DIR} ensured (or already existed)."
    return 0
}

# --- UNCONDITIONALLY FORCEFUL FILE/DIRECTORY OPERATIONS ---

copy_configurations() {
    info_msg ">>> UNCONDITIONALLY Force-Copying Configurations from ${DOTFILES_SOURCE_DIR} <<<"
    info_msg ">>> This section has minimal checks. `set -o errexit` is active. <<<"

    # Hyprland
    info_msg "Force-processing Hyprland..."
    rm -rf "${CONFIG_TARGET_DIR}/hypr"
    cp -rL "${DOTFILES_SOURCE_DIR}/hypr" "${CONFIG_TARGET_DIR}/" # cp SRC_DIR DEST_PARENT_DIR

    # Waybar
    info_msg "Force-processing Waybar..."
    rm -rf "${CONFIG_TARGET_DIR}/waybar"
    cp -rL "${DOTFILES_SOURCE_DIR}/waybar" "${CONFIG_TARGET_DIR}/"

    # Ensure specific sub-directories for Hyprland files exist AFTER main component copy
    info_msg "Force-creating Hyprland sub-directories..."
    mkdir -p "${USER_HYPR_SCRIPTS_DIR}"  # e.g., ~/.config/hypr/scripts
    mkdir -p "${WALLPAPER_CONFIG_DIR}" # e.g., ~/.config/hypr/wallpaper

    # Wallpaper
    info_msg "Force-copying wallpaper..."
    cp -f "${DOTFILES_SOURCE_DIR}/${DEFAULT_WALLPAPER_FILE}" \
          "${WALLPAPER_CONFIG_DIR}/${DEFAULT_WALLPAPER_FILE}"

    # Hyprpaper script
    info_msg "Force-copying Hyprpaper script..."
    cp -f "${DOTFILES_SOURCE_DIR}/scripts/config/hyprpaper.sh" \
          "${USER_HYPR_SCRIPTS_DIR}/hyprpaper.sh"
    chmod +x "${USER_HYPR_SCRIPTS_DIR}/hyprpaper.sh"
    
    # Alacritty (config file only)
    info_msg "Force-processing Alacritty config file..."
    mkdir -p "${CONFIG_TARGET_DIR}/alacritty" 
    cp -f "${DOTFILES_SOURCE_DIR}/alacritty/alacritty.toml" \
          "${CONFIG_TARGET_DIR}/alacritty/alacritty.toml"
    
    # Example for Rofi (if a full component)
    # info_msg "Force-processing Rofi component..."
    # rm -rf "${CONFIG_TARGET_DIR}/rofi"
    # cp -rL "${DOTFILES_SOURCE_DIR}/rofi" "${CONFIG_TARGET_DIR}/"

    # Example for Rofi (if a single config file)
    # info_msg "Force-processing Rofi config file..."
    # mkdir -p "${CONFIG_TARGET_DIR}/rofi"
    # cp -f "${DOTFILES_SOURCE_DIR}/rofi/config.rasi" \
    #       "${CONFIG_TARGET_DIR}/rofi/config.rasi"

    info_msg ">>> UNCONDITIONALLY Force-Copying Configurations COMPLETED <<<"
    return 0 # If any cp/rm failed, errexit would have stopped the script.
}

update_hyprland_env_config() {
    if [[ "${SKIP_HYPR_ENV}" == "true" ]]; then info_msg "Skipping Hyprland env.conf update."; return 0; fi
    
    local target_file="${CONFIG_TARGET_DIR}/hypr/conf/env.conf"
    info_msg "Checking/Updating Hyprland env config: ${target_file}"

    mkdir -p "$(dirname "${target_file}")"; touch "${target_file}"

    local desired_scripts_line="env = HYPR_SCRIPTS_DIR,${USER_HYPR_SCRIPTS_DIR}"
    local desired_config_line="env = CONFIG_TARGET_DIR,${CONFIG_TARGET_DIR}"
    
    local temp_file; temp_file=$(mktemp --tmpdir "${SCRIPT_NAME}_envconf.XXXXXX")
    
    local original_content; original_content=$(<"${target_file}")

    grep -Ev "^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*(HYPR_SCRIPTS_DIR|CONFIG_TARGET_DIR)," "${target_file}" > "${temp_file}" || true 

    if [[ -s "${temp_file}" ]] && [[ "$(tail -c1 "${temp_file}")" != $'\n' ]]; then
        echo "" >> "${temp_file}"
    fi
    echo "${desired_scripts_line}" >> "${temp_file}"
    echo "${desired_config_line}" >> "${temp_file}"

    local new_content; new_content=$(<"${temp_file}")

    if [[ "${original_content}" == "${new_content}" ]]; then
        info_msg "${target_file} already correct. No changes."
        rm -f "${temp_file}"
        return 0
    fi

    local backup_file="${target_file}.bak.$(date +%Y%m%d%H%M%S)"
    cp "${target_file}" "${backup_file}" || warning_msg "Failed to backup ${target_file}"
    info_msg "Backed up ${target_file} to ${backup_file}"
    
    mv "${temp_file}" "${target_file}"
    info_msg "${target_file} updated successfully."
    return 0
}

configure_hyprpaper_script() {
    info_msg "Configuring local hyprpaper script..."
    local script_path="${USER_HYPR_SCRIPTS_DIR}/hyprpaper.sh"

    if [[ ! -f "${script_path}" ]]; then warning_msg "Hyprpaper script not found: ${script_path}"; return 1; fi # Keep this check
    chmod +x "${script_path}"

    info_msg "Executing hyprpaper config script: ${script_path}"
    export CONFIG_TARGET_DIR 
    if "${script_path}"; then
        info_msg "Hyprpaper script executed successfully."
        return 0
    else
        warning_msg "Hyprpaper script failed (status $?)."
        return 1
    fi
}

manage_daemon() {
    local process_name="$1" command_to_start="$2"
    local -r sigterm_timeout=3
    local daemon_status=0

    info_msg "Managing daemon: ${process_name}..."
    if ! command -v "${process_name}" >/dev/null 2>&1; then
        warning_msg "Cmd '${process_name}' not found. Skipping."
        return 1
    fi

    if pgrep -x -u "$(id -u)" "${process_name}" >/dev/null; then
        info_msg "Stopping existing ${process_name}..."
        pkill -x -SIGTERM -u "$(id -u)" "${process_name}"
        local count=0
        while pgrep -x -u "$(id -u)" "${process_name}" >/dev/null && (( count < sigterm_timeout )); do
            sleep 1; ((count++))
        done
        if pgrep -x -u "$(id -u)" "${process_name}" >/dev/null; then
            warning_msg "${process_name} didn't stop with SIGTERM. Sending SIGKILL."
            pkill -x -SIGKILL -u "$(id -u)" "${process_name}"
            sleep 0.5
        fi
        info_msg "${process_name} stopped."
    else
        info_msg "No existing ${process_name} process found."
    fi

    local log_file; log_file=$(mktemp --tmpdir "${process_name}_${SCRIPT_NAME}.XXXXXX.log")
    info_msg "Starting ${process_name}. Log: ${log_file}"
    if nohup "${command_to_start}" >"${log_file}" 2>&1 & then
        disown "$!"
        sleep 0.5 
        if pgrep -x -u "$(id -u)" "${process_name}" >/dev/null; then
            info_msg "${process_name} started successfully."
        else
            error_msg "${process_name} launched but seems to have exited. Check log: ${log_file}"
            daemon_status=1
        fi
    else
        error_msg "Failed to execute 'nohup ${command_to_start}'. Check log: ${log_file}"
        daemon_status=1
    fi
    return ${daemon_status}
}

# --- Cleanup ---
cleanup() {
    local exit_status=$?
    info_msg "Initiating cleanup (exit status: ${exit_status})..."
    if [[ -n "${TEMP_CLONE_DIR}" && -d "${TEMP_CLONE_DIR}" ]]; then
        cleanup_temp_dir "${TEMP_CLONE_DIR}" || warning_msg "Failed to clean temp dir: ${TEMP_CLONE_DIR}" # from fs_ops.sh
    fi
    release_lock
    if [[ "${OVERALL_SCRIPT_STATUS}" -ne 0 || "${exit_status}" -ne 0 ]]; then
        warning_msg "Script finished with errors. OVERALL_SCRIPT_STATUS=${OVERALL_SCRIPT_STATUS}, exit_status=${exit_status}."
    else
        info_msg "Script finished successfully."
    fi
    info_msg "Log file: ${SCRIPT_LOG_FILE}"
}

# --- Help Message ---
print_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] (Version: ${SCRIPT_VERSION})
UNCONDITIONALLY AND FORCEFULLY sets up Crimson Cascade Dotfiles, 
overwriting existing configs. USE WITH EXTREME CAUTION.

Options:
  --skip-backups         Skip configuration backups.
  --skip-services        Skip restarting waybar/hyprpaper.
  --skip-hypr-env        Skip updating Hyprland's env.conf.
  --debug                Enable verbose debug messages.
  --log-file <path>      Custom log file path. (Default: ${DEFAULT_SCRIPT_LOG_FILE})
  --version              Display version and exit.
  -h, --help             Display this help message and exit.
EOF
}

# --- Main Script Orchestration ---
main() {
    if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
      critical_exit "Bash 4.4+ required."
    fi

    if ! command -v getopt >/dev/null; then
        critical_exit "getopt command not found. Please install it (usually part of util-linux)."
    fi
    if ! getopt -o "" --long "test-option" -n "getopt-test" -- --test-option > /dev/null 2>&1; then
        local getopt_version_output
        getopt_version_output=$(getopt --version 2>&1 || echo "Version unknown") 
        error_msg "getopt found, but it may not support long options correctly or is not behaving as expected."
        error_msg "getopt version/output: ${getopt_version_output}"
        critical_exit "A getopt implementation that supports standard long options is required."
    else
        debug_msg "getopt check passed (using $(getopt --version 2>/dev/null || echo "util-linux getopt"))."
    fi

    local short_opts="h"
    local long_opts="skip-backups,skip-services,skip-hypr-env,debug,log-file:,help,version"
    local parsed_opts
    if ! parsed_opts=$(getopt -o "${short_opts}" --long "${long_opts}" -n "${SCRIPT_NAME// /_}" -- "$@"); then
        print_help >&2; exit 1
    fi
    eval set -- "${parsed_opts}"

    while true; do
        case "$1" in
            --skip-backups) SKIP_BACKUPS=true; shift ;;
            --skip-services) SKIP_SERVICES=true; shift ;;
            --skip-hypr-env) SKIP_HYPR_ENV=true; shift ;;
            --debug) DEBUG_MODE=true; shift ;;
            --log-file) SCRIPT_LOG_FILE="$2"; shift 2 ;;
            --version) printf '%s version %s\n' "${SCRIPT_NAME}" "${SCRIPT_VERSION}"; exit 0 ;;
            -h|--help) print_help; exit 0 ;;
            --) shift; break ;;
            *) critical_exit "Internal arg parsing error!" ;;
        esac
    done

    mkdir -p "$(dirname "${SCRIPT_LOG_FILE}")"; touch "${SCRIPT_LOG_FILE}"

    info_msg "--- ${SCRIPT_NAME} v${SCRIPT_VERSION} execution started ---"
    [[ "${DEBUG_MODE}" == "true" ]] && info_msg "DEBUG mode enabled."

    trap cleanup EXIT HUP INT QUIT TERM
    acquire_lock || critical_exit "Failed to acquire script lock."

    initialize_script || { OVERALL_SCRIPT_STATUS=1; critical_exit "Initialization failed."; }
    
    # For process_configurations, if it returns non-zero (critical copy failure), set OVERALL_SCRIPT_STATUS
    process_configurations || OVERALL_SCRIPT_STATUS=1
    
    if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then # Only manage services if configs were OK
        manage_services_phase || OVERALL_SCRIPT_STATUS=1 # Service failure is also an overall failure
    else
        warning_msg "Skipping service management due to prior critical errors in configuration."
    fi
    
    exit "${OVERALL_SCRIPT_STATUS}"
}

initialize_script() {
    info_msg "Phase: Initializing Script..."
    source_libraries 
    print_header   # From ui.sh

    local source_dirs_array=()
    mapfile -d $'\0' -t source_dirs_array < <(determine_source_dir) # From git_ops.sh
    
    DOTFILES_SOURCE_DIR="${source_dirs_array[0]}"
    TEMP_CLONE_DIR="${source_dirs_array[1]}"

    [[ -n "${DOTFILES_SOURCE_DIR}" ]] || critical_exit "Dotfiles source dir is empty (from determine_source_dir)."
    info_msg "Dotfiles source: ${DOTFILES_SOURCE_DIR}"
    [[ -n "${TEMP_CLONE_DIR}" ]] && info_msg "Temp clone dir: ${TEMP_CLONE_DIR}"
    
    verify_core_dependencies # From dependencies.sh
    info_msg "Initialization phase completed."; return 0
}

process_configurations() {
    info_msg "Phase: Processing Configurations..."
    
    perform_backups # Backup failure is non-critical, does not return error code to stop this phase

    setup_target_directories # This is critical, will exit if fails due to errexit

    # copy_configurations is critical. If it fails (e.g., source DOTFILES_SOURCE_DIR is wrong, cp fails),
    # errexit will stop the script. If it completes, it returns 0.
    copy_configurations

    # These are run if copy_configurations succeeded. Their failure will set OVERALL_SCRIPT_STATUS via main loop logic.
    update_hyprland_env_config || return 1 
    configure_hyprpaper_script || return 1

    info_msg "Configuration processing phase completed."; return 0
}

manage_services_phase() {
    if [[ "${SKIP_SERVICES}" == "true" ]]; then info_msg "Skipping service management."; return 0; fi
    info_msg "Phase: Managing Services..."
    local any_service_failed=false

    manage_daemon "waybar" "waybar" || any_service_failed=true
    manage_daemon "hyprpaper" "hyprpaper" || any_service_failed=true
    
    if [[ "$any_service_failed" == true ]]; then
        warning_msg "Service management phase had issues with one or more daemons."
        return 1 # Indicate this phase had problems
    fi
    
    info_msg "Service management phase completed successfully."
    info_msg ""
    info_msg "--------------------------------------------------------------------"
    info_msg "Services (re)started. LOG OUT and LOG BACK IN for all changes."
    info_msg "--------------------------------------------------------------------"
    return 0
}

# --- Script Execution Guard ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

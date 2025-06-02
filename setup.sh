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
readonly SCRIPT_VERSION="1.0.2-forceful-write"

# --- Configuration Constants ---
declare -xr BACKUP_DIR_BASE="${HOME}/config_backups_crimson_cascade"
declare -xr GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
declare -xr REPO_NAME="crimson-cascade-dots"

readonly CONFIG_TARGET_DIR="${HOME}/.config"
readonly DEFAULT_WALLPAPER_FILE="crimson_black_wallpaper.png" # Assumed to be at the root of your dotfiles repo
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

# --- Logging Framework ---
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

# --- Library Sourcing (fs_ops.sh role is diminished for core copy operations) ---
source_libraries() {
    info_msg "Sourcing library scripts from '${SCRIPT_DIR}/scripts/setup_lib'..."
    local lib_dir="${SCRIPT_DIR}/scripts/setup_lib"
    local SOURCED_SUCCESS=true
    for lib in ui.sh dependencies.sh backup.sh fs_ops.sh git_ops.sh; do
        local lib_path="${lib_dir}/${lib}"
        if [[ ! -f "${lib_path}" ]]; then critical_exit "Lib not found: ${lib_path}"; fi
        # shellcheck source=/dev/null
        source "${lib_path}" || { error_msg "Failed to source ${lib_path}"; SOURCED_SUCCESS=false; }
        debug_msg "Sourced library: ${lib_path}"
    done
    [[ "${SOURCED_SUCCESS}" == "true" ]] || critical_exit "One or more libraries failed to source."
    info_msg "All library scripts sourced."
}

# --- Core Function Implementations ---

perform_backups() {
    if [[ "${SKIP_BACKUPS}" == "true" ]]; then info_msg "Skipping backups."; return 0; fi
    info_msg "Starting backup process..."
    # handle_backup_process is from backup.sh
    handle_backup_process "hypr" "waybar" "alacritty" "rofi" || {
        warning_msg "Backup process encountered issues. Continuing."
        return 1
    }
    info_msg "Backup process completed."; return 0
}

# SIMPLIFIED setup_target_directories: Only ensures the main ~/.config exists.
# Specific subdirs are handled forcefully by copy_configurations.
setup_target_directories() {
    info_msg "Ensuring base target configuration directory exists: ${CONFIG_TARGET_DIR}..."
    if mkdir -p "${CONFIG_TARGET_DIR}"; then
        info_msg "Base target directory ${CONFIG_TARGET_DIR} ensured."
        return 0
    else
        error_msg "CRITICAL: Failed to create base target directory ${CONFIG_TARGET_DIR}."
        return 1 # This will cause script to halt if it fails early
    fi
}

# --- FORCEFUL FILE/DIRECTORY COPY FUNCTIONS (INTERNAL TO THIS SCRIPT) ---

overwrite_component_dir_forceful() {
    local source_component_path="$1" # Full path to source component dir, e.g., ${DOTFILES_SOURCE_DIR}/hypr
    local dest_component_path="$2"   # Full path to dest component dir, e.g., ${CONFIG_TARGET_DIR}/hypr
    local display_name="$3"

    info_msg "FORCEFULLY OVERWRITING component ${display_name}: '${source_component_path}' -> '${dest_component_path}'"

    if [[ ! -d "${source_component_path}" ]]; then
        error_msg "SOURCE DIR NOT FOUND for ${display_name}: ${source_component_path}. Skipping."
        return 1
    fi

    local parent_dest_dir; parent_dest_dir=$(dirname "${dest_component_path}")
    mkdir -p "${parent_dest_dir}" || { error_msg "Failed to create parent dir '${parent_dest_dir}'."; return 1; }
    
    if [[ -e "${dest_component_path}" ]]; then
        info_msg "Removing existing target: '${dest_component_path}'"
        rm -rf "${dest_component_path}" || { error_msg "Failed to remove '${dest_component_path}'."; return 1; }
    fi

    # Copy source component (e.g. .../dots/hypr) INTO parent of dest (e.g. .../.config/)
    # This creates .../.config/hypr
    cp -rL "${source_component_path}" "${parent_dest_dir}/" || { error_msg "Failed to copy ${display_name}."; return 1; }
    
    info_msg "${display_name} component FORCEFULLY OVERWRITTEN."
    return 0
}

copy_single_file_forceful() {
    local source_file_path="$1" # Full path to source file
    local dest_file_path="$2"   # Full path to destination file
    local display_name="$3"

    info_msg "FORCEFULLY copying file ${display_name}: '${source_file_path}' -> '${dest_file_path}'"

    if [[ ! -f "${source_file_path}" ]]; then
        error_msg "SOURCE FILE NOT FOUND for ${display_name}: ${source_file_path}. Skipping."
        return 1
    fi

    local dest_dir; dest_dir=$(dirname "${dest_file_path}")
    mkdir -p "${dest_dir}" || { error_msg "Failed to create dest dir '${dest_dir}'."; return 1; }

    cp -f "${source_file_path}" "${dest_file_path}" || { error_msg "Failed to copy ${display_name}."; return 1; }
    
    # Make scripts executable
    if [[ "${dest_file_path}" == *scripts/*.sh || "${dest_file_path}" == *.sh ]]; then
        chmod +x "${dest_file_path}" || warning_msg "Failed to chmod +x ${dest_file_path}"
    fi
    info_msg "${display_name} file FORCEFULLY copied."
    return 0
}

copy_configurations() {
    info_msg "FORCEFULLY Copying configuration files from ${DOTFILES_SOURCE_DIR}..."
    local all_ops_ok=true
    
    # --- Component Directories (Full Overwrite) ---
    overwrite_component_dir_forceful \
        "${DOTFILES_SOURCE_DIR}/hypr" \
        "${CONFIG_TARGET_DIR}/hypr" \
        "Hyprland" || all_ops_ok=false

    overwrite_component_dir_forceful \
        "${DOTFILES_SOURCE_DIR}/waybar" \
        "${CONFIG_TARGET_DIR}/waybar" \
        "Waybar" || all_ops_ok=false

    # --- Explicit Directory Creation for specific sub-targets AFTER component overwrite ---
    # This is CRITICAL if your source ${DOTFILES_SOURCE_DIR}/hypr does NOT contain these subdirs.
    info_msg "Forcefully ensuring specific sub-directories exist post-component-overwrite..."
    
    # These use the global constants for user scripts and wallpaper target
    mkdir -p "${USER_HYPR_SCRIPTS_DIR}" || { error_msg "CRIT: Failed to create ${USER_HYPR_SCRIPTS_DIR}"; all_ops_ok=false; }
    info_msg "Forcefully ensured directory: ${USER_HYPR_SCRIPTS_DIR}"
    
    mkdir -p "${WALLPAPER_CONFIG_DIR}" || { error_msg "CRIT: Failed to create ${WALLPAPER_CONFIG_DIR}"; all_ops_ok=false; }
    info_msg "Forcefully ensured directory: ${WALLPAPER_CONFIG_DIR}"

    # --- Single Files ---
    # Wallpaper (source is assumed to be at the root of DOTFILES_SOURCE_DIR)
    copy_single_file_forceful \
        "${DOTFILES_SOURCE_DIR}/${DEFAULT_WALLPAPER_FILE}" \
        "${WALLPAPER_CONFIG_DIR}/${DEFAULT_WALLPAPER_FILE}" \
        "Default wallpaper" || all_ops_ok=false

    # Hyprpaper script (source is DOTFILES_SOURCE_DIR/scripts/config/hyprpaper.sh)
    copy_single_file_forceful \
        "${DOTFILES_SOURCE_DIR}/scripts/config/hyprpaper.sh" \
        "${USER_HYPR_SCRIPTS_DIR}/hyprpaper.sh" \
        "Hyprpaper script" || all_ops_ok=false
    
    # Alacritty (assuming only alacritty.toml, and 'alacritty' is not a full component dir in your dots)
    local target_alacritty_dir="${CONFIG_TARGET_DIR}/alacritty"
    mkdir -p "${target_alacritty_dir}" || { error_msg "CRIT: Failed to create ${target_alacritty_dir}"; all_ops_ok=false; }
    info_msg "Forcefully ensured directory: ${target_alacritty_dir}"
    
    # Only attempt copy if directory was ensured (or already existed)
    if [[ "${all_ops_ok}" == true || -d "${target_alacritty_dir}" ]]; then
        copy_single_file_forceful \
            "${DOTFILES_SOURCE_DIR}/alacritty/alacritty.toml" \
            "${target_alacritty_dir}/alacritty.toml" \
            "Alacritty configuration" || all_ops_ok=false
    fi
    
    # Add other components/files here using overwrite_component_dir_forceful or copy_single_file_forceful
    # Example for Rofi if it's a full component in your dotfiles:
    # overwrite_component_dir_forceful \
    #     "${DOTFILES_SOURCE_DIR}/rofi" \
    #     "${CONFIG_TARGET_DIR}/rofi" \
    #     "Rofi" || all_ops_ok=false
    # Example for Rofi if it's just a single file:
    # local target_rofi_dir="${CONFIG_TARGET_DIR}/rofi"
    # mkdir -p "${target_rofi_dir}" || { error_msg "CRIT: Failed to create ${target_rofi_dir}"; all_ops_ok=false; }
    # info_msg "Forcefully ensured directory: ${target_rofi_dir}"
    # if [[ "${all_ops_ok}" == true || -d "${target_rofi_dir}" ]]; then
    #    copy_single_file_forceful \
    #        "${DOTFILES_SOURCE_DIR}/rofi/config.rasi" \
    #        "${target_rofi_dir}/config.rasi" \
    #        "Rofi config" || all_ops_ok=false
    # fi

    [[ "${all_ops_ok}" == true ]] || return 1
    info_msg "Configuration files FORCEFUL copy process completed."
    return 0
}

update_hyprland_env_config() {
    # This function seems mostly fine, let's keep its logic but ensure robustness
    if [[ "${SKIP_HYPR_ENV}" == "true" ]]; then info_msg "Skipping Hyprland env.conf update."; return 0; fi
    
    local target_file="${CONFIG_TARGET_DIR}/hypr/conf/env.conf"
    info_msg "Checking/Updating Hyprland env config: ${target_file}"

    mkdir -p "$(dirname "${target_file}")" || { error_msg "Failed to create dir for env.conf"; return 1; }
    touch "${target_file}" || { error_msg "Failed to touch env.conf"; return 1; } # Ensure it exists

    local desired_scripts_line="env = HYPR_SCRIPTS_DIR,${USER_HYPR_SCRIPTS_DIR}"
    local desired_config_line="env = CONFIG_TARGET_DIR,${CONFIG_TARGET_DIR}"
    
    local temp_file; temp_file=$(mktemp --tmpdir "${SCRIPT_NAME}_envconf.XXXXXX") || { error_msg "mktemp failed"; return 1; }
    
    local original_content; original_content=$(<"${target_file}")

    # Filter out old managed lines
    grep -Ev "^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*(HYPR_SCRIPTS_DIR|CONFIG_TARGET_DIR)," "${target_file}" > "${temp_file}" || true # Allow no match

    # Append desired lines, ensuring newline if temp_file is not empty and lacks one
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
    cp "${target_file}" "${backup_file}" || { warning_msg "Failed to backup ${target_file}"; }
    info_msg "Backed up ${target_file} to ${backup_file}"
    
    mv "${temp_file}" "${target_file}" || { error_msg "Failed to update ${target_file}"; rm -f "${temp_file}"; return 1; }
    info_msg "${target_file} updated successfully."
    return 0
}

configure_hyprpaper_script() {
    info_msg "Configuring local hyprpaper script..."
    local script_path="${USER_HYPR_SCRIPTS_DIR}/hyprpaper.sh"

    if [[ ! -f "${script_path}" ]]; then warning_msg "Hyprpaper script not found: ${script_path}"; return 1; fi
    chmod +x "${script_path}" || { error_msg "Failed to chmod +x ${script_path}"; return 1; }

    info_msg "Executing hyprpaper config script: ${script_path}"
    export CONFIG_TARGET_DIR # Ensure available to sub-script
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
        sleep 0.5 # Give it a moment to start or fail
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
        # cleanup_temp_dir is from fs_ops.sh
        cleanup_temp_dir "${TEMP_CLONE_DIR}" || warning_msg "Failed to clean temp dir: ${TEMP_CLONE_DIR}"
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
Forcefully sets up Crimson Cascade Dotfiles, overwriting existing configs.

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
    command -v getopt >/dev/null && getopt -T >/dev/null 2>&1 || critical_exit "GNU getopt required."

    local short_opts="h"
    local long_opts="skip-backups,skip-services,skip-hypr-env,debug,log-file:,help,version"
    local parsed_opts
    parsed_opts=$(getopt -o "${short_opts}" --long "${long_opts}" -n "${SCRIPT_NAME}" -- "$@") || { print_help >&2; exit 1; }
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

    mkdir -p "$(dirname "${SCRIPT_LOG_FILE}")" || critical_exit "Cannot create log dir."
    touch "${SCRIPT_LOG_FILE}" || critical_exit "Cannot create/update log file."

    info_msg "--- ${SCRIPT_NAME} v${SCRIPT_VERSION} execution started ---"
    [[ "${DEBUG_MODE}" == "true" ]] && info_msg "DEBUG mode enabled."

    trap cleanup EXIT HUP INT QUIT TERM
    acquire_lock || critical_exit "Failed to acquire script lock."

    # Phase 1: Initialization (determine source, source libs)
    initialize_script || { OVERALL_SCRIPT_STATUS=1; critical_exit "Initialization failed."; }
    
    # Phase 2: Configuration (backup, copy, env update)
    process_configurations || OVERALL_SCRIPT_STATUS=1
    
    # Phase 3: Services (only if configs were okay)
    if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
        manage_services_phase || OVERALL_SCRIPT_STATUS=1
    else
        warning_msg "Skipping service management due to prior errors."
    fi
    
    # Exit status is determined by OVERALL_SCRIPT_STATUS
    # The cleanup trap will provide the final log messages.
    exit "${OVERALL_SCRIPT_STATUS}"
}

initialize_script() {
    info_msg "Phase: Initializing Script..."
    source_libraries # Sources ui.sh, dependencies.sh, git_ops.sh etc.
    print_header   # From ui.sh

    local source_dirs_array=()
    # determine_source_dir is from git_ops.sh
    mapfile -d $'\0' -t source_dirs_array < <(determine_source_dir) || critical_exit "determine_source_dir failed."
    
    [[ "${#source_dirs_array[@]}" -eq 2 ]] || critical_exit "determine_source_dir: unexpected output count."
    DOTFILES_SOURCE_DIR="${source_dirs_array[0]}"
    TEMP_CLONE_DIR="${source_dirs_array[1]}"

    [[ -n "${DOTFILES_SOURCE_DIR}" ]] || critical_exit "Dotfiles source dir is empty."
    info_msg "Dotfiles source: ${DOTFILES_SOURCE_DIR}"
    [[ -n "${TEMP_CLONE_DIR}" ]] && info_msg "Temp clone dir: ${TEMP_CLONE_DIR}"
    
    verify_core_dependencies || return 1 # From dependencies.sh
    info_msg "Initialization phase completed."; return 0
}

process_configurations() {
    info_msg "Phase: Processing Configurations..."
    local phase_ok=true
    
    perform_backups || phase_ok=false # Non-critical if backup fails
    
    setup_target_directories || { error_msg "Base target dir setup FAILED. Halting config processing."; return 1; }
    
    copy_configurations || { error_msg "Core configuration copying FAILED."; return 1; } # Critical
    update_hyprland_env_config || phase_ok=false
    configure_hyprpaper_script || phase_ok=false

    [[ "${phase_ok}" == true ]] || { warning_msg "Config processing phase had non-critical issues."; return 1; }
    info_msg "Configuration processing phase completed."; return 0
}

manage_services_phase() {
    if [[ "${SKIP_SERVICES}" == "true" ]]; then info_msg "Skipping service management."; return 0; fi
    info_msg "Phase: Managing Services..."
    local phase_ok=true

    manage_daemon "waybar" "waybar" || phase_ok=false
    manage_daemon "hyprpaper" "hyprpaper" || phase_ok=false
    
    [[ "${phase_ok}" == true ]] || { warning_msg "Service management phase had issues."; return 1; }
    
    info_msg "Service management phase completed."
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

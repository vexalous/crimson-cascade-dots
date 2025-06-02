#!/usr/bin/env bash

# Strict mode: exit on error, unset variable, or pipe failure
set -o errexit -o nounset -o pipefail
# Set Internal Field Separator to only newline and tab, guarding against unintended word splitting.
# Note: 'set -o nounset' requires all variables (including those in sourced scripts)
# to be explicitly set or defaulted. Verify this for all dependencies.
IFS=$'\n\t'

# --- Script Identity & Constants ---
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
LOCK_FILE="/tmp/${SCRIPT_NAME}.lock" # Lockfile to prevent concurrent runs
readonly LOCK_FILE
DEFAULT_SCRIPT_LOG_FILE="/tmp/${SCRIPT_NAME}.$(date +%Y%m%d).log"
readonly DEFAULT_SCRIPT_LOG_FILE
readonly SCRIPT_VERSION="1.0.0-dev" # Example version; populate as needed

# --- Configuration Constants ---
# These constants are intended for use by sourced library scripts (e.g., backup.sh, git_ops.sh).
# Use declare -xr to atomically declare, assign, make readonly, and export.
declare -xr BACKUP_DIR_BASE="${HOME}/config_backups_crimson_cascade"
declare -xr GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
declare -xr REPO_NAME="crimson-cascade-dots"

readonly CONFIG_TARGET_DIR="${HOME}/.config"
readonly DEFAULT_WALLPAPER_FILE="crimson_black_wallpaper.png"
readonly USER_HYPR_SCRIPTS_DIR="${CONFIG_TARGET_DIR}/hypr/scripts"
readonly WALLPAPER_CONFIG_DIR="${CONFIG_TARGET_DIR}/hypr/wallpaper"

# --- Global Variables (State & Configuration) ---
DOTFILES_SOURCE_DIR=""
TEMP_CLONE_DIR="" # Cleaned up by 'trap cleanup'

# Script behavior flags, set by argument parsing
DEBUG_MODE=false
SKIP_BACKUPS=false
SKIP_SERVICES=false
SKIP_HYPR_ENV=false
SCRIPT_LOG_FILE="${DEFAULT_SCRIPT_LOG_FILE}"
OVERALL_SCRIPT_STATUS=0 # Global tracker: 0=all good, 1=non-critical issues occurred


# --- Logging Framework ---
log_message() {
    local type="$1" message="$2" timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[${type}] [${timestamp}] ${message}"
    # Use printf for safer handling of special characters and consistency.
    printf '%s\n' "${formatted_message}" >> "${SCRIPT_LOG_FILE}" # Always log to file
    case "${type}" in # Optionally print to console
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
critical_exit() {
    log_message "CRITICAL" "$*"
    OVERALL_SCRIPT_STATUS=1 # Ensure overall status reflects critical failure
    # Cleanup will be called by the EXIT trap. Script will exit with 1 due to this call.
    exit 1
}

# --- Lockfile Management ---
acquire_lock() {
    # Advanced consideration for very high-contention environments:
    # Implement a retry loop with exponential backoff here if acquiring the lock
    # after a stale lock removal frequently fails due to another instance immediately
    # acquiring it. For typical dotfile script usage, this is usually not necessary.
    if (set -o noclobber; echo "$$" > "${LOCK_FILE}") 2>/dev/null; then
        debug_msg "Lock acquired: ${LOCK_FILE} (PID $$)"
        return 0
    fi
    local locked_pid
    locked_pid=$(cat "${LOCK_FILE}" 2>/dev/null || echo "unknown_pid")
    error_msg "${SCRIPT_NAME} is already running (PID: ${locked_pid} as per lockfile) or lockfile is stale."
    if [[ "${locked_pid}" != "unknown_pid" ]] && ! ps -p "${locked_pid}" > /dev/null; then
        warning_msg "Stale lockfile detected (PID ${locked_pid} is not running)."
        warning_msg "Removing stale lockfile: ${LOCK_FILE}"
        rm -f "${LOCK_FILE}"
        info_msg "Stale lockfile removed. Please try running the script again."
    fi
    return 1 # Lock not acquired
}
release_lock() {
    if ! rm -f "${LOCK_FILE}"; then
        warning_msg "Failed to release lockfile: ${LOCK_FILE}. This is unusual if the lock was held."
    else
        debug_msg "Lock released: ${LOCK_FILE}"
    fi
}

# --- Library Sourcing ---
source_libraries() {
    info_msg "Sourcing library scripts from '${SCRIPT_DIR}/scripts/setup_lib'..."
    local lib_dir="${SCRIPT_DIR}/scripts/setup_lib"

    # Unrolled loop for individual shellcheck directives
    local lib_path="${lib_dir}/ui.sh"
    if [[ ! -f "${lib_path}" ]]; then critical_exit "Required library file not found: ${lib_path}"; fi
    # shellcheck source=scripts/setup_lib/ui.sh
    source "${lib_path}"; debug_msg "Sourced library: ${lib_path}"

    lib_path="${lib_dir}/dependencies.sh"
    if [[ ! -f "${lib_path}" ]]; then critical_exit "Required library file not found: ${lib_path}"; fi
    # shellcheck source=scripts/setup_lib/dependencies.sh
    source "${lib_path}"; debug_msg "Sourced library: ${lib_path}"

    lib_path="${lib_dir}/backup.sh"
    if [[ ! -f "${lib_path}" ]]; then critical_exit "Required library file not found: ${lib_path}"; fi
    # shellcheck source=scripts/setup_lib/backup.sh
    source "${lib_path}"; debug_msg "Sourced library: ${lib_path}"

    lib_path="${lib_dir}/fs_ops.sh"
    if [[ ! -f "${lib_path}" ]]; then critical_exit "Required library file not found: ${lib_path}"; fi
    # shellcheck source=scripts/setup_lib/fs_ops.sh
    source "${lib_path}"; debug_msg "Sourced library: ${lib_path}"

    lib_path="${lib_dir}/git_ops.sh"
    if [[ ! -f "${lib_path}" ]]; then critical_exit "Required library file not found: ${lib_path}"; fi
    # shellcheck source=scripts/setup_lib/git_ops.sh
    source "${lib_path}"; debug_msg "Sourced library: ${lib_path}"

    info_msg "All library scripts sourced successfully."
}

# --- Core Function Implementations (Return 0 for success, 1 for non-critical failure) ---

perform_backups() {
    if [[ "${SKIP_BACKUPS}" == "true" ]]; then
        info_msg "Skipping backup process (user-specified --skip-backups)."
        return 0
    fi
    info_msg "Starting configuration backup process..."
    local components_to_backup=("hypr" "waybar" "alacritty" "rofi")
    if handle_backup_process "${components_to_backup[@]}"; then # Provided by backup.sh
        info_msg "Backup process completed successfully."
        return 0
    else
        warning_msg "Backup process encountered issues. Review logs. Continuing setup."
        return 1 # Non-critical failure
    fi
}

setup_target_directories() {
    info_msg "Ensuring target configuration directories exist under ${CONFIG_TARGET_DIR}..."
    local wallpaper_rel_path="${WALLPAPER_CONFIG_DIR#${CONFIG_TARGET_DIR}/}"
    [[ -z "${wallpaper_rel_path}" || "${wallpaper_rel_path}" == "/" ]] && wallpaper_rel_path="hypr/wallpaper"
    local dirs_to_ensure=( "hypr/conf" "hypr/scripts" "${wallpaper_rel_path}" "waybar" "alacritty" "rofi" )

    if ensure_target_dirs "${CONFIG_TARGET_DIR}" "${dirs_to_ensure[@]}"; then # Provided by fs_ops.sh
        info_msg "Target directories ensured successfully."
        return 0
    else
        error_msg "Failed to ensure one or more target directories. This is a critical setup step."
        return 1 # Indicates failure of this essential step
    fi
}

# NEW HELPER FUNCTION to fully overwrite a component directory
# This replaces the need for fs_ops.sh/copy_component for cases requiring full overwrite.
overwrite_component_dir() {
    local source_base_dir="$1"     # e.g., ${DOTFILES_SOURCE_DIR}
    local dest_base_dir="$2"       # e.g., ${CONFIG_TARGET_DIR}
    local component_name="$3"      # e.g., "hypr"
    local display_name="${4:-${component_name}}" # User-friendly name for logging

    local source_component_full_path="${source_base_dir}/${component_name}"
    local dest_component_full_path="${dest_base_dir}/${component_name}"

    info_msg "Force-overwriting component ${display_name}: '${source_component_full_path}' -> '${dest_component_full_path}'"

    if [[ ! -d "${source_component_full_path}" ]]; then
        error_msg "Source directory for ${display_name} component not found: ${source_component_full_path}"
        return 1
    fi

    # Ensure parent of destination component directory exists
    # e.g., if dest_component_full_path is /home/user/.config/hypr, parent is /home/user/.config
    local parent_dest_dir
    parent_dest_dir=$(dirname "${dest_component_full_path}")
    if ! mkdir -p "${parent_dest_dir}"; then
        error_msg "Failed to create parent directory for ${display_name} destination: ${parent_dest_dir}"
        return 1
    fi
    
    # Remove existing destination directory or file if it exists to ensure a clean overwrite
    if [[ -e "${dest_component_full_path}" ]]; then
        info_msg "Removing existing configuration at '${dest_component_full_path}' for ${display_name}."
        if ! rm -rf "${dest_component_full_path}"; then
            error_msg "Failed to remove existing '${dest_component_full_path}' for ${display_name}."
            return 1
        fi
    fi

    # Copy the source component directory to the parent of the intended destination path.
    # cp -rL source_dir/component_name dest_base_dir/
    # e.g., cp -rL "${DOTFILES_SOURCE_DIR}/hypr" "${CONFIG_TARGET_DIR}/"
    # This creates ${CONFIG_TARGET_DIR}/hypr
    # -L: follow all symbolic links in SOURCE and copy the files and directories they point to.
    if cp -rL "${source_component_full_path}" "${parent_dest_dir}/"; then
        info_msg "${display_name} component force-overwritten successfully at ${dest_component_full_path}."
        return 0
    else
        error_msg "Failed to copy ${display_name} component from '${source_component_full_path}' to '${parent_dest_dir}/'."
        return 1
    fi
}


copy_configurations() {
    info_msg "Copying configuration files from ${DOTFILES_SOURCE_DIR}..."
    local all_copied_successfully=true
    
    # Note on overwrite strategy:
    # - For component directories (hypr, waybar), we use `overwrite_component_dir`.
    #   This function removes the target directory first, then copies the source.
    #   This ensures that any user files in the target not present in the source are removed.
    # - For single files, `copy_single_file` (from fs_ops.sh) is assumed to use `cp -f`,
    #   which overwrites the destination file if it exists.
    # - Order matters: Overwrite components first, then copy specific single files into them.
    #   This prevents a single file copy from being erased by a subsequent component overwrite.

    # --- Component Directories (Full Overwrite) ---
    # Overwrite Hyprland component
    overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "hypr" "Hyprland" || all_copied_successfully=false
    # Overwrite Waybar component
    overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "waybar" "Waybar" || all_copied_successfully=false
    # Add other components here if they need full overwrite, e.g.:
    # overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "rofi" "Rofi" || all_copied_successfully=false
    # overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "alacritty" "Alacritty" || all_copied_successfully=false
    # N.B.: The original script copied alacritty.toml as a single file. If 'alacritty' is a full component
    # directory in your dotfiles, use overwrite_component_dir. If it's just the .toml, keep copy_single_file.

    # --- Single Files (Copied/Overwritten into place) ---
    # These are copied *after* their parent components are established to ensure they are not wiped out.
    
    # Wallpaper (copied into the now-overwritten hypr component's wallpaper dir)
    local wallpaper_dest_rel_path="hypr/wallpaper/${DEFAULT_WALLPAPER_FILE}"
    copy_single_file "${DEFAULT_WALLPAPER_FILE}" "${wallpaper_dest_rel_path}" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Default wallpaper" || all_copied_successfully=false

    # Hyprpaper script (copied into the now-overwritten hypr component's scripts dir)
    copy_single_file "scripts/config/hyprpaper.sh" "hypr/scripts/hyprpaper.sh" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Hyprpaper script" || all_copied_successfully=false

    # Alacritty config (if it's a single file and not a full component directory)
    # If DOTFILES_SOURCE_DIR/alacritty is a directory with more than just alacritty.toml,
    # consider using overwrite_component_dir for "alacritty" instead.
    copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Alacritty configuration" || all_copied_successfully=false

    if [[ "${all_copied_successfully}" == true ]]; then
        info_msg "Configuration files copy process completed successfully (with overwrites)."
        return 0
    else
        warning_msg "One or more configuration files may have failed to copy/overwrite. Review logs."
        return 1
    fi
}

update_hyprland_env_config() {
    if [[ "${SKIP_HYPR_ENV}" == "true" ]]; then
        info_msg "Skipping Hyprland env.conf update (user-specified --skip-hypr-env)."
        return 0
    fi
    info_msg "Checking/Updating Hyprland environment config: ${CONFIG_TARGET_DIR}/hypr/conf/env.conf"
    local target_file="${CONFIG_TARGET_DIR}/hypr/conf/env.conf"
    local desired_scripts_line="env = HYPR_SCRIPTS_DIR,${USER_HYPR_SCRIPTS_DIR}"
    local desired_config_line="env = CONFIG_TARGET_DIR,${CONFIG_TARGET_DIR}"

    mkdir -p "$(dirname "${target_file}")"
    # Create target_file if it doesn't exist.
    # If it does exist, original_content will be read from it.
    # If it doesn't, original_content remains empty.
    [[ ! -f "${target_file}" ]] && { info_msg "Creating empty ${target_file}."; touch "${target_file}"; }


    local temp_new_content_file
    temp_new_content_file=$(mktemp --tmpdir "${SCRIPT_NAME}_envconf.XXXXXX")
    if [[ ! -f "${temp_new_content_file}" ]]; then
        error_msg "Failed to create temporary file for env.conf update. Aborting this step."
        return 1
    fi

    local original_content=""
    # Only read original_content if target_file exists and is not empty
    # This handles the case where target_file was just created by `touch`.
    if [[ -s "${target_file}" ]]; then
        original_content=$(<"${target_file}")
    fi


    # Regex to match managed env lines, whether active or commented, with flexible spacing
    local hypr_scripts_regex="^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*HYPR_SCRIPTS_DIR,"
    local config_target_regex="^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*CONFIG_TARGET_DIR,"
    local combined_filter_regex="${hypr_scripts_regex}|${config_target_regex}"

    # Rebuild content: filter original content from target_file directly, excluding managed lines.
    if [[ -f "${target_file}" ]]; then # Check if target_file exists before grepping
        grep -Ev -- "${combined_filter_regex}" "${target_file}" > "${temp_new_content_file}" || : # Allow no match / empty output
    else
        # If target_file somehow doesn't exist (e.g. race after touch, or touch failed silently before errexit)
        # ensure temp_new_content_file is empty.
        : > "${temp_new_content_file}"
    fi


    # Append desired lines, ensuring proper newline if needed
    if [[ -s "${temp_new_content_file}" ]]; then
        # Read only the last character to check for newline, more efficient than reading whole file
        local last_char_val=""
        last_char_val=$(tail -c1 "${temp_new_content_file}")
        if [[ "${last_char_val}" != "" && "${last_char_val}" != $'\n' ]]; then
            echo "" >> "${temp_new_content_file}" # Explicitly echo "" for newline (SC2188 fix)
        fi
    fi
    echo "${desired_scripts_line}" >> "${temp_new_content_file}"
    echo "${desired_config_line}" >> "${temp_new_content_file}"

    local new_content
    new_content=$(<"${temp_new_content_file}")

    # Compare new content with original. Only write if different.
    # Note: original_content might be empty if the file was just touched or was empty.
    if [[ "${original_content}" == "${new_content}" ]]; then
        info_msg "${target_file} is already correctly configured. No changes needed."
        rm -f "${temp_new_content_file}"
        return 0
    fi

    info_msg "Updating ${target_file} as changes are required."
    local backup_file # SC2155
    backup_file="${target_file}.bak.$(date +%Y%m%d%H%M%S)"
    cp "${target_file}" "${backup_file}" # Backup existing file before overwrite
    info_msg "Backup of original ${target_file} created at ${backup_file}"

    if mv "${temp_new_content_file}" "${target_file}"; then
        info_msg "${target_file} updated successfully."
        return 0
    else
        error_msg "Failed to move temporary content to ${target_file}. Original file might be unchanged or corrupted."
        rm -f "${temp_new_content_file}" # Attempt to clean up
        return 1
    fi
}


configure_hyprpaper_script() {
    info_msg "Configuring local hyprpaper script (if found)..."
    local script_path="${USER_HYPR_SCRIPTS_DIR}/hyprpaper.sh"
    local script_exit_status=0

    if [[ ! -f "${script_path}" ]]; then
        warning_msg "Hyprpaper script not found at: ${script_path}. Cannot configure wallpaper via this script."
        return 1
    fi
    if ! chmod +x "${script_path}"; then
        error_msg "Failed to set execute permission on ${script_path}."
        return 1
    fi

    info_msg "Executing hyprpaper configuration script: ${script_path}"
    if [[ -z "${CONFIG_TARGET_DIR:-}" ]]; then
        error_msg "CRITICAL: CONFIG_TARGET_DIR env variable is not set. Cannot execute hyprpaper script reliably."
        return 1
    fi
    export CONFIG_TARGET_DIR # Make available to the sub-script

    # Execute and capture exit status
    "${script_path}" || script_exit_status=$?

    if [[ "${script_exit_status}" -eq 0 ]]; then
        info_msg "Hyprpaper configuration script executed successfully."
        return 0
    else
        warning_msg "Hyprpaper configuration script (${script_path}) execution failed with status ${script_exit_status}. Check its output or logs."
        return 1
    fi
}

manage_daemon() {
    local process_name="$1" command_to_start="$2" log_file daemon_status=0
    local -r sigterm_timeout_seconds=3 # Seconds to wait for SIGTERM
    local nohup_pid

    info_msg "Managing daemon process: ${process_name}..."
    if ! command -v "${process_name}" >/dev/null 2>&1; then
        warning_msg "Command '${process_name}' not found. Skipping management of this daemon."
        return 1
    fi

    # Using long options for pgrep/pkill for max clarity
    if pgrep --exact --uid "$(id -u)" "${process_name}" >/dev/null; then
        info_msg "Attempting graceful shutdown (SIGTERM) of existing ${process_name} process(es)..."
        if pkill --exact --signal SIGTERM --uid "$(id -u)" "${process_name}"; then
            local count=0
            while [[ "${count}" -lt "${sigterm_timeout_seconds}" ]]; do
                if ! pgrep --exact --uid "$(id -u)" "${process_name}" >/dev/null; then
                    info_msg "${process_name} terminated gracefully via SIGTERM."
                    break
                fi
                sleep 1
                ((count++))
            done
            if [[ "${count}" -ge "${sigterm_timeout_seconds}" ]] && pgrep --exact --uid "$(id -u)" "${process_name}" >/dev/null; then
                warning_msg "${process_name} did not terminate via SIGTERM after ${sigterm_timeout_seconds}s. Sending SIGKILL..."
                if pkill --exact --signal SIGKILL --uid "$(id -u)" "${process_name}"; then
                    sleep 0.5 # Give SIGKILL a moment
                    info_msg "${process_name} terminated via SIGKILL."
                else
                    warning_msg "SIGKILL command for ${process_name} failed (process might have just exited or other issue)."
                fi
            fi
        else
            warning_msg "Sending SIGTERM to ${process_name} failed (process may have already exited or permission issue)."
        fi
    else
        info_msg "No existing ${process_name} process found running for user $(id -un)."
    fi

    log_file=$(mktemp --tmpdir "${process_name}_${SCRIPT_NAME}.XXXXXX.log")
    info_msg "Starting ${process_name} in background. Log: ${log_file}"
    if nohup "${command_to_start}" >"${log_file}" 2>&1 & then
        nohup_pid=$! # Get PID of the nohup process itself
        disown "${nohup_pid}" # Decouple from script's job table
        debug_msg "${process_name} (via nohup PID ${nohup_pid}) disowned."
        sleep 0.5 # Allow process to initialize or fail fast
        if pgrep --exact --uid "$(id -u)" "${process_name}" >/dev/null; then
            info_msg "${process_name} started successfully in background."
        else
            error_msg "${process_name} was launched but seems to have exited or failed to start."
            error_msg "Please check the daemon log: ${log_file} and system logs (e.g., journalctl)."
            daemon_status=1
        fi
    else
        error_msg "Failed to execute 'nohup ${command_to_start}'. ${process_name} may not have started."
        error_msg "Check permissions, command path, or the daemon log: ${log_file} (if created)."
        daemon_status=1
    fi
    return ${daemon_status}
}

# --- Cleanup ---
cleanup() {
    local script_exit_status=$? # Capture the exit status of the script (how trap EXIT was triggered)
    info_msg "Initiating cleanup sequence (Script is exiting with status: ${script_exit_status})..."
    if [[ -n "${TEMP_CLONE_DIR}" && -d "${TEMP_CLONE_DIR}" ]]; then
        info_msg "Cleaning temporary clone directory: ${TEMP_CLONE_DIR}"
        if cleanup_temp_dir "${TEMP_CLONE_DIR}"; then # From fs_ops.sh
             info_msg "Temporary clone directory cleaned successfully."
        else
            warning_msg "Failed to clean temporary clone directory: ${TEMP_CLONE_DIR}"
            warning_msg "Manual removal may be needed: rm -rf ${TEMP_CLONE_DIR}"
        fi
    fi
    release_lock

    # Final summary message reflecting the outcome
    if [[ "${script_exit_status}" -eq 0 && "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
        info_msg "Script completed all operations successfully and exited cleanly (status 0)."
    elif [[ "${script_exit_status}" -eq 1 && "${OVERALL_SCRIPT_STATUS}" -ne 0 ]]; then
        warning_msg "Script finished, but non-critical operations reported issues (OVERALL_SCRIPT_STATUS=${OVERALL_SCRIPT_STATUS}). Exiting with status 1."
    elif [[ "${script_exit_status}" -ne 0 ]]; then
        error_msg "Script exited prematurely or with a critical error (captured exit status: ${script_exit_status}). OVERALL_SCRIPT_STATUS was ${OVERALL_SCRIPT_STATUS}."
    else 
        warning_msg "Script exiting with status 0, but internal OVERALL_SCRIPT_STATUS was ${OVERALL_SCRIPT_STATUS}. This indicates an unexpected state. Review logs."
    fi
    info_msg "Cleanup finished. Full script execution log available at: ${SCRIPT_LOG_FILE}"
}

# --- Help Message ---
print_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS] (Version: ${SCRIPT_VERSION})
Manages the setup of Crimson Cascade Dotfiles. This script attempts to be idempotent.
It overwrites existing configuration directories like hypr, waybar, etc., with the
versions from the dotfiles repository. Single configuration files are also overwritten.
Backups are created by default before overwriting.

Options:
  --skip-backups         Skip the configuration backup process.
  --skip-services        Skip managing (restarting) waybar and hyprpaper daemons.
  --skip-hypr-env        Skip updating Hyprland's env.conf file.
  --debug                Enable verbose debug messages for script execution.
  --log-file <path>      Specify a custom path for the script's log file.
                         (Default: ${DEFAULT_SCRIPT_LOG_FILE})
  --version              Display script version and exit.
  -h, --help             Display this help message and exit.

Note: This script uses GNU getopt for argument parsing, which is standard on most Linux
      systems. For macOS or other systems without GNU getopt by default, you may need
      to install 'gnu-getopt' (e.g., via Homebrew) and ensure it's in your PATH,
      or modify the script to use POSIX getopts (short options only).
      This script also requires Bash version 4.4+ for certain features (NUL-delimited mapfile).
EOF
}

# --- Main Script Orchestration ---
main() {
    # Check for Bash version (Bash 4.4+ for mapfile -d)
    if ((BASH_VERSINFO[0] < 4)) || ((BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4)); then
      critical_exit "This script requires Bash version 4.4 or newer (for NUL-delimited mapfile support)."
    fi

    # Check for GNU getopt
    if ! command -v getopt >/dev/null || ! getopt -T >/dev/null 2>&1; then
        local getopt_output # Check if it's GNU getopt specifically
        getopt_output=$(getopt -T 2>&1)
        if [[ -z "${getopt_output}" && $? -eq 4 ]]; then
             debug_msg "GNU getopt detected."
        else
             critical_exit "GNU getopt is required for long option parsing but not found or not the GNU version. Please install 'gnu-getopt' or ensure GNU getopt is in your PATH."
        fi
    fi


    # Argument Parsing with GNU getopt:
    local short_opts="h"
    local long_opts="skip-backups,skip-services,skip-hypr-env,debug,log-file:,help,version"
    local parsed_opts
    if ! parsed_opts=$(getopt -o "${short_opts}" --long "${long_opts}" -n "${SCRIPT_NAME}" -- "$@"); then
        print_help >&2
        exit 1
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
            *) critical_exit "Internal error in argument parsing logic!" ;;
        esac
    done

    mkdir -p "$(dirname "${SCRIPT_LOG_FILE}")" || critical_exit "Cannot create log directory: $(dirname "${SCRIPT_LOG_FILE}")"
    # Touch also creates if not exists, or updates timestamp if it does.
    touch "${SCRIPT_LOG_FILE}" || critical_exit "Cannot create or update log file: ${SCRIPT_LOG_FILE}"


    info_msg "--- ${SCRIPT_NAME} execution started (Version: ${SCRIPT_VERSION}) ---"
    info_msg "Using script log file: ${SCRIPT_LOG_FILE}"
    [[ "${DEBUG_MODE}" == "true" ]] && info_msg "DEBUG mode has been enabled."

    trap cleanup EXIT HUP INT QUIT TERM
    if ! acquire_lock; then critical_exit "Exiting due to failure to acquire script lock."; fi

    initialize_script || OVERALL_SCRIPT_STATUS=1
    if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
        process_configurations || OVERALL_SCRIPT_STATUS=1
        if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
             manage_services_phase || OVERALL_SCRIPT_STATUS=1
        else
            warning_msg "Skipping service management due to issues encountered in configuration processing."
        fi
    else
         warning_msg "Skipping configuration and service management due to issues encountered in initialization."
    fi

    if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
        info_msg "--- ${SCRIPT_NAME} execution concluded successfully. ---"
        exit 0
    else
        warning_msg "--- ${SCRIPT_NAME} execution concluded, but one or more non-critical errors occurred. Review log. ---"
        exit 1
    fi
}

initialize_script() {
    info_msg "Phase: Initializing Script..."
    local phase_status=0
    source_libraries
    print_header # Assumed from ui.sh

    DOTFILES_SOURCE_DIR="" TEMP_CLONE_DIR=""
    # IMPORTANT ASSUMPTION: determine_source_dir (from git_ops.sh) must output
    # two NUL-terminated strings for DOTFILES_SOURCE_DIR and TEMP_CLONE_DIR respectively
    # to handle potential spaces in paths correctly. This requires Bash 4.4+.
    local source_dirs_array=()
    # The command substitution `determine_source_dir` is run. Its stdout is piped to mapfile.
    if ! mapfile -d $'\0' -t source_dirs_array < <(determine_source_dir); then
        error_msg "Failed to read output from determine_source_dir."
        error_msg "Ensure git_ops.sh/determine_source_dir provides two NUL-delimited paths."
        critical_exit "Could not determine source directories due to read failure."
    fi

    # Ensure we received exactly two elements from determine_source_dir
    if [[ "${#source_dirs_array[@]}" -ne 2 ]]; then
        error_msg "determine_source_dir provided an unexpected number of paths."
        error_msg "Expected 2 NUL-delimited paths, received ${#source_dirs_array[@]}."
        critical_exit "Invalid output format from determine_source_dir."
    fi

    DOTFILES_SOURCE_DIR="${source_dirs_array[0]}"
    TEMP_CLONE_DIR="${source_dirs_array[1]}"


    if [[ -z "${DOTFILES_SOURCE_DIR}" ]]; then
        critical_exit "Dotfiles source directory was determined to be empty. Cannot proceed."
    fi
    info_msg "Dotfiles source directory identified as: ${DOTFILES_SOURCE_DIR}"
    if [[ -n "${TEMP_CLONE_DIR}" ]]; then
        info_msg "Using temporary clone directory: ${TEMP_CLONE_DIR}"
    fi
    # verify_core_dependencies might be called here or within determine_source_dir context
    # Original script had it after TEMP_CLONE_DIR check, so keeping it if it's relevant
    # if [[ -n "${TEMP_CLONE_DIR}" ]]; then
    #    verify_core_dependencies || phase_status=1 # verify_core_dependencies usually from dependencies.sh
    # fi
    # Assuming verify_core_dependencies is general or handled correctly by sourced scripts.
    # If it's meant to check deps for cloning and the repo is local, it might be skipped.
    # For now, let's assume it's correctly handled by the original logic if needed.
    # A general dependency check is good practice anyway.
    verify_core_dependencies || phase_status=1


    if [[ "${phase_status}" -eq 0 ]]; then info_msg "Initialization phase completed with no issues reported.";
    else warning_msg "Initialization phase completed with some issues reported."; fi
    return ${phase_status}
}

process_configurations() {
    info_msg "Phase: Processing Configurations..."
    local phase_status=0

    perform_backups || phase_status=1

    if ! setup_target_directories; then
        error_msg "Critical failure during target directory setup. Aborting configuration processing phase."
        return 1 # This return will be caught by `|| OVERALL_SCRIPT_STATUS=1` in main.
                 # but for clarity, we set phase_status and let the main flow handle OVERALL_SCRIPT_STATUS.
    fi

    copy_configurations || phase_status=1
    update_hyprland_env_config || phase_status=1
    configure_hyprpaper_script || phase_status=1

    if [[ "${phase_status}" -eq 0 ]]; then info_msg "Configuration processing phase completed with no issues reported.";
    else warning_msg "Configuration processing phase completed with some issues reported."; fi
    return ${phase_status}
}

manage_services_phase() {
    if [[ "${SKIP_SERVICES}" == "true" ]]; then
        info_msg "Phase: Skipping service management (user-specified --skip-services)."
        return 0
    fi
    info_msg "Phase: Managing Services (Waybar, Hyprpaper)..."
    local phase_status=0

    manage_daemon "waybar" "waybar" || phase_status=1
    manage_daemon "hyprpaper" "hyprpaper" || phase_status=1

    if [[ "${phase_status}" -eq 0 ]]; then info_msg "Service management phase completed with no issues reported.";
    else warning_msg "Service management phase completed with some issues reported."; fi

    info_msg "" # Consistent logging for blank line
    info_msg "--------------------------------------------------------------------"
    info_msg "Relevant services have been (re)started (if installed and not skipped)."
    info_msg "If you are running this script outside of an active Hyprland session,"
    info_msg "or if environment variables were changed, it is STRONGLY RECOMMENDED to"
    info_msg "LOG OUT and LOG BACK IN for all changes to take full effect."
    info_msg "--------------------------------------------------------------------"
    return ${phase_status}
}

# --- Script Execution Guard ---
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

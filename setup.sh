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
readonly SCRIPT_VERSION="1.0.1-fixed-overwrite" # Example version; populate as needed

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
    # This function ensures the *base* directories. Specific sub-directories for single files
    # within overwritten components will be handled in copy_configurations.
    local wallpaper_rel_path="${WALLPAPER_CONFIG_DIR#${CONFIG_TARGET_DIR}/}"
    [[ -z "${wallpaper_rel_path}" || "${wallpaper_rel_path}" == "/" ]] && wallpaper_rel_path="hypr/wallpaper"
    
    # Define base directories to ensure. `hypr/wallpaper` is technically handled by `hypr` itself being ensured.
    # The more specific ones like hypr/scripts, hypr/wallpaper will be handled post-component-overwrite
    # if they are not part of the source component structure.
    local dirs_to_ensure=( "hypr" "waybar" "alacritty" "rofi" ) 
    # Example: ensure_target_dirs "${CONFIG_TARGET_DIR}" "hypr" "waybar" "alacritty" "rofi"

    if ensure_target_dirs "${CONFIG_TARGET_DIR}" "${dirs_to_ensure[@]}"; then # Provided by fs_ops.sh
        info_msg "Target directories ensured successfully."
        return 0
    else
        error_msg "Failed to ensure one or more target directories. This is a critical setup step."
        return 1 # Indicates failure of this essential step
    fi
}

# HELPER FUNCTION to fully overwrite a component directory
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

    local parent_dest_dir
    parent_dest_dir=$(dirname "${dest_component_full_path}")
    if ! mkdir -p "${parent_dest_dir}"; then # Ensures ~/.config exists
        error_msg "Failed to create parent directory for ${display_name} destination: ${parent_dest_dir}"
        return 1
    fi
    
    if [[ -e "${dest_component_full_path}" ]]; then
        info_msg "Removing existing configuration at '${dest_component_full_path}' for ${display_name}."
        if ! rm -rf "${dest_component_full_path}"; then
            error_msg "Failed to remove existing '${dest_component_full_path}' for ${display_name}."
            return 1
        fi
    fi

    # Copy the source component directory. -L follows symlinks from source.
    # e.g., cp -rL "${DOTFILES_SOURCE_DIR}/hypr" "${CONFIG_TARGET_DIR}/"
    # This will create ${CONFIG_TARGET_DIR}/hypr
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
    
    # --- Component Directories (Full Overwrite) ---
    # These functions remove the target directory first, then copy the source.
    
    overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "hypr" "Hyprland" || all_copied_successfully=false
    overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "waybar" "Waybar" || all_copied_successfully=false
    
    # Decide for alacritty and rofi:
    # If DOTFILES_SOURCE_DIR/alacritty and DOTFILES_SOURCE_DIR/rofi are full component directories
    # that you want to fully replace in ~/.config/, then use overwrite_component_dir:
    # overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "alacritty" "Alacritty" || all_copied_successfully=false
    # overwrite_component_dir "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "rofi" "Rofi" || all_copied_successfully=false
    # If you only copy specific files (e.g., alacritty.toml), don't use overwrite_component_dir for them.

    # --- Explicit Directory Creation for Single File Targets ---
    # After overwriting components, we must ensure the specific target directories for
    # individual files exist, as overwrite_component_dir might have removed them if
    # they were not present in the source component's structure.

    local hypr_wallpaper_dir="${CONFIG_TARGET_DIR}/hypr/wallpaper" # Same as WALLPAPER_CONFIG_DIR
    local hypr_scripts_dir="${CONFIG_TARGET_DIR}/hypr/scripts"   # Same as USER_HYPR_SCRIPTS_DIR
    local alacritty_dir="${CONFIG_TARGET_DIR}/alacritty"         # For alacritty.toml if alacritty is not a full component

    info_msg "Ensuring target directories for specific single files exist post-component-overwrite..."
    if ! mkdir -p "${hypr_wallpaper_dir}"; then
        error_msg "Failed to create target directory: ${hypr_wallpaper_dir}"
        all_copied_successfully=false
    else
        debug_msg "Ensured directory exists: ${hypr_wallpaper_dir}"
    fi
    if ! mkdir -p "${hypr_scripts_dir}"; then
        error_msg "Failed to create target directory: ${hypr_scripts_dir}"
        all_copied_successfully=false
    else
        debug_msg "Ensured directory exists: ${hypr_scripts_dir}"
    fi
    
    # This 'mkdir -p' for alacritty_dir is only necessary if 'alacritty' is NOT 
    # handled by `overwrite_component_dir` above. If you *are* using 
    # `overwrite_component_dir` for "alacritty", then that function ensures
    # `${CONFIG_TARGET_DIR}/alacritty` is created based on your source, and this `mkdir -p` is redundant
    # or could conflict if the source `alacritty` is just a file.
    # Assuming for now that 'alacritty' is NOT a fully overwritten component, and we only copy alacritty.toml into it.
    # If DOTFILES_SOURCE_DIR/alacritty is a directory that is fully copied via overwrite_component_dir,
    # then this explicit mkdir -p might not be needed or could be removed.
    if ! overwrite_component_dir_was_used_for "alacritty"; then # Placeholder for your logic
        if ! mkdir -p "${alacritty_dir}"; then
            error_msg "Failed to create target directory: ${alacritty_dir}"
            all_copied_successfully=false
        else
            debug_msg "Ensured directory exists: ${alacritty_dir}"
        fi
    fi

    # --- Single Files (Copied/Overwritten into place using fs_ops.sh/copy_single_file) ---
    # These are copied *after* their parent components are established AND specific target dirs are ensured.
    
    local wallpaper_dest_rel_path="hypr/wallpaper/${DEFAULT_WALLPAPER_FILE}"
    # copy_single_file <source_filename_in_repo_root_or_subdir> <dest_relative_to_config_target_dir> <source_base> <dest_base> <display_name>
    copy_single_file "${DEFAULT_WALLPAPER_FILE}" "${wallpaper_dest_rel_path}" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Default wallpaper" || all_copied_successfully=false

    copy_single_file "scripts/config/hyprpaper.sh" "hypr/scripts/hyprpaper.sh" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Hyprpaper script" || all_copied_successfully=false

    # Alacritty config:
    # This assumes DOTFILES_SOURCE_DIR/alacritty/alacritty.toml exists.
    # And that `~/.config/alacritty/` directory is now ensured (either by `overwrite_component_dir` or the explicit `mkdir -p` above).
    copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Alacritty configuration" || all_copied_successfully=false
    
    # Example for Rofi if it's not a full component:
    # if ! overwrite_component_dir_was_used_for "rofi"; then
    #   if ! mkdir -p "${CONFIG_TARGET_DIR}/rofi"; then error_msg ...; all_copied_successfully=false; fi
    # fi
    # copy_single_file "rofi/config.rasi" "rofi/config.rasi" \
    #    "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Rofi configuration" || all_copied_successfully=false


    if [[ "${all_copied_successfully}" == true ]]; then
        info_msg "Configuration files copy process completed successfully (with overwrites and explicit directory creation)."
        return 0
    else
        warning_msg "One or more configuration files/directories may have failed to copy/overwrite or create. Review logs."
        return 1
    fi
}

# Placeholder function - replace with your actual logic to determine if overwrite_component_dir was used
overwrite_component_dir_was_used_for() {
    local component_to_check="$1"
    # Example: if you decide to always use overwrite_component_dir for 'alacritty', return 0 (true)
    # if [[ "$component_to_check" == "alacritty" ]]; then return 0; fi
    # For this example, assume it was NOT used, so mkdir -p will run.
    return 1 # False, meaning it was not used.
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
    [[ ! -f "${target_file}" ]] && { info_msg "Creating empty ${target_file}."; touch "${target_file}"; }

    local temp_new_content_file
    temp_new_content_file=$(mktemp --tmpdir "${SCRIPT_NAME}_envconf.XXXXXX")
    if [[ ! -f "${temp_new_content_file}" ]]; then
        error_msg "Failed to create temporary file for env.conf update. Aborting this step."
        return 1
    fi

    local original_content=""
    if [[ -s "${target_file}" ]]; then
        original_content=$(<"${target_file}")
    fi

    local hypr_scripts_regex="^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*HYPR_SCRIPTS_DIR,"
    local config_target_regex="^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*CONFIG_TARGET_DIR,"
    local combined_filter_regex="${hypr_scripts_regex}|${config_target_regex}"

    if [[ -f "${target_file}" ]]; then 
        grep -Ev -- "${combined_filter_regex}" "${target_file}" > "${temp_new_content_file}" || : 
    else
        : > "${temp_new_content_file}"
    fi

    if [[ -s "${temp_new_content_file}" ]]; then
        local last_char_val=""
        last_char_val=$(tail -c1 "${temp_new_content_file}")
        if [[ "${last_char_val}" != "" && "${last_char_val}" != $'\n' ]]; then
            echo "" >> "${temp_new_content_file}"
        fi
    fi
    echo "${desired_scripts_line}" >> "${temp_new_content_file}"
    echo "${desired_config_line}" >> "${temp_new_content_file}"

    local new_content
    new_content=$(<"${temp_new_content_file}")

    if [[ "${original_content}" == "${new_content}" ]]; then
        info_msg "${target_file} is already correctly configured. No changes needed."
        rm -f "${temp_new_content_file}"
        return 0
    fi

    info_msg "Updating ${target_file} as changes are required."
    local backup_file 
    backup_file="${target_file}.bak.$(date +%Y%m%d%H%M%S)"
    cp "${target_file}" "${backup_file}" 
    info_msg "Backup of original ${target_file} created at ${backup_file}"

    if mv "${temp_new_content_file}" "${target_file}"; then
        info_msg "${target_file} updated successfully."
        return 0
    else
        error_msg "Failed to move temporary content to ${target_file}. Original file might be unchanged or corrupted."
        rm -f "${temp_new_content_file}" 
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
    export CONFIG_TARGET_DIR 

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
    local -r sigterm_timeout_seconds=3 
    local nohup_pid

    info_msg "Managing daemon process: ${process_name}..."
    if ! command -v "${process_name}" >/dev/null 2>&1; then
        warning_msg "Command '${process_name}' not found. Skipping management of this daemon."
        return 1
    fi

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
                    sleep 0.5 
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
        nohup_pid=$! 
        disown "${nohup_pid}" 
        debug_msg "${process_name} (via nohup PID ${nohup_pid}) disowned."
        sleep 0.5 
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
    local script_exit_status=$? 
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

Note: This script uses GNU getopt for argument parsing. Bash version 4.4+ is required.
      Ensure 'gnu-getopt' is installed and in PATH if not on a standard Linux system.
EOF
}

# --- Main Script Orchestration ---
main() {
    if ((BASH_VERSINFO[0] < 4)) || ((BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4)); then
      critical_exit "This script requires Bash version 4.4 or newer."
    fi

    if ! command -v getopt >/dev/null || ! getopt -T >/dev/null 2>&1; then
        local getopt_output 
        getopt_output=$(getopt -T 2>&1)
        if [[ -z "${getopt_output}" && $? -eq 4 ]]; then
             debug_msg "GNU getopt detected."
        else
             critical_exit "GNU getopt is required. Please install 'gnu-getopt'."
        fi
    fi

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
            warning_msg "Skipping service management due to issues in configuration processing."
        fi
    else
         warning_msg "Skipping configuration and service management due to issues in initialization."
    fi

    if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
        info_msg "--- ${SCRIPT_NAME} execution concluded successfully. ---"
        exit 0
    else
        warning_msg "--- ${SCRIPT_NAME} execution concluded, but one or more non-critical errors occurred. ---"
        exit 1
    fi
}

initialize_script() {
    info_msg "Phase: Initializing Script..."
    local phase_status=0
    source_libraries
    print_header # Assumed from ui.sh

    DOTFILES_SOURCE_DIR="" TEMP_CLONE_DIR=""
    local source_dirs_array=()
    if ! mapfile -d $'\0' -t source_dirs_array < <(determine_source_dir); then # From git_ops.sh
        critical_exit "Failed to determine source directories from determine_source_dir."
    fi

    if [[ "${#source_dirs_array[@]}" -ne 2 ]]; then
        critical_exit "determine_source_dir provided an unexpected number of paths (${#source_dirs_array[@]}). Expected 2."
    fi

    DOTFILES_SOURCE_DIR="${source_dirs_array[0]}"
    TEMP_CLONE_DIR="${source_dirs_array[1]}"

    if [[ -z "${DOTFILES_SOURCE_DIR}" ]]; then
        critical_exit "Dotfiles source directory is empty. Cannot proceed."
    fi
    info_msg "Dotfiles source directory: ${DOTFILES_SOURCE_DIR}"
    [[ -n "${TEMP_CLONE_DIR}" ]] && info_msg "Using temporary clone directory: ${TEMP_CLONE_DIR}"
    
    verify_core_dependencies || phase_status=1 # From dependencies.sh

    if [[ "${phase_status}" -eq 0 ]]; then info_msg "Initialization phase completed with no issues reported.";
    else warning_msg "Initialization phase completed with some issues reported."; fi
    return ${phase_status}
}

process_configurations() {
    info_msg "Phase: Processing Configurations..."
    local phase_status=0

    perform_backups || phase_status=1

    # setup_target_directories ensures base dirs like ~/.config/hypr exist.
    # copy_configurations will handle more specific subdirs post-overwrite.
    if ! setup_target_directories; then
        error_msg "Critical failure during target directory setup. Aborting."
        return 1 
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

    info_msg "" 
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

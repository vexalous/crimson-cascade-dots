#!/usr/bin/env bash

# Strict mode: exit on error, unset variable, or pipe failure
set -o errexit -o nounset -o pipefail
# Set Internal Field Separator to only newline and tab, guarding against unintended word splitting.
IFS=$'\n\t'

# --- Script Identity & Constants ---
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOCK_FILE="/tmp/${SCRIPT_NAME}.lock" # Lockfile to prevent concurrent runs
readonly DEFAULT_SCRIPT_LOG_FILE="/tmp/${SCRIPT_NAME}.$(date +%Y%m%d).log"

# --- Configuration Constants ---
# These constants might be used by sourced library scripts (e.g., backup.sh, git_ops.sh)
# If not, they should be removed or their usage verified. (SC2034 - flagged if truly unused by *this* script and its direct dependencies)
readonly BACKUP_DIR_BASE="${HOME}/config_backups_crimson_cascade"
readonly GIT_REPO_URL="https://github.com/vexalous/crimson-cascade-dots.git"
readonly REPO_NAME="crimson-cascade-dots"

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
    echo "${formatted_message}" >> "${SCRIPT_LOG_FILE}" # Always log to file
    case "${type}" in # Optionally print to console
        ERROR|CRITICAL) echo "${formatted_message}" >&2 ;;
        WARNING) echo "${formatted_message}" >&2 ;;
        INFO) echo "${formatted_message}" ;;
        DEBUG) [[ "${DEBUG_MODE}" == "true" ]] && echo "${formatted_message}" ;;
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

copy_configurations() {
    info_msg "Copying configuration files from ${DOTFILES_SOURCE_DIR}..."
    local all_copied_successfully=true
    # Simplified destination path for wallpaper
    local wallpaper_dest_rel_path="hypr/wallpaper/${DEFAULT_WALLPAPER_FILE}"

    # Assumes copy_single_file & copy_component from fs_ops.sh return 0 on success, non-0 on failure
    copy_single_file "${DEFAULT_WALLPAPER_FILE}" "${wallpaper_dest_rel_path}" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Default wallpaper" || all_copied_successfully=false
    copy_component "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "hypr" "Hyprland" || all_copied_successfully=false
    copy_single_file "scripts/config/hyprpaper.sh" "hypr/scripts/hyprpaper.sh" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Hyprpaper script" || all_copied_successfully=false
    copy_component "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "waybar" "Waybar" || all_copied_successfully=false
    copy_single_file "alacritty/alacritty.toml" "alacritty/alacritty.toml" \
        "${DOTFILES_SOURCE_DIR}" "${CONFIG_TARGET_DIR}" "Alacritty" || all_copied_successfully=false

    if [[ "${all_copied_successfully}" == true ]]; then
        info_msg "Configuration files copy process completed successfully."
        return 0
    else
        warning_msg "One or more configuration files may have failed to copy. Review logs."
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
    [[ ! -f "${target_file}" ]] && { info_msg "Creating empty ${target_file}."; touch "${target_file}"; }

    local temp_new_content_file
    temp_new_content_file=$(mktemp --tmpdir "${SCRIPT_NAME}_envconf.XXXXXX")
    if [[ ! -f "${temp_new_content_file}" ]]; then
        error_msg "Failed to create temporary file for env.conf update. Aborting this step."
        return 1
    fi

    local original_content=""
    [[ -s "${target_file}" ]] && original_content=$(<"${target_file}")

    # Regex to match managed env lines, whether active or commented, with flexible spacing
    local hypr_scripts_regex="^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*HYPR_SCRIPTS_DIR,"
    local config_target_regex="^[[:space:]]*#*[[:space:]]*env[[:space:]]*=[[:space:]]*CONFIG_TARGET_DIR,"
    local combined_filter_regex="${hypr_scripts_regex}|${config_target_regex}"

    # Rebuild content: filter original content, excluding any lines matching our managed variables.
    if [[ -n "${original_content}" ]]; then
        # Use process substitution for grep to avoid issues with `while read` loops and variable scope
        grep -Ev -- "${combined_filter_regex}" <<< "${original_content}" > "${temp_new_content_file}" || true # Allow no match (empty output)
    else
        # If original content is empty, ensure temp file is also empty (or effectively by > redirect)
        >"${temp_new_content_file}"
    fi

    # Append desired lines, ensuring proper newline if needed
    if [[ -s "${temp_new_content_file}" ]]; then
        local last_char_of_temp_file
        last_char_of_temp_file=$(<"${temp_new_content_file}") # Read entire file to check last char
        if [[ "${last_char_of_temp_file: -1}" != $'\n' ]]; then
            echo "" >> "${temp_new_content_file}" # Explicitly echo "" for newline
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
    local backup_file # SC2155
    backup_file="${target_file}.bak.$(date +%Y%m%d%H%M%S)"
    cp "${target_file}" "${backup_file}"
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

    if "${script_path}"; then
        info_msg "Hyprpaper configuration script executed successfully."
        return 0
    else
        warning_msg "Hyprpaper configuration script (${script_path}) execution failed. Check its output or logs."
        return 1
    fi
}

manage_daemon() {
    local process_name="$1" command_to_start="$2" log_file daemon_status=0
    local -r sigterm_timeout_seconds=3 # Seconds to wait for SIGTERM

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
        # This case means script logic determined non-critical errors, and it's exiting with 1 (due to main logic)
        warning_msg "Script finished with non-critical operations reporting issues (OVERALL_SCRIPT_STATUS=${OVERALL_SCRIPT_STATUS}). Exiting with status 1."
    elif [[ "${script_exit_status}" -ne 0 ]]; then
        # This means errexit, critical_exit, or an external signal caused a non-zero exit before main could set its final exit code.
        error_msg "Script exited prematurely or with a critical error (captured exit status: ${script_exit_status}). OVERALL_SCRIPT_STATUS was ${OVERALL_SCRIPT_STATUS}."
    else # script_exit_status is 0, but OVERALL_SCRIPT_STATUS might be non-zero (should not happen if main exits based on OVERALL_SCRIPT_STATUS)
        warning_msg "Script exiting with status 0, but internal OVERALL_SCRIPT_STATUS was ${OVERALL_SCRIPT_STATUS}. This indicates an unexpected state. Review logs."
    fi
    info_msg "Cleanup finished. Full script execution log available at: ${SCRIPT_LOG_FILE}"
}

# --- Help Message ---
print_help() {
    cat << EOF
Usage: ${SCRIPT_NAME} [OPTIONS]
Manages the setup of Crimson Cascade Dotfiles. This script attempts to be idempotent.

Options:
  --skip-backups         Skip the configuration backup process.
  --skip-services        Skip managing (restarting) waybar and hyprpaper daemons.
  --skip-hypr-env        Skip updating Hyprland's env.conf file.
  --debug                Enable verbose debug messages for script execution.
  --log-file <path>      Specify a custom path for the script's log file.
                         (Default: ${DEFAULT_SCRIPT_LOG_FILE})
  -h, --help             Display this help message and exit.

Example:
  ${SCRIPT_NAME} --skip-backups --debug
EOF
}

# --- Main Script Orchestration ---
main() {
    # Argument Parsing with GNU getopt:
    # This script uses GNU getopt for long options. For maximum portability to systems
    # without GNU getopt (e.g., macOS by default, some minimal *BSDs), consider:
    # 1. Sticking to POSIX getopts (short options only).
    # 2. Implementing a check for GNU getopt and falling back to getopts or manual parsing.
    # 3. Requiring GNU getopt as a dependency.
    # For most Linux desktop environments, GNU getopt is standard.
    local short_opts="h" # Only -h for short options, others are long
    local long_opts="skip-backups,skip-services,skip-hypr-env,debug,log-file:,help"
    local parsed_opts
    if ! parsed_opts=$(getopt -o "${short_opts}" --long "${long_opts}" -n "${SCRIPT_NAME}" -- "$@"); then
        # getopt prints error messages on invalid options to stderr
        print_help >&2
        exit 1 # Exit with an error code
    fi
    eval set -- "${parsed_opts}" # Reset positional parameters ($1, $2, etc.)

    while true; do
        case "$1" in
            --skip-backups) SKIP_BACKUPS=true; shift ;;
            --skip-services) SKIP_SERVICES=true; shift ;;
            --skip-hypr-env) SKIP_HYPR_ENV=true; shift ;;
            --debug) DEBUG_MODE=true; shift ;;
            --log-file) SCRIPT_LOG_FILE="$2"; shift 2 ;;
            -h|--help) print_help; exit 0 ;;
            --) shift; break ;; # End of options marker
            *) critical_exit "Internal error in argument parsing logic!" ;; # Should not happen with getopt
        esac
    done

    # Initialize logging system
    mkdir -p "$(dirname "${SCRIPT_LOG_FILE}")" && touch "${SCRIPT_LOG_FILE}"
    info_msg "--- ${SCRIPT_NAME} execution started ---"
    info_msg "Using script log file: ${SCRIPT_LOG_FILE}"
    [[ "${DEBUG_MODE}" == "true" ]] && info_msg "DEBUG mode has been enabled."

    # Register cleanup trap and acquire lock
    trap cleanup EXIT HUP INT QUIT TERM
    if ! acquire_lock; then critical_exit "Exiting due to failure to acquire script lock."; fi

    # Execute main phases, updating OVERALL_SCRIPT_STATUS if any phase reports non-critical issues.
    initialize_script || OVERALL_SCRIPT_STATUS=1
    # Only proceed to next phase if the previous critical steps were successful (OVERALL_SCRIPT_STATUS is 0)
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

    # Determine final exit code based on OVERALL_SCRIPT_STATUS
    if [[ "${OVERALL_SCRIPT_STATUS}" -eq 0 ]]; then
        info_msg "--- ${SCRIPT_NAME} execution concluded successfully. ---"
        exit 0 # Explicitly exit 0 for full success
    else
        warning_msg "--- ${SCRIPT_NAME} execution concluded, but one or more non-critical errors occurred. Review log. ---"
        exit 1 # Exit 1 if any non-critical errors were tracked by OVERALL_SCRIPT_STATUS
    fi
}

initialize_script() {
    info_msg "Phase: Initializing Script..."
    local phase_status=0 # 0 for success, 1 for non-critical issues in this phase
    source_libraries       # This will critical_exit if a library is not found
    print_header           # print_header is expected from ui.sh

    DOTFILES_SOURCE_DIR="" TEMP_CLONE_DIR="" # Reset/initialize
    local source_dir_output
    source_dir_output="$(determine_source_dir)" # determine_source_dir from git_ops.sh
    read -r DOTFILES_SOURCE_DIR TEMP_CLONE_DIR <<< "${source_dir_output}"

    if [[ -z "${DOTFILES_SOURCE_DIR}" ]]; then
        critical_exit "Dotfiles source directory could not be determined. Cannot proceed."
    fi
    info_msg "Dotfiles source directory identified as: ${DOTFILES_SOURCE_DIR}"
    if [[ -n "${TEMP_CLONE_DIR}" ]]; then
        info_msg "Using temporary clone directory: ${TEMP_CLONE_DIR}"
        verify_core_dependencies || phase_status=1 # verify_core_dependencies from dependencies.sh
    fi

    if [[ "${phase_status}" -eq 0 ]]; then info_msg "Initialization phase completed with no issues reported.";
    else warning_msg "Initialization phase completed with some issues reported."; fi
    return ${phase_status}
}

process_configurations() {
    info_msg "Phase: Processing Configurations..."
    local phase_status=0

    perform_backups || phase_status=1

    # setup_target_directories is critical. If it fails, return immediately.
    if ! setup_target_directories; then
        error_msg "Critical failure during target directory setup. Aborting configuration processing phase."
        return 1 # Indicates failure of this phase
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
        return 0 # Skipped successfully
    fi
    info_msg "Phase: Managing Services (Waybar, Hyprpaper)..."
    local phase_status=0

    manage_daemon "waybar" "waybar" || phase_status=1
    manage_daemon "hyprpaper" "hyprpaper" || phase_status=1

    if [[ "${phase_status}" -eq 0 ]]; then info_msg "Service management phase completed with no issues reported.";
    else warning_msg "Service management phase completed with some issues reported."; fi

    # Final user advice message
    echo # Add a blank line for readability
    info_msg "--------------------------------------------------------------------"
    info_msg "Relevant services have been (re)started (if installed and not skipped)."
    info_msg "If you are running this script outside of an active Hyprland session,"
    info_msg "or if environment variables were changed, it is STRONGLY RECOMMENDED to"
    info_msg "LOG OUT and LOG BACK IN for all changes to take full effect."
    info_msg "--------------------------------------------------------------------"
    return ${phase_status}
}

# --- Script Execution Guard ---
# Ensures main() is called only when the script is executed directly, not when sourced.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

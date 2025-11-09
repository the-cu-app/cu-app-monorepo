#!/bin/bash
# Logging utilities

# Prevent double-sourcing
if [ -n "${CU_CLI_LOGGING_LOADED:-}" ]; then
    return 0
fi
CU_CLI_LOGGING_LOADED=1

# Source colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Log file location
LOG_DIR="${CU_CLI_LOG_DIR:-$HOME/.cu-cli/logs}"
LOG_FILE="$LOG_DIR/cu-cli-$(date +%Y%m%d).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Current log level (can be overridden by environment variable)
CURRENT_LOG_LEVEL=${CU_CLI_LOG_LEVEL:-$LOG_LEVEL_INFO}

# Verbose mode flag
VERBOSE=${VERBOSE:-false}

# Write to log file
log_to_file() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
}

# Debug log
log_debug() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_DEBUG" ] || [ "$VERBOSE" = true ]; then
        echo -e "${GRAY}[DEBUG]${NC} $1"
    fi
    log_to_file "DEBUG" "$1"
}

# Info log
log_info() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_INFO" ]; then
        print_info "$1"
    fi
    log_to_file "INFO" "$1"
}

# Warning log
log_warn() {
    if [ "$CURRENT_LOG_LEVEL" -le "$LOG_LEVEL_WARN" ]; then
        print_warning "$1"
    fi
    log_to_file "WARN" "$1"
}

# Error log
log_error() {
    print_error "$1"
    log_to_file "ERROR" "$1"
}

# Success log
log_success() {
    print_success "$1"
    log_to_file "INFO" "$1"
}

# Command execution with logging
exec_cmd() {
    local cmd="$1"
    local description="${2:-Executing command}"

    log_debug "Executing: $cmd"

    if [ "$VERBOSE" = true ]; then
        print_command "$cmd"
        eval "$cmd"
        local exit_code=$?
    else
        eval "$cmd" >> "$LOG_FILE" 2>&1
        local exit_code=$?
    fi

    if [ $exit_code -eq 0 ]; then
        log_debug "Command succeeded: $description"
        return 0
    else
        log_error "Command failed ($exit_code): $description"
        return $exit_code
    fi
}

# Log a section start
log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Show log file location
show_log_location() {
    echo -e "${DIM}Log file: $LOG_FILE${NC}"
}

# Clean old logs (keep last 7 days)
cleanup_old_logs() {
    find "$LOG_DIR" -name "cu-cli-*.log" -mtime +7 -delete 2>/dev/null
}

# Initialize logging
init_logging() {
    cleanup_old_logs
    log_debug "CU CLI session started"
    log_debug "Log file: $LOG_FILE"
}

#!/bin/bash
# Terminal colors and formatting utilities

# Prevent double-sourcing
if [ -n "${CU_CLI_COLORS_LOADED:-}" ]; then
    return 0
fi
CU_CLI_COLORS_LOADED=1

# Color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m' # No Color

# Text formatting
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly UNDERLINE='\033[4m'

# Icons/Emojis
readonly CHECK="✓"
readonly CROSS="✗"
readonly ARROW="→"
readonly BULLET="•"
readonly ROCKET="🚀"
readonly WRENCH="🔧"
readonly WARNING="⚠️"
readonly INFO="ℹ️"
readonly PACKAGE="📦"
readonly CHART="📊"
readonly LOCK="🔒"
readonly KEY="🔑"

# Print functions
print_error() {
    echo -e "${RED}${CROSS}${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}${CHECK}${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}${WARNING}${NC}  $1"
}

print_info() {
    echo -e "${CYAN}${INFO}${NC}  $1"
}

print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_subheader() {
    echo ""
    echo -e "${BOLD}${CYAN}${ARROW} $1${NC}"
    echo ""
}

print_step() {
    echo -e "${GRAY}${BULLET}${NC} $1"
}

print_command() {
    echo -e "${DIM}  $ $1${NC}"
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local message=$3
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))

    printf "\r${CYAN}["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "]${NC} ${percent}%% - ${message}"

    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Spinner for long operations
show_spinner() {
    local pid=$1
    local message=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "\r${CYAN}%c${NC} ${message}..." "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done

    printf "\r"
}

# Box drawing
print_box() {
    local text="$1"
    local padding=2
    local length=$((${#text} + padding * 2))

    echo -e "${BLUE}┌$(printf '─%.0s' $(seq 1 $length))┐${NC}"
    echo -e "${BLUE}│$(printf ' %.0s' $(seq 1 $padding))${WHITE}${text}$(printf ' %.0s' $(seq 1 $padding))${BLUE}│${NC}"
    echo -e "${BLUE}└$(printf '─%.0s' $(seq 1 $length))┘${NC}"
}

# Table row
print_table_row() {
    local col1="$1"
    local col2="$2"
    local col3="${3:-}"

    printf "%-30s ${GRAY}│${NC} %-30s" "$col1" "$col2"
    if [ -n "$col3" ]; then
        printf " ${GRAY}│${NC} %-20s" "$col3"
    fi
    echo ""
}

# Table header
print_table_header() {
    local col1="$1"
    local col2="$2"
    local col3="${3:-}"

    print_table_row "${BOLD}${col1}${NC}" "${BOLD}${col2}${NC}" "${col3:+${BOLD}${col3}${NC}}"
    printf "%.0s─" {1..80}
    echo ""
}

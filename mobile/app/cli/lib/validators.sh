#!/bin/bash
# Input validation functions

# Source colors
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# Validate CU ID (lowercase alphanumeric, hyphens, underscores)
validate_cu_id() {
    local cu_id="$1"

    if [[ ! "$cu_id" =~ ^[a-z0-9_-]+$ ]]; then
        print_error "Invalid CU ID: '$cu_id'"
        echo "  CU ID must contain only lowercase letters, numbers, hyphens, and underscores"
        return 1
    fi

    if [ ${#cu_id} -lt 2 ]; then
        print_error "CU ID too short: '$cu_id'"
        echo "  CU ID must be at least 2 characters"
        return 1
    fi

    if [ ${#cu_id} -gt 50 ]; then
        print_error "CU ID too long: '$cu_id'"
        echo "  CU ID must be at most 50 characters"
        return 1
    fi

    return 0
}

# Validate hex color (#RRGGBB or #RGB)
validate_color() {
    local color="$1"

    if [[ ! "$color" =~ ^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$ ]]; then
        print_error "Invalid color: '$color'"
        echo "  Color must be in hex format (#RRGGBB or #RGB)"
        return 1
    fi

    return 0
}

# Validate URL
validate_url() {
    local url="$1"

    if [[ ! "$url" =~ ^https?:// ]]; then
        print_error "Invalid URL: '$url'"
        echo "  URL must start with http:// or https://"
        return 1
    fi

    return 0
}

# Validate email
validate_email() {
    local email="$1"

    if [[ ! "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$ ]]; then
        print_error "Invalid email: '$email'"
        return 1
    fi

    return 0
}

# Validate phone number (flexible format)
validate_phone() {
    local phone="$1"

    # Remove all non-digit characters for validation
    local digits_only=$(echo "$phone" | tr -cd '0-9')

    if [ ${#digits_only} -lt 10 ]; then
        print_error "Invalid phone number: '$phone'"
        echo "  Phone number must contain at least 10 digits"
        return 1
    fi

    return 0
}

# Validate routing number (9 digits)
validate_routing_number() {
    local routing="$1"

    if [[ ! "$routing" =~ ^[0-9]{9}$ ]]; then
        print_error "Invalid routing number: '$routing'"
        echo "  Routing number must be exactly 9 digits"
        return 1
    fi

    return 0
}

# Validate domain name
validate_domain() {
    local domain="$1"

    if [[ ! "$domain" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]\.[a-z]{2,}$ ]]; then
        print_error "Invalid domain: '$domain'"
        echo "  Domain must be in format: example.com"
        return 1
    fi

    return 0
}

# Validate required field
validate_required() {
    local value="$1"
    local field_name="$2"

    if [ -z "$value" ]; then
        print_error "$field_name is required"
        return 1
    fi

    return 0
}

# Validate number
validate_number() {
    local value="$1"
    local field_name="$2"
    local min="${3:-}"
    local max="${4:-}"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        print_error "Invalid $field_name: '$value' (must be a number)"
        return 1
    fi

    if [ -n "$min" ] && [ "$value" -lt "$min" ]; then
        print_error "$field_name must be at least $min"
        return 1
    fi

    if [ -n "$max" ] && [ "$value" -gt "$max" ]; then
        print_error "$field_name must be at most $max"
        return 1
    fi

    return 0
}

# Validate yes/no input
validate_yes_no() {
    local value="$1"

    value=$(echo "$value" | tr '[:upper:]' '[:lower:]')

    if [[ "$value" != "y" && "$value" != "yes" && "$value" != "n" && "$value" != "no" ]]; then
        print_error "Invalid input: '$value' (must be yes or no)"
        return 1
    fi

    return 0
}

# Check if command exists
check_command() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &> /dev/null; then
        print_error "Required command not found: $cmd"
        if [ -n "$install_hint" ]; then
            echo "  Install with: $install_hint"
        fi
        return 1
    fi

    return 0
}

# Check if file exists
check_file_exists() {
    local file="$1"

    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        return 1
    fi

    return 0
}

# Check if directory exists
check_dir_exists() {
    local dir="$1"

    if [ ! -d "$dir" ]; then
        print_error "Directory not found: $dir"
        return 1
    fi

    return 0
}

# Validate JSON string
validate_json() {
    local json="$1"

    if ! echo "$json" | jq empty 2>/dev/null; then
        print_error "Invalid JSON"
        return 1
    fi

    return 0
}

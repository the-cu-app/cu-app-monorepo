#!/bin/bash
# Config command - Manage CU configurations

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/cli/lib/colors.sh"
source "$SCRIPT_DIR/cli/lib/logging.sh"
source "$SCRIPT_DIR/cli/lib/validators.sh"
source "$SCRIPT_DIR/cli/lib/supabase.sh"

# Show config help
show_config_help() {
    cat << EOF
${BOLD}${BLUE}cu config${NC} - Manage CU configurations

${BOLD}USAGE:${NC}
  cu config <subcommand> [options]

${BOLD}SUBCOMMANDS:${NC}
  ${CYAN}show${NC}            Show CU configuration
  ${CYAN}update${NC}          Update CU configuration
  ${CYAN}feature-flags${NC}   Manage feature flags
  ${CYAN}branding${NC}        Update branding (colors, logo)
  ${CYAN}delete${NC}          Delete CU configuration

${BOLD}SHOW OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --json              Output in JSON format

${BOLD}UPDATE OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --name <name>       Update CU name
  --domain <domain>   Update domain
  --colors <hex,hex>  Update colors (primary,secondary)
  --logo <url>        Update logo URL
  --routing <number>  Update routing number

${BOLD}FEATURE FLAGS OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --enable <key>      Enable feature
  --disable <key>     Disable feature
  --list              List all feature flags

${BOLD}EXAMPLES:${NC}
  ${DIM}# Show CU configuration${NC}
  ${CYAN}cu config show --cu-id navyfederal${NC}

  ${DIM}# Update branding colors${NC}
  ${CYAN}cu config branding --cu-id navyfederal \\${NC}
    ${CYAN}--colors "#003366,#DCB767"${NC}

  ${DIM}# Enable a feature${NC}
  ${CYAN}cu config feature-flags --cu-id navyfederal \\${NC}
    ${CYAN}--enable ai_coaching${NC}

  ${DIM}# List all feature flags${NC}
  ${CYAN}cu config feature-flags --cu-id navyfederal --list${NC}

EOF
}

# Show CU configuration
cmd_show() {
    local cu_id=""
    local json_output=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --json)
                json_output=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$cu_id" ]; then
        print_error "CU ID required"
        exit 1
    fi

    validate_cu_id "$cu_id" || exit 1

    local cu_data
    cu_data=$(supabase_get_cu "$cu_id" 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_error "CU not found: $cu_id"
        exit 1
    fi

    if [ "$json_output" = true ]; then
        echo "$cu_data" | jq '.'
    else
        print_header "CU Configuration: $cu_id"

        echo ""
        print_table_header "Setting" "Value"
        print_table_row "CU Code" "$(echo "$cu_data" | jq -r '.cu_code')"
        print_table_row "Name" "$(echo "$cu_data" | jq -r '.cu_name')"
        print_table_row "Display Name" "$(echo "$cu_data" | jq -r '.display_name')"
        print_table_row "Email" "$(echo "$cu_data" | jq -r '.email // "N/A"')"
        print_table_row "Phone" "$(echo "$cu_data" | jq -r '.phone // "N/A"')"
        print_table_row "Website" "$(echo "$cu_data" | jq -r '.website // "N/A"')"
        print_table_row "Logo URL" "$(echo "$cu_data" | jq -r '.logo_url // "N/A"')"
        print_table_row "Primary Color" "$(echo "$cu_data" | jq -r '.primary_color')"
        print_table_row "Secondary Color" "$(echo "$cu_data" | jq -r '.secondary_color')"
        print_table_row "Routing Number" "$(echo "$cu_data" | jq -r '.routing_number // "N/A"')"
        print_table_row "Institution Code" "$(echo "$cu_data" | jq -r '.institution_code // "N/A"')"
        print_table_row "Status" "$(echo "$cu_data" | jq -r 'if .is_active then "Active" else "Inactive" end')"
        print_table_row "Created" "$(echo "$cu_data" | jq -r '.created_at')"
        echo ""
    fi
}

# Update CU configuration
cmd_update() {
    local cu_id=""
    local updates=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --name)
                updates+=("\"cu_name\": \"$2\"")
                shift 2
                ;;
            --domain)
                updates+=("\"website\": \"https://$2\"")
                shift 2
                ;;
            --logo)
                updates+=("\"logo_url\": \"$2\"")
                shift 2
                ;;
            --routing)
                updates+=("\"routing_number\": \"$2\"")
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$cu_id" ]; then
        print_error "CU ID required"
        exit 1
    fi

    if [ ${#updates[@]} -eq 0 ]; then
        print_error "No updates specified"
        exit 1
    fi

    log_info "Updating CU: $cu_id"

    # Build update JSON
    local update_json="{$(IFS=, ; echo "${updates[*]}")}"

    local result
    result=$(supabase_update_cu "$cu_id" "$update_json")

    if [ $? -eq 0 ]; then
        log_success "CU updated successfully"
        cmd_show --cu-id "$cu_id"
    else
        log_error "Failed to update CU"
        exit 1
    fi
}

# Manage feature flags
cmd_feature_flags() {
    local cu_id=""
    local enable_feature=""
    local disable_feature=""
    local list_flags=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --enable)
                enable_feature="$2"
                shift 2
                ;;
            --disable)
                disable_feature="$2"
                shift 2
                ;;
            --list)
                list_flags=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$cu_id" ]; then
        print_error "CU ID required"
        exit 1
    fi

    validate_cu_id "$cu_id" || exit 1

    if [ "$list_flags" = true ]; then
        print_header "Feature Flags: $cu_id"

        local flags
        flags=$(supabase_get_feature_flags "$cu_id" 2>/dev/null)

        if [ $? -eq 0 ]; then
            local count
            count=$(echo "$flags" | jq length)

            if [ "$count" -eq 0 ]; then
                log_warn "No feature flags configured"
                exit 0
            fi

            echo ""
            print_table_header "Feature" "Status" "Config"

            echo "$flags" | jq -r '.[] | [.feature_key, (if .is_enabled then "Enabled" else "Disabled" end), (.config | tostring)] | @tsv' | while IFS=$'\t' read -r key status config; do
                if [ "$status" = "Enabled" ]; then
                    status="${GREEN}●${NC} Enabled"
                else
                    status="${RED}●${NC} Disabled"
                fi
                print_table_row "$key" "$status" "$config"
            done

            echo ""
        else
            log_error "Failed to fetch feature flags"
            exit 1
        fi
    elif [ -n "$enable_feature" ]; then
        log_info "Enabling feature: $enable_feature"
        supabase_create_feature_flag "$cu_id" "$enable_feature" true "{}"
        log_success "Feature enabled: $enable_feature"
    elif [ -n "$disable_feature" ]; then
        log_error "Disable feature not yet implemented"
        exit 1
    else
        print_error "No action specified (use --list, --enable, or --disable)"
        exit 1
    fi
}

# Update branding
cmd_branding() {
    local cu_id=""
    local colors=""
    local logo=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --colors)
                colors="$2"
                shift 2
                ;;
            --logo)
                logo="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$cu_id" ]; then
        print_error "CU ID required"
        exit 1
    fi

    local updates=()

    if [ -n "$colors" ]; then
        IFS=',' read -r primary secondary <<< "$colors"

        validate_color "$primary" || exit 1
        validate_color "$secondary" || exit 1

        updates+=("\"primary_color\": \"$primary\"")
        updates+=("\"secondary_color\": \"$secondary\"")
    fi

    if [ -n "$logo" ]; then
        validate_url "$logo" || exit 1
        updates+=("\"logo_url\": \"$logo\"")
    fi

    if [ ${#updates[@]} -eq 0 ]; then
        print_error "No branding updates specified"
        exit 1
    fi

    log_info "Updating branding for: $cu_id"

    local update_json="{$(IFS=, ; echo "${updates[*]}")}"

    local result
    result=$(supabase_update_cu "$cu_id" "$update_json")

    if [ $? -eq 0 ]; then
        log_success "Branding updated successfully"
        cmd_show --cu-id "$cu_id"
    else
        log_error "Failed to update branding"
        exit 1
    fi
}

# Delete CU
cmd_delete() {
    local cu_id=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$cu_id" ]; then
        print_error "CU ID required"
        exit 1
    fi

    print_warning "You are about to DELETE CU: $cu_id"
    print_warning "This will remove all associated data (FAQs, feature flags, etc.)"
    echo ""

    if ! confirm "Are you ABSOLUTELY sure you want to delete this CU?" "n"; then
        log_info "Delete cancelled"
        exit 0
    fi

    log_error "Delete command not yet implemented"
    exit 1
}

# Main config command
cmd_config() {
    if [ $# -eq 0 ]; then
        show_config_help
        exit 0
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        show)
            cmd_show "$@"
            ;;
        update)
            cmd_update "$@"
            ;;
        feature-flags)
            cmd_feature_flags "$@"
            ;;
        branding)
            cmd_branding "$@"
            ;;
        delete)
            cmd_delete "$@"
            ;;
        -h|--help)
            show_config_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            show_config_help
            exit 1
            ;;
    esac
}

#!/bin/bash
# Subscription command - Manage CU subscriptions and licensing

# Get project root directory (go up from commands -> cli -> root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLI_DIR="$SCRIPT_DIR/cli"

# Source libraries (they handle double-sourcing protection)
source "$CLI_DIR/lib/colors.sh"
source "$CLI_DIR/lib/logging.sh"
source "$CLI_DIR/lib/validators.sh"
source "$CLI_DIR/lib/supabase.sh"
source "$CLI_DIR/lib/licensing.sh"

# Show subscription help
show_subscription_help() {
    cat << EOF
${BOLD}${BLUE}cu subscription${NC} - Manage subscriptions and licensing

${BOLD}USAGE:${NC}
  cu subscription <subcommand> [options]

${BOLD}SUBCOMMANDS:${NC}
  ${CYAN}status${NC}      Show subscription status and online indicator
  ${CYAN}activate${NC}    Activate a subscription for a CU
  ${CYAN}plans${NC}       List available subscription plans
  ${CYAN}upgrade${NC}     Upgrade to a different plan
  ${CYAN}usage${NC}       View usage metrics
  ${CYAN}heartbeat${NC}   Send heartbeat to show CU is online

${BOLD}STATUS OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --json              Output in JSON format

${BOLD}ACTIVATE OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --plan <code>       Plan code (starter, professional, enterprise, custom)
  --trial             Activate as trial (14 days)
  --billing <cycle>   Billing cycle: monthly, annual (default: monthly)

${BOLD}USAGE OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --month <YYYY-MM>   Month to view (default: current month)

${BOLD}EXAMPLES:${NC}
  ${DIM}# Show subscription status${NC}
  ${CYAN}cu subscription status --cu-id navyfederal${NC}

  ${DIM}# List available plans${NC}
  ${CYAN}cu subscription plans${NC}

  ${DIM}# Activate subscription${NC}
  ${CYAN}cu subscription activate --cu-id navyfederal \\${NC}
    ${CYAN}--plan professional --billing annual${NC}

  ${DIM}# Activate trial${NC}
  ${CYAN}cu subscription activate --cu-id navyfederal \\${NC}
    ${CYAN}--plan professional --trial${NC}

  ${DIM}# View usage metrics${NC}
  ${CYAN}cu subscription usage --cu-id navyfederal${NC}

  ${DIM}# Send heartbeat${NC}
  ${CYAN}cu subscription heartbeat --cu-id navyfederal${NC}

EOF
}

# Show subscription status
cmd_status() {
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

    if [ "$json_output" = true ]; then
        get_cu_subscription "$cu_id"
    else
        show_subscription_status "$cu_id"
    fi
}

# List subscription plans
cmd_plans() {
    print_header "Available Subscription Plans"

    local plans
    plans=$(list_subscription_plans)

    if [ $? -ne 0 ]; then
        log_error "Failed to fetch subscription plans"
        exit 1
    fi

    echo ""
    print_table_header "Plan" "Price (Monthly)" "Price (Annual)" "Max Members"

    echo "$plans" | jq -r '.[] | [.plan_name, "$\(.monthly_price)/mo", "$\(.annual_price)/yr", (.max_members // "Unlimited")] | @tsv' | while IFS=$'\t' read -r name monthly annual members; do
        print_table_row "$name" "$monthly" "$annual" "$members"
    done

    echo ""
    log_info "To activate a plan, run:"
    echo "  ${CYAN}cu subscription activate --cu-id <cu-id> --plan <plan-code>${NC}"
    echo ""
}

# Activate subscription
cmd_activate() {
    local cu_id=""
    local plan_code=""
    local is_trial=false
    local billing_cycle="monthly"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --plan)
                plan_code="$2"
                shift 2
                ;;
            --trial)
                is_trial=true
                shift
                ;;
            --billing)
                billing_cycle="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$cu_id" ] || [ -z "$plan_code" ]; then
        print_error "CU ID and plan are required"
        show_subscription_help
        exit 1
    fi

    validate_cu_id "$cu_id" || exit 1

    # Check if subscription already exists
    if get_cu_subscription "$cu_id" > /dev/null 2>&1; then
        print_error "CU already has an active subscription"
        echo ""
        echo "To upgrade, run:"
        echo "  ${CYAN}cu subscription upgrade --cu-id $cu_id --plan $plan_code${NC}"
        exit 1
    fi

    print_header "Activating Subscription"

    log_info "CU: $cu_id"
    log_info "Plan: $plan_code"
    log_info "Billing: $billing_cycle"

    if [ "$is_trial" = true ]; then
        log_info "Type: Trial (14 days)"
    fi

    echo ""
    if ! confirm "Activate this subscription?" "y"; then
        log_warn "Activation cancelled"
        exit 0
    fi

    log_info "Creating subscription..."

    local license_type="production"
    if [ "$is_trial" = true ]; then
        license_type="trial"
    fi

    local result
    result=$(create_subscription "$cu_id" "$plan_code" "$license_type" "$billing_cycle")

    if [ $? -eq 0 ]; then
        local license_key
        license_key=$(echo "$result" | jq -r '.license_key')

        print_header "Subscription Activated! 🎉"

        echo ""
        echo "${BOLD}${GREEN}✓${NC} Subscription successfully activated${NC}"
        echo ""
        echo "${BOLD}License Key:${NC}"
        echo "  ${CYAN}$license_key${NC}"
        echo ""
        echo "${DIM}Save this license key - you'll need it to activate your apps${NC}"
        echo ""

        # Send first heartbeat
        log_info "Sending initial heartbeat..."
        send_heartbeat "$cu_id" "cli" "1.0.0" "production" > /dev/null 2>&1

        echo ""
        echo "Next steps:"
        echo "  1. View status: ${CYAN}cu subscription status --cu-id $cu_id${NC}"
        echo "  2. Deploy app: ${CYAN}cu deploy --cu-id $cu_id --target all${NC}"
        echo ""
    else
        log_error "Failed to activate subscription"
        exit 1
    fi
}

# View usage metrics
cmd_usage() {
    local cu_id=""
    local month=$(date +%Y-%m)

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --month)
                month="$2"
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

    validate_cu_id "$cu_id" || exit 1

    print_header "Usage Metrics: $cu_id ($month)"

    # Get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") || exit 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Get monthly usage
    local usage
    usage=$(supabase_request "GET" "cu_monthly_usage?cu_id=eq.$cu_uuid&month=eq.${month}-01")

    if echo "$usage" | jq -e '.[0]' > /dev/null 2>&1; then
        local data
        data=$(echo "$usage" | jq '.[0]')

        echo ""
        print_table_header "Metric" "Usage"
        print_table_row "Total Members" "$(echo "$data" | jq -r '.total_members')"
        print_table_row "Total Transactions" "$(echo "$data" | jq -r '.total_transactions')"
        print_table_row "Total API Calls" "$(echo "$data" | jq -r '.total_api_calls')"
        print_table_row "Storage Used" "$(echo "$data" | jq -r '.total_storage_gb') GB"
        print_table_row "Bandwidth Used" "$(echo "$data" | jq -r '.total_bandwidth_gb') GB"
        print_table_row "FAQs Generated" "$(echo "$data" | jq -r '.total_faqs_generated')"
        print_table_row "AI Cost" "\$$(echo "$data" | jq -r '.total_ai_cost')"

        echo ""
        echo "${BOLD}Billing:${NC}"
        print_table_row "  Subscription" "\$$(echo "$data" | jq -r '.base_subscription_charge')"
        print_table_row "  Overages" "\$$(echo "$data" | jq -r '.overage_charges')"
        print_table_row "  Total" "${BOLD}\$$(echo "$data" | jq -r '.total_charges')${NC}"

        echo ""
    else
        log_warn "No usage data found for $month"
        echo ""
        echo "Usage data is generated at the end of each month"
    fi
}

# Send heartbeat
cmd_heartbeat() {
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

    validate_cu_id "$cu_id" || exit 1

    log_info "Sending heartbeat for $cu_id..."

    if send_heartbeat "$cu_id" "cli" "1.0.0" "production"; then
        log_success "Heartbeat sent - CU is now ONLINE"
    else
        log_error "Failed to send heartbeat"
        exit 1
    fi
}

# Upgrade subscription (TODO)
cmd_upgrade() {
    log_error "Upgrade command not yet implemented"
    exit 1
}

# Main subscription command
cmd_subscription() {
    if [ $# -eq 0 ]; then
        show_subscription_help
        exit 0
    fi

    # Check prerequisites
    check_command "jq" "brew install jq" || exit 1
    check_supabase_config || exit 1

    local subcommand="$1"
    shift

    case "$subcommand" in
        status)
            cmd_status "$@"
            ;;
        plans)
            cmd_plans "$@"
            ;;
        activate)
            cmd_activate "$@"
            ;;
        upgrade)
            cmd_upgrade "$@"
            ;;
        usage)
            cmd_usage "$@"
            ;;
        heartbeat)
            cmd_heartbeat "$@"
            ;;
        -h|--help)
            show_subscription_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            show_subscription_help
            exit 1
            ;;
    esac
}

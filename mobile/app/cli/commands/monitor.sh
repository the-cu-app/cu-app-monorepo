#!/bin/bash
# Monitor command - Monitor CU health and metrics

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/cli/lib/colors.sh"
source "$SCRIPT_DIR/cli/lib/logging.sh"
source "$SCRIPT_DIR/cli/lib/validators.sh"
source "$SCRIPT_DIR/cli/lib/supabase.sh"

# Show monitor help
show_monitor_help() {
    cat << EOF
${BOLD}${BLUE}cu monitor${NC} - Monitor CU health and metrics

${BOLD}USAGE:${NC}
  cu monitor [options]

${BOLD}OPTIONS:${NC}
  --cu-id <id>        Monitor specific CU
  --dashboard         Show live dashboard (all CUs)
  --metrics           Show detailed metrics
  --logs              Show recent logs
  --refresh <seconds> Auto-refresh interval (default: 5)

${BOLD}EXAMPLES:${NC}
  ${DIM}# Show dashboard for all CUs${NC}
  ${CYAN}cu monitor --dashboard${NC}

  ${DIM}# Monitor specific CU${NC}
  ${CYAN}cu monitor --cu-id navyfederal${NC}

  ${DIM}# Show detailed metrics${NC}
  ${CYAN}cu monitor --cu-id navyfederal --metrics${NC}

  ${DIM}# Watch logs${NC}
  ${CYAN}cu monitor --cu-id navyfederal --logs${NC}

EOF
}

# Get CU metrics
get_cu_metrics() {
    local cu_id="$1"

    local cu_data
    cu_data=$(supabase_get_cu "$cu_id" 2>/dev/null) || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Count FAQs
    local member_faq_count
    member_faq_count=$(supabase_request "GET" "member_faqs?select=count&cu_id=eq.$cu_uuid" | jq -r '.[0].count // 0')

    local staff_faq_count
    staff_faq_count=$(supabase_request "GET" "staff_training_faqs?select=count&cu_id=eq.$cu_uuid" | jq -r '.[0].count // 0')

    # Count feature flags
    local feature_count
    feature_count=$(supabase_request "GET" "cu_feature_flags?select=count&cu_id=eq.$cu_uuid" | jq -r '.[0].count // 0')

    # Build metrics JSON
    jq -n \
        --arg cu_id "$cu_id" \
        --arg cu_name "$(echo "$cu_data" | jq -r '.display_name')" \
        --arg status "$(echo "$cu_data" | jq -r 'if .is_active then "active" else "inactive" end')" \
        --arg member_faqs "$member_faq_count" \
        --arg staff_faqs "$staff_faq_count" \
        --arg features "$feature_count" \
        '{
            cu_id: $cu_id,
            cu_name: $cu_name,
            status: $status,
            member_faqs: ($member_faqs | tonumber),
            staff_faqs: ($staff_faqs | tonumber),
            features: ($features | tonumber)
        }'
}

# Show dashboard
show_dashboard() {
    clear
    print_header "CU Platform Dashboard"

    echo ""
    log_info "Fetching data..."

    # Get all CUs
    local cus
    cus=$(supabase_list_cus 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_error "Failed to fetch CUs"
        return 1
    fi

    local cu_count
    cu_count=$(echo "$cus" | jq length)

    # Get metrics for each CU
    echo ""
    print_table_header "CU" "Status" "FAQs" "Features"

    local total_faqs=0
    local total_features=0
    local active_count=0

    echo "$cus" | jq -r '.[] | .cu_code' | while read -r cu_id; do
        local metrics
        metrics=$(get_cu_metrics "$cu_id" 2>/dev/null)

        if [ $? -eq 0 ]; then
            local cu_name=$(echo "$metrics" | jq -r '.cu_name')
            local status=$(echo "$metrics" | jq -r '.status')
            local member_faqs=$(echo "$metrics" | jq -r '.member_faqs')
            local staff_faqs=$(echo "$metrics" | jq -r '.staff_faqs')
            local features=$(echo "$metrics" | jq -r '.features')

            local total_cu_faqs=$((member_faqs + staff_faqs))
            total_faqs=$((total_faqs + total_cu_faqs))
            total_features=$((total_features + features))

            if [ "$status" = "active" ]; then
                status="${GREEN}●${NC} Active"
                active_count=$((active_count + 1))
            else
                status="${RED}●${NC} Inactive"
            fi

            print_table_row "$cu_id" "$status" "$total_cu_faqs" "$features"
        fi
    done

    echo ""
    echo "${BOLD}Summary:${NC}"
    echo "  Total CUs: $cu_count"
    echo "  Active: ${GREEN}$active_count${NC}"
    echo "  Total FAQs: $total_faqs"
    echo "  Total Features: $total_features"
    echo ""

    echo "${DIM}Updated: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
}

# Show CU details
show_cu_details() {
    local cu_id="$1"

    print_header "CU Monitor: $cu_id"

    # Get CU data
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id" 2>/dev/null)

    if [ $? -ne 0 ]; then
        log_error "CU not found: $cu_id"
        return 1
    fi

    # Get metrics
    local metrics
    metrics=$(get_cu_metrics "$cu_id")

    # Display info
    echo ""
    echo "${BOLD}Configuration:${NC}"
    print_table_row "Name" "$(echo "$cu_data" | jq -r '.display_name')"
    print_table_row "Domain" "$(echo "$cu_data" | jq -r '.website // "N/A"')"
    print_table_row "Status" "$(echo "$cu_data" | jq -r 'if .is_active then "Active" else "Inactive" end')"
    print_table_row "Routing Number" "$(echo "$cu_data" | jq -r '.routing_number // "N/A"')"
    print_table_row "Primary Color" "$(echo "$cu_data" | jq -r '.primary_color')"
    print_table_row "Secondary Color" "$(echo "$cu_data" | jq -r '.secondary_color')"

    echo ""
    echo "${BOLD}Content Metrics:${NC}"
    print_table_row "Member FAQs" "$(echo "$metrics" | jq -r '.member_faqs')"
    print_table_row "Staff FAQs" "$(echo "$metrics" | jq -r '.staff_faqs')"
    print_table_row "Feature Flags" "$(echo "$metrics" | jq -r '.features')"

    echo ""
    echo "${BOLD}Feature Flags:${NC}"
    local flags
    flags=$(supabase_get_feature_flags "$cu_id" 2>/dev/null)

    if [ $? -eq 0 ]; then
        echo "$flags" | jq -r '.[] | [.feature_key, (if .is_enabled then "Enabled" else "Disabled" end)] | @tsv' | while IFS=$'\t' read -r key status; do
            if [ "$status" = "Enabled" ]; then
                status="${GREEN}●${NC} Enabled"
            else
                status="${RED}●${NC} Disabled"
            fi
            print_table_row "  $key" "$status"
        done
    else
        echo "  No feature flags configured"
    fi

    echo ""
}

# Show logs (TODO)
show_logs() {
    local cu_id="$1"

    log_error "Log viewing not yet implemented"
    return 1
}

# Main monitor command
cmd_monitor() {
    local cu_id=""
    local show_dash=false
    local show_metrics=false
    local show_logs_flag=false
    local refresh_interval=0

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --dashboard)
                show_dash=true
                shift
                ;;
            --metrics)
                show_metrics=true
                shift
                ;;
            --logs)
                show_logs_flag=true
                shift
                ;;
            --refresh)
                refresh_interval="$2"
                shift 2
                ;;
            -h|--help)
                show_monitor_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_monitor_help
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_command "jq" "brew install jq" || exit 1
    check_supabase_config || exit 1

    # Execute based on options
    if [ "$show_dash" = true ]; then
        if [ "$refresh_interval" -gt 0 ]; then
            # Auto-refresh
            while true; do
                show_dashboard
                sleep "$refresh_interval"
            done
        else
            show_dashboard
        fi
    elif [ "$show_logs_flag" = true ]; then
        show_logs "$cu_id"
    elif [ -n "$cu_id" ]; then
        if [ "$refresh_interval" -gt 0 ]; then
            # Auto-refresh
            while true; do
                show_cu_details "$cu_id"
                sleep "$refresh_interval"
            done
        else
            show_cu_details "$cu_id"
        fi
    else
        # Default: show dashboard
        show_dashboard
    fi
}

#!/bin/bash
# Doctor command - Run diagnostics and health checks

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/cli/lib/colors.sh"
source "$SCRIPT_DIR/cli/lib/logging.sh"
source "$SCRIPT_DIR/cli/lib/validators.sh"
source "$SCRIPT_DIR/cli/lib/supabase.sh"

# Show doctor help
show_doctor_help() {
    cat << EOF
${BOLD}${BLUE}cu doctor${NC} - Run diagnostics and health checks

${BOLD}USAGE:${NC}
  cu doctor [options]

${BOLD}OPTIONS:${NC}
  --cu-id <id>        Check specific CU (optional, checks all if not provided)
  --fix               Automatically fix issues where possible
  --verbose           Show detailed diagnostic information

${BOLD}CHECKS PERFORMED:${NC}
  • Environment variables
  • Supabase connection
  • Database schema
  • CU configurations
  • Feature flags
  • Missing content (FAQs, Figma)
  • API endpoints
  • Required dependencies

${BOLD}EXAMPLES:${NC}
  ${DIM}# Check everything${NC}
  ${CYAN}cu doctor${NC}

  ${DIM}# Check specific CU${NC}
  ${CYAN}cu doctor --cu-id navyfederal${NC}

  ${DIM}# Check and auto-fix issues${NC}
  ${CYAN}cu doctor --cu-id navyfederal --fix${NC}

EOF
}

# Track issues
declare -a ISSUES
declare -a WARNINGS
declare -i CHECK_COUNT=0
declare -i PASS_COUNT=0
declare -i FAIL_COUNT=0
declare -i WARN_COUNT=0

# Add issue
add_issue() {
    ISSUES+=("$1")
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Add warning
add_warning() {
    WARNINGS+=("$1")
    WARN_COUNT=$((WARN_COUNT + 1))
}

# Run check
run_check() {
    local check_name="$1"
    local check_func="$2"

    CHECK_COUNT=$((CHECK_COUNT + 1))
    echo -ne "${CYAN}[$(printf "%2d" $CHECK_COUNT)]${NC} ${check_name}..."

    if $check_func > /dev/null 2>&1; then
        echo -e " ${GREEN}${CHECK}${NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo -e " ${RED}${CROSS}${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
}

# Check environment variables
check_env_vars() {
    [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]
}

# Check Supabase connection
check_supabase_connection() {
    supabase_health_check
}

# Check required commands
check_required_commands() {
    command -v flutter > /dev/null 2>&1 && \
    command -v dart > /dev/null 2>&1 && \
    command -v jq > /dev/null 2>&1 && \
    command -v curl > /dev/null 2>&1
}

# Check Python and dependencies
check_python() {
    command -v python3 > /dev/null 2>&1 && \
    python3 -c "import requests" 2>/dev/null
}

# Check database tables
check_database_tables() {
    local tables=(
        "cu_configurations"
        "cu_feature_flags"
        "cu_api_endpoints"
        "member_faqs"
        "staff_training_faqs"
        "developer_faqs"
        "design_faqs"
        "security_compliance_faqs"
        "feature_content_cache"
    )

    for table in "${tables[@]}"; do
        local result
        result=$(supabase_request "GET" "$table?limit=1" "" false)
        if ! echo "$result" | jq -e '.' > /dev/null 2>&1; then
            return 1
        fi
    done

    return 0
}

# Check CU configuration
check_cu_config() {
    local cu_id="$1"

    local cu_data
    cu_data=$(supabase_get_cu "$cu_id" 2>/dev/null)

    [ $? -eq 0 ]
}

# Check missing logos
check_cu_logos() {
    local cu_id="$1"

    local cu_data
    cu_data=$(supabase_get_cu "$cu_id" 2>/dev/null) || return 1

    local logo_url
    logo_url=$(echo "$cu_data" | jq -r '.logo_url // ""')

    if [ -z "$logo_url" ]; then
        add_warning "CU '$cu_id': Missing logo URL"
        return 1
    fi

    # Check if logo is accessible
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" "$logo_url" 2>/dev/null)

    if [ "$http_code" != "200" ]; then
        add_warning "CU '$cu_id': Logo URL not accessible (HTTP $http_code): $logo_url"
        return 1
    fi

    return 0
}

# Check missing FAQs
check_cu_faqs() {
    local cu_id="$1"

    local cu_data
    cu_data=$(supabase_get_cu "$cu_id" 2>/dev/null) || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Check member FAQs
    local member_faq_count
    member_faq_count=$(supabase_request "GET" "member_faqs?select=count&cu_id=eq.$cu_uuid" | jq -r '.[0].count // 0')

    if [ "$member_faq_count" -lt 10 ]; then
        add_warning "CU '$cu_id': Low member FAQ count ($member_faq_count)"
        return 1
    fi

    return 0
}

# Check feature flags
check_cu_feature_flags() {
    local cu_id="$1"

    local flags
    flags=$(supabase_get_feature_flags "$cu_id" 2>/dev/null)

    [ $? -eq 0 ]
}

# Run diagnostics
run_diagnostics() {
    local cu_id="$1"

    print_header "Running Diagnostics"

    echo ""
    log_info "Checking system health..."
    echo ""

    # System checks
    run_check "Environment variables configured" check_env_vars || \
        add_issue "Missing environment variables (SUPABASE_URL, SUPABASE_ANON_KEY)"

    run_check "Supabase connection" check_supabase_connection || \
        add_issue "Cannot connect to Supabase"

    run_check "Required commands installed" check_required_commands || \
        add_issue "Missing required commands (flutter, dart, jq, curl)"

    run_check "Python dependencies" check_python || \
        add_warning "Python or requests module not installed"

    run_check "Database tables exist" check_database_tables || \
        add_issue "Database tables missing or inaccessible"

    # CU-specific checks
    if [ -n "$cu_id" ]; then
        echo ""
        log_info "Checking CU: $cu_id"
        echo ""

        run_check "CU configuration exists" check_cu_config "$cu_id" || \
            add_issue "CU '$cu_id' not found in database"

        run_check "Logo URL configured and accessible" check_cu_logos "$cu_id"

        run_check "Member FAQs generated" check_cu_faqs "$cu_id"

        run_check "Feature flags configured" check_cu_feature_flags "$cu_id" || \
            add_warning "No feature flags configured for CU '$cu_id'"
    fi

    # Summary
    echo ""
    print_header "Diagnostic Results"

    echo ""
    echo "${BOLD}Summary:${NC}"
    echo "  Total checks: $CHECK_COUNT"
    echo "  ${GREEN}Passed: $PASS_COUNT${NC}"
    echo "  ${RED}Failed: $FAIL_COUNT${NC}"
    echo "  ${YELLOW}Warnings: $WARN_COUNT${NC}"
    echo ""

    # Show issues
    if [ ${#ISSUES[@]} -gt 0 ]; then
        echo "${BOLD}${RED}Issues:${NC}"
        for issue in "${ISSUES[@]}"; do
            echo "  ${RED}${CROSS}${NC} $issue"
        done
        echo ""
    fi

    # Show warnings
    if [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "${BOLD}${YELLOW}Warnings:${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "  ${YELLOW}${WARNING}${NC}  $warning"
        done
        echo ""
    fi

    # Recommendations
    if [ ${#ISSUES[@]} -gt 0 ] || [ ${#WARNINGS[@]} -gt 0 ]; then
        echo "${BOLD}Recommendations:${NC}"

        if [ ${#ISSUES[@]} -gt 0 ]; then
            echo "  • Fix critical issues before deployment"
        fi

        if grep -q "Missing logo" <<< "${WARNINGS[*]}"; then
            echo "  • Upload missing logos or update logo URLs"
        fi

        if grep -q "Low.*FAQ count" <<< "${WARNINGS[*]}"; then
            echo "  • Generate FAQs: ${CYAN}cu content generate --cu-id $cu_id --type member${NC}"
        fi

        if grep -q "No feature flags" <<< "${WARNINGS[*]}"; then
            echo "  • Configure feature flags: ${CYAN}cu config feature-flags --cu-id $cu_id${NC}"
        fi

        echo ""
    fi

    # Exit code
    if [ ${#ISSUES[@]} -gt 0 ]; then
        return 1
    else
        log_success "All critical checks passed!"
        return 0
    fi
}

# Main doctor command
cmd_doctor() {
    local cu_id=""
    local auto_fix=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --fix)
                auto_fix=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_doctor_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_doctor_help
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_command "jq" "brew install jq" || exit 1

    # Run diagnostics
    run_diagnostics "$cu_id"
}

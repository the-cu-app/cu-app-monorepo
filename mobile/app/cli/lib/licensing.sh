#!/bin/bash
# Licensing and subscription management

# Prevent double-sourcing
if [ -n "${CU_CLI_LICENSING_LOADED:-}" ]; then
    return 0
fi
CU_CLI_LICENSING_LOADED=1

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/logging.sh"
source "$SCRIPT_DIR/supabase.sh"

# Validate license key
validate_license() {
    local license_key="$1"

    check_supabase_config || return 1

    log_debug "Validating license: $license_key"

    # Call Supabase function to validate
    local response
    response=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/validate_license" \
        -H "apikey: $SUPABASE_ANON_KEY" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"p_license_key\": \"$license_key\"}")

    echo "$response"
}

# Check if license is valid
check_license_valid() {
    local license_key="$1"

    local result
    result=$(validate_license "$license_key")

    local is_valid
    is_valid=$(echo "$result" | jq -r '.valid // false')

    [ "$is_valid" = "true" ]
}

# Get active subscription for CU
get_cu_subscription() {
    local cu_id="$1"

    # Get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Get active subscription
    local response
    response=$(supabase_request "GET" "cu_subscriptions?cu_id=eq.$cu_uuid&status=eq.active&order=current_period_end.desc&limit=1")

    if echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo "$response" | jq '.[0]'
        return 0
    else
        return 1
    fi
}

# Get subscription plan details
get_subscription_plan() {
    local plan_id="$1"

    local response
    response=$(supabase_request "GET" "subscription_plans?id=eq.$plan_id")

    if echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo "$response" | jq '.[0]'
        return 0
    else
        return 1
    fi
}

# List all subscription plans
list_subscription_plans() {
    local response
    response=$(supabase_request "GET" "subscription_plans?is_active=eq.true&is_public=eq.true&order=monthly_price.asc")

    echo "$response"
}

# Create subscription for CU
create_subscription() {
    local cu_id="$1"
    local plan_code="$2"
    local license_type="${3:-production}"
    local billing_cycle="${4:-monthly}"

    # Get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Get plan
    local plan
    plan=$(supabase_request "GET" "subscription_plans?plan_code=eq.$plan_code")

    if ! echo "$plan" | jq -e '.[0]' > /dev/null 2>&1; then
        log_error "Plan not found: $plan_code"
        return 1
    fi

    local plan_id
    plan_id=$(echo "$plan" | jq -r '.[0].id')

    # Generate license key
    local license_key
    license_key=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/generate_license_key" \
        -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d '{}')

    license_key=$(echo "$license_key" | jq -r '.')

    # Calculate period end
    local period_end
    if [ "$billing_cycle" = "annual" ]; then
        period_end=$(date -v+1y +%Y-%m-%d 2>/dev/null || date -d "+1 year" +%Y-%m-%d)
    else
        period_end=$(date -v+1m +%Y-%m-%d 2>/dev/null || date -d "+1 month" +%Y-%m-%d)
    fi

    # Create subscription
    local subscription_data
    subscription_data=$(jq -n \
        --arg cu_id "$cu_uuid" \
        --arg plan_id "$plan_id" \
        --arg license_key "$license_key" \
        --arg license_type "$license_type" \
        --arg billing_cycle "$billing_cycle" \
        --arg period_end "$period_end" \
        '{
            cu_id: $cu_id,
            plan_id: $plan_id,
            license_key: $license_key,
            license_type: $license_type,
            billing_cycle: $billing_cycle,
            status: "active",
            current_period_start: (now | todate),
            current_period_end: $period_end
        }')

    local response
    response=$(supabase_request "POST" "cu_subscriptions" "$subscription_data" true)

    if echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo "$response" | jq '.[0]'
        return 0
    else
        log_error "Failed to create subscription"
        return 1
    fi
}

# Send heartbeat
send_heartbeat() {
    local cu_id="$1"
    local platform="${2:-cli}"
    local version="${3:-1.0.0}"
    local environment="${4:-production}"

    # Get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Call heartbeat function
    local response
    response=$(curl -s -X POST "${SUPABASE_URL}/rest/v1/rpc/update_heartbeat" \
        -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"p_cu_id\": \"$cu_uuid\",
            \"p_environment\": \"$environment\",
            \"p_platform\": \"$platform\",
            \"p_version\": \"$version\",
            \"p_active_users\": 0,
            \"p_health_status\": \"healthy\"
        }")

    if echo "$response" | jq -e '.' > /dev/null 2>&1; then
        log_debug "Heartbeat sent for CU: $cu_id"
        return 0
    else
        log_warn "Failed to send heartbeat"
        return 1
    fi
}

# Log usage event
log_usage() {
    local cu_id="$1"
    local event_type="$2"
    local event_action="${3:-}"
    local metadata="${4:-{}}"

    # Get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") 2>/dev/null || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    # Create usage log
    local log_data
    log_data=$(jq -n \
        --arg cu_id "$cu_uuid" \
        --arg event_type "$event_type" \
        --arg event_action "$event_action" \
        --arg source "cli" \
        --arg source_version "1.0.0" \
        --argjson metadata "$metadata" \
        '{
            cu_id: $cu_id,
            event_type: $event_type,
            event_action: $event_action,
            source: $source,
            source_version: $source_version,
            event_metadata: $metadata
        }')

    supabase_request "POST" "cu_usage_logs" "$log_data" false > /dev/null 2>&1

    return 0
}

# Show subscription status
show_subscription_status() {
    local cu_id="$1"

    local subscription
    subscription=$(get_cu_subscription "$cu_id" 2>/dev/null)

    if [ $? -ne 0 ]; then
        print_warning "No active subscription found for CU: $cu_id"
        return 1
    fi

    local plan_id
    plan_id=$(echo "$subscription" | jq -r '.plan_id')

    local plan
    plan=$(get_subscription_plan "$plan_id")

    echo ""
    print_header "Subscription Status: $cu_id"

    echo ""
    print_table_header "Setting" "Value"
    print_table_row "License Key" "$(echo "$subscription" | jq -r '.license_key')"
    print_table_row "Plan" "$(echo "$plan" | jq -r '.plan_name')"
    print_table_row "Status" "${GREEN}$(echo "$subscription" | jq -r '.status')${NC}"
    print_table_row "Type" "$(echo "$subscription" | jq -r '.license_type')"
    print_table_row "Billing Cycle" "$(echo "$subscription" | jq -r '.billing_cycle')"
    print_table_row "Current Period" "$(echo "$subscription" | jq -r '.current_period_start') to $(echo "$subscription" | jq -r '.current_period_end')"
    print_table_row "Last Heartbeat" "$(echo "$subscription" | jq -r '.last_heartbeat_at // "Never"')"

    echo ""
    echo "${BOLD}Plan Limits:${NC}"
    print_table_row "  Max Members" "$(echo "$plan" | jq -r '.max_members // "Unlimited"')"
    print_table_row "  Max Transactions/Month" "$(echo "$plan" | jq -r '.max_transactions_per_month // "Unlimited"')"
    print_table_row "  Max API Calls/Month" "$(echo "$plan" | jq -r '.max_api_calls_per_month // "Unlimited"')"

    echo ""
    echo "${BOLD}Features:${NC}"
    echo "$plan" | jq -r '.features | to_entries[] | select(.value == true) | "  ✓ \(.key)"'

    echo ""

    # Check if online (heartbeat in last 10 minutes)
    local last_heartbeat
    last_heartbeat=$(echo "$subscription" | jq -r '.last_heartbeat_at // ""')

    if [ -n "$last_heartbeat" ]; then
        local now_epoch
        now_epoch=$(date +%s)

        local heartbeat_epoch
        heartbeat_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo "$last_heartbeat" | cut -d. -f1)" +%s 2>/dev/null || echo "0")

        local diff=$((now_epoch - heartbeat_epoch))

        if [ $diff -lt 600 ]; then
            echo "${GREEN}●${NC} CU is ${BOLD}ONLINE${NC} (last seen $(($diff / 60)) minutes ago)"
        else
            echo "${YELLOW}●${NC} CU is ${BOLD}OFFLINE${NC} (last seen $(($diff / 3600)) hours ago)"
        fi
    else
        echo "${GRAY}●${NC} CU has ${BOLD}NEVER${NC} connected"
    fi

    echo ""
}

# Check subscription and enforce limits
enforce_subscription_limits() {
    local cu_id="$1"
    local feature="${2:-}"

    local subscription
    subscription=$(get_cu_subscription "$cu_id" 2>/dev/null)

    if [ $? -ne 0 ]; then
        print_error "No active subscription - CU is not licensed"
        echo ""
        echo "To activate, run:"
        echo "  ${CYAN}cu config subscription --cu-id $cu_id --activate${NC}"
        return 1
    fi

    # Check if subscription is expired
    local period_end
    period_end=$(echo "$subscription" | jq -r '.current_period_end')

    local now
    now=$(date -u +%Y-%m-%dT%H:%M:%S)

    if [[ "$period_end" < "$now" ]]; then
        print_error "Subscription expired on $period_end"
        echo ""
        echo "To renew, contact: billing@cu.app"
        return 1
    fi

    # Check feature entitlement if specified
    if [ -n "$feature" ]; then
        local plan_id
        plan_id=$(echo "$subscription" | jq -r '.plan_id')

        local plan
        plan=$(get_subscription_plan "$plan_id")

        local has_feature
        has_feature=$(echo "$plan" | jq -r ".features.$feature // false")

        if [ "$has_feature" != "true" ]; then
            print_error "Feature '$feature' not included in current plan"
            echo ""
            echo "To upgrade, run:"
            echo "  ${CYAN}cu config subscription --cu-id $cu_id --upgrade${NC}"
            return 1
        fi
    fi

    # Send heartbeat
    send_heartbeat "$cu_id" "cli" "1.0.0" "production" > /dev/null 2>&1

    return 0
}

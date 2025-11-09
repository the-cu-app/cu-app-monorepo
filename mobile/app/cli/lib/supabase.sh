#!/bin/bash
# Supabase API wrapper functions

# Source dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"
source "$SCRIPT_DIR/logging.sh"

# Supabase configuration from environment
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-}"

# Check if Supabase is configured
check_supabase_config() {
    if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
        print_error "Supabase not configured"
        echo ""
        echo "Please set environment variables:"
        echo "  export SUPABASE_URL='https://your-project.supabase.co'"
        echo "  export SUPABASE_ANON_KEY='your-anon-key'"
        echo "  export SUPABASE_SERVICE_ROLE_KEY='your-service-role-key'  # Optional, for admin operations"
        echo ""
        return 1
    fi
    return 0
}

# Make Supabase REST API request
supabase_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local use_service_key="${4:-false}"

    check_supabase_config || return 1

    local auth_key="$SUPABASE_ANON_KEY"
    if [ "$use_service_key" = true ] && [ -n "$SUPABASE_SERVICE_ROLE_KEY" ]; then
        auth_key="$SUPABASE_SERVICE_ROLE_KEY"
    fi

    local url="${SUPABASE_URL}/rest/v1/${endpoint}"

    log_debug "Supabase $method request: $url"

    local response
    if [ -n "$data" ]; then
        response=$(curl -s -X "$method" "$url" \
            -H "apikey: $auth_key" \
            -H "Authorization: Bearer $auth_key" \
            -H "Content-Type: application/json" \
            -H "Prefer: return=representation" \
            -d "$data")
    else
        response=$(curl -s -X "$method" "$url" \
            -H "apikey: $auth_key" \
            -H "Authorization: Bearer $auth_key" \
            -H "Content-Type: application/json")
    fi

    echo "$response"
}

# Call Supabase Edge Function
supabase_function() {
    local function_name="$1"
    local payload="${2:-{}}"

    check_supabase_config || return 1

    local url="${SUPABASE_URL}/functions/v1/${function_name}"

    log_debug "Calling Supabase function: $function_name"

    local response
    response=$(curl -s -X POST "$url" \
        -H "Authorization: Bearer $SUPABASE_ANON_KEY" \
        -H "Content-Type: application/json" \
        -d "$payload")

    echo "$response"
}

# Get CU configuration
supabase_get_cu() {
    local cu_id="$1"

    local response
    response=$(supabase_request "GET" "cu_configurations?cu_code=eq.$cu_id")

    if echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo "$response" | jq '.[0]'
        return 0
    else
        return 1
    fi
}

# Create CU configuration
supabase_create_cu() {
    local cu_data="$1"

    local response
    response=$(supabase_request "POST" "cu_configurations" "$cu_data" true)

    if echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo "$response" | jq '.[0]'
        return 0
    else
        log_error "Failed to create CU: $(echo "$response" | jq -r '.message // .error // .')"
        return 1
    fi
}

# Update CU configuration
supabase_update_cu() {
    local cu_id="$1"
    local cu_data="$2"

    local response
    response=$(supabase_request "PATCH" "cu_configurations?cu_code=eq.$cu_id" "$cu_data" true)

    if echo "$response" | jq -e '.[0]' > /dev/null 2>&1; then
        echo "$response" | jq '.[0]'
        return 0
    else
        log_error "Failed to update CU: $(echo "$response" | jq -r '.message // .error // .')"
        return 1
    fi
}

# List all CUs
supabase_list_cus() {
    local response
    response=$(supabase_request "GET" "cu_configurations?select=cu_code,cu_name,display_name,is_active&order=cu_name.asc")

    if echo "$response" | jq -e '.' > /dev/null 2>&1; then
        echo "$response"
        return 0
    else
        return 1
    fi
}

# Get feature flags for CU
supabase_get_feature_flags() {
    local cu_id="$1"

    # First get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    local response
    response=$(supabase_request "GET" "cu_feature_flags?cu_id=eq.$cu_uuid")

    echo "$response"
}

# Create feature flag
supabase_create_feature_flag() {
    local cu_id="$1"
    local feature_key="$2"
    local is_enabled="${3:-false}"
    local config="${4:-{}}"

    # Get CU UUID
    local cu_data
    cu_data=$(supabase_get_cu "$cu_id") || return 1

    local cu_uuid
    cu_uuid=$(echo "$cu_data" | jq -r '.id')

    local flag_data
    flag_data=$(jq -n \
        --arg cu_id "$cu_uuid" \
        --arg feature_key "$feature_key" \
        --argjson is_enabled "$is_enabled" \
        --argjson config "$config" \
        '{cu_id: $cu_id, feature_key: $feature_key, is_enabled: $is_enabled, config: $config}')

    supabase_request "POST" "cu_feature_flags" "$flag_data" true
}

# Generate FAQs via Edge Function
supabase_generate_faqs() {
    local audience="$1"
    local cu_id="${2:-}"
    local categories="${3:-}"
    local count="${4:-10}"

    local payload
    payload=$(jq -n \
        --arg audience "$audience" \
        --arg cu_id "$cu_id" \
        --arg categories "$categories" \
        --arg count "$count" \
        '{audience: $audience, cuId: $cu_id, categories: ($categories | split(",") | map(select(length > 0))), count: ($count | tonumber)}')

    supabase_function "generate-faqs" "$payload"
}

# Generate feature content via Edge Function
supabase_generate_content() {
    local cu_id="$1"
    local features="${2:-}"

    local payload
    if [ -n "$features" ]; then
        payload=$(jq -n \
            --arg cu_id "$cu_id" \
            --arg features "$features" \
            '{cuId: $cu_id, features: ($features | split(",") | map(select(length > 0))), batchMode: true}')
    else
        payload=$(jq -n \
            --arg cu_id "$cu_id" \
            '{cuId: $cu_id, batchMode: true}')
    fi

    supabase_function "generate-feature-content" "$payload"
}

# Check Supabase health
supabase_health_check() {
    check_supabase_config || return 1

    log_info "Checking Supabase connection..."

    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "$SUPABASE_URL/rest/v1/" \
        -H "apikey: $SUPABASE_ANON_KEY")

    if [ "$response" = "200" ]; then
        log_success "Supabase is reachable"
        return 0
    else
        log_error "Supabase is unreachable (HTTP $response)"
        return 1
    fi
}

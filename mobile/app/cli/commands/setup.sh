#!/bin/bash
# Setup command - Interactive CU setup wizard

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/cli/lib/colors.sh"
source "$SCRIPT_DIR/cli/lib/logging.sh"
source "$SCRIPT_DIR/cli/lib/validators.sh"
source "$SCRIPT_DIR/cli/lib/supabase.sh"

# Show setup help
show_setup_help() {
    cat << EOF
${BOLD}${BLUE}cu setup${NC} - Set up a new credit union

${BOLD}USAGE:${NC}
  cu setup [options]

${BOLD}OPTIONS:${NC}
  --cu-id <id>            CU identifier (e.g., navyfederal, becu)
  --name <name>           Full CU name
  --domain <domain>       Domain name (e.g., navyfederal.app)
  --colors <primary,sec>  Brand colors in hex
  --routing <number>      9-digit routing number
  --skip-content          Skip automatic content generation
  --wizard                Run interactive wizard (default)
  -h, --help              Show this help

${BOLD}EXAMPLES:${NC}
  ${DIM}# Interactive wizard (recommended)${NC}
  ${CYAN}cu setup${NC}

  ${DIM}# Non-interactive setup${NC}
  ${CYAN}cu setup --cu-id navyfederal --name "Navy Federal Credit Union" \\${NC}
    ${CYAN}--domain navyfederal.app --routing 256074974${NC}

EOF
}

# Prompt for input with validation
prompt() {
    local prompt_text="$1"
    local default_value="${2:-}"
    local validator="${3:-}"
    local value

    while true; do
        if [ -n "$default_value" ]; then
            echo -ne "${CYAN}${prompt_text}${NC} ${DIM}[$default_value]${NC}: "
        else
            echo -ne "${CYAN}${prompt_text}${NC}: "
        fi

        read -r value

        # Use default if empty
        if [ -z "$value" ] && [ -n "$default_value" ]; then
            value="$default_value"
        fi

        # Validate if validator provided
        if [ -n "$validator" ]; then
            if $validator "$value"; then
                echo "$value"
                return 0
            fi
            echo ""
        else
            echo "$value"
            return 0
        fi
    done
}

# Confirm action
confirm() {
    local message="$1"
    local default="${2:-n}"

    while true; do
        echo -ne "${YELLOW}${message}${NC} ${DIM}[y/n]${NC}: "
        read -r response

        response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

        if [ -z "$response" ]; then
            response="$default"
        fi

        case "$response" in
            y|yes)
                return 0
                ;;
            n|no)
                return 1
                ;;
            *)
                print_error "Please answer yes or no"
                ;;
        esac
    done
}

# Interactive wizard
run_wizard() {
    print_header "CU Setup Wizard"

    log_info "This wizard will guide you through setting up a new credit union"
    echo ""

    # Step 1: Basic Information
    print_subheader "Step 1: Basic Information"

    local cu_id
    cu_id=$(prompt "CU ID (lowercase, alphanumeric)" "" validate_cu_id)

    # Check if CU already exists
    if supabase_get_cu "$cu_id" > /dev/null 2>&1; then
        print_error "CU with ID '$cu_id' already exists"
        echo ""
        if confirm "Do you want to update the existing CU instead?"; then
            log_info "Updating existing CU: $cu_id"
            # TODO: Implement update flow
            log_error "Update not yet implemented"
            return 1
        else
            return 1
        fi
    fi

    local cu_name
    cu_name=$(prompt "Full CU Name" "")

    local cu_short_name
    cu_short_name=$(prompt "Short Name/Abbreviation" "$(echo "$cu_name" | head -c 10)")

    local display_name
    display_name=$(prompt "Display Name" "$cu_name")

    # Step 2: Contact Information
    print_subheader "Step 2: Contact Information"

    local email
    email=$(prompt "Support Email" "support@${cu_id}.app" validate_email)

    local phone
    phone=$(prompt "Support Phone" "" validate_phone)

    local website
    website=$(prompt "Website URL" "https://${cu_id}.app" validate_url)

    local domain
    domain=$(prompt "Domain" "${cu_id}.app" validate_domain)

    # Step 3: Branding
    print_subheader "Step 3: Branding"

    local primary_color
    primary_color=$(prompt "Primary Color (hex)" "#0066CC" validate_color)

    local secondary_color
    secondary_color=$(prompt "Secondary Color (hex)" "#4CAF50" validate_color)

    local logo_url
    logo_url=$(prompt "Logo URL" "https://cdn.${cu_id}.app/logo.svg")

    # Step 4: Banking Details
    print_subheader "Step 4: Banking Details"

    local routing_number
    routing_number=$(prompt "Routing Number (9 digits)" "" validate_routing_number)

    local institution_code
    institution_code=$(prompt "Institution Code" "")

    # Step 5: Configuration
    print_subheader "Step 5: Configuration"

    echo ""
    echo "Would you like to enable these features?"
    echo ""

    local features=()

    if confirm "Enable Core Banking?" "y"; then
        features+=("core_banking")
    fi

    if confirm "Enable Transfers?" "y"; then
        features+=("transfers")
    fi

    if confirm "Enable Bill Pay?" "y"; then
        features+=("bill_pay")
    fi

    if confirm "Enable Mobile Deposit?" "y"; then
        features+=("mobile_deposit")
    fi

    if confirm "Enable Card Management?" "y"; then
        features+=("cards")
    fi

    if confirm "Enable P2P Payments?" "y"; then
        features+=("p2p_payments")
    fi

    if confirm "Enable Financial Insights?" "y"; then
        features+=("insights")
    fi

    # Step 6: Content Generation
    print_subheader "Step 6: Content Generation"

    local generate_content=true
    if ! confirm "Generate FAQs and Figma content automatically?" "y"; then
        generate_content=false
    fi

    # Step 7: Review
    print_subheader "Step 7: Review Configuration"

    echo ""
    print_table_header "Setting" "Value"
    print_table_row "CU ID" "$cu_id"
    print_table_row "Name" "$cu_name"
    print_table_row "Short Name" "$cu_short_name"
    print_table_row "Display Name" "$display_name"
    print_table_row "Email" "$email"
    print_table_row "Phone" "$phone"
    print_table_row "Website" "$website"
    print_table_row "Domain" "$domain"
    print_table_row "Primary Color" "$primary_color"
    print_table_row "Secondary Color" "$secondary_color"
    print_table_row "Logo URL" "$logo_url"
    print_table_row "Routing Number" "$routing_number"
    print_table_row "Institution Code" "$institution_code"
    print_table_row "Features" "$(IFS=, ; echo "${features[*]}")"
    print_table_row "Generate Content" "$generate_content"
    echo ""

    if ! confirm "Create this credit union?" "y"; then
        log_warn "Setup cancelled by user"
        return 1
    fi

    # Step 8: Create CU
    print_subheader "Step 8: Creating Credit Union"

    log_info "Creating CU in Supabase..."

    # Build JSON payload
    local cu_data
    cu_data=$(jq -n \
        --arg cu_name "$cu_name" \
        --arg cu_code "$cu_id" \
        --arg display_name "$display_name" \
        --arg email "$email" \
        --arg phone "$phone" \
        --arg website "$website" \
        --arg logo_url "$logo_url" \
        --arg primary_color "$primary_color" \
        --arg secondary_color "$secondary_color" \
        --arg routing_number "$routing_number" \
        --arg institution_code "$institution_code" \
        '{
            cu_name: $cu_name,
            cu_code: $cu_code,
            display_name: $display_name,
            email: $email,
            phone: $phone,
            website: $website,
            logo_url: $logo_url,
            primary_color: $primary_color,
            secondary_color: $secondary_color,
            routing_number: $routing_number,
            institution_code: $institution_code,
            is_active: true
        }')

    local result
    result=$(supabase_create_cu "$cu_data")

    if [ $? -ne 0 ]; then
        log_error "Failed to create CU"
        return 1
    fi

    local cu_uuid
    cu_uuid=$(echo "$result" | jq -r '.id')

    log_success "CU created with ID: $cu_uuid"

    # Create feature flags
    log_info "Setting up feature flags..."

    for feature in "${features[@]}"; do
        log_debug "Enabling feature: $feature"
        supabase_create_feature_flag "$cu_id" "$feature" true "{}" > /dev/null 2>&1
    done

    log_success "Feature flags configured"

    # Generate content if requested
    if [ "$generate_content" = true ]; then
        print_subheader "Step 9: Generating Content"

        log_info "This may take a few minutes..."
        echo ""

        # Generate member FAQs
        log_info "Generating member FAQs..."
        local faq_result
        faq_result=$(supabase_generate_faqs "member" "$cu_id" "" "10")

        if echo "$faq_result" | jq -e '.success' > /dev/null 2>&1; then
            local faq_count
            faq_count=$(echo "$faq_result" | jq -r '.faqsGenerated')
            log_success "Generated $faq_count member FAQs"
        else
            log_warn "FAQ generation failed (you can generate later)"
        fi

        # Generate staff FAQs
        log_info "Generating staff FAQs..."
        faq_result=$(supabase_generate_faqs "staff" "$cu_id" "" "10")

        if echo "$faq_result" | jq -e '.success' > /dev/null 2>&1; then
            local faq_count
            faq_count=$(echo "$faq_result" | jq -r '.faqsGenerated')
            log_success "Generated $faq_count staff FAQs"
        else
            log_warn "Staff FAQ generation failed (you can generate later)"
        fi

        # Generate Figma content
        log_info "Generating Figma content..."
        local content_result
        content_result=$(supabase_generate_content "$cu_id" "")

        if echo "$content_result" | jq -e '.success' > /dev/null 2>&1; then
            log_success "Figma content generated"
        else
            log_warn "Figma content generation failed (you can generate later)"
        fi
    fi

    # Success!
    print_header "Setup Complete! 🎉"

    echo ""
    echo "${GREEN}${BOLD}Your credit union has been created successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. View your CU:"
    echo "     ${CYAN}cu config show --cu-id $cu_id${NC}"
    echo ""
    echo "  2. Generate more content:"
    echo "     ${CYAN}cu content generate --cu-id $cu_id --all${NC}"
    echo ""
    echo "  3. Deploy your app:"
    echo "     ${CYAN}cu deploy --cu-id $cu_id${NC}"
    echo ""
    echo "  4. Monitor health:"
    echo "     ${CYAN}cu monitor --cu-id $cu_id${NC}"
    echo ""
    echo "${DIM}CU ID: $cu_id${NC}"
    echo "${DIM}UUID: $cu_uuid${NC}"
    echo ""
}

# Main setup command
cmd_setup() {
    # Parse options
    local cu_id=""
    local cu_name=""
    local domain=""
    local routing=""
    local skip_content=false
    local use_wizard=true

    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                use_wizard=false
                shift 2
                ;;
            --name)
                cu_name="$2"
                use_wizard=false
                shift 2
                ;;
            --domain)
                domain="$2"
                use_wizard=false
                shift 2
                ;;
            --routing)
                routing="$2"
                use_wizard=false
                shift 2
                ;;
            --skip-content)
                skip_content=true
                shift
                ;;
            --wizard)
                use_wizard=true
                shift
                ;;
            -h|--help)
                show_setup_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_setup_help
                exit 1
                ;;
        esac
    done

    # Check prerequisites
    check_command "jq" "brew install jq" || exit 1
    check_command "curl" || exit 1

    if ! check_supabase_config; then
        exit 1
    fi

    # Run wizard or non-interactive setup
    if [ "$use_wizard" = true ]; then
        run_wizard
    else
        # TODO: Implement non-interactive setup
        log_error "Non-interactive setup not yet implemented"
        echo "Use the interactive wizard: cu setup --wizard"
        exit 1
    fi
}

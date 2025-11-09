#!/bin/bash
# Content command - Generate FAQs, Figma content, and documentation

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/cli/lib/colors.sh"
source "$SCRIPT_DIR/cli/lib/logging.sh"
source "$SCRIPT_DIR/cli/lib/validators.sh"
source "$SCRIPT_DIR/cli/lib/supabase.sh"

# Show content help
show_content_help() {
    cat << EOF
${BOLD}${BLUE}cu content${NC} - Generate content for credit unions

${BOLD}USAGE:${NC}
  cu content <subcommand> [options]

${BOLD}SUBCOMMANDS:${NC}
  ${CYAN}generate${NC}     Generate new content
  ${CYAN}preview${NC}      Preview content before saving
  ${CYAN}export${NC}       Export content to CSV/JSON
  ${CYAN}sync${NC}         Sync content to external services

${BOLD}GENERATE OPTIONS:${NC}
  --cu-id <id>        CU identifier (required for member/staff)
  --type <type>       Content type: member, staff, developer, design, security, figma
  --all               Generate all content types
  --categories <list> Comma-separated categories
  --count <number>    Number of items per category (default: 10)
  --output <file>     Output file path (for figma type)

${BOLD}EXAMPLES:${NC}
  ${DIM}# Generate all content for a CU${NC}
  ${CYAN}cu content generate --cu-id navyfederal --all${NC}

  ${DIM}# Generate member FAQs only${NC}
  ${CYAN}cu content generate --cu-id navyfederal --type member${NC}

  ${DIM}# Generate specific categories${NC}
  ${CYAN}cu content generate --cu-id becu --type member \\${NC}
    ${CYAN}--categories login,transfers,deposits${NC}

  ${DIM}# Generate Figma content and export to CSV${NC}
  ${CYAN}cu content generate --cu-id golden1 --type figma \\${NC}
    ${CYAN}--output figma_golden1.csv${NC}

  ${DIM}# Generate platform-wide developer FAQs${NC}
  ${CYAN}cu content generate --type developer${NC}

  ${DIM}# Preview content before generating${NC}
  ${CYAN}cu content preview --cu-id navyfederal --type member${NC}

  ${DIM}# Export existing content${NC}
  ${CYAN}cu content export --cu-id navyfederal --type member \\${NC}
    ${CYAN}--output member_faqs.json${NC}

EOF
}

# Estimate cost for content generation
estimate_cost() {
    local type="$1"
    local count="${2:-10}"

    case "$type" in
        member)
            # ~90 FAQs at $0.03 per FAQ
            echo "~\$3.00"
            ;;
        staff)
            # ~70 FAQs at $0.02 per FAQ
            echo "~\$1.50"
            ;;
        developer|design|security)
            # Platform-wide, ~70 FAQs
            echo "~\$1.50"
            ;;
        figma)
            # ~60 features, ~$0.08 per feature
            echo "~\$5.00"
            ;;
        all)
            # Member + staff + figma
            echo "~\$10.00"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Generate content
cmd_generate() {
    local cu_id=""
    local content_type=""
    local generate_all=false
    local categories=""
    local count=10
    local output_file=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --type)
                content_type="$2"
                shift 2
                ;;
            --all)
                generate_all=true
                shift
                ;;
            --categories)
                categories="$2"
                shift 2
                ;;
            --count)
                count="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_content_help
                exit 1
                ;;
        esac
    done

    # Validate
    if [ "$generate_all" = false ] && [ -z "$content_type" ]; then
        print_error "Either --type or --all must be specified"
        show_content_help
        exit 1
    fi

    # Check prerequisites
    check_command "python3" "brew install python3" || exit 1
    check_supabase_config || exit 1

    # Check if CU exists (if needed)
    if [ -n "$cu_id" ]; then
        validate_cu_id "$cu_id" || exit 1

        if ! supabase_get_cu "$cu_id" > /dev/null 2>&1; then
            print_error "CU not found: $cu_id"
            echo "Run 'cu list' to see available CUs"
            exit 1
        fi
    fi

    # Show cost estimate
    if [ "$generate_all" = true ]; then
        local cost=$(estimate_cost "all")
        print_warning "Estimated cost: $cost"
    elif [ -n "$content_type" ]; then
        local cost=$(estimate_cost "$content_type" "$count")
        print_warning "Estimated cost: $cost"
    fi

    echo ""
    if ! confirm "Continue with content generation?" "y"; then
        log_warn "Content generation cancelled"
        exit 0
    fi

    # Generate content based on type
    if [ "$generate_all" = true ]; then
        generate_all_content "$cu_id" "$count"
    else
        generate_content_by_type "$cu_id" "$content_type" "$categories" "$count" "$output_file"
    fi
}

# Generate all content for a CU
generate_all_content() {
    local cu_id="$1"
    local count="$2"

    print_header "Generating All Content for $cu_id"

    local total_steps=3
    local current_step=0

    # Step 1: Member FAQs
    current_step=$((current_step + 1))
    print_subheader "[$current_step/$total_steps] Generating Member FAQs"

    local result
    result=$(supabase_generate_faqs "member" "$cu_id" "" "$count")

    if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
        local faq_count=$(echo "$result" | jq -r '.faqsGenerated')
        log_success "Generated $faq_count member FAQs"
    else
        log_error "Failed to generate member FAQs"
        echo "$result" | jq -r '.error // .message // .' | log_error
    fi

    # Step 2: Staff FAQs
    current_step=$((current_step + 1))
    print_subheader "[$current_step/$total_steps] Generating Staff FAQs"

    result=$(supabase_generate_faqs "staff" "$cu_id" "" "$count")

    if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
        local faq_count=$(echo "$result" | jq -r '.faqsGenerated')
        log_success "Generated $faq_count staff FAQs"
    else
        log_error "Failed to generate staff FAQs"
    fi

    # Step 3: Figma Content
    current_step=$((current_step + 1))
    print_subheader "[$current_step/$total_steps] Generating Figma Content"

    result=$(supabase_generate_content "$cu_id" "")

    if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
        local feature_count=$(echo "$result" | jq -r '.featuresGenerated')
        log_success "Generated content for $feature_count features"
    else
        log_error "Failed to generate Figma content"
    fi

    print_header "Content Generation Complete"
    log_success "All content generated for $cu_id"
}

# Generate content by specific type
generate_content_by_type() {
    local cu_id="$1"
    local content_type="$2"
    local categories="$3"
    local count="$4"
    local output_file="$5"

    print_header "Generating ${content_type^} Content"

    case "$content_type" in
        member|staff|developer|design|security)
            # FAQ generation
            log_info "Calling FAQ generation API..."

            local result
            result=$(supabase_generate_faqs "$content_type" "$cu_id" "$categories" "$count")

            if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
                local faq_count=$(echo "$result" | jq -r '.faqsGenerated')
                local cat_count=$(echo "$result" | jq -r '.categoriesGenerated')
                log_success "Generated $faq_count FAQs across $cat_count categories"

                if [ -n "$cu_id" ]; then
                    log_info "FAQs saved to database for CU: $cu_id"
                else
                    log_info "Platform-wide FAQs saved to database"
                fi
            else
                log_error "Failed to generate FAQs"
                echo "$result" | jq -r '.error // .message // "Unknown error"'
                exit 1
            fi
            ;;

        figma)
            # Figma content generation
            log_info "Calling Figma content generation API..."

            local result
            result=$(supabase_generate_content "$cu_id" "")

            if echo "$result" | jq -e '.success' > /dev/null 2>&1; then
                local feature_count=$(echo "$result" | jq -r '.featuresGenerated')
                log_success "Generated content for $feature_count features"

                # Export to CSV if requested
                if [ -n "$output_file" ]; then
                    log_info "Exporting to CSV: $output_file"

                    # Call Python script to export
                    python3 "$SCRIPT_DIR/scripts/generate_feature_content.py" "$cu_id" \
                        --output "$output_file"

                    if [ $? -eq 0 ]; then
                        log_success "Exported to $output_file"
                    else
                        log_error "Failed to export CSV"
                    fi
                fi
            else
                log_error "Failed to generate Figma content"
                echo "$result" | jq -r '.error // .message // "Unknown error"'
                exit 1
            fi
            ;;

        *)
            print_error "Unknown content type: $content_type"
            echo "Valid types: member, staff, developer, design, security, figma"
            exit 1
            ;;
    esac
}

# Preview content (TODO)
cmd_preview() {
    log_error "Preview command not yet implemented"
    exit 1
}

# Export content
cmd_export() {
    local cu_id=""
    local content_type=""
    local output_file=""

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --type)
                content_type="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            *)
                print_error "Unknown option: $1"
                show_content_help
                exit 1
                ;;
        esac
    done

    # Validate
    if [ -z "$cu_id" ] || [ -z "$content_type" ] || [ -z "$output_file" ]; then
        print_error "Missing required options"
        show_content_help
        exit 1
    fi

    log_info "Exporting $content_type content for $cu_id to $output_file"
    log_error "Export command not yet implemented"
    exit 1
}

# Sync content (TODO)
cmd_sync() {
    log_error "Sync command not yet implemented"
    exit 1
}

# Main content command
cmd_content() {
    if [ $# -eq 0 ]; then
        show_content_help
        exit 0
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        generate)
            cmd_generate "$@"
            ;;
        preview)
            cmd_preview "$@"
            ;;
        export)
            cmd_export "$@"
            ;;
        sync)
            cmd_sync "$@"
            ;;
        -h|--help)
            show_content_help
            ;;
        *)
            print_error "Unknown subcommand: $subcommand"
            show_content_help
            exit 1
            ;;
    esac
}

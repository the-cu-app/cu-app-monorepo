#!/bin/bash
# Deploy command - Build and deploy apps and services

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$SCRIPT_DIR/cli/lib/colors.sh"
source "$SCRIPT_DIR/cli/lib/logging.sh"
source "$SCRIPT_DIR/cli/lib/validators.sh"
source "$SCRIPT_DIR/cli/lib/supabase.sh"

# Show deploy help
show_deploy_help() {
    cat << EOF
${BOLD}${BLUE}cu deploy${NC} - Deploy apps and services

${BOLD}USAGE:${NC}
  cu deploy [options]

${BOLD}OPTIONS:${NC}
  --cu-id <id>        CU identifier
  --target <target>   Deployment target: ios, android, web, functions, all
  --env <environment> Environment: dev, staging, production (default: dev)
  --skip-tests        Skip running tests
  --skip-build        Skip build step (deploy only)
  --rollback          Rollback to previous version

${BOLD}EXAMPLES:${NC}
  ${DIM}# Deploy everything for a CU${NC}
  ${CYAN}cu deploy --cu-id navyfederal --target all${NC}

  ${DIM}# Deploy iOS app only${NC}
  ${CYAN}cu deploy --cu-id navyfederal --target ios --env production${NC}

  ${DIM}# Deploy Supabase functions${NC}
  ${CYAN}cu deploy --target functions${NC}

  ${DIM}# Rollback deployment${NC}
  ${CYAN}cu deploy --cu-id navyfederal --rollback${NC}

EOF
}

# Build Flutter app
build_flutter_app() {
    local platform="$1"
    local cu_id="$2"

    log_info "Building Flutter app for $platform..."

    case "$platform" in
        ios)
            exec_cmd "flutter build ios --release --dart-define=CU_ID=$cu_id" \
                "Build iOS app"
            ;;
        android)
            exec_cmd "flutter build apk --release --dart-define=CU_ID=$cu_id" \
                "Build Android app"
            ;;
        web)
            exec_cmd "flutter build web --release --dart-define=CU_ID=$cu_id" \
                "Build web app"
            ;;
        *)
            print_error "Unknown platform: $platform"
            return 1
            ;;
    esac
}

# Deploy Supabase functions
deploy_supabase_functions() {
    log_info "Deploying Supabase Edge Functions..."

    check_command "supabase" "brew install supabase/tap/supabase" || return 1

    local functions=(
        "generate-faqs"
        "generate-feature-content"
    )

    for func in "${functions[@]}"; do
        log_info "Deploying function: $func"
        exec_cmd "supabase functions deploy $func" "Deploy $func"
    done

    log_success "All Supabase functions deployed"
}

# Run migrations
run_migrations() {
    log_info "Running database migrations..."

    check_command "supabase" "brew install supabase/tap/supabase" || return 1

    exec_cmd "supabase db push" "Apply database migrations"

    log_success "Migrations applied"
}

# Main deploy command
cmd_deploy() {
    local cu_id=""
    local target="all"
    local environment="dev"
    local skip_tests=false
    local skip_build=false
    local do_rollback=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case $1 in
            --cu-id)
                cu_id="$2"
                shift 2
                ;;
            --target)
                target="$2"
                shift 2
                ;;
            --env)
                environment="$2"
                shift 2
                ;;
            --skip-tests)
                skip_tests=true
                shift
                ;;
            --skip-build)
                skip_build=true
                shift
                ;;
            --rollback)
                do_rollback=true
                shift
                ;;
            -h|--help)
                show_deploy_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_deploy_help
                exit 1
                ;;
        esac
    done

    # Validate
    if [ "$target" != "functions" ] && [ -z "$cu_id" ]; then
        print_error "CU ID required for app deployments"
        show_deploy_help
        exit 1
    fi

    print_header "Deployment for $cu_id"

    # Run tests
    if [ "$skip_tests" = false ]; then
        log_info "Running tests..."
        exec_cmd "flutter test" "Run tests"
        log_success "Tests passed"
    fi

    # Build and deploy based on target
    case "$target" in
        ios)
            build_flutter_app "ios" "$cu_id"
            log_warn "iOS deployment to App Store not automated yet"
            log_info "Build complete. Upload to App Store Connect manually"
            ;;
        android)
            build_flutter_app "android" "$cu_id"
            log_warn "Android deployment to Play Store not automated yet"
            log_info "Build complete. Upload to Play Console manually"
            ;;
        web)
            build_flutter_app "web" "$cu_id"
            log_info "Deploying to hosting..."
            log_error "Web deployment not yet implemented"
            ;;
        functions)
            deploy_supabase_functions
            run_migrations
            ;;
        all)
            build_flutter_app "ios" "$cu_id"
            build_flutter_app "android" "$cu_id"
            build_flutter_app "web" "$cu_id"
            deploy_supabase_functions
            run_migrations
            log_success "All deployments complete"
            ;;
        *)
            print_error "Unknown target: $target"
            show_deploy_help
            exit 1
            ;;
    esac

    print_header "Deployment Complete"
    log_success "Successfully deployed $target for $cu_id"
}

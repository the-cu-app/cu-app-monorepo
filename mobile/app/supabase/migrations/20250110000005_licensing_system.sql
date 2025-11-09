-- CU Platform Licensing & Subscription System
-- Tracks active CU subscriptions, usage, and telemetry (Unreal Engine-style pricing)

-- ============================================================================
-- Subscription Plans & Tiers
-- ============================================================================

CREATE TABLE IF NOT EXISTS subscription_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_code TEXT NOT NULL UNIQUE,
    plan_name TEXT NOT NULL,
    description TEXT,

    -- Pricing
    monthly_price DECIMAL(10,2) NOT NULL,
    annual_price DECIMAL(10,2),
    setup_fee DECIMAL(10,2) DEFAULT 0,

    -- Limits
    max_members INTEGER, -- NULL = unlimited
    max_transactions_per_month INTEGER,
    max_api_calls_per_month INTEGER,
    max_storage_gb INTEGER,
    max_admin_users INTEGER DEFAULT 5,

    -- Features
    features JSONB DEFAULT '{}', -- {"ai_coaching": true, "mobile_deposit": true, etc.}

    -- Revenue sharing (Unreal Engine-style)
    revenue_share_percentage DECIMAL(5,2) DEFAULT 0, -- e.g., 5.00 for 5%
    revenue_threshold DECIMAL(10,2) DEFAULT 0, -- Revenue share kicks in after this

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_public BOOLEAN DEFAULT true, -- Show in pricing page

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT valid_revenue_share CHECK (revenue_share_percentage >= 0 AND revenue_share_percentage <= 100)
);

-- Default plans
INSERT INTO subscription_plans (plan_code, plan_name, description, monthly_price, annual_price, max_members, max_transactions_per_month, features, revenue_share_percentage, revenue_threshold) VALUES
('starter', 'Starter', 'For small credit unions getting started', 99.00, 990.00, 1000, 10000, '{"core_banking": true, "transfers": true, "bill_pay": false, "mobile_deposit": false}', 0, 0),
('professional', 'Professional', 'For growing credit unions', 499.00, 4990.00, 10000, 100000, '{"core_banking": true, "transfers": true, "bill_pay": true, "mobile_deposit": true, "cards": true}', 0, 0),
('enterprise', 'Enterprise', 'For large credit unions', 1999.00, 19990.00, NULL, NULL, '{"core_banking": true, "transfers": true, "bill_pay": true, "mobile_deposit": true, "cards": true, "ai_coaching": true, "insights": true}', 5.00, 1000000),
('custom', 'Custom', 'Tailored for your needs', 0.00, 0.00, NULL, NULL, '{}', 0, 0);

-- ============================================================================
-- CU Subscriptions (Active Licenses)
-- ============================================================================

CREATE TABLE IF NOT EXISTS cu_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES subscription_plans(id),

    -- License Key
    license_key TEXT NOT NULL UNIQUE,
    license_type TEXT NOT NULL CHECK (license_type IN ('trial', 'production', 'development', 'sandbox')),

    -- Status
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'cancelled', 'expired')),

    -- Billing Period
    billing_cycle TEXT NOT NULL DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly', 'annual', 'custom')),
    current_period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    current_period_end TIMESTAMPTZ NOT NULL,

    -- Trial
    is_trial BOOLEAN DEFAULT false,
    trial_ends_at TIMESTAMPTZ,

    -- Limits Override (if custom negotiated)
    custom_limits JSONB DEFAULT '{}',
    custom_features JSONB DEFAULT '{}',

    -- Usage tracking
    last_heartbeat_at TIMESTAMPTZ, -- Last time CU "phoned home"
    last_deployment_at TIMESTAMPTZ,
    last_content_generation_at TIMESTAMPTZ,

    -- Metadata
    activated_at TIMESTAMPTZ DEFAULT NOW(),
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(cu_id, plan_id)
);

-- Index for quick lookups
CREATE INDEX idx_cu_subscriptions_license_key ON cu_subscriptions(license_key);
CREATE INDEX idx_cu_subscriptions_status ON cu_subscriptions(status);
CREATE INDEX idx_cu_subscriptions_cu_id ON cu_subscriptions(cu_id);

-- ============================================================================
-- Usage Tracking (Telemetry)
-- ============================================================================

CREATE TABLE IF NOT EXISTS cu_usage_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES cu_subscriptions(id) ON DELETE SET NULL,

    -- Event Details
    event_type TEXT NOT NULL, -- 'cli_command', 'api_call', 'content_generation', 'deployment', 'heartbeat'
    event_action TEXT, -- 'setup', 'deploy', 'generate_faqs', etc.
    event_metadata JSONB DEFAULT '{}',

    -- Usage Metrics
    api_calls INTEGER DEFAULT 0,
    storage_used_mb DECIMAL(10,2) DEFAULT 0,
    bandwidth_used_mb DECIMAL(10,2) DEFAULT 0,

    -- Source
    source TEXT, -- 'cli', 'web_app', 'mobile_app', 'api'
    source_version TEXT,
    source_ip INET,
    user_agent TEXT,

    -- Timestamp
    logged_at TIMESTAMPTZ DEFAULT NOW(),

    -- Aggregation window
    window_start TIMESTAMPTZ, -- For hourly/daily rollups
    window_end TIMESTAMPTZ
);

-- Indexes for analytics
CREATE INDEX idx_cu_usage_logs_cu_id ON cu_usage_logs(cu_id);
CREATE INDEX idx_cu_usage_logs_event_type ON cu_usage_logs(event_type);
CREATE INDEX idx_cu_usage_logs_logged_at ON cu_usage_logs(logged_at);

-- ============================================================================
-- Heartbeat / "Phone Home" System
-- ============================================================================

CREATE TABLE IF NOT EXISTS cu_heartbeats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES cu_subscriptions(id) ON DELETE SET NULL,

    -- Status
    is_online BOOLEAN DEFAULT true,

    -- Environment
    environment TEXT, -- 'production', 'staging', 'development'
    platform TEXT, -- 'ios', 'android', 'web', 'cli'
    version TEXT,

    -- Metrics
    active_users INTEGER DEFAULT 0, -- Current active users
    total_members INTEGER DEFAULT 0, -- Total CU members
    total_transactions_today INTEGER DEFAULT 0,
    total_api_calls_today INTEGER DEFAULT 0,

    -- System Health
    health_status TEXT DEFAULT 'healthy' CHECK (health_status IN ('healthy', 'degraded', 'down', 'maintenance')),
    health_checks JSONB DEFAULT '{}', -- Detailed health metrics

    -- Location
    server_ip INET,
    server_region TEXT,

    -- Timestamps
    heartbeat_at TIMESTAMPTZ DEFAULT NOW(),
    next_expected_heartbeat TIMESTAMPTZ,

    -- Metadata
    metadata JSONB DEFAULT '{}'
);

-- Index for latest heartbeat per CU
CREATE INDEX idx_cu_heartbeats_cu_id ON cu_heartbeats(cu_id);
CREATE INDEX idx_cu_heartbeats_heartbeat_at ON cu_heartbeats(heartbeat_at DESC);

-- ============================================================================
-- Monthly Usage Aggregates (for billing)
-- ============================================================================

CREATE TABLE IF NOT EXISTS cu_monthly_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES cu_subscriptions(id) ON DELETE SET NULL,

    -- Period
    month DATE NOT NULL, -- First day of month

    -- Usage Metrics
    total_members INTEGER DEFAULT 0,
    total_transactions INTEGER DEFAULT 0,
    total_api_calls INTEGER DEFAULT 0,
    total_storage_gb DECIMAL(10,2) DEFAULT 0,
    total_bandwidth_gb DECIMAL(10,2) DEFAULT 0,

    -- Content Generation Usage
    total_faqs_generated INTEGER DEFAULT 0,
    total_figma_content_generated INTEGER DEFAULT 0,
    total_ai_tokens_used BIGINT DEFAULT 0,
    total_ai_cost DECIMAL(10,2) DEFAULT 0,

    -- Deployment Activity
    total_deployments INTEGER DEFAULT 0,
    total_builds INTEGER DEFAULT 0,

    -- Revenue (if applicable)
    reported_revenue DECIMAL(12,2) DEFAULT 0, -- Self-reported by CU
    revenue_share_owed DECIMAL(10,2) DEFAULT 0,

    -- Calculated Charges
    base_subscription_charge DECIMAL(10,2) DEFAULT 0,
    overage_charges DECIMAL(10,2) DEFAULT 0,
    total_charges DECIMAL(10,2) DEFAULT 0,

    -- Billing
    invoice_id UUID,
    invoice_status TEXT DEFAULT 'pending' CHECK (invoice_status IN ('pending', 'paid', 'overdue', 'waived')),

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(cu_id, month)
);

-- Index for billing queries
CREATE INDEX idx_cu_monthly_usage_cu_id ON cu_monthly_usage(cu_id);
CREATE INDEX idx_cu_monthly_usage_month ON cu_monthly_usage(month DESC);

-- ============================================================================
-- License Validation Logs
-- ============================================================================

CREATE TABLE IF NOT EXISTS license_validation_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID REFERENCES cu_configurations(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES cu_subscriptions(id) ON DELETE SET NULL,
    license_key TEXT,

    -- Validation Result
    is_valid BOOLEAN NOT NULL,
    validation_result TEXT, -- 'valid', 'expired', 'suspended', 'invalid_key', 'limit_exceeded'

    -- Request Details
    requested_feature TEXT, -- Feature being accessed
    source TEXT, -- 'cli', 'app', 'api'
    source_version TEXT,
    source_ip INET,

    -- Response
    response_message TEXT,
    response_metadata JSONB DEFAULT '{}',

    -- Timestamp
    validated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_license_validation_logs_cu_id ON license_validation_logs(cu_id);
CREATE INDEX idx_license_validation_logs_validated_at ON license_validation_logs(validated_at DESC);

-- ============================================================================
-- Functions
-- ============================================================================

-- Generate unique license key
CREATE OR REPLACE FUNCTION generate_license_key()
RETURNS TEXT AS $$
DECLARE
    key TEXT;
BEGIN
    key := 'CU-' ||
           UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)) || '-' ||
           UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8)) || '-' ||
           UPPER(SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8));
    RETURN key;
END;
$$ LANGUAGE plpgsql;

-- Validate license
CREATE OR REPLACE FUNCTION validate_license(p_license_key TEXT)
RETURNS JSONB AS $$
DECLARE
    subscription RECORD;
    plan RECORD;
    result JSONB;
BEGIN
    -- Find subscription
    SELECT * INTO subscription
    FROM cu_subscriptions
    WHERE license_key = p_license_key;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'valid', false,
            'status', 'invalid_key',
            'message', 'License key not found'
        );
    END IF;

    -- Check status
    IF subscription.status != 'active' THEN
        RETURN jsonb_build_object(
            'valid', false,
            'status', subscription.status,
            'message', 'License is ' || subscription.status
        );
    END IF;

    -- Check expiration
    IF subscription.current_period_end < NOW() THEN
        RETURN jsonb_build_object(
            'valid', false,
            'status', 'expired',
            'message', 'License expired on ' || subscription.current_period_end
        );
    END IF;

    -- Get plan details
    SELECT * INTO plan
    FROM subscription_plans
    WHERE id = subscription.plan_id;

    -- Valid license
    RETURN jsonb_build_object(
        'valid', true,
        'status', 'active',
        'cu_id', subscription.cu_id,
        'plan', plan.plan_name,
        'expires_at', subscription.current_period_end,
        'features', plan.features,
        'limits', jsonb_build_object(
            'max_members', plan.max_members,
            'max_transactions_per_month', plan.max_transactions_per_month,
            'max_api_calls_per_month', plan.max_api_calls_per_month
        )
    );
END;
$$ LANGUAGE plpgsql;

-- Update heartbeat
CREATE OR REPLACE FUNCTION update_heartbeat(
    p_cu_id UUID,
    p_environment TEXT,
    p_platform TEXT,
    p_version TEXT,
    p_active_users INTEGER DEFAULT 0,
    p_health_status TEXT DEFAULT 'healthy'
)
RETURNS UUID AS $$
DECLARE
    heartbeat_id UUID;
    subscription_id UUID;
BEGIN
    -- Get active subscription
    SELECT id INTO subscription_id
    FROM cu_subscriptions
    WHERE cu_id = p_cu_id
    AND status = 'active'
    ORDER BY current_period_end DESC
    LIMIT 1;

    -- Insert heartbeat
    INSERT INTO cu_heartbeats (
        cu_id,
        subscription_id,
        environment,
        platform,
        version,
        active_users,
        health_status,
        next_expected_heartbeat
    ) VALUES (
        p_cu_id,
        subscription_id,
        p_environment,
        p_platform,
        p_version,
        p_active_users,
        p_health_status,
        NOW() + INTERVAL '5 minutes' -- Expect heartbeat every 5 min
    )
    RETURNING id INTO heartbeat_id;

    -- Update subscription last heartbeat
    UPDATE cu_subscriptions
    SET last_heartbeat_at = NOW()
    WHERE id = subscription_id;

    RETURN heartbeat_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE cu_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cu_usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cu_heartbeats ENABLE ROW LEVEL SECURITY;
ALTER TABLE cu_monthly_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE license_validation_logs ENABLE ROW LEVEL SECURITY;

-- Public can read active plans
CREATE POLICY "Anyone can view active subscription plans"
ON subscription_plans FOR SELECT
TO public
USING (is_active = true AND is_public = true);

-- CU admins can view their subscription
CREATE POLICY "CU admins can view their subscription"
ON cu_subscriptions FOR SELECT
TO authenticated
USING (
    cu_id IN (
        SELECT cu_id FROM user_profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'owner')
    )
);

-- Platform admins can view all
CREATE POLICY "Platform admins can view all subscriptions"
ON cu_subscriptions FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'platform_admin'
    )
);

-- Similar policies for other tables...

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE subscription_plans IS 'Subscription tiers and pricing plans';
COMMENT ON TABLE cu_subscriptions IS 'Active CU licenses and subscriptions';
COMMENT ON TABLE cu_usage_logs IS 'Telemetry and usage tracking events';
COMMENT ON TABLE cu_heartbeats IS 'Real-time CU online status (phone home)';
COMMENT ON TABLE cu_monthly_usage IS 'Monthly aggregated usage for billing';
COMMENT ON TABLE license_validation_logs IS 'License validation attempts and results';

COMMENT ON FUNCTION generate_license_key() IS 'Generate unique license key in format CU-XXXXXXXX-XXXXXXXX-XXXXXXXX';
COMMENT ON FUNCTION validate_license(TEXT) IS 'Validate license key and return status + entitlements';
COMMENT ON FUNCTION update_heartbeat(UUID, TEXT, TEXT, TEXT, INTEGER, TEXT) IS 'Record CU heartbeat to show online status';

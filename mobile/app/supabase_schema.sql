-- Core Banking Database Schema
-- This file contains the database tables for core banking functionality and multi-CU support

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Credit Union Configurations Table (Multi-CU Support)
CREATE TABLE IF NOT EXISTS cu_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_name TEXT NOT NULL UNIQUE,
    cu_code TEXT NOT NULL UNIQUE, -- Short code for CU identification

    -- Contact Information
    display_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    website TEXT,

    -- Branding
    logo_url TEXT,
    primary_color TEXT DEFAULT '#0066CC',
    secondary_color TEXT DEFAULT '#333333',
    theme_config JSONB DEFAULT '{}',

    -- Banking Configuration
    routing_number TEXT,
    institution_code TEXT,
    swift_code TEXT,

    -- API Configuration
    api_base_url TEXT,
    api_version TEXT DEFAULT 'v1',
    auth_method TEXT CHECK (auth_method IN ('oauth', 'api_key', 'jwt', 'basic')),

    -- Status and Settings
    is_active BOOLEAN DEFAULT true,
    is_sandbox BOOLEAN DEFAULT false,
    settings JSONB DEFAULT '{}',

    -- Rate Limits
    rate_limit_per_minute INTEGER DEFAULT 60,
    rate_limit_per_hour INTEGER DEFAULT 1000,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    last_sync_at TIMESTAMPTZ,

    -- Metadata
    metadata JSONB DEFAULT '{}',

    CONSTRAINT non_empty_cu_name CHECK (LENGTH(cu_name) > 0),
    CONSTRAINT non_empty_cu_code CHECK (LENGTH(cu_code) > 0)
);

-- Credit Union Feature Flags Table
CREATE TABLE IF NOT EXISTS cu_feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    feature_key TEXT NOT NULL,

    -- Feature Control
    is_enabled BOOLEAN DEFAULT false,
    rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),

    -- Feature Configuration
    config JSONB DEFAULT '{}',
    description TEXT,

    -- Targeting
    target_user_segments TEXT[], -- Array of user segment identifiers
    target_environments TEXT[] DEFAULT ARRAY['production'], -- 'production', 'staging', 'development'

    -- Scheduling
    enabled_from TIMESTAMPTZ,
    enabled_until TIMESTAMPTZ,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Metadata
    created_by UUID REFERENCES auth.users(id),
    updated_by UUID REFERENCES auth.users(id),
    metadata JSONB DEFAULT '{}',

    UNIQUE(cu_id, feature_key),
    CONSTRAINT non_empty_feature_key CHECK (LENGTH(feature_key) > 0)
);

-- Credit Union API Endpoints Table
CREATE TABLE IF NOT EXISTS cu_api_endpoints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    endpoint_key TEXT NOT NULL, -- e.g., 'accounts.list', 'transactions.get', 'transfers.create'

    -- Endpoint Details
    method TEXT NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE')),
    path TEXT NOT NULL, -- API path template, e.g., '/accounts/{account_id}'
    base_url TEXT, -- Override base URL if different from CU config

    -- Authentication
    auth_required BOOLEAN DEFAULT true,
    auth_config JSONB DEFAULT '{}',

    -- Headers and Parameters
    default_headers JSONB DEFAULT '{}',
    required_params TEXT[], -- Array of required parameter names
    optional_params TEXT[], -- Array of optional parameter names

    -- Request/Response Configuration
    request_schema JSONB, -- JSON schema for request validation
    response_schema JSONB, -- JSON schema for response validation
    timeout_seconds INTEGER DEFAULT 30,

    -- Rate Limiting
    rate_limit_per_minute INTEGER,
    rate_limit_per_hour INTEGER,

    -- Status
    is_active BOOLEAN DEFAULT true,
    is_deprecated BOOLEAN DEFAULT false,
    deprecated_at TIMESTAMPTZ,
    sunset_date DATE,

    -- Documentation
    description TEXT,
    example_request JSONB,
    example_response JSONB,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Metadata
    metadata JSONB DEFAULT '{}',

    UNIQUE(cu_id, endpoint_key),
    CONSTRAINT non_empty_endpoint_key CHECK (LENGTH(endpoint_key) > 0),
    CONSTRAINT non_empty_path CHECK (LENGTH(path) > 0),
    CONSTRAINT positive_timeout CHECK (timeout_seconds > 0)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_cu_configurations_code ON cu_configurations(cu_code);
CREATE INDEX IF NOT EXISTS idx_cu_configurations_active ON cu_configurations(is_active) WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_cu_feature_flags_cu_id ON cu_feature_flags(cu_id);
CREATE INDEX IF NOT EXISTS idx_cu_feature_flags_feature_key ON cu_feature_flags(feature_key);
CREATE INDEX IF NOT EXISTS idx_cu_feature_flags_enabled ON cu_feature_flags(cu_id, is_enabled) WHERE is_enabled = true;

CREATE INDEX IF NOT EXISTS idx_cu_api_endpoints_cu_id ON cu_api_endpoints(cu_id);
CREATE INDEX IF NOT EXISTS idx_cu_api_endpoints_key ON cu_api_endpoints(endpoint_key);
CREATE INDEX IF NOT EXISTS idx_cu_api_endpoints_active ON cu_api_endpoints(cu_id, is_active) WHERE is_active = true;

-- Triggers for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply update triggers
CREATE TRIGGER update_cu_configurations_updated_at
    BEFORE UPDATE ON cu_configurations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cu_feature_flags_updated_at
    BEFORE UPDATE ON cu_feature_flags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_cu_api_endpoints_updated_at
    BEFORE UPDATE ON cu_api_endpoints
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE cu_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE cu_feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE cu_api_endpoints ENABLE ROW LEVEL SECURITY;

-- Policies for cu_configurations (admin access only via service role)
CREATE POLICY "Service role can manage CU configurations" ON cu_configurations
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Authenticated users can view active CU configurations" ON cu_configurations
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- Policies for cu_feature_flags (admin access only via service role)
CREATE POLICY "Service role can manage feature flags" ON cu_feature_flags
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Authenticated users can view enabled feature flags" ON cu_feature_flags
    FOR SELECT USING (auth.role() = 'authenticated' AND is_enabled = true);

-- Policies for cu_api_endpoints (admin access only via service role)
CREATE POLICY "Service role can manage API endpoints" ON cu_api_endpoints
    FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Authenticated users can view active API endpoints" ON cu_api_endpoints
    FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);

-- Comments for documentation
COMMENT ON TABLE cu_configurations IS 'Multi-CU support: stores configuration for each credit union';
COMMENT ON TABLE cu_feature_flags IS 'Feature flag management for credit unions with rollout controls';
COMMENT ON TABLE cu_api_endpoints IS 'API endpoint definitions and configurations for each credit union';

-- Initial seed data for a sample CU (optional)
INSERT INTO cu_configurations (
    cu_name,
    cu_code,
    display_name,
    email,
    is_active,
    is_sandbox
) VALUES
('Sample Credit Union', 'SAMPLE_CU', 'Sample CU', 'support@samplecu.com', true, true)
ON CONFLICT (cu_name) DO NOTHING;

-- Final schema validation
DO $$
BEGIN
    RAISE NOTICE 'Core Banking Database Schema Created Successfully!';
    RAISE NOTICE 'Tables created: %, %, %',
        'cu_configurations',
        'cu_feature_flags',
        'cu_api_endpoints';
END $$;
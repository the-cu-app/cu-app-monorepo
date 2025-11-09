-- SUPAHYPER Design System - Supabase Schema
-- Content Management System for tokenized strings and configurations

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS design_tokens CASCADE;
DROP TABLE IF EXISTS content_strings CASCADE;
DROP TABLE IF EXISTS component_configs CASCADE;
DROP TABLE IF EXISTS feature_flags CASCADE;
DROP TABLE IF EXISTS theme_variants CASCADE;
DROP TABLE IF EXISTS user_preferences CASCADE;
DROP TABLE IF EXISTS content_versions CASCADE;

-- Theme variants table
CREATE TABLE theme_variants (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Content strings table for internationalization and content management
CREATE TABLE content_strings (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    key VARCHAR(255) NOT NULL,
    value TEXT NOT NULL,
    locale VARCHAR(10) DEFAULT 'en-US',
    category VARCHAR(100),
    description TEXT,
    tags TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id),
    UNIQUE(key, locale)
);

-- Component configurations
CREATE TABLE component_configs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    component_name VARCHAR(255) NOT NULL,
    variant VARCHAR(100),
    props_json JSONB NOT NULL DEFAULT '{}',
    theme_variant_id UUID REFERENCES theme_variants(id) ON DELETE CASCADE,
    description TEXT,
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(component_name, variant, theme_variant_id)
);

-- Feature flags for progressive rollout
CREATE TABLE feature_flags (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    feature_key VARCHAR(255) NOT NULL UNIQUE,
    enabled BOOLEAN DEFAULT false,
    rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
    user_segments JSONB DEFAULT '[]',
    config JSONB DEFAULT '{}',
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ
);

-- Design tokens for dynamic theming
CREATE TABLE design_tokens (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    token_category VARCHAR(100) NOT NULL, -- colors, typography, spacing, etc.
    token_key VARCHAR(255) NOT NULL,
    token_value TEXT NOT NULL,
    token_type VARCHAR(50), -- color, dimension, font, etc.
    platform VARCHAR(50) DEFAULT 'all', -- all, ios, android, web
    theme_variant_id UUID REFERENCES theme_variants(id) ON DELETE CASCADE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(token_key, platform, theme_variant_id)
);

-- User preferences for personalization
CREATE TABLE user_preferences (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    theme_variant_id UUID REFERENCES theme_variants(id),
    locale VARCHAR(10) DEFAULT 'en-US',
    accessibility_settings JSONB DEFAULT '{}',
    component_overrides JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Content versions for audit trail
CREATE TABLE content_versions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID NOT NULL,
    version_number INTEGER NOT NULL,
    changes JSONB NOT NULL,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMPTZ DEFAULT NOW(),
    change_reason TEXT
);

-- Indexes for performance
CREATE INDEX idx_content_strings_key ON content_strings(key);
CREATE INDEX idx_content_strings_locale ON content_strings(locale);
CREATE INDEX idx_content_strings_category ON content_strings(category);
CREATE INDEX idx_content_strings_tags ON content_strings USING gin(tags);
CREATE INDEX idx_content_strings_search ON content_strings USING gin(value gin_trgm_ops);

CREATE INDEX idx_component_configs_name ON component_configs(component_name);
CREATE INDEX idx_component_configs_variant ON component_configs(variant);
CREATE INDEX idx_component_configs_props ON component_configs USING gin(props_json);

CREATE INDEX idx_feature_flags_key ON feature_flags(feature_key);
CREATE INDEX idx_feature_flags_enabled ON feature_flags(enabled);
CREATE INDEX idx_feature_flags_expires ON feature_flags(expires_at);

CREATE INDEX idx_design_tokens_category ON design_tokens(token_category);
CREATE INDEX idx_design_tokens_key ON design_tokens(token_key);
CREATE INDEX idx_design_tokens_platform ON design_tokens(platform);

CREATE INDEX idx_content_versions_table_record ON content_versions(table_name, record_id);

-- Row Level Security (RLS)
ALTER TABLE content_strings ENABLE ROW LEVEL SECURITY;
ALTER TABLE component_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE theme_variants ENABLE ROW LEVEL SECURITY;

-- Policies for content_strings (read-only for anonymous, write for authenticated)
CREATE POLICY "Public read access" ON content_strings
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert" ON content_strings
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update" ON content_strings
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Policies for component_configs
CREATE POLICY "Public read access" ON component_configs
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage" ON component_configs
    FOR ALL USING (auth.role() = 'authenticated');

-- Policies for feature_flags (admin only write)
CREATE POLICY "Public read access" ON feature_flags
    FOR SELECT USING (true);

-- Policies for design_tokens
CREATE POLICY "Public read access" ON design_tokens
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can manage" ON design_tokens
    FOR ALL USING (auth.role() = 'authenticated');

-- Policies for user_preferences
CREATE POLICY "Users can read own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies for theme_variants
CREATE POLICY "Public read access" ON theme_variants
    FOR SELECT USING (true);

-- Functions and triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_content_strings_updated_at
    BEFORE UPDATE ON content_strings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_component_configs_updated_at
    BEFORE UPDATE ON component_configs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_feature_flags_updated_at
    BEFORE UPDATE ON feature_flags
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_design_tokens_updated_at
    BEFORE UPDATE ON design_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_theme_variants_updated_at
    BEFORE UPDATE ON theme_variants
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Function for versioning
CREATE OR REPLACE FUNCTION create_content_version()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO content_versions (
        table_name,
        record_id,
        version_number,
        changes,
        changed_by
    )
    VALUES (
        TG_TABLE_NAME,
        NEW.id,
        COALESCE(
            (SELECT MAX(version_number) + 1 
             FROM content_versions 
             WHERE table_name = TG_TABLE_NAME 
             AND record_id = NEW.id),
            1
        ),
        to_jsonb(NEW),
        auth.uid()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply versioning triggers to important tables
CREATE TRIGGER version_content_strings
    AFTER INSERT OR UPDATE ON content_strings
    FOR EACH ROW EXECUTE FUNCTION create_content_version();

CREATE TRIGGER version_design_tokens
    AFTER INSERT OR UPDATE ON design_tokens
    FOR EACH ROW EXECUTE FUNCTION create_content_version();

-- Insert default theme
INSERT INTO theme_variants (name, description, is_active) VALUES
    ('default', 'Default SUPAHYPER theme', true),
    ('dark', 'Dark mode theme', false),
    ('high_contrast', 'High contrast accessibility theme', false);

-- Insert default content strings
INSERT INTO content_strings (key, value, category, locale) VALUES
    ('app.name', 'SUPAHYPER', 'branding', 'en-US'),
    ('app.tagline', 'Banking Reimagined', 'branding', 'en-US'),
    ('connect.title', 'Connect Your Account', 'onboarding', 'en-US'),
    ('connect.subtitle', 'Securely link your bank account to get started with SUPAHYPER', 'onboarding', 'en-US'),
    ('connect.security.title', 'Military Grade Security', 'onboarding', 'en-US'),
    ('connect.security.description', 'For our members. Your data is encrypted and protected with the same security standards used by major banks.', 'onboarding', 'en-US'),
    ('feature.speed.title', 'Built in a Week', 'features', 'en-US'),
    ('feature.speed.description', 'Simple app that leans heavy on design tokens and real-time subscriptions. All Flutter.', 'features', 'en-US'),
    ('feature.legacy.title', 'Legacy Bridge', 'features', 'en-US'),
    ('feature.legacy.description', 'Snaps right onto your Symitar/PowerOn legacy systems, acting as a bridge while providing full UX layer.', 'features', 'en-US'),
    ('feature.kyc.title', 'Real KYC & Ownership', 'features', 'en-US'),
    ('feature.kyc.description', 'You own your website, experiences, and fraud/UX behavioral tools tied to your organization goals.', 'features', 'en-US'),
    ('feature.mx.title', 'Better Than MX', 'features', 'en-US'),
    ('feature.mx.description', 'Cleans transactions better than MX - superior data quality and categorization.', 'features', 'en-US'),
    ('button.connect', 'Connect Account', 'ui', 'en-US'),
    ('button.login', 'Log In', 'ui', 'en-US'),
    ('button.signup', 'Sign Up', 'ui', 'en-US'),
    ('status.connecting', 'Connecting...', 'ui', 'en-US'),
    ('status.loading', 'Loading...', 'ui', 'en-US'),
    ('error.general', 'Something went wrong. Please try again.', 'errors', 'en-US'),
    ('success.connected', 'Account connected successfully!', 'success', 'en-US');

-- Insert default feature flags
INSERT INTO feature_flags (feature_key, enabled, description) VALUES
    ('new_connect_screen', true, 'Enhanced connect account screen with 3D animations'),
    ('particle_effects', true, 'Particle animation effects in backgrounds'),
    ('haptic_feedback', true, 'Haptic feedback on interactions'),
    ('advanced_animations', true, 'Advanced animation effects throughout the app'),
    ('supabase_content', false, 'Load content from Supabase instead of hardcoded strings');

-- Insert sample design tokens (subset for demonstration)
INSERT INTO design_tokens (token_category, token_key, token_value, token_type, theme_variant_id) VALUES
    ('colors', 'primary', '#000000', 'color', (SELECT id FROM theme_variants WHERE name = 'default')),
    ('colors', 'secondary', '#6B7280', 'color', (SELECT id FROM theme_variants WHERE name = 'default')),
    ('colors', 'success', '#10B981', 'color', (SELECT id FROM theme_variants WHERE name = 'default')),
    ('colors', 'error', '#EF4444', 'color', (SELECT id FROM theme_variants WHERE name = 'default')),
    ('spacing', 'unit', '8', 'dimension', (SELECT id FROM theme_variants WHERE name = 'default')),
    ('typography', 'font_primary', 'Geist', 'font', (SELECT id FROM theme_variants WHERE name = 'default')),
    ('typography', 'font_mono', 'GeistMono', 'font', (SELECT id FROM theme_variants WHERE name = 'default'));

-- Grant permissions
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres;
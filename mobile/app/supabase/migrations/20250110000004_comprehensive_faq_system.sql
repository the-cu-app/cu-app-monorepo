-- Comprehensive FAQ System for Multi-Audience Knowledge Base
-- Serves: Members, Staff, Developers, Designers, Security/Compliance teams

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. MEMBER-FACING FAQs
-- =============================================================================

CREATE TABLE IF NOT EXISTS member_faqs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cu_id TEXT NOT NULL REFERENCES cu_configurations(cu_id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN (
    'login', 'accounts', 'transfers', 'bill_pay', 'deposits',
    'cards', 'security', 'settings', 'troubleshooting', 'general'
  )),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  search_keywords TEXT[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT false,
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for member FAQs
CREATE INDEX idx_member_faqs_cu ON member_faqs(cu_id);
CREATE INDEX idx_member_faqs_category ON member_faqs(category);
CREATE INDEX idx_member_faqs_tags ON member_faqs USING GIN(tags);
CREATE INDEX idx_member_faqs_search ON member_faqs USING GIN(
  to_tsvector('english', question || ' ' || answer)
);

-- =============================================================================
-- 2. STAFF TRAINING FAQs
-- =============================================================================

CREATE TABLE IF NOT EXISTS staff_training_faqs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cu_id TEXT NOT NULL REFERENCES cu_configurations(cu_id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN (
    'account_help', 'technical', 'compliance', 'verification',
    'escalation', 'products', 'system_limits', 'general'
  )),
  role TEXT CHECK (role IN (
    'teller', 'manager', 'phone_support', 'loan_officer',
    'compliance_officer', 'it_support', 'all_staff'
  )),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  escalation_procedure TEXT,
  related_policies TEXT[] DEFAULT '{}',
  tags TEXT[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0,
  is_mandatory_training BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for staff FAQs
CREATE INDEX idx_staff_faqs_cu ON staff_training_faqs(cu_id);
CREATE INDEX idx_staff_faqs_category ON staff_training_faqs(category);
CREATE INDEX idx_staff_faqs_role ON staff_training_faqs(role);
CREATE INDEX idx_staff_faqs_tags ON staff_training_faqs USING GIN(tags);
CREATE INDEX idx_staff_faqs_search ON staff_training_faqs USING GIN(
  to_tsvector('english', question || ' ' || answer)
);

-- =============================================================================
-- 3. DEVELOPER FAQs
-- =============================================================================

CREATE TABLE IF NOT EXISTS developer_faqs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category TEXT NOT NULL CHECK (category IN (
    'api', 'deployment', 'customization', 'database',
    'authentication', 'performance', 'troubleshooting', 'general'
  )),
  difficulty_level TEXT CHECK (difficulty_level IN (
    'beginner', 'intermediate', 'advanced'
  )),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  code_example TEXT,
  programming_language TEXT,  -- 'dart', 'typescript', 'sql', 'python'
  related_docs TEXT[] DEFAULT '{}',  -- URLs to documentation
  tags TEXT[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0,
  is_deprecated BOOLEAN DEFAULT false,
  deprecated_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for developer FAQs
CREATE INDEX idx_developer_faqs_category ON developer_faqs(category);
CREATE INDEX idx_developer_faqs_difficulty ON developer_faqs(difficulty_level);
CREATE INDEX idx_developer_faqs_tags ON developer_faqs USING GIN(tags);
CREATE INDEX idx_developer_faqs_search ON developer_faqs USING GIN(
  to_tsvector('english', question || ' ' || answer || ' ' || COALESCE(code_example, ''))
);

-- =============================================================================
-- 4. DESIGN FAQs
-- =============================================================================

CREATE TABLE IF NOT EXISTS design_faqs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category TEXT NOT NULL CHECK (category IN (
    'tokens', 'components', 'figma', 'branding',
    'accessibility', 'responsive', 'composition', 'general'
  )),
  tool TEXT CHECK (tool IN (
    'figma', 'sketch', 'adobe_xd', 'framer', 'storybook', 'general'
  )),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  visual_example_url TEXT,  -- Screenshot/mockup URL
  figma_file_url TEXT,
  tags TEXT[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for design FAQs
CREATE INDEX idx_design_faqs_category ON design_faqs(category);
CREATE INDEX idx_design_faqs_tool ON design_faqs(tool);
CREATE INDEX idx_design_faqs_tags ON design_faqs USING GIN(tags);
CREATE INDEX idx_design_faqs_search ON design_faqs USING GIN(
  to_tsvector('english', question || ' ' || answer)
);

-- =============================================================================
-- 5. SECURITY & COMPLIANCE FAQs
-- =============================================================================

CREATE TABLE IF NOT EXISTS security_compliance_faqs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category TEXT NOT NULL CHECK (category IN (
    'encryption', 'audit', 'compliance', 'access_control',
    'incident_response', 'penetration_testing', 'vulnerability', 'general'
  )),
  regulation TEXT,  -- 'GDPR', 'CCPA', 'PCI-DSS', 'SOC2', 'GLBA', etc.
  severity_level TEXT CHECK (severity_level IN (
    'low', 'medium', 'high', 'critical'
  )),
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  policy_reference TEXT,  -- Link to official policy
  audit_trail_location TEXT,  -- Where to find audit logs
  compliance_framework TEXT[],  -- ['SOC2', 'ISO27001', 'NIST']
  tags TEXT[] DEFAULT '{}',
  display_order INTEGER DEFAULT 0,
  last_audit_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for security/compliance FAQs
CREATE INDEX idx_security_faqs_category ON security_compliance_faqs(category);
CREATE INDEX idx_security_faqs_regulation ON security_compliance_faqs(regulation);
CREATE INDEX idx_security_faqs_severity ON security_compliance_faqs(severity_level);
CREATE INDEX idx_security_faqs_tags ON security_compliance_faqs USING GIN(tags);
CREATE INDEX idx_security_faqs_search ON security_compliance_faqs USING GIN(
  to_tsvector('english', question || ' ' || answer)
);

-- =============================================================================
-- AUTO-UPDATE TIMESTAMPS
-- =============================================================================

CREATE OR REPLACE FUNCTION update_faq_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER member_faqs_updated_at
  BEFORE UPDATE ON member_faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_faq_timestamp();

CREATE TRIGGER staff_faqs_updated_at
  BEFORE UPDATE ON staff_training_faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_faq_timestamp();

CREATE TRIGGER developer_faqs_updated_at
  BEFORE UPDATE ON developer_faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_faq_timestamp();

CREATE TRIGGER design_faqs_updated_at
  BEFORE UPDATE ON design_faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_faq_timestamp();

CREATE TRIGGER security_faqs_updated_at
  BEFORE UPDATE ON security_compliance_faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_faq_timestamp();

-- =============================================================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================================================

-- Enable RLS on all FAQ tables
ALTER TABLE member_faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_training_faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE developer_faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE design_faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_compliance_faqs ENABLE ROW LEVEL SECURITY;

-- Member FAQs: Members can read their CU's FAQs
CREATE POLICY "Members can read their CU's FAQs"
  ON member_faqs FOR SELECT
  TO authenticated
  USING (cu_id = (SELECT cu_id FROM user_profiles WHERE id = auth.uid()));

-- Staff FAQs: Staff can read their CU's training materials
CREATE POLICY "Staff can read their CU's training FAQs"
  ON staff_training_faqs FOR SELECT
  TO authenticated
  USING (
    cu_id = (SELECT cu_id FROM user_profiles WHERE id = auth.uid())
    AND (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('staff', 'admin', 'manager')
  );

-- Developer FAQs: All authenticated developers can read
CREATE POLICY "Developers can read all developer FAQs"
  ON developer_faqs FOR SELECT
  TO authenticated
  USING (true);

-- Design FAQs: All authenticated designers can read
CREATE POLICY "Designers can read all design FAQs"
  ON design_faqs FOR SELECT
  TO authenticated
  USING (true);

-- Security/Compliance FAQs: Admins and security teams only
CREATE POLICY "Security teams can read compliance FAQs"
  ON security_compliance_faqs FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('admin', 'security', 'compliance')
  );

-- Admin policies for managing FAQs
CREATE POLICY "Admins can manage all FAQs"
  ON member_faqs FOR ALL
  TO authenticated
  USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can manage staff FAQs"
  ON staff_training_faqs FOR ALL
  TO authenticated
  USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can manage developer FAQs"
  ON developer_faqs FOR ALL
  TO authenticated
  USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can manage design FAQs"
  ON design_faqs FOR ALL
  TO authenticated
  USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) = 'admin');

CREATE POLICY "Admins can manage security FAQs"
  ON security_compliance_faqs FOR ALL
  TO authenticated
  USING ((SELECT role FROM user_profiles WHERE id = auth.uid()) IN ('admin', 'security'));

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================

-- Function: Search FAQs with full-text search
CREATE OR REPLACE FUNCTION search_member_faqs(
  p_cu_id TEXT,
  p_search_query TEXT,
  p_category TEXT DEFAULT NULL
)
RETURNS SETOF member_faqs AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM member_faqs
  WHERE cu_id = p_cu_id
    AND (p_category IS NULL OR category = p_category)
    AND to_tsvector('english', question || ' ' || answer) @@ plainto_tsquery('english', p_search_query)
  ORDER BY
    helpful_count DESC,
    is_featured DESC,
    display_order ASC,
    created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get featured FAQs
CREATE OR REPLACE FUNCTION get_featured_faqs(p_cu_id TEXT, p_limit INTEGER DEFAULT 5)
RETURNS SETOF member_faqs AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM member_faqs
  WHERE cu_id = p_cu_id AND is_featured = true
  ORDER BY display_order ASC, helpful_count DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Function: Increment FAQ view count
CREATE OR REPLACE FUNCTION increment_faq_view(p_faq_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE member_faqs
  SET view_count = view_count + 1
  WHERE id = p_faq_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Mark FAQ as helpful
CREATE OR REPLACE FUNCTION mark_faq_helpful(p_faq_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE member_faqs
  SET helpful_count = helpful_count + 1
  WHERE id = p_faq_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE member_faqs IS 'Member-facing FAQs with CU-specific branding';
COMMENT ON TABLE staff_training_faqs IS 'Staff training materials for helping members';
COMMENT ON TABLE developer_faqs IS 'Platform-wide developer documentation FAQs';
COMMENT ON TABLE design_faqs IS 'Design system FAQs for UI/UX designers';
COMMENT ON TABLE security_compliance_faqs IS 'Security and compliance FAQs for auditors';

COMMENT ON FUNCTION search_member_faqs IS 'Full-text search for member FAQs';
COMMENT ON FUNCTION get_featured_faqs IS 'Get top featured FAQs for dashboard';
COMMENT ON FUNCTION increment_faq_view IS 'Track FAQ views for analytics';
COMMENT ON FUNCTION mark_faq_helpful IS 'Track helpful FAQs for ranking';

-- =============================================================================
-- SAMPLE DATA (for testing)
-- =============================================================================

-- Sample member FAQ (will be replaced with AI-generated content)
INSERT INTO member_faqs (cu_id, category, question, answer, tags, is_featured)
VALUES (
  'demo',
  'login',
  'How do I reset my password?',
  'To reset your password, tap "Forgot Password" on the login screen, enter your email address, and follow the instructions in the reset email.',
  ARRAY['password', 'reset', 'login', 'security'],
  true
) ON CONFLICT DO NOTHING;

-- Sample developer FAQ
INSERT INTO developer_faqs (category, difficulty_level, question, answer, code_example, tags)
VALUES (
  'api',
  'beginner',
  'How do I authenticate API requests?',
  'All API requests must include a valid JWT token in the Authorization header. Obtain tokens via the /auth/token endpoint.',
  'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  ARRAY['authentication', 'jwt', 'api']
) ON CONFLICT DO NOTHING;

-- Sample security FAQ
INSERT INTO security_compliance_faqs (category, regulation, severity_level, question, answer, tags)
VALUES (
  'encryption',
  'PCI-DSS',
  'high',
  'How is cardholder data encrypted at rest?',
  'All cardholder data is encrypted using AES-256 encryption. Encryption keys are managed via AWS KMS with automatic rotation every 90 days.',
  ARRAY['encryption', 'PCI-DSS', 'compliance']
) ON CONFLICT DO NOTHING;

-- Feature Content Cache Table
-- Stores AI-generated content for banking features to avoid regeneration

CREATE TABLE IF NOT EXISTS feature_content_cache (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cu_id TEXT NOT NULL REFERENCES cu_configurations(cu_id) ON DELETE CASCADE,
  feature_name TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure one content per feature per CU
  UNIQUE(cu_id, feature_name)
);

-- Index for fast lookups
CREATE INDEX idx_feature_content_cu ON feature_content_cache(cu_id);
CREATE INDEX idx_feature_content_feature ON feature_content_cache(feature_name);

-- RLS Policies
ALTER TABLE feature_content_cache ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read cached content
CREATE POLICY "Allow authenticated users to read feature content"
  ON feature_content_cache
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow service role to insert/update content
CREATE POLICY "Allow service role to manage feature content"
  ON feature_content_cache
  FOR ALL
  TO service_role
  USING (true);

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_feature_content_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER feature_content_updated_at
  BEFORE UPDATE ON feature_content_cache
  FOR EACH ROW
  EXECUTE FUNCTION update_feature_content_timestamp();

COMMENT ON TABLE feature_content_cache IS 'Caches AI-generated Figma content for banking features to reduce API costs';

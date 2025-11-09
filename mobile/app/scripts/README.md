# CU Feature Content Generator

Automated content generation for credit union banking app features, optimized for Figma design workflows.

## Overview

This tool generates comprehensive, CU-branded content tables for banking features that can be directly imported into Figma using the Google Sheets Sync plugin.

**Key Features:**
- ✅ **Variable CU Branding** - Works with any credit union configuration
- ✅ **AI-Powered Content** - Uses GPT-4 to generate contextual, professional content
- ✅ **Figma-Ready** - Outputs CSV format compatible with Google Sheets Sync plugin
- ✅ **Caching** - Stores generated content in Supabase to avoid regeneration
- ✅ **Batch Processing** - Generates content for 60+ features automatically
- ✅ **No Browser Automation** - Uses Supabase Edge Functions instead of brittle browser scripts

## Architecture

```
┌─────────────────┐
│  Python Script  │
│  (CLI Client)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Supabase Edge Function │
│  generate-feature-content│
└────────┬────────────────┘
         │
         ├──► OpenAI GPT-4 API
         │
         └──► Supabase DB (Cache)
```

## Setup

### 1. Environment Variables

```bash
# Supabase Configuration
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"

# OpenAI API Key (for Edge Function)
export OPENAI_API_KEY="sk-..."
```

### 2. Deploy Edge Function

```bash
cd cu_core_banking_app
supabase functions deploy generate-feature-content --no-verify-jwt
```

### 3. Run Database Migration

```bash
supabase db push
```

## Usage

### Generate Content for a Single CU

```bash
python scripts/generate_feature_content.py navyfederal \
  --output figma_content_navyfederal.csv
```

### Generate for Specific Features Only

```bash
python scripts/generate_feature_content.py becu \
  --features "Dashboard Screen" "Login Screen" "Transaction History" \
  --output figma_content_becu.csv
```

### Generate for Multiple CUs (Batch)

```bash
#!/bin/bash
CU_IDS=("navyfederal" "becu" "golden1" "penfed" "alliant")

for cu_id in "${CU_IDS[@]}"; do
  echo "Generating content for $cu_id..."
  python scripts/generate_feature_content.py "$cu_id" \
    --output "figma_content_${cu_id}.csv"
  sleep 5  # Rate limiting between CUs
done
```

## Output Format

The script generates a CSV file with 30 columns:

| Column | Description |
|--------|-------------|
| Feature | Feature name (e.g., "Dashboard Screen") |
| Slot 1 | Purpose of feature |
| Slot 2 | Information displayed |
| Slot 3 | Member actions available |
| Slot 4 | Fields displayed |
| Slot 5 | Possible scenarios |
| ... | ... |
| Slot 29 | Desktop optimization ideas |

## Importing to Figma

1. Upload CSV to Google Sheets
2. Install **Google Sheets Sync** plugin in Figma
3. Connect the plugin to your Google Sheet
4. Map columns to text layers in your Figma design
5. Sync content across all artboards

## Feature List

The generator supports 60+ core banking features:

**Authentication & Security:**
- Splash Screen
- Join Now Screen
- Login Screen
- Multi-factor Authentication
- Identity Verification
- Forgot Password

**Account Management:**
- Dashboard
- Checking Account Overview
- Savings Account Overview
- Credit Card Overview
- Mortgage Overview
- Transaction History

**Transfers & Payments:**
- Internal Transfers
- External Transfers
- Bill Pay
- Mobile Check Deposit

**Services:**
- Digital Card Management
- Financial Insights
- Branch & ATM Locations
- eStatements
- Document Upload
- Rewards Program

**Communication:**
- In-App Chat
- Contact CU
- AI Chatbot
- Feedback

## Caching

Generated content is automatically cached in the `feature_content_cache` table:

```sql
SELECT
  cu_id,
  feature_name,
  LEFT(content, 100) as content_preview,
  updated_at
FROM feature_content_cache
WHERE cu_id = 'navyfederal'
ORDER BY updated_at DESC;
```

To regenerate content (bypass cache), delete the cached row:

```sql
DELETE FROM feature_content_cache
WHERE cu_id = 'navyfederal'
AND feature_name = 'Dashboard Screen';
```

## Cost Optimization

**OpenAI API Costs:**
- ~60 features × 2000 tokens per feature = ~120,000 tokens
- GPT-4 Turbo: $0.01/1K input + $0.03/1K output tokens
- Estimated cost per CU: **~$4-6**

**Caching Benefits:**
- First generation: $4-6
- Subsequent uses: $0 (uses cache)
- Regenerate only when content needs updating

## Comparison: Old vs New Approach

### ❌ Old Approach (Browser Automation)

```python
# Brittle, slow, unreliable
for feature in features:
    pyperclip.copy(question)
    os.system('open Microsoft Edge')
    os.system('paste')
    os.system('press enter')
    time.sleep(30)  # Wait for ChatGPT response
```

**Problems:**
- Requires Microsoft Edge running
- Depends on UI layout
- Breaks with browser updates
- No caching
- Manual copy-paste required
- Hardcoded "Suncoast" references

### ✅ New Approach (Edge Functions)

```python
# Fast, reliable, scalable
result = generate_feature_content(
    cu_id='navyfederal',
    output_file='content.csv'
)
```

**Benefits:**
- ✅ Works for ANY credit union
- ✅ Fully automated API calls
- ✅ Built-in caching
- ✅ Batch processing
- ✅ Direct CSV export
- ✅ No browser required
- ✅ Variable CU branding

## Examples

### Generate for Navy Federal Credit Union

```bash
python scripts/generate_feature_content.py navyfederal \
  --output nfcu_content.csv
```

**Output:**
```csv
Feature,Slot 1,Slot 2,Slot 3,...
Dashboard Screen,Provide members with an overview of their Navy Federal accounts,Account balances...,View account details...
Login Screen,Authenticate Navy Federal members securely,Username field...,Enter credentials...
```

### Generate for BECU

```bash
python scripts/generate_feature_content.py becu \
  --features "Dashboard Screen" "Mobile Check Deposit" \
  --output becu_partial.csv
```

## Troubleshooting

### Error: "CU not found"

Make sure the CU configuration exists in `cu_configurations` table:

```sql
SELECT cu_id, name FROM cu_configurations WHERE cu_id = 'navyfederal';
```

### Error: "OpenAI API key not set"

Set the environment variable in your Edge Function:

```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

### Content Generation is Slow

This is expected for batch mode (60+ features). The function includes rate limiting to avoid OpenAI API rate limits:

- 2 seconds between requests
- ~2 minutes total for all features

## Future Enhancements

- [ ] Support for custom feature lists per CU
- [ ] Multi-language content generation
- [ ] A/B testing content variations
- [ ] Direct Figma API integration (skip CSV export)
- [ ] Real-time content preview
- [ ] Bulk regeneration for all CUs

## Related Files

- `supabase/functions/generate-feature-content/index.ts` - Edge Function
- `supabase/migrations/20250110000003_feature_content_cache.sql` - Database schema
- `scripts/generate_feature_content.py` - Python CLI client
- `scripts/legacy_suncoast_script.py` - Old browser automation (deprecated)

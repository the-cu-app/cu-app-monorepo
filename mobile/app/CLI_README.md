# CU CLI - Unified Command-Line Tool

A powerful, unified CLI tool for managing your white-label credit union banking platform. Replaces scattered Python scripts, manual processes, and complex workflows with a single, intuitive command-line interface.

## 🚀 Quick Start

### Installation

1. **Make the CLI executable:**
   ```bash
   chmod +x cu
   ```

2. **Add to PATH (optional but recommended):**
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   export PATH="$PATH:/path/to/cu_core_banking_app"

   # Or create a symlink
   ln -s /path/to/cu_core_banking_app/cu /usr/local/bin/cu
   ```

3. **Configure environment:**
   ```bash
   export SUPABASE_URL="https://your-project.supabase.co"
   export SUPABASE_ANON_KEY="your-anon-key"
   export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
   export OPENAI_API_KEY="sk-..."
   ```

4. **Verify installation:**
   ```bash
   cu --help
   ```

### Prerequisites

- **jq** - JSON processor: `brew install jq`
- **curl** - HTTP client (usually pre-installed)
- **Flutter** - For app builds: `brew install flutter`
- **Python 3** - For content generation scripts: `brew install python3`
- **Supabase CLI** (optional) - For function deployment: `brew install supabase/tap/supabase`

## 📋 Commands

### `cu setup` - Interactive CU Setup Wizard

Set up a new credit union with a guided, interactive wizard.

```bash
# Run the interactive wizard
cu setup

# Non-interactive (coming soon)
cu setup --cu-id navyfederal --name "Navy Federal Credit Union"
```

**What it does:**
- ✅ Collects all CU information with validation
- ✅ Creates Supabase database entries
- ✅ Configures feature flags
- ✅ Generates FAQs and Figma content automatically
- ✅ Provides next steps for deployment

**Time:** ~5-10 minutes (including content generation)

---

### `cu content` - Generate Content

Generate FAQs, Figma content, and documentation for your CUs.

```bash
# Generate all content for a CU
cu content generate --cu-id navyfederal --all

# Generate member FAQs only
cu content generate --cu-id navyfederal --type member

# Generate specific FAQ categories
cu content generate --cu-id becu --type member \
  --categories login,transfers,deposits

# Generate Figma content and export to CSV
cu content generate --cu-id golden1 --type figma \
  --output figma_golden1.csv

# Generate platform-wide developer FAQs
cu content generate --type developer

# Preview content before generating (coming soon)
cu content preview --cu-id navyfederal --type member

# Export existing content (coming soon)
cu content export --cu-id navyfederal --type member \
  --output member_faqs.json
```

**Content Types:**
- `member` - Member-facing FAQs (requires --cu-id)
- `staff` - Staff training FAQs (requires --cu-id)
- `developer` - Developer documentation (platform-wide)
- `design` - Design system FAQs (platform-wide)
- `security` - Security & compliance FAQs (platform-wide)
- `figma` - Figma-ready CSV content (requires --cu-id)

**Cost Estimates:**
- Member FAQs: ~$3.00
- Staff FAQs: ~$1.50
- Figma content: ~$5.00
- Platform FAQs: ~$1.50 each
- All content: ~$10.00 per CU

---

### `cu deploy` - Deploy Apps & Services

Build and deploy iOS, Android, web apps, and Supabase functions.

```bash
# Deploy everything for a CU
cu deploy --cu-id navyfederal --target all

# Deploy iOS app only
cu deploy --cu-id navyfederal --target ios --env production

# Deploy Android app
cu deploy --cu-id navyfederal --target android

# Deploy web app
cu deploy --cu-id navyfederal --target web

# Deploy Supabase functions only
cu deploy --target functions

# Skip tests
cu deploy --cu-id navyfederal --target all --skip-tests

# Rollback deployment (coming soon)
cu deploy --cu-id navyfederal --rollback
```

**Targets:**
- `ios` - Build iOS app (`.ipa`)
- `android` - Build Android app (`.apk`)
- `web` - Build web app
- `functions` - Deploy Supabase Edge Functions
- `all` - Build and deploy everything

**Environments:**
- `dev` - Development (default)
- `staging` - Staging
- `production` - Production

---

### `cu monitor` - Monitor Health & Metrics

Real-time monitoring of CU health, metrics, and status.

```bash
# Show dashboard for all CUs
cu monitor --dashboard

# Monitor specific CU
cu monitor --cu-id navyfederal

# Show detailed metrics
cu monitor --cu-id navyfederal --metrics

# Watch logs (coming soon)
cu monitor --cu-id navyfederal --logs

# Auto-refresh every 5 seconds
cu monitor --dashboard --refresh 5
```

**Metrics Tracked:**
- ✅ CU status (active/inactive)
- ✅ FAQ counts (member, staff)
- ✅ Feature flag counts
- ⏳ API usage (coming soon)
- ⏳ Error rates (coming soon)
- ⏳ User engagement (coming soon)

---

### `cu doctor` - Run Diagnostics

Comprehensive health checks and diagnostics for your CU platform.

```bash
# Check everything
cu doctor

# Check specific CU
cu doctor --cu-id navyfederal

# Check and auto-fix issues (coming soon)
cu doctor --cu-id navyfederal --fix

# Verbose output
cu doctor --cu-id navyfederal --verbose
```

**Checks Performed:**
- ✅ Environment variables configured
- ✅ Supabase connection working
- ✅ Required commands installed (flutter, jq, curl, python3)
- ✅ Database tables exist
- ✅ CU configuration valid
- ✅ Logo URLs accessible
- ✅ FAQ content generated
- ✅ Feature flags configured

**Exit Codes:**
- `0` - All checks passed
- `1` - Critical issues found

---

### `cu config` - Manage Configurations

View and update CU configurations, feature flags, and branding.

```bash
# Show CU configuration
cu config show --cu-id navyfederal

# Show in JSON format
cu config show --cu-id navyfederal --json

# Update CU name
cu config update --cu-id navyfederal --name "Navy Federal CU"

# Update branding colors
cu config branding --cu-id navyfederal \
  --colors "#003366,#DCB767"

# Update logo URL
cu config branding --cu-id navyfederal \
  --logo "https://cdn.navyfederal.app/logo.svg"

# List feature flags
cu config feature-flags --cu-id navyfederal --list

# Enable a feature
cu config feature-flags --cu-id navyfederal \
  --enable ai_coaching

# Disable a feature (coming soon)
cu config feature-flags --cu-id navyfederal \
  --disable mobile_deposit

# Delete CU (coming soon, with confirmation)
cu config delete --cu-id navyfederal
```

---

### `cu list` - List All CUs

Show all configured credit unions.

```bash
cu list
```

**Output:**
```
Credit Unions

CU Code                        Name                           Status
─────────────────────────────────────────────────────────────────────────────
navyfederal                    Navy Federal Credit Union      ● Active
becu                           BECU                           ● Active
golden1                        Golden 1 Credit Union          ● Inactive

Found 3 credit union(s)
```

---

### `cu version` - Show Version

Display CLI version information.

```bash
cu version
```

---

### `cu help` - Show Help

Display help for any command.

```bash
# General help
cu help

# Command-specific help
cu setup --help
cu content --help
cu deploy --help
```

## 🎯 Common Workflows

### Set Up Your First CU (5-10 minutes)

```bash
# 1. Run the setup wizard
cu setup

# Follow the interactive prompts:
# - Enter CU ID (e.g., navyfederal)
# - Enter CU name, contact info
# - Configure branding (colors, logo)
# - Select features to enable
# - Auto-generate content (FAQs, Figma)

# 2. Verify the setup
cu config show --cu-id navyfederal
cu doctor --cu-id navyfederal

# 3. Build and deploy
cu deploy --cu-id navyfederal --target all
```

**Result:** Production-ready CU in ~10 minutes!

---

### Generate Content for Multiple CUs

```bash
# List of CUs
CUS="navyfederal becu golden1 penfed alliant"

# Generate all content for each CU
for cu_id in $CUS; do
  echo "Generating content for $cu_id..."
  cu content generate --cu-id $cu_id --all
  sleep 5  # Rate limiting
done
```

---

### Monitor Platform Health

```bash
# Live dashboard with auto-refresh
cu monitor --dashboard --refresh 10

# Or in a separate terminal, run doctor periodically
watch -n 60 cu doctor
```

---

### Update Branding for All CUs

```bash
#!/bin/bash
# update_branding.sh

CU_ID="$1"
PRIMARY="$2"
SECONDARY="$3"

cu config branding --cu-id "$CU_ID" --colors "$PRIMARY,$SECONDARY"
cu config show --cu-id "$CU_ID"
```

Usage:
```bash
./update_branding.sh navyfederal "#003366" "#DCB767"
```

---

## 🔧 Advanced Usage

### Environment Variables

```bash
# Required
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"  # For admin operations
export OPENAI_API_KEY="sk-..."  # For content generation

# Optional
export CU_CLI_LOG_DIR="$HOME/.cu-cli/logs"  # Log directory
export CU_CLI_LOG_LEVEL=1  # 0=DEBUG, 1=INFO, 2=WARN, 3=ERROR
```

### Global Options

```bash
# Verbose output (show all commands)
cu --verbose setup

# Quiet mode (errors only)
cu --quiet list

# JSON output
cu --json config show --cu-id navyfederal

# Dry run (show what would be done)
cu --dry-run deploy --cu-id navyfederal --target all
```

### Logging

Logs are automatically saved to `$HOME/.cu-cli/logs/`:

```bash
# View today's log
tail -f ~/.cu-cli/logs/cu-cli-$(date +%Y%m%d).log

# Search logs
grep "ERROR" ~/.cu-cli/logs/*.log

# Clean old logs (automatic, keeps last 7 days)
# Manual cleanup:
rm ~/.cu-cli/logs/cu-cli-*.log
```

## 🐛 Troubleshooting

### "Command not found: cu"

**Solution:** Add CLI to PATH or use absolute path:
```bash
export PATH="$PATH:/path/to/cu_core_banking_app"
# Or
./cu setup
```

### "Supabase not configured"

**Solution:** Set environment variables:
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
```

### "Failed to create CU: Unauthorized"

**Solution:** Set service role key for admin operations:
```bash
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
```

### "Required command not found: jq"

**Solution:** Install missing dependencies:
```bash
brew install jq        # macOS
apt-get install jq     # Linux
```

### Content generation failing

**Solution:** Check OpenAI API key and Supabase function deployment:
```bash
# Verify OpenAI key
echo $OPENAI_API_KEY

# Check Supabase functions
supabase functions list

# Redeploy if needed
cu deploy --target functions
```

### Run diagnostics

```bash
# Check everything
cu doctor

# Check specific CU
cu doctor --cu-id navyfederal
```

## 📚 Examples

See the [examples/](examples/) directory for:
- Batch CU setup scripts
- Custom content generation workflows
- Deployment automation examples
- Monitoring dashboards

## 🤝 Contributing

Contributions welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📝 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation:** [docs.cu.app](https://docs.cu.app)
- **Issues:** [GitHub Issues](https://github.com/yourusername/cu-app/issues)
- **Email:** support@cu.app

---

**Built with ❤️ for the CU community**

*Making multi-tenant banking platforms manageable, one command at a time.*

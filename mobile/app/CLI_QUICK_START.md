# CU CLI - Quick Start Guide

## ⚡️ Installation (30 seconds)

```bash
# 1. Make executable
chmod +x cu

# 2. Add to PATH (optional)
export PATH="$PATH:$(pwd)"

# 3. Configure (required)
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
export OPENAI_API_KEY="sk-..."

# 4. Test
./cu --help
```

## 🎯 Most Common Commands

### Set Up Your First CU (5-10 minutes)
```bash
cu setup
# Follow the interactive prompts
# ✅ Creates CU in database
# ✅ Auto-generates FAQs
# ✅ Creates Figma content
```

### List All CUs
```bash
cu list
```

### Generate Content
```bash
# All content for a CU
cu content generate --cu-id navyfederal --all

# Member FAQs only
cu content generate --cu-id navyfederal --type member

# Figma content → CSV
cu content generate --cu-id navyfederal --type figma \
  --output figma_navyfederal.csv
```

### Monitor Health
```bash
# Dashboard (all CUs)
cu monitor --dashboard

# Specific CU
cu monitor --cu-id navyfederal

# Auto-refresh every 5 seconds
cu monitor --dashboard --refresh 5
```

### Run Diagnostics
```bash
# Check everything
cu doctor

# Check specific CU
cu doctor --cu-id navyfederal
```

### Manage Configuration
```bash
# Show config
cu config show --cu-id navyfederal

# Update branding
cu config branding --cu-id navyfederal \
  --colors "#003366,#DCB767"

# List feature flags
cu config feature-flags --cu-id navyfederal --list

# Enable feature
cu config feature-flags --cu-id navyfederal --enable ai_coaching
```

### Deploy
```bash
# Build everything
cu deploy --cu-id navyfederal --target all

# iOS only
cu deploy --cu-id navyfederal --target ios

# Deploy functions
cu deploy --target functions
```

## 📝 Command Cheat Sheet

| Command | What It Does | Time |
|---------|--------------|------|
| `cu setup` | Create new CU (wizard) | 5-10 min |
| `cu list` | List all CUs | 1 sec |
| `cu content generate` | Generate FAQs/Figma | 2-5 min |
| `cu monitor` | View dashboard | 1 sec |
| `cu doctor` | Run health checks | 5 sec |
| `cu config show` | View CU settings | 1 sec |
| `cu deploy` | Build & deploy | 5-10 min |

## 🆘 Troubleshooting

### "Command not found: cu"
```bash
# Use absolute path
./cu setup

# Or add to PATH
export PATH="$PATH:$(pwd)"
```

### "Supabase not configured"
```bash
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
```

### "Required command not found: jq"
```bash
brew install jq        # macOS
apt-get install jq     # Linux
```

### Need help?
```bash
cu help                    # General help
cu setup --help            # Command-specific help
cu doctor                  # Run diagnostics
```

## 🎬 5-Minute Demo

```bash
# 1. Setup wizard
cu setup
# Enter: navyfederal, Navy Federal Credit Union, colors, etc.
# Wait for content generation (~3 min)

# 2. Verify setup
cu config show --cu-id navyfederal
cu doctor --cu-id navyfederal

# 3. Monitor
cu monitor --cu-id navyfederal

# 4. Build
cu deploy --cu-id navyfederal --target all
```

## 📚 Full Documentation

See [CLI_README.md](CLI_README.md) for complete documentation.

---

**That's it! You're ready to manage 200+ CUs from a single CLI.** 🚀

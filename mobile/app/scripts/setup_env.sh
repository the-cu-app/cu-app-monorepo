#!/bin/bash

# Environment Setup Script
# Securely configures API keys and environment variables

set -e

echo "🔐 Secure Environment Setup"
echo "============================"
echo ""

# Check if .env already exists
if [ -f .env ]; then
  echo "⚠️  .env file already exists!"
  read -p "Do you want to overwrite it? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting. Existing .env file preserved."
    exit 0
  fi
fi

# Prompt for Supabase credentials
echo "📍 Supabase Configuration"
echo "  (Get from: https://app.supabase.com/project/_/settings/api)"
echo ""

read -p "Supabase URL (https://xxxxx.supabase.co): " SUPABASE_URL
read -p "Supabase Anon Key: " SUPABASE_ANON_KEY
read -sp "Supabase Service Role Key (hidden): " SUPABASE_SERVICE_ROLE_KEY
echo ""

# Prompt for OpenAI API key
echo ""
echo "🤖 OpenAI Configuration"
echo "  (Get from: https://platform.openai.com/api-keys)"
echo ""

read -sp "OpenAI API Key (sk-...): " OPENAI_API_KEY
echo ""

# Prompt for Vercel token (optional)
echo ""
echo "▲ Vercel Configuration (Optional)"
echo "  (Get from: https://vercel.com/account/tokens)"
echo ""

read -p "Vercel Token (optional, press Enter to skip): " VERCEL_TOKEN

# Prompt for GoDaddy API credentials (optional)
echo ""
echo "🌐 GoDaddy API Configuration (Optional)"
echo "  (Get from: https://developer.godaddy.com/keys)"
echo ""

read -p "GoDaddy API Key (optional, press Enter to skip): " GODADDY_API_KEY
read -p "GoDaddy API Secret (optional, press Enter to skip): " GODADDY_API_SECRET

# Create .env file
cat > .env << EOF
# Supabase Configuration
SUPABASE_URL=$SUPABASE_URL
SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=$SUPABASE_SERVICE_ROLE_KEY

# OpenAI API Key
OPENAI_API_KEY=$OPENAI_API_KEY

# Vercel Configuration
VERCEL_TOKEN=$VERCEL_TOKEN

# GoDaddy API (for DNS automation)
GODADDY_API_KEY=$GODADDY_API_KEY
GODADDY_API_SECRET=$GODADDY_API_SECRET

# Next.js Configuration
NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
EOF

# Secure the file
chmod 600 .env

# Add to .gitignore
if ! grep -q "^\.env$" .gitignore 2>/dev/null; then
  echo ".env" >> .gitignore
  echo "✅ Added .env to .gitignore"
fi

echo ""
echo "✅ Environment configuration complete!"
echo ""
echo "Credentials saved to: .env"
echo "File permissions: 600 (read/write for owner only)"
echo ""
echo "Next steps:"
echo "  1. Verify: cat .env"
echo "  2. Set Supabase secrets: ./scripts/setup_supabase_secrets.sh"
echo "  3. Deploy: ./scripts/deploy_complete_portfolio.sh"
echo ""

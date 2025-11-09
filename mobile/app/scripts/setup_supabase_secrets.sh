#!/bin/bash

# Supabase Secrets Setup
# Configures secrets for Edge Functions

set -e

echo "🔐 Supabase Secrets Setup"
echo "========================="
echo ""

# Load environment variables
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found!"
  echo "Run ./scripts/setup_env.sh first"
  exit 1
fi

source .env

# Check if logged in to Supabase
if ! supabase projects list &> /dev/null; then
  echo "Please login to Supabase first:"
  supabase login
fi

# Prompt for project reference
echo "📍 Supabase Project"
echo ""
echo "Available projects:"
supabase projects list
echo ""

read -p "Enter your project reference ID: " PROJECT_REF

# Link to project
echo ""
echo "Linking to project..."
supabase link --project-ref $PROJECT_REF

# Set secrets
echo ""
echo "Setting Edge Function secrets..."

supabase secrets set OPENAI_API_KEY="$OPENAI_API_KEY"

echo ""
echo "✅ Secrets configured!"
echo ""
echo "Verify with: supabase secrets list"
echo ""

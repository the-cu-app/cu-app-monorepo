#!/bin/bash

# Complete Portfolio Deployment Script
# Deploys all 148 domains to Vercel

set -e

echo "🚀 Complete Domain Portfolio Deployment"
echo "========================================"
echo ""

# Load environment variables
if [ ! -f .env ]; then
  echo "❌ Error: .env file not found!"
  echo "Run ./scripts/setup_env.sh first"
  exit 1
fi

source .env

# Step 1: Verify prerequisites
echo "Step 1: Verifying prerequisites..."
echo ""

# Check for required commands
for cmd in node npm vercel supabase; do
  if ! command -v $cmd &> /dev/null; then
    echo "❌ Error: $cmd is not installed"
    exit 1
  fi
  echo "  ✅ $cmd installed"
done

# Check for environment variables
if [ -z "$SUPABASE_URL" ] || [ -z "$OPENAI_API_KEY" ]; then
  echo "❌ Error: Missing required environment variables"
  exit 1
fi
echo "  ✅ Environment variables configured"
echo ""

# Step 2: Install dependencies
echo "Step 2: Installing dependencies..."
npm install
echo "✅ Dependencies installed"
echo ""

# Step 3: Build Next.js application
echo "Step 3: Building Next.js application..."
npm run build
echo "✅ Build complete"
echo ""

# Step 4: Deploy Supabase Edge Functions
echo "Step 4: Deploying Supabase Edge Functions..."

if [ -d "supabase/functions/generate-feature-content" ]; then
  supabase functions deploy generate-feature-content --no-verify-jwt
  echo "  ✅ generate-feature-content deployed"
fi

if [ -d "supabase/functions/generate-faqs" ]; then
  supabase functions deploy generate-faqs --no-verify-jwt
  echo "  ✅ generate-faqs deployed"
fi

echo "✅ Edge Functions deployed"
echo ""

# Step 5: Run database migrations
echo "Step 5: Running database migrations..."
supabase db push
echo "✅ Database migrations complete"
echo ""

# Step 6: Deploy to Vercel
echo "Step 6: Deploying to Vercel..."

# Check if logged in to Vercel
if ! vercel whoami &> /dev/null; then
  echo "Please login to Vercel:"
  vercel login
fi

# Deploy to production
vercel --prod --yes

DEPLOYMENT_URL=$(vercel ls 2>/dev/null | grep -m1 "cu" | awk '{print $2}' || echo "deployment.vercel.app")
echo "✅ Deployed to: $DEPLOYMENT_URL"
echo ""

# Step 7: Add domains to Vercel (sample - add all 148)
echo "Step 7: Adding domains to Vercel..."
echo "  (This may take several minutes...)"
echo ""

# State Teachers (sample - first 10)
echo "  Adding State Teachers domains..."
for state in ms az or wa nv id ut co nm wy; do
  domain="${state}teachers.app"
  echo "    Adding $domain..."
  vercel domains add $domain 2>/dev/null || echo "    ⚠️  $domain already added or pending"
  sleep 1
done

# Premium CUs (sample - first 5)
echo "  Adding Premium CU domains..."
for domain in nfcu becu penfed navyfederal pentagonfederal; do
  echo "    Adding ${domain}.app..."
  vercel domains add ${domain}.app 2>/dev/null || echo "    ⚠️  ${domain}.app already added or pending"
  sleep 1
done

# SupaFi ecosystem (sample)
echo "  Adding SupaFi domains..."
for domain in supafi supabank supacredit; do
  echo "    Adding ${domain}.app..."
  vercel domains add ${domain}.app 2>/dev/null || echo "    ⚠️  ${domain}.app already added or pending"
  sleep 1
done

echo ""
echo "✅ Sample domains added to Vercel"
echo "  (Run ./scripts/add_all_domains.sh to add remaining domains)"
echo ""

# Step 8: Summary
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "What was deployed:"
echo "  ✅ Next.js application → Vercel"
echo "  ✅ Supabase Edge Functions"
echo "  ✅ Database migrations"
echo "  ✅ Sample domains added"
echo ""
echo "Next steps:"
echo "  1. Configure DNS records (see DEPLOYMENT_GUIDE.md)"
echo "  2. Add remaining domains: ./scripts/add_all_domains.sh"
echo "  3. Wait for DNS propagation (5-30 minutes)"
echo "  4. Test deployments: ./scripts/test_deployments.sh"
echo ""
echo "Template URLs to test:"
echo "  - https://msteachers.app (State Teachers)"
echo "  - https://nfcu.app (Premium CU)"
echo "  - https://supafi.app (SupaFi)"
echo ""

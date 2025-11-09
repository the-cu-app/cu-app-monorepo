# Complete Deployment Guide - Domain Portfolio to Vercel

**Goal:** Deploy 148 domains from GoDaddy to Vercel with automated multi-tenant architecture

---

## STEP 1: SECURE API KEY STORAGE

### Option A: Environment Variables (Recommended)

```bash
# Navigate to project directory
cd /Users/kylekusche/Downloads/openai-chatkit-advanced-samples-main/cu-admin-platform/cu_core_banking_app

# Create .env file (NEVER commit this to git)
cat > .env << 'EOF'
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# OpenAI API Key
OPENAI_API_KEY=sk-your-openai-key-here

# Vercel Configuration
VERCEL_TOKEN=your-vercel-token-here
VERCEL_ORG_ID=your-org-id-here
VERCEL_PROJECT_ID=your-project-id-here
EOF

# Secure the file (only you can read/write)
chmod 600 .env

# Add to .gitignore to prevent accidental commits
echo ".env" >> .gitignore
```

### Option B: System Environment (Persistent)

```bash
# Add to your shell profile (~/.zshrc or ~/.bashrc)
echo 'export SUPABASE_URL="https://your-project.supabase.co"' >> ~/.zshrc
echo 'export SUPABASE_ANON_KEY="your-anon-key-here"' >> ~/.zshrc
echo 'export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key-here"' >> ~/.zshrc
echo 'export OPENAI_API_KEY="sk-your-openai-key-here"' >> ~/.zshrc
echo 'export VERCEL_TOKEN="your-vercel-token-here"' >> ~/.zshrc

# Reload shell configuration
source ~/.zshrc

# Verify
echo $SUPABASE_URL
```

### Set Supabase Secrets (for Edge Functions)

```bash
# Navigate to project
cd /Users/kylekusche/Downloads/openai-chatkit-advanced-samples-main/cu-admin-platform/cu_core_banking_app

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Set OpenAI API key for Edge Functions
supabase secrets set OPENAI_API_KEY=sk-your-openai-key-here

# Verify secrets
supabase secrets list
```

---

## STEP 2: EXPORT DOMAINS FROM GODADDY

### Get Domain List with Auth Codes

```bash
# You already have auth codes in your domain list
# Create a CSV for bulk operations

cat > godaddy_domains.csv << 'EOF'
domain,auth_code,registrar
msteachers.app,AUTH_CODE_HERE,godaddy
azteachers.app,AUTH_CODE_HERE,godaddy
orteachers.app,AUTH_CODE_HERE,godaddy
# ... (continue for all 148 domains)
EOF
```

### GoDaddy Export Process

1. **Unlock Domains (Bulk)**
   ```bash
   # For each domain in GoDaddy dashboard:
   # 1. Go to "Domains" → "My Domains"
   # 2. Select all domains (checkbox)
   # 3. Click "Settings" → "Domain Lock" → "Turn Off"
   ```

2. **Get Authorization Codes**
   ```bash
   # For each domain:
   # 1. Go to domain settings
   # 2. Click "Transfer Domain"
   # 3. Click "Get Authorization Code"
   # 4. Save to CSV
   ```

3. **Disable Auto-Renew**
   ```bash
   # Bulk action in GoDaddy:
   # 1. Select all domains
   # 2. "Settings" → "Auto-Renew" → "Turn Off"
   ```

---

## STEP 3: IMPORT DOMAINS TO VERCEL

### Install Vercel CLI

```bash
# Install Vercel CLI globally
npm install -g vercel

# Login to Vercel
vercel login

# Get your Vercel token (save for later)
vercel whoami
```

### Option A: Vercel Dashboard (Recommended for First Time)

1. **Go to Vercel Dashboard**
   - Navigate to: https://vercel.com/dashboard
   - Click your project or create new one

2. **Add Domains**
   - Go to "Settings" → "Domains"
   - Click "Add Domain"
   - Enter domain name: `msteachers.app`
   - Vercel will provide DNS records

3. **Configure DNS at GoDaddy (Temporary)**
   ```
   For each domain, add these records in GoDaddy DNS:

   A Record:
   Host: @
   Points to: 76.76.21.21
   TTL: 600

   CNAME Record:
   Host: www
   Points to: cname.vercel-dns.com
   TTL: 600
   ```

4. **Initiate Transfer**
   - After DNS is verified, initiate transfer from GoDaddy
   - Use authorization codes
   - Approve transfer in email

### Option B: Vercel API (Bulk Automation)

```bash
# Create deployment script
cat > scripts/deploy_all_domains.sh << 'EOF'
#!/bin/bash

# Load environment variables
source .env

# Domains to deploy
DOMAINS=(
  "msteachers.app"
  "azteachers.app"
  "orteachers.app"
  # ... add all 148 domains
)

# Vercel project name
PROJECT_NAME="cu-banking-platform"

# Deploy to Vercel
echo "Deploying to Vercel..."
vercel --prod --yes

# Get deployment URL
DEPLOYMENT_URL=$(vercel ls | grep -m1 "cu-banking-platform" | awk '{print $2}')

# Add all domains to Vercel project
for domain in "${DOMAINS[@]}"; do
  echo "Adding domain: $domain"

  vercel domains add $domain $PROJECT_NAME

  # Wait for DNS propagation
  sleep 2
done

echo "All domains added to Vercel!"
echo "Next: Configure DNS at GoDaddy to point to Vercel"
EOF

chmod +x scripts/deploy_all_domains.sh
```

---

## STEP 4: DEPLOY MULTI-TENANT NEXT.JS APP

### Create Vercel Configuration

```bash
# Create vercel.json
cat > vercel.json << 'EOF'
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "regions": ["iad1", "sfo1", "pdx1"],
  "env": {
    "SUPABASE_URL": "@supabase_url",
    "SUPABASE_ANON_KEY": "@supabase_anon_key",
    "OPENAI_API_KEY": "@openai_api_key"
  },
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/api/domain-router"
    }
  ]
}
EOF
```

### Create Domain Router Middleware

```bash
# Create middleware for domain-based routing
cat > middleware.ts << 'EOF'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Domain configuration mapping
const DOMAIN_CONFIG = {
  'msteachers.app': {
    cuId: 'msteachers',
    template: 'state-teachers',
    name: 'Mississippi Teachers Credit Union'
  },
  'azteachers.app': {
    cuId: 'azteachers',
    template: 'state-teachers',
    name: 'Arizona Teachers Credit Union'
  },
  'nfcu.app': {
    cuId: 'navyfederal',
    template: 'premium-cu',
    name: 'Navy Federal Credit Union'
  },
  'becu.app': {
    cuId: 'becu',
    template: 'premium-cu',
    name: 'Boeing Employees Credit Union'
  },
  // ... add all 148 domains
}

export function middleware(request: NextRequest) {
  const hostname = request.headers.get('host') || ''
  const domain = hostname.replace(/^www\./, '')

  // Get domain configuration
  const config = DOMAIN_CONFIG[domain]

  if (!config) {
    // Default to demo config
    return NextResponse.rewrite(new URL('/demo', request.url))
  }

  // Clone the request headers
  const requestHeaders = new Headers(request.headers)

  // Add custom headers with domain config
  requestHeaders.set('x-cu-id', config.cuId)
  requestHeaders.set('x-cu-template', config.template)
  requestHeaders.set('x-cu-name', config.name)

  // Rewrite to appropriate template
  const response = NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  })

  // Add template identifier for cold start optimization
  response.cookies.set('cu_template', config.template, {
    httpOnly: true,
    secure: true,
    sameSite: 'strict'
  })

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
}
EOF
```

### Deploy to Vercel

```bash
# Build the project
npm run build

# Deploy to Vercel (production)
vercel --prod

# Or use custom script
./scripts/deploy_all_domains.sh
```

---

## STEP 5: CONFIGURE DNS FOR ALL DOMAINS

### Bulk DNS Update Script

```bash
# Create DNS update script
cat > scripts/update_godaddy_dns.sh << 'EOF'
#!/bin/bash

# GoDaddy API credentials (get from https://developer.godaddy.com/keys)
GODADDY_API_KEY="your-godaddy-api-key"
GODADDY_API_SECRET="your-godaddy-api-secret"

# Vercel IP (get from Vercel dashboard)
VERCEL_IP="76.76.21.21"

# Domains to update
DOMAINS=(
  "msteachers.app"
  "azteachers.app"
  # ... add all 148 domains
)

# Update DNS for each domain
for domain in "${DOMAINS[@]}"; do
  echo "Updating DNS for: $domain"

  # Update A record
  curl -X PUT "https://api.godaddy.com/v1/domains/$domain/records/A/@" \
    -H "Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET" \
    -H "Content-Type: application/json" \
    -d '[{"data":"'$VERCEL_IP'","ttl":600}]'

  # Update CNAME record
  curl -X PUT "https://api.godaddy.com/v1/domains/$domain/records/CNAME/www" \
    -H "Authorization: sso-key $GODADDY_API_KEY:$GODADDY_API_SECRET" \
    -H "Content-Type: application/json" \
    -d '[{"data":"cname.vercel-dns.com","ttl":600}]'

  echo "✅ DNS updated for: $domain"
  sleep 1  # Rate limiting
done

echo "All DNS records updated!"
EOF

chmod +x scripts/update_godaddy_dns.sh
```

---

## STEP 6: AUTOMATED DEPLOYMENT SCRIPT (ALL-IN-ONE)

```bash
# Create master deployment script
cat > scripts/deploy_complete_portfolio.sh << 'EOF'
#!/bin/bash

set -e  # Exit on error

echo "🚀 Complete Domain Portfolio Deployment"
echo "========================================"

# Step 1: Verify environment
echo ""
echo "Step 1: Verifying environment variables..."
if [ -z "$SUPABASE_URL" ] || [ -z "$OPENAI_API_KEY" ] || [ -z "$VERCEL_TOKEN" ]; then
  echo "❌ Missing environment variables. Please set up .env file first."
  exit 1
fi
echo "✅ Environment verified"

# Step 2: Build Next.js app
echo ""
echo "Step 2: Building Next.js application..."
cd /Users/kylekusche/Downloads/openai-chatkit-advanced-samples-main/cu-admin-platform/cu_core_banking_app
npm install
npm run build
echo "✅ Build complete"

# Step 3: Deploy to Vercel
echo ""
echo "Step 3: Deploying to Vercel..."
vercel --prod --yes
DEPLOYMENT_URL=$(vercel ls | grep -m1 "cu-banking-platform" | awk '{print $2}')
echo "✅ Deployed to: $DEPLOYMENT_URL"

# Step 4: Add all domains
echo ""
echo "Step 4: Adding domains to Vercel..."

# State Teachers (50 domains)
for state in ms az or wa nv id ut co nm wy mt nd sd ne ks ok tx mn wi il mi in oh ky tn mo ar la ia wv va nc sc ga fl al pa nj ny ct ri ma vt nh me md de dc hi; do
  echo "  Adding ${state}teachers.app..."
  vercel domains add ${state}teachers.app || true
done

# Premium CUs (30 domains)
for domain in nfcu becu penfed navyfederal pentagonfederal golden1 schoolsfirst alliant suncoast vystar securityservice tdecu randolph techcu achieva summit coastal dort langley usalliance americafirst firsttech mountain america digital gesa meriwest safe star unify; do
  echo "  Adding ${domain}.app..."
  vercel domains add ${domain}.app || true
done

# SupaFi ecosystem
for domain in supafi supabank supacredit supacard supalend supapay supasave supawallet supamoney; do
  echo "  Adding ${domain}.app..."
  vercel domains add ${domain}.app || true
done

echo "✅ All domains added to Vercel"

# Step 5: Update DNS
echo ""
echo "Step 5: DNS Configuration"
echo "  Please run: ./scripts/update_godaddy_dns.sh"
echo "  (Requires GoDaddy API credentials)"

# Step 6: Deploy Supabase Edge Functions
echo ""
echo "Step 6: Deploying Supabase Edge Functions..."
supabase functions deploy generate-feature-content
supabase functions deploy generate-faqs
echo "✅ Edge Functions deployed"

# Step 7: Run database migrations
echo ""
echo "Step 7: Running database migrations..."
supabase db push
echo "✅ Database migrations complete"

echo ""
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Configure DNS at GoDaddy (run ./scripts/update_godaddy_dns.sh)"
echo "2. Wait for DNS propagation (5-30 minutes)"
echo "3. Verify SSL certificates (auto-provisioned by Vercel)"
echo "4. Test each template group"
echo ""
echo "Template URLs to test:"
echo "  - https://msteachers.app (State Teachers template)"
echo "  - https://nfcu.app (Premium CU template)"
echo "  - https://supafi.app (SupaFi template)"
echo "  - https://suncoast.app (Suncoast template)"
echo ""
EOF

chmod +x scripts/deploy_complete_portfolio.sh
```

---

## QUICK START: ONE-COMMAND DEPLOYMENT

### Prerequisites Checklist

```bash
# 1. Install dependencies
brew install node
npm install -g vercel
npm install -g supabase

# 2. Set environment variables
cp .env.example .env
# Edit .env with your actual keys

# 3. Login to services
vercel login
supabase login
```

### Run Complete Deployment

```bash
# Navigate to project
cd /Users/kylekusche/Downloads/openai-chatkit-advanced-samples-main/cu-admin-platform/cu_core_banking_app

# Run master deployment script
./scripts/deploy_complete_portfolio.sh
```

**Estimated time:** 15-30 minutes for complete deployment

---

## MONITORING & VERIFICATION

### Check Deployment Status

```bash
# List all Vercel deployments
vercel ls

# Check specific domain
vercel domains ls | grep msteachers.app

# View deployment logs
vercel logs
```

### Test Each Template Group

```bash
# Create testing script
cat > scripts/test_deployments.sh << 'EOF'
#!/bin/bash

# Test domains
DOMAINS=(
  "https://msteachers.app"
  "https://nfcu.app"
  "https://supafi.app"
  "https://suncoast.app"
  "https://becu.app"
)

for url in "${DOMAINS[@]}"; do
  echo "Testing: $url"
  status=$(curl -s -o /dev/null -w "%{http_code}" $url)

  if [ $status -eq 200 ]; then
    echo "  ✅ Status: $status OK"
  else
    echo "  ❌ Status: $status FAILED"
  fi
done
EOF

chmod +x scripts/test_deployments.sh
./scripts/test_deployments.sh
```

---

## TROUBLESHOOTING

### DNS Not Propagating
```bash
# Check DNS status
dig msteachers.app
nslookup msteachers.app

# Flush local DNS cache (Mac)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

### SSL Certificate Issues
```bash
# Vercel auto-provisions SSL
# If issues, check Vercel dashboard → Domains → SSL
# Certificates usually provision within 10 minutes
```

### Domain Not Resolving
```bash
# Verify domain is added to Vercel
vercel domains ls | grep yourdomain.app

# Check Vercel DNS records
vercel domains inspect yourdomain.app
```

---

## COST ESTIMATES

### Vercel Hosting
- **Pro Plan:** $20/month (recommended for production)
- **Includes:**
  - 100 GB bandwidth
  - Unlimited domains
  - SSL certificates (auto)
  - Edge functions
  - Analytics

### Domain Transfers
- **.app domains:** ~$15/year each
- **148 domains × $15 = $2,220/year**

### API Costs
- **OpenAI (GPT-4 Turbo):** ~$1,900 first generation (cached thereafter)
- **Supabase:** Free tier → Pro ($25/month) recommended

**Total Monthly:** ~$45-65/month + domain renewals
**Total First Year:** ~$3,000-4,000 (including domain transfers)

---

## SUPPORT RESOURCES

- **Vercel Docs:** https://vercel.com/docs
- **Supabase Docs:** https://supabase.com/docs
- **GoDaddy API:** https://developer.godaddy.com
- **Domain Transfer Guide:** https://vercel.com/docs/concepts/projects/domains/transferring-a-domain

**Ready to deploy! Run `./scripts/deploy_complete_portfolio.sh` to start.**

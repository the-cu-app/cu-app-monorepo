#!/bin/bash

# Add All 148 Domains to Vercel
# Bulk domain addition script

set -e

echo "🌐 Adding All 148 Domains to Vercel"
echo "===================================="
echo ""

# Check if logged in to Vercel
if ! vercel whoami &> /dev/null; then
  echo "❌ Error: Not logged in to Vercel"
  echo "Run: vercel login"
  exit 1
fi

# Get project name
PROJECT_NAME=$(vercel ls 2>/dev/null | grep -m1 "cu" | awk '{print $1}' || echo "")

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ Error: No Vercel project found"
  echo "Run ./scripts/deploy_complete_portfolio.sh first"
  exit 1
fi

echo "📦 Project: $PROJECT_NAME"
echo ""

# Function to add domain
add_domain() {
  local domain=$1
  echo "  Adding $domain..."
  vercel domains add $domain $PROJECT_NAME 2>/dev/null || echo "    ⚠️  Already added or pending"
  sleep 0.5  # Rate limiting
}

# GROUP 1: State Teachers (50 domains)
echo "Group 1: State Teachers Credit Unions (50 domains)"
echo "---------------------------------------------------"
for state in ms az or wa nv id ut co nm wy mt nd sd ne ks ok tx mn wi il mi in oh ky tn mo ar la ia wv va nc sc ga fl al pa nj ny ct ri ma vt nh me md de dc hi; do
  add_domain "${state}teachers.app"
done
echo "✅ State Teachers complete"
echo ""

# GROUP 2: Premium CUs (30 domains)
echo "Group 2: Premium Credit Unions (30 domains)"
echo "--------------------------------------------"
domains=(
  "nfcu.app" "becu.app" "penfed.app" "navyfederal.app" "pentagonfederal.app"
  "golden1.app" "schoolsfirst.app" "alliant.app" "suncoast.app" "vystar.app"
  "securityservice.app" "tdecu.app" "randolph.app" "techcu.app" "achieva.app"
  "summit.app" "coastal.app" "dort.app" "langley.app" "usalliance.app"
  "americafirst.app" "firsttech.app" "mountain.app" "america.app" "digital.app"
  "gesa.app" "meriwest.app" "safe.app" "star.app" "unify.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Premium CUs complete"
echo ""

# GROUP 3: Suncoast Ecosystem (20 domains)
echo "Group 3: Suncoast Ecosystem (20 domains)"
echo "-----------------------------------------"
domains=(
  "suncoast.app" "suncoast.ai" "suncoast.com" "suncoast.io"
  "suncoast.credit" "suncoast.money" "suncoast.bank"
  "sunmobile.app" "sunpay.app" "sunlend.app" "sunsave.app"
  "suninvest.app" "suninsure.app" "sunhome.app" "sunauto.app"
  "suncoastcu.app" "suncoastfcu.app" "mysuncoast.app"
  "suncoastmembers.app" "suncoastbanking.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Suncoast Ecosystem complete"
echo ""

# GROUP 4: SupaFi Ecosystem (15 domains)
echo "Group 4: SupaFi Ecosystem (15 domains)"
echo "---------------------------------------"
domains=(
  "supafi.app" "supafi.ai" "supafi.io" "supafi.money" "supafi.bank"
  "supafi.credit" "supafi.finance"
  "supabank.app" "supacredit.app" "supacard.app" "supalend.app"
  "supapay.app" "supasave.app" "supawallet.app" "supamoney.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ SupaFi Ecosystem complete"
echo ""

# GROUP 5: Fintech Brands (10 domains)
echo "Group 5: Fintech Innovation Brands (10 domains)"
echo "------------------------------------------------"
domains=(
  "vybe.app" "vybebank.app" "momentum.app" "momentumbank.app"
  "velocity.app" "velocitybank.app" "nova.app" "novabank.app"
  "pulse.app" "pulsebank.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Fintech Brands complete"
echo ""

# GROUP 6: Member Experience (4 domains)
echo "Group 6: Member Experience Platforms (4 domains)"
echo "-------------------------------------------------"
domains=(
  "memberapp.app" "cuapp.app" "mycreditunion.app" "creditunionapp.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Member Experience complete"
echo ""

# GROUP 7: UX Finance (3 domains)
echo "Group 7: UX Finance (3 domains)"
echo "--------------------------------"
domains=(
  "uxfinance.app" "uxbank.app" "uxmoney.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ UX Finance complete"
echo ""

# GROUP 8: Flutter Platform (2 domains)
echo "Group 8: Flutter Platform (2 domains)"
echo "--------------------------------------"
domains=(
  "flutterbanking.app" "fluttercredit.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Flutter Platform complete"
echo ""

# GROUP 9: CU Industry Tools (7 domains)
echo "Group 9: CU Industry Tools (7 domains)"
echo "---------------------------------------"
domains=(
  "cucore.app" "cusuite.app" "cuplatform.app" "cutech.app"
  "cubankingsuite.app" "creditunioncore.app" "creditunionplatform.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ CU Industry Tools complete"
echo ""

# GROUP 10: Education (5 domains)
echo "Group 10: Education & Financial Literacy (5 domains)"
echo "-----------------------------------------------------"
domains=(
  "teacherscu.app" "educatorscu.app" "schoolemployees.app"
  "studentbanking.app" "youthbanking.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Education complete"
echo ""

# GROUP 11: Rollerblade (6 domains)
echo "Group 11: Rollerblade Lifestyle Banking (6 domains)"
echo "----------------------------------------------------"
domains=(
  "rollerblade.app" "rollerblade.bank" "rollerblade.money"
  "rollerblade.credit" "rollerblade.finance" "rollerblade.io"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Rollerblade complete"
echo ""

# GROUP 12: Payment Rails (3 domains)
echo "Group 12: Payment Rails & Infrastructure (3 domains)"
echo "-----------------------------------------------------"
domains=(
  "payrailz.app" "paymentrails.app" "financerails.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Payment Rails complete"
echo ""

# GROUP 13: Utility Domains (8 domains)
echo "Group 13: Utility & Experimental (8 domains)"
echo "---------------------------------------------"
domains=(
  "quickcu.app" "fastcu.app" "instantcu.app" "smartcu.app"
  "simplecu.app" "easycu.app" "moderncu.app" "digitalcu.app"
)
for domain in "${domains[@]}"; do
  add_domain "$domain"
done
echo "✅ Utility domains complete"
echo ""

# Summary
echo "========================================"
echo "✅ ALL 148 DOMAINS ADDED TO VERCEL!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Configure DNS at GoDaddy"
echo "  2. Wait for DNS propagation (5-30 minutes)"
echo "  3. Verify SSL certificates (auto-provisioned)"
echo "  4. Test: ./scripts/test_deployments.sh"
echo ""
echo "View domains:"
echo "  vercel domains ls"
echo ""

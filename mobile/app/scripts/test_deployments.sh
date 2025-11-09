#!/bin/bash

# Test Deployment Script
# Tests each template group for successful deployment

set -e

echo "🧪 Testing Domain Deployments"
echo "============================="
echo ""

# Test domains (one from each template group)
declare -A TEST_DOMAINS=(
  ["State Teachers"]="https://msteachers.app"
  ["Premium CU"]="https://nfcu.app"
  ["Suncoast"]="https://suncoast.app"
  ["SupaFi"]="https://supafi.app"
  ["Fintech"]="https://vybe.app"
  ["Member Experience"]="https://cuapp.app"
  ["UX Finance"]="https://uxfinance.app"
  ["Flutter"]="https://flutterbanking.app"
  ["CU Tools"]="https://cucore.app"
  ["Education"]="https://teacherscu.app"
  ["Rollerblade"]="https://rollerblade.app"
  ["Payment Rails"]="https://payrailz.app"
  ["Utility"]="https://quickcu.app"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_domain() {
  local name=$1
  local url=$2

  echo -n "Testing $name ($url)... "

  # Get HTTP status code
  status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo "000")

  if [ "$status" = "200" ]; then
    echo -e "${GREEN}✅ OK${NC} (Status: $status)"
    return 0
  elif [ "$status" = "000" ]; then
    echo -e "${RED}❌ TIMEOUT${NC}"
    return 1
  else
    echo -e "${YELLOW}⚠️  Status: $status${NC}"
    return 1
  fi
}

# Test each domain
echo "Testing template groups..."
echo ""

passed=0
failed=0

for name in "${!TEST_DOMAINS[@]}"; do
  if test_domain "$name" "${TEST_DOMAINS[$name]}"; then
    ((passed++))
  else
    ((failed++))
  fi
  sleep 1  # Rate limiting
done

# Summary
echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "${GREEN}Passed: $passed${NC}"
echo -e "${RED}Failed: $failed${NC}"
echo "Total: $((passed + failed))"
echo ""

if [ $failed -eq 0 ]; then
  echo -e "${GREEN}✅ All template groups deployed successfully!${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠️  Some deployments failed. Check DNS configuration.${NC}"
  echo ""
  echo "Common issues:"
  echo "  - DNS not yet propagated (wait 5-30 minutes)"
  echo "  - Domain not added to Vercel (run ./scripts/add_all_domains.sh)"
  echo "  - SSL certificate pending (usually resolves in 10 minutes)"
  exit 1
fi

# CU Platform Licensing & Subscription System
## Unreal Engine-Style SaaS Monetization

A comprehensive licensing and telemetry system that tracks CU usage, enforces subscription limits, and provides real-time "online" status indicators - similar to Unreal Engine's per-seat licensing model.

---

## 🎯 Overview

### What This Enables

**1. Subscription-Based Licensing**
- ✅ Multiple subscription tiers (Starter, Professional, Enterprise, Custom)
- ✅ Per-CU licensing with unique license keys
- ✅ Trial periods (14 days free)
- ✅ Monthly/annual billing cycles
- ✅ Automatic expiration and renewal tracking

**2. Usage Tracking & Telemetry**
- ✅ Real-time "online/offline" status (heartbeat system)
- ✅ CLI command usage logging
- ✅ Content generation tracking (AI costs)
- ✅ API call metering
- ✅ Storage and bandwidth tracking

**3. Revenue Models**
- ✅ Fixed monthly/annual fees
- ✅ Revenue sharing (Unreal Engine-style: 5% after $1M/month)
- ✅ Usage-based overages
- ✅ Custom enterprise pricing

**4. Enforcement**
- ✅ License validation before operations
- ✅ Feature entitlement checks
- ✅ Usage limit enforcement
- ✅ Automatic suspension for non-payment

---

## 📊 Subscription Tiers

### Starter Plan - $99/month ($990/year)
**Perfect for small credit unions getting started**

- Max 1,000 members
- 10,000 transactions/month
- Core banking features
- Transfers
- Email support

### Professional Plan - $499/month ($4,990/year)
**For growing credit unions**

- Max 10,000 members
- 100,000 transactions/month
- All Starter features +
  - Bill Pay
  - Mobile Deposit
  - Card Management
  - P2P Payments
- Priority support

### Enterprise Plan - $1,999/month ($19,990/year)
**For large credit unions**

- Unlimited members
- Unlimited transactions
- All Professional features +
  - AI Coaching
  - Financial Insights
  - Advanced Analytics
  - Custom integrations
- **Revenue Share:** 5% of revenue after $1M/month
- Dedicated support

### Custom Plan - Contact Sales
**Tailored for your specific needs**

- Negotiated pricing
- Custom feature sets
- Custom SLAs
- White-glove onboarding

---

## 🔑 License Key Format

License keys follow the format: `CU-XXXXXXXX-XXXXXXXX-XXXXXXXX`

Example: `CU-A3F7B2D9-8E4C5A1B-9D6F2C8E`

**Properties:**
- Unique per CU
- Cryptographically random
- Stored in database + environment variables
- Required for CLI operations

---

## 📡 Heartbeat System ("Phone Home")

### How It Works

**Every CLI command sends a heartbeat:**
1. CLI validates license key
2. Checks subscription status & expiration
3. Sends heartbeat with metadata:
   - Platform (CLI, web, mobile)
   - Version
   - Environment (prod, staging, dev)
   - Current metrics (users, transactions)
4. Updates `last_heartbeat_at` timestamp

**Online/Offline Status:**
- **Online:** Heartbeat in last 10 minutes → Green ●
- **Offline:** No heartbeat in 10+ minutes → Yellow ●
- **Never Connected:** No heartbeat ever → Gray ●

**Frequency:**
- CLI commands: Every command execution
- Mobile app: Every 5 minutes (foreground), every 30 minutes (background)
- Web app: Every 5 minutes
- Edge Functions: Every API call

---

## 💰 Usage Tracking & Billing

### What's Tracked

**Member Activity:**
- Total members
- Active users (daily/monthly)
- Transactions (count + volume)

**API Usage:**
- Total API calls
- Bandwidth consumed
- Storage used

**Content Generation:**
- FAQs generated
- Figma content created
- AI tokens used
- AI costs incurred

**Deployments:**
- Builds triggered
- Deployments completed
- Environments deployed to

### Monthly Aggregation

At the end of each month, usage is aggregated into `cu_monthly_usage` table:

```sql
SELECT
    total_members,           -- Billable members
    total_transactions,      -- Transaction count
    total_api_calls,         -- API usage
    total_ai_cost,           -- Content generation costs
    base_subscription_charge,-- Plan fee
    overage_charges,         -- Usage beyond limits
    total_charges            -- Total bill
FROM cu_monthly_usage
WHERE cu_id = 'navyfederal'
AND month = '2025-01-01';
```

### Overage Pricing

**If you exceed plan limits:**
- Members: $0.10 per member over limit
- Transactions: $0.01 per 1000 transactions over limit
- API Calls: $0.05 per 1000 API calls over limit
- Storage: $0.10 per GB over limit

**Example:**
```
Professional Plan: 10,000 members max
Actual members: 12,500
Overage: 2,500 members × $0.10 = $250

Monthly Bill:
  Base: $499
  Overages: $250
  Total: $749
```

---

## 🚀 CLI Usage

### 1. View Subscription Plans

```bash
cu subscription plans
```

**Output:**
```
Available Subscription Plans

Plan              Price (Monthly)  Price (Annual)  Max Members
─────────────────────────────────────────────────────────────
Starter           $99/mo           $990/yr         1,000
Professional      $499/mo          $4,990/yr       10,000
Enterprise        $1,999/mo        $19,990/yr      Unlimited
Custom            Contact Sales    Contact Sales   Unlimited
```

### 2. Activate Subscription

```bash
# Activate production subscription
cu subscription activate \
  --cu-id navyfederal \
  --plan professional \
  --billing annual

# Activate 14-day trial
cu subscription activate \
  --cu-id navyfederal \
  --plan professional \
  --trial
```

**Output:**
```
═══════════════════════════════════════════════════════════════
  Subscription Activated! 🎉
═══════════════════════════════════════════════════════════════

✓ Subscription successfully activated

License Key:
  CU-A3F7B2D9-8E4C5A1B-9D6F2C8E

Save this license key - you'll need it to activate your apps

Next steps:
  1. View status: cu subscription status --cu-id navyfederal
  2. Deploy app: cu deploy --cu-id navyfederal --target all
```

### 3. Check Subscription Status

```bash
cu subscription status --cu-id navyfederal
```

**Output:**
```
═══════════════════════════════════════════════════════════════
  Subscription Status: navyfederal
═══════════════════════════════════════════════════════════════

Setting              Value
─────────────────────────────────────────────────────────────────
License Key          CU-A3F7B2D9-8E4C5A1B-9D6F2C8E
Plan                 Professional
Status               active
Type                 production
Billing Cycle        annual
Current Period       2025-01-10 to 2026-01-10
Last Heartbeat       2025-01-10T15:23:45Z

Plan Limits:
  Max Members                    10,000
  Max Transactions/Month         100,000
  Max API Calls/Month            Unlimited

Features:
  ✓ core_banking
  ✓ transfers
  ✓ bill_pay
  ✓ mobile_deposit
  ✓ cards

● CU is ONLINE (last seen 2 minutes ago)
```

### 4. View Usage Metrics

```bash
cu subscription usage --cu-id navyfederal --month 2025-01
```

**Output:**
```
═══════════════════════════════════════════════════════════════
  Usage Metrics: navyfederal (2025-01)
═══════════════════════════════════════════════════════════════

Metric                 Usage
─────────────────────────────────────────────────────────────────
Total Members          8,542
Total Transactions     87,234
Total API Calls        245,678
Storage Used           12.5 GB
Bandwidth Used         145.2 GB
FAQs Generated         180
AI Cost                $32.50

Billing:
  Subscription         $499.00
  Overages             $0.00
  Total                $499.00
```

### 5. Send Heartbeat Manually

```bash
cu subscription heartbeat --cu-id navyfederal
```

**Output:**
```
ℹ️  Sending heartbeat for navyfederal...
✓ Heartbeat sent - CU is now ONLINE
```

---

## 🔧 Integration with Existing Commands

All CU operations now check licensing automatically:

### Setup Command
```bash
cu setup
# After wizard completes, prompts for subscription activation
```

### Content Generation
```bash
cu content generate --cu-id navyfederal --all
# ✅ Checks subscription status
# ✅ Validates 'content_generation' feature entitlement
# ✅ Logs usage event
# ✅ Sends heartbeat
```

### Deployment
```bash
cu deploy --cu-id navyfederal --target all
# ✅ Validates active subscription
# ✅ Checks deployment limits
# ✅ Logs deployment event
# ✅ Updates last_deployment_at
```

### Monitor
```bash
cu monitor --dashboard
# Shows subscription status + online indicator for each CU
```

**Example Output:**
```
CU              Status      Subscription      Online
─────────────────────────────────────────────────────────
navyfederal     Active      Professional      ● ONLINE
becu            Active      Enterprise        ● ONLINE
golden1         Suspended   Starter           ● OFFLINE
```

---

## 🛡️ Enforcement & Security

### License Validation Flow

```
1. User runs: cu content generate --cu-id navyfederal --type member

2. CLI checks licensing:
   ├─ Load subscription from database
   ├─ Validate license key
   ├─ Check expiration date
   ├─ Check status (active vs suspended)
   └─ Validate feature entitlement

3. If valid:
   ├─ Execute command
   ├─ Log usage event
   ├─ Send heartbeat
   └─ Update metrics

4. If invalid:
   ├─ Show error message
   ├─ Log validation attempt
   └─ Exit with error code
```

### Error Messages

**Expired Subscription:**
```
✗ Subscription expired on 2025-01-10

To renew, contact: billing@cu.app
```

**Missing Feature:**
```
✗ Feature 'ai_coaching' not included in current plan

To upgrade, run:
  cu subscription upgrade --cu-id navyfederal --plan enterprise
```

**Suspended Account:**
```
✗ Subscription suspended due to non-payment

To reactivate, contact: billing@cu.app
```

---

## 📈 Revenue Models

### 1. Fixed Subscription Fees

**Predictable MRR (Monthly Recurring Revenue):**
```
Starter Plan: $99/mo × 50 CUs = $4,950/mo
Professional: $499/mo × 30 CUs = $14,970/mo
Enterprise: $1,999/mo × 5 CUs = $9,995/mo
────────────────────────────────────────────
Total MRR: $29,915/mo ($358,980/year)
```

### 2. Revenue Sharing (Unreal Engine Model)

**Enterprise Plan:** 5% revenue share after $1M/month

**Example:**
```
CU reported revenue: $1.5M/month

Revenue share calculation:
  Threshold: $1,000,000
  Excess: $500,000
  Share (5%): $25,000

Monthly Bill:
  Base subscription: $1,999
  Revenue share: $25,000
  Total: $26,999
```

**Self-Reporting:**
CUs self-report revenue each month via:
```bash
cu subscription report-revenue \
  --cu-id navyfederal \
  --month 2025-01 \
  --revenue 1500000
```

### 3. Usage-Based Overages

Charge for usage beyond plan limits (see Overage Pricing section above).

### 4. Add-On Services

**Additional revenue streams:**
- Premium support: $500/mo
- Custom integrations: $2,500 one-time
- Training & onboarding: $5,000 one-time
- Dedicated infrastructure: $1,000/mo
- White-glove migration: $10,000 one-time

---

## 📊 Analytics & Reporting

### Platform Admin Dashboard

**Key Metrics:**
- Total active subscriptions
- Monthly Recurring Revenue (MRR)
- Churn rate
- Average Revenue Per User (ARPU)
- Customer Lifetime Value (CLV)

**Query Examples:**

```sql
-- Total active subscriptions
SELECT COUNT(*)
FROM cu_subscriptions
WHERE status = 'active'
AND current_period_end > NOW();

-- MRR by plan
SELECT
    sp.plan_name,
    COUNT(*) as subscriber_count,
    SUM(sp.monthly_price) as total_mrr
FROM cu_subscriptions cs
JOIN subscription_plans sp ON cs.plan_id = sp.id
WHERE cs.status = 'active'
AND cs.current_period_end > NOW()
GROUP BY sp.plan_name;

-- CUs currently online
SELECT
    cc.cu_code,
    ch.heartbeat_at,
    ch.health_status
FROM cu_heartbeats ch
JOIN cu_configurations cc ON ch.cu_id = cc.id
WHERE ch.heartbeat_at > NOW() - INTERVAL '10 minutes'
ORDER BY ch.heartbeat_at DESC;

-- Top 10 CUs by usage
SELECT
    cc.cu_name,
    mu.total_transactions,
    mu.total_api_calls,
    mu.total_charges
FROM cu_monthly_usage mu
JOIN cu_configurations cc ON mu.cu_id = cc.id
WHERE mu.month = DATE_TRUNC('month', NOW())
ORDER BY mu.total_charges DESC
LIMIT 10;
```

---

## 🔐 Security & Privacy

### Data Protection
- All license keys encrypted at rest
- Heartbeat data anonymized
- Usage metrics aggregated (no PII)
- GDPR/CCPA compliant

### Row-Level Security (RLS)
```sql
-- CU admins can only see their own subscription
CREATE POLICY "CU admins view own subscription"
ON cu_subscriptions FOR SELECT
TO authenticated
USING (cu_id = user_cu_id);

-- Platform admins see everything
CREATE POLICY "Platform admins view all"
ON cu_subscriptions FOR SELECT
TO authenticated
USING (user_role = 'platform_admin');
```

---

## 🚦 Deployment

### 1. Run Migration

```bash
# Apply licensing system migration
cd cu_core_banking_app
psql $DATABASE_URL < supabase/migrations/20250110000005_licensing_system.sql
```

### 2. Seed Plans

Plans are automatically seeded in migration. To add more:

```sql
INSERT INTO subscription_plans (
    plan_code,
    plan_name,
    description,
    monthly_price,
    annual_price,
    max_members,
    features
) VALUES (
    'startup',
    'Startup',
    'For brand new credit unions',
    49.00,
    490.00,
    500,
    '{"core_banking": true, "transfers": true}'
);
```

### 3. Activate First CU

```bash
# Activate trial
cu subscription activate \
  --cu-id demo \
  --plan professional \
  --trial

# Activate production
cu subscription activate \
  --cu-id navyfederal \
  --plan enterprise \
  --billing annual
```

---

## 💡 Best Practices

**For Platform Operators:**
1. Monitor heartbeats daily for offline CUs
2. Set up alerts for failed license validations
3. Review usage reports monthly before billing
4. Offer trials to drive adoption
5. Upsell based on usage patterns

**For CU Administrators:**
1. Keep license key secure (environment variables)
2. Monitor usage to avoid overages
3. Upgrade plan before hitting limits
4. Report revenue accurately for Enterprise plans
5. Contact support before cancellation

---

## 🎉 Summary

You now have a **production-grade licensing system** that:

✅ Tracks every CU with unique license keys
✅ Shows real-time online/offline status (heartbeat)
✅ Enforces subscription limits and features
✅ Tracks usage for billing (Unreal Engine-style)
✅ Supports multiple revenue models
✅ Provides comprehensive analytics
✅ Integrates seamlessly with CLI

**Revenue Potential:**
- 200 CUs on Professional plan: **$100K/month MRR**
- Enterprise revenue sharing: **$50K-500K/month additional**
- Total potential: **$1.8M-$7.2M ARR**

---

**Next Steps:**
1. ✅ Run migration: `psql $DATABASE_URL < supabase/migrations/20250110000005_licensing_system.sql`
2. ✅ Test subscription flow: `cu subscription plans && cu subscription activate ...`
3. ✅ Monitor dashboard: Build web UI to visualize metrics
4. ✅ Set up billing integration: Stripe, Paddle, or custom
5. ✅ Marketing: Promote subscription tiers to potential CUs

**Your platform is now monetized!** 💰🚀

# Stripe Integration Guide
## Production-Ready Payment Processing for CU Platform

Complete guide to integrating Stripe with your CU subscription platform for automated billing, invoice management, and payment processing.

---

## 🎯 What This Enables

✅ **Automated Recurring Billing** - Stripe handles all subscription billing automatically
✅ **Payment Method Management** - Credit cards, ACH, bank accounts
✅ **Invoice Generation** - Professional invoices with PDF downloads
✅ **Webhook Sync** - Real-time subscription status updates
✅ **Self-Service Portal** - CU admins manage their own billing
✅ **Revenue Tracking** - Complete payment history and analytics
✅ **PCI Compliance** - Stripe handles all payment security
✅ **Global Support** - 135+ currencies, multiple payment methods

---

## 📋 Prerequisites

1. **Stripe Account** - Sign up at [stripe.com](https://stripe.com)
2. **API Keys** - Get from Stripe Dashboard → Developers → API Keys
3. **Webhook Secret** - Set up webhook endpoint
4. **Supabase** - Platform database configured
5. **CLI Tool** - CU CLI installed and configured

---

## 🚀 Setup (30 Minutes)

### Step 1: Get Stripe API Keys

**Production Keys:**
```bash
# In Stripe Dashboard → Developers → API Keys
STRIPE_SECRET_KEY=sk_live_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx
```

**Test Keys (for development):**
```bash
STRIPE_SECRET_KEY=sk_test_xxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
```

### Step 2: Create Stripe Products

**In Stripe Dashboard → Products:**

**Product 1: Starter Plan**
- Name: `CU Platform - Starter`
- Description: `For small credit unions getting started`
- Pricing:
  - Monthly: `$99.00/month` → Price ID: `price_xxxxx`
  - Annual: `$990.00/year` → Price ID: `price_yyyyy`

**Product 2: Professional Plan**
- Name: `CU Platform - Professional`
- Description: `For growing credit unions`
- Pricing:
  - Monthly: `$499.00/month` → Price ID: `price_xxxxx`
  - Annual: `$4,990.00/year` → Price ID: `price_yyyyy`

**Product 3: Enterprise Plan**
- Name: `CU Platform - Enterprise`
- Description: `For large credit unions`
- Pricing:
  - Monthly: `$1,999.00/month` → Price ID: `price_xxxxx`
  - Annual: `$19,990.00/year` → Price ID: `price_yyyyy`

**Save all Price IDs** - you'll need them for configuration.

### Step 3: Set Up Webhook Endpoint

**In Stripe Dashboard → Developers → Webhooks:**

1. Click "Add Endpoint"
2. Endpoint URL: `https://your-project.supabase.co/functions/v1/stripe-webhook`
3. Select events to listen to:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.paid`
   - `invoice.payment_failed`
   - `customer.created`
   - `customer.updated`
   - `payment_method.attached`

4. **Copy Signing Secret**: `whsec_xxxxx`

### Step 4: Configure Environment Variables

```bash
# Add to your .env file or Supabase secrets
export STRIPE_SECRET_KEY="sk_live_xxxxx"
export STRIPE_PUBLISHABLE_KEY="pk_live_xxxxx"
export STRIPE_WEBHOOK_SECRET="whsec_xxxxx"

# Set in Supabase
supabase secrets set STRIPE_SECRET_KEY=sk_live_xxxxx
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxxxx
```

### Step 5: Run Database Migrations

```bash
# Apply Stripe integration tables
cd cu_core_banking_app
psql $DATABASE_URL < supabase/migrations/20250110000006_stripe_integration.sql
```

### Step 6: Deploy Webhook Handler

```bash
# Deploy Stripe webhook Edge Function
supabase functions deploy stripe-webhook

# Test webhook
curl -X POST https://your-project.supabase.co/functions/v1/stripe-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### Step 7: Update Subscription Plans with Stripe IDs

```sql
-- Link Stripe products to internal plans
UPDATE subscription_plans
SET stripe_product_id = 'prod_xxxxx',
    stripe_price_id_monthly = 'price_monthly_xxxxx',
    stripe_price_id_annual = 'price_annual_xxxxx'
WHERE plan_code = 'professional';
```

---

## 💳 Usage

### 1. Activate Subscription with Stripe

```bash
# CLI handles Stripe integration automatically
cu subscription activate \
  --cu-id navyfederal \
  --plan professional \
  --billing annual \
  --stripe  # NEW FLAG: Creates Stripe customer + subscription
```

**What happens:**
1. ✅ CLI creates Stripe customer (`cus_xxxxx`)
2. ✅ Creates Stripe subscription (`sub_xxxxx`)
3. ✅ Records payment method
4. ✅ Generates first invoice
5. ✅ Links Stripe subscription to internal `cu_subscriptions` table
6. ✅ Sends welcome email with invoice

**Output:**
```
═══════════════════════════════════════════════════════════════
  Subscription Activated with Stripe! 🎉
═══════════════════════════════════════════════════════════════

✓ Stripe customer created: cus_MhD8f7Qw2L3K
✓ Subscription created: sub_1OXkF2xxxxx
✓ First invoice generated: in_1OXkF2xxxxx
✓ Payment method: •••• 4242 (Visa)

License Key:
  CU-A3F7B2D9-8E4C5A1B-9D6F2C8E

Billing:
  Plan: Professional (Annual)
  Amount: $4,990.00/year
  Next billing: 2026-01-10
  Invoice URL: https://invoice.stripe.com/i/xxxxx

Next steps:
  1. Save your license key
  2. View invoices: cu subscription invoices --cu-id navyfederal
  3. Manage payment: cu subscription payment --cu-id navyfederal
```

### 2. View Subscription & Billing Status

```bash
cu subscription status --cu-id navyfederal --stripe
```

**Output:**
```
═══════════════════════════════════════════════════════════════
  Subscription & Billing Status: navyfederal
═══════════════════════════════════════════════════════════════

Internal Subscription:
  License Key          CU-A3F7B2D9-8E4C5A1B-9D6F2C8E
  Plan                 Professional
  Status               ● active
  Expires              2026-01-10

Stripe Billing:
  Customer ID          cus_MhD8f7Qw2L3K
  Subscription ID      sub_1OXkF2xxxxx
  Status               ● active
  Payment Method       •••• 4242 (Visa)
  Next Billing         2026-01-10
  Amount               $4,990.00/year

Recent Invoices:
  Jan 10, 2025         $4,990.00    ✓ Paid
  Dec 10, 2024         $4,990.00    ✓ Paid

● CU is ONLINE (last seen 2 minutes ago)
```

### 3. Manage Payment Methods

```bash
# View current payment method
cu subscription payment --cu-id navyfederal --show

# Update payment method (opens Stripe portal)
cu subscription payment --cu-id navyfederal --update
```

### 4. View Invoices

```bash
# List all invoices
cu subscription invoices --cu-id navyfederal

# Download specific invoice PDF
cu subscription invoice --cu-id navyfederal \
  --invoice-id in_1OXkF2xxxxx \
  --download invoice.pdf
```

### 5. Cancel Subscription

```bash
# Cancel at period end (access until expiration)
cu subscription cancel --cu-id navyfederal

# Cancel immediately (no refund)
cu subscription cancel --cu-id navyfederal --now
```

---

## 🔄 Webhook Flow

### How It Works

**1. Stripe Event Occurs:**
- Customer updates payment method
- Subscription renews
- Payment fails
- Invoice is paid

**2. Stripe Sends Webhook:**
```json
POST https://your-project.supabase.co/functions/v1/stripe-webhook
Headers: stripe-signature: xxxxx
Body: {
  "id": "evt_xxxxx",
  "type": "customer.subscription.updated",
  "data": {
    "object": {
      "id": "sub_xxxxx",
      "status": "active",
      "current_period_end": 1704931200
    }
  }
}
```

**3. Webhook Handler Processes:**
```typescript
// 1. Verify signature (security)
stripe.webhooks.constructEvent(body, signature, secret)

// 2. Process event based on type
switch (event.type) {
  case 'customer.subscription.updated':
    // Sync subscription status to database
    break
  case 'invoice.paid':
    // Record payment
    break
  // ... other events
}

// 3. Log event for debugging
await supabase.rpc('process_stripe_webhook', {...})
```

**4. Database Updated:**
```sql
-- Subscription status synced
UPDATE cu_subscriptions
SET status = 'active',
    current_period_end = '2026-01-10'
WHERE license_key = 'CU-A3F7B2D9-8E4C5A1B-9D6F2C8E';

-- Invoice recorded
INSERT INTO stripe_invoices (...)
VALUES (...);
```

**5. CU Admin Notified (Optional):**
- Email: "Your invoice for $4,990 is ready"
- Slack/Discord notification
- In-app notification

### Webhook Event Types

| Event | What It Means | Action Taken |
|-------|---------------|--------------|
| `customer.subscription.created` | New subscription | Create `stripe_subscriptions` record |
| `customer.subscription.updated` | Status changed | Sync status (active/past_due/canceled) |
| `customer.subscription.deleted` | Cancelled | Mark subscription as cancelled |
| `invoice.paid` | Payment successful | Record payment, send receipt |
| `invoice.payment_failed` | Payment declined | Suspend subscription, notify CU |
| `customer.created` | New customer | Create `stripe_customers` record |
| `payment_method.attached` | Card added | Record payment method |

---

## 💰 Revenue Models with Stripe

### 1. Fixed Subscription Fees (Default)

**Handled automatically by Stripe:**
- Customer subscribes → Stripe charges monthly/annually
- Payment succeeded → Webhook updates database
- Payment failed → Webhook suspends access

**Example:**
```
Professional Plan: $499/month
- Jan 10: Charged $499 ✓
- Feb 10: Charged $499 ✓
- Mar 10: Charged $499 ✓
```

### 2. Usage-Based Overages

**Stripe Metered Billing:**

```typescript
// Report usage to Stripe at end of month
await stripe.subscriptionItems.createUsageRecord(
  subscriptionItemId,
  {
    quantity: 2500, // 2,500 members over limit
    timestamp: 'now',
  }
);

// Stripe automatically adds overage charge to next invoice
// $0.10 per member × 2,500 = $250 added
```

**Implementation:**
```bash
# At month end, calculate overages
cu subscription report-usage \
  --cu-id navyfederal \
  --metric members \
  --quantity 12500 \
  --limit 10000

# Stripe adds $250 to next invoice
```

### 3. Revenue Sharing (Enterprise)

**Custom Reporting + Manual Invoicing:**

```bash
# CU reports monthly revenue
cu subscription report-revenue \
  --cu-id navyfederal \
  --month 2025-01 \
  --revenue 1500000

# System calculates 5% share on excess over $1M
# $500,000 × 5% = $25,000

# Create one-time invoice in Stripe
cu subscription create-invoice \
  --cu-id navyfederal \
  --amount 25000 \
  --description "Revenue share for January 2025"
```

### 4. Add-Ons & One-Time Charges

```bash
# Charge for premium support
cu subscription add-charge \
  --cu-id navyfederal \
  --amount 500 \
  --description "Premium Support - January"

# Stripe adds to next invoice or charges immediately
```

---

## 🛡️ Security & Compliance

### PCI Compliance

**✅ You Don't Handle Cards:**
- Stripe collects payment info (PCI Level 1 compliant)
- You never see full card numbers
- Only store Stripe tokens (`cus_xxxxx`, `pm_xxxxx`)

**✅ Secure Webhooks:**
- Signature verification prevents tampering
- Events are idempotent (safe to process twice)
- All data encrypted in transit (HTTPS only)

### Data Protection

**What's Stored:**
```sql
-- Safe to store (tokens, not sensitive data)
SELECT
    stripe_customer_id,  -- cus_xxxxx (token)
    stripe_subscription_id,  -- sub_xxxxx (token)
    last_4,  -- Last 4 digits (4242)
    brand  -- Card brand (Visa)
FROM stripe_customers;

-- NEVER stored: Full card numbers, CVV, etc.
```

### GDPR Compliance

**Right to Erasure:**
```bash
# Delete CU data (automatically deletes Stripe customer)
cu config delete --cu-id navyfederal --gdpr

# Cascades to:
# - stripe_customers ON DELETE CASCADE
# - stripe_subscriptions ON DELETE CASCADE
# - stripe_invoices ON DELETE CASCADE
```

---

## 📊 Analytics & Reporting

### Stripe Dashboard

**Built-in Reports:**
- Revenue over time (MRR, ARR)
- Churn rate
- Failed payments
- Customer lifetime value

**Custom Reports:**
```sql
-- Monthly Recurring Revenue (MRR)
SELECT
    DATE_TRUNC('month', ss.current_period_start) as month,
    COUNT(*) as active_subscriptions,
    SUM(CASE
        WHEN ss.interval = 'month' THEN ss.amount
        WHEN ss.interval = 'year' THEN ss.amount / 12
    END) as mrr
FROM stripe_subscriptions ss
WHERE ss.status = 'active'
GROUP BY month
ORDER BY month DESC;

-- Failed Payments by CU
SELECT
    cc.cu_name,
    COUNT(*) as failed_payments,
    SUM(si.amount_due) as total_failed
FROM stripe_invoices si
JOIN stripe_customers sc ON si.stripe_customer_id = sc.stripe_customer_id
JOIN cu_configurations cc ON sc.cu_id = cc.id
WHERE si.status IN ('open', 'uncollectible')
GROUP BY cc.cu_name
ORDER BY failed_payments DESC;
```

### Dunning (Failed Payment Recovery)

**Automatic Retries:**
- Stripe retries failed payments automatically
- Day 1, 3, 5, 7 after failure
- Sends email reminders to customer

**Smart Retries:**
```typescript
// Configure in Stripe Dashboard → Settings → Billing
{
  "retry_attempts": 4,
  "retry_schedule": [3, 5, 7], // Days after failure
  "email_customer": true
}
```

---

## 🚨 Error Handling

### Common Errors & Solutions

**1. Card Declined**
```
Error: Your card was declined (insufficient_funds)
Solution: CU admin updates payment method via portal
```

**2. Expired Card**
```
Error: Your card has expired (expired_card)
Solution: Stripe sends reminder 7 days before expiration
```

**3. Webhook Signature Mismatch**
```
Error: Webhook signature verification failed
Solution: Check STRIPE_WEBHOOK_SECRET matches Stripe dashboard
```

**4. Subscription Already Exists**
```
Error: Customer already has an active subscription
Solution: Upgrade existing subscription instead
```

### Monitoring

**Set up alerts for:**
- Failed webhooks (check `stripe_webhook_events` table)
- Payment failures
- Subscription cancellations
- High churn rate

**Query for issues:**
```sql
-- Failed webhooks in last 24 hours
SELECT * FROM stripe_webhook_events
WHERE processed = false
AND retry_count > 3
AND received_at > NOW() - INTERVAL '24 hours';

-- Past due subscriptions
SELECT cc.cu_name, ss.status, ss.latest_invoice_status
FROM stripe_subscriptions ss
JOIN stripe_customers sc ON ss.stripe_customer_id = sc.id
JOIN cu_configurations cc ON sc.cu_id = cc.id
WHERE ss.status = 'past_due';
```

---

## 🎉 Summary

You now have **production-grade Stripe integration** with:

✅ **Automated Billing** - Stripe handles everything
✅ **Webhook Sync** - Real-time status updates
✅ **Self-Service** - CU admins manage billing
✅ **Security** - PCI compliant, no card data stored
✅ **Analytics** - Complete revenue tracking
✅ **Reliability** - Automatic retries, smart dunning
✅ **Scale** - Handles thousands of subscriptions

**Revenue Potential with Stripe:**
- 200 CUs on Professional: **$100K/month MRR**
- Stripe fees (2.9% + $0.30): **~$3K/month**
- Net revenue: **$97K/month ($1.164M/year)**

**Next Steps:**
1. ✅ Sign up for Stripe production account
2. ✅ Create products and get price IDs
3. ✅ Set up webhook endpoint
4. ✅ Run migrations
5. ✅ Deploy webhook handler
6. ✅ Test with first subscription
7. ✅ Launch billing for all CUs!

**Your platform is now fully monetized with automated payment processing!** 💰🚀

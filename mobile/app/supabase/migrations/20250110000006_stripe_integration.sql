-- Stripe Payment Integration
-- Links CU subscriptions with Stripe for automated billing

-- ============================================================================
-- Stripe Customer Records
-- ============================================================================

CREATE TABLE IF NOT EXISTS stripe_customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,

    -- Stripe IDs
    stripe_customer_id TEXT NOT NULL UNIQUE, -- cus_xxxxx
    stripe_subscription_id TEXT, -- sub_xxxxx (from Stripe)

    -- Customer Details
    email TEXT NOT NULL,
    name TEXT,
    description TEXT,

    -- Payment Method
    default_payment_method_id TEXT, -- pm_xxxxx
    payment_method_type TEXT, -- 'card', 'bank_account', 'ach'
    last_4 TEXT, -- Last 4 digits of card/account

    -- Billing
    billing_email TEXT,
    billing_address JSONB DEFAULT '{}',

    -- Status
    is_active BOOLEAN DEFAULT true,
    delinquent BOOLEAN DEFAULT false, -- Behind on payments

    -- Metadata
    stripe_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(cu_id)
);

CREATE INDEX idx_stripe_customers_cu_id ON stripe_customers(cu_id);
CREATE INDEX idx_stripe_customers_stripe_customer_id ON stripe_customers(stripe_customer_id);

-- ============================================================================
-- Stripe Subscriptions (Sync with Stripe)
-- ============================================================================

CREATE TABLE IF NOT EXISTS stripe_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_subscription_id UUID NOT NULL REFERENCES cu_subscriptions(id) ON DELETE CASCADE,
    stripe_customer_id UUID NOT NULL REFERENCES stripe_customers(id) ON DELETE CASCADE,

    -- Stripe IDs
    stripe_subscription_id TEXT NOT NULL UNIQUE, -- sub_xxxxx
    stripe_price_id TEXT NOT NULL, -- price_xxxxx
    stripe_product_id TEXT, -- prod_xxxxx

    -- Status (synced from Stripe)
    status TEXT NOT NULL, -- 'active', 'past_due', 'canceled', 'unpaid', 'trialing'
    cancel_at_period_end BOOLEAN DEFAULT false,

    -- Billing
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end TIMESTAMPTZ NOT NULL,
    trial_start TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    ended_at TIMESTAMPTZ,

    -- Pricing
    amount DECIMAL(10,2) NOT NULL, -- Amount in dollars
    currency TEXT DEFAULT 'usd',
    interval TEXT NOT NULL, -- 'month', 'year'

    -- Latest Invoice
    latest_invoice_id TEXT, -- in_xxxxx
    latest_invoice_status TEXT, -- 'paid', 'open', 'void', 'uncollectible'

    -- Metadata
    stripe_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(cu_subscription_id)
);

CREATE INDEX idx_stripe_subscriptions_subscription_id ON stripe_subscriptions(cu_subscription_id);
CREATE INDEX idx_stripe_subscriptions_stripe_sub_id ON stripe_subscriptions(stripe_subscription_id);
CREATE INDEX idx_stripe_subscriptions_status ON stripe_subscriptions(status);

-- ============================================================================
-- Stripe Invoices
-- ============================================================================

CREATE TABLE IF NOT EXISTS stripe_invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    stripe_subscription_id UUID REFERENCES stripe_subscriptions(id) ON DELETE SET NULL,

    -- Stripe IDs
    stripe_invoice_id TEXT NOT NULL UNIQUE, -- in_xxxxx
    stripe_customer_id TEXT NOT NULL,

    -- Invoice Details
    invoice_number TEXT, -- Human-readable invoice number
    amount_due DECIMAL(10,2) NOT NULL,
    amount_paid DECIMAL(10,2) DEFAULT 0,
    amount_remaining DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'usd',

    -- Status
    status TEXT NOT NULL, -- 'draft', 'open', 'paid', 'void', 'uncollectible'
    paid BOOLEAN DEFAULT false,

    -- Dates
    invoice_date TIMESTAMPTZ NOT NULL,
    due_date TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    period_start TIMESTAMPTZ,
    period_end TIMESTAMPTZ,

    -- PDF
    invoice_pdf_url TEXT,
    hosted_invoice_url TEXT, -- Stripe-hosted payment page

    -- Line Items (stored as JSON)
    line_items JSONB DEFAULT '[]',

    -- Metadata
    stripe_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stripe_invoices_cu_id ON stripe_invoices(cu_id);
CREATE INDEX idx_stripe_invoices_stripe_invoice_id ON stripe_invoices(stripe_invoice_id);
CREATE INDEX idx_stripe_invoices_status ON stripe_invoices(status);
CREATE INDEX idx_stripe_invoices_invoice_date ON stripe_invoices(invoice_date DESC);

-- ============================================================================
-- Stripe Webhook Events Log
-- ============================================================================

CREATE TABLE IF NOT EXISTS stripe_webhook_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Event Details
    stripe_event_id TEXT NOT NULL UNIQUE, -- evt_xxxxx
    event_type TEXT NOT NULL, -- 'customer.subscription.updated', etc.
    event_data JSONB NOT NULL,

    -- Processing
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMPTZ,
    processing_error TEXT,
    retry_count INTEGER DEFAULT 0,

    -- Metadata
    received_at TIMESTAMPTZ DEFAULT NOW(),
    api_version TEXT
);

CREATE INDEX idx_stripe_webhook_events_event_type ON stripe_webhook_events(event_type);
CREATE INDEX idx_stripe_webhook_events_processed ON stripe_webhook_events(processed);
CREATE INDEX idx_stripe_webhook_events_received_at ON stripe_webhook_events(received_at DESC);

-- ============================================================================
-- Stripe Payment Methods
-- ============================================================================

CREATE TABLE IF NOT EXISTS stripe_payment_methods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cu_id UUID NOT NULL REFERENCES cu_configurations(id) ON DELETE CASCADE,
    stripe_customer_id UUID REFERENCES stripe_customers(id) ON DELETE CASCADE,

    -- Stripe ID
    stripe_payment_method_id TEXT NOT NULL UNIQUE, -- pm_xxxxx

    -- Type & Details
    type TEXT NOT NULL, -- 'card', 'bank_account', 'us_bank_account'
    brand TEXT, -- 'visa', 'mastercard', etc.
    last_4 TEXT,
    exp_month INTEGER,
    exp_year INTEGER,

    -- Bank Account Details (if applicable)
    bank_name TEXT,
    account_holder_name TEXT,
    routing_number TEXT,

    -- Status
    is_default BOOLEAN DEFAULT false,

    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stripe_payment_methods_cu_id ON stripe_payment_methods(cu_id);
CREATE INDEX idx_stripe_payment_methods_stripe_pm_id ON stripe_payment_methods(stripe_payment_method_id);

-- ============================================================================
-- Stripe Products & Prices (Synced from Stripe)
-- ============================================================================

CREATE TABLE IF NOT EXISTS stripe_products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID REFERENCES subscription_plans(id) ON DELETE SET NULL,

    -- Stripe IDs
    stripe_product_id TEXT NOT NULL UNIQUE, -- prod_xxxxx
    stripe_price_id_monthly TEXT, -- price_xxxxx for monthly
    stripe_price_id_annual TEXT, -- price_xxxxx for annual

    -- Product Details
    name TEXT NOT NULL,
    description TEXT,
    active BOOLEAN DEFAULT true,

    -- Pricing
    monthly_price DECIMAL(10,2),
    annual_price DECIMAL(10,2),

    -- Metadata
    stripe_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_stripe_products_plan_id ON stripe_products(plan_id);
CREATE INDEX idx_stripe_products_stripe_product_id ON stripe_products(stripe_product_id);

-- ============================================================================
-- Functions
-- ============================================================================

-- Create Stripe customer for CU
CREATE OR REPLACE FUNCTION create_stripe_customer(
    p_cu_id UUID,
    p_stripe_customer_id TEXT,
    p_email TEXT,
    p_name TEXT
)
RETURNS UUID AS $$
DECLARE
    customer_id UUID;
BEGIN
    INSERT INTO stripe_customers (
        cu_id,
        stripe_customer_id,
        email,
        name
    ) VALUES (
        p_cu_id,
        p_stripe_customer_id,
        p_email,
        p_name
    )
    RETURNING id INTO customer_id;

    RETURN customer_id;
END;
$$ LANGUAGE plpgsql;

-- Sync subscription from Stripe webhook
CREATE OR REPLACE FUNCTION sync_stripe_subscription(
    p_stripe_subscription_id TEXT,
    p_status TEXT,
    p_current_period_start TIMESTAMPTZ,
    p_current_period_end TIMESTAMPTZ,
    p_cancel_at_period_end BOOLEAN
)
RETURNS VOID AS $$
BEGIN
    UPDATE stripe_subscriptions
    SET
        status = p_status,
        current_period_start = p_current_period_start,
        current_period_end = p_current_period_end,
        cancel_at_period_end = p_cancel_at_period_end,
        updated_at = NOW()
    WHERE stripe_subscription_id = p_stripe_subscription_id;

    -- Also update our internal subscription
    UPDATE cu_subscriptions cs
    SET
        status = CASE
            WHEN p_status = 'active' THEN 'active'
            WHEN p_status = 'past_due' THEN 'suspended'
            WHEN p_status = 'canceled' THEN 'cancelled'
            WHEN p_status = 'unpaid' THEN 'suspended'
            ELSE cs.status
        END,
        current_period_end = p_current_period_end,
        updated_at = NOW()
    FROM stripe_subscriptions ss
    WHERE cs.id = ss.cu_subscription_id
    AND ss.stripe_subscription_id = p_stripe_subscription_id;
END;
$$ LANGUAGE plpgsql;

-- Process Stripe webhook event
CREATE OR REPLACE FUNCTION process_stripe_webhook(
    p_stripe_event_id TEXT,
    p_event_type TEXT,
    p_event_data JSONB
)
RETURNS BOOLEAN AS $$
DECLARE
    event_exists BOOLEAN;
BEGIN
    -- Check if already processed
    SELECT EXISTS (
        SELECT 1 FROM stripe_webhook_events
        WHERE stripe_event_id = p_stripe_event_id
        AND processed = true
    ) INTO event_exists;

    IF event_exists THEN
        RETURN true; -- Already processed
    END IF;

    -- Insert event
    INSERT INTO stripe_webhook_events (
        stripe_event_id,
        event_type,
        event_data
    ) VALUES (
        p_stripe_event_id,
        p_event_type,
        p_event_data
    )
    ON CONFLICT (stripe_event_id) DO NOTHING;

    -- Process based on event type
    CASE p_event_type
        WHEN 'customer.subscription.updated' THEN
            -- Sync subscription status
            PERFORM sync_stripe_subscription(
                p_event_data->'data'->'object'->>'id',
                p_event_data->'data'->'object'->>'status',
                to_timestamp((p_event_data->'data'->'object'->'current_period_start')::bigint),
                to_timestamp((p_event_data->'data'->'object'->'current_period_end')::bigint),
                (p_event_data->'data'->'object'->>'cancel_at_period_end')::boolean
            );

        WHEN 'invoice.paid' THEN
            -- Mark invoice as paid
            UPDATE stripe_invoices
            SET paid = true, paid_at = NOW(), status = 'paid'
            WHERE stripe_invoice_id = p_event_data->'data'->'object'->>'id';

        WHEN 'invoice.payment_failed' THEN
            -- Mark subscription as past due
            UPDATE cu_subscriptions cs
            SET status = 'suspended'
            FROM stripe_subscriptions ss,
                 stripe_invoices si
            WHERE si.stripe_invoice_id = p_event_data->'data'->'object'->>'id'
            AND ss.id = si.stripe_subscription_id
            AND cs.id = ss.cu_subscription_id;

        ELSE
            -- Log unhandled event type
            NULL;
    END CASE;

    -- Mark as processed
    UPDATE stripe_webhook_events
    SET processed = true, processed_at = NOW()
    WHERE stripe_event_id = p_stripe_event_id;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Row Level Security (RLS)
-- ============================================================================

ALTER TABLE stripe_customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_webhook_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE stripe_products ENABLE ROW LEVEL SECURITY;

-- CU admins can view their own Stripe data
CREATE POLICY "CU admins view own Stripe customer"
ON stripe_customers FOR SELECT
TO authenticated
USING (
    cu_id IN (
        SELECT cu_id FROM user_profiles
        WHERE id = auth.uid()
        AND role IN ('admin', 'owner')
    )
);

-- Similar policies for other tables...

-- Platform admins can view all
CREATE POLICY "Platform admins view all Stripe data"
ON stripe_customers FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM user_profiles
        WHERE id = auth.uid()
        AND role = 'platform_admin'
    )
);

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE stripe_customers IS 'Stripe customer records linked to CUs';
COMMENT ON TABLE stripe_subscriptions IS 'Stripe subscription sync (master is Stripe)';
COMMENT ON TABLE stripe_invoices IS 'Invoice history from Stripe';
COMMENT ON TABLE stripe_webhook_events IS 'Log of Stripe webhook events for debugging';
COMMENT ON TABLE stripe_payment_methods IS 'Payment methods attached to CU accounts';
COMMENT ON TABLE stripe_products IS 'Stripe products/prices synced from Stripe';

COMMENT ON FUNCTION create_stripe_customer(UUID, TEXT, TEXT, TEXT) IS 'Create Stripe customer record after successful Stripe API call';
COMMENT ON FUNCTION sync_stripe_subscription(TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, BOOLEAN) IS 'Sync subscription status from Stripe webhook';
COMMENT ON FUNCTION process_stripe_webhook(TEXT, TEXT, JSONB) IS 'Process incoming Stripe webhook event (idempotent)';

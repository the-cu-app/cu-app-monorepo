-- Zelle Recipients Table
CREATE TABLE IF NOT EXISTS zelle_recipients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    profile_image TEXT,
    is_enrolled BOOLEAN DEFAULT false,
    is_favorite BOOLEAN DEFAULT false,
    last_payment_date TIMESTAMP WITH TIME ZONE,
    last_payment_amount DECIMAL(10, 2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, email)
);

-- Zelle Transactions Table
CREATE TABLE IF NOT EXISTS zelle_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id),
    sender_name VARCHAR(255) NOT NULL,
    recipient_id UUID NOT NULL,
    recipient_name VARCHAR(255) NOT NULL,
    from_account_id UUID NOT NULL REFERENCES accounts(id),
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    memo TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(50) NOT NULL DEFAULT 'completed',
    type VARCHAR(50) NOT NULL, -- 'sent' or 'received'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Zelle Payment Requests Table
CREATE TABLE IF NOT EXISTS zelle_payment_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id),
    requester_name VARCHAR(255) NOT NULL,
    requester_email VARCHAR(255) NOT NULL,
    recipient_id UUID NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    memo TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'expired'
    accepted_at TIMESTAMP WITH TIME ZONE,
    declined_at TIMESTAMP WITH TIME ZONE
);

-- Zelle Recurring Payments Table
CREATE TABLE IF NOT EXISTS zelle_recurring_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES zelle_recipients(id),
    recipient_name VARCHAR(255) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    frequency VARCHAR(50) NOT NULL, -- 'weekly', 'biweekly', 'monthly'
    start_date DATE NOT NULL,
    end_date DATE,
    memo TEXT,
    is_active BOOLEAN DEFAULT true,
    last_execution_date TIMESTAMP WITH TIME ZONE,
    next_execution_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Update transfers table to support Zelle
ALTER TABLE transfers ADD COLUMN IF NOT EXISTS recipient_id UUID;
ALTER TABLE transfers ADD COLUMN IF NOT EXISTS recipient_email VARCHAR(255);
ALTER TABLE transfers ADD COLUMN IF NOT EXISTS recipient_name VARCHAR(255);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_zelle_recipients_user_id ON zelle_recipients(user_id);
CREATE INDEX IF NOT EXISTS idx_zelle_recipients_email ON zelle_recipients(email);
CREATE INDEX IF NOT EXISTS idx_zelle_recipients_favorite ON zelle_recipients(user_id, is_favorite);
CREATE INDEX IF NOT EXISTS idx_zelle_recipients_last_payment ON zelle_recipients(user_id, last_payment_date DESC);

CREATE INDEX IF NOT EXISTS idx_zelle_transactions_sender ON zelle_transactions(sender_id);
CREATE INDEX IF NOT EXISTS idx_zelle_transactions_recipient ON zelle_transactions(recipient_id);
CREATE INDEX IF NOT EXISTS idx_zelle_transactions_timestamp ON zelle_transactions(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_zelle_requests_requester ON zelle_payment_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_zelle_requests_recipient ON zelle_payment_requests(recipient_id);
CREATE INDEX IF NOT EXISTS idx_zelle_requests_status ON zelle_payment_requests(status);
CREATE INDEX IF NOT EXISTS idx_zelle_requests_expires ON zelle_payment_requests(expires_at);

CREATE INDEX IF NOT EXISTS idx_zelle_recurring_user ON zelle_recurring_payments(user_id);
CREATE INDEX IF NOT EXISTS idx_zelle_recurring_active ON zelle_recurring_payments(is_active, next_execution_date);

-- Row Level Security
ALTER TABLE zelle_recipients ENABLE ROW LEVEL SECURITY;
ALTER TABLE zelle_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE zelle_payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE zelle_recurring_payments ENABLE ROW LEVEL SECURITY;

-- Policies for zelle_recipients
CREATE POLICY "Users can view their own recipients" ON zelle_recipients
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own recipients" ON zelle_recipients
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own recipients" ON zelle_recipients
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recipients" ON zelle_recipients
    FOR DELETE USING (auth.uid() = user_id);

-- Policies for zelle_transactions
CREATE POLICY "Users can view their own transactions" ON zelle_transactions
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid()::text = recipient_id);

CREATE POLICY "Users can insert their own transactions" ON zelle_transactions
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Policies for zelle_payment_requests
CREATE POLICY "Users can view their own requests" ON zelle_payment_requests
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid()::text = recipient_id);

CREATE POLICY "Users can insert their own requests" ON zelle_payment_requests
    FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Users can update requests they receive" ON zelle_payment_requests
    FOR UPDATE USING (auth.uid()::text = recipient_id);

-- Policies for zelle_recurring_payments
CREATE POLICY "Users can view their own recurring payments" ON zelle_recurring_payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own recurring payments" ON zelle_recurring_payments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own recurring payments" ON zelle_recurring_payments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recurring payments" ON zelle_recurring_payments
    FOR DELETE USING (auth.uid() = user_id);

-- Function to automatically expire payment requests
CREATE OR REPLACE FUNCTION expire_payment_requests() RETURNS void AS $$
BEGIN
    UPDATE zelle_payment_requests
    SET status = 'expired'
    WHERE status = 'pending' AND expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- Function to process recurring payments (to be called by a scheduled job)
CREATE OR REPLACE FUNCTION process_recurring_payments() RETURNS void AS $$
DECLARE
    payment RECORD;
BEGIN
    FOR payment IN 
        SELECT * FROM zelle_recurring_payments 
        WHERE is_active = true 
        AND next_execution_date <= NOW()
    LOOP
        -- Create a transfer record
        INSERT INTO transfers (
            user_id, from_account_id, recipient_email, recipient_name, 
            recipient_id, amount, type, memo, status
        )
        SELECT 
            payment.user_id, 
            (SELECT id FROM accounts WHERE user_id = payment.user_id LIMIT 1),
            (SELECT email FROM zelle_recipients WHERE id = payment.recipient_id),
            payment.recipient_name,
            payment.recipient_id,
            payment.amount,
            'zelle_transfer',
            COALESCE(payment.memo, 'Recurring payment'),
            'completed';
        
        -- Update the recurring payment record
        UPDATE zelle_recurring_payments
        SET 
            last_execution_date = NOW(),
            next_execution_date = CASE payment.frequency
                WHEN 'weekly' THEN NOW() + INTERVAL '7 days'
                WHEN 'biweekly' THEN NOW() + INTERVAL '14 days'
                WHEN 'monthly' THEN NOW() + INTERVAL '1 month'
            END
        WHERE id = payment.id;
        
        -- Deactivate if past end date
        UPDATE zelle_recurring_payments
        SET is_active = false
        WHERE id = payment.id AND end_date IS NOT NULL AND next_execution_date > end_date;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
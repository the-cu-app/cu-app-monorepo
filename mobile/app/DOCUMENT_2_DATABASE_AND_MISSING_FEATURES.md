# DOCUMENT 2: DATABASE SCHEMAS & MISSING FEATURES

## TABLE OF CONTENTS
1. [Complete Database Schema](#complete-database-schema)
2. [Missing Screens to Build](#missing-screens-to-build)
3. [Missing Features](#missing-features)
4. [Onboarding System Requirements](#onboarding-system-requirements)
5. [Implementation Checklist](#implementation-checklist)

---

# COMPLETE DATABASE SCHEMA

## DATABASE EXTENSIONS REQUIRED

```sql
-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

---

## 1. USER & AUTHENTICATION TABLES

### 1.1 TABLE: users

**Purpose:** User profile information (extends auth.users)

**CREATE TABLE:**
```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone VARCHAR(20),
  date_of_birth DATE,
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state VARCHAR(2),
  zip_code VARCHAR(10),
  country VARCHAR(2) DEFAULT 'US',
  profile_image_url TEXT,
  bio TEXT,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY, FK→auth.users(id) | User ID (same as auth.users) |
| email | TEXT | UNIQUE, NOT NULL | User email address |
| first_name | TEXT | | User first name |
| last_name | TEXT | | User last name |
| phone | VARCHAR(20) | | Phone number |
| date_of_birth | DATE | | Date of birth |
| address_line1 | TEXT | | Street address line 1 |
| address_line2 | TEXT | | Street address line 2 |
| city | TEXT | | City |
| state | VARCHAR(2) | | State code (US) |
| zip_code | VARCHAR(10) | | ZIP/Postal code |
| country | VARCHAR(2) | DEFAULT 'US' | Country code |
| profile_image_url | TEXT | | Profile picture URL |
| bio | TEXT | | User bio/description |
| preferences | JSONB | DEFAULT '{}' | User preferences JSON |
| created_at | TIMESTAMPTZ | NOT NULL | Creation timestamp |
| updated_at | TIMESTAMPTZ | NOT NULL | Last update timestamp |

**INDEXES:**
```sql
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_phone ON public.users(phone);
```

**RLS POLICIES:**
```sql
-- Users can view own profile
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- Users can update own profile
CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

-- Users can insert own profile
CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);
```

**TRIGGERS:**
```sql
-- Auto-create user profile on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

### 1.2 TABLE: user_profiles

**Purpose:** Multiple profiles per user (personal, business, trust, etc.)

**CREATE TABLE:**
```sql
CREATE TABLE public.user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cu_id UUID REFERENCES public.cu_configurations(id),
  profile_name TEXT NOT NULL,
  profile_type TEXT NOT NULL CHECK (profile_type IN ('personal', 'business', 'premium', 'trust', 'youth', 'student')),
  membership_tier TEXT DEFAULT 'general' CHECK (membership_tier IN ('general', 'premium', 'business', 'enhanced', 'trust', 'youth', 'student')),
  is_primary BOOLEAN DEFAULT false,
  avatar_url TEXT,
  color_scheme TEXT DEFAULT 'blue',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Profile ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user ID |
| cu_id | UUID | FK→cu_configurations | Credit union ID |
| profile_name | TEXT | NOT NULL | Display name for profile |
| profile_type | TEXT | NOT NULL, CHECK constraint | Type: personal/business/etc |
| membership_tier | TEXT | CHECK constraint | Tier: general/premium/etc |
| is_primary | BOOLEAN | DEFAULT false | Primary profile flag |
| avatar_url | TEXT | | Profile avatar image |
| color_scheme | TEXT | DEFAULT 'blue' | UI color preference |
| is_active | BOOLEAN | DEFAULT true | Active status |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX idx_user_profiles_cu_id ON public.user_profiles(cu_id);
CREATE INDEX idx_user_profiles_primary ON public.user_profiles(user_id, is_primary) WHERE is_primary = true;
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own profiles" ON public.user_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own profiles" ON public.user_profiles
  FOR ALL USING (auth.uid() = user_id);
```

---

## 2. ACCOUNT TABLES

### 2.1 TABLE: accounts

**Purpose:** User bank accounts (checking, savings, credit, loans)

**CREATE TABLE:**
```sql
CREATE TABLE public.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  profile_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  plaid_account_id TEXT,
  account_name TEXT NOT NULL,
  account_type TEXT NOT NULL CHECK (account_type IN ('checking', 'savings', 'credit', 'loan', 'investment', 'mortgage', 'cd', 'money_market')),
  account_subtype TEXT,
  current_balance DECIMAL(15,2) DEFAULT 0.00,
  available_balance DECIMAL(15,2) DEFAULT 0.00,
  credit_limit DECIMAL(15,2),
  currency VARCHAR(3) DEFAULT 'USD',
  account_number TEXT,
  routing_number TEXT,
  account_mask TEXT,
  institution_name TEXT,
  institution_id TEXT,
  is_external BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  last_synced_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Account ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user |
| profile_id | UUID | FK→user_profiles | Associated profile |
| plaid_account_id | TEXT | | Plaid account identifier |
| account_name | TEXT | NOT NULL | Display name |
| account_type | TEXT | NOT NULL, CHECK | checking/savings/credit/etc |
| account_subtype | TEXT | | Detailed subtype |
| current_balance | DECIMAL(15,2) | DEFAULT 0.00 | Current balance |
| available_balance | DECIMAL(15,2) | DEFAULT 0.00 | Available balance |
| credit_limit | DECIMAL(15,2) | | Credit limit (if credit) |
| currency | VARCHAR(3) | DEFAULT 'USD' | Currency code |
| account_number | TEXT | | Full account number |
| routing_number | TEXT | | Routing number |
| account_mask | TEXT | | Last 4 digits (display) |
| institution_name | TEXT | | Bank name |
| institution_id | TEXT | | Institution identifier |
| is_external | BOOLEAN | DEFAULT false | External (Plaid) account |
| is_active | BOOLEAN | DEFAULT true | Active status |
| last_synced_at | TIMESTAMPTZ | | Last Plaid sync time |
| created_at | TIMESTAMPTZ | NOT NULL | Creation time |
| updated_at | TIMESTAMPTZ | NOT NULL | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_accounts_user_id ON public.accounts(user_id);
CREATE INDEX idx_accounts_profile_id ON public.accounts(profile_id);
CREATE INDEX idx_accounts_plaid_id ON public.accounts(plaid_account_id);
CREATE INDEX idx_accounts_type ON public.accounts(account_type);
CREATE INDEX idx_accounts_active ON public.accounts(user_id, is_active) WHERE is_active = true;
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own accounts" ON public.accounts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own accounts" ON public.accounts
  FOR ALL USING (auth.uid() = user_id);
```

---

### 2.2 TABLE: transactions

**Purpose:** Financial transactions for all accounts

**CREATE TABLE:**
```sql
CREATE TABLE public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  account_id UUID REFERENCES public.accounts(id) ON DELETE CASCADE NOT NULL,
  plaid_transaction_id TEXT,
  transaction_name TEXT NOT NULL,
  merchant_name TEXT,
  amount DECIMAL(15,2) NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('credit', 'debit')),
  category TEXT[],
  category_id TEXT,
  primary_category TEXT,
  detailed_category TEXT,
  pending BOOLEAN DEFAULT false,
  payment_channel TEXT CHECK (payment_channel IN ('online', 'in_store', 'other')),
  transaction_date DATE NOT NULL,
  authorized_date DATE,
  posted_date DATE,
  iso_currency_code VARCHAR(3) DEFAULT 'USD',
  location JSONB,
  payment_meta JSONB,
  merchant_entity_id TEXT,
  logo_url TEXT,
  website TEXT,
  is_recurring BOOLEAN DEFAULT false,
  is_subscription BOOLEAN DEFAULT false,
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Transaction ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user |
| account_id | UUID | NOT NULL, FK→accounts | Associated account |
| plaid_transaction_id | TEXT | | Plaid transaction ID |
| transaction_name | TEXT | NOT NULL | Transaction description |
| merchant_name | TEXT | | Merchant name |
| amount | DECIMAL(15,2) | NOT NULL | Transaction amount |
| transaction_type | TEXT | NOT NULL, CHECK | credit or debit |
| category | TEXT[] | | Category array |
| category_id | TEXT | | Category identifier |
| primary_category | TEXT | | Main category |
| detailed_category | TEXT | | Detailed category |
| pending | BOOLEAN | DEFAULT false | Pending status |
| payment_channel | TEXT | CHECK | online/in-store/other |
| transaction_date | DATE | NOT NULL | Transaction date |
| authorized_date | DATE | | Authorization date |
| posted_date | DATE | | Posted date |
| iso_currency_code | VARCHAR(3) | DEFAULT 'USD' | Currency |
| location | JSONB | | Location data |
| payment_meta | JSONB | | Payment metadata |
| merchant_entity_id | TEXT | | Merchant identifier |
| logo_url | TEXT | | Merchant logo URL |
| website | TEXT | | Merchant website |
| is_recurring | BOOLEAN | DEFAULT false | Recurring flag |
| is_subscription | BOOLEAN | DEFAULT false | Subscription flag |
| notes | TEXT | | User notes |
| tags | TEXT[] | | User tags |
| created_at | TIMESTAMPTZ | NOT NULL | Creation time |
| updated_at | TIMESTAMPTZ | NOT NULL | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX idx_transactions_account_id ON public.transactions(account_id);
CREATE INDEX idx_transactions_date ON public.transactions(transaction_date DESC);
CREATE INDEX idx_transactions_plaid_id ON public.transactions(plaid_transaction_id);
CREATE INDEX idx_transactions_pending ON public.transactions(user_id, pending) WHERE pending = true;
CREATE INDEX idx_transactions_merchant ON public.transactions(merchant_name);
CREATE INDEX idx_transactions_category ON public.transactions USING GIN(category);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own transactions" ON public.transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own transactions" ON public.transactions
  FOR ALL USING (auth.uid() = user_id);
```

---

## 3. CARD TABLES

### 3.1 TABLE: bank_cards

**Purpose:** Debit and credit cards

**CREATE TABLE:**
```sql
CREATE TABLE public.bank_cards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  card_name TEXT NOT NULL,
  card_type TEXT NOT NULL CHECK (card_type IN ('debit', 'credit', 'prepaid', 'virtual')),
  card_network TEXT CHECK (card_network IN ('visa', 'mastercard', 'amex', 'discover')),
  card_number_encrypted TEXT,
  card_number_last_four VARCHAR(4) NOT NULL,
  cardholder_name TEXT NOT NULL,
  expiration_month INTEGER NOT NULL CHECK (expiration_month BETWEEN 1 AND 12),
  expiration_year INTEGER NOT NULL CHECK (expiration_year >= 2024),
  cvv_encrypted TEXT,
  is_virtual BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'locked', 'frozen', 'cancelled', 'expired')),
  spending_limit DECIMAL(10,2),
  daily_limit DECIMAL(10,2),
  pin_encrypted TEXT,
  billing_address JSONB,
  controls JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  issued_date DATE,
  last_used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Card ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user |
| profile_id | UUID | FK→user_profiles | Associated profile |
| account_id | UUID | FK→accounts | Linked account |
| card_name | TEXT | NOT NULL | Display name |
| card_type | TEXT | NOT NULL, CHECK | debit/credit/prepaid/virtual |
| card_network | TEXT | CHECK | visa/mastercard/amex/discover |
| card_number_encrypted | TEXT | | Encrypted full number |
| card_number_last_four | VARCHAR(4) | NOT NULL | Last 4 digits |
| cardholder_name | TEXT | NOT NULL | Name on card |
| expiration_month | INTEGER | NOT NULL, CHECK 1-12 | Expiry month |
| expiration_year | INTEGER | NOT NULL, CHECK >=2024 | Expiry year |
| cvv_encrypted | TEXT | | Encrypted CVV |
| is_virtual | BOOLEAN | DEFAULT false | Virtual card flag |
| is_primary | BOOLEAN | DEFAULT false | Primary card flag |
| status | TEXT | CHECK | active/locked/frozen/etc |
| spending_limit | DECIMAL(10,2) | | Monthly spending limit |
| daily_limit | DECIMAL(10,2) | | Daily spending limit |
| pin_encrypted | TEXT | | Encrypted PIN |
| billing_address | JSONB | | Billing address JSON |
| controls | JSONB | DEFAULT '{}' | Card controls JSON |
| metadata | JSONB | DEFAULT '{}' | Additional metadata |
| issued_date | DATE | | Issue date |
| last_used_at | TIMESTAMPTZ | | Last usage timestamp |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_bank_cards_user_id ON public.bank_cards(user_id);
CREATE INDEX idx_bank_cards_profile_id ON public.bank_cards(profile_id);
CREATE INDEX idx_bank_cards_account_id ON public.bank_cards(account_id);
CREATE INDEX idx_bank_cards_status ON public.bank_cards(status);
CREATE INDEX idx_bank_cards_last_four ON public.bank_cards(card_number_last_four);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own cards" ON public.bank_cards
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own cards" ON public.bank_cards
  FOR ALL USING (auth.uid() = user_id);
```

---

## 4. BILL PAY & TRANSFERS TABLES

### 4.1 TABLE: payees

**Purpose:** Bill payment recipients

**CREATE TABLE:**
```sql
CREATE TABLE public.payees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  payee_name TEXT NOT NULL,
  payee_type TEXT CHECK (payee_type IN ('company', 'individual', 'utility', 'loan', 'other')),
  account_number TEXT,
  routing_number TEXT,
  email TEXT,
  phone TEXT,
  address JSONB,
  payment_methods TEXT[] DEFAULT ARRAY['ach'],
  is_favorite BOOLEAN DEFAULT false,
  logo_url TEXT,
  website TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Payee ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user |
| payee_name | TEXT | NOT NULL | Payee display name |
| payee_type | TEXT | CHECK | company/individual/utility/etc |
| account_number | TEXT | | Payee account number |
| routing_number | TEXT | | Payee routing number |
| email | TEXT | | Payee email |
| phone | TEXT | | Payee phone |
| address | JSONB | | Payee address JSON |
| payment_methods | TEXT[] | DEFAULT ['ach'] | Supported payment methods |
| is_favorite | BOOLEAN | DEFAULT false | Favorite flag |
| logo_url | TEXT | | Payee logo URL |
| website | TEXT | | Payee website |
| notes | TEXT | | User notes |
| created_at | TIMESTAMPTZ | NOT NULL | Creation time |
| updated_at | TIMESTAMPTZ | NOT NULL | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_payees_user_id ON public.payees(user_id);
CREATE INDEX idx_payees_favorite ON public.payees(user_id, is_favorite) WHERE is_favorite = true;
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own payees" ON public.payees
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own payees" ON public.payees
  FOR ALL USING (auth.uid() = user_id);
```

---

### 4.2 TABLE: scheduled_payments

**Purpose:** Scheduled bill payments

**CREATE TABLE:**
```sql
CREATE TABLE public.scheduled_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  from_account_id UUID REFERENCES public.accounts(id) ON DELETE CASCADE NOT NULL,
  to_payee_id UUID REFERENCES public.payees(id) ON DELETE CASCADE NOT NULL,
  payment_name TEXT,
  amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
  description TEXT,
  scheduled_date DATE NOT NULL,
  next_payment_date DATE,
  frequency TEXT DEFAULT 'one-time' CHECK (frequency IN ('one-time', 'weekly', 'bi-weekly', 'monthly', 'quarterly', 'annually')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  auto_pay BOOLEAN DEFAULT false,
  reminder_days_before INTEGER DEFAULT 3,
  last_processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Payment ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user |
| from_account_id | UUID | NOT NULL, FK→accounts | Source account |
| to_payee_id | UUID | NOT NULL, FK→payees | Destination payee |
| payment_name | TEXT | | Display name |
| amount | DECIMAL(15,2) | NOT NULL, CHECK >0 | Payment amount |
| description | TEXT | | Payment description |
| scheduled_date | DATE | NOT NULL | Scheduled date |
| next_payment_date | DATE | | Next payment (recurring) |
| frequency | TEXT | CHECK | one-time/weekly/monthly/etc |
| status | TEXT | CHECK | pending/completed/etc |
| auto_pay | BOOLEAN | DEFAULT false | Auto-pay flag |
| reminder_days_before | INTEGER | DEFAULT 3 | Reminder days |
| last_processed_at | TIMESTAMPTZ | | Last process time |
| created_at | TIMESTAMPTZ | NOT NULL | Creation time |
| updated_at | TIMESTAMPTZ | NOT NULL | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_scheduled_payments_user_id ON public.scheduled_payments(user_id);
CREATE INDEX idx_scheduled_payments_account_id ON public.scheduled_payments(from_account_id);
CREATE INDEX idx_scheduled_payments_payee_id ON public.scheduled_payments(to_payee_id);
CREATE INDEX idx_scheduled_payments_date ON public.scheduled_payments(scheduled_date);
CREATE INDEX idx_scheduled_payments_status ON public.scheduled_payments(status);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own scheduled payments" ON public.scheduled_payments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own scheduled payments" ON public.scheduled_payments
  FOR ALL USING (auth.uid() = user_id);
```

---

## 5. ZELLE TABLES

### 5.1 TABLE: zelle_recipients

**Purpose:** Saved Zelle recipients/contacts

**CREATE TABLE:**
```sql
CREATE TABLE public.zelle_recipients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  recipient_name VARCHAR(255) NOT NULL,
  recipient_email VARCHAR(255) NOT NULL,
  recipient_phone VARCHAR(20),
  profile_image TEXT,
  is_enrolled BOOLEAN DEFAULT false,
  is_favorite BOOLEAN DEFAULT false,
  last_payment_date TIMESTAMPTZ,
  last_payment_amount DECIMAL(10, 2),
  total_sent DECIMAL(12, 2) DEFAULT 0,
  total_received DECIMAL(12, 2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, recipient_email)
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Recipient ID |
| user_id | UUID | NOT NULL, FK→users | Owner user |
| recipient_name | VARCHAR(255) | NOT NULL | Recipient name |
| recipient_email | VARCHAR(255) | NOT NULL | Recipient email |
| recipient_phone | VARCHAR(20) | | Recipient phone |
| profile_image | TEXT | | Profile image URL |
| is_enrolled | BOOLEAN | DEFAULT false | Zelle enrollment status |
| is_favorite | BOOLEAN | DEFAULT false | Favorite flag |
| last_payment_date | TIMESTAMPTZ | | Last payment timestamp |
| last_payment_amount | DECIMAL(10, 2) | | Last payment amount |
| total_sent | DECIMAL(12, 2) | DEFAULT 0 | Total sent to recipient |
| total_received | DECIMAL(12, 2) | DEFAULT 0 | Total received from recipient |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**UNIQUE CONSTRAINT:** (user_id, recipient_email)

**INDEXES:**
```sql
CREATE INDEX idx_zelle_recipients_user_id ON public.zelle_recipients(user_id);
CREATE INDEX idx_zelle_recipients_email ON public.zelle_recipients(recipient_email);
CREATE INDEX idx_zelle_recipients_favorite ON public.zelle_recipients(user_id, is_favorite);
CREATE INDEX idx_zelle_recipients_last_payment ON public.zelle_recipients(user_id, last_payment_date DESC);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view their own recipients" ON public.zelle_recipients
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own recipients" ON public.zelle_recipients
  FOR ALL USING (auth.uid() = user_id);
```

---

### 5.2 TABLE: zelle_transactions

**Purpose:** Zelle payment transactions

**CREATE TABLE:**
```sql
CREATE TABLE public.zelle_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES public.users(id),
  sender_name VARCHAR(255) NOT NULL,
  sender_email VARCHAR(255) NOT NULL,
  recipient_id UUID NOT NULL,
  recipient_name VARCHAR(255) NOT NULL,
  recipient_email VARCHAR(255) NOT NULL,
  from_account_id UUID NOT NULL REFERENCES public.accounts(id),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  memo TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW(),
  status VARCHAR(50) NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  type VARCHAR(50) NOT NULL CHECK (type IN ('sent', 'received')),
  transaction_ref TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Transaction ID |
| sender_id | UUID | NOT NULL, FK→users | Sender user ID |
| sender_name | VARCHAR(255) | NOT NULL | Sender name |
| sender_email | VARCHAR(255) | NOT NULL | Sender email |
| recipient_id | UUID | NOT NULL | Recipient user/contact ID |
| recipient_name | VARCHAR(255) | NOT NULL | Recipient name |
| recipient_email | VARCHAR(255) | NOT NULL | Recipient email |
| from_account_id | UUID | NOT NULL, FK→accounts | Source account |
| amount | DECIMAL(10, 2) | NOT NULL, CHECK >0 | Amount |
| memo | TEXT | | Payment memo |
| timestamp | TIMESTAMPTZ | | Transaction timestamp |
| status | VARCHAR(50) | NOT NULL, CHECK | pending/completed/etc |
| type | VARCHAR(50) | NOT NULL, CHECK | sent or received |
| transaction_ref | TEXT | | Reference number |
| created_at | TIMESTAMPTZ | | Creation time |

**INDEXES:**
```sql
CREATE INDEX idx_zelle_transactions_sender ON public.zelle_transactions(sender_id);
CREATE INDEX idx_zelle_transactions_recipient ON public.zelle_transactions(recipient_id);
CREATE INDEX idx_zelle_transactions_timestamp ON public.zelle_transactions(timestamp DESC);
CREATE INDEX idx_zelle_transactions_status ON public.zelle_transactions(status);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view their own transactions" ON public.zelle_transactions
  FOR SELECT USING (auth.uid() = sender_id OR auth.uid()::text = recipient_id);

CREATE POLICY "Users can insert their own transactions" ON public.zelle_transactions
  FOR INSERT WITH CHECK (auth.uid() = sender_id);
```

---

### 5.3 TABLE: zelle_payment_requests

**Purpose:** Zelle payment requests

**CREATE TABLE:**
```sql
CREATE TABLE public.zelle_payment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users(id),
  requester_name VARCHAR(255) NOT NULL,
  requester_email VARCHAR(255) NOT NULL,
  recipient_id UUID NOT NULL,
  recipient_email VARCHAR(255) NOT NULL,
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'expired')),
  accepted_at TIMESTAMPTZ,
  declined_at TIMESTAMPTZ,
  transaction_id UUID REFERENCES public.zelle_transactions(id)
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Request ID |
| requester_id | UUID | NOT NULL, FK→users | Requester user ID |
| requester_name | VARCHAR(255) | NOT NULL | Requester name |
| requester_email | VARCHAR(255) | NOT NULL | Requester email |
| recipient_id | UUID | NOT NULL | Recipient ID |
| recipient_email | VARCHAR(255) | NOT NULL | Recipient email |
| amount | DECIMAL(10, 2) | NOT NULL, CHECK >0 | Requested amount |
| memo | TEXT | | Request message |
| created_at | TIMESTAMPTZ | | Creation time |
| expires_at | TIMESTAMPTZ | NOT NULL | Expiration time |
| status | VARCHAR(50) | NOT NULL, CHECK | pending/accepted/etc |
| accepted_at | TIMESTAMPTZ | | Acceptance timestamp |
| declined_at | TIMESTAMPTZ | | Decline timestamp |
| transaction_id | UUID | FK→zelle_transactions | Resulting transaction |

**INDEXES:**
```sql
CREATE INDEX idx_zelle_requests_requester ON public.zelle_payment_requests(requester_id);
CREATE INDEX idx_zelle_requests_recipient ON public.zelle_payment_requests(recipient_id);
CREATE INDEX idx_zelle_requests_status ON public.zelle_payment_requests(status);
CREATE INDEX idx_zelle_requests_expires ON public.zelle_payment_requests(expires_at);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view their own requests" ON public.zelle_payment_requests
  FOR SELECT USING (auth.uid() = requester_id OR auth.uid()::text = recipient_id);

CREATE POLICY "Users can create requests" ON public.zelle_payment_requests
  FOR INSERT WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "Recipients can update requests" ON public.zelle_payment_requests
  FOR UPDATE USING (auth.uid()::text = recipient_id);
```

---

### 5.4 TABLE: zelle_recurring_payments

**Purpose:** Recurring Zelle payments

**CREATE TABLE:**
```sql
CREATE TABLE public.zelle_recurring_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES public.zelle_recipients(id),
  recipient_name VARCHAR(255) NOT NULL,
  recipient_email VARCHAR(255) NOT NULL,
  from_account_id UUID NOT NULL REFERENCES public.accounts(id),
  amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
  frequency VARCHAR(50) NOT NULL CHECK (frequency IN ('weekly', 'bi-weekly', 'monthly', 'quarterly')),
  start_date DATE NOT NULL,
  end_date DATE,
  memo TEXT,
  is_active BOOLEAN DEFAULT true,
  last_execution_date TIMESTAMPTZ,
  next_execution_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Recurring payment ID |
| user_id | UUID | NOT NULL, FK→users | Owner user |
| recipient_id | UUID | NOT NULL, FK→zelle_recipients | Recipient |
| recipient_name | VARCHAR(255) | NOT NULL | Recipient name |
| recipient_email | VARCHAR(255) | NOT NULL | Recipient email |
| from_account_id | UUID | NOT NULL, FK→accounts | Source account |
| amount | DECIMAL(10, 2) | NOT NULL, CHECK >0 | Payment amount |
| frequency | VARCHAR(50) | NOT NULL, CHECK | weekly/bi-weekly/etc |
| start_date | DATE | NOT NULL | Start date |
| end_date | DATE | | End date (optional) |
| memo | TEXT | | Payment memo |
| is_active | BOOLEAN | DEFAULT true | Active flag |
| last_execution_date | TIMESTAMPTZ | | Last execution |
| next_execution_date | TIMESTAMPTZ | | Next execution |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_zelle_recurring_user ON public.zelle_recurring_payments(user_id);
CREATE INDEX idx_zelle_recurring_active ON public.zelle_recurring_payments(is_active, next_execution_date);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view their own recurring payments" ON public.zelle_recurring_payments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own recurring payments" ON public.zelle_recurring_payments
  FOR ALL USING (auth.uid() = user_id);
```

---

## 6. BUDGET COMMITMENT TABLES (NO CAP AI)

### 6.1 TABLE: budget_commitments

**Purpose:** AI-enforced budget commitments

**CREATE TABLE:**
```sql
CREATE TABLE public.budget_commitments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES public.user_profiles(id),
  commitment_name TEXT NOT NULL,
  commitment_type TEXT NOT NULL CHECK (commitment_type IN ('merchant_block', 'category_limit', 'amount_cap', 'savings_goal')),
  restrictions JSONB NOT NULL,
  difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'extreme')),
  ai_personality TEXT CHECK (ai_personality IN ('motivational', 'strict', 'supportive', 'analytical', 'humorous')),
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  is_locked BOOLEAN DEFAULT false,
  locked_at TIMESTAMPTZ,
  biometric_hash TEXT,
  current_spend DECIMAL(12,2) DEFAULT 0,
  limit_amount DECIMAL(12,2),
  penalty_points INTEGER DEFAULT 0,
  violation_count INTEGER DEFAULT 0,
  emergency_override_count INTEGER DEFAULT 0,
  last_violation_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Commitment ID |
| user_id | UUID | NOT NULL, FK→auth.users | Owner user |
| profile_id | UUID | FK→user_profiles | Associated profile |
| commitment_name | TEXT | NOT NULL | Display name |
| commitment_type | TEXT | NOT NULL, CHECK | Type of commitment |
| restrictions | JSONB | NOT NULL | Restriction rules JSON |
| difficulty_level | TEXT | NOT NULL, CHECK | easy/medium/hard/extreme |
| ai_personality | TEXT | CHECK | AI coach personality |
| start_date | DATE | NOT NULL | Start date |
| end_date | DATE | | End date (optional) |
| is_active | BOOLEAN | DEFAULT true | Active flag |
| is_locked | BOOLEAN | DEFAULT false | Biometric lock flag |
| locked_at | TIMESTAMPTZ | | Lock timestamp |
| biometric_hash | TEXT | | Biometric auth hash |
| current_spend | DECIMAL(12,2) | DEFAULT 0 | Current spending |
| limit_amount | DECIMAL(12,2) | | Spending limit |
| penalty_points | INTEGER | DEFAULT 0 | Penalty points |
| violation_count | INTEGER | DEFAULT 0 | Number of violations |
| emergency_override_count | INTEGER | DEFAULT 0 | Emergency overrides |
| last_violation_at | TIMESTAMPTZ | | Last violation time |
| metadata | JSONB | DEFAULT '{}' | Additional metadata |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_budget_commitments_user_id ON public.budget_commitments(user_id);
CREATE INDEX idx_budget_commitments_profile_id ON public.budget_commitments(profile_id);
CREATE INDEX idx_budget_commitments_active ON public.budget_commitments(user_id, is_active) WHERE is_active = true;
CREATE INDEX idx_budget_commitments_type ON public.budget_commitments(commitment_type);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own commitments" ON public.budget_commitments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own commitments" ON public.budget_commitments
  FOR ALL USING (auth.uid() = user_id);
```

---

### 6.2 TABLE: commitment_violations

**Purpose:** Budget commitment violation log

**CREATE TABLE:**
```sql
CREATE TABLE public.commitment_violations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  commitment_id UUID NOT NULL REFERENCES public.budget_commitments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  transaction_id UUID REFERENCES public.transactions(id),
  violation_type TEXT NOT NULL CHECK (violation_type IN ('overspend', 'blocked_merchant', 'category_exceeded', 'amount_cap_exceeded')),
  severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  amount DECIMAL(12,2) NOT NULL,
  merchant_name TEXT,
  category TEXT,
  penalty_points INTEGER DEFAULT 0,
  ai_message TEXT,
  user_response TEXT CHECK (user_response IN ('acknowledged', 'override', 'cancelled', 'ignored')),
  was_overridden BOOLEAN DEFAULT false,
  override_reason TEXT,
  occurred_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Violation ID |
| commitment_id | UUID | NOT NULL, FK→budget_commitments | Associated commitment |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| transaction_id | UUID | FK→transactions | Related transaction |
| violation_type | TEXT | NOT NULL, CHECK | Type of violation |
| severity | TEXT | NOT NULL, CHECK | low/medium/high/critical |
| amount | DECIMAL(12,2) | NOT NULL | Transaction amount |
| merchant_name | TEXT | | Merchant name |
| category | TEXT | | Transaction category |
| penalty_points | INTEGER | DEFAULT 0 | Points deducted |
| ai_message | TEXT | | AI coach message |
| user_response | TEXT | CHECK | User's response |
| was_overridden | BOOLEAN | DEFAULT false | Override flag |
| override_reason | TEXT | | Override justification |
| occurred_at | TIMESTAMPTZ | | Violation timestamp |
| created_at | TIMESTAMPTZ | | Creation time |

**INDEXES:**
```sql
CREATE INDEX idx_violations_commitment ON public.commitment_violations(commitment_id);
CREATE INDEX idx_violations_user ON public.commitment_violations(user_id);
CREATE INDEX idx_violations_occurred ON public.commitment_violations(occurred_at DESC);
CREATE INDEX idx_violations_severity ON public.commitment_violations(severity);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own violations" ON public.commitment_violations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert violations" ON public.commitment_violations
  FOR INSERT WITH CHECK (true);
```

---

### 6.3 TABLE: commitment_audit_log

**Purpose:** Tamper-evident audit log for commitment changes

**CREATE TABLE:**
```sql
CREATE TABLE public.commitment_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  commitment_id UUID NOT NULL REFERENCES public.budget_commitments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  action TEXT NOT NULL CHECK (action IN ('created', 'locked', 'modified', 'emergency_override', 'deleted', 'violation')),
  changes JSONB,
  previous_hash TEXT,
  current_hash TEXT,
  biometric_verified BOOLEAN DEFAULT false,
  ip_address INET,
  user_agent TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Log entry ID |
| commitment_id | UUID | NOT NULL, FK→budget_commitments | Commitment |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| action | TEXT | NOT NULL, CHECK | Action type |
| changes | JSONB | | Changes JSON |
| previous_hash | TEXT | | Previous hash |
| current_hash | TEXT | | Current hash |
| biometric_verified | BOOLEAN | DEFAULT false | Biometric flag |
| ip_address | INET | | Source IP |
| user_agent | TEXT | | User agent |
| timestamp | TIMESTAMPTZ | | Timestamp |

**INDEXES:**
```sql
CREATE INDEX idx_audit_log_commitment ON public.commitment_audit_log(commitment_id);
CREATE INDEX idx_audit_log_user ON public.commitment_audit_log(user_id);
CREATE INDEX idx_audit_log_timestamp ON public.commitment_audit_log(timestamp DESC);
```

**RLS POLICIES:**
```sql
-- Read-only for users
CREATE POLICY "Users can view own audit log" ON public.commitment_audit_log
  FOR SELECT USING (auth.uid() = user_id);

-- Append-only for system
CREATE POLICY "System can append audit log" ON public.commitment_audit_log
  FOR INSERT WITH CHECK (true);
```

---

## 7. CHAT & AI TABLES

### 7.1 TABLE: chat_messages

**Purpose:** AI chat conversation history

**CREATE TABLE:**
```sql
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  session_id UUID NOT NULL,
  message TEXT NOT NULL,
  sender TEXT NOT NULL CHECK (sender IN ('user', 'assistant')),
  message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'action')),
  metadata JSONB DEFAULT '{}',
  tokens_used INTEGER,
  model_used TEXT DEFAULT 'gpt-4',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Message ID |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| session_id | UUID | NOT NULL | Chat session ID |
| message | TEXT | NOT NULL | Message content |
| sender | TEXT | NOT NULL, CHECK | user or assistant |
| message_type | TEXT | CHECK | text/image/file/action |
| metadata | JSONB | DEFAULT '{}' | Additional metadata |
| tokens_used | INTEGER | | AI tokens consumed |
| model_used | TEXT | DEFAULT 'gpt-4' | AI model |
| created_at | TIMESTAMPTZ | NOT NULL | Creation time |

**INDEXES:**
```sql
CREATE INDEX idx_chat_messages_user_id ON public.chat_messages(user_id);
CREATE INDEX idx_chat_messages_session ON public.chat_messages(session_id);
CREATE INDEX idx_chat_messages_created ON public.chat_messages(created_at DESC);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own chat messages" ON public.chat_messages
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chat messages" ON public.chat_messages
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

---

### 7.2 TABLE: chat_sessions

**Purpose:** Chat conversation sessions

**CREATE TABLE:**
```sql
CREATE TABLE public.chat_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_name TEXT,
  ai_personality TEXT CHECK (ai_personality IN ('motivational', 'strict', 'supportive', 'analytical', 'humorous')),
  context JSONB DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  last_message_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Session ID |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| session_name | TEXT | | Display name |
| ai_personality | TEXT | CHECK | AI personality |
| context | JSONB | DEFAULT '{}' | Session context |
| is_active | BOOLEAN | DEFAULT true | Active flag |
| last_message_at | TIMESTAMPTZ | | Last message time |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_chat_sessions_user ON public.chat_sessions(user_id);
CREATE INDEX idx_chat_sessions_active ON public.chat_sessions(user_id, is_active) WHERE is_active = true;
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own sessions" ON public.chat_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own sessions" ON public.chat_sessions
  FOR ALL USING (auth.uid() = user_id);
```

---

## 8. CHECK DEPOSIT TABLES

### 8.1 TABLE: check_deposits

**Purpose:** Mobile check deposits

**CREATE TABLE:**
```sql
CREATE TABLE public.check_deposits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
  check_number TEXT,
  amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
  amount_detected DECIMAL(12,2),
  front_image_url TEXT NOT NULL,
  back_image_url TEXT NOT NULL,
  memo TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'approved', 'rejected', 'deposited')),
  rejection_reason TEXT,
  expected_availability_date DATE,
  deposited_at TIMESTAMPTZ,
  reference_number TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Deposit ID |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| account_id | UUID | NOT NULL, FK→accounts | Destination account |
| check_number | TEXT | | Check number |
| amount | DECIMAL(12,2) | NOT NULL, CHECK >0 | Deposit amount |
| amount_detected | DECIMAL(12,2) | | OCR detected amount |
| front_image_url | TEXT | NOT NULL | Front image URL |
| back_image_url | TEXT | NOT NULL | Back image URL |
| memo | TEXT | | Deposit memo |
| status | TEXT | CHECK | pending/approved/etc |
| rejection_reason | TEXT | | Rejection reason |
| expected_availability_date | DATE | | Availability date |
| deposited_at | TIMESTAMPTZ | | Deposit timestamp |
| reference_number | TEXT | | Reference number |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_check_deposits_user ON public.check_deposits(user_id);
CREATE INDEX idx_check_deposits_account ON public.check_deposits(account_id);
CREATE INDEX idx_check_deposits_status ON public.check_deposits(status);
CREATE INDEX idx_check_deposits_created ON public.check_deposits(created_at DESC);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own deposits" ON public.check_deposits
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create deposits" ON public.check_deposits
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own deposits" ON public.check_deposits
  FOR UPDATE USING (auth.uid() = user_id);
```

---

## 9. CU CONFIGURATION TABLES

### 9.1 TABLE: cu_configurations

**Purpose:** Credit union configurations (multi-tenancy)

**CREATE TABLE:**
```sql
CREATE TABLE public.cu_configurations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  cu_name TEXT NOT NULL UNIQUE,
  cu_code TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  website TEXT,
  logo_url TEXT,
  primary_color TEXT DEFAULT '#0066CC',
  secondary_color TEXT DEFAULT '#333333',
  theme_config JSONB DEFAULT '{}',
  routing_number TEXT,
  institution_code TEXT,
  swift_code TEXT,
  api_base_url TEXT,
  api_version TEXT DEFAULT 'v1',
  auth_method TEXT CHECK (auth_method IN ('oauth', 'api_key', 'jwt', 'basic')),
  is_active BOOLEAN DEFAULT true,
  is_sandbox BOOLEAN DEFAULT false,
  settings JSONB DEFAULT '{}',
  rate_limit_per_minute INTEGER DEFAULT 60,
  rate_limit_per_hour INTEGER DEFAULT 1000,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_sync_at TIMESTAMPTZ,
  metadata JSONB DEFAULT '{}',

  CONSTRAINT non_empty_cu_name CHECK (LENGTH(cu_name) > 0),
  CONSTRAINT non_empty_cu_code CHECK (LENGTH(cu_code) > 0)
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | CU ID |
| cu_name | TEXT | NOT NULL, UNIQUE | CU name |
| cu_code | TEXT | NOT NULL, UNIQUE | Short code |
| display_name | TEXT | NOT NULL | Display name |
| email | TEXT | | Contact email |
| phone | TEXT | | Contact phone |
| website | TEXT | | Website URL |
| logo_url | TEXT | | Logo URL |
| primary_color | TEXT | DEFAULT '#0066CC' | Primary brand color |
| secondary_color | TEXT | DEFAULT '#333333' | Secondary color |
| theme_config | JSONB | DEFAULT '{}' | Theme configuration |
| routing_number | TEXT | | Routing number |
| institution_code | TEXT | | Institution code |
| swift_code | TEXT | | SWIFT code |
| api_base_url | TEXT | | API base URL |
| api_version | TEXT | DEFAULT 'v1' | API version |
| auth_method | TEXT | CHECK | oauth/api_key/jwt/basic |
| is_active | BOOLEAN | DEFAULT true | Active flag |
| is_sandbox | BOOLEAN | DEFAULT false | Sandbox mode |
| settings | JSONB | DEFAULT '{}' | Settings JSON |
| rate_limit_per_minute | INTEGER | DEFAULT 60 | Rate limit/min |
| rate_limit_per_hour | INTEGER | DEFAULT 1000 | Rate limit/hour |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |
| last_sync_at | TIMESTAMPTZ | | Last sync time |
| metadata | JSONB | DEFAULT '{}' | Metadata |

**INDEXES:**
```sql
CREATE INDEX idx_cu_configurations_code ON public.cu_configurations(cu_code);
CREATE INDEX idx_cu_configurations_active ON public.cu_configurations(is_active) WHERE is_active = true;
```

**RLS POLICIES:**
```sql
CREATE POLICY "Service role can manage CU configurations" ON public.cu_configurations
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Authenticated users can view active CU configurations" ON public.cu_configurations
  FOR SELECT USING (auth.role() = 'authenticated' AND is_active = true);
```

---

## 10. PRIVACY & COMPLIANCE TABLES

### 10.1 TABLE: data_access_log

**Purpose:** FDX 1033 - Data access audit trail

**CREATE TABLE:**
```sql
CREATE TABLE public.data_access_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  accessed_by TEXT NOT NULL,
  access_type TEXT NOT NULL CHECK (access_type IN ('read', 'write', 'export', 'delete', 'share')),
  data_type TEXT NOT NULL,
  record_count INTEGER DEFAULT 0,
  ip_address INET,
  user_agent TEXT,
  application_name TEXT,
  application_id TEXT,
  success BOOLEAN DEFAULT true,
  reason TEXT,
  metadata JSONB DEFAULT '{}',
  accessed_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Log entry ID |
| user_id | UUID | NOT NULL, FK→auth.users | Data owner |
| accessed_by | TEXT | NOT NULL | Accessor (app/user) |
| access_type | TEXT | NOT NULL, CHECK | read/write/export/etc |
| data_type | TEXT | NOT NULL | Type of data accessed |
| record_count | INTEGER | DEFAULT 0 | Number of records |
| ip_address | INET | | Source IP |
| user_agent | TEXT | | User agent |
| application_name | TEXT | | Application name |
| application_id | TEXT | | Application ID |
| success | BOOLEAN | DEFAULT true | Success flag |
| reason | TEXT | | Access reason |
| metadata | JSONB | DEFAULT '{}' | Metadata |
| accessed_at | TIMESTAMPTZ | | Access timestamp |

**INDEXES:**
```sql
CREATE INDEX idx_data_access_log_user ON public.data_access_log(user_id);
CREATE INDEX idx_data_access_log_accessed_at ON public.data_access_log(accessed_at DESC);
CREATE INDEX idx_data_access_log_type ON public.data_access_log(access_type);
CREATE INDEX idx_data_access_log_data_type ON public.data_access_log(data_type);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own access log" ON public.data_access_log
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert access log" ON public.data_access_log
  FOR INSERT WITH CHECK (true);
```

---

### 10.2 TABLE: connected_apps

**Purpose:** Third-party apps with data access

**CREATE TABLE:**
```sql
CREATE TABLE public.connected_apps (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  app_name TEXT NOT NULL,
  app_id TEXT NOT NULL,
  app_icon_url TEXT,
  app_website TEXT,
  permissions TEXT[] NOT NULL,
  scopes TEXT[] NOT NULL,
  access_token_hash TEXT,
  refresh_token_hash TEXT,
  token_expires_at TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  revoked_at TIMESTAMPTZ,
  revoke_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Connection ID |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| app_name | TEXT | NOT NULL | App name |
| app_id | TEXT | NOT NULL | App identifier |
| app_icon_url | TEXT | | App icon URL |
| app_website | TEXT | | App website |
| permissions | TEXT[] | NOT NULL | Permissions granted |
| scopes | TEXT[] | NOT NULL | OAuth scopes |
| access_token_hash | TEXT | | Token hash |
| refresh_token_hash | TEXT | | Refresh token hash |
| token_expires_at | TIMESTAMPTZ | | Token expiry |
| last_accessed_at | TIMESTAMPTZ | | Last access |
| is_active | BOOLEAN | DEFAULT true | Active flag |
| revoked_at | TIMESTAMPTZ | | Revocation time |
| revoke_reason | TEXT | | Revoke reason |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_connected_apps_user ON public.connected_apps(user_id);
CREATE INDEX idx_connected_apps_active ON public.connected_apps(user_id, is_active) WHERE is_active = true;
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own connected apps" ON public.connected_apps
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own connected apps" ON public.connected_apps
  FOR ALL USING (auth.uid() = user_id);
```

---

### 10.3 TABLE: data_export_requests

**Purpose:** FDX 1033 - Data portability export requests

**CREATE TABLE:**
```sql
CREATE TABLE public.data_export_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  data_types TEXT[] NOT NULL,
  export_format TEXT NOT NULL CHECK (export_format IN ('fdx_json', 'csv', 'pdf', 'xml')),
  start_date DATE,
  end_date DATE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  file_url TEXT,
  file_size_bytes BIGINT,
  download_expires_at TIMESTAMPTZ,
  downloaded_at TIMESTAMPTZ,
  error_message TEXT,
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Request ID |
| user_id | UUID | NOT NULL, FK→auth.users | User |
| data_types | TEXT[] | NOT NULL | Data types to export |
| export_format | TEXT | NOT NULL, CHECK | fdx_json/csv/pdf/xml |
| start_date | DATE | | Date range start |
| end_date | DATE | | Date range end |
| status | TEXT | CHECK | pending/processing/etc |
| file_url | TEXT | | Download URL |
| file_size_bytes | BIGINT | | File size |
| download_expires_at | TIMESTAMPTZ | | URL expiry |
| downloaded_at | TIMESTAMPTZ | | Download time |
| error_message | TEXT | | Error message |
| requested_at | TIMESTAMPTZ | | Request time |
| completed_at | TIMESTAMPTZ | | Completion time |

**INDEXES:**
```sql
CREATE INDEX idx_data_export_requests_user ON public.data_export_requests(user_id);
CREATE INDEX idx_data_export_requests_status ON public.data_export_requests(status);
CREATE INDEX idx_data_export_requests_requested ON public.data_export_requests(requested_at DESC);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own export requests" ON public.data_export_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create export requests" ON public.data_export_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);
```

---

## 11. NOTIFICATION & SETTINGS TABLES

### 11.1 TABLE: notification_preferences

**Purpose:** User notification settings

**CREATE TABLE:**
```sql
CREATE TABLE public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email_enabled BOOLEAN DEFAULT true,
  push_enabled BOOLEAN DEFAULT true,
  sms_enabled BOOLEAN DEFAULT false,
  transaction_alerts BOOLEAN DEFAULT true,
  budget_alerts BOOLEAN DEFAULT true,
  security_alerts BOOLEAN DEFAULT true,
  marketing_emails BOOLEAN DEFAULT false,
  weekly_summary BOOLEAN DEFAULT true,
  violation_alerts BOOLEAN DEFAULT true,
  payment_reminders BOOLEAN DEFAULT true,
  low_balance_threshold DECIMAL(10,2) DEFAULT 100.00,
  large_transaction_threshold DECIMAL(10,2) DEFAULT 500.00,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Preference ID |
| user_id | UUID | NOT NULL, UNIQUE, FK→auth.users | User |
| email_enabled | BOOLEAN | DEFAULT true | Email notifications |
| push_enabled | BOOLEAN | DEFAULT true | Push notifications |
| sms_enabled | BOOLEAN | DEFAULT false | SMS notifications |
| transaction_alerts | BOOLEAN | DEFAULT true | Transaction alerts |
| budget_alerts | BOOLEAN | DEFAULT true | Budget alerts |
| security_alerts | BOOLEAN | DEFAULT true | Security alerts |
| marketing_emails | BOOLEAN | DEFAULT false | Marketing emails |
| weekly_summary | BOOLEAN | DEFAULT true | Weekly summary |
| violation_alerts | BOOLEAN | DEFAULT true | Violation alerts |
| payment_reminders | BOOLEAN | DEFAULT true | Payment reminders |
| low_balance_threshold | DECIMAL(10,2) | DEFAULT 100.00 | Low balance amount |
| large_transaction_threshold | DECIMAL(10,2) | DEFAULT 500.00 | Large transaction |
| quiet_hours_start | TIME | | Quiet hours start |
| quiet_hours_end | TIME | | Quiet hours end |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_notification_preferences_user ON public.notification_preferences(user_id);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own preferences" ON public.notification_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own preferences" ON public.notification_preferences
  FOR ALL USING (auth.uid() = user_id);
```

---

### 11.2 TABLE: accessibility_settings

**Purpose:** Accessibility preferences per user

**CREATE TABLE:**
```sql
CREATE TABLE public.accessibility_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  color_blind_mode TEXT CHECK (color_blind_mode IN ('none', 'protanopia', 'deuteranopia', 'tritanopia')),
  high_contrast BOOLEAN DEFAULT false,
  font_scale DECIMAL(3,2) DEFAULT 1.00 CHECK (font_scale >= 0.75 AND font_scale <= 2.00),
  reduce_motion BOOLEAN DEFAULT false,
  screen_reader_optimized BOOLEAN DEFAULT false,
  haptic_feedback_strength TEXT DEFAULT 'medium' CHECK (haptic_feedback_strength IN ('off', 'light', 'medium', 'strong')),
  voice_control_enabled BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Settings ID |
| user_id | UUID | NOT NULL, UNIQUE, FK→auth.users | User |
| color_blind_mode | TEXT | CHECK | none/protanopia/etc |
| high_contrast | BOOLEAN | DEFAULT false | High contrast mode |
| font_scale | DECIMAL(3,2) | CHECK 0.75-2.00 | Font size scale |
| reduce_motion | BOOLEAN | DEFAULT false | Reduce animations |
| screen_reader_optimized | BOOLEAN | DEFAULT false | Screen reader mode |
| haptic_feedback_strength | TEXT | CHECK | off/light/medium/strong |
| voice_control_enabled | BOOLEAN | DEFAULT false | Voice control |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_accessibility_settings_user ON public.accessibility_settings(user_id);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own accessibility settings" ON public.accessibility_settings
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own accessibility settings" ON public.accessibility_settings
  FOR ALL USING (auth.uid() = user_id);
```

---

## 12. SECURITY TABLES

### 12.1 TABLE: two_factor_auth

**Purpose:** 2FA configuration

**CREATE TABLE:**
```sql
CREATE TABLE public.two_factor_auth (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  is_enabled BOOLEAN DEFAULT false,
  method TEXT CHECK (method IN ('sms', 'email', 'authenticator_app')),
  phone_number_encrypted TEXT,
  email_encrypted TEXT,
  totp_secret_encrypted TEXT,
  backup_codes_encrypted TEXT[],
  last_verified_at TIMESTAMPTZ,
  enabled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | 2FA ID |
| user_id | UUID | NOT NULL, UNIQUE, FK→auth.users | User |
| is_enabled | BOOLEAN | DEFAULT false | Enabled flag |
| method | TEXT | CHECK | sms/email/authenticator_app |
| phone_number_encrypted | TEXT | | Encrypted phone |
| email_encrypted | TEXT | | Encrypted email |
| totp_secret_encrypted | TEXT | | Encrypted TOTP secret |
| backup_codes_encrypted | TEXT[] | | Encrypted backup codes |
| last_verified_at | TIMESTAMPTZ | | Last verification |
| enabled_at | TIMESTAMPTZ | | Enable timestamp |
| created_at | TIMESTAMPTZ | | Creation time |
| updated_at | TIMESTAMPTZ | | Update time |

**INDEXES:**
```sql
CREATE INDEX idx_two_factor_auth_user ON public.two_factor_auth(user_id);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own 2FA settings" ON public.two_factor_auth
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own 2FA settings" ON public.two_factor_auth
  FOR ALL USING (auth.uid() = user_id);
```

---

### 12.2 TABLE: security_events

**Purpose:** Security event log

**CREATE TABLE:**
```sql
CREATE TABLE public.security_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type TEXT NOT NULL CHECK (event_type IN ('login', 'logout', 'password_change', '2fa_enabled', '2fa_disabled', 'failed_login', 'account_locked', 'suspicious_activity')),
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  description TEXT NOT NULL,
  ip_address INET,
  user_agent TEXT,
  location JSONB,
  metadata JSONB DEFAULT '{}',
  occurred_at TIMESTAMPTZ DEFAULT NOW()
);
```

**FIELDS:**
| Field Name | Type | Constraints | Description |
|------------|------|-------------|-------------|
| id | UUID | PRIMARY KEY | Event ID |
| user_id | UUID | FK→auth.users | User (optional) |
| event_type | TEXT | NOT NULL, CHECK | Event type |
| severity | TEXT | NOT NULL, CHECK | info/warning/critical |
| description | TEXT | NOT NULL | Event description |
| ip_address | INET | | Source IP |
| user_agent | TEXT | | User agent |
| location | JSONB | | Location data |
| metadata | JSONB | DEFAULT '{}' | Metadata |
| occurred_at | TIMESTAMPTZ | | Event timestamp |

**INDEXES:**
```sql
CREATE INDEX idx_security_events_user ON public.security_events(user_id);
CREATE INDEX idx_security_events_occurred ON public.security_events(occurred_at DESC);
CREATE INDEX idx_security_events_type ON public.security_events(event_type);
CREATE INDEX idx_security_events_severity ON public.security_events(severity);
```

**RLS POLICIES:**
```sql
CREATE POLICY "Users can view own security events" ON public.security_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert security events" ON public.security_events
  FOR INSERT WITH CHECK (true);
```

---

# MISSING SCREENS TO BUILD

## 1. TRANSACTIONS SCREEN
**Route:** `/transactions`
**Priority:** HIGH

**Purpose:** Full transaction list with filtering and search

**Required Features:**
- Transaction list (all accounts)
- Filter by account, date, category, amount
- Search by merchant/description
- Sort options
- Export functionality
- Pagination

**Database Tables Used:**
- transactions
- accounts
- categories (needs to be created)

**Widgets:**
- EnhancedTransactionItem
- TransactionFilterSheet
- SkeletonLoaders (loading state)

---

## 2. CARDS SCREEN
**Route:** `/cards`
**Priority:** HIGH

**Purpose:** Card management dashboard

**Required Features:**
- Card list (physical & virtual)
- 3D card flip animations
- Add new card
- Card details view
- Lock/unlock cards
- View recent transactions per card

**Database Tables Used:**
- bank_cards
- transactions (card transactions)

**Widgets:**
- CardWidget
- CardItemSkeleton

---

## 3. NET WORTH SCREEN
**Route:** `/net-worth`
**Priority:** MEDIUM

**Purpose:** Net worth tracking and visualization

**Required Features:**
- Total assets calculation
- Total liabilities calculation
- Net worth chart over time
- Asset breakdown (accounts, investments, property)
- Liability breakdown (loans, credit cards)

**Database Tables Used:**
- accounts
- bank_cards
- net_worth_snapshots (needs to be created)

**Widgets:**
- Charts (fl_chart)
- AnalyticsSkeleton

---

## 4. SAVINGS GOALS SCREEN
**Route:** `/savings-goals`
**Priority:** MEDIUM

**Purpose:** Savings goal tracking

**Required Features:**
- Create savings goal
- Track progress
- Automated transfers to goal
- Goal categories
- Visual progress indicators

**Database Tables Needed:**
CREATE TABLE public.savings_goals (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  goal_name TEXT NOT NULL,
  target_amount DECIMAL(12,2) NOT NULL,
  current_amount DECIMAL(12,2) DEFAULT 0,
  target_date DATE,
  category TEXT,
  auto_transfer_enabled BOOLEAN DEFAULT false,
  transfer_amount DECIMAL(10,2),
  transfer_frequency TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 5. INVESTMENTS SCREEN
**Route:** `/investments`
**Priority:** LOW

**Purpose:** Investment account management

**Required Features:**
- Investment account list
- Holdings view
- Performance charts
- Buy/sell functionality
- Portfolio allocation

**Database Tables Needed:**
- accounts (type: investment)
- investment_holdings (needs to be created)
- investment_transactions (needs to be created)

---

## 6. BUSINESS BANKING SCREEN
**Route:** `/business`
**Priority:** MEDIUM

**Purpose:** Business banking features

**Required Features:**
- Business account management
- Employee access controls
- Expense tracking
- Invoice management
- Business reports

**Database Tables Needed:**
- business_profiles (needs to be created)
- employees (needs to be created)
- invoices (needs to be created)

---

## 7. LOANS SCREEN
**Route:** `/loans`
**Priority:** MEDIUM

**Purpose:** Loan management and applications

**Required Features:**
- Current loans list
- Payment schedules
- Loan calculator
- Apply for new loan
- Extra payment options

**Database Tables Needed:**
CREATE TABLE public.loans (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  loan_type TEXT CHECK (loan_type IN ('personal', 'auto', 'mortgage', 'student')),
  original_amount DECIMAL(15,2) NOT NULL,
  current_balance DECIMAL(15,2) NOT NULL,
  interest_rate DECIMAL(5,4) NOT NULL,
  monthly_payment DECIMAL(10,2) NOT NULL,
  term_months INTEGER NOT NULL,
  remaining_months INTEGER NOT NULL,
  next_payment_date DATE NOT NULL,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 8. MERCHANT OFFERS SCREEN
**Route:** `/merchant`
**Priority:** LOW

**Purpose:** Merchant offers and cashback

**Required Features:**
- Available offers
- Activated offers
- Cashback tracking
- Featured merchants
- Offer categories

**Database Tables Needed:**
CREATE TABLE public.merchant_offers (
  id UUID PRIMARY KEY,
  merchant_name TEXT NOT NULL,
  offer_description TEXT NOT NULL,
  cashback_percentage DECIMAL(5,2),
  cashback_amount DECIMAL(10,2),
  category TEXT,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 9. PAYROLL SCREEN
**Route:** `/payroll`
**Priority:** LOW

**Purpose:** Payroll management for business accounts

**Required Features:**
- Employee list
- Pay schedule setup
- Direct deposit configuration
- Tax withholding
- Pay stubs

**Database Tables Needed:**
- employees (needs to be created)
- payroll_runs (needs to be created)
- pay_stubs (needs to be created)

---

## 10. COMMITMENT DETAILS SCREEN
**Route:** `/commitment-details/:id`
**Priority:** HIGH

**Purpose:** Detailed budget commitment view

**Required Features:**
- Commitment overview
- Progress tracking
- Violation history
- Edit commitment (if unlocked)
- Emergency override
- Delete commitment

**Database Tables Used:**
- budget_commitments
- commitment_violations
- commitment_audit_log

---

## 11. SECURITY SETTINGS SCREEN
**Route:** `/security` or `/settings/security`
**Priority:** HIGH

**Purpose:** Security configuration hub

**Required Features:**
- Password change
- 2FA setup/management
- Biometric settings
- Security events log
- Trusted devices
- Session management

**Database Tables Used:**
- two_factor_auth
- security_events
- trusted_devices (needs to be created)

---

## 12. ACCOUNT SETTINGS SCREEN
**Route:** `/settings/account`
**Priority:** MEDIUM

**Purpose:** Account management

**Required Features:**
- Profile editing
- Email/phone update
- Address update
- Close account
- Download data

**Database Tables Used:**
- users
- user_profiles

---

## 13. CATEGORIES MANAGEMENT SCREEN
**Route:** `/settings/categories`
**Priority:** LOW

**Purpose:** Custom transaction categories

**Required Features:**
- View categories
- Create custom category
- Edit category
- Assign colors/icons
- Category budget limits

**Database Tables Needed:**
CREATE TABLE public.transaction_categories (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  category_name TEXT NOT NULL,
  category_icon TEXT,
  category_color TEXT,
  is_custom BOOLEAN DEFAULT false,
  parent_category TEXT,
  budget_limit DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 14. STATEMENTS & DOCUMENTS SCREEN
**Route:** `/documents` or `/statements`
**Priority:** MEDIUM

**Purpose:** View and download statements

**Required Features:**
- Monthly statements list
- Tax documents
- Download PDF
- Year-end summaries
- Transaction receipts

**Database Tables Needed:**
CREATE TABLE public.documents (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  document_type TEXT NOT NULL,
  document_name TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size_bytes BIGINT,
  statement_month DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 15. RECIPIENTS/CONTACTS SCREEN
**Route:** `/contacts` or `/recipients`
**Priority:** MEDIUM

**Purpose:** Manage transfer recipients

**Required Features:**
- Saved recipients list
- Add recipient
- Edit recipient
- Favorite recipients
- Recent recipients
- Zelle contacts

**Database Tables Used:**
- zelle_recipients
- payees

---

# MISSING FEATURES

## 1. COMPREHENSIVE ONBOARDING SYSTEM

### CURRENT STATE:
- Basic onboarding screens exist
- Missing slider implementation
- Missing step indicators
- Missing progress tracking

### REQUIRED:
**Onboarding Flow with Sliders:**

```
SCREEN 1: Welcome Slider
┌─────────────────────────────────┐
│  ●  ○  ○  ○  ○                  │
│                                 │
│     [Welcome Illustration]      │
│                                 │
│   Welcome to Banking App!       │
│   Your financial partner        │
│                                 │
│         [Skip]    [Next] →      │
└─────────────────────────────────┘

SCREEN 2: Features Slider
┌─────────────────────────────────┐
│  ○  ●  ○  ○  ○                  │
│                                 │
│     [Features Illustration]     │
│                                 │
│   Track Your Spending           │
│   Real-time insights            │
│                                 │
│    ← [Back]      [Next] →       │
└─────────────────────────────────┘

SCREEN 3: Security Slider
┌─────────────────────────────────┐
│  ○  ○  ●  ○  ○                  │
│                                 │
│     [Security Illustration]     │
│                                 │
│   Bank-Level Security           │
│   Your data is protected        │
│                                 │
│    ← [Back]      [Next] →       │
└─────────────────────────────────┘

SCREEN 4: AI Features Slider
┌─────────────────────────────────┐
│  ○  ○  ○  ●  ○                  │
│                                 │
│       [AI Illustration]         │
│                                 │
│   AI-Powered Insights           │
│   Smart budget management       │
│                                 │
│    ← [Back]      [Next] →       │
└─────────────────────────────────┘

SCREEN 5: Get Started
┌─────────────────────────────────┐
│  ○  ○  ○  ○  ●                  │
│                                 │
│     [Success Illustration]      │
│                                 │
│   Let's Get Started!            │
│   Create your account now       │
│                                 │
│    ← [Back]   [GET STARTED]     │
└─────────────────────────────────┘
```

**Implementation Required:**
- PageView widget for slider
- Dot indicators
- Swipe gestures
- Auto-advance option
- Skip button
- Progress tracking

**Database Table:**
CREATE TABLE public.onboarding_progress (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  completed_slides INTEGER[] DEFAULT '{}',
  completed BOOLEAN DEFAULT false,
  skipped BOOLEAN DEFAULT false,
  completed_at TIMESTAMPTZ
);

---

## 2. TRANSACTION CATEGORIZATION

### CURRENT STATE:
- Categories stored as text array
- No custom categories
- No category budget limits

### REQUIRED:
- Category management system
- Custom category creation
- Category icons and colors
- Budget limits per category
- Category spending trends

**Implementation:**
- Create transaction_categories table (see above)
- Category picker widget
- Category budget tracking
- Category analytics

---

## 3. RECURRING TRANSACTION DETECTION

### CURRENT STATE:
- is_recurring flag exists
- No automatic detection
- No management UI

### REQUIRED:
- AI-based recurring transaction detection
- Recurring transaction management screen
- Edit/cancel recurring transactions
- Subscription tracking
- Renewal reminders

**Database Table:**
CREATE TABLE public.recurring_transactions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  merchant_name TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  frequency TEXT NOT NULL,
  next_expected_date DATE NOT NULL,
  last_transaction_date DATE,
  is_active BOOLEAN DEFAULT true,
  category TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 4. BUDGET CATEGORIES & LIMITS

### CURRENT STATE:
- Budget commitments exist for NoCap
- No traditional monthly budgets
- No category-based budgeting

### REQUIRED:
- Monthly budget by category
- Budget vs actual tracking
- Budget rollover options
- Budget alerts
- Budget templates

**Database Table:**
CREATE TABLE public.category_budgets (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  category TEXT NOT NULL,
  monthly_limit DECIMAL(10,2) NOT NULL,
  current_spend DECIMAL(10,2) DEFAULT 0,
  month DATE NOT NULL,
  rollover_enabled BOOLEAN DEFAULT false,
  alert_threshold_percentage INTEGER DEFAULT 80,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(user_id, category, month)
);

---

## 5. MERCHANT INFORMATION ENRICHMENT

### CURRENT STATE:
- Merchant logos via Clearbit CDN
- Basic merchant name
- Limited merchant data

### REQUIRED:
- Comprehensive merchant database
- Merchant categories
- Merchant contact info
- Merchant hours/location
- Merchant reviews/ratings

**Database Table:**
CREATE TABLE public.merchants (
  id UUID PRIMARY KEY,
  merchant_name TEXT NOT NULL UNIQUE,
  logo_url TEXT,
  website TEXT,
  phone TEXT,
  email TEXT,
  category TEXT,
  address JSONB,
  hours JSONB,
  rating DECIMAL(3,2),
  review_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 6. SCHEDULED TRANSFERS

### CURRENT STATE:
- scheduled_payments exists for bill pay
- No scheduled internal transfers
- No recurring transfers

### REQUIRED:
- Schedule one-time transfer
- Recurring internal transfers
- Transfer calendar view
- Edit/cancel scheduled transfers

**Implementation:**
- Extend scheduled_payments table
- Add internal transfer support
- Calendar widget
- Transfer scheduling UI

---

## 7. MULTI-CURRENCY SUPPORT

### CURRENT STATE:
- Currency field exists (default USD)
- No currency conversion
- No multi-currency accounts

### REQUIRED:
- Currency conversion rates
- Multi-currency display
- Foreign transaction handling
- Currency exchange history

**Database Table:**
CREATE TABLE public.currency_rates (
  id UUID PRIMARY KEY,
  from_currency VARCHAR(3) NOT NULL,
  to_currency VARCHAR(3) NOT NULL,
  rate DECIMAL(18,8) NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(from_currency, to_currency)
);

---

## 8. GEOLOCATION & FRAUD DETECTION

### CURRENT STATE:
- location field in transactions
- No fraud detection
- No location-based alerts

### REQUIRED:
- Transaction location tracking
- Unusual location alerts
- Travel mode
- Trusted locations
- Fraud scoring

**Database Table:**
CREATE TABLE public.fraud_alerts (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  transaction_id UUID REFERENCES public.transactions(id),
  alert_type TEXT NOT NULL,
  risk_score INTEGER CHECK (risk_score BETWEEN 0 AND 100),
  reason TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

---

## 9. REFERRAL PROGRAM

### CURRENT STATE:
- Not implemented

### REQUIRED:
- Referral code generation
- Referral tracking
- Referral rewards
- Referral history

**Database Table:**
CREATE TABLE public.referrals (
  id UUID PRIMARY KEY,
  referrer_id UUID NOT NULL REFERENCES auth.users(id),
  referee_id UUID REFERENCES auth.users(id),
  referral_code TEXT NOT NULL UNIQUE,
  status TEXT DEFAULT 'pending',
  reward_amount DECIMAL(10,2),
  reward_paid BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

---

## 10. FINANCIAL GOALS & MILESTONES

### CURRENT STATE:
- Savings goals planned but not implemented

### REQUIRED:
- Multiple goal types (savings, debt payoff, etc.)
- Goal progress tracking
- Milestone celebrations
- Goal recommendations

**Database Tables:**
- savings_goals (see above)
- debt_payoff_goals
- milestone_achievements

---

# ONBOARDING SYSTEM REQUIREMENTS

## SLIDER-BASED ONBOARDING

### IMPLEMENTATION STEPS:

1. **Create Onboarding Slider Widget**
```dart
// File: lib/widgets/onboarding_slider.dart

class OnboardingSlider extends StatefulWidget {
  final List<OnboardingSlide> slides;
  final VoidCallback onComplete;

  const OnboardingSlider({
    required this.slides,
    required this.onComplete,
  });
}

class OnboardingSlide {
  final String title;
  final String description;
  final String illustrationPath;
  final Color backgroundColor;
}
```

2. **Update Onboarding Screen**
```dart
// File: lib/screens/onboarding/onboarding_screen.dart

final slides = [
  OnboardingSlide(
    title: 'Welcome to Your Bank',
    description: 'Modern banking made simple',
    illustrationPath: 'assets/onboarding/welcome.svg',
    backgroundColor: Colors.blue,
  ),
  OnboardingSlide(
    title: 'Track Your Spending',
    description: 'Real-time insights and analytics',
    illustrationPath: 'assets/onboarding/analytics.svg',
    backgroundColor: Colors.green,
  ),
  // ... more slides
];
```

3. **Add Dot Indicators**
```dart
// File: lib/widgets/dot_indicator.dart

class DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
}
```

4. **Black & White Consistent Design**
- Use only black (#000000) and white (#FFFFFF)
- Subtle grays for borders/shadows (#F5F5F5, #E0E0E0)
- No colors except for illustrations
- Clean, minimalist design
- Consistent list tiles (use ConsistentListTile widget)

---

# IMPLEMENTATION CHECKLIST

## IMMEDIATE PRIORITIES (Week 1-2)

### ✓ Already Implemented
- [x] User authentication
- [x] Account management
- [x] Transaction tracking
- [x] Plaid integration
- [x] Check deposit
- [x] Zelle payments
- [x] Bill pay
- [x] Budget commitments (NoCap)
- [x] Privacy/compliance (FDX 1033)
- [x] Card management (partial)

### ⬜ High Priority - Implement Now
- [ ] `/transactions` - Transaction List Screen
- [ ] `/cards` - Cards Management Screen
- [ ] `/commitment-details/:id` - Commitment Details
- [ ] `/security` - Security Settings Screen
- [ ] Onboarding Slider System
- [ ] Transaction categorization
- [ ] Category budgets

## MEDIUM PRIORITY (Week 3-4)

- [ ] `/net-worth` - Net Worth Tracking
- [ ] `/savings-goals` - Savings Goals
- [ ] `/business` - Business Banking
- [ ] `/loans` - Loan Management
- [ ] `/documents` - Statements & Documents
- [ ] `/contacts` - Recipient Management
- [ ] Recurring transaction detection
- [ ] Scheduled transfers
- [ ] Fraud detection basics

## LOW PRIORITY (Week 5+)

- [ ] `/investments` - Investment Accounts
- [ ] `/merchant` - Merchant Offers
- [ ] `/payroll` - Payroll Management
- [ ] Multi-currency support
- [ ] Referral program
- [ ] Financial goals & milestones
- [ ] Advanced fraud detection
- [ ] Geolocation features

---

# API ENDPOINTS TO IMPLEMENT

When you create the Supabase API, implement these endpoints:

## Authentication
```
POST   /auth/signup
POST   /auth/login
POST   /auth/logout
POST   /auth/refresh
POST   /auth/password/reset
POST   /auth/password/change
```

## Accounts
```
GET    /accounts
GET    /accounts/:id
POST   /accounts
PUT    /accounts/:id
DELETE /accounts/:id
POST   /accounts/sync         (trigger Plaid sync)
```

## Transactions
```
GET    /transactions
GET    /transactions/:id
POST   /transactions
PUT    /transactions/:id
DELETE /transactions/:id
GET    /transactions/search
GET    /transactions/export
```

## Cards
```
GET    /cards
GET    /cards/:id
POST   /cards
PUT    /cards/:id
DELETE /cards/:id
POST   /cards/:id/lock
POST   /cards/:id/unlock
```

## Transfers
```
POST   /transfers/internal
POST   /transfers/external
GET    /transfers/history
```

## Zelle
```
POST   /zelle/send
POST   /zelle/request
GET    /zelle/recipients
POST   /zelle/recipients
GET    /zelle/transactions
```

## Bill Pay
```
GET    /payees
POST   /payees
PUT    /payees/:id
DELETE /payees/:id
POST   /payments/schedule
GET    /payments/scheduled
PUT    /payments/:id
DELETE /payments/:id
```

## Budget Commitments
```
GET    /commitments
POST   /commitments
GET    /commitments/:id
PUT    /commitments/:id
DELETE /commitments/:id
POST   /commitments/:id/lock
GET    /commitments/:id/violations
```

## Check Deposit
```
POST   /check-deposits
POST   /check-deposits/upload
GET    /check-deposits/:id
GET    /check-deposits/history
```

## Privacy & Export (FDX 1033)
```
POST   /export/request
GET    /export/requests
GET    /export/:id/download
GET    /access-log
GET    /connected-apps
POST   /connected-apps/:id/revoke
```

---

# CONCLUSION

This document provides:
1. ✅ Complete database schema with all field definitions
2. ✅ Missing screens that need to be built
3. ✅ Missing features to implement
4. ✅ Onboarding system requirements
5. ✅ Implementation checklist
6. ✅ API endpoints to create

**YOU (User) create the Supabase tables and API endpoints.**
**I (Assistant) defined everything you need.**

When you're ready to implement, start with the High Priority items and work down the list.

All field names, types, and constraints are specified exactly as they should be created in Supabase.

---

# DOCUMENT END

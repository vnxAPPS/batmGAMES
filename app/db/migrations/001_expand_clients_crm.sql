-- Migration 001: Expand clients table for CRM functionality
-- Based on e-commerce best practices (Shopify, HubSpot, Mailchimp)

-- ══════════════════════════════════════════════════════════════
-- SECTION 1: Contact Information
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- ══════════════════════════════════════════════════════════════
-- SECTION 2: Telegram Extended Info
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS language_code VARCHAR(10) DEFAULT 'ru';
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_bot BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_premium BOOLEAN DEFAULT false;

-- ══════════════════════════════════════════════════════════════
-- SECTION 3: Demographics
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS age_range VARCHAR(10);
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(10);
ALTER TABLE users ADD COLUMN IF NOT EXISTS city TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS country VARCHAR(2) DEFAULT 'RU';

-- ══════════════════════════════════════════════════════════════
-- SECTION 4: Acquisition & UTM Tracking (Google Analytics standard)
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS acquisition_source TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referrer_user_id BIGINT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS utm_source TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS utm_medium TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS utm_campaign TEXT;

-- ══════════════════════════════════════════════════════════════
-- SECTION 5: Engagement Metrics
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS requests_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS joined_community BOOLEAN DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS community_joined_at TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscribed_newsletter BOOLEAN DEFAULT false;

-- ══════════════════════════════════════════════════════════════
-- SECTION 6: Purchase Behavior (RFM Analysis)
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_orders INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS total_spent DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS avg_order_value DECIMAL(10,2) DEFAULT 0.00;
ALTER TABLE users ADD COLUMN IF NOT EXISTS first_order_date TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_order_date TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS favorite_category TEXT;

-- ══════════════════════════════════════════════════════════════
-- SECTION 7: Segmentation & Tags
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS customer_tier TEXT DEFAULT 'Новый';
ALTER TABLE users ADD COLUMN IF NOT EXISTS interests TEXT DEFAULT '[]';
ALTER TABLE users ADD COLUMN IF NOT EXISTS tags TEXT DEFAULT '[]';
ALTER TABLE users ADD COLUMN IF NOT EXISTS communication_preferences TEXT DEFAULT '{"email": true, "sms": false}';

-- ══════════════════════════════════════════════════════════════
-- SECTION 8: CRM Notes & Scoring
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS crm_score INTEGER DEFAULT 0;

-- ══════════════════════════════════════════════════════════════
-- SECTION 9: GDPR Compliance (EU) & ФЗ-152 (RU)
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS consent_given BOOLEAN DEFAULT true;
ALTER TABLE users ADD COLUMN IF NOT EXISTS consent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS data_retention_until TIMESTAMP;
ALTER TABLE users ADD COLUMN IF NOT EXISTS opted_out BOOLEAN DEFAULT false;

-- ══════════════════════════════════════════════════════════════
-- SECTION 10: Google Sheets Sync
-- ══════════════════════════════════════════════════════════════
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_sheets_row INTEGER;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_synced_at TIMESTAMP;

-- ══════════════════════════════════════════════════════════════
-- Indexes for performance
-- ══════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_customer_tier ON users(customer_tier);
CREATE INDEX IF NOT EXISTS idx_users_last_seen ON users(last_seen DESC);
CREATE INDEX IF NOT EXISTS idx_users_acquisition_source ON users(acquisition_source);
CREATE INDEX IF NOT EXISTS idx_users_referrer ON users(referrer_user_id);

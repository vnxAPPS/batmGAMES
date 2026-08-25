-- Migration 002: Create orders table for purchase tracking
-- E-commerce standard: order history for RFM analysis

CREATE TABLE IF NOT EXISTS orders (
    -- ══════════════════════════════════════════════════════════════
    -- Primary Key & Relations
    -- ══════════════════════════════════════════════════════════════
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id BIGINT NOT NULL,

    -- ══════════════════════════════════════════════════════════════
    -- Timestamps
    -- ══════════════════════════════════════════════════════════════
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- ══════════════════════════════════════════════════════════════
    -- Order Status
    -- ══════════════════════════════════════════════════════════════
    status TEXT DEFAULT 'pending', -- pending, paid, completed, cancelled, refunded

    -- ══════════════════════════════════════════════════════════════
    -- Product Info
    -- ══════════════════════════════════════════════════════════════
    product_name TEXT NOT NULL,
    product_id TEXT,
    category TEXT, -- "Стратегия", "Семейные", "Каркассон", etc.
    quantity INTEGER DEFAULT 1,

    -- ══════════════════════════════════════════════════════════════
    -- Financial
    -- ══════════════════════════════════════════════════════════════
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT '₸',
    discount_amount DECIMAL(10,2) DEFAULT 0.00,
    promo_code TEXT,

    -- ══════════════════════════════════════════════════════════════
    -- Payment
    -- ══════════════════════════════════════════════════════════════
    payment_method TEXT, -- kaspi, card, cash, terminal
    payment_id TEXT,

    -- ══════════════════════════════════════════════════════════════
    -- Delivery
    -- ══════════════════════════════════════════════════════════════
    delivery_method TEXT, -- pickup, courier, post
    delivery_address TEXT,
    delivery_cost DECIMAL(10,2) DEFAULT 0.00,

    -- ══════════════════════════════════════════════════════════════
    -- Additional
    -- ══════════════════════════════════════════════════════════════
    comment TEXT,

    -- Foreign Key
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ══════════════════════════════════════════════════════════════
-- Indexes for performance
-- ══════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_category ON orders(category);

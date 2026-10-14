-- ============================================================================
-- Chapter 06 Lab: PostgreSQL Database Design, DDL, and Transactions
-- ============================================================================

-- 1. Setup Extensions & Custom Types
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM ('pending', 'processing', 'completed', 'cancelled');
    END IF;
END $$;

-- 2. Schema Creation (Users & Orders)
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    status order_status DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 3. Optimization Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_metadata_gin ON users USING GIN (metadata);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status_created ON orders(status, created_at DESC);

-- 4. Seed Seed Data
INSERT INTO users (id, email, password_hash, full_name, metadata) VALUES
    ('11111111-1111-4111-a111-111111111111', 'alex@example.com', '$2b$12$eImiTXuWVxfM37uY4JANjO', 'Alex Dev', '{"role": "admin", "tier": "gold"}'),
    ('22222222-2222-4222-a222-222222222222', 'sarah@example.com', '$2b$12$eImiTXuWVxfM37uY4JANjO', 'Sarah User', '{"role": "user", "tier": "silver"}');

INSERT INTO orders (user_id, total_amount, status) VALUES
    ('11111111-1111-4111-a111-111111111111', 149.99, 'completed'),
    ('11111111-1111-4111-a111-111111111111', 89.50, 'processing'),
    ('22222222-2222-4222-a222-222222222222', 29.99, 'pending');

-- 5. Analytical & Index Demonstration Queries

-- Join with Aggregation (Total spend per user)
SELECT 
    u.full_name,
    u.email,
    COUNT(o.id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0.00) AS grand_total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
GROUP BY u.id, u.full_name, u.email;

-- Query JSONB column using GIN Index
SELECT full_name, email, metadata->>'tier' AS loyalty_tier
FROM users
WHERE metadata @> '{"role": "admin"}';

-- 6. Atomic Transaction Example
BEGIN;

INSERT INTO orders (user_id, total_amount, status) 
VALUES ('22222222-2222-4222-a222-222222222222', 199.99, 'pending');

-- Simulated verification check before committing
COMMIT;

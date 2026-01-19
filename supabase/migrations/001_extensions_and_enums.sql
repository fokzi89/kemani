-- ============================================================
-- Migration 001: Extensions and Enums
-- ============================================================
-- Purpose: Enable required PostgreSQL extensions and create custom types

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- Enums
CREATE TYPE business_type AS ENUM ('supermarket', 'pharmacy', 'grocery', 'mini_mart', 'restaurant');
CREATE TYPE user_role AS ENUM ('platform_admin', 'tenant_admin', 'branch_manager', 'cashier', 'driver');
CREATE TYPE payment_method AS ENUM ('cash', 'card', 'bank_transfer', 'mobile_money');
CREATE TYPE transaction_type AS ENUM ('sale', 'restock', 'adjustment', 'expiry', 'transfer_out', 'transfer_in');
CREATE TYPE transfer_status AS ENUM ('pending', 'in_transit', 'completed', 'cancelled');
CREATE TYPE sale_status AS ENUM ('completed', 'voided', 'refunded');
CREATE TYPE order_type AS ENUM ('marketplace', 'ecommerce_sync', 'ai_chat');
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'preparing', 'ready', 'completed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('unpaid', 'paid', 'refunded');
CREATE TYPE fulfillment_type AS ENUM ('pickup', 'delivery');
CREATE TYPE delivery_type AS ENUM ('local_bike', 'local_bicycle', 'intercity');
CREATE TYPE delivery_status AS ENUM ('pending', 'assigned', 'picked_up', 'in_transit', 'delivered', 'failed', 'cancelled');
CREATE TYPE proof_type AS ENUM ('photo', 'signature', 'recipient_name');
CREATE TYPE vehicle_type AS ENUM ('bike', 'bicycle');
CREATE TYPE platform_type AS ENUM ('woocommerce', 'shopify', 'custom');
CREATE TYPE sync_status AS ENUM ('pending', 'syncing', 'success', 'error');
CREATE TYPE chat_status AS ENUM ('active', 'completed', 'escalated', 'abandoned');
CREATE TYPE sender_type AS ENUM ('customer', 'ai_agent', 'staff');
CREATE TYPE plan_tier AS ENUM ('free', 'basic', 'pro', 'enterprise', 'enterprise_custom');
CREATE TYPE subscription_status AS ENUM ('active', 'suspended', 'cancelled');
CREATE TYPE settlement_status AS ENUM ('pending', 'invoiced', 'paid');
CREATE TYPE message_direction AS ENUM ('outbound', 'inbound');
CREATE TYPE message_type AS ENUM ('text', 'template', 'media');
CREATE TYPE whatsapp_delivery_status AS ENUM ('pending', 'sent', 'delivered', 'read', 'failed');
CREATE TYPE receipt_format AS ENUM ('pdf', 'thermal_print', 'email');

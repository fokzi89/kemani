-- ============================================================
-- Migration 005: Order and Delivery Tables
-- ============================================================
-- Purpose: Create orders, order items, riders, deliveries, and staff attendance tables

-- Orders
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    order_number VARCHAR(50) NOT NULL,
    customer_id UUID NOT NULL REFERENCES customers(id),
    order_type order_type NOT NULL,
    order_status order_status DEFAULT 'pending',
    payment_status payment_status DEFAULT 'unpaid',
    payment_method payment_method,
    payment_reference VARCHAR(255),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    delivery_fee DECIMAL(12,2) DEFAULT 0 CHECK (delivery_fee >= 0),
    tax_amount DECIMAL(12,2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(12,2) NOT NULL CHECK (total_amount >= 0),
    fulfillment_type fulfillment_type NOT NULL,
    delivery_address_id UUID REFERENCES customer_addresses(id),
    special_instructions TEXT,
    ecommerce_platform VARCHAR(50),
    ecommerce_order_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    _sync_client_id UUID,
    CONSTRAINT valid_total CHECK (total_amount = subtotal + delivery_fee + tax_amount),
    CONSTRAINT delivery_address_required CHECK (
        (fulfillment_type = 'pickup' AND delivery_address_id IS NULL) OR
        (fulfillment_type = 'delivery' AND delivery_address_id IS NOT NULL)
    )
);

CREATE TABLE order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    product_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12,2) NOT NULL CHECK (unit_price > 0),
    subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
    CONSTRAINT valid_subtotal CHECK (subtotal = unit_price * quantity)
);

-- Riders
CREATE TABLE riders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    vehicle_type vehicle_type NOT NULL,
    license_number VARCHAR(50),
    phone VARCHAR(20) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    total_deliveries INTEGER DEFAULT 0 CHECK (total_deliveries >= 0),
    successful_deliveries INTEGER DEFAULT 0 CHECK (successful_deliveries >= 0),
    average_delivery_time_minutes DECIMAL(8,2),
    rating DECIMAL(3,2) CHECK (rating >= 0 AND rating <= 5),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    CONSTRAINT valid_success_rate CHECK (successful_deliveries <= total_deliveries)
);

-- Deliveries
CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    order_id UUID UNIQUE NOT NULL REFERENCES orders(id),
    tracking_number VARCHAR(50) UNIQUE NOT NULL,
    delivery_type delivery_type NOT NULL,
    rider_id UUID REFERENCES riders(id),
    delivery_status delivery_status DEFAULT 'pending',
    customer_address TEXT NOT NULL,
    customer_phone VARCHAR(20) NOT NULL,
    customer_latitude DECIMAL(10,8),
    customer_longitude DECIMAL(11,8),
    distance_km DECIMAL(8,2),
    estimated_delivery_time TIMESTAMPTZ,
    actual_delivery_time TIMESTAMPTZ,
    proof_type proof_type,
    proof_data TEXT,
    failure_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    _sync_version BIGINT DEFAULT 1,
    _sync_modified_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT rider_required_for_local CHECK (
        (delivery_type IN ('local_bike', 'local_bicycle') AND rider_id IS NOT NULL) OR
        (delivery_type = 'intercity')
    ),
    CONSTRAINT proof_required_for_delivered CHECK (
        (delivery_status != 'delivered') OR
        (proof_type IS NOT NULL AND proof_data IS NOT NULL)
    )
);

-- Staff Attendance
CREATE TABLE staff_attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES users(id),
    clock_in_at TIMESTAMPTZ NOT NULL,
    clock_out_at TIMESTAMPTZ,
    total_hours DECIMAL(8,2),
    shift_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_clock_out CHECK (clock_out_at IS NULL OR clock_out_at > clock_in_at),
    CONSTRAINT valid_total_hours CHECK (
        (clock_out_at IS NULL AND total_hours IS NULL) OR
        (clock_out_at IS NOT NULL AND total_hours = EXTRACT(EPOCH FROM (clock_out_at - clock_in_at)) / 3600)
    )
);

-- Sample Data Generator for Testing POS Analytics
-- This script generates realistic sample data for testing the POS system
-- IMPORTANT: Only run this on development/test databases, NOT in production!

-- ============================================================================
-- Get current user's tenant and branch IDs
-- ============================================================================
DO $$
DECLARE
  sample_tenant_id uuid;
  sample_branch_id uuid;
  sample_user_id uuid;
  sample_customer_ids uuid[];
  sample_product_ids uuid[];
  current_date date := CURRENT_DATE;
  sale_date timestamptz;
  sale_count int := 0;
  i int;
  j int;
BEGIN
  -- Get a tenant ID (use the first tenant or create a sample one)
  SELECT id INTO sample_tenant_id FROM tenants LIMIT 1;

  IF sample_tenant_id IS NULL THEN
    RAISE EXCEPTION 'No tenant found. Please create a tenant first.';
  END IF;

  -- Get a branch ID for this tenant
  SELECT id INTO sample_branch_id FROM branches WHERE tenant_id = sample_tenant_id LIMIT 1;

  IF sample_branch_id IS NULL THEN
    RAISE EXCEPTION 'No branch found for tenant. Please create a branch first.';
  END IF;

  -- Get a user ID for this tenant
  SELECT id INTO sample_user_id FROM users WHERE tenant_id = sample_tenant_id LIMIT 1;

  IF sample_user_id IS NULL THEN
    RAISE EXCEPTION 'No user found for tenant. Please create a user first.';
  END IF;

  RAISE NOTICE 'Using tenant_id: %, branch_id: %, user_id: %', sample_tenant_id, sample_branch_id, sample_user_id;

  -- ============================================================================
  -- Create Sample Products
  -- ============================================================================
  RAISE NOTICE 'Creating sample products...';

  INSERT INTO products (tenant_id, name, description, sku, category, unit_price, cost_price, is_active)
  VALUES
    (sample_tenant_id, 'Paracetamol 500mg', 'Pain relief tablets', 'MED-001', 'Medicine', 500.00, 300.00, true),
    (sample_tenant_id, 'Ibuprofen 400mg', 'Anti-inflammatory tablets', 'MED-002', 'Medicine', 800.00, 500.00, true),
    (sample_tenant_id, 'Vitamin C 1000mg', 'Immune support supplement', 'SUPP-001', 'Supplements', 1200.00, 700.00, true),
    (sample_tenant_id, 'Multivitamin', 'Daily multivitamin supplement', 'SUPP-002', 'Supplements', 1500.00, 900.00, true),
    (sample_tenant_id, 'Hand Sanitizer 500ml', 'Antibacterial hand sanitizer', 'HYG-001', 'Hygiene', 1000.00, 600.00, true),
    (sample_tenant_id, 'Face Mask (Pack of 50)', 'Disposable face masks', 'HYG-002', 'Hygiene', 2500.00, 1500.00, true),
    (sample_tenant_id, 'Bandages', 'Adhesive bandages pack', 'MED-003', 'Medicine', 600.00, 350.00, true),
    (sample_tenant_id, 'Cough Syrup', 'Cough relief syrup', 'MED-004', 'Medicine', 1800.00, 1100.00, true),
    (sample_tenant_id, 'Antiseptic Cream', 'Wound care cream', 'MED-005', 'Medicine', 900.00, 550.00, true),
    (sample_tenant_id, 'Thermometer Digital', 'Digital body thermometer', 'EQP-001', 'Equipment', 3500.00, 2000.00, true),
    (sample_tenant_id, 'Blood Pressure Monitor', 'Digital BP monitor', 'EQP-002', 'Equipment', 8500.00, 5000.00, true),
    (sample_tenant_id, 'First Aid Kit', 'Complete first aid kit', 'KIT-001', 'Kits', 5000.00, 3000.00, true),
    (sample_tenant_id, 'Eye Drops', 'Lubricating eye drops', 'MED-006', 'Medicine', 1200.00, 700.00, true),
    (sample_tenant_id, 'Antacid Tablets', 'Heartburn relief', 'MED-007', 'Medicine', 700.00, 400.00, true),
    (sample_tenant_id, 'Allergy Relief', 'Antihistamine tablets', 'MED-008', 'Medicine', 1500.00, 900.00, true)
  ON CONFLICT DO NOTHING;

  -- Get product IDs
  SELECT ARRAY_AGG(id) INTO sample_product_ids
  FROM products
  WHERE tenant_id = sample_tenant_id;

  RAISE NOTICE 'Created % products', array_length(sample_product_ids, 1);

  -- ============================================================================
  -- Create Branch Inventory
  -- ============================================================================
  RAISE NOTICE 'Creating branch inventory...';

  FOR i IN 1..array_length(sample_product_ids, 1) LOOP
    INSERT INTO branch_inventory (
      tenant_id,
      branch_id,
      product_id,
      stock_quantity,
      low_stock_threshold,
      is_active
    )
    VALUES (
      sample_tenant_id,
      sample_branch_id,
      sample_product_ids[i],
      FLOOR(RANDOM() * 500 + 100)::int, -- Random stock between 100-600
      20, -- Low stock threshold
      true
    )
    ON CONFLICT (branch_id, product_id) DO UPDATE
    SET stock_quantity = branch_inventory.stock_quantity + FLOOR(RANDOM() * 500 + 100)::int;
  END LOOP;

  -- ============================================================================
  -- Create Sample Customers
  -- ============================================================================
  RAISE NOTICE 'Creating sample customers...';

  INSERT INTO customers (tenant_id, phone, full_name, email, loyalty_points, total_purchases, purchase_count, loyalty_tier)
  VALUES
    (sample_tenant_id, '08012345678', 'John Doe', 'john.doe@example.com', 150, 15000.00, 12, 'silver'),
    (sample_tenant_id, '08098765432', 'Jane Smith', 'jane.smith@example.com', 250, 25000.00, 20, 'gold'),
    (sample_tenant_id, '07012345678', 'Ahmed Ibrahim', null, 80, 8000.00, 6, 'bronze'),
    (sample_tenant_id, '09087654321', 'Blessing Okafor', 'blessing@example.com', 120, 12000.00, 10, 'silver'),
    (sample_tenant_id, '08123456789', 'Chidi Nwankwo', null, 50, 5000.00, 4, 'bronze'),
    (sample_tenant_id, '07098765432', 'Fatima Hassan', 'fatima@example.com', 300, 30000.00, 25, 'gold'),
    (sample_tenant_id, '09012345678', 'Emeka Okonkwo', null, 40, 4000.00, 3, 'bronze'),
    (sample_tenant_id, '08087654321', 'Aisha Mohammed', 'aisha@example.com', 180, 18000.00, 15, 'silver')
  ON CONFLICT DO NOTHING;

  -- Get customer IDs
  SELECT ARRAY_AGG(id) INTO sample_customer_ids
  FROM customers
  WHERE tenant_id = sample_tenant_id;

  RAISE NOTICE 'Created % customers', array_length(sample_customer_ids, 1);

  -- ============================================================================
  -- Create Sample Sales (Last 6 Months)
  -- ============================================================================
  RAISE NOTICE 'Creating sample sales transactions...';

  -- Generate sales for the last 180 days
  FOR i IN 0..179 LOOP
    sale_date := (CURRENT_DATE - (i || ' days')::interval)::date +
                 (FLOOR(RANDOM() * 14 + 8)::int || ' hours')::interval + -- Random hour 8am-10pm
                 (FLOOR(RANDOM() * 60)::int || ' minutes')::interval;

    -- Create 1-5 sales per day
    FOR j IN 1..FLOOR(RANDOM() * 4 + 1)::int LOOP
      DECLARE
        new_sale_id uuid;
        sale_number_val text;
        customer_id_val uuid;
        num_items int;
        subtotal_val numeric := 0;
        tax_val numeric;
        discount_val numeric;
        total_val numeric;
        k int;
        product_idx int;
        quantity_val int;
        unit_price_val numeric;
        item_subtotal numeric;
      BEGIN
        new_sale_id := gen_random_uuid();
        sale_number_val := 'SALE-' || to_char(sale_date, 'YYYYMMDD') || '-' || LPAD((sale_count + 1)::text, 4, '0');

        -- 70% chance to have a customer
        IF RANDOM() < 0.7 THEN
          customer_id_val := sample_customer_ids[FLOOR(RANDOM() * array_length(sample_customer_ids, 1) + 1)::int];
        ELSE
          customer_id_val := NULL;
        END IF;

        -- Random number of items (1-5)
        num_items := FLOOR(RANDOM() * 4 + 1)::int;

        -- Insert sale record
        INSERT INTO sales (
          id,
          tenant_id,
          branch_id,
          sale_number,
          cashier_id,
          customer_id,
          subtotal,
          tax_amount,
          discount_amount,
          total_amount,
          payment_method,
          status,
          created_at,
          updated_at
        )
        VALUES (
          new_sale_id,
          sample_tenant_id,
          sample_branch_id,
          sale_number_val,
          sample_user_id,
          customer_id_val,
          0, -- Will update after items
          0,
          0,
          0,
          CASE FLOOR(RANDOM() * 4)::int
            WHEN 0 THEN 'cash'
            WHEN 1 THEN 'card'
            WHEN 2 THEN 'transfer'
            ELSE 'mobile'
          END,
          'completed',
          sale_date,
          sale_date
        );

        -- Add sale items
        FOR k IN 1..num_items LOOP
          product_idx := FLOOR(RANDOM() * array_length(sample_product_ids, 1) + 1)::int;
          quantity_val := FLOOR(RANDOM() * 3 + 1)::int; -- 1-4 items

          -- Get product price
          SELECT unit_price INTO unit_price_val
          FROM products
          WHERE id = sample_product_ids[product_idx];

          item_subtotal := quantity_val * unit_price_val;
          subtotal_val := subtotal_val + item_subtotal;

          -- Insert sale item
          INSERT INTO sale_items (
            sale_id,
            product_id,
            product_name,
            quantity,
            unit_price,
            discount_percent,
            discount_amount,
            subtotal
          )
          SELECT
            new_sale_id,
            p.id,
            p.name,
            quantity_val,
            p.unit_price,
            0,
            0,
            item_subtotal
          FROM products p
          WHERE p.id = sample_product_ids[product_idx];
        END LOOP;

        -- Calculate tax and discount
        discount_val := CASE WHEN RANDOM() < 0.2 THEN FLOOR(RANDOM() * 500 + 100)::numeric ELSE 0 END;
        tax_val := subtotal_val * 0.075;
        total_val := subtotal_val + tax_val - discount_val;

        -- Update sale totals
        UPDATE sales
        SET
          subtotal = subtotal_val,
          tax_amount = tax_val,
          discount_amount = discount_val,
          total_amount = total_val
        WHERE id = new_sale_id;

        sale_count := sale_count + 1;
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Created % sales transactions', sale_count;
  RAISE NOTICE 'Sample data generation completed successfully!';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error: %', SQLERRM;
    RAISE;
END $$;

-- ============================================================================
-- RLS for Remaining 4 Tables - Using Parent Table Joins
-- ============================================================================
-- All parent tables confirmed to have tenant_id column
-- ============================================================================

-- 1. CUSTOMER_ADDRESSES (join through customers)
ALTER TABLE customer_addresses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customer_addresses_tenant_isolation" ON customer_addresses
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM customers c
      WHERE c.id = customer_addresses.customer_id
      AND c.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- 2. RECEIPTS (join through sales)
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "receipts_tenant_isolation" ON receipts
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM sales s
      WHERE s.id = receipts.sale_id
      AND s.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- 3. TRANSFER_ITEMS (join through inter_branch_transfers)
ALTER TABLE transfer_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "transfer_items_tenant_isolation" ON transfer_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM inter_branch_transfers ibt
      WHERE ibt.id = transfer_items.transfer_id
      AND ibt.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- 4. CHAT_MESSAGES (join through chat_conversations)
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_messages_tenant_isolation" ON chat_messages
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM chat_conversations cc
      WHERE cc.id = chat_messages.conversation_id
      AND cc.tenant_id = (auth.jwt() ->> 'tenant_id')::UUID
    )
  );

-- ============================================================================
-- SUCCESS! All 4 remaining tables now secured
-- ============================================================================
-- Total secured: 8 tables (4 from previous step + 4 from this step)
-- Skipped: 1 table (spatial_ref_sys - system table, no permission)
-- ============================================================================

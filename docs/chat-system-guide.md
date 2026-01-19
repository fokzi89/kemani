# Enhanced Chat System Guide

## Overview

The chat system supports rich media, interactive elements, and plan-based feature access for customer-to-AI agent conversations.

## Plan Requirements

### Chat Feature Access
- **Available on:** Pro and Enterprise plans
- **Check function:** `has_chat_feature(tenant_id)`

### E-Commerce Chat Button (Product Detail)
- **Available on:** Pro and Enterprise plans (or explicit feature flag)
- **Check function:** `has_ecommerce_chat_feature(tenant_id)`

```sql
-- Check if tenant can use chat features
SELECT has_chat_feature('tenant-uuid-here');

-- Check if e-commerce chat button should be shown
SELECT has_ecommerce_chat_feature('tenant-uuid-here');
```

## Message Types

### 1. Text Message
```sql
INSERT INTO chat_messages (conversation_id, sender_type, message_type, message_text)
VALUES (
    'conversation-uuid',
    'customer',
    'text',
    'Do you have this product in stock?'
);
```

### 2. Image Message
```sql
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    media_url, media_size_bytes, thumbnail_url, message_text
)
VALUES (
    'conversation-uuid',
    'customer',
    'image',
    'https://storage.example.com/images/product-question.jpg',
    245678,
    'https://storage.example.com/thumbnails/product-question.jpg',
    'Is this the product?'
);
```

### 3. Audio Note
```sql
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    media_url, media_size_bytes, media_duration_seconds
)
VALUES (
    'conversation-uuid',
    'customer',
    'audio',
    'https://storage.example.com/audio/voice-note.mp3',
    123456,
    45  -- 45 seconds
);
```

### 4. Video Message
```sql
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    media_url, media_size_bytes, media_duration_seconds, thumbnail_url
)
VALUES (
    'conversation-uuid',
    'customer',
    'video',
    'https://storage.example.com/videos/product-demo.mp4',
    5242880,  -- 5MB
    120,  -- 2 minutes
    'https://storage.example.com/thumbnails/video-thumb.jpg'
);
```

### 5. Location/Delivery Coordinates
```sql
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata
)
VALUES (
    'conversation-uuid',
    'customer',
    'location',
    'Please deliver to this address',
    jsonb_build_object(
        'latitude', 6.5244,
        'longitude', 3.3792,
        'address', '123 Main Street, Victoria Island, Lagos',
        'landmark', 'Opposite First Bank'
    )
);
```

### 6. Product Card with Add to Cart
```sql
-- AI Agent sends product card
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata, action_type, action_data
)
VALUES (
    'conversation-uuid',
    'ai_agent',
    'product_card',
    'Here is the product you asked about:',
    jsonb_build_object(
        'product_id', 'product-uuid',
        'name', 'Premium Coffee Beans 500g',
        'price', 4500.00,
        'currency', 'NGN',
        'image_url', 'https://storage.example.com/products/coffee.jpg',
        'stock', 25,
        'description', 'Freshly roasted Arabica beans'
    ),
    'add_to_cart',
    jsonb_build_object(
        'product_id', 'product-uuid',
        'default_quantity', 1,
        'max_quantity', 10
    )
);

-- Customer clicks "Add to Cart" button
UPDATE chat_messages
SET action_completed_at = NOW(),
    action_completed_by = 'customer-user-uuid'
WHERE id = 'message-uuid';

-- Insert confirmation message
INSERT INTO chat_messages (conversation_id, sender_type, message_type, message_text, metadata)
VALUES (
    'conversation-uuid',
    'system',
    'system_action',
    'Added 1x Premium Coffee Beans to cart',
    jsonb_build_object('cart_item_id', 'cart-item-uuid', 'quantity', 1)
);
```

### 7. Staff Applies Discount
```sql
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata, action_type, action_data
)
VALUES (
    'conversation-uuid',
    'staff',
    'discount_applied',
    'I''ve applied a 10% discount for you!',
    jsonb_build_object(
        'product_id', 'product-uuid',
        'original_price', 4500.00,
        'discount_percent', 10,
        'discount_amount', 450.00,
        'final_price', 4050.00,
        'discount_code', 'CHAT10',
        'valid_until', '2024-01-31T23:59:59Z'
    ),
    'apply_discount',
    jsonb_build_object(
        'discount_id', 'discount-uuid',
        'auto_applied', true
    )
);
```

### 8. PDF Receipt for Payment
```sql
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata, media_url
)
VALUES (
    'conversation-uuid',
    'ai_agent',
    'receipt',
    'Here is your payment receipt',
    jsonb_build_object(
        'receipt_id', 'receipt-uuid',
        'sale_id', 'sale-uuid',
        'receipt_number', 'RCP-2024-0001',
        'amount', 4050.00,
        'payment_method', 'bank_transfer',
        'paid_at', '2024-01-20T14:30:00Z'
    ),
    'https://storage.example.com/receipts/RCP-2024-0001.pdf'
);
```

### 9. Payment Confirmation (Bank Transfer)
```sql
-- Customer shares transfer confirmation
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata, media_url
)
VALUES (
    'conversation-uuid',
    'customer',
    'payment_confirmation',
    'I have made the transfer',
    jsonb_build_object(
        'reference', 'TXN123456789',
        'amount', 4050.00,
        'bank', 'First Bank',
        'account_name', 'Customer Name',
        'transfer_date', '2024-01-20',
        'needs_verification', true
    ),
    'https://storage.example.com/payment-proofs/transfer-screenshot.jpg'
);

-- Staff verifies and confirms
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata
)
VALUES (
    'conversation-uuid',
    'staff',
    'system_action',
    'Payment verified! Your order is being processed.',
    jsonb_build_object(
        'payment_verified', true,
        'verified_by', 'staff-uuid',
        'verified_at', NOW(),
        'order_id', 'order-uuid'
    )
);
```

## E-Commerce Integration

### Product List with Chat Button

```typescript
// Example React component
function ProductCard({ product, tenantId }) {
  const [canShowChat, setCanShowChat] = useState(false);

  useEffect(() => {
    // Check if tenant has e-commerce chat feature
    supabase.rpc('has_ecommerce_chat_feature', { p_tenant_id: tenantId })
      .then(({ data }) => setCanShowChat(data));
  }, [tenantId]);

  return (
    <div className="product-card">
      <img src={product.image_url} alt={product.name} />
      <h3>{product.name}</h3>
      <p>{product.price}</p>

      <div className="actions">
        <button onClick={() => addToCart(product)}>Add to Cart</button>

        {/* Only show chat button for Pro/Enterprise plans */}
        {canShowChat && (
          <button onClick={() => startProductChat(product)}>
            💬 Ask about this product
          </button>
        )}
      </div>
    </div>
  );
}
```

### Starting a Product-Specific Chat

```sql
-- Create new conversation for product inquiry
INSERT INTO chat_conversations (tenant_id, branch_id, customer_id, status)
VALUES ('tenant-uuid', 'branch-uuid', 'customer-uuid', 'active')
RETURNING id;

-- Send initial product question
INSERT INTO chat_messages (
    conversation_id, sender_type, message_type,
    message_text, metadata
)
VALUES (
    'conversation-uuid',
    'customer',
    'text',
    'I need more details about this product',
    jsonb_build_object(
        'product_id', 'product-uuid',
        'source', 'ecommerce_product_page'
    )
);
```

## Query Examples

### Get conversation with all messages
```sql
SELECT
    c.*,
    json_agg(
        json_build_object(
            'id', m.id,
            'sender_type', m.sender_type,
            'message_type', m.message_type,
            'message_text', m.message_text,
            'media_url', m.media_url,
            'metadata', m.metadata,
            'action_type', m.action_type,
            'created_at', m.created_at
        )
        ORDER BY m.created_at ASC
    ) AS messages
FROM chat_conversations c
LEFT JOIN chat_messages m ON c.id = m.conversation_id
WHERE c.id = 'conversation-uuid'
GROUP BY c.id;
```

### Get pending actions (e.g., unapplied discounts)
```sql
SELECT
    m.*,
    c.customer_id,
    c.tenant_id
FROM chat_messages m
JOIN chat_conversations c ON m.conversation_id = c.id
WHERE m.action_type IS NOT NULL
  AND m.action_completed_at IS NULL
  AND c.status = 'active'
ORDER BY m.created_at DESC;
```

### Get all media shared in a conversation
```sql
SELECT
    message_type,
    media_url,
    thumbnail_url,
    media_size_bytes,
    media_duration_seconds,
    created_at
FROM chat_messages
WHERE conversation_id = 'conversation-uuid'
  AND message_type IN ('image', 'audio', 'video')
ORDER BY created_at DESC;
```

## Feature Flags in Subscriptions

### Setting up plan features
```sql
-- Update subscription features for a tenant
UPDATE subscriptions
SET features = jsonb_build_object(
    'ecommerce_chat', true,
    'ai_chat', true,
    'advanced_analytics', true,
    'multi_currency', false,
    'api_access', true
)
WHERE id = 'subscription-uuid';
```

### Example subscription tiers
```sql
-- Free tier
INSERT INTO subscriptions (plan_tier, features, ...)
VALUES (
    'free',
    '{"ecommerce_chat": false, "ai_chat": false}',
    ...
);

-- Basic tier
INSERT INTO subscriptions (plan_tier, features, ...)
VALUES (
    'basic',
    '{"ecommerce_chat": false, "ai_chat": true}',
    ...
);

-- Pro tier (Growth plan)
INSERT INTO subscriptions (plan_tier, features, ...)
VALUES (
    'pro',
    '{"ecommerce_chat": true, "ai_chat": true, "advanced_analytics": true}',
    ...
);

-- Enterprise tier
INSERT INTO subscriptions (plan_tier, features, ...)
VALUES (
    'enterprise',
    '{"ecommerce_chat": true, "ai_chat": true, "advanced_analytics": true, "multi_currency": true, "api_access": true, "custom_integrations": true}',
    ...
);
```

## Notes

1. **Media Storage**: Use Supabase Storage or external CDN for storing images, audio, video files
2. **Security**: Validate file uploads, scan for malware, limit file sizes
3. **Performance**: Use pagination for loading chat messages, lazy load media
4. **AI Integration**: Use the `intent` and `confidence_score` fields for AI response routing
5. **Escalation**: When `chat_conversations.status = 'escalated'`, route to `escalated_to_user_id` staff member

# Chat Service Documentation

## Overview

The chat service provides real-time messaging capabilities for the SvelteKit storefront, including WebSocket connections, file uploads, and rich media support.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SvelteKit Application                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐         ┌──────────────┐                  │
│  │   ChatWidget │────────▶│  Chat Store  │                  │
│  │  Component   │         │   (Svelte)   │                  │
│  └──────────────┘         └──────┬───────┘                  │
│                                   │                          │
│                                   ▼                          │
│                          ┌──────────────┐                   │
│                          │ Chat Service │                   │
│                          │   (Class)    │                   │
│                          └──────┬───────┘                   │
│                                 │                            │
│                    ┌────────────┼────────────┐              │
│                    ▼            ▼            ▼              │
│              ┌─────────┐  ┌─────────┐  ┌─────────┐         │
│              │WebSocket│  │HTTP API │  │ Storage │         │
│              └─────────┘  └─────────┘  └─────────┘         │
└─────────────────────────────────────────────────────────────┘
                     │            │            │
                     ▼            ▼            ▼
              ┌──────────────────────────────────┐
              │      Backend Services             │
              │  - WebSocket Server               │
              │  - Chat API Routes                │
              │  - Supabase Storage               │
              │  - Database (PostgreSQL)          │
              └──────────────────────────────────┘
```

## Components

### 1. ChatService (`chat.ts`)

The core service class that manages WebSocket connections and chat operations.

**Key Features:**
- WebSocket connection management with auto-reconnect
- Message sending and receiving
- File upload handling
- Typing indicators
- Heartbeat mechanism
- Connection state management

**Usage:**
```typescript
import { createChatService } from '$lib/services/chat';

const chatService = createChatService({
    branchId: 'branch-123',
    tenantId: 'tenant-123',
    customerId: 'customer-123',
    sessionToken: 'session-token',
    planTier: 'pro'
});

// Initialize session
const response = await chatService.initialize();

// Connect WebSocket
chatService.connect(response.session.id, {
    onMessage: (message) => console.log('New message:', message),
    onConnect: () => console.log('Connected'),
    onDisconnect: () => console.log('Disconnected')
});

// Send message
await chatService.sendMessage({
    sessionId: response.session.id,
    messageType: 'text',
    content: 'Hello!'
});
```

### 2. Chat Store (`stores/chat.ts`)

Svelte store for reactive state management of chat sessions.

**Key Features:**
- Reactive state updates
- Optimistic message updates
- Automatic WebSocket event handling
- Derived stores for convenience
- Error handling

**Usage:**
```typescript
import { chatStore, chatMessages, isChatOpen } from '$lib/stores/chat';

// Initialize
await chatStore.initialize({
    branchId: 'branch-123',
    tenantId: 'tenant-123',
    customerId: 'customer-123',
    sessionToken: 'session-token',
    planTier: 'pro'
});

// Send message
await chatStore.sendMessage('Hello!');

// Upload file
await chatStore.sendFile(file, 'image');

// Share product
await chatStore.shareProduct('product-id', 'Product Name');
```

### 3. ChatWidget Component (`components/ChatWidget.svelte`)

Pre-built UI component for chat interface.

**Features:**
- Floating chat button
- Expandable chat window
- Message list with auto-scroll
- File upload (images, PDFs, audio)
- Voice recording
- Product sharing
- Typing indicators
- Connection status
- Plan-based feature access

## WebSocket Protocol

### Connection

```
ws://localhost:5173/api/chat/ws?sessionId={sessionId}&token={sessionToken}
```

### Message Types

#### Client → Server

1. **Ping (Heartbeat)**
```json
{
    "type": "ping"
}
```

2. **Typing Indicator**
```json
{
    "type": "typing",
    "sessionId": "session-id",
    "isTyping": true
}
```

#### Server → Client

1. **New Message**
```json
{
    "type": "message",
    "data": {
        "id": "message-id",
        "session_id": "session-id",
        "sender_type": "agent",
        "sender_name": "Agent Name",
        "message_type": "text",
        "content": "Hello!",
        "created_at": "2024-01-01T00:00:00Z"
    }
}
```

2. **Typing Indicator**
```json
{
    "type": "typing",
    "data": {
        "isTyping": true,
        "agentName": "Agent Name"
    }
}
```

3. **Agent Status Change**
```json
{
    "type": "agent_status",
    "data": {
        "status": "online"
    }
}
```

4. **Queue Update**
```json
{
    "type": "queue_update",
    "data": {
        "position": 3
    }
}
```

5. **Session Update**
```json
{
    "type": "session_update",
    "data": {
        "id": "session-id",
        "status": "active",
        "agent_id": "agent-id"
    }
}
```

6. **Error**
```json
{
    "type": "error",
    "data": {
        "message": "Error description"
    }
}
```

## HTTP API Endpoints

### POST `/api/chat`

Main chat API endpoint for various actions.

**Actions:**

1. **Initialize Session**
```json
{
    "action": "initialize",
    "branchId": "branch-id",
    "tenantId": "tenant-id",
    "customerId": "customer-id",
    "sessionToken": "session-token",
    "planTier": "pro"
}
```

Response:
```json
{
    "session": { /* ChatSession */ },
    "messages": [ /* ChatMessage[] */ ],
    "agentStatus": "online",
    "queuePosition": null
}
```

2. **Send Message**
```json
{
    "action": "send_message",
    "sessionId": "session-id",
    "messageType": "text",
    "content": "Hello!",
    "productId": null,
    "attachmentId": null
}
```

Response:
```json
{
    "message": { /* ChatMessage */ }
}
```

3. **Mark Messages as Read**
```json
{
    "action": "mark_read",
    "sessionId": "session-id",
    "messageIds": ["msg-1", "msg-2"]
}
```

4. **End Session**
```json
{
    "action": "end_session",
    "sessionId": "session-id"
}
```

### POST `/api/chat/upload`

Upload file attachments.

**Request:**
- Content-Type: `multipart/form-data`
- Fields:
  - `file`: File to upload
  - `sessionId`: Chat session ID
  - `fileType`: 'image' | 'pdf' | 'voice'

**Response:**
```json
{
    "url": "https://storage.url/file.jpg",
    "attachmentId": "attachment-id"
}
```

### GET `/api/chat/history`

Fetch chat history.

**Query Parameters:**
- `sessionId`: Chat session ID
- `limit`: Number of messages (default: 50)
- `before`: ISO timestamp for pagination

**Response:**
```json
{
    "messages": [ /* ChatMessage[] */ ]
}
```

## File Upload Specifications

### Supported File Types

1. **Images**
   - MIME types: `image/*`
   - Max size: 5MB
   - Formats: JPEG, PNG, GIF, WebP

2. **PDFs**
   - MIME type: `application/pdf`
   - Max size: 10MB

3. **Audio (Voice Notes)**
   - MIME types: `audio/*`
   - Max size: 5MB (≈2 minutes)
   - Formats: WebM, MP3, WAV

### Validation

```typescript
import { validateChatFile } from '$lib/services/chat';

const validation = validateChatFile(file);
if (!validation.valid) {
    console.error(validation.error);
}
```

## Connection Management

### Auto-Reconnection

The service automatically attempts to reconnect when the connection is lost:

- **Max attempts**: 5
- **Initial delay**: 1 second
- **Backoff strategy**: Exponential (doubles each attempt)
- **Max delay**: 30 seconds

### Heartbeat

- **Interval**: 30 seconds
- **Purpose**: Keep connection alive and detect disconnections
- **Message**: `{ "type": "ping" }`

## State Management

### Chat Store State

```typescript
interface ChatState {
    session: ChatSession | null;
    messages: ChatMessage[];
    isOpen: boolean;
    isConnected: boolean;
    isConnecting: boolean;
    isLoading: boolean;
    isTyping: boolean;
    typingAgentName: string | null;
    agentStatus: 'online' | 'offline' | 'busy';
    queuePosition: number | null;
    error: string | null;
    unreadCount: number;
}
```

### Derived Stores

```typescript
import { 
    chatMessages,      // ChatMessage[]
    chatSession,       // ChatSession | null
    isChatOpen,        // boolean
    isChatConnected,   // boolean
    chatUnreadCount,   // number
    chatAgentStatus,   // 'online' | 'offline' | 'busy'
    chatError          // string | null
} from '$lib/stores/chat';
```

## Plan-Based Features

### Free Plan
- ✅ Live chat with owner/admin only
- ❌ No dedicated agents
- ❌ No AI agent
- ❌ No file uploads

### Growth Plan
- ✅ Live chat with single agent
- ✅ File uploads (images, PDFs, voice)
- ✅ Queue position display
- ❌ No AI agent
- ❌ No multi-agent support

### Business Plan
- ✅ Live chat with multiple agents
- ✅ File uploads (images, PDFs, voice)
- ✅ AI agent fallback
- ✅ Image recognition
- ✅ Product sharing
- ✅ Advanced analytics

## Error Handling

### Common Errors

1. **Connection Failed**
```typescript
{
    type: 'error',
    data: { message: 'WebSocket connection error' }
}
```

2. **Upload Failed**
```typescript
{
    type: 'error',
    data: { message: 'Failed to upload file' }
}
```

3. **Session Expired**
```typescript
{
    type: 'error',
    data: { message: 'Chat session expired' }
}
```

### Error Recovery

```typescript
chatStore.subscribe($chat => {
    if ($chat.error) {
        // Show error to user
        console.error('Chat error:', $chat.error);
        
        // Clear error after showing
        setTimeout(() => {
            chatStore.clearError();
        }, 5000);
    }
});
```

## Performance Optimization

### Best Practices

1. **Message Pagination**
   - Load initial 50 messages
   - Implement "Load More" for history
   - Use virtual scrolling for long conversations

2. **File Compression**
   - Compress images before upload
   - Use WebP format when possible
   - Implement progressive loading

3. **Connection Pooling**
   - Reuse WebSocket connections
   - Implement connection pooling for multiple chats
   - Close inactive connections

4. **Caching**
   - Cache messages in localStorage
   - Implement offline message queue
   - Sync on reconnection

## Security Considerations

1. **Authentication**
   - Validate session tokens on server
   - Implement token refresh mechanism
   - Use secure WebSocket (WSS) in production

2. **Input Validation**
   - Sanitize message content
   - Validate file types and sizes
   - Implement rate limiting

3. **Data Privacy**
   - Encrypt sensitive messages
   - Implement message retention policies
   - Comply with GDPR/privacy regulations

## Testing

### Unit Tests

```typescript
import { describe, it, expect } from 'vitest';
import { validateChatFile, formatFileSize } from '$lib/services/chat';

describe('Chat Service', () => {
    it('validates image files correctly', () => {
        const file = new File([''], 'test.jpg', { type: 'image/jpeg' });
        const result = validateChatFile(file);
        expect(result.valid).toBe(true);
    });

    it('formats file sizes correctly', () => {
        expect(formatFileSize(1024)).toBe('1 KB');
        expect(formatFileSize(1024 * 1024)).toBe('1 MB');
    });
});
```

### Integration Tests

```typescript
import { describe, it, expect, beforeEach } from 'vitest';
import { chatStore } from '$lib/stores/chat';

describe('Chat Store', () => {
    beforeEach(() => {
        chatStore.reset();
    });

    it('initializes chat session', async () => {
        await chatStore.initialize({
            branchId: 'test-branch',
            tenantId: 'test-tenant',
            sessionToken: 'test-token',
            planTier: 'pro'
        });

        const state = get(chatStore);
        expect(state.session).not.toBeNull();
    });
});
```

## Troubleshooting

### WebSocket Connection Issues

**Problem**: WebSocket fails to connect

**Solutions**:
1. Check WebSocket URL format
2. Verify session token is valid
3. Check firewall/proxy settings
4. Ensure WebSocket server is running

### File Upload Failures

**Problem**: Files fail to upload

**Solutions**:
1. Check file size limits
2. Verify file type is supported
3. Check storage bucket permissions
4. Verify network connectivity

### Message Delivery Issues

**Problem**: Messages not delivered

**Solutions**:
1. Check WebSocket connection status
2. Verify session is active
3. Check message queue
4. Implement retry mechanism

## Migration Guide

### From Socket.io to Native WebSocket

If migrating from Socket.io:

1. Update connection URL format
2. Change event emission to JSON messages
3. Update event handlers
4. Implement reconnection logic
5. Update authentication mechanism

## Future Enhancements

1. **Message Reactions**
   - Add emoji reactions to messages
   - Track reaction counts

2. **Message Threading**
   - Reply to specific messages
   - Create conversation threads

3. **Rich Text Formatting**
   - Support markdown
   - Add text formatting toolbar

4. **Video/Screen Sharing**
   - WebRTC integration
   - Screen sharing capability

5. **Chat Analytics**
   - Response time tracking
   - Customer satisfaction ratings
   - Agent performance metrics

## Support

For issues or questions:
- Check the examples in `examples/chat-usage.ts`
- Review the component implementation in `components/ChatWidget.svelte`
- Consult the API documentation above

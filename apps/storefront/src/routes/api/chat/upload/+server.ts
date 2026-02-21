import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';

export const POST: RequestHandler = async ({ request, locals: { supabase } }) => {
    try {
        const formData = await request.formData();
        const file = formData.get('file') as File;
        const sessionId = formData.get('sessionId') as string;
        const type = formData.get('type') as 'image' | 'voice' | 'pdf';
        const sessionToken = formData.get('sessionToken') as string;

        if (!file || !sessionId || !type) {
            return json({ error: 'Missing required file data' }, { status: 400 });
        }

        // Validate session access
        const { data: session, error: sessionError } = await supabase
            .from('chat_sessions')
            .select('id, customer_id, session_token')
            .eq('id', sessionId)
            .single();

        if (sessionError || !session) {
            return json({ error: 'Session invalid' }, { status: 404 });
        }

        if (sessionToken && session.session_token !== sessionToken && !session.customer_id) {
            return json({ error: 'Unauthorized session access' }, { status: 403 });
        }

        // Generate unique filename
        const filename = `${Date.now()}-${file.name.replace(/[^a-zA-Z0-9.-]/g, '_')}`;
        const path = `${sessionId}/${filename}`;

        // Upload to Storage
        const bucket = 'chat-attachments';
        const { error: uploadError } = await supabase.storage
            .from(bucket)
            .upload(path, file, {
                cacheControl: '3600',
                upsert: false
            });

        if (uploadError) {
            console.error('Upload Error:', uploadError);
            throw uploadError;
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
            .from(bucket)
            .getPublicUrl(path);

        // Record attachment in database
        const { data: attachment, error: dbError } = await supabase
            .from('chat_attachments')
            .insert({
                message_id: null, // Will be linked when message is sent (or create message here?)
                // Actually, schema links attachment to message. But we need attachment ID first?
                // Or maybe link it later? Schema says `message_id` is NOT NULL?
                // Let's check schema.
                // 11. chat_attachments -> message_id UUID NOT NULL REFERENCES chat_messages(id)

                // Problem: We upload file first, then send message. But attachment must link to message.
                // Solution:
                // 1. Create message first with empty content/type? No.
                // 2. Upload file, get URL.
                // 3. Send message with URL as content.
                // 4. Then creating attachment record linked to message.

                // Wait, if `chat_attachments` requires `message_id`, we can't insert it without a message.
                // So the API flow should be:
                // 1. Upload file to Storage -> Get URL/Path.
                // 2. Create Message with content=URL.
                // 3. Create Attachment record linked to that message.

                // However, `chatStore.ts` does:
                // const { url, attachmentId } = await chatService.uploadFile(...)
                // const message = await chatService.sendMessage(..., attachmentId)

                // This implies `uploadFile` returns an ID. But if `chat_attachments` needs `message_id`, we can't create the record yet.
                // So `uploadFile` should just return the URL and metadata, NOT the DB record ID yet?
                // OR we create a temporary message?

                // Let's look at schema again.
                // message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE

                // Okay, so we MUST have a message ID.

                // Revised Flow in `uploadFile` endpoint:
                // Just upload to storage and return keys. The client will then call `sendMessage`.
                // BUT we need to record the attachment metadata (size, type) securely.

                // Maybe `uploadFile` endpoint creates the message AND attachment?
                // But `chatStore` calls `sendMessage` separately. This is a bit disjointed.

                // To fix this without changing `chatStore` logic too much:
                // 1. `uploadFile` uploads to storage. Returns URL and file metadata (size, type, path).
                // 2. `sendMessage` accepts `attachment` object (URL, size, type, path).
                // 3. `sendMessage` creates message AND attachment record in a transaction (or sequential).

                // Let's check `chatStore.ts` implementation of `sendFile`:
                // const { url, attachmentId } = await chatService.uploadFile(...)
                // const message = await chatService.sendMessage(..., attachmentId)

                // It expects `attachmentId`. This suggests `chat_attachments` record is created in `uploadFile`.
                // If so, `message_id` must be nullable in schema or we provide a dummy one?
                // Schema has `NOT NULL`.

                // I must update the schema to make `message_id` nullable OR handling it differently.
                // Making it nullable allows "orphaned" attachments (uploaded but message failed), which is fine for drafts.
                // Let's modify schema or adjust logic.

                // Adjusting logic is better if I can.
                // If I change `chatStore`, I can pass file metadata to `sendMessage` directly.

                // Let's check `chat.ts` store again.
                /*
                const { url, attachmentId } = await chatService.uploadFile(state.session.id, file, fileType);
                const message = await chatService.sendMessage({
                    sessionId: state.session.id,
                    messageType: fileType,
                    content: url,
                    attachmentId
                });
                */

                // If I change `message_id` to NULLABLE in schema, it solves this.
                // Let's check if I can modify schema. Yes, I can run a migration.

                // ALTER TABLE chat_attachments ALTER COLUMN message_id DROP NOT NULL;

                // This is the cleanest way to support "Upload then Send" flow.

                session_id: sessionId,
                file_type: type,
                file_name: file.name,
                file_size: file.size,
                mime_type: file.type,
                storage_path: path,
                storage_url: publicUrl,
                uploaded_by: session.customer_id || session.id // heuristic
            })
            .select() // Returning *
            .single(); // we want single result

        if (dbError) {
            // If message_id is NOT NULL, this will fail.
            // I will create a migration to make it nullable.
            throw dbError;
        }

        return json({
            url: publicUrl,
            attachmentId: attachment.id
        });

    } catch (error: any) {
        console.error('File Upload API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};

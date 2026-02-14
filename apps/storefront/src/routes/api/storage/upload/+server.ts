import type { RequestHandler } from './$types';
import { json } from '@sveltejs/kit';
import { createClient } from '$lib/services/supabase';

// POST - Upload chat attachment
export const POST: RequestHandler = async ({ request }) => {
    try {
        const formData = await request.formData();
        const file = formData.get('file') as File;
        const type = formData.get('type') as string; // image, audio, pdf

        if (!file) {
            return json({ error: 'No file provided' }, { status: 400 });
        }

        // Validate file type and size
        const validTypes = {
            image: ['image/jpeg', 'image/png', 'image/gif', 'image/webp'],
            audio: ['audio/mpeg', 'audio/wav', 'audio/ogg'],
            pdf: ['application/pdf']
        };

        const maxSizes = {
            image: 5 * 1024 * 1024, // 5MB
            audio: 2 * 1024 * 1024, // 2MB (2 min max)
            pdf: 10 * 1024 * 1024   // 10MB
        };

        const fileType = type as 'image' | 'audio' | 'pdf';

        if (!validTypes[fileType]?.includes(file.type)) {
            return json({ error: 'Invalid file type' }, { status: 400 });
        }

        if (file.size > maxSizes[fileType]) {
            return json({ error: 'File too large' }, { status: 400 });
        }

        const supabase = createClient();

        // Upload to Supabase Storage
        const fileName = `${Date.now()}-${file.name}`;
        const filePath = `chat-attachments/${fileType}/${fileName}`;

        const { data, error } = await supabase.storage
            .from('chat-attachments')
            .upload(filePath, file, {
                contentType: file.type
            });

        if (error) {
            console.error('File upload error:', error);
            return json({ error: error.message }, { status: 500 });
        }

        // Get public URL
        const { data: { publicUrl } } = supabase.storage
            .from('chat-attachments')
            .getPublicUrl(filePath);

        return json({ url: publicUrl, path: filePath, type: fileType }, { status: 201 });
    } catch (error: any) {
        console.error('Storage upload API Error:', error);
        return json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
};

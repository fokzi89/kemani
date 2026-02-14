import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { WhatsAppService } from '@/lib/integrations/whatsapp';

export async function POST(req: NextRequest) {
    try {
        const supabase = await createClient();
        const { data: { user }, error } = await supabase.auth.getUser();

        if (error || !user) {
            return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
        }

        const body = await req.json();
        const { to, type, content, templateName, language } = body;
        const tenantId = user.user_metadata.tenant_id;

        if (!tenantId) {
            return NextResponse.json({ error: 'Tenant ID missing' }, { status: 400 });
        }

        if (!to) {
            return NextResponse.json({ error: 'Recipient phone number is required' }, { status: 400 });
        }

        let result;

        if (type === 'template') {
            if (!templateName) return NextResponse.json({ error: 'Template name is required' }, { status: 400 });
            result = await WhatsAppService.sendTemplate(tenantId, to, templateName, language);
        } else {
            // Default to text
            if (!content) return NextResponse.json({ error: 'Message content is required' }, { status: 400 });
            result = await WhatsAppService.sendTextMessage(tenantId, to, content);
        }

        // TODO: Log to database (WhatsAppMessage table) implementation deferred to valid webhook or explicit log service call here.
        // For now, returning success based on API call.

        return NextResponse.json({ success: true, data: result });

    } catch (error: any) {
        console.error('WhatsApp API Error', error);
        return NextResponse.json({ error: error.message || 'Internal Server Error' }, { status: 500 });
    }
}

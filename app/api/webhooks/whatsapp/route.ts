import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/client';

// NOTE: This webhook needs to be public for Meta to reach it.
// Security is handled via verify_token for verification and signature validation for POST (signature logic deferred for MVP).

export async function GET(req: NextRequest) {
    // Webhook Verification Request
    const { searchParams } = new URL(req.url);
    const mode = searchParams.get('hub.mode');
    const token = searchParams.get('hub.verify_token');
    const challenge = searchParams.get('hub.challenge');

    // In a real app, VERIFY_TOKEN should be stored in ENV or Tenant Settings per webhook.
    // For MVP, assume a fixed token or we dynamically check against all tenants?
    // Meta usually expects one webhook URL per app.
    // Let's assume a global env for the platform, or we check against a specific tenant if the URL was unique.
    // For now: "kemani_verify_token"

    if (mode === 'subscribe' && token === 'kemani_verify_token') {
        return new NextResponse(challenge, { status: 200 });
    }

    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
}

export async function POST(req: NextRequest) {
    try {
        const body = await req.json();

        // Check if this is a WhatsApp status update or message
        if (body.object) {
            if (body.entry &&
                body.entry[0].changes &&
                body.entry[0].changes[0].value.messages &&
                body.entry[0].changes[0].value.messages[0]
            ) {
                const phone_no_id = body.entry[0].changes[0].value.metadata.phone_number_id;
                const from = body.entry[0].changes[0].value.messages[0].from;
                const msg_body = body.entry[0].changes[0].value.messages[0].text?.body;

                console.log("WhatsApp Message Received:", { from, msg_body, phone_no_id });

                // TODO: Look up tenant by phone_number_id and save message to DB.
                // Deferred: This requires querying tenants where whatsappSettings.phoneNumberId == phone_no_id.
            }
            return NextResponse.json({ success: true }, { status: 200 });
        } else {
            return NextResponse.json({ error: 'Not Found' }, { status: 404 });
        }
    } catch (error) {
        console.error("Webhook Error", error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

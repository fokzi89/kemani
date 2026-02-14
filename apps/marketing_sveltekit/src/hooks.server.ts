import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
    const url = new URL(event.request.url);
    const host = url.host; // e.g., tenant.kemani.com or localhost:5173

    // Simple tenant resolution logic
    // In a real app, you might query a database or API to verify the tenant
    let tenant = null;

    // Check for subdomain
    if (host.includes('kemani.com') && !host.startsWith('www') && !host.startsWith('marketing')) {
        tenant = host.split('.')[0];
    } else if (host.includes('localhost')) {
        // Logic for local dev, maybe using a query param or a specific path prefix for testing
        // For now, we'll assume no tenant if localhost unless specifically handled
    }

    // Attach tenant to locals
    event.locals.tenant = tenant;

    const response = await resolve(event);
    return response;
};

import { createClient } from '@/lib/supabase/client';
import { BrandingConfig } from '@/lib/types/database';

interface WhatsAppConfig {
    phoneNumberId: string;
    accessToken: string;
    businessAccountId: string;
}

export class WhatsAppService {

    /**
     * Retrieves WhatsApp configuration for a tenant (from Branding/Settings)
     */
    static async getConfig(tenantId: string): Promise<WhatsAppConfig | null> {
        const supabase = await createClient();
        const { data, error } = await supabase
            .from('tenants')
            .select('ecommerce_settings') // Actually part of naming convention mix-up in my plan vs reality? 
            // In database.ts replace, I put it in BrandingConfig which maps to 'ecommerce_settings' column? 
            // Wait, database.ts `BrandingConfig` is likely the type for a JSONB column `settings` or similar.
            // Let's check `MarketplaceService` usage: `.select('name, ... ecommerce_settings')`
            // and types: `settings: tenant.ecommerce_settings as BrandingConfig['ecommerceSettings']`.
            // Ah, the `BrandingConfig` usually maps to a column.
            // Let's assume there is a `settings` jsonb column or we are extending `ecommerce_settings` (which is named narrowly).
            // Actually, in Phase 2 `T079` we implemented branding endpoint.
            // Let's check `lib/types/database.ts` again or `setup.sql` if I could.
            // Based on `MarketplaceService.getStorefrontDetails`, it selects `ecommerce_settings`.
            // Let's assume for MVP we are piggybacking on `ecommerce_settings` column or a new one.
            // Ideally we should have a `settings` column.
            // For now, let's assume we read from a `settings` jsonb column if it exists, OR `ecommerce_settings` if that's what we have.
            // I'll stick to `ecommerce_settings` column for now assuming it's a JSONB bag, 
            // OR I should use `BrandingConfig` as the type of that column.
            // Let's check `MarketplaceService` again.
            // It casts `tenant.ecommerce_settings` to `BrandingConfig['ecommerceSettings']`.
            // This implies `BrandingConfig` is the SHAPE of the whole object, but `ecommerce_settings` column stores just the inner part?
            // Actually `MarketplaceService` code:
            // `settings: tenant.ecommerce_settings as BrandingConfig['ecommerceSettings']`
            // It seems `ecommerce_settings` DB column holds the inner object. 
            // I should probably add `whatsappSettings` to that JSONB column.
            // So in DB, the column is `ecommerce_settings` (jsonb).
            // I will treat it as a general settings bag for now.
            .eq('id', tenantId)
            .single();

        if (error || !data || !data.ecommerce_settings) return null;

        // Need to cast properly. In real app, avoid 'any'.
        // Assuming the column `ecommerce_settings` now holds { ...ecommerce, whatsappSettings: {...} }
        // or we need to migrate/expand it. 
        // For MVP, let's assume we can save to it.
        const settings = data.ecommerce_settings as any;
        return settings.whatsappSettings as WhatsAppConfig;
    }

    /**
     * Send a text message
     */
    static async sendTextMessage(tenantId: string, to: string, body: string) {
        const config = await this.getConfig(tenantId);
        if (!config || !config.accessToken) throw new Error("WhatsApp not configured for this tenant");

        const url = `https://graph.facebook.com/v17.0/${config.phoneNumberId}/messages`;

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${config.accessToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                messaging_product: "whatsapp",
                recipient_type: "individual",
                to: to,
                type: "text",
                text: { preview_url: false, body: body }
            })
        });

        const resData = await response.json();
        if (!response.ok) {
            throw new Error(resData.error?.message || "Failed to send WhatsApp message");
        }
        return resData;
    }

    /**
     * Send a template message (e.g., order_confirmation)
     */
    static async sendTemplate(tenantId: string, to: string, templateName: string, language: string = 'en_US', components: any[] = []) {
        const config = await this.getConfig(tenantId);
        if (!config || !config.accessToken) throw new Error("WhatsApp not configured for this tenant");

        const url = `https://graph.facebook.com/v17.0/${config.phoneNumberId}/messages`;

        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${config.accessToken}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                messaging_product: "whatsapp",
                to: to,
                type: "template",
                template: {
                    name: templateName,
                    language: { code: language },
                    components: components
                }
            })
        });

        const resData = await response.json();
        if (!response.ok) {
            throw new Error(resData.error?.message || "Failed to send WhatsApp template");
        }
        return resData;
    }
}

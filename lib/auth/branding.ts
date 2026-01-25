import { createClient } from '@/lib/supabase/client';
import { BrandingConfig } from '@/lib/types/database';

export class BrandingService {
  /**
   * Update tenant branding configuration
   */
  static async updateBranding(tenantId: string, branding: BrandingConfig) {
    const supabase = createClient();

    const updates: any = {};

    if (branding.logoUrl !== undefined) {
      updates.logo_url = branding.logoUrl;
    }

    if (branding.brandColor !== undefined) {
      updates.brand_color = branding.brandColor;
    }

    if (branding.customDomain !== undefined) {
      updates.custom_domain = branding.customDomain;
    }

    if (branding.ecommerceEnabled !== undefined) {
      updates.ecommerce_enabled = branding.ecommerceEnabled;
    }

    if (branding.ecommerceSettings !== undefined) {
      updates.ecommerce_settings = branding.ecommerceSettings;
    }

    const { data, error } = await supabase
      .from('tenants')
      .update(updates)
      .eq('id', tenantId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Upload tenant logo
   */
  static async uploadLogo(tenantId: string, file: File): Promise<string> {
    const supabase = createClient();

    const fileExt = file.name.split('.').pop();
    const fileName = `${tenantId}/logo.${fileExt}`;
    const filePath = `tenant-logos/${fileName}`;

    // Upload file to Supabase Storage
    const { error: uploadError } = await supabase.storage
      .from('public')
      .upload(filePath, file, {
        cacheControl: '3600',
        upsert: true,
      });

    if (uploadError) throw uploadError;

    // Get public URL
    const { data: { publicUrl } } = supabase.storage
      .from('public')
      .getPublicUrl(filePath);

    // Update tenant with logo URL
    await this.updateBranding(tenantId, { logoUrl: publicUrl });

    return publicUrl;
  }

  /**
   * Get tenant branding
   */
  static async getBranding(tenantId: string) {
    const supabase = createClient();

    const { data, error } = await supabase
      .from('tenants')
      .select('logo_url, brand_color, custom_domain, ecommerce_enabled, ecommerce_settings')
      .eq('id', tenantId)
      .single();

    if (error) throw error;

    return {
      logoUrl: data.logo_url,
      brandColor: data.brand_color,
      customDomain: data.custom_domain,
      ecommerceEnabled: data.ecommerce_enabled,
      ecommerceSettings: data.ecommerce_settings as BrandingConfig['ecommerceSettings'],
    } as BrandingConfig;
  }

  /**
   * Set custom domain
   */
  static async setCustomDomain(tenantId: string, domain: string) {
    const supabase = createClient();

    const { data, error } = await supabase
      .from('tenants')
      .update({
        custom_domain: domain,
        custom_domain_verified: false, // Needs verification
      })
      .eq('id', tenantId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Verify custom domain
   */
  static async verifyCustomDomain(tenantId: string) {
    const supabase = createClient();

    // In a real implementation, you would:
    // 1. Check DNS records
    // 2. Verify SSL certificate
    // 3. Update domain status

    // For now, just mark as verified
    const { data, error } = await supabase
      .from('tenants')
      .update({ custom_domain_verified: true })
      .eq('id', tenantId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Enable/disable e-commerce
   */
  static async toggleEcommerce(tenantId: string, enabled: boolean) {
    const supabase = createClient();

    const { data, error } = await supabase
      .from('tenants')
      .update({ ecommerce_enabled: enabled })
      .eq('id', tenantId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /**
   * Update e-commerce settings
   */
  static async updateEcommerceSettings(
    tenantId: string,
    settings: BrandingConfig['ecommerceSettings']
  ) {
    const supabase = createClient();

    const { data, error } = await supabase
      .from('tenants')
      .update({ ecommerce_settings: settings })
      .eq('id', tenantId)
      .select()
      .single();

    if (error) throw error;
    return data;
  }
}
